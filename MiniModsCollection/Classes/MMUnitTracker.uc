class MMUnitTracker extends Actor;

struct TAmmoInfo
{
	var int iPreviousAmmoCount;
	var int iCurrentAmmoCount;
	var int iAmmoSpentVisibleToPlayer;
};

var XGUnit m_kUnit;
var UIUnitFlag m_kUnitFlag;
var XGAbility_Targeted m_kShotStatMod;
var bool m_bRangeModifiersApplied;
var int m_iWatchActiveUnitHandle;
var int m_iWatchActiveUnitTravelHandle;
var int m_iWatchActiveUnitAction;
var int m_iWatchFireActionStatus;
var int m_iWatchAbilitiesHUD;
var int m_iWatchScoutAbilitySlot;
var bool m_bFirstTileReactionCheckDone;
var array<XGUnit> m_arrOverwatchingEnemies;
var bool m_bForceNextReactionCheck;
var int m_iLastInterval_MoveReactionProcessing;
var int m_iUnitHP;
var DelayedOverwatch m_kDelayedOWHandler;
var MMScoutSense_FX m_kScoutSense;
var MMXGAbility_ScoutSense m_kScoutAbility;
var int m_iScoutAbilitySlot;
var bool m_bUnitDisoriented;
var bool m_bUsedGrappleThisTurn;
var bool m_bGrappleCheckPending;
var Vector m_vGrappleDestination;
var int m_iGrappleCharges;
var bool m_bLWRebalance;
var TAmmoInfo m_kTAmmoInfo;
var bool m_bStartedTurnUnseenToPlayer;
var bool m_bEndedTurnUnseenToPlayer;
var int m_iNumTurnsUnseenToPlayer;
var StaticMeshComponent m_kSightRing;
var bool m_bSightRingVisible;
var array<TMenuOption> m_arrSaveValueQueue;

