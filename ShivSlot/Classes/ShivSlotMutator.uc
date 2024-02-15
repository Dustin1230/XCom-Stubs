class ShivSlotMutator extends XComMutator config(ModShivSlot);

struct TConfigShivTech
{
	var int iTech;
	var int iFoundryTech;
	var int iSlots;
};
var config bool SHIV_SLOT_ENABLED;
var config int NUM_SHIV_SLOTS;
var config bool REQUIRES_SUPERSKYRANGER;
var config bool ENABLE_COVERTOPS_EXTRACTIONS;
var config bool ENABLE_COVERTOPS_DATARECOVERY;
var config bool ENABLE_TERROR;
var config bool ENABLE_ALIEN_BASE;
var config array<TConfigShivTech> UnlockTech;
var bool m_bVerboseLog;
var string m_strBuildVersion;
var int m_hWatchLaunchMission;
var int m_hWatchSoldierView;
var int m_hWatchHelpBar;
var XGShip_Dropship m_kDropShiv;
var XGShip_Dropship m_kSkyranger;
var array<XGStrategySoldier> m_arrAllSoldiers;
var array<XGStrategySoldier> m_arrShivs;
var UIModInputGate m_kInputHelper;
var ShivSlotOptionsContainer m_kModMenuOptions;
var localized string m_strShivSlotLabel;
var XGStrategySoldier kS;

