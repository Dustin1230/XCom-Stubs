class TacticalDebugger extends XComMutator
	config(LWDebugger);

var config bool bLogEnabled;
var config bool bDebugDoubleMove;
var config bool bDebugPanicFlag;
var config bool bDebugRadarArrays;
var config bool bDebugLocation;
var config bool bDebugLocationIncludeWounded;
var config bool bDebugMultiSmoke;
var config bool bDebugAcidOnRobots;
var array<XGUnit> m_arrPanicking;
var array<XGUnit> m_arrRecovering;
var array<XGUnit> m_arrAOETargets;
var array<XGUnit> m_arrFreezeUnits;
var array<XGUnit> m_arrSteppingOutOfCover;
var int m_iNumPermanentAliens;
var int m_iNumPermanentHumans;
var int m_watchVar_InfoBox;
var int m_watchVar_ActiveUnit;
var int m_watchVar_CurrAction;
var int m_watchVar_TargetLoc;
var int m_watchVar_FireDebug;
var int m_watchVar_FireHangBreakout;
var array<LWD_UnitTracker> m_arrUnitTrackers;

var XGAbility_Targeted m_kSavedAbility;

function Mutate(String MutateString, PlayerController Sender)
{
    super.Mutate(MutateString, Sender);
}

function PostLoadSaveGame(PlayerController Sender)
{
	SetTimer(2.0, true, 'RegisterWatchVars');
	SetTimer(2.0, false, 'UpdateStepOuts');
}
function PostLevelLoaded(PlayerController Sender)
{
	PostLoadSaveGame(Sender);
}
function RegisterWatchVars()
{
	local XGUnit kUnit;

	if(XComPresentationLayer(XComTacticalController(PC()).m_Pres).m_kTacticalHUD != none && IsBattleReady())
	{
		ClearTimer('RegisterWatchVars');
		m_watchVar_InfoBox = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(XComPresentationLayer(XComTacticalController(PC()).m_Pres).m_kTacticalHUD.m_kAbilityHUD, 'm_kTargetingRequestUnit', self, OnInfoBox);
		GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(XGBattle_SP(GRI().GetBattle()).GetHumanPlayer().GetSquad(), 'm_iNumPermanentUnits', self, OnNewHumanUnit);
		GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(XGBattle_SP(GRI().GetBattle()).GetAIPlayer().GetSquad(), 'm_iNumPermanentUnits', self, OnNewAlienUnit);
		//GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(GRI().GetBattle().m_kPodMgr,'m_arrActivation', self, OnPodMgrActivation);
		m_iNumPermanentHumans = XGBattle_SP(GRI().GetBattle()).GetHumanPlayer().GetSquad().GetNumPermanentMembers();
		m_iNumPermanentAliens = XGBattle_SP(GRI().GetBattle()).GetAIPlayer().GetSquad().GetNumPermanentMembers();
		foreach DynamicActors(class'XGUnit', kUnit)
		{
			if(!kUnit.IsDead())
			{
				InitUnitTrackingFor(kUnit);
			}
		}
		SetTimer(0.10, true, 'UpdatePlayerWatchVar');
	}
}
function UpdatePlayerWatchVar()
{
	if(GRI().GetBattle().IsInState('TransitioningPlayers') || GRI().GetBattle().m_kActivePlayer == none)
	{
		return;
	}
	ClearTimer(GetFuncName());
	if(GRI().GetBattle().m_kActivePlayer == XGBattle_SP(GRI().GetBattle()).GetHumanPlayer())
	{
		m_arrFreezeUnits.Length = 0;
	}
	if(m_watchVar_ActiveUnit != -1)
	{
		GetWorldInfo().MyWatchVariableMgr.UnRegisterWatchVariable(m_watchVar_ActiveUnit);
	}
	m_watchVar_ActiveUnit = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(GRI().GetBattle().m_kActivePlayer, 'm_kActiveUnit', self, OnActiveUnitChange);
	OnActiveUnitChange();
	DebugVolumeEffects();
}
function OnInfoBox();
//-----------------------------------------------
// UTILITY FUNCTIONS
//----------------------------------------------
static function WorldInfo GetWorldInfo()
{
	return class'Engine'.static.GetCurrentWorldInfo();
}

static function PlayerController PC()
{
	return GetWorldInfo().GetALocalPlayerController();
}