/** A wrapper for static SaveValueString*/
function SaveValue(string sKey, coerce string sValue)
{
	if(sValue ~= string(true))
	{
		sValue = "true";
	}
	else if(sValue ~= string(false))
	{
		sValue = "false";
	}
	class'XGSaveHelper'.static.SaveValueString(class'XGSaveHelper'.static.GetSaveData("MiniModsCollection"), m_kUnit, sKey, sValue);
}
/** A wrapper for static GetSavedValueString*/
function string GetSavedValue(string sKey, optional coerce string sObject=string(m_kUnit))
{
	return class'XGSaveHelper'.static.GetSavedValueString(class'XGSaveHelper'.static.GetSaveData("MiniModsCollection"), sObject, sKey);
}
function QueueSaveValue(string sKey, coerce string sValue)
{
	local TMenuOption tEntry;

	tEntry.strText = sKey;
	tEntry.strHelp = sValue;
	m_arrSaveValueQueue.AddItem(tEntry);
}
function ProcessSaveQueue()
{
	if(!IsInState('SavingData', true))
	{
		PushState('SavingData');
	}
}
function BaseInit(XGUnit kUnit)
{
	m_kUnit = kUnit;
	if(!kUnit.IsDead())
	{
		InitSavedData();
		UpdateUnitFlag();
		RegisterWatchVars();
	}
	m_bLWRebalance = DynamicLoadObject("LWRebalance.RebalanceMutator", class'Class', true) != none;
}
function Init(XGUnit kUnit)
{
	BaseInit(kUnit);
	if(kUnit.IsDead())
	{
		return;
	}
	m_kSightRing = new (kUnit) class'StaticMeshComponent'(kUnit.GetPawn().RangeIndicator);
	m_kSightRing.SetStaticMesh(kUnit.GetPawn().CivilianRescueRing);
	kUnit.AttachComponent(m_kSightRing);
	SetBase(m_kUnit.GetPawn());
	if(class'MiniModsTactical'.default.m_bRangeAimModifiers)
	{
		CreateShotStatModFor(kUnit);
		EnableDisableShotStatMod(m_kUnit.GetTeam() != GetActiveUnit().GetTeam());
		UpdateRangeShotModifiers();
	}
	kUnit.m_bReactionFireStatus = !class'MiniModsTactical'.default.m_bSequentialOverwatch;//this effectively disables/re-enables original OW code
	OnDropIn();//it's in Init for the drop-in/walk-in reinforcements to immediatly check for reaction fire
	LimitChainPanic();
}
event Destroyed()
{
	m_kSightRing = none;
}
function InitSavedData()
{
	local string sValue;

	//ensure correct num of grapple charges and availability after load from save
	if(class'MiniModsTactical'.default.m_bNoCostGrapple)
	{	
		sValue = GetSavedValue("m_iGrappleCharges");
		m_iGrappleCharges = (sValue != "" ? int(sValue) : class'MiniModsTactical'.default.m_iGrappleCharges);
	}
	sValue = GetSavedValue("m_bUsedGrappleThisTurn");
	m_bUsedGrappleThisTurn = (sValue != "" ? bool(sValue) : false);

	//init Ammo Spent by Enemies mod
	sValue = GetSavedValue("iPreviousAmmoCount");
	if(sValue == "")
	{
		UpdateAmmoInfo();
		m_kTAmmoInfo.iPreviousAmmoCount = m_kTAmmoInfo.iCurrentAmmoCount;
		QueueSaveValue("iPreviousAmmoCount", m_kTAmmoInfo.iPreviousAmmoCount);
	}
	else
	{
		m_kTAmmoInfo.iPreviousAmmoCount = int(GetSavedValue("iPreviousAmmoCount"));
		m_kTAmmoInfo.iCurrentAmmoCount= int(GetSavedValue("iCurrentAmmoCount"));
		m_kTAmmoInfo.iAmmoSpentVisibleToPlayer= int(GetSavedValue("iAmmoSpentVisibleToPlayer"));
		UpdateDisplayAmmoSpent();
	}
	sValue = GetSavedValue("m_bStartedTurnUnseenToPlayer");
	if(sValue != "")
	{
		m_bStartedTurnUnseenToPlayer = bool(sValue);
		m_bEndedTurnUnseenToPlayer= bool(GetSavedValue("m_bEndedTurnUnseenToPlayer"));
		m_iNumTurnsUnseenToPlayer= int(GetSavedValue("m_iNumTurnsUnseenToPlayer"));
	}
	//Range shot modifiers
	sValue = GetSavedValue("m_bRangeModifiersApplied");
	m_bRangeModifiersApplied = (sValue != "" ? bool(sValue) : false);
}
//this function creates a custom ability which is then applied on the unit
//it has eEffect_TargetStats so its aTargetStats are included in any ToHit calculations
function CreateShotStatModFor(XGUnit kUnit)
{
	local array<XGUnit> arrTargets;
	local XGAbilityTree kAbilities;

	kAbilities = XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_kAbilities;
	//hijack eAbility_HeatWave (69) for the purpose of shot stat modifier
	kAbilities.BuildAbility(eAbility_HeatWave, eTarget_Self, 0, -1, 0, eEffect_TargetStats,,,,,,,,,,,eDisplayProp_NonMenu);
	arrTargets[0] = kUnit;
	m_kShotStatMod = XGAbility_Targeted(kAbilities.SpawnAbility(69, kUnit, arrTargets, kUnit.GetInventory().GetActiveWeapon()));
	m_kShotStatMod.m_bSave = false;
	m_kShotStatMod.strName = m_kShotStatMod.GetWeaponName();
}
function RegisterWatchVars()
{
	local WatchVariableMgr kWatchMgr;

	kWatchMgr = class'Engine'.static.GetCurrentWorldInfo().MyWatchVariableMgr;

	kWatchMgr.RegisterWatchVariable(self, 'm_arrSaveValueQueue', self, ProcessSaveQueue);
	kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_aCurrentStats', self, UpdateUnitHP, 0);
	kWatchMgr.RegisterWatchVariable(m_kUnit.GetPawn(), 'm_iLastInterval_MoveReactionProcessing', self, OnUnitChangedTileDuringMovement);
	kWatchMgr.RegisterWatchVariable(m_kUnit, 'bSteppingOutOfCover', self, OnUnitSteppingOut);
	kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_kCurrAction', self, OnUnitAction);
	kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_aAbilities', self, OnRebuildUnitAbilities);
	kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_iNumAbilitiesAffecting', self, UpdateAbilitiesAffecting);
	kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_aCurrentStats', self, UpdateSightRing, eStat_SightRadius);
	kWatchMgr.RegisterWatchVariable(class'MiniModsTactical'.static.BATTLE(), 'm_kActivePlayer', self, OnActivePlayerChanged);
	kWatchMgr.RegisterWatchVariable(class'MiniModsTactical'.static.BATTLE().m_kSpawnAlienQueue, 'm_arrOverwatches', self, OnDropIn);
	if(!m_kUnit.IsMeleeOnly() && m_kUnit.GetInventory().GetPrimaryWeapon() != none && !m_kUnit.GetInventory().GetPrimaryWeapon().HasProperty(eWP_UnlimitedAmmo))
	{
		kWatchMgr.RegisterWatchVariable(m_kUnit.GetInventory().GetPrimaryWeapon(), 'm_iTurnFired', self, OnAmmoChanged);
	}
	kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_arrMoraleEventsThisTurn', self, LimitChainPanic);
	kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_bPanicMoveFinished', self, OnPanicMoveFinished);
	if(m_kUnit.GetInventory().GetSecondaryWeapon() != none)
	{
		kWatchMgr.RegisterWatchVariable(m_kUnit.GetInventory().GetSecondaryWeapon(), 'm_iTurnFired', self, OnAmmoChanged);
	}
	kWatchMgr.RegisterWatchVariable(self, 'm_kUnitFlag', self, UpdateUnitFlag);
    kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_iBaseCoverValue', self, UpdateCoverState);
    kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_bIsFlying', self, UpdateCoverState);
    kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_bInAscent', self, UpdateCoverState);
    kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_arrBonuses', self, UpdateBuffDebuffs);
    kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_arrPenalties', self, UpdateBuffDebuffs);
    kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_iMovesActionsPerformed', self, UpdateMoves);
    kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_iFireActionsPerformed', self, UpdateMoves);	
    kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_eUsedAbility', self, OnUnitUsedAbility);
    //kWatchMgr.RegisterWatchVariable(m_kUnit, 'm_bInSmokeBomb', self, UpdateSmoke);
	OnActivePlayerChanged();
}
function MMGfxUnitFlag GfxUnitFlag()
{
	if(m_kUnitFlag == none)
	{
		CacheUnitFlag();
	}
	return (m_kUnitFlag != none && m_kUnitFlag.manager != none) ? MMGfxUnitFlag(m_kUnitFlag.manager.GetVariableObject(string(m_kUnitFlag.GetMCPath()), class'MMGfxUnitFlag')) : none;
}
function UpdateUnitFlag()
{
	foreach XComPresentationLayer(XComTacticalController(GetALocalPlayerController()).m_Pres).m_kUnitFlagManager.m_arrFlags(m_kUnitFlag)
	{
		if(m_kUnitFlag.m_kUnit == m_kUnit)
		{
			if(m_bLWRebalance)
			{
				SetTimer(0.30, false, 'SetUnitFlagDelegates');
			}
			else
			{
				SetUnitFlagDelegates();
			}
			GfxUnitFlag().AdjustHitPointsBlockPosition();
			GfxUnitFlag().AdjustOverwatchIconPosition();
			GFxUnitFlag().AdjustBuffIndicatorsPositions();
			break;
		}
	}
}
function CacheUnitFlag()
{
	foreach XComPresentationLayer(XComTacticalController(GetALocalPlayerController()).m_Pres).m_kUnitFlagManager.m_arrFlags(m_kUnitFlag)
	{
		if(m_kUnitFlag.m_kUnit == m_kUnit)
		{
			break;
		}
	}
}
function SetUnitFlagDelegates()
{
	if(class'MiniModsTactical'.default.m_bCompactHPDisplay)
	{
		if(m_kUnitFlag.manager == none)
		{
			SetTimer(0.10, false, GetFuncName());
			return;
		}
		GfxUnitFlag().SetHitPointsDelegate(SetUnitFlagHP);//redirects all ActionScript's SetHitPoints calls to SetUnitFlagHP
		GfxUnitFlag().SetHitPointsPreviewDelegate(SetUnitFlagHPPreview);//redirects all ActionScript's SetHitPoints calls to SetUnitFlagHPPreview
		GfxUnitFlag().SetCoverDelegate(SetUnitFlagCover);//redirects all ActionScript's SetCover calls to SetUnitFlagCover
		m_kUnitFlag.RealizeHitPoints();
		m_kUnitFlag.RealizeCover();
		m_kUnitFlag.RealizeCriticallyWounded();
		m_kUnitFlag.RealizeEKG();
		m_kUnitFlag.RealizeStunned();
	}
}
function UpdateCoverState()
{
}
function UpdateBuffDebuffs()
{
	if(GfxUnitFlag() != none)
		GfxUnitFlag().AdjustBuffIndicatorsPositions();
}
function UpdateMoves()
{
	if(GfxUnitFlag() != none)
		GfxUnitFlag().AdjustBuffIndicatorsPositions();
}
function UpdateUnitHP()
{
	m_iUnitHP = m_kUnit.m_aCurrentStats[eStat_HP];
	if(m_iUnitHP <= 0 && m_kScoutSense != none)
	{
		m_kScoutSense.m_bCueIsValid=false;
		m_kScoutSense.HidePerceptionInfo();
		m_kScoutSense.SetHidden(true);
	}
}
function UpdateScoutSense()
{
	if(m_kScoutSense == none)
	{
		m_kScoutSense = Spawn(class'MMScoutSense_FX', m_kUnit);
		m_kScoutSense.Init(m_kUnit);
		m_kScoutSense.UpdateNearestEnemy();
		m_kScoutSense.UpdateDirection(true);
	}
	else
	{
		m_kScoutSense.UpdateNearestEnemy();
		m_kScoutSense.UpdateDirection();
	}
}
function OnActivePlayerChanged()
{
	local bool bOnInit;

	bOnInit = InStr(GetScriptTrace(), "RegisterWatchVars") != -1;
	UnRegisterWatchVar(m_iWatchActiveUnitHandle);
	m_iWatchActiveUnitHandle = class'Engine'.static.GetCurrentWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(class'MiniModsTactical'.static.BATTLE().m_kActivePlayer, 'm_kActiveUnit', self, OnActiveUnitChanged);
	if(m_kUnit.GetPlayer() != class'MiniModsTactical'.static.BATTLE().m_kActivePlayer && m_kScoutSense != none)
	{
		m_kScoutSense.SetHidden(true);
		m_kScoutSense.HidePerceptionInfo();
	}
	if(!bOnInit)
	{
		m_bUsedGrappleThisTurn = false;
		QueueSaveValue("m_bUsedGrappleThisTurn", "false");
		UpdateTurnsUnseen();
	}
	OnActiveUnitChanged();
}
function OnActiveUnitChanged()
{
	if(class'MiniModsTactical'.static.BATTLE().IsInState('TransitioningPlayers') || GetActiveUnit() == none)
	{
		SetTimer(0.10, false, GetFuncName());
		return;
	}
	UnregisterWatchVar(m_iWatchActiveUnitTravelHandle);
	UnregisterWatchVar(m_iWatchActiveUnitAction);
	UnregisterWatchVar(m_iWatchAbilitiesHUD);
	UpdateDisplayAmmoSpent();
	//LogInternal(GetFuncName() @ GetStateName() @ m_kUnit @  m_kUnit.SafeGetCharacterFullName());
	if(GetActiveUnit() != none)
	{
		if(GetActiveUnit().GetTeam() != m_kUnit.GetTeam())
		{
			m_iWatchActiveUnitTravelHandle = class'Engine'.static.GetCurrentWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(class'MiniModsTactical'.static.BATTLE().m_kActivePlayer.GetActiveUnit().GetPawn(), 'm_iLastInterval_MoveReactionProcessing', self, OnActiveUnitChangedTileDuringMovement);
			m_iWatchActiveUnitAction = class'Engine'.static.GetCurrentWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(class'MiniModsTactical'.static.BATTLE().m_kActivePlayer.GetActiveUnit(), 'm_kCurrAction', self, OnActiveUnitAction);
			if(class'MiniModsTactical'.default.m_bRangeAimModifiers)
			{
				EnableDisableShotStatMod(true);
				UpdateRangeShotModifiers();
			}
		}
		else
		{
			EnableDisableShotStatMod(false);
		}
		if(IsActiveUnit())
		{
			OnUnitActivated();
		}
		else
		{
			if(m_kScoutSense != none && !m_kScoutSense.bHidden && !class'MiniModsTactical'.default.m_bScoutSensePersistentCues)
			{
				m_kScoutSense.SetHidden(true);
				m_kScoutSense.HidePerceptionInfo();
			}
		}
	}
	SetTimer(0.30, false, 'FixShieldPipsPosition');
}
function OnUnitActivated()
{
	OnUnitEndMove();
}
function OnUnitEndMove()
{
	local bool bActivationOnly;

	bActivationOnly = InStr(GetScriptTrace(), "OnUnitActivated") != -1;
	//LogInternal((bActivationOnly ? "OnUnitActivated" : "OnUnitEndMove") @ GetStateName() @ m_kUnit.SafeGetCharacterFullName());		
	if(class'MiniModsTactical'.default.m_bScoutSense && !GRI().GetBattle().IsAlienTurn())
	{
		if(HasScoutSense() && !SquadHasVisibleEnemies())
		{
			AddPerceptionAbility();
			m_iWatchAbilitiesHUD = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES().m_kTacticalHUD.m_kAbilityHUD, 'm_arrAbilities', self, OnRebuiltAbilitiesHUD);
			UpdateScoutSense();
			m_kScoutSense.SetTickIsDisabled(true);
			if(!bActivationOnly)
			{
				m_kScoutSense.ShowPerceptionInfo();
				m_kScoutSense.SetHidden(!m_kScoutSense.m_bCueIsValid || !m_kUnit.IsAliveAndWell());
				if(m_kUnit.GetMoves() == 0 && !m_kUnit.TakenTurnEndingAction())
				{
					PushState('CameraLookAtUnit');
				}
			}
		}
		else if(SquadHasVisibleEnemies())
		{
			HideAllScoutSenseCues();
		}
	}
	m_bGrappleCheckPending = false;
}
/**Don't call this function in a middle of a turn.*/
function UpdateTurnsUnseen()
{
	if(GRI().GetBattle().m_kActivePlayer == GRI().GetBattle().GetAIPlayer() || GRI().GetBattle().m_kActivePlayer == GRI().GetBattle().m_arrPlayers[0])
	{
		if(GRI().GetBattle().m_kActivePlayer == m_kUnit.GetPlayer())
		{
			m_bStartedTurnUnseenToPlayer = m_kUnit.IsVisibleToTeam(eTeam_XCom);
		}
		else
		{
			m_bEndedTurnUnseenToPlayer = m_kUnit.IsVisibleToTeam(eTeam_XCom);
		}
	}
	if(!m_kUnit.IsDormant())
	{
		if(m_bStartedTurnUnseenToPlayer && m_bEndedTurnUnseenToPlayer)
		{
			m_iNumTurnsUnseenToPlayer++;
		}
		else
		{
			m_iNumTurnsUnseenToPlayer = 0;
		}
	}
	QueueSaveValue("m_bStartedTurnUnseenToPlayer", m_bStartedTurnUnseenToPlayer ? "True" : "False");
	QueueSaveValue("m_bEndedTurnUnseenToPlayer", m_bEndedTurnUnseenToPlayer ? "True" : "False");
	QueueSaveValue("m_iNumTurnsUnseenToPlayer", m_iNumTurnsUnseenToPlayer);
}
function OnAmmoChanged()
{
	UpdateAmmoInfo();
	if(m_kUnit.IsVisibleToTeam(eTeam_XCom))
	{
		if(m_kTAmmoInfo.iCurrentAmmoCount < m_kTAmmoInfo.iPreviousAmmoCount)
		{
			m_kTAmmoInfo.iAmmoSpentVisibleToPlayer += (m_kTAmmoInfo.iPreviousAmmoCount - m_kTAmmoInfo.iCurrentAmmoCount);//ammo spent visibly
		}
		else
		{
			m_kTAmmoInfo.iAmmoSpentVisibleToPlayer = 0; //reload
		}
		UpdateDisplayAmmoSpent();
	}
	else if(m_iNumTurnsUnseenToPlayer > 0)
	{
		m_kTAmmoInfo.iAmmoSpentVisibleToPlayer = 0;
	}
	SaveValue("iAmmoSpentVisibleToPlayer", m_kTAmmoInfo.iAmmoSpentVisibleToPlayer);
}
function UpdateAmmoInfo()
{
	local XGWeapon kWeapon;
	local int iAmmoChunk;

	m_kTAmmoInfo.iPreviousAmmoCount = m_kTAmmoInfo.iCurrentAmmoCount;
	kWeapon = m_kUnit.GetInventory().GetActiveWeapon();
	if(class'MiniModsStrategy'.static.IsLongWarBuild())
	{
		iAmmoChunk = GRI().m_kGameCore.GetOverheatIncrement(none, kWeapon.ItemType(), eAbility_ShotStandard, m_kUnit.GetCharacter().m_kChar, false);
	}
	else
	{
		iAmmoChunk = GRI().m_kGameCore.GetAmmoCost(kWeapon.GamePlayType(), 7, m_kUnit.GetCharacter().m_kChar.aUpgrades[113] > 0, m_kUnit.GetCharacter().m_kChar, false);
	}
	if(iAmmoChunk > 0)
	{
		m_kTAmmoInfo.iCurrentAmmoCount = kWeapon.GetRemainingAmmo() / iAmmoChunk;
	}
	QueueSaveValue("iPreviousAmmoCount", m_kTAmmoInfo.iPreviousAmmoCount);
	QueueSaveValue("iCurrentAmmoCount", m_kTAmmoInfo.iCurrentAmmoCount);
}
function UpdateDisplayAmmoSpent()
{
	local UIModGfxTextField gfxAmmoFlagTxt;
	local string strAmmoInfo;

	if(m_kUnitFlag == none || m_kUnitFlag.manager == none)
	{
		return;
	}
	gfxAmmoFlagTxt = GfxUnitFlag().GetAmmoTxtBox();
	if(m_kUnit.GetPlayer() != GRI().GetBattle().GetAIPlayer() || m_kUnit.IsMeleeOnly() || m_kUnit.IsCriticallyWounded())
	{
		gfxAmmoFlagTxt.SetVisible(false);
	}
	else
	{
		strAmmoInfo = Localize("XGAmmo", "m_strType", "XComGame") @ "-" $ m_kTAmmoInfo.iAmmoSpentVisibleToPlayer;
		strAmmoInfo = class'UIUtilities'.static.GetHTMLColoredText(strAmmoInfo, eUIState_Hyperwave);
		gfxAmmoFlagTxt.SetHTMLText(strAmmoInfo);
		gfxAmmoFlagTxt.SetVisible(class'MiniModsTactical'.default.m_bShowAmmoSpentByEnemies && m_kTAmmoInfo.iAmmoSpentVisibleToPlayer > 0);
	}
}
function LimitChainPanic()
{
	local int iEvent;

	`Log(GetFuncName() @ m_kUnit.SafeGetCharacterFullName());
	if(!class'MiniModsTactical'.default.m_bLimitChainPanic)
	{
		return;
	}
	m_kUnit.bIgnoreMoralEvents = true;
	foreach class'MiniModsTactical'.default.IgnoredMoraleEvent(iEvent)
	{
		if(m_kUnit.m_arrMoraleEventsThisTurn.Find(EMoraleEvent(iEvent)) < 0)
		{
			m_kUnit.m_arrMoraleEventsThisTurn.AddItem(EMoraleEvent(iEvent));
		}
	}
}
function OnPanicMoveFinished()
{
	`Log(GetFuncName() @ m_kUnit.m_bPanicMoveFinished @ m_kUnit);
	if(m_kUnit.m_bPanicMoveFinished)
	{
		MoraleCheck(none, true);
	}
}
function MoraleCheck(XGAction kAction, optional bool bPanic)
{
	local int iMoraleEvent;
	local bool bIgnoreEvent;

	SetSquadIgnoreMoraleEvents(false);
	if(!class'MiniModsTactical'.default.m_bLimitChainPanic)
	{
		return;
	}
	iMoraleEvent = -1;
	if(kAction == none)
	{
		`Log(m_kUnit.SafeGetCharacterFullName() $ (bPanic ? ", ally panicked" : ""),,GetFuncName());
		iMoraleEvent = bPanic ? eMoraleEvent_AllyPanics : -1;
	}
	else if(kAction.IsA('XGAction_TakeDamage'))
	{
		if(class'MiniModsTactical'.default.IgnoredMoraleEvent.Find(eMoraleEvent_Wounded) < 0)
		{
			if(XGAction_TakeDamage(kAction).m_kDamageType == class'XComDamageType_Flame' && m_kUnit.GetCharType() != 15)
			{
				iMoraleEvent = XGAction_TakeDamage(kAction).m_kDamageDealer.GetCharacter().HasUpgrade(120) ? eMoraleEvent_MAX : eMoraleEvent_SetOnFire;
				m_kUnit.bForcePanicMove = m_kUnit.OnMoraleEvent(iMoraleEvent);
				`Log(m_kUnit.SafeGetCharacterFullName() $ ", damage taken",,GetFuncName());
			}
			else if(XGAction_TakeDamage(kAction).m_kDamageType != class'XComDamageType_Electropulse')
			{
				`Log(m_kUnit.SafeGetCharacterFullName() $ ", electropulse",,GetFuncName());
				m_kUnit.OnMoraleEvent(eMoraleEvent_Wounded);
			}
		}
		else
		{
			`Log("Panic check disabled by mod",,GetFuncName());
		}
		iMoraleEvent = -1;
	}
	else if(kAction.IsA('XGAction_CriticallyWounded'))
	{
		iMoraleEvent = eMoraleEvent_AllyCritical;
	}
	else if(kAction.IsA('XGAction_BecomePossessed'))
	{
		iMoraleEvent = eMoraleEvent_AllyTurned;
	}
	else if(kAction.IsA('XGAction_Berserk'))
	{
		iMoraleEvent = eMoraleEvent_MutonIntimidate;
	}
	else if(kAction.IsA('XGAction_Death'))
	{
		iMoraleEvent = eMoraleEvent_AllyKilled;
	}
	bIgnoreEvent = class'MiniModsTactical'.default.IgnoredMoraleEvent.Find(iMoraleEvent) != -1;
	if(!bIgnoreEvent)
	{
		`Log(m_kUnit.SafeGetCharacterFullName() $ ", event" @ string(GetEnum(enum'EMoraleEvent', iMoraleEvent)),,GetFuncName());
		if(iMoraleEvent == eMoraleEvent_MutonIntimidate)
		{
			m_kUnit.OnMoraleEvent(eMoraleEvent_MutonIntimidate);
		}
		else if(iMoraleEvent != -1)
		{
			m_kUnit.GetSquad().OnMoraleEvent(EMoraleEvent(iMoraleEvent), m_kUnit);
		}
	}
	else if(iMoraleEvent != -1)
	{
		`Log("Squad-panic check disabled by mod",,GetFuncName());
	}
	SetSquadIgnoreMoraleEvents(true);
}
function SetSquadIgnoreMoraleEvents(bool bIgnore)
{
	local int iMember;
	local XGSquad kSquad;

	kSquad = m_kUnit.GetSquad();
	if(kSquad != none)
	{
		for(iMember=0; iMember < kSquad.GetNumMembers(); ++iMember)
		{
			kSquad.GetMemberAt(iMember).bIgnoreMoralEvents = bIgnore;
		}
	}
}
function PopUpObjectsHP(optional float fRange=960.0)
{
	local XComDestructibleActor kDestructible;
	local string strMsg;
	local XGUnit kActiveUnit;

	kActiveUnit = GRI().GetBattle().m_kActivePlayer.GetActiveUnit();
	if(kActiveUnit.GetPlayer().IsHumanPlayer())
	{
		foreach AllActors(class'XComDestructibleActor', kDestructible)
		{
			if(VSize2D(kDestructible.Location - kActiveUnit.GetLocation()) < fRange)
			{
				strMsg = "HP:" @ kDestructible.TotalHealth;
				WORLDMESSENGER().Message(strMsg, kDestructible.Location,,1,,,,,10.0);
			}
		}
	}
}
function OnActiveUnitChangedTileDuringMovement()
{
	if(class'MiniModsTactical'.default.m_bRangeAimModifiers)
	{
		UpdateRangeShotModifiers();
	}
}
function OnUnitChangedTileDuringMovement()
{
	//m_iLastInterval_MoveReactionProcessing = m_kUnit.GetPawn().m_iLastInterval_MoveReactionProcessing;
	if(m_kUnit.GetPawn().m_iLastInterval_MoveReactionProcessing > 0)
	{
		//MESSENGER().Message(GetFuncName() @ m_kUnit.GetPawn().m_iLastInterval_MoveReactionProcessing @ GetStateName() @ m_kUnit.SafeGetCharacterFullName());
		//LogInternal(GetFuncName() @ m_kUnit.GetPawn().m_iLastInterval_MoveReactionProcessing @ GetStateName() @ m_kUnit.SafeGetCharacterFullName());
		if(class'MiniModsTactical'.default.m_bRangeAimModifiers)
		{
			UpdateRangeShotModifiers();
		}
	}
}
function OnActiveUnitSteppingOut()
{
	if(GetActiveUnit() != m_kUnit && GetActiveUnit().GetAction().IsA('XGAction_BeginMove'))
	{
		OnActiveUnitChangedTileDuringMovement();
	}
}
function OnUnitSteppingOut()
{
	if(m_kUnit.GetAction().IsA('XGAction_BeginMove'))
	{
		if(!IsInState('UnitMoving', true))
		{
			PushState('UnitMoving');
		}
		OnUnitChangedTileDuringMovement();
	}
}
function OnUnitAction()
{
	local XGAction kAction;

	kAction = m_kUnit.GetAction();
	if(kAction != none)
	{
		if( kAction.IsA('XGAction_Fire') && XGAction_Fire(kAction).m_kShot != none)
		{
			if(class'MiniModsTactical'.default.m_bMoreGlamCam)
			{
				DoGlamCamForShot(XGAction_Fire(kAction));
			}
		}
		if( kAction.IsA('XGAction_Fire') && XGAction_Fire(kAction).m_kShot != none && !XGAction_Fire(kAction).m_kShot.IsReactionShot() 
			&& !IsInState('UnitFiring')	&& (class'MiniModsTactical'.default.m_bSequentialOverwatch || class'MiniModsTactical'.default.m_bAlwaysCoveringFire) )
		{
			PushState('UnitFiring');
		}
		else if(kAction.IsA('XGAction_BeginMove') && !IsInState('UnitMoving'))
		{
			PushState('UnitMoving');
			if(class'MiniModsTactical'.default.m_bFasterCCS)
			{
				PushState('ProcessingReaction');
			}
		}
		else if(kAction.IsA('XGAction_EndMove') && GetStateName() == 'UnitMoving')
		{
			PopState();
		}
		else if(XGAction_RemoveAbilityEffect_Hidden(m_kUnit.GetAction()) != none && m_kUnit.GetCharType() == 23 && class'MiniModsTactical'.default.m_bSequentialOverwatch)
		{
			PushState('ProcessingUnstealth');
		}
		else if(kAction.IsA('XGAction_Targeting'))
		{
			if(kAction.m_kUnit.IsAbilityOnCooldown(eAbility_Grapple) && XGAction_Targeting(kAction).m_kShot != none && XGAction_Targeting(kAction).m_kShot.IsA('XGAbility_Grapple'))
			{
				XGAction_Targeting(kAction).m_bFired = true; //this will disable grappling
			}
		}
		else if(kAction.IsA('XGAction_Death') && IsInState('ProcessingUnstealth'))
		{
			m_kUnit.m_kStrangleTarget.m_bStrangleStarted = false;
			m_kUnit.m_kStrangleTarget.IdleStateMachine.CheckForStanceUpdate();
		}
		else if(kAction.IsA('XGAction_Idle') && !IsInState('ProcessingUnstealth'))
		{
			PopAllStates();
			if(m_bGrappleCheckPending)
			{
				GRI().m_kBattle.m_kGlamMgr.StopMatinee();
				m_bGrappleCheckPending = false;
				
				if(VSize(m_kUnit.GetLocation() - m_vGrappleDestination) > 96.0)
				{
					if(m_kUnit.GetPawn().SetLocation(m_vGrappleDestination))
					{
						MESSENGER().Message("Debugging grapple location for" @ m_kUnit.SafeGetCharacterFullName());
						m_kUnit.ProcessNewPosition(true);
					}
				}
				OnUnitEndMove();
			}
		}
		MoraleCheck(kAction);
	}
}
function OnActiveUnitAction()
{
	if( GetActiveUnit() != none && GetActiveUnit() != m_kUnit && GetActiveUnit().GetAction() != none)
	{
		if(GetActiveUnit().GetAction().IsA('XGAction_Fire') && class'MiniModsTactical'.default.m_bSequentialOverwatch)
		{
			//this will disable triggering shots by original ApplyReactionCost
			m_kUnit.m_bReactionFireStatus = false;
		}
	}
}
function OnFireActionStatusChanged();