function string GetDebugName()
{
	return Class.Name @ "v." @ m_strBuildVersion;
}
function ToggleVerboseLog()
{
	m_bVerboseLog = !m_bVerboseLog;
}
function XComHQPresentationLayer PRES()
{
	return XComHQPresentationLayer(XComPlayerController(GetALocalPlayerController()).m_Pres);
}
function XGStrategy STRATEGY()
{
	if(XComHeadquartersGame(WorldInfo.Game) != none)
	{
		return XComHeadquartersGame(WorldInfo.Game).GetGameCore();
	}
	else return none;
}
event PostBeginPlay()
{
	super.PostBeginPlay();
	default.NUM_SHIV_SLOTS == Max(1, default.NUM_SHIV_SLOTS);
	NUM_SHIV_SLOTS = Max(1, default.NUM_SHIV_SLOTS);
	SignUpToModManager();
	SetTimer(1.0, true, 'StrategyLoadedCheck');
	`log(GetDebugName() @ "online");
}
function StrategyLoadedCheck()
{
	if(PRES() != none && PRES().m_bPresLayerReady && STRATEGY() != none && STRATEGY().HANGAR() != none)
	{
		ClearTimer(GetFuncName());
		WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kSquadSelect', self, OnSquadSelect);
		//DebugAddShivs();
		m_kSkyranger = STRATEGY().HANGAR().m_kSkyranger;
		InitDropshiv();
		SignUpToModManager();
		//debug FIXME!!!!
		foreach STRATEGY().HANGAR().GetDropship().m_arrSoldiers(kS)
		{
			STRATEGY().BARRACKS().DetermineTimeOut(kS);
			STRATEGY().BARRACKS().HealAndRest();
			STRATEGY().BARRACKS().SetAllSoldierHQLocations();
		}
		m_kSkyranger.BARRACKS().ClearSquad(m_kSkyranger);
		m_kSkyranger.BARRACKS().m_aLastMissionSoldiers.Length = 0;
	}
}
function SignUpToModManager()
{
	if(class'UIModManager'.static.GetModMgr() != none)
	{
		class'UIModManager'.static.RegisterStartUpCallback(BuildDataForModManager);
	}
}
function XGShip_Dropship GetDropShiv()
{
	if(m_kDropShiv == none)
	{
		InitDropshiv();
	}
	return m_kDropShiv;
}
function InitDropshiv()
{
	local XGShip_Dropship kDropship;

	if(m_kDropShiv == none)
	{
		foreach DynamicActors(class'XGShip_Dropship', kDropship)
		{
			if(kDropship.GetCallsign() == "ShivSlot")
			{
				m_kDropShiv = kDropship;
				break;
			}
		}
		if(m_kDropShiv == none)
		{
			m_kDropShiv = Spawn(class'XGShip_Dropship');
			m_kDropShiv.m_strCallsign = "ShivSlot";
		}
	}
}
function OnSquadSelect()
{
	if(PRES().m_kSquadSelect!= none)
	{
		if(!IsInState('State_ChooseSquad'))
		{
			PushState('State_ChooseSquad');
		}
	}
	else if(GetStateName() == 'State_ChooseSquad')
	{
		PopState();
	}
}
function CacheBarracks()
{
	local XGStrategySoldier kSoldier;

	m_arrAllSoldiers = STRATEGY().BARRACKS().m_arrSoldiers;
	foreach m_arrAllSoldiers(kSoldier)
	{
		if(kSoldier.IsATank() && m_arrShivs.Find(kSoldier) < 0)
		{
			m_arrShivs.AddItem(kSoldier);
		}
	}
}

function UpdateSquadSelectView();

function int GetNumOfShivSlots()
{
	local TConfigShivTech tUnlock;

	NUM_SHIV_SLOTS = default.NUM_SHIV_SLOTS;
	foreach UnlockTech(tUnlock)
	{
		if(tUnlock.iFoundryTech > 0 && STRATEGY().ENGINEERING().IsFoundryTechResearched(tUnlock.iFoundryTech))
		{
			NUM_SHIV_SLOTS += tUnlock.iSlots;
		}
		if(tUnlock.iTech > 0 && STRATEGY().LABS().IsResearched(tUnlock.iTech))
		{
			NUM_SHIV_SLOTS += tUnlock.iSlots;
		}
	}
	return Min(12 - m_kSkyranger.GetCapacity(), NUM_SHIV_SLOTS);
}

function bool IsShivSlotActivated()
{
	if(GetNumOfShivSlots() == 0)
	{
		return false;
	}
	if(STRATEGY().TECHTREE().m_arrFoundryTechs.Length < 30)
	{
		return SHIV_SLOT_ENABLED;//vanilla EW
	}
	else
	{ 
		return SHIV_SLOT_ENABLED && (!REQUIRES_SUPERSKYRANGER || STRATEGY().ENGINEERING().IsFoundryTechResearched(37)); 
	}
}
function bool MissionTypeAllowsShivSlot()
{
	local bool bAllowed;

	switch(m_kSkyranger.m_kMission.m_iMissionType)
	{
	case eMission_CovertOpsExtraction:
		bAllowed = ENABLE_COVERTOPS_EXTRACTIONS;
		break;
	case eMission_CaptureAndHold:
		bAllowed = ENABLE_COVERTOPS_DATARECOVERY;
		break;
	case eMission_TerrorSite:
		bAllowed = ENABLE_TERROR;
		break;
	case eMission_AlienBase:
		bAllowed = ENABLE_ALIEN_BASE;
		break;
	case eMission_HQAssault:
		bAllowed = false;
		break;
	default:
		bAllowed = true;
	}
	return bAllowed;
}
function DebugAddShivs()
{
	local int i, iNumShivs;
	local XGFacility_Barracks kBarracks;

	kBarracks = STRATEGY().BARRACKS();
	for(i=0; i<kBarracks.m_arrSoldiers.Length; ++i)
	{
		if(kBarracks.m_arrSoldiers[i].IsATank() && kBarracks.m_arrSoldiers[i].m_iTurnsOut == 0)
			++iNumShivs;
	}
	if(iNumShivs < 2)
	{
		STRATEGY().STORAGE().AddItem(100, 2);
	}
}
function ToggleChooseSquadView()
{
	local UISquadSelect kUI;

	`log(GetFuncName(),m_bVerboseLog,Class.Name);

	kUI = PRES().m_kSquadSelect;
	if(kUI != none)
	{
		ClearPawns();
		ToggleDropShip();
		if(IsShivSlotView())
		{
			CleanUpSquadList();
		}
		kUI.GetMgr().UpdateView();
		UpdateSquadSelectView();
	}
}
function OnHelpBarUpdate()
{
	local UISquadSelect kUI;
	local int i;

	`log(GetFuncName(),m_bVerboseLog,Class.Name);
	kUI = PRES().m_kSquadSelect;
	if(IsShivSlotView())
	{
		for(i=0; i < kUI.m_kHelpBar.m_arrButtonClickDelegates.Length; ++i)
		{
			if(kUI.m_kHelpBar.m_arrButtonClickDelegates[i] == kUI.OnMouseCancel)
			{
				kUI.m_kHelpBar.m_arrButtonClickDelegates[i] = ToggleChooseSquadView;
			}
		}
	}
	if(IsShivSlotActivated() && MissionTypeAllowsShivSlot())
	{
		m_kInputHelper.BringToTopOfScreenStack();
	}
}

function ToggleDropShip()
{
	`log(GetFuncName(),m_bVerboseLog,Class.Name);
	if(CurrentDropship() == GetDropShiv())
	{
		STRATEGY().HANGAR().m_kSkyranger = m_kSkyranger;
		STRATEGY().BARRACKS().m_arrSoldiers = m_arrAllSoldiers;
		PRES().m_kSquadSelect.m_kSquadList.m_iMaxSlots = m_kSkyranger.GetCapacity();
	}
	else
	{
		STRATEGY().HANGAR().m_kSkyranger = m_kDropShiv;
		m_kDropShiv.m_kMission = m_kSkyranger.m_kMission;
		STRATEGY().BARRACKS().m_arrSoldiers = m_arrShivs;
		PRES().m_kSquadSelect.m_kSquadList.m_iMaxSlots = GetNumOfShivSlots();
	}
}
function ClearPawns()
{
	local XGStrategySoldier kSoldier;
	local XGShip_Dropship kSkyranger;

	kSkyranger = CurrentDropship();
	foreach kSkyranger.m_arrSoldiers(kSoldier)
	{
		kSoldier.SetHQLocation(eSoldierLoc_Barracks);
		kSoldier.DestroyPawn();
	}
}
function CleanUpSquadList()
{
	local UISquadSelect_SquadList kList;
	local int iBox;
	local array<ASValue> arrParams;
	local GFxObject gfxBox;

	if(IsShivSlotView())
	{
		kList = PRES().m_kSquadSelect.m_kSquadList;
		for(iBox=0; iBox < 12; ++iBox)
		{
			kList.m_arrUIOptions[iBox].bHint = false;
			if(iBox < 6 - GetNumOfShivSlots()/2 || iBox >= 6 + GetNumOfShivSlots()/2)
			{
				arrParams.Length = 0;
				gfxBox = kList.manager.GetVariableObject(kList.GetMCPath() $ ".unit"$iBox);
				gfxBox.Invoke("ClearUnitText", arrParams);
				gfxBox.Invoke("ClearAddUnitText", arrParams);
				gfxBox.Invoke("RefreshAddUnit", arrParams);
				gfxBox.Invoke("Hide", arrParams);
			}
		}
	}
}
function bool OnButtonPress(int Cmd, int Arg)
{
	if(IsShivSlotView())
	{
		switch(Cmd)
		{
		case 303:
			if(PRES().m_kSquadSelect.m_iView == 0)
			{
				PRES().m_kSquadSelect.GetMgr().PlayBadSound();
				return true;
			}
			break;
        case 301:
        case 510:
        case 405:
            if(PRES().m_kSquadSelect.m_iView == 0)
            {
                ToggleChooseSquadView();
                PRES().m_kSquadSelect.GetMgr().PlaySmallCloseSound();
				return true;
            }
			break;
        default:
			return PRES().m_kSquadSelect.OnUnrealCommand(Cmd, Arg);
		}
	}
	else if(PRES().m_kSquadSelect.m_iView == 0 && (Cmd == class'UI_FxsInput'.const.FXS_BUTTON_LBUMPER || Cmd == class'UI_FxsInput'.const.FXS_KEY_TAB))
	{
		ToggleChooseSquadView();
		return true;
	}
	else return PRES().m_kSquadSelect.OnUnrealCommand(Cmd, Arg);
}