static function XComTacticalGRI GRI()
{
	return XComTacticalGRI(GetWorldInfo().GRI);
}
function XGBattle_SP BATTLE()
{
	return XGBattle_SP(GRI().m_kBattle);
}
function XComPresentationLayer PRES()
{
	return XComPresentationLayer(XComPlayerController(GetALocalPlayerController()).m_Pres);
}
function actor GetActor(class<actor> ActorClass, string strName)
{
	local actor kActorToGet;

	foreach DynamicActors(ActorClass, kActorToGet)
	{
		if(string(kActorToGet) == strName)
		{
			return kActorToGet;
		}
	}
}
static function string GetParameterString(int iParameterID, string strParams, optional string strSeparator=",")
{
    local array<string> arrFunctParas;
    
    if(strParams != "")
    {
        ParseStringIntoArray(Split(strParams, ":", true), arrFunctParas, strSeparator, true);
        return arrFunctParas[iParameterID];
    }
	return "";
}
function bool IsBattleReady()
{
	local bool bXComLoaded, bAliensLoaded, bNeutralLoaded;
	local XGPlayer kPlayer;

	kPlayer = GRI().m_kBattle.m_arrPlayers[0];
	if(kPlayer != none && kPlayer.GetSquad() != none)
	{
		bXComLoaded = true;
	}
	kPlayer = GRI().m_kBattle.m_arrPlayers[1];
	if(kPlayer != none && kPlayer.GetSquad() != none)
	{
		bAliensLoaded = true;
	}
	kPlayer = GRI().m_kBattle.m_arrPlayers[2];
	if(kPlayer != none && kPlayer.GetSquad() != none)
	{
		bNeutralLoaded = true;
	}
	return (GRI().m_kBattle.AtBottomOfRunningStateBeginBlock() &&  bAliensLoaded && bXComLoaded && bNeutralLoaded);
}
//-----------------------------------
// END OF UTILITY SECTION
//-----------------------------------
function MutateUpdateInteractClaim(string strUnitName, PlayerController Sender)
{
	local XGUnit kUnit;

	if(!IsBattleReady())
	{
		return;
	}
	kUnit = XGUnit(GetActor(class'XGUnit', strUnitName));
	ClearAOEHitMaterialForUnit(kUnit);
	`Log(GetFuncName() @ strUnitName,bLogEnabled,'LWDebugger');
	if( (kUnit.IsAlien() || kUnit.IsExalt()) && GRI().GetBattle().m_kPodMgr.IsInState('Active'))
	{
		//`Log("Grabbed alien: " @ kUnit.GetCharacter().SafeGetCharacterName() @ GetRightMost(kUnit) @ "for debugging", bLogEnabled, 'LWDebugger');
		//if(bDebugDoubleMove)
		//	DebugDoubleMove(kUnit);
	}
	else
	{
		//`Log("Grabbed unit: " @ kUnit.GetCharacter().SafeGetCharacterFullName() @ "for debugging", bLogEnabled, 'LWDebugger');
		UpdatePanicked(kUnit);
		if(DebugPanicCheck(kUnit))
			DebugUnitFlag(kUnit); 
	}
	if(bDebugLocation)
		DebugBadLocation(kUnit);
	if(bDebugMultiSmoke)
		UpdateSmoke();
	if(!GRI().GetBattle().IsInState('TransitioningPlayers'))
	{
		DebugStepOuts();
	}
	else
	{
		//m_arrFreezeUnits.Length = 0;
		SetTimer(0.10, true, 'UpdatePlayerWatchVar');
	}
}
function CacheDormantPods()
{
	local XComAlienPod kPod;
	local array<XComAlienPod> arrAllPods;
	local XGUnit kUnit;
	local XGPlayer kPlayer;

	kPlayer = XGBattle_SP(GRI().m_kBattle).GetLocalPlayer();
	if(!kPlayer.IsA('XGAIPlayer'))
	{
		m_arrFreezeUnits.Length = 0;
		foreach DynamicActors(class'XComAlienPod', kPod) 
			arrAllPods.AddItem(kPod);
		foreach arrAllPods(kPod)
		{
			if(kPod.IsInState('Dormant'))
			{
				foreach kPod.m_arrAlien(kUnit)
				{
					m_arrFreezeUnits.AddItem(kUnit);
					`Log(string(kPod) @ "is Dormant; disabling turn for:" @ kUnit.GetCharacter().SafeGetCharacterName() @ GetRightMost(kUnit) @ ", only whole pod can move/reveal.", bLogEnabled, 'LWDebugger');
				}
			}
		}
	}
}

function DebugDoubleMove(XGUnit kUnit)
{
	if(m_arrFreezeUnits.Find(kUnit) < 0)
	{
		m_arrFreezeUnits.AddItem(kUnit);
		kUnit.SetMoves(0);
		`Log(kUnit.GetCharacter().SafeGetCharacterName() @ "(" $ string(kUnit) $ ") deactivated this turn due to pod reveal.",bLogEnabled,'LWDebugger');
	}
}
function OnPodMgrActivation()
{
	local XComAlienPodManager kPodMgr;
	local XGUnit kAlien;
	local XComAlienPod kPod;

	kPodMgr = GRI().GetBattle().m_kPodMgr;
	`Log(GetFuncName() @ kPodMgr.GetStateName(),bLogEnabled,'LWDebugger');
	if(kPodMgr.IsInState('Inactive'))
	{
		if(bDebugDoubleMove)
		{
			foreach kPodMgr.m_arrPod(kPod)
			{
				foreach kPod.m_arrAlien(kAlien)
				{
					if(kAlien.IsDormant())
						continue;
					`Log(kalien@"started turn" @ kAlien.m_kBehavior.HasStartedTurn() @ kAlien.m_kBehavior.m_iLastTurnStart,,'LWDebugger');
					DebugDoubleMove(kAlien);
				}
			}
		}
	}
}
function UpdatePanicked(XGUnit kUnit)
{
	if(kUnit.m_iPanicCounter > 0)
	{
		if(m_arrPanicking.Find(kUnit) < 0)
			m_arrPanicking.AddItem(kUnit);
	}
	else
	{
		if(m_arrPanicking.Find(kUnit) != -1)
		{
			m_arrPanicking.RemoveItem(kUnit);
			m_arrRecovering.AddItem(kUnit);
		}
	}
}
function bool DebugPanicCheck(XGUnit kUnit)
{
	if(m_arrRecovering.Find(kUnit) != -1)
		return true;
	else
		return false;
}