function OnDropIn()
{
	local array<DelayedOverwatch> arrOverwatches;

	if(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_kSpawnAlienQueue.m_arrOverwatches.Length > 0)
	{
		arrOverwatches = XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_kSpawnAlienQueue.m_arrOverwatches;
		if(arrOverwatches[arrOverwatches.Length - 1].m_arrUnitsTriggeringOverwatch[0] == m_kUnit)
		{
			m_kDelayedOWHandler = arrOverwatches[arrOverwatches.Length - 1];
		}
		if(m_kDelayedOWHandler != none && !IsInState('ProcessingDropIn'))
		{
			PushState('ProcessingDropIn');
		}
	}
	if(m_kUnit.IsMoving() && !IsInState('UnitMoving', true))
	{
		PushState('UnitMoving');
	}
}
function UpdateRangeShotModifiers()
{	
	local int iDist;
	//local int iToHit;
	//local XGAbility_Targeted kShot;
	//local array<XGUnit> arrTargets;

	if(ShouldCalculateRangeModifiers())
	{
		iDist = int(VSize(GetActiveUnit().GetLocation() - m_kUnit.GetLocation()) / 96.0);

		if(!IsActiveUnit())
		{
			RemoveRangeShotModifiers();
			m_kShotStatMod.aTargetStats[eStat_Offense] = -iDist;//FIXME, iDist must replaced by proper function of course
			m_kShotStatMod.aTargetStats[eStat_Defense] = -iDist;//IMPORTANT: defense modifier must be NEGATIVE, as it's modifier of AIM not DEF
			ApplyRangeShotModifiers();
		}
		GetShotModAbility().m_kWeapon = GetActiveUnit().GetInventory().GetActiveWeapon();
		GetShotModAbility().strName = GetShotModAbility().GetWeaponName() @ "vs" @ m_kUnit.SafeGetCharacterFullName();

		//VISUAL DEBUGGING STUFF
		//if(m_kUnit.m_kBehavior != none && !class'MiniModsTactical'.static.BATTLE().m_kPodMgr.IsBusy())
		//{
		//	arrTargets[0] = GetActiveUnit();
		//	kShot = XGAbility_Targeted(XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_kAbilities.SpawnAbility(7, m_kUnit, arrTargets, m_kUnit.GetInventory().GetActiveWeapon(),,true, false));
		//	//arrTargets[0] = m_kUnit;
		//	//kShot = XGAbility_Targeted(XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_kAbilities.SpawnAbility(7, GetActiveUnit(), arrTargets, GetActiveUnit().GetInventory().GetActiveWeapon(),,true, true));
		//	iToHit = kShot.GetHitChance();
		//	WORLDMESSENGER().Message(iDist @ "tiles" @ iToHit $ "\%", m_kUnit.GetLocation(), eColor_Green,,,,,,5.0);
		//	LogInternal(iDist @ "tiles" @ iToHit $ "\%");
		//	kShot.Destroy();
		//}
	}
}
function ClearRangeShotModifiers()
{
	local int i;

	for(i=0; i < 19; ++i)
	{
		GetShotModAbility().aTargetStats[i] = 0;
	}
}
function ApplyRangeShotModifiers()
{
	//the issue with aTargetStats[2] (defense) is that we need to keep it "negative" for UI to treat it as penalty to hit
	//but actually we want to apply a positive defense to m_aCurrentStats
	//therefore function UpdateRangeShotModifiers sets aTargetStats[estat_defense] to negative value
	//but here we revert it temporarily to a positive and then set back to the negative
	if(!m_bRangeModifiersApplied)
	{
		GetShotModAbility().aTargetStats[eStat_Defense] = -GetShotModAbility().aTargetStats[eStat_Defense];
		m_kUnit.AddStatModifiers(GetShotModAbility().aTargetStats);
		GetShotModAbility().aTargetStats[eStat_Defense] = -GetShotModAbility().aTargetStats[eStat_Defense];
		m_bRangeModifiersApplied = true;
		QueueSaveValue("m_bRangeModifiersApplied", "True");
	}
}
function RemoveRangeShotModifiers()
{
	if(m_bRangeModifiersApplied)
	{
		GetShotModAbility().aTargetStats[eStat_Defense] = -GetShotModAbility().aTargetStats[eStat_Defense];
		m_kUnit.RemoveStatModifiers(GetShotModAbility().aTargetStats);
		GetShotModAbility().aTargetStats[eStat_Defense] = -GetShotModAbility().aTargetStats[eStat_Defense];
		m_bRangeModifiersApplied = false;
		QueueSaveValue("m_bRangeModifiersApplied", "False");
	}
}
function EnableDisableShotStatMod(bool bEnable)
{
	if(GetShotModAbility() == none)
	{
		return;
	}
	if(bEnable)
	{
		GetShotModAbility().m_bIgnoreCalculation = false;
		if(!m_kUnit.IsAffectedByAbility(69))
		{
			m_kUnit.AddAbilityAffecting(GetShotModAbility());
		}
		ApplyRangeShotModifiers();
	}
	else 
	{
		GetShotModAbility().m_bIgnoreCalculation = true;
		if(m_kUnit.IsAffectedByAbility(69))
		{
			m_kUnit.RemoveAbilityAffecting(GetShotModAbility());
		}
		RemoveRangeShotModifiers();
	}
}
function XGAbility_Targeted GetShotModAbility()
{
	return m_kShotStatMod;
}
function bool ShouldCalculateRangeModifiers()
{
	return (GetShotModAbility() != none && !GetShotModAbility().m_bIgnoreCalculation);
}
//-----------------------------
//      SEQUENTIAL OW CODE:
//-----------------------------
function bool UnitIsSafeFromReactionFire()
{
	return  (m_kUnit.IsMoving() && m_kUnit.SafeFromReactionFireMinDistToDest()) 
			|| m_kUnit.IsHiding();
}
function bool IsShadowStepping(optional XGUnit kUnit=m_kUnit)
{
	local bool bShadowStepAvailable, bShadowStepValid;

	bShadowStepAvailable = UnitCanShadowStep(kUnit) || (kUnit.m_bDashing && class'MiniModsTactical'.default.m_bDashGivesShadowStep);
	bShadowStepValid = !kUnit.IsAugmented() && !kUnit.IsShiv() && !CharacterCannotShadowStep(kUnit.GetCharacter());
	if(class'MiniModsTactical'.default.m_bShadowStepRequiresDash)
	{
		bShadowStepValid = bShadowStepValid && kUnit.m_bDashing;
	}
	else if(class'MiniModsTactical'.default.m_bShadowStepOnlyOnMove)
	{
		bShadowStepValid = bShadowStepValid && kUnit.IsMoving();
	}
	return class'MiniModsTactical'.default.m_bShadowStep && bShadowStepAvailable && bShadowStepValid;
}
function bool CharacterCannotShadowStep(XGCharacter kChar)
{
	return kChar.IsA('XGCharacter_Cyberdisc') || kChar.IsA('XGCharacter_Mechtoid') || kChar.IsA('XGCharacter_Muton') || kChar.IsA('XGCharacter_Sectopod');
}
/**Checks if a unit is capable of shadowstepping in general.*/
function bool UnitCanShadowStep(XGUnit kUnit)
{
	local bool bHasShadowPerk;
	local int iPerk;

	for(iPerk = 0; iPerk < class'MiniModsTactical'.default.m_arrShadowStepPerks.Length; ++iPerk)
	{
		if(class'MiniModsTactical'.default.m_arrShadowStepPerks[iPerk] > 0 && kUnit.GetCharacter().HasUpgrade(class'MiniModsTactical'.default.m_arrShadowStepPerks[iPerk]))
		{
			bHasShadowPerk = true;
			break;
		}
	}
	return (bHasShadowPerk || class'MiniModsTactical'.default.m_bDashGivesShadowStep) && !CharacterCannotShadowStep(kUnit.GetCharacter());
}
function bool IsShadowStepBuster(XGUnit kUnit)
{
	local bool bShadowBuster;
	local int iPerk;

	for(iPerk = 0; iPerk < class'MiniModsTactical'.default.m_arrShadowBusterPerks.Length; ++iPerk)
	{
		if(class'MiniModsTactical'.default.m_arrShadowBusterPerks[iPerk] > 0 && kUnit.GetCharacter().HasUpgrade(class'MiniModsTactical'.default.m_arrShadowBusterPerks[iPerk]))
		{
			bShadowBuster= true;
			break;
		}
	}
	return bShadowBuster;
}
function int FindSuppressionExecutingEnemy(XGUnit kEnemy)
{
	local int iEnemy;

	for(iEnemy = 0; iEnemy < m_kUnit.m_numSuppressionExecutingEnemies; ++iEnemy)
	{
		if(m_kUnit.m_arrSuppressionExecutingEnemies[iEnemy] == kEnemy)
		{
			return iEnemy;
		}
	}
	return -1;
}
function bool SquadHasVisibleEnemies()
{
	local XGSquad kSquad;
	local array<XGUnit> arrEnemies;
	local int iMember;
	local bool bFound;

	kSquad = m_kUnit.GetPlayer().GetSquad();
	for(iMember=0; iMember < kSquad.GetNumMembers(); ++iMember)
	{
		arrEnemies = kSquad.GetMemberAt(iMember).GetVisibleEnemies();
		if(arrEnemies.Length > 0)
		{
			bFound=true;
			break;
		}
	}
	return bFound;
}
function XGUnit GetActiveUnit()
{
	return class'MiniModsTactical'.static.BATTLE().m_kActivePlayer.m_kActiveUnit;
}
function bool IsActiveUnit()
{
	return m_kUnit == GetActiveUnit();
}
function GetEnemySquad(out XGSquad kOutSquad)
{
	if(m_kUnit.GetPlayer() != none && m_kUnit.GetPlayer() == GRI().GetBattle().GetAIPlayer() )
	{
		kOutSquad = XGBattle_SP(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle).GetHumanPlayer().GetSquad();
	}
	else
	{
		kOutSquad = XGBattle_SP(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle).GetAIPlayer().GetSquad();
	}
}
function XComPresentationLayer PRES()
{
	return class'MiniModsTactical'.static.PRES();
}
function UIMessageMgr MESSENGER()
{
	return PRES().GetMessenger();
}
function UIWorldMessageMgr WORLDMESSENGER()
{
	return PRES().GetWorldMessenger();
}
function XComTacticalGRI GRI()
{
	return class'MiniModsTactical'.static.GRI();
}
static function MMUnitTracker GetUnitTrackerFor(XGUnit kUnit)
{
	local MMUnitTracker kTracker;

	foreach kUnit.GetPawn().BasedActors(class'MMUnitTracker', kTracker)
	{
		if(kTracker.m_kUnit == kUnit)
			break;
	}
	return kTracker;
}
static function InitTrackerFor(XGUnit kUnit, optional out MMUnitTracker kTracker)
{
	kTracker = GetUnitTrackerFor(kUnit);
	if(kTracker != none)
	{
		kTracker.Init(kUnit);
	}
	else
	{
		kTracker = class'Engine'.static.GetCurrentWorldInfo().Spawn(class'MMUnitTracker');
		kTracker.Init(kUnit);
	}
}
function PopAllStates()
{
	while(GetStateName() != Class.Name)
	{
		PopState();
		//SetTickIsDisabled(true);
	}
}
function EnsureScoutAbility()
{
	if(m_kScoutAbility == none)
	{
		m_kScoutAbility = Spawn(class'MMXGAbility_ScoutSense', m_kUnit); //spawn the ability
		m_kScoutAbility.Init(MiniModsTactical(class'UIModManager'.static.GetMutator("MiniModsCollection.MiniModsTactical")).m_iScoutAbilityIdx); //init basic data from TAbility template and do any other "init" stuff
	}
}
function AddPerceptionAbility()
{
	local UITacticalHUD_AbilityContainer kAbilitiesHUD;
	local XGAbility kHUDAbility;
	local GFxObject gfxIcon;
	local array<ASValue> arrParams;
	local bool bFound;

	if(SquadHasVisibleEnemies())
	{
		LogInternal("ERROR: Attempted" @ GetFuncName @ "with enemies already in sight. Skipping....");
		return;
	}
	EnsureScoutAbility();                                               //spawn m_kScoutAbility if needed
	kAbilitiesHUD = PRES().m_kTacticalHUD.m_kAbilityHUD;                //grab the HUD
	m_kUnit.RefreshAbilityList();                                       //clean the array removing any 'none' abilities
	if(m_kUnit.m_iNumAbilities <=62)
	{
		m_kUnit.m_aAbilities[m_kUnit.m_iNumAbilities++] = m_kScoutAbility;  //put the scout XGAbility in unit's arrays
	}
	DisableWatchVar(m_iWatchAbilitiesHUD);                              //ensure no callback after m_arrAbilities change (to prevent double-call)
	kAbilitiesHUD.m_arrAbilities.AddItem(m_kScoutAbility);              //add the ability to the HUD
	kAbilitiesHUD.BuildAbilities(m_kUnit);                              //let the HUD update icons
	EnableWatchVar(m_iWatchAbilitiesHUD);                               //re-enable callbacks
	foreach kAbilitiesHUD.m_arrAbilities(kHUDAbility, m_iScoutAbilitySlot)
	{
		//get the index of just added ability icon (loop is compulsory, cause other mods might have added their abils too)
		if(MMXGAbility_ScoutSense(kHUDAbility) != none && MMXGAbility_ScoutSense(kHUDAbility) == m_kScoutAbility)
		{
			bFound = true;
			break;
		}
	}
	//LogInternal(GetFuncName() @ GetStateName() @ m_kUnit @  m_kUnit.SafeGetCharacterFullName() @ "m_iScoutAbilitySlot="@m_iScoutAbilitySlot);
	if(bFound)
	{
		gfxIcon = PRES().GetHUD().GetVariableObject(string(kAbilitiesHUD.GetMCPath())).GetObject(string(m_iScoutAbilitySlot));
			arrParams.Add(1);
			arrParams[0].Type=AS_String;
			arrParams[0].s="Move";                                          //provide icon identifier,
		gfxIcon.Invoke("SetIconLabel", arrParams);                          //set the new icon	
	}
	else
	{
		m_iScoutAbilitySlot = -1;
	}
}