function OnLaunchMission()
{
	local XGStrategySoldier kTank;

	`log(GetFuncName(),m_bVerboseLog,Class.Name);
	if(m_kSkyranger.m_kMission != none && m_kSkyranger.m_kMission.m_kDesc.m_strTime != "")
	{
		foreach m_kDropShiv.m_arrSoldiers(kTank)
		{
			if(kTank != none && m_kSkyranger.m_arrSoldiers.Find(kTank) < 0)
			{
				m_kSkyranger.m_arrSoldiers.AddItem(kTank);
			}
		}
		m_kDropShiv.m_arrSoldiers.Length = 0;
	}
}
function bool IsShivSlotView()
{
	return CurrentDropship() == m_kDropShiv;
}
function XGShip_Dropship CurrentDropship()
{
	return STRATEGY().HANGAR().m_kSkyranger;
}
function BuildDataForModManager()
{
	foreach DynamicActors(class'ShivSlotOptionsContainer', m_kModMenuOptions)
	{
		break;
	}
	if(m_kModMenuOptions == none)
	{
		m_kModMenuOptions = Spawn(class'ShivSlotOptionsContainer');
	}
	m_kModMenuOptions.Init(self);
}
state State_ChooseSquad
{
	event PushedState()
	{
		`log(GetFuncName() @ GetStateName(),,Name);
		UnregisterWatchVars();
		m_kInputHelper = Spawn(class'UIModInputGate');
	}
	event PoppedState()
	{
		`log(GetFuncName() @ GetStateName(),,Name);
		UnregisterWatchVars();
		m_kInputHelper.PopFromScreenStack();
		m_kInputHelper.Destroy();
		m_kInputHelper=none;
	}
	event ContinuedState()
	{
		`log(GetFuncName() @ GetStateName(),,Name);
		UpdateSquadSelectView();
	}
	function UnregisterWatchVars()
	{
		if(m_hWatchLaunchMission != -1)
		{
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_hWatchLaunchMission);
			m_hWatchLaunchMission = -1;
		}
		if(m_hWatchSoldierView!= -1)
		{
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_hWatchSoldierView);
			m_hWatchSoldierView = -1;
		}
		if(m_hWatchHelpBar != -1)
		{
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_hWatchHelpBar);
			m_hWatchHelpBar = -1;
		}
	}
	function RegisterWatchVars()
	{
		m_hWatchLaunchMission = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kSkyranger.m_kMission.m_kDesc, 'm_strTime', self, OnLaunchMission);
		m_hWatchSoldierView = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES().m_kSquadSelect.m_kSquadList, 'm_bInSoldierView', self, UpdateSquadSelectView);
		m_hWatchHelpBar = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES().m_kSquadSelect.m_kHelpBar, 'm_arrButtonClickDelegates', self, OnHelpBarUpdate);
	}
	function UpdateSquadSelectView()
	{
		local UIModGfxButton gfxButton;

		`log(GetFuncName(),,Name);
		if(!PRES().IsInState('State_ChooseSquad'))
		{
			`log(GetFuncName() @ "skipped, Pres not in State_ChooseSquad",,Name);
			return;
		}
		if(IsShivSlotActivated() && MissionTypeAllowsShivSlot() && GetNumOfShivSlots() > 0)
		{
			if(!IsShivSlotView())
			{
				gfxButton = UIModGfxButton(class'UIModUtils'.static.BindMovie(PRES().m_kSquadSelect.manager.GetVariableObject(string(PRES().m_kSquadSelect.GetMCPath())), "XComButton", "ShivSlotButton", class'UIModGfxButton',PRES().m_kSquadSelect.manager));
				class'UIModUtils'.static.AS_OverrideClickButtonDelegate(gfxButton, ToggleChooseSquadView);
				if(PRES().GetHUD().IsMouseActive())
				{
					gfxButton.AS_SetStyle(4);
				}
				else
				{
					gfxButton.AS_SetStyle(3);
				}
				if(m_strShivSlotLabel != "")
				{
					gfxButton.AS_SetHTMLText(class'UIUtilities'.static.GetHTMLColoredText(m_strShivSlotLabel, eUIState_Normal));
				}
				else
				{
					gfxButton.AS_SetHTMLText(class'UIUtilities'.static.GetHTMLColoredText(Localize("XGCharacter_Tank", "m_sFirstName", "XComGame"), eUIState_Normal));
				}
				gfxButton.AS_SetIcon(class'UI_FxsGamepadIcons'.const.ICON_LB_L1);
				gfxButton.SetPosition(640 - gfxButton.GetFloat("_width")/2, 50);
			}
			else
			{
				PRES().m_kSquadSelect.manager.GetVariableObject(PRES().m_kSquadSelect.GetMCPath() $ ".ShivSlotButton").SetVisible(false);
				PRES().m_kSquadSelect.GetMgr().m_txtLaunch.iState = 1;
			}
			PRES().m_kSquadSelect.UpdateButtonHelp();
			OnHelpBarUpdate();
		}
	}
Begin:
	CacheBarracks();
	while(XComHeadquartersCamera(XComPlayerController(PRES().Owner).PlayerCamera).IsMoving())
	{
		Sleep(0.10);
	}
	m_kInputHelper.GateInit(PRES().m_kSquadSelect,,OnButtonPress);
	UpdateSquadSelectView();
	ClearPawns();
	m_kSkyranger.BARRACKS().ClearSquad(m_kSkyranger);
	RegisterWatchVars();
}
state UpdatingOptions
{
Begin:
	BuildDataForModManager();
}
DefaultProperties
{
	m_strBuildVersion="1.02"
	m_bVerboseLog=false
}