function DebugUnitFlag(XGUnit kUnit)
{
	local UIUnitFlagManager kFlagMgr;
	local UIUnitFlag kFlag;
	local int I;


	kFlagMgr = XComPresentationLayer(XComPlayerController(PC()).m_Pres).m_kUnitFlagManager;
	if(kFlagMgr != none)
	{
		`Log("Replacing UnitFlag after panic for:" @ kUnit.GetCharacter().SafeGetCharacterFullName(), bLogEnabled, 'LWDebugger');
		for(I = 0; I < kFlagMgr.m_arrFlags.Length; ++I)
		{
			if(kFlagMgr.m_arrFlags[I].m_kUnit == kUnit)
			{
				kFlag = kFlagMgr.m_arrFlags[I];
				break;
			}
		}
		if(kFlag != none)
		{
			kFlag.Remove();
			kFlag.Destroy();
			kFlagMgr.AddFlag(kUnit);
			if(m_arrRecovering.Find(kUnit) != -1)
			{
				m_arrRecovering.RemoveItem(kUnit);
			}
		}
	}
}
function MutateNotifyKismetOfLoad(PlayerController Sender)
{
	local SeqVar_Object kDebugObj;
	local XComRadarArrayActor kGoodRadar1, kGoodRadar2;
	local XGUnit kCovertOp;
	local array<SequenceObject> akSequences;
    local SequenceObject kSeq;
	
	if(!bDebugRadarArrays || XGBattle_SPCovertOpsExtraction(GRI().m_kBattle) == none)
	{
		`Log("Debug radar arrays:" @ bDebugRadarArrays $ ". Covert Ops Extraction mission:" @ string(XGBattle_SPCovertOpsExtraction(GRI().m_kBattle) != none), bLogEnabled, name);
		return;
	}
    akSequences = GetWorldInfo().MyKismetVariableMgr.GetObjectByClass(class'SeqVar_Object');
	if(akSequences.Length > 0)
	{
		foreach akSequences(kSeq)
		{
			kDebugObj = SeqVar_Object(kSeq);
			if(kDebugObj.VarName == 'pisFirstArray' && kDebugObj.GetObjectValue() != none)
				kGoodRadar1 = XComRadarArrayActor(kDebugObj.GetObjectValue());
			else if(kDebugObj.VarName == 'pisSecondArray' &&  kDebugObj.GetObjectValue() != none)
				kGoodRadar2 = XComRadarArrayActor(kDebugObj.GetObjectValue());
			else if(kDebugObj.VarName == 'objCovertOperative' &&  kDebugObj.GetObjectValue() != none)
				kCovertOp = XGUnit(kDebugObj.GetObjectValue());
			if(kGoodRadar1 != none && kGoodRadar2 != none && kCovertOp != none)
				break;
		}
		//kCovertOp = XGBattle_SPCovertOpsExtraction(GRI().m_kBattle).GetCovertOperative();
		foreach akSequences(kSeq)
		{
			kDebugObj = SeqVar_Object(kSeq);
			if(kDebugObj.VarName == 'pisFirstArray' && kDebugObj.GetObjectValue() == none)
			{
				kDebugObj.SetObjectValue(kGoodRadar1);
				LogInternal("Updating kismet object:" @ kDebugObj.VarName $ ". New value:" @ kDebugObj.GetObjectValue(), name);
			}
			else if(kDebugObj.VarName == 'pisSecondArray' &&  kDebugObj.GetObjectValue() == none)
			{
				kDebugObj.SetObjectValue(kGoodRadar2);
				LogInternal("Updating kismet object:" @ kDebugObj.VarName $ ". New value:" @ kDebugObj.GetObjectValue(), name);
			}
			else if(kDebugObj.VarName == 'objCovertOperative' && kDebugObj.GetObjectValue() == none)
			{
				kDebugObj.SetObjectValue(kCovertOp);
				LogInternal("Updating kismet object:" @ kDebugObj.VarName $ ". New value:" @ kDebugObj.GetObjectValue(), name);
			}
			else if(kDebugObj.VarName == 'objCovertOperativePawn' && kDebugObj.GetObjectValue() == none)
			{
				kDebugObj.SetObjectValue(kCovertOp.GetPawn());
				LogInternal("Updating kismet object:" @ kDebugObj.VarName $ ". New value:" @ kDebugObj.GetObjectValue(), name);
			}
		}
	}
}