function OnRebuiltAbilitiesHUD()
{
	if(m_kUnit == GetActiveUnit() && HasScoutSense() && !SquadHasVisibleEnemies())
	{
		if(m_iScoutAbilitySlot != -1 && ( m_iScoutAbilitySlot > (PRES().m_kTacticalHUD.m_kAbilityHUD.m_arrAbilities.Length -1) || PRES().m_kTacticalHUD.m_kAbilityHUD.m_arrAbilities[m_iScoutAbilitySlot] == none) )
		{
			AddPerceptionAbility();
		}
	}
	else
	{
		UnregisterWatchVar(m_iWatchAbilitiesHUD);
		m_iScoutAbilitySlot = -1;
	}
}
function PutAbilityOnCooldown(int iAbility, optional int iCooldown = GRI().m_kGameCore.m_kAbilities.GetTAbility(iAbility).iCooldown)
{
	local XGAbility kAbility;

	if(!m_kUnit.IsAbilityOnCooldown(iAbility))
	{
		m_kUnit.m_aAbilitiesOnCooldown[m_kUnit.m_iNumAbilitiesOnCooldown].iType = iAbility;
		if(iCooldown == GRI().m_kGameCore.m_kAbilities.GetTAbility(iAbility).iCooldown)
		{
			//cooldown cannot match GetTAbility(iAbility).iCooldown cause HUD will ignore the cooldown - not a wise code there
			if(iCooldown > 1 && (iCooldown & 1) == 0)
			{
				--iCooldown; //for even numbers
			}
			else
			{
				++iCooldown;//for odd numbers
			}
		}
		m_kUnit.m_aAbilitiesOnCooldown[m_kUnit.m_iNumAbilitiesOnCooldown].iCooldown = iCooldown;
		++m_kUnit.m_iNumAbilitiesOnCooldown;
		kAbility = m_kUnit.FindAbility(iAbility, none);
		GRI().m_kGameCore.m_kAbilities.RemoveAbilityFromBuiltAbilitiesList(kAbility);
		if(XGAbility_Targeted(kAbility) != none)
		{
			GRI().m_kGameCore.m_kAbilities.RemoveAbility(XGAbility_Targeted(kAbility));
		}
	}
}
function OnRebuildUnitAbilities()
{
	if(!GRI().GetBattle().IsAlienTurn() && m_kUnit == GetActiveUnit())
	{
		UpdateGrappleCharges();
		UpdateGrappleCooldown();
	}
}
function UpdateGrappleCooldown()
{
	local XGAbility kAbility;
	local GFxObject gfxIcon;
	local int idx;
	local array<ASValue> arrParams;
	
	if(m_kUnit.IsAbilityOnCooldown(eAbility_Grapple))
	{
		if(class'MiniModsTactical'.default.m_bNoCostGrapple && class'MiniModsTactical'.default.m_iGrappleCooldown > 0)
		{
			for(idx=0; idx < m_kUnit.m_iNumAbilitiesOnCooldown; ++idx)
			{
				if(m_kUnit.m_aAbilitiesOnCooldown[idx].iType == 6 && m_kUnit.m_aAbilitiesOnCooldown[idx].iCooldown - 1 > class'MiniModsTactical'.default.m_iGrappleCooldown)
				{
					m_kUnit.m_aAbilitiesOnCooldown[idx].iCooldown = Min(class'MiniModsTactical'.default.m_iGrappleCooldown, m_kUnit.m_aAbilitiesOnCooldown[idx].iCooldown);
					break;
				}
			}
			kAbility = m_kUnit.FindAbility(eAbility_Grapple, none);
			if(kAbility != none)
			{
				kAbility.m_bCachedAvailable=false;
				kAbility.m_eAvailableCode = 23;
			}
			idx = PRES().m_kTacticalHUD.m_kAbilityHUD.FindAbilityByType(eAbility_Grapple);
			if(idx != -1 && PRES().m_kTacticalHUD.m_kAbilityHUD.m_arrUIAbilityData[idx].m_bAvailable)
			{
				PRES().m_kTacticalHUD.m_kAbilityHUD.m_arrUIAbilityData[idx].m_bAvailable = false;
				gfxIcon = PRES().GetHUD().GetVariableObject(string(PRES().m_kTacticalHUD.m_kAbilityHUD.GetMCPath())).GetObject(string(idx));
					arrParams.Add(1);
					arrParams[0].Type=AS_Boolean;
					arrParams[0].b=false;
				gfxIcon.Invoke("SetAvailable", arrParams);//set disabled
			}
		}
		else
		{
			GRI().m_kGameCore.m_kAbilities.RemoveAbilityFromCooldown(m_kUnit, eAbility_Grapple);
		}
	}
}
function UpdateGrappleCharges()
{
	local XGAbility kAbility;
	local GFxObject gfxIcon;
	local int idx;
	local array<ASValue> arrParams;

	if(!class'MiniModsTactical'.default.m_bNoCostGrapple)
		return;

	if(GetSavedValue("m_iGrappleCharges") == "")
	{
		//grapple not yet used by the unit (cause there is no saved value for it)
		m_iGrappleCharges = class'MiniModsTactical'.default.m_iGrappleCharges;
	}
	kAbility = m_kUnit.FindAbility(eAbility_Grapple, none);
	if(kAbility != none && !m_kUnit.IsAbilityOnCooldown(eAbility_Grapple))
	{
		if(m_iGrappleCharges <= 0)
		{
			kAbility.m_bCachedAvailable=false;
			kAbility.m_eAvailableCode = 17; //this handles help message
		}
		idx = PRES().m_kTacticalHUD.m_kAbilityHUD.FindAbilityByType(eAbility_Grapple);
		if(idx != -1)
		{
			PRES().m_kTacticalHUD.m_kAbilityHUD.m_arrUIAbilityData[idx].m_iCharge = Max(1, m_iGrappleCharges); //min 1 is to force UI update on swithching units 
			gfxIcon = PRES().GetHUD().GetVariableObject(string(PRES().m_kTacticalHUD.m_kAbilityHUD.GetMCPath())).GetObject(string(idx));
				arrParams.Add(1);
				arrParams[0].Type=AS_String;
				arrParams[0].s=PRES().m_kTacticalHUD.m_kAbilityHUD.m_strChargePrefix $ string(m_iGrappleCharges);
			gfxIcon.Invoke("SetCharge", arrParams);//set "x charges" txt
			if(PRES().m_kTacticalHUD.m_kAbilityHUD.m_arrUIAbilityData[idx].m_bAvailable != (m_iGrappleCharges > 0))
			{
				PRES().m_kTacticalHUD.m_kAbilityHUD.m_arrUIAbilityData[idx].m_bAvailable = m_iGrappleCharges > 0;
					arrParams[0].Type=AS_Boolean;
					arrParams[0].b = m_iGrappleCharges > 0;
				gfxIcon.Invoke("SetAvailable", arrParams);//set disabled/enabled
			}
		}
	}
}

function UnregisterWatchVar(out int iHandle)
{
	if(iHandle != -1)
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(iHandle);
		iHandle = -1;
	}
}
function DisableWatchVar(int iHandle)
{
	if(iHandle != -1)
	{
		WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(iHandle, false);
	}
	else
	{
		LogInternal("Failed to disable watch variable due to idx=-1.", Class.name);
	}
}
function EnableWatchVar(int iHandle)
{
	if(iHandle != -1)
	{
		WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(iHandle, true);
	}
	else
	{
		LogInternal("Failed to re-enable watch variable due to idx=-1.", Class.name);
	}
}