function DebugBadLocation(XGUnit kUnit)
{
	local Vector vLoc, vClosestLoc;
	
	if(!GRI().GetBattle().AtBottomOfRunningStateBeginBlock() || (!bDebugLocationIncludeWounded && kUnit.IsCriticallyWounded()) )
	{
		return;
	}
	vLoc = kUnit.GetPawn().Location; 
	if(kUnit.IsAliveAndWell() && !kUnit.IsSuppressionExecuting() && kUnit.m_arrSuppressionTargets[0]==none && !kUnit.IsFlying() && !GRI().IsValidLocation(vLoc, kUnit, true))
	{
		vClosestLoc = GRI().GetClosestValidLocation(vLoc, kUnit);
		if(kUnit.GetPawn().SetLocation(vClosestLoc))
		{
			if(bLogEnabled)
			{
				PRES().GetMessenger().Message("Debugged invalid location for" @ kUnit.SafeGetCharacterFullName(),,ePulse_Red);
			}
		}
	}
}
function array<TTile> GetValidTilesInRadius(Vector vCenter, int iTilesRadius, XGUnit kUnit)
{
	local XGOvermindActor kHelp;
	local TTile kCenterTile, kTile;
	local array<TTile> arrValidTiles;
	local int iX, iY;
	local XComWorldData kWorld;

	kHelp = XGAIPlayer(GRI().GetBattle().GetAIPlayer()).m_kOvermindHandler.m_kOvermind;
	kWorld = class'XComWorldData'.static.GetWorldData();
	kWorld.GetTileCoordinatesFromPosition(vCenter, kCenterTile.X, kCenterTile.Y, kCenterTile.Z);
	kTile.Z = kCenterTile.Z;
	for(iX = -iTilesRadius; iX <= iTilesRadius; ++iX)
	{
		for(iY= -iTilesRadius; iY <= iTilesRadius; ++ iY)
		{
			kTile.X = kCenterTile.X + iX;
			kTile.Y = kCenterTile.Y + iY;
			if(GRI().IsValidLocation(kHelp.TileToPoint(kTile), kUnit, false))
			{
				arrValidTiles.AddItem(kTile);
			}
		}
	}
	return arrValidTiles;
}

function UpdateSmoke()
{
	local XGUnit kUnit;

	foreach DynamicActors(class'XGUnit', kUnit)
	{
		if(!kUnit.IsDead())
			UpdateSmokeForUnit(kUnit);
	}
}
function UpdateSmokeForUnit(XGUnit kUnit)
{
	local int X, Y, Z;
	local XGVolume kSmoke;

//	`Log(GetFuncName() @ kUnit.SafeGetCharacterName(), bLogEnabled, name);
	if(!class'XComWorldData'.static.GetWorldData().GetFloorTileForPosition(kUnit.GetPawn().Location, X, Y, Z))
	{
		return;
	}
	if(class'XComWorldData'.static.GetWorldData().TileContainsSmoke(X, Y, Z) && !kUnit.m_bInSmokeBomb)
	{
		kSmoke = kUnit.GetGameplayVolume(1);
		if(kSmoke == none)
		{
			kSmoke = kUnit.GetGameplayVolume(2);
		}
		if(kSmoke != none)
		{
			`Log("Smoke to get updated found", bLogEnabled, name);
			if(kSmoke.m_kInstigator.GetCharacter().HasUpgrade(52))
			{
				kUnit.m_bInDenseSmoke = true;
				kUnit.AddBonus(52);
			}
			if(kSmoke.m_kInstigator.GetCharacter().HasUpgrade(ePerk_CombatDrugs))
			{
				kUnit.m_bInCombatDrugs = true;
				kUnit.AddBonus(ePerk_CombatDrugs);
			}
			kUnit.m_bInSmokeBomb = true;
			kUnit.AddBonus(44);
			kUnit.UpdateCoverBonuses(none);
		}
	}
}
function DebugVolumeEffects()
{
	local XGVolume kVol;
	local XGVolumeMgr kVolMgr;
	local int i;

	kVolMgr = BATTLE().m_kVolumeMgr;
	for(i=0; i < kVolMgr.m_iNumVolumes; ++i)
	{
		kVol = kVolMgr.m_aVolumes[i];
		if(kVol.GetType() == eVolume_Smoke || kVol.GetType() == eVolume_CombatDrugs)
		{
			if(kVol.m_iTurnTimer == 2)
			{
				kVol.InitVolumeEffect();
			}
		}
	}
}
function UpdateStepOuts()
{
	local XGUnit kUnit;

	foreach DynamicActors(class'XGUnit', kUnit)
	{
		if(kUnit.bSteppingOutOfCover 
			&& !kUnit.IsMoving() 
			&& !IsGrappling(kUnit)
			&& m_arrSteppingOutOfCover.Find(kUnit) < 0)
		{
			m_arrSteppingOutOfCover.AddItem(kUnit);
		}
	}
}
function bool IsGrappling(XGUnit kUnit)
{
	return (XGAction_Fire(kUnit.m_kActionQueue.PeekNext()) != none && XGAction_Fire(kUnit.m_kActionQueue.PeekNext()).IsCurrentAbilityGrapple());
}
function DebugStepOuts()
{
	local array<XGUnit> arrPendingUnits;
	local XGUnit kUnit;

	arrPendingUnits = m_arrSteppingOutOfCover;
	foreach arrPendingUnits(kUnit)
	{
		if(!kUnit.bSteppingOutOfCover)
		{
			if(!kUnit.IsPerformingAction() || kUnit.GetAction().IsA('XGAction_Idle'))
			{
				DebugStepOutForUnit(kUnit);
			}
			else
			{
				//PRES().GetMessenger().Message("Postponed debugging for" @ kUnit.SafeGetCharacterFullName() @ "performing" @ string(kUnit.GetAction()));
				SetTimer(0.30, false, GetFuncName());
			}
		}
	}
}
function DebugStepOutForUnit(XGUnit kUnit)
{
	local Vector vLoc, vStoredLoc;
	local int iX, iY, iZ;

	m_arrSteppingOutOfCover.RemoveItem(kUnit);
	//the unit is no longer stepping out
	vLoc = kUnit.GetPawn().Location;
	vStoredLoc = kUnit.RestoreLocation;
	if(VSize(vLoc - vStoredLoc) >= 30.0)
	{
		class'XComWorldData'.static.GetWorldData().ClearTileBlockedByUnitFlag(kUnit);
		class'XComWorldData'.static.GetWorldData().GetTileCoordinatesFromPosition(vStoredLoc, iX, iY, iZ);
		vLoc = class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(iX, iY, iZ);
		if(kUnit.GetPawn().SetLocation(vLoc))
		{
			if(bLogEnabled)
			{
				PRES().GetMessenger().Message("Debugged step-out for" @ kUnit.SafeGetCharacterFullName() $ "!",,ePulse_Red,3.0);
			}
			kUnit.SetTimer(0.20, false, 'ProcessNewPosition', kUnit);
		}
	}
}

//------------------------
// Mark robots in acid
//------------------------
function bool IsAOETarget(XGUnit kUnit)
{
	return m_arrAOETargets.Find(kUnit) != -1;
}
function ApplyAOEMaterialForUnit(XGUnit kUnit)
{
	local MaterialInstanceConstant MIC;
//    local Texture BodyDiffuse, BodyNormal;
	local int i;

	if(kUnit == none)
		return;
	if(!IsAOETarget(kUnit))
		m_arrAOETargets.AddItem(kUnit);
	for(i=0; i<kUnit.GetPawn().Mesh.GetNumElements(); ++i)
	{
		MIC = new (kUnit.GetPawn()) class'MaterialInstanceConstant'; //create an instance
		MIC.SetParent(kUnit.GetPawn().AOEHitMaterial);//set the template for the instance
		kUnit.GetPawn().Mesh.SetMaterial(i, MIC);
	}
	//	kUnit.GetPawn().Mesh.GetMaterial(0).GetTextureParameterValue('Diffuse', BodyDiffuse);
	//	kUnit.GetPawn().Mesh.GetMaterial(0).GetTextureParameterValue('Normal', BodyNormal);
	//MIC.SetTextureParameterValue('Diffuse', BodyDiffuse);
	//MIC.SetTextureParameterValue('Normal', BodyNormal);
	//kUnit.GetPawn().Mesh.SetMaterial(0, MIC);
}
function ClearAOEHitMaterialForUnit(XGUnit kUnit)
{
    local MeshComponent MeshComp;
	local int I;
	
	if(kUnit == none)
		return;
	if(IsAOETarget(kUnit))
		m_arrAOETargets.RemoveItem(kUnit);
	foreach kUnit.GetPawn().AllOwnedComponents(class'MeshComponent', MeshComp)
	{
		for(I = 0; I < MeshComp.Materials.Length; ++I)
		{
			MeshComp.SetMaterial(I, none);
		}
	}
	kUnit.GetPawn().UpdateAllMeshMaterials();
}
function OnActiveUnitChange()
{
	local XGUnit kActiveUnit;

	if(m_watchVar_CurrAction > 0)
	{
		GetWorldInfo().MyWatchVariableMgr.UnRegisterWatchVariable(m_watchVar_CurrAction);
	}
	kActiveUnit = GRI().GetBattle().m_kActivePlayer.m_kActiveUnit;
	if(kActiveUnit != none)
	{
		m_watchVar_CurrAction = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(kActiveUnit, 'm_kCurrAction', self, UpdateCurrAction);
		if(GRI().GetBattle().IsAlienTurn() && m_arrFreezeUnits.Find(kActiveUnit) != -1)
		{
			if(bDebugDoubleMove)
			{
				if(bLogEnabled)
				{
					PRES().GetWorldMessenger().Message("...zzz", kActiveUnit.GetLocation());
				}
				kActiveUnit.SetMoves(0);
			}
		}
	}
	else
	{
		m_watchVar_CurrAction = -1;
		while(m_arrAOETargets.Length > 0)
		{
			ClearAOEHitMaterialForUnit(m_arrAOETargets[m_arrAOETargets.Length -1]);
		}
		SetTimer(0.30, false, GetFuncName());
	}
}
function OnNewHumanUnit()
{
	local XGUnit kNewUnit;
	local XGSquad kSquad;
	local int iNewSquadSize;

	kSquad = XGBattle_SP(GRI().GetBattle()).GetHumanPlayer().GetSquad();
	iNewSquadSize = kSquad.GetNumPermanentMembers();
	while(m_iNumPermanentHumans < iNewSquadSize)
	{
		kNewUnit = kSquad.m_arrPermanentMembers[m_iNumPermanentHumans];
		InitUnitTrackingFor(kNewUnit);
		++ m_iNumPermanentHumans;
	}
}
function OnNewAlienUnit()
{
	local XGUnit kNewUnit;
	local XGSquad kSquad;
	local int iNewSquadSize;

	kSquad = XGBattle_SP(GRI().GetBattle()).GetAIPlayer().GetSquad();
	iNewSquadSize = kSquad.GetNumPermanentMembers();
	while(m_iNumPermanentAliens < iNewSquadSize)
	{
		kNewUnit = kSquad.m_arrPermanentMembers[m_iNumPermanentAliens];
		InitUnitTrackingFor(kNewUnit);
		++ m_iNumPermanentAliens;
	}
}
function InitUnitTrackingFor(XGUnit kUnit)
{
	local LWD_UnitTracker kTracker;

	GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(kUnit, 'm_bInSmokeBomb', self, UpdateSmoke);
	GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(kUnit, 'bSteppingOutOfCover', self, UpdateStepOuts);
	if(GetUnitTracker(kUnit) == none)
	{
		kTracker = Spawn(class'LWD_UnitTracker', self);
		kTracker.Init(kUnit); 
		m_arrUnitTrackers.AddItem(kTracker);
	}
}
function LWD_UnitTracker GetUnitTracker(XGUnit kUnit)
{
	local LWD_UnitTracker kTracker;

	foreach m_arrUnitTrackers(kTracker)
	{
		if(kTracker.m_kUnit == kUnit)
		{
			return kTracker;
		}
	}
	return none;
}
function UpdateCurrAction()
{
	local XGAction_Targeting kTargeting;
	local XGAction_Fire kFire;

	GetWorldInfo().Game.Mutate("TacticalDebugger.UpdateCurrAction", none);
	if(GRI().GetBattle().m_kActivePlayer.GetActiveUnit() != none)
	{
		kTargeting = XGAction_Targeting(GRI().GetBattle().m_kActivePlayer.GetActiveUnit().GetAction());
		kFire = XGAction_Fire(GRI().GetBattle().m_kActivePlayer.GetActiveUnit().GetAction());
	}
	if(kTargeting != none)
	{
		ModTargetingAction(kTargeting);
	}
	else if(kFire != none)
	{
		ModFireAction(kFire);
	}
	else
	{
		while(m_arrAOETargets.Length > 0)
		{
			ClearAOEHitMaterialForUnit(m_arrAOETargets[m_arrAOETargets.Length -1]);
		}
	}

}
function ModTargetingAction(XGAction_Targeting kTargeting)
{
	if(kTargeting == none || kTargeting.m_kShot.m_kWeapon == none)
	{
		return;
	}
	if( (bDebugAcidOnRobots && kTargeting.m_kShot.m_kWeapon.m_eType == eItem_ChemGrenade) )
	{
		m_watchVar_TargetLoc = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(kTargeting, 'm_vSplashCenterCache', self, UpdateTargets);
	}
	else
	{
		if(m_watchVar_TargetLoc > 0)
		{
			GetWorldInfo().MyWatchVariableMgr.UnRegisterWatchVariable(m_watchVar_TargetLoc);
			m_watchVar_TargetLoc = -1;
		}
		while(m_arrAOETargets.Length > 0)
		{
			ClearAOEHitMaterialForUnit(m_arrAOETargets[m_arrAOETargets.Length -1]);
		}
	}
}
function DelayedUpdateTargets()
{
	if(XComPresentationLayer(XComTacticalController(PC()).m_Pres).m_kGermanMode == none && !GRI().GetBattle().IsPaused())
		UpdateTargets();
}
function UpdateTargets()
{
	local XGUnit kUnit;
	local array<XGUnit> arrValidTargets;
	local XGAction_Targeting kTargeting;
	local vector vHitLoc, vUnitLoc;
	local int iX, iY, iZ;

	if(IsTimerActive('DelayedUpdateTargets'))
	{
		return;
	}
	kTargeting = XGAction_Targeting(XComTacticalController(PC()).GetActiveUnit().GetAction());
	if(kTargeting != none)
	{
		if(kTargeting.ExplosionEmitter != none)
		{
			vHitLoc = kTargeting.ExplosionEmitter.Location;
		}
		else if(kTargeting.m_bShotIsBlocked)
		{
			vHitLoc = kTargeting.m_vHitLocation;
		}
		else
		{
			vHitLoc = kTargeting.m_vTarget;
		}
		class'XComWorldData'.static.GetWorldData().GetTileCoordinatesFromPosition(vHitLoc,iX, iY, iZ);
		vHitLoc = class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(iX, iY, iZ);
		//PRES().GetWorldMessenger().Message("HitTile", vHitLoc);
		//LogInternal(GetFuncName(), 'LWDebugger');
		
		//cache current targets
		foreach DynamicActors(class'XGUnit', kUnit)
		{
			if(kUnit.IsDead() || !kUnit.IsVisible() || !kTargeting.m_kShot.CanTargetUnit(kUnit))
				continue;
		
			vUnitLoc = kUnit.GetTargetLocation();
			class'XComWorldData'.static.GetWorldData().GetTileCoordinatesFromPosition(vUnitLoc,iX, iY, iZ);
			vUnitLoc = class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(iX, iY, iZ);

			if(kTargeting.m_fSplashRadiusCache > VSize(vUnitLoc - vHitLoc))
			{
				arrValidTargets.AddItem(kUnit);
			}
		
			if(arrValidTargets.Find(kUnit) != -1)
			{
				ApplyAOEMaterialForUnit(kUnit);
			}
			else
			{
				ClearAOEHitMaterialForUnit(kUnit);
			}
		}
	}
	else
	{
		foreach DynamicActors(class'XGUnit', kUnit)
		{
			ClearAOEHitMaterialForUnit(kUnit);
		}
	}
}
function DebugSuppression(XGUnit kTarget)
{
	local int idx;
	local XGUnit kSuppressor;
	local XGAction_Fire kAction;

	for(idx=0; idx < 16; idx++)
	{
		kSuppressor = XGUnit(kTarget.m_arrSuppressionExecutingEnemies[idx]);
		if(kSuppressor != none)
		{
			kAction = XGAction_Fire(kSuppressor.GetAction());
			if(kAction != none && kAction.IsA('XGAction_FireOverwatchExecuting') && kAction.m_eFireActionStatus == EFAS_Firing_Wait && kAction.m_fHangBreakoutTime > 1.0)
			{
				if(bLogEnabled)
				{
					PRES().GetAnchoredMessenger().Message("szmind: Suppression bug detected on" @ kSuppressor @ kSuppressor.SafeGetCharacterFullName(), 0.5, 0.5,Center,3.0,,eIcon_ExclamationMark);
					PRES().GetAnchoredMessenger().Message("Re-initing suppression shot for" @ kSuppressor.SafeGetCharacterFullName(), 0.5, 0.6,Center,3.0,,eIcon_ExclamationMark);
				}
				kAction.GotoState('Firing');
			}
		}
	}
}
function ModFireAction(XGAction_Fire kFireAction)
{
	return;
	if(m_watchVar_FireDebug != -1)
	{
		GetWorldInfo().MyWatchVariableMgr.UnRegisterWatchVariable(m_watchVar_FireDebug);
		GetWorldInfo().MyWatchVariableMgr.UnRegisterWatchVariable(m_watchVar_FireHangBreakout);
	}
	m_watchVar_FireHangBreakout = 0;
	if(bLogEnabled)
	{
		PRES().GetMessenger().Message(kFireAction.m_kUnit.SafeGetCharacterFullName() @ "performs" @ kFireAction);
		SetTimer(1.0, true, 'LogDebugFireInfo');
	}
//	m_watchVar_FireDebug = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(kFireAction, 'm_eFireActionStatus', self, LogDebugFireInfo);
//	m_watchVar_FireHangBreakout = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(kFireAction, 'm_fHangBreakoutTime', self, LogDebugFireInfo);
}
function LogDebugFireInfo()
{
	local XGAction_Fire kFireAction;
	
	kFireAction = XGAction_Fire(GRI().GetBattle().m_kActivePlayer.GetActiveUnit().GetAction());
	if(kFireAction != none)
	{
		PRES().GetMessenger().Message(kFireAction @ "state:" @ kFireAction.GetStateName() @ (GRI().m_kCameraManager.WaitForCamera() ? "waiting for camera" : "") @ ++m_watchVar_FireHangBreakout);
		if(GRI().m_kCameraManager.WaitForCamera() && m_watchVar_FireHangBreakout > 5)
		{
			PRES().GetMessenger().Message("Debugging...");
			GRI().m_kCameraManager.ClearCameraWaitFlag();
		}
	}
	else
	{
		PRES().GetMessenger().Message("Stopped watching fire action");
		ClearTimer(GetFuncName());
	}
}
defaultproperties
{
	m_watchVar_CurrAction=-1
	m_watchVar_ActiveUnit=-1
	m_watchVar_InfoBox=-1
	m_watchVar_TargetLoc=-1
	m_watchVar_FireDebug=-1
}