function bool HasScoutSense()
{
	local int iPerception;

	iPerception = class'MiniModsTactical'.default.m_iScoutSensePerk;
	if(iPerception <= 0)
	{
		iPerception = GRI().m_kPerkTree.GetPerkInTree(eSC_Sniper, 1, 2);
	}
	if(iPerception == 0)
	{
		iPerception = GRI().m_kPerkTree.GetPerkInTree(eSC_Sniper, 0, 0);
	}
	return class'MiniModsTactical'.default.m_bScoutSense && m_kUnit.GetCharacter().HasUpgrade(iPerception);
}
function HideAllScoutSenseCues()
{
	local MMScoutSense_FX kSenseCue;

	foreach DynamicActors(class'MMScoutSense_FX', kSenseCue)
	{
		kSenseCue.SetHidden(true);
		kSenseCue.HidePerceptionInfo();
		kSenseCue.SetTickIsDisabled(true);
	}
}
function UpdateAbilitiesAffecting()
{
	if(class'MiniModsTactical'.default.m_bFlashBangBlinds)
	{
		UpdateDisoriented();
	}
}
function UpdateDisoriented()
{
	if(!m_bUnitDisoriented && m_kUnit.IsAffectedByAbility(eAbility_FlashBang))
	{
		m_bUnitDisoriented = true;
		m_kUnit.SetSightRadius(class'MiniModsTactical'.default.m_iDisorientedSightRadius * 3 / 2);
	}
	else if(m_bUnitDisoriented && !m_kUnit.IsAffectedByAbility(eAbility_FlashBang))
	{
		m_bUnitDisoriented = false;
		m_kUnit.SetSightRadius(m_kUnit.GetCharacter().GetCharMaxStat(eStat_SightRadius));
	}
}
function UpdateSightRing()
{
	m_bSightRingVisible = ShouldShowSightRing();
	SetSightRingState(m_bSightRingVisible);
}
simulated function SetSightRingState(bool bEnabled)
{
	local float SightRadiusUnits;

	if(m_kUnit != none)
	{
		SightRadiusUnits = m_kUnit.GetSightRadius() * 64.0;
	}
	if(m_kSightRing != none)
	{
		m_kSightRing.SetScale(SightRadiusUnits * 2.0 / 512.0);
		SetRingColor(m_kSightRing);
		m_kSightRing.SetHidden(!bEnabled);
	}
}
function SetRingColor(StaticMeshComponent kRing)
{
	local LinearColor tColor;
	local MaterialInstanceConstant MIC;

	MIC = MaterialInstanceConstant(kRing.GetMaterial(0));
	if(MIC == none)
	{
		MIC = new (kRing.Outer) class'MaterialInstanceConstant';
		MIC.SetParent(kRing.GetMaterial(0));
		kRing.SetMaterial(0, MIC);
	}

	tColor.R= float(class'MiniModsTactical'.default.m_tSightRingColor.R) / 255.0;
	tColor.G= float(class'MiniModsTactical'.default.m_tSightRingColor.G) / 255.0;
	tColor.B= float(class'MiniModsTactical'.default.m_tSightRingColor.B) / 255.0;
	//ensure basic color in case of lack of config
	if(tColor.R==0.0 && tColor.G==0.0 && tColor.B==0.0)
	{
		tColor.R = 240.0 / 255.0;
		tColor.G = 120.0 / 255.0;
		tColor.B = 40.0 / 255.0;
	}
	MIC.SetVectorParameterValue('Color', tColor);
}
function bool IsInOverwatch(XGUnit kUnit)
{
	return kUnit != none && kUnit.m_aCurrentStats[eStat_Reaction] > 0;
}
function DebugStrangleLocation()
{
	local Vector vTargetLoc, vUnitLoc;
	
	if(m_kUnit.IsAlive() && m_kUnit.m_kStrangleTarget != none)
    {
		vUnitLoc = m_kUnit.GetLocation();
		vTargetLoc = m_kUnit.m_kStrangleTarget.GetLocation();
		vUnitLoc.Z = 0.0;
		vTargetLoc.Z = 0.0;
		if(VSize(vUnitLoc - vTargetLoc) > 48.0)
		{
			vTargetLoc.Z = m_kUnit.GetPawn().Location.Z;
			m_kUnit.GetPawn().SetLocation(vTargetLoc);
			`Log(string(GetFuncName()),, 'MiniMods');
		}
    }
}
event Tick(float fDeltaTime)
{
	if(class'MiniModsTactical'.default.m_bAlienSightRings || class'MiniModsTactical'.default.m_bFlashBangBlinds)
	{
		UpdateSightRing();
	}
	else
	{
		SetSightRingState(false);
	}
}
function UpdateVisibilityIndicator()
{
	local XGUnit kSpotter;
	local UIModGfxTextField gfxIndicator;
	local XComCoverPoint kSpotCover, kUnitCover;
	local Vector vTestLocation, vUnitLocation, vPeekLocation, vStart, vEnd, vHitLoc, vHitNormal;
	local bool bCanSee, bPeekLeftAvailable, bPeekRightAvailable, bOnlyFromSquadSight;
	local TTile SpotTile, UnitTile, PeekTile;
    local int dX, dY, dZ, iToTargetDirection, iToSpotterDirection, iCheck, idx;
    local string sLog;
	local XComTraceManager kTraceMgr;
	local actor kHitActor;
	local array<Vector> arrTestLocations, arrTargetLocations;

	return;
	kTraceMgr= XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kTraceMgr;
    kSpotter = GetActiveUnit();
	if(kSpotter == none || kSpotter.GetAction() == none || !kSpotter.GetAction().IsA('XGAction_Path'))
	{
		return;
	}
	if(m_kUnitFlag != none && m_kUnitFlag.manager != none)
	{
		gfxIndicator = GfxUnitFlag().GetAmmoTxtBox();
	}
	if(gfxIndicator != none)
	{
		if(kSpotter.GetPathingPawn().HasValidNonZeroPath())
		{
			vTestLocation = kSpotter.GetPathingPawn().GetPathDestinationLimitedByCost();
			SnapToTile(vTestLocation, SpotTile);

			vUnitLocation = m_kUnit.GetPawn().Location;
			SnapToTile(vUnitLocation, UnitTile);

			//get relative tile-coord differences between testLoc and unitLoc
			dX = SpotTile.X - UnitTile.X;
			dY = UnitTile.Y - SpotTile.Y;
			dZ = UnitTile.Z - SpotTile.Z;
			//if(Square(dX) + Square(dY) > 49)
			//{
			//	gfxIndicator.SetVisible(false);
			//	return;
			//}
			vTestLocation = kSpotter.GetPathingPawn().GetPathDestinationLimitedByCost();
			SnapToTile(vTestLocation, SpotTile);
			arrTestLocations.AddItem(vTestLocation);
			if(kSpotter.CanUseCover() && class'XComWorldData'.static.GetWorldData().GetCoverPoint(vTestLocation, kSpotCover) )
			{
				for(iCheck=0; iCheck < 2; ++iCheck)
				{
					bPeekLeftAvailable=false;
					bPeekRightAvailable=false;
					if(iCheck == 0)
					{
						class'XComWorldData'.static.GetWorldData().GetCoverDirection(iToTargetDirection, Clamp(dX, -1, 1), 0);
					}
					else
					{
						class'XComWorldData'.static.GetWorldData().GetCoverDirection(iToTargetDirection, 0, Clamp(dY, -1 ,1));
					}				
					if((kSpotCover.Flags & iToTargetDirection) != 0)//cover in direction available
					{
						bPeekLeftAvailable = ((kSpotCover.Flags >> 8) & iToTargetDirection) != 0;
						bPeekRightAvailable = ((kSpotCover.Flags >> 12) & iToTargetDirection) != 0;
					}
					if(bPeekLeftAvailable)
					{
						vPeekLocation = vTestLocation + 96.0 * class'XComWorldData'.static.GetPeekLeftDirection(iToTargetDirection, false);
						SnapToTile(vPeekLocation, PeekTile);
						//WORLDMESSENGER().Message("L", vPeekLocation,,1);
						arrTestLocations.AddItem(vPeekLocation);
					}
					if(bPeekRightAvailable)
					{
						vPeekLocation = vTestLocation + 96.0 * class'XComWorldData'.static.GetPeekRightDirection(iToTargetDirection, false);
						SnapToTile(vPeekLocation, PeekTile);
						//WORLDMESSENGER().Message("R", vPeekLocation,,1);
						arrTestLocations.AddItem(vPeekLocation);
					}
				}
			}
			//cache target default and peek locations
			vUnitLocation = m_kUnit.GetPawn().Location;
			SnapToTile(vUnitLocation, UnitTile);
			arrTargetLocations.AddItem(vUnitLocation);
			if(m_kUnit.CanUseCover() && m_kUnit.IsInCover())
			{
				kUnitCover = m_kUnit.GetCoverPoint();
				for(iCheck=0; iCheck < 2; ++iCheck)
				{
					bPeekLeftAvailable=false;
					bPeekRightAvailable=false;
					if(iCheck == 0)
					{
						class'XComWorldData'.static.GetWorldData().GetCoverDirection(iToSpotterDirection, -Clamp(dX, -1, 1), 0);
					}
					else
					{
						class'XComWorldData'.static.GetWorldData().GetCoverDirection(iToSpotterDirection, 0, -Clamp(dY, -1 ,1));
					}
					if((kUnitCover.Flags & iToSpotterDirection) != 0)//any cover available
					{
						bPeekLeftAvailable = ((kUnitCover.Flags >> 8) & iToSpotterDirection) != 0;
						bPeekRightAvailable = ((kUnitCover.Flags >> 12) & iToSpotterDirection) != 0;
					}
					if(bPeekLeftAvailable)
					{
						vPeekLocation = vUnitLocation + 96.0 * class'XComWorldData'.static.GetPeekLeftDirection(iToSpotterDirection, false);
						SnapToTile(vPeekLocation, PeekTile);
						//WORLDMESSENGER().Message("L", vPeekLocation,,1);
						arrTargetLocations.AddItem(vPeekLocation);
					}
					if(bPeekRightAvailable)
					{
						vPeekLocation = vUnitLocation + 96.0 * class'XComWorldData'.static.GetPeekRightDirection(iToSpotterDirection, false);
						SnapToTile(vPeekLocation, PeekTile);
						//WORLDMESSENGER().Message("R", vPeekLocation,,1);
						arrTargetLocations.AddItem(vPeekLocation);
					}	
				}		
			}
			//----------------------------------------
			sLog = dX @ dY @ dZ;
			//class'XComWorldData'.static.GetWorldData().GetCoverDirection(iCoverDirection, Clamp(dX, -1, 1), 0);
			//sLog @= iCoverDirection >>3 & 1 $ iCoverDirection >> 2 & 1 $ iCoverDirection >> 1 & 1 $ iCoverDirection & 1;
			//class'XComWorldData'.static.GetWorldData().GetCoverDirection(iCoverDirection, 0, Clamp(dY, -1, 1));
			//sLog @= iCoverDirection >>3 & 1 $ iCoverDirection >> 2 & 1 $ iCoverDirection >> 1 & 1 $ iCoverDirection & 1;
			//-----------------------------------------

			foreach arrTestLocations(vStart, iCheck)
			{
				vStart.Z += 64.0;
				foreach arrTargetLocations(vEnd, idx)
				{
					vEnd.Z += 64.0;
					kHitActor = kTraceMgr.XTrace(eXTrace_UnitVisibility_IgnoreAllButTarget, vHitLoc, vHitNormal, vEnd, vStart,,,,,m_kUnit.GetPawn()); 
					if(kHitActor != none && kHitActor != m_kUnit.GetPawn())
					{
						SnapToTile(vHitLoc, SpotTile);
						WORLDMESSENGER().Message(string(kHitActor), vHitLoc,,1);
					}
					else
					{
						bCanSee = true;
						break;
					}
				}
				if(bCanSee)
				{
					sLog @= (iCheck > 0 ? "P" : "");
					sLog @= (idx > 0 ? "p" : "");
					break;
				}
			}
			bOnlyFromSquadSight = VSizeSq(m_kUnit.GetLocation() - vTestLocation) > Square(float(kSpotter.GetSightRadius() * 64));
			//get the XComCoverPoint in the test location (it holds cover flags for the tile)
			if((bCanSee) && !bOnlyFromSquadSight || kSpotter.GetCharacter().HasUpgrade(ePerk_SquadSight))
			{
				gfxIndicator.SetHTMLText(sLog);
				gfxIndicator.SetVisible(true);
			}
		}
		if(!bCanSee)
		{
			gfxIndicator.SetHTMLText("");
			gfxIndicator.SetVisible(false);
		}
	}
}
function SnapToTile(out Vector vLoc, out TTile Tile)
{
	class'XComWorldData'.static.GetWorldData().GetTileCoordinatesFromPosition(vLoc, Tile.X, Tile.Y, Tile.Z);
	vLoc = class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(Tile.X, Tile.Y, Tile.Z);
}
function SnapToFloorTile(out Vector vLoc, out TTile Tile)
{
	class'XComWorldData'.static.GetWorldData().GetFloorTileForPosition(vLoc, Tile.X, Tile.Y, Tile.Z);
	vLoc = class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(Tile.X, Tile.Y, Tile.Z);
}

function UnitPeekSide GetRequiredPeekSide(int iToTargetDirection, int iToSpotterDirection)
{
	local UnitPeekSide ePeek;

	ePeek = eNoPeek;
	switch(iToTargetDirection)
	{
	case 1://North
		if(iToSpotterDirection == 4) //East
			ePeek = ePeekRight;
		else if(iToSpotterDirection == 8) //West
			ePeek = ePeekLeft;
		break;
	case 2://South
		if(iToSpotterDirection == 4) //East
			ePeek = ePeekLeft;
		else if(iToSpotterDirection == 8) //West
			ePeek = ePeekRight;
		break;
	case 4://East
		if(iToSpotterDirection == 1) //North
			ePeek = ePeekLeft;
		else if(iToSpotterDirection == 2) //South
			ePeek = ePeekRight;
		break;
	case 8://West
		if(iToSpotterDirection == 1) //North
			ePeek = ePeekRight;
		else if(iToSpotterDirection == 2) //South
			ePeek = ePeekLeft;
		break;
	default:
		ePeek = eNoPeek;
	}
	return ePeek;
}
function bool TraceVisibilityTileToTile(TTile FromTile, TTile TargetTile)
{
	local XComTraceManager kTraceMgr;
	local Actor kHitActor;
	local Vector vHitLoc, vHitDir, vStart, vEnd;

	kTraceMgr= XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kTraceMgr;
	vStart = class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(FromTile.X, FromTile.Y, FromTile.Z);
	vEnd =class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(TargetTile.X, TargetTile.Y, TargetTile.Z);
	do{
		kHitActor = kTraceMgr.XTrace(eXTrace_UnitVisibility, vHitLoc, vHitDir, vEnd, vStart); 
		if(kHitActor != m_kUnit.GetPawn())
		{
			WORLDMESSENGER().Message(string(kHitActor), vHitLoc);
		}
	}until(kHitActor == m_kUnit.GetPawn() || kHitActor == none);
	return kHitActor == m_kUnit.GetPawn() || kHitActor == none;
}
function bool IsLocInSmoke(Vector vLoc, optional bool bOnlyDenseSmoke)
{
	local XGVolumeMgr kVolMgr;
	local XGVolume kVolume;
	local bool bFound;
	local int iVolume;

	kVolMgr = class'MiniModsTactical'.static.BATTLE().m_kVolumeMgr;
	for(iVolume=0; iVolume < kVolMgr.m_iNumVolumes; ++iVolume)
	{
		kVolume = kVolMgr.m_aVolumes[iVolume];
		if( (kVolume.GetType() == eVolume_CombatDrugs || kVolume.GetType() == eVolume_Smoke) && (!bOnlyDenseSmoke || kVolume.m_kInstigator.GetCharacter().HasUpgrade(52)) && kVolume.IsPointInVolume(vLoc))
		{
			bFound=true;
			break;
		}
	}
	return bFound;
}
function bool ShouldShowSightRing()
{
	local bool bShow;
	local TTile tDestTile;
	local Vector vDestLoc;
	
	if(m_kUnit == none || !m_kUnit.IsVisibleToTeam(eTeam_XCom) || m_kUnit.IsDead() || m_kUnit.IsCriticallyWounded())
	{
		return false;
	}
	if(class'MiniModsTactical'.default.m_bAlienSightRings)
	{
		if(class'MiniModsTactical'.default.m_bAlienSightRingsPermanent)
		{
			bShow = m_kUnit.m_eTeam == eTeam_Alien;
		}
		else if(GetActiveUnit() != none && GetActiveUnit().m_eTeam == eTeam_XCom && m_kUnit.m_eTeam == eTeam_Alien && GetActiveUnit().GetAction().IsA('XGAction_Path') )
		{
			vDestLoc = GetActiveUnit().GetPathingPawn().GetPathDestinationLimitedByCost();
			SnapToTile(vDestLoc, tDestTile);
			bShow = VSizeSq(vDestLoc - m_kUnit.GetLocation()) > 18*18*96*96;
			//bShow = class'XComWorldData'.static.GetWorldData().CanSeeActorToTile(m_kUnit, tDestTile.X, tDestTile.Y, tDestTile.Z);
			//bShow = class'XComWorldData'.static.GetWorldData().CanSeeActorToLocation(m_kUnit, vDestLoc);
		}
		if(bShow && class'MiniModsTactical'.default.m_bAlienSightRingsOnlyXcomTurn)
		{
			bShow = !GRI().GetBattle().IsAlienTurn();
		}
	}
	if(!bShow && class'MiniModsTactical'.default.m_bFlashBangBlinds)
	{
		bShow = m_bUnitDisoriented;
	}
	return bShow;	
}

function SetUnitFlagHP(int iCurrent, int iMax, optional int iBase)
{
	local MMGfxUnitHPBar gfxHPBar;
	local MMGfxUnitFlag gfxFlag;

	if(m_kUnitFlag == none || m_kUnitFlag.manager == none)
	{
		return;
	}
	gfxFlag = GfxUnitFlag();
	gfxFlag.HitPointsBlockMC().GetObject("hitPoints").SetVisible(false);
    gfxFlag.SetFloat("_cachedCurrHP", float(iCurrent));
    gfxFlag.SetFloat("_cachedCurrHPmax", float(iMax));
	if(iBase > 0)
	{
	    gfxFlag.SetFloat("_cachedBaseHP", float(iBase));
	}
	else
	{
		iBase = gfxFlag.GetFloat("_cachedBaseHP");
	}
	gfxHPBar = gfxFlag.GetHPBar();
	if(iCurrent < 0 && iMax < 0 || m_kUnit.IsCriticallyWounded() || m_kUnit.m_bStunned)
	{
		gfxHPBar.SetVisible(false);		
	}
	else
	{
		gfxHPBar.SetVisible(true);		
		gfxHPBar.SetArmorPct(float(iCurrent) / float(iMax));
		if(iBase > 0 && iCurrent > iBase)
		{
			gfxHPBar.SetHPPct(float(iBase) / float(iMax));
		}
		else
		{
			gfxHPBar.SetHPPct(float(iCurrent) / float(iMax));
		}
		if(class'MMGfxUnitHPBar'.default.SHOW_MAX_HP)
		{
			gfxHPBar.SetHPTxt(iCurrent@"/"@iMax);
		}
		else
		{
			gfxHPBar.SetHPTxt(string(iCurrent));
		}
	}
	if(m_kUnit.m_eTeam == eTeam_XCom)
	{
		if(m_kUnit.GetMoves() == 0)
		{
			gfxHPBar.ARMOR_COLOR_STRING = gfxHPBar.ARMOR_COLOR_STRING_INACTIVE;
			gfxHPBar.BASE_COLOR_STRING = gfxHPBar.BASE_COLOR_STRING_INACTIVE;
			gfxHPBar.TXT_COLOR_STRING = gfxHPBar.TXT_COLOR_STRING_INACTIVE;
			gfxHPBar.HP_ICON_COLOR_HEX = gfxHPBar.HP_ICON_COLOR_HEX_INACTIVE;
		}
		else
		{
			gfxHPBar.ARMOR_COLOR_STRING = gfxHPBar.ARMOR_COLOR_STRING_XCOM;
			gfxHPBar.BASE_COLOR_STRING = gfxHPBar.BASE_COLOR_STRING_XCOM;
			gfxHPBar.TXT_COLOR_STRING = gfxHPBar.TXT_COLOR_STRING_XCOM;
			gfxHPBar.HP_ICON_COLOR_HEX = gfxHPBar.HP_ICON_COLOR_HEX_XCOM;
		}
	}
	gfxHPBar.RealizeColors();
	gfxFlag.AdjustHitPointsBlockPosition();
}

function SetUnitFlagHPPreview(optional int iPossibleDmg)
{
	local MMGfxUnitHPBar gfxHPBar;
	local MMGfxUnitFlag gfxFlag;
	local int iNewHP, iHP, iMaxHP;

	if(m_kUnitFlag == none || m_kUnitFlag.manager == none)
	{
		return;
	}
	gfxFlag = GfxUnitFlag();
	gfxHPBar = gfxFlag.GetHPBar();
	iHP = m_kUnit.GetUnitHP();
	iMaxHP = m_kUnit.GetUnitMaxHP();
	iNewHP = Clamp(iHP + iPossibleDmg, 0, iMaxHP);
	if(iPossibleDmg == 0)
	{
		//gfxHPBar.GetObject("bg").SetFloat("_width", gfxFlag.m_fHPBarWidth);
		gfxHPBar.m_gfxDmg.SetVisible(false);
		gfxHPBar.m_gfxKillShotIcon.SetVisible(false);
		gfxHPBar.m_gfxHPIcon.SetVisible(true);
		SetUnitFlagHP(iHP, iMaxHP);
		PRES().UnsubscribeToUIUpdate(gfxHPBar.AnimateDmgPreview);
	}
	else 
	{
		SetUnitFlagHP(iNewHP, iMaxHP);
		gfxHPBar.SetDmgPreviewColor(iPossibleDmg < 0 ? gfxHPBar.DMG_COLOR_STRING : gfxHPBar.HEAL_COLOR_STRING);
		if(iPossibleDmg < 0)
		{
			gfxHPBar.SetDmgPct( FMin(Abs(iPossibleDmg), float(iHP)) / float(iMaxHP) );
			gfxHPBar.m_gfxDmg.SetFloat("_x", FMax(0.0, gfxHPBar.BAR_WIDTH * float(iNewHP) / float(iMaxHP)));
			gfxHPBar.SetHPTxt(iNewHP @ m_kUnit.m_sDamageImage @ Min(iHP, -iPossibleDmg));
			if(iHP + iPossibleDmg <= 0)
			{
				gfxHPBar.m_gfxHPIcon.SetVisible(false);
				gfxHPBar.m_gfxKillShotIcon.SetVisible(true);
			}
		}
		else
		{
			gfxHPBar.SetDmgPct(FMin(Abs(iPossibleDmg), float(iMaxHP - iHP)) / float(iMaxHP));
			gfxHPBar.m_gfxDmg.SetFloat("_x", gfxHPBar.BAR_WIDTH * m_kUnit.GetHealthPct());
			gfxHPBar.SetHPTxt(iNewHP @ "+" @ Min(iMaxHP - iHP, iPossibleDmg));
		}
		gfxHPBar.m_gfxDmg.SetVisible(true);
		PRES().SubscribeToUIUpdate(gfxHPBar.AnimateDmgPreview);
//		gfxHPBar.SetBgVisibility(true);
//		gfxHPBar.SetBgPct(m_kUnit.GetHealthPct());
		if(m_kUnit.GetUnitHP() > m_kUnit.GetCharacter().GetCharMaxHP())
		{
//			gfxHPBar.SetBgColor(gfxHPBar.ARMOR_COLOR_STRING);
		}
		else
		{
//			gfxHPBar.SetBgColor(gfxHPBar.BASE_COLOR_STRING);
		}
	}
}
function SetUnitFlagCover(string State, bool bIsFlanked)
{
	local array<ASValue> arrParams;
	local MMGfxUnitFlag gfxFlag;

	gfxFlag = GfxUnitFlag();
	arrParams.Length = 2;
	arrParams[0].Type = AS_String;
	arrParams[0].s = State;
	arrParams[1].Type = AS_Boolean;
	arrParams[1].b = bIsFlanked;
	gfxFlag.GetObject("coverStatusObj").Invoke("setCoverStatus", arrParams);
	gfxFlag.AdjustOverwatchIconPosition();
}
function FixShieldPipsPosition()
{
	if(GfxUnitFlag() != none)
	{
		GfxUnitFlag().AdjustHitPointsBlockPosition();
		GfxUnitFlag().AdjustBuffIndicatorsPositions();
	}
}
function FixOWIconPosition()
{
	if(GfxUnitFlag() != none)
	{
		GfxUnitFlag().AdjustOverwatchIconPosition();
	}
}
function DoGlamCamForShot(XGAction_Fire kShot)
{
	local XComGlamManager kGlamMgr;
	local KineticStrikeAttackInfo AttackInfo;
	local Vector vTargetLoc;
	local Rotator vTargetRot;

	if(IsGlamCamEnabledForAction(kShot))
	{
		kGlamMgr = GRI().m_kBattle.m_kGlamMgr;
		kGlamMgr.FlushMatineeCache();
		kGlamMgr.FocusUnit = m_kUnit;
		kGlamMgr.FocusAction = kShot;
		kGlamMgr.FocusTarget = kShot.m_kTargetedEnemy;
		kGlamMgr.FocusLocation = kShot.GetTargetLoc();
		kGlamMgr.m_bPlayerTargetingForceStartCachingCams = false;
		if(kShot.m_kShot.iType == 81)
		{
			vTargetLoc = kShot.GetTargetLoc();
			Class'XComWorldData'.static.GetWorldData().GetKineticStrikeInfoFromTargetLocation(m_kUnit.GetPawn(), vTargetLoc, AttackInfo);
			if(AttackInfo.AttackUnit != none && XGUnit(AttackInfo.AttackUnit).GetCharType() != 15 && XGUnit(AttackInfo.AttackUnit).GetCharType() != 16 && XGUnit(AttackInfo.AttackUnit).GetCharType() != 21)
			{
				kGlamMgr.CacheKineticStrikeCam(m_kUnit, XGUnit(AttackInfo.AttackUnit));
				kGlamMgr.FocusTarget = XGUnit(AttackInfo.AttackUnit);
				kGlamMgr.GetFiringCamTransform(kShot, vTargetLoc, vTargetRot);
				kGlamMgr.MatineeCache[kGlamMgr.MatineeCache.Length-1].Location = vTargetLoc;
				kGlamMgr.MatineeCache[kGlamMgr.MatineeCache.Length-1].Rotation = vTargetRot;
				kGlamMgr.MatineeCache[kGlamMgr.MatineeCache.Length-1].SeqTags[0] = "CIN_Powerfist";
				kGlamMgr.TrySpecificGlamCam(GLAMCAM_KineticStrike, m_kUnit, false);
			}
		}
		else
		{
			kGlamMgr.CacheFiringCam(kShot);
			if(kShot.m_kShot.IsRocketShot())
			{
				kGlamMgr.MatineeCache[kGlamMgr.MatineeCache.Length-1].Location = kGlamMgr.GetGlamCamLoc(m_kUnit);
			}
			kGlamMgr.TrySpecificGlamCam(GLAMCAM_Firing, m_kUnit, false);
		}
	}
}
function bool IsGlamCamEnabledForAction(XGAction_Fire kShot)
{
	if(kShot.IsCurrentAbilityGrapple())
	{
		return class'MiniModsTactical'.default.m_bGlamCam_Grapple;
	}
	else if(kShot.m_kShot.IsRocketShot())
	{
		return class'MiniModsTactical'.default.m_bGlamCam_Rocket;
	}
	else if(kShot.m_kShot.iType == 81 || kShot.m_kShot.IsGrenadeAbility())
	{
		return true;
	}
	return false;
}
function OnUnitUsedAbility()
{
	if(m_kUnit.m_eUsedAbility == eAbility_Overwatch && m_kUnit.GetCharacter().HasUpgrade(ePerk_Sentinel))
	{
		m_kUnit.PlaySound(SoundCue(DynamicLoadObject("ArclinonSoundPack.Sentinel_Overwatch_Cue", class'SoundCue')));
	}
}
state CameraLookAtUnit
{
	event PoppedState()
	{
		if(HasScoutSense() && m_kUnit.GetMoves() == 0 && !m_kScoutSense.m_bCueIsValid)
		{
			m_kScoutSense.HidePerceptionInfo();
		}
	}
Begin:
	GRI().m_kCameraManager.AddDyingUnit(m_kUnit);
	while(GRI().m_kCameraManager.m_aDyingUnits[0] != m_kUnit)
	{
		Sleep(0.10);
	}
	Sleep(2.0);
	GRI().m_kCameraManager.RemoveDyingUnit(m_kUnit);
	GRI().GetBattle().m_kActivePlayer.GetActiveUnit().MoveCursorToMe();
	PRES().GetCamera().m_kScrollView.SetLocationTarget(GRI().GetBattle().m_kActivePlayer.GetActiveUnit().GetCurrentView().GetLookAt());
	PRES().GetCamera().SetCurrentView(GRI().GetBattle().m_kActivePlayer.GetActiveUnit().GetCurrentView());
	PopState();
}
state UnitMoving
{
	event PushedState()
	{
		//MESSENGER().Message(m_kUnit.SafeGetCharacterFullName() @ GetStateName() @ GetFuncName());
		//LogInternal(GetFuncName() @ GetStateName() @ m_kUnit @ m_kUnit.SafeGetCharacterFullName());		
		if(m_kScoutSense != none)
		{
			m_kScoutSense.SetTickIsDisabled(false);
			m_kScoutSense.HidePerceptionInfo();
		}
	}
	event PoppedState()
	{
		SetTimer(0.30, false, 'OnUnitEndMove'); //MUST be a timer, direct call causes runaway loop (dunno why)
	}
	function OnUnitChangedTileDuringMovement()
	{
		//MESSENGER().Message(m_kUnit.SafeGetCharacterFullName() @ "moving, tile" @ m_kUnit.GetPawn().m_iLastInterval_MoveReactionProcessing @ (UnitIsSafeFromReactionFire() ? "SAFE FROM OW" : "OW RISK"));
		super.OnUnitChangedTileDuringMovement();
		if(class'MiniModsTactical'.default.m_bSequentialOverwatch && !UnitIsSafeFromReactionFire())
		{
			if(GetStateName() == 'ProcessingReaction')
			{
				//this is to abort current reaction processing if unit has already reached new tile
				PopState();
			}
			PushState('ProcessingReaction');
		}
	}
Begin:
	m_bFirstTileReactionCheckDone=false;
	while(m_kUnit.IsMoving() && !m_kUnit.GetAction().IsA('XGAction_EndMove'))
	{
		if(int(m_kUnit.GetPawn().m_fDistanceMovedAlongPath / 96.0) == 1 && !m_bFirstTileReactionCheckDone)
		{
			OnUnitChangedTileDuringMovement();
			m_bFirstTileReactionCheckDone = true;
		}
		Sleep(0.0);
	}
	Sleep(0.10);
	PopState();
}
state UnitFiring
{
	event PushedState()
	{
		//LogInternal(GetFuncName() @ GetStateName() @ m_kUnit @ m_kUnit.SafeGetCharacterFullName());
		UnregisterWatchVar(m_iWatchFireActionStatus);
		m_iWatchFireActionStatus = class'Engine'.static.GetCurrentWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(XGACtion_Fire(m_kUnit.GetAction()), 'm_eFireActionStatus', self, OnFireActionStatusChanged);
		m_bForceNextReactionCheck = false; 
	}
	function bool ShotTriggersCovFire(XGAbility_Targeted kShot)
	{
		switch(kShot.GetType())
		{
			case 6: //grapple
			case 20: //steady weapon
			case 22: //reaction shot
			case 27: //take cover
			case 33: //reload
			case 70: //civ take cover
			case 94: //psi reflect
				return false;
			default:
				break;
		}
		return !GRI().m_kGameCore.m_kAbilities.AbilityHasProperty(kShot.GetType(), 8);
	}
	function OnFireActionStatusChanged()
	{
		local XGAction_Fire kFire;
		local int iType;

		kFire = XGAction_Fire(m_kUnit.GetAction());
		iType = kFire.m_kShot != none ? kFire.m_kShot.GetType() : 0;
		//MESSENGER().Message(m_kunit.SafeGetCharacterFullName() @ GetStateName () @ kFire.m_kShot.GetType() @ kFire.m_eFireActionStatus);
		if(iType == eAbility_Grapple || iType == eAbility_PsiReflect)
		{
			if(!m_bGrappleCheckPending && kFire.m_kshot.IsA('XGAbility_Grapple'))
			{
				m_bGrappleCheckPending = true;
				m_bUsedGrappleThisTurn = true;
				m_vGrappleDestination = m_kUnit.GetPathingPawn().Path.GetPoint(m_kUnit.GetPathingPawn().Path.PathSize() -1);
				SaveValue("m_bUsedGrappleThisTurn", m_bUsedGrappleThisTurn ? "true" : "false");
				if(class'MiniModsTactical'.default.m_bNoCostGrapple)
				{
					--m_iGrappleCharges;
					SaveValue("m_iGrappleCharges", m_iGrappleCharges);
					PutAbilityOnCooldown(eAbility_Grapple);
				}
			}
			return;
		}
		switch(kFire.m_eFireActionStatus)
		{
		case 1:
			//LogInternal("m_eFireActionStatus" @ int(kFire.m_eFireActionStatus) @ "shot type" @ kFire.m_kShot.GetType());
			if(kFire.m_kShot != none && !kFire.m_kShot.IsReactionShot() && ShotTriggersCovFire(kFire.m_kShot))
			{
				if(class'MiniModsTactical'.default.m_bSequentialOverwatch)
				{
					//MESSENGER().Message("m_eFireActionStatus" @ kFire.m_eFireActionStatus @ "shot type" @ kFire.m_kShot.GetType());
					PushState('ProcessingCoveringFire');
				}
				else if(class'MiniModsTactical'.default.m_bAlwaysCoveringFire)
				{
					m_kUnit.ApplyReactionCost(0, true, false, false);
				}
			}
			break;
		case 9:
			//LogInternal("m_eFireActionStatus" @ int(kFire.m_eFireActionStatus) @ "shot type" @ kFire.m_kShot.GetType());
			if(kFire.m_kShot != none && kFire.m_kShot.IsReactionShot() 
				&& !m_kUnit.m_bFiredReactiveTargeting && !kFire.IsHit())
			{
				//MESSENGER().Message("m_eFireActionStatus" @ kFire.m_eFireActionStatus @ "shot type" @ kFire.m_kShot.GetType());
				GetUnitTrackerFor(kFire.m_kShot.GetPrimaryTarget()).m_bForceNextReactionCheck = true;
			}
			if( !kFire.m_kShot.IsReactionShot()
				&& kFire.m_kShot.GetPrimaryTarget() != none
				&& kFire.m_kShot.GetPrimaryTarget().GetCharacter().HasUpgrade(ePerk_ReactiveTargetingSensors)
				&& !kFire.m_kShot.GetPrimaryTarget().m_bFiredReactiveTargeting)
			{
				kFire.m_kShot.GetPrimaryTarget().m_bReactionFireStatus = true; //enable Reactive Targeting shot
			}
			else if(class'MiniModsTactical'.default.m_bSequentialOverwatch && m_kUnit.m_bFiredReactiveTargeting)
			{
				m_kUnit.m_bReactionFireStatus = false; //reset after Reactive shot
			}
			break;
		case 13:
			if(GRI().m_kBattle.m_kGlamMgr.m_bEnableUnitRushCam)
			{
				GRI().m_kBattle.m_kGlamMgr.StopMatinee();
			}
		default:
			break;
		}
	}
	event PoppedState()
	{
		//LogInternal(GetFuncName() @ GetStateName() @ m_kUnit @ m_kUnit.SafeGetCharacterFullName());		
		UnregisterWatchVar(m_iWatchFireActionStatus);
	}
Begin:
	while(m_kUnit.GetAction().IsA('XGAction_Fire'))
	{
		Sleep(0.0);
	}
	if(class'MiniModsTactical'.default.m_bFasterRapidReaction && m_kUnit.m_kRapidReactionUnit != none)
	{
		m_kUnit.m_kRapidReactionUnit = none; //this will allow immediate next rapid-reaction-shot
	}
	PopState();
}
state ProcessingReaction
{
	event  PushedState()
	{
		//MESSENGER().Message(m_kUnit.SafeGetCharacterFullName() @ GetStateName() @ GetFuncName());
	//LogInternal(GetFuncName() @ GetStateName() @ m_kUnit @ m_kUnit.SafeGetCharacterFullName());		
		m_bForceNextReactionCheck = false;
		m_iLastInterval_MoveReactionProcessing = m_kUnit.GetPawn().m_iLastInterval_MoveReactionProcessing;
	}
	event PoppedState()
	{
		//MESSENGER().Message(m_kUnit.SafeGetCharacterFullName() @ GetStateName() @ GetFuncName());
		m_arrOverwatchingEnemies.Length=0;
		//LogInternal(GetFuncName() @ GetStateName() @ m_kUnit @ m_kUnit.SafeGetCharacterFullName());		
	}
	function bool InitialValidationPassed()
	{
		return !m_kUnit.IsHiding();
	}
	function bool IsEnemyShootingThroughSmoke(XGUnit kEnemy)
	{
		local Vector vStart, vEnd, vLoc, vDir;
		local int iTiles, iTilesDistance/*, iX, iY, iZ, */;
		local bool bSmoke;
		
		bSmoke = false;
		if(class'MiniModsTactical'.default.m_bSmokeBlocksReactionFire)
		{
			vStart = kEnemy.GetLocation();
			vEnd = m_kUnit.GetLocation();
			vDir = Normal(vEnd - vStart);
			if(VSize(vEnd - vStart) > (class'MiniModsTactical'.default.m_fReactionDistanceThroughSmoke * 96.0))
			{
				iTilesDistance = int(VSize(vEnd - vStart) / 96.0);
				vLoc = vStart;
				for(iTiles=0; iTiles <= iTilesDistance; ++iTiles)
				{
					if(IsLocInSmoke(vLoc, class'MiniModsTactical'.default.m_bSmokeBlocksReactionFire_DenseOnly))
					{
						MESSENGER().Message(kEnemy.SafeGetCharacterFullName() @ class'MiniModsTactical'.default.m_strReactionBlockedBySmoke);
						bSmoke = true;
						break;
					}
					vLoc = vLoc + vDir * 96.0;
					//class'XComWorldData'.static.GetWorldData().GetTileCoordinatesFromPosition(vLoc, iX, iY, iZ);
					//if(class'XComWorldData'.static.GetWorldData().TileContainsSmoke(iX, iY, iZ))
				}
			}
		}
		return bSmoke;
	}
	function bool IsSentinelValid(XGUnit kUnit)
	{
		return false; //this 'state' is for movement (2 sentinel shots on the same tile would not trigger anyway)
	}
	function bool IsValidOverwatcher(XGUnit kEnemy)
	{
		local bool bReactionStatusOK;

		bReactionStatusOK = IsInOverwatch(kEnemy) && ( !IsInState('UnitMoving', true) || m_iLastInterval_MoveReactionProcessing > 0 );
		
		return kEnemy.IsAlert() && (bReactionStatusOK || kEnemy.GetCharacter().HasUpgrade(40) || kEnemy.HasSentinelModule()) && kEnemy.GetNumberOfSuppressionTargets() == 0 && kEnemy.IsEnemyVisible(m_kUnit) && !IsEnemyShootingThroughSmoke(kEnemy);
	}
	function bool OnlyCoveringFire()
	{
		return false;
	}
	function bool ShouldWaitBeforeNextShot()
	{
		return false;
	}
	function bool ShouldSplitSentinelShots()
	{
		return class'MiniModsTactical'.default.m_bSplitSentinelOWShots;
	}
	function float GetPauseTimeBeforNextShot()
	{
		return 0.10;
	}
	function XGUnit GetStrangleTarget()
	{
		return none;
	}
	function XGUnit GetNextOverwatcherInQueue()
	{
		if(m_arrOverwatchingEnemies.Length > 0)
		{
			return m_arrOverwatchingEnemies[m_arrOverwatchingEnemies.Length - 1];
		}
		return none;
	}
	function bool ForceBreakReactionLoop()
	{
		if( int(m_kUnit.GetPawn().m_fDistanceMovedAlongPath / 96.0) > m_iLastInterval_MoveReactionProcessing || UnitIsSafeFromReactionFire() || !m_kUnit.IsAliveAndWell())
		{
			return true;
		}
		return false;
	}
	function bool IsForcedNextReactionCheck()
	{
		return m_bForceNextReactionCheck && GetNextOverwatcherInQueue() != none;
	}
	function UpdateUnitHP()
	{
		super.UpdateUnitHP();
		if(m_iUnitHP > 0 && class'MiniModsTactical'.default.m_bSequentialOverwatch)
		{
			m_bForceNextReactionCheck = GetNextOverwatcherInQueue() != none;
		}
	}
	function bool UnitIsSafeFromReactionFire()
	{
		return super.UnitIsSafeFromReactionFire();

	}

	function CheckForPopup(XGUnit kUnit)
	{
		if(IsShadowStepping())
		{
			if(kUnit == m_kUnit && m_arrOverwatchingEnemies.Length > 0)
			{
				if(WORLDMESSENGER().m_arrMsgs.Find('m_sID', "ShadowStep_"$GetRightMost(m_kUnit)) < 0)
				{
					WORLDMESSENGER().Message(class'MiniModsTactical'.default.m_strShadowStepping, m_kUnit.GetLocation(),,,"ShadowStep_"$GetRightMost(m_kUnit));
				}
			}
			else if(kUnit != m_kUnit && IsShadowStepBuster(kUnit))
			{
				WORLDMESSENGER().Message(class'MiniModsTactical'.default.m_strShadowStepBuster, kUnit.GetLocation());
			}
		}
	}

	function CacheCurrentOverwatchers()
	{
		local XGSquad kEnemySquad;
		local int iEnemy;
		local XGUnit kEnemy;
		local array<XGUnit> arrSentinels;

		GetEnemySquad(kEnemySquad);
		m_arrOverwatchingEnemies.Length = 0;
		for(iEnemy=0; iEnemy<kEnemySquad.GetNumMembers(); ++iEnemy)
		{
			kEnemy = kEnemySquad.GetMemberAt(iEnemy);
			if(IsValidOverwatcher(kEnemy))
			{
				m_arrOverwatchingEnemies.InsertItem(0, kEnemy);
				if( IsSentinelValid(kEnemy))
				{
					if(ShouldSplitSentinelShots())
					{
						arrSentinels.AddItem(kEnemy);
					}
					else
					{
						m_arrOverwatchingEnemies.InsertItem(0, kEnemy);
					}
				}
			}
		}
		foreach arrSentinels(kEnemy)
		{
			m_arrOverwatchingEnemies.AddItem(kEnemy);
		}
		if(class'MiniModsTactical'.default.m_bTakeOWShotsByDist)
		{
			SortOverwatchersByDist();
		}
	}
	/** Sorts overwatcher's array by distance in DESCENDING order. That is because the array is processed from the last element to the 1st.*/
	function SortOverwatchersByDist()
	{
		local array<float> arrSortedDistSq;
		local float fDistSq;
		local array<XGUnit> arrSortedEnemies, arrSentinels;
		local XGUnit kEnemy;
		local int i;
		local bool bInsert;

		foreach m_arrOverwatchingEnemies(kEnemy)
		{
			//calc squared distance between enemy and active unit
			fDistSq = VSizeSq(m_kUnit.GetLocation() - kEnemy.GetLocation());
			if(arrSortedDistSq.Length == 0)
			{
				arrSortedEnemies.AddItem(kEnemy);
				arrSortedDistSq.AddItem(fDistSq);
				continue;
			}
			bInsert=false;
			//loop over sorted distances and find insert spot
			for(i=0; i < arrSortedDistSq.Length; ++i)
			{
				if(arrSortedDistSq[i] < fDistSq)
				{
					bInsert = true;
					break;
				}
			}
			if(bInsert)
			{
				//insert the new distance at found index
				arrSortedDistSq.InsertItem(i, fDistSq);
				arrSortedEnemies.InsertItem(i, kEnemy);
			}
			else
			{
				//if the right spot not found add to the end of arrays
				arrSortedDistSq.AddItem(fDistSq);
				arrSortedEnemies.AddItem(kEnemy);
			}
		}
		//sentinels and Rapid Reaction shooters are cached twice in the array (their entries next to each other)
		//if their shots are to be split we must find each duplicated entry and put one of the entries to the begining
		//(units at begining of the array will be processed LAST - cause the array is processed from the end)
		if(class'MiniModsTactical'.default.m_bSplitSentinelOWShots)
		{
			for(i=0; i < arrSortedEnemies.Length; ++i)
			{
				kEnemy = arrSortedEnemies[i];
				if( IsSentinelValid(kEnemy) && arrSentinels.Find(kEnemy) < 0)
				{
					arrSentinels.AddItem(kEnemy);
					arrSortedEnemies.Remove(i, 1);
					arrSortedEnemies.InsertItem(0, kEnemy);
				}
			}
		}
		m_arrOverwatchingEnemies = arrSortedEnemies;
	}
	function ProcessNextOverwatcher()
	{
		local XGUnit kEnemy;
		local int iEnemy;
		
		for(iEnemy=m_arrOverwatchingEnemies.Length - 1; iEnemy >= 0; --iEnemy)
		{
			kEnemy = m_arrOverwatchingEnemies[iEnemy];

			//MESSENGER().Message(GetFuncName() @ kEnemy @ kEnemy.GetCharacter().SafeGetCharacterFullName() $ ", forced:" @ IsForcedNextReactionCheck());
			if(class'MiniModsTactical'.default.m_bSequentialOverwatch && ShouldWaitBeforeNextShot() && !kEnemy.IsIdle())
			{   
				if(!class'MiniModsTactical'.default.m_bItchyTrigger)
				{
					m_bForceNextReactionCheck = true;//disposable, just a shortcut in the loop
					break;
				}
			}
			
			kEnemy.m_bReactionFireStatus=(!IsShadowStepping() || IsShadowStepBuster(kEnemy));
			m_kUnit.ApplyReactionCost(0, true, OnlyCoveringFire(), false,,GetStrangleTarget());
			m_arrOverwatchingEnemies.Remove(iEnemy, 1);
			kEnemy.m_bReactionFireStatus = !class'MiniModsTactical'.default.m_bSequentialOverwatch;
			
			if( class'MiniModsTactical'.default.m_bSequentialOverwatch && m_kUnit.IsSuppressionExecuting() 
				&& FindSuppressionExecutingEnemy(kEnemy) != -1)
			{
				CheckForPopup(kEnemy); //CovFire pop-up for units that do not have the perk or ShadowBuster pop-up
				if(!class'MiniModsTactical'.default.m_bItchyTrigger)
				{
					m_bForceNextReactionCheck = false;
					break;
				}
			}
		}
	}

Begin:
	while(!InitialValidationPassed() || GRI().m_kCameraManager.WaitForCamera())
	{
		Sleep(0.05);
	}
	CacheCurrentOverwatchers();
	if(!m_kUnit.GetAction().IsA('XGAction_Fire'))
	{
		CheckForPopup(m_kUnit);
	}
	//MESSENGER().Message("Cached" @ m_arrOverwatchingEnemies.Length @ "potential reaction shots." @ GetStateName());
	if(m_arrOverwatchingEnemies.Length > 0)
	{
		do
		{
			while(m_kUnit.IsSuppressionExecuting() && !IsForcedNextReactionCheck())
			{
				Sleep(0.10);
			}
			if(ForceBreakReactionLoop())
			{
				//MESSENGER().Message("Force-break reaction check");
				break;
			}
			if(ShouldWaitBeforeNextShot() && GetNextOverwatcherInQueue() != none)
			{
				//MESSENGER().Message("Waiting shortly before next OW shot");
				if(GetNextOverwatcherInQueue().IsIdle())
				{
					Sleep(GetPauseTimeBeforNextShot());
				}
				else 
				{
					//MESSENGER().Message("Waiting long before next shot");
					do
					{
						Sleep(0.10);
					}
					until(GetNextOverwatcherInQueue().IsIdle());
				}
			}
			ProcessNextOverwatcher();
		}
		until(!m_kUnit.IsSuppressionExecuting() || !m_kUnit.IsAliveAndWell());
	}
	PopState();
}

state ProcessingCoveringFire extends ProcessingReaction
{
	event  PushedState()
	{
		//MESSENGER().Message(m_kUnit @ "CF check");
		//LogInternal(GetFuncName() @ GetStateName() @ m_kUnit @ m_kUnit.SafeGetCharacterFullName());
		//CacheCurrentOverwatchers();
		m_bForceNextReactionCheck = false;
	}
	event PoppedState()
	{
		super.PoppedState();
		//LogInternal(GetFuncName() @ GetStateName() @ m_kUnit @ m_kUnit.SafeGetCharacterFullName());
	}
	function bool InitialValidationPassed()
	{
		return super.InitialValidationPassed() && !GRI().m_kCameraManager.WaitForCamera();
	}
	function bool IsSentinelValid(XGUnit kUnit)
	{
		return (kUnit.GetCharacter().HasUpgrade(54) || kUnit.GetCharacter().HasUpgrade(23)) && class'MiniModsTactical'.default.m_bSentinelCoveringFire;
	}
	function bool IsValidOverwatcher(XGUnit kUnit)
	{
		return super.IsValidOverwatcher(kUnit) && (class'MiniModsTactical'.default.m_bAlwaysCoveringFire || kUnit.GetCharacter().HasUpgrade(47));
	}
	function bool OnlyCoveringFire()
	{
		return !class'MiniModsTactical'.default.m_bAlwaysCoveringFire;
	}
	function bool ShouldWaitBeforeNextShot()
	{
		return class'MiniModsTactical'.default.m_bSequentialOverwatch && m_kUnit.IsSuppressionExecuting() && GetNextOverwatcherInQueue() != none;
	}
	function float GetPauseTimeBeforNextShot()
	{
		return 1.0;
	}
	function CheckForPopup(XGUnit kUnit)
	{
		if(class'MiniModsTactical'.default.m_bAlwaysCoveringFire && !kUnit.GetCharacter().HasUpgrade(47) && !kUnit.GetAction().IsA('XGAction_FireOverwatchExecuting') && !m_bLWRebalance)
		{
			WORLDMESSENGER().Message(class'MiniModsTactical'.static.GRI().m_kGameCore.GetUnexpandedLocalizedMessageString(eULS_CoveringFireProc), kUnit.GetLocation(), eColor_Cyan,,,kUnit.m_eTeamVisibilityFlags);
		}
		super.CheckForPopup(kUnit);
	}
	function bool ForceBreakReactionLoop()
	{
		return UnitIsSafeFromReactionFire() || !m_kUnit.IsAliveAndWell();	
	}
}
state ProcessingUnstealth extends ProcessingReaction
{
	//ignores OnUnitChangedTileDuringMovement, OnUnitSteppingOut;

	event  PushedState()
	{
		m_bForceNextReactionCheck = false;
	}
	event PoppedState()
	{
		SetTimer(3.0, false, 'DebugStrangleLocation');
	}
	function XGUnit GetStrangleTarget()
	{
		return m_kUnit.m_kStrangleTarget;
	}
	function bool ShouldWaitBeforeNextShot()
	{
		return class'MiniModsTactical'.default.m_bSequentialOverwatch && m_kUnit.IsSuppressionExecuting() && GetNextOverwatcherInQueue() != none;
	}
	function bool ForceBreakReactionLoop()
	{
		return UnitIsSafeFromReactionFire() || !m_kUnit.IsAliveAndWell();	
	}
	function bool IsSentinelValid(XGUnit kUnit)
	{
		return kUnit.GetCharacter().HasUpgrade(54) || kUnit.GetCharacter().HasUpgrade(23);
	}
	function bool InitialValidationPassed()
	{
		local bool bPendingVisibilityUpdate, bHiding;

		bHiding = m_kUnit.IsHiding();
		if( (XComSeeker(m_kUnit.GetPawn()) != none && XComSeeker(m_kUnit.GetPawn()).m_bStealthFXOn) || m_kUnit.GetPawn().IsTimerActive('CleanUpGhostFX', m_kUnit) )
		{
			bHiding = true;
		}
		bPendingVisibilityUpdate = class'XComWorldData'.static.GetWorldData().HasPendingVisibilityUpdates() || class'XComWorldData'.static.GetWorldData().IsRebuildingTiles();

		return !bHiding && !bPendingVisibilityUpdate;
	}
}
state ProcessingDropIn extends ProcessingUnstealth
{
	event  PushedState()
	{
		//MESSENGER().Message(m_kUnit @ GetStateName());
		if(class'MiniModsTactical'.default.m_bSequentialOverwatch)
		{
			//MESSENGER().Message("Disabled" @ m_kDelayedOWHandler);
			m_kDelayedOWHandler.SetTickIsDisabled(true);//disable original code
		}
		m_bForceNextReactionCheck = false;
	}
	event PoppedState()
	{
		super.PoppedState();
		m_kDelayedOWHandler.SetTickIsDisabled(false);//this will let the original code destroy the OW handler
		m_kDelayedOWHandler = none;
	}
	function bool InitialValidationPassed()
	{
		return m_kUnit.IsIdle();
	}
	function XGUnit GetStrangleTarget()
	{
		return none;
	}
	function bool ForceBreakReactionLoop()
	{
		m_kUnit.ResetReaction(); //drop-in units have reaction at 20 which prevents non-sentinel/RR shots
		return UnitIsSafeFromReactionFire() || !m_kUnit.IsAliveAndWell();	
	}

}
state SavingData
{
	event PushedState()
	{
		//MESSENGER().Message(m_kUnit @ GetFuncName() @ GetStateName());
	}
	event PoppedState()
	{
		//MESSENGER().Message(m_kUnit @ GetFuncName() @ GetStateName());
	}
Begin:
	while(m_arrSaveValueQueue.Length > 0)
	{
		SaveValue(m_arrSaveValueQueue[0].strText, m_arrSaveValueQueue[0].strHelp);
		m_arrSaveValueQueue.Remove(0, 1);
		Sleep(0.05);
	}
	PopState();
}
/**FIXME
 * - m_bReactionStatus is in CheckpointRecord, ensure hot-update
 */
DefaultProperties
{
	m_iWatchActiveUnitHandle=-1
	m_iWatchActiveUnitAction=-1
	m_iWatchFireActionStatus=-1
	m_iWatchActiveUnitTravelHandle=-1
}