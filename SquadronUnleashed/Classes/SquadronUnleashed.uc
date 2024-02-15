class SquadronUnleashed extends XComMutator
	config(SquadronUnleashed);

struct TShipWeaponSU
{
	var int iWeaponType;
	var bool bPrimary;
	var bool bSecondary;
	var bool bClose;
	var int iAmmo;
	var int RearmHours;
	var int iAimMod;
	var int iAimModClose;
	var int iCritChanceMod;
	var float fDmgMod;
	var int iDmgMod;
	var float fCritDmgMod;
	var int iCritDmgMod;

	structdefaultproperties
	{
		iAmmo=-1;
		bPrimary=true;
	}
};
struct TBaseShipWeapon
{
	var EShipWeapon eType;
	var int iDamage;
	var int iArmorPen;
	var int iToHit;
	var int iAvionicsBonus;
	var int iCooldown;
};
struct TBaseShipTemplate
{
	var int iShipType;
	var int iWeapon1;
	var int iWeapon2;
	var int iGeoSpeed;
	var int iBattleSpeed;
	var int iHP;
	var int iArmor;
	var int iAP;

	structdefaultproperties
	{
		iWeapon1=8;
	}
};
struct TShipWeaponBalanceMod
{
	var int iDifficulty;
	var int iWeaponType;
	var int iAimMod;
	var float fDmgMod;
	var int iAPMod;

	structdefaultproperties
	{
		iDifficulty=-1;
	}
};
struct TShipBalanceMod
{
	var int iDifficulty;
	var int iShipType;
	var float fHPMod;
	var int iHPMod;
	var int iArmorMod;
	var int iAPMod;
	var int iSpeedMod;

	structdefaultproperties
	{
		iDifficulty=-1;
	}
};

var string m_strBuildVersion;
var string m_strDebugTxt;
var int m_iWatchMissionControl;
var int m_iWatchActiveAlert;
var int m_iWatchHangarBays;
var int m_iWatchHangarOrders;
var int m_iWatchHangarTransfers;
var int m_iWatchShipTemplates;
var int m_iWatchWeaponTemplates;
var int m_optTutorialButtonID;
var int m_iRefuellingHours;
var config bool bVerboseLog;
var bool m_bInitialized;
var bool m_bAmmoLimits;
var XGRecapSaveData m_kSaveData;
var SU_UFOAlert m_kSqUFOContact;
var XGShip_UFO m_kInterceptedUFO;
var SU_UIShipLoadout m_kShipLoadoutSecondary;
var UIShipLoadout m_kShipLoadoutPrimary;
var SU_UIStrategyHUD_FSM_Hangar m_kHangarMenu;
var SU_UIPilotRoster m_kPilotRosterUI;
var SU_UIPilotCard m_kPilotCard;
var array<SU_WatchShipMgr> m_arrWatchShipManagers;
var SU_PilotRankMgr m_kRankMgr;
var SU_PilotQuarters m_kPilotQuarters;
var SU_PilotTrainingCentre m_kPilotTrainingCenter;
var SU_UIAirforceCommand m_kAirforceCommand;
var SU_UIPilotTraining m_kPilotTrainingUI;
var SU_UIInputGate MyInputGate;
var SU_HelpManager m_kHelpMgr;
var SU_SoundMgr m_kSoundMgr;
var SUTickMutator m_kTickMutator;
var SU_ModOptionsContainer m_kOptionsContainer;
var bool m_bTutorial;
var config bool m_bTutorialPrompt;
var config byte eUFOStanceAIsetting;
var config byte eFixedUFOStance;
var config int MIN_SQUADRON_SIZE;
var config int MAX_SQUADRON_SIZE;
var config array<int> AGGRO_FOR_WEAPON;
var config int AGGRO_FOR_BAL;
var config int AGGRO_FOR_DEF;
var config int AGGRO_FOR_AGG;
var config int AGGRO_FOR_FIRESTORM;
var config int INTERCEPTION_TWEAK_SCALER;
var config int AGG_JET_AIM_BONUS;
var config int AGG_JET_DMG_BONUS;
var config int AGG_JET_FORCE_HIT_CHANCE;
var config float AGG_JET_DMG_VULNERABILITY;
var config int AGG_UFO_AIM_BONUS;
var config float AGG_UFO_SPEED_DOWN;
var config float AGG_UFO_FIRERATE_BOOST;
var config int DEF_JET_AIM_PENALTY;
var config int DEF_JET_DODGE_CHANCE;
var config int DEF_UFO_AIM_PENALTY;
var config float DEF_UFO_SPEED_BOOST;
var config int DEF_MAX_HIT_CHANCE;
var config int BAL_MAX_HIT_CHANCE;
var config int AGG_MAX_HIT_CHANCE;
var config int LONE_BULLET_CHANCE_BAL;
var config int LONE_BULLET_CHANCE_AGG;
var config float LONE_BULLET_DMG_MOD; 
var config int AIM_PENALTY_VS_SMALL_UFO;
var config int AIM_BONUS_VS_LARGE_UFO;
var config int AIM_BONUS_PER_KILL;
var config int MAX_AIM_BONUS_FOR_KILLS;
var config int AIM_BONUS_CLOSE_DISTANCE_GLOBAL;
var config float XCOM_DMG_MODIFIER_GLOBAL;
var config float UFO_HP_MODIFIER_GLOBAL;
var config float EXTRA_DMG_PCT_PER_KILL;
var config float EXTRA_DMG_FOR_RESEARCH;
var config int DAMAGED_JET_AIM_PENALTY;
var config float DAMAGED_JET_HP_PCT_CAN_FIGHT;
var config float DAMAGED_SPEED_PENALTY;
var config float GLOBAL_ENGAGEMENT_TIME_MULTIPLIER;
var config float CRIT_DMG_MULTIPLIER;
var config int CRIT_MIN_CHANCE;
var config int CRIT_MAX_CHANCE;
var config float SECONDARY_WPN_DMG_MOD;
var config bool ALWAYS_SHOW_UFO_HP;
var config bool bAutoSortShipList;
var config bool bInterceptionTweakOn;
var config float TIME_SLOMO_FACTOR;
var config array<TShipWeaponSU> ShipWeapons;
var config array<TShipBalanceMod> Balance_Ships;
var config array<TShipWeaponBalanceMod> Balance_ShipWeapons; 
var config TBaseShipWeapon VulcanCannon;
var config int HANGAR_CAPACITY;
var config int INTERCEPTOR_REFUEL_HOURS;
var config int PILOT_TRANSFER_HOURS;
var config int PILOT_RECOVER_AFTER_COMBAT_HOURS;
var config int PILOT_SURVIVAL_CHANCE_FLAT;
var config int PILOT_SURVIVAL_CHANCE_PER_RANK;
var config bool PILOT_CMDR_NEVER_DIES;
var config int PILOT_WOUND_CHANCE_ON_SHOTDOWN;
var config int PILOT_HEAL_DAYS;
var config int PILOT_COST_TO_HIRE;
var config int PILOT_COST_MONTHLY;
var config float AGG_TACTIC_AUTOBACKOFF_HP_PCT;
var config float AGG_TACTIC_AUTOABORT_HP_PCT;
var config bool AGG_TACTIC_START_CLOSE;
var config float BAL_TACTIC_AUTOBACKOFF_HP_PCT;
var config float BAL_TACTIC_AUTOABORT_HP_PCT;
var config bool BAL_TACTIC_START_CLOSE;
var config float DEF_TACTIC_AUTOBACKOFF_HP_PCT;
var config float DEF_TACTIC_AUTOABORT_HP_PCT;
var config bool DEF_TACTIC_START_CLOSE;
var config bool m_bDisablePilotXP;
var config string m_strVulcanCanonImgPath;
var config array<string> PilotVoiceSet;
var localized string m_strLabelLaunchFighter;
var localized string m_strLabelLaunchFighters;
var localized string m_strStanceDEF;
var localized string m_strStanceBAL;
var localized string m_strStanceAGG;
var localized string m_strAggro;
var localized string m_strLabelHullStrength;
var localized string m_strNoPilotAssigned;
var localized string m_strNoShipAssigned;
var localized string m_strDaysOutOfService;
var localized string m_strResetTutorialTitle;
var localized string m_strResetTutorialText;

function string GetDebugName()
{
	return GetItemName(string(default.Class)) @ m_strBuildVersion;
}
event PostBeginPlay()
{
	if(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game) != none)
		SetTimer(0.50, true, 'StrategyLoadedCheck');
	m_kRankMgr = Spawn(class'SU_PilotRankMgr');
	SignUpToModManager();
	if(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).LoggedInPlayerName == "szmind")
	{
		class'SquadronUnleashed'.default.bVerboseLog = true;
		bVerboseLog = true;
	}
}
function SignUpToModManager()
{
	if(class'UIModManager'.static.GetModMgr() != none)
	{
		class'UIModManager'.static.RegisterStartUpCallback(BuildDataForModManager);
	}
}
function BuildDataForModManager()
{
	foreach DynamicActors(class'SU_ModOptionsContainer', m_kOptionsContainer)
	{
		break;
	}
	if(m_kOptionsContainer == none)
	{
		m_kOptionsContainer = Spawn(class'SU_ModOptionsContainer');
	}
	m_kOptionsContainer.Init(self);//this reads and caches all ModRecord and ModOption... lines from .ini)
}
function Mutate(string strMutateCall, PlayerController PC)
{
	if(strMutateCall ~= "UninitSU")
	{
		UnInit();
	}
	super.Mutate(strMutateCall, PC);
}
static function bool IsLWR()
{
	return class'UIModManager'.static.GetMutator("LWRebalance.RebalanceMutator") != none;;
}
function StrategyLoadedCheck()
{
	if(PRES() != none && PRES().m_bPresLayerReady && class'SU_Utils'.static.HANGAR() != none)
	{
		ClearTimer(GetFuncName());//stop timer loop
		m_kSaveData = class'XGSaveHelper'.static.GetSaveData("SquadronUnleashed");
		m_bTutorial = class'XGSaveHelper'.static.GetProfileStatValue("SquadronUnleashed.m_bTutorial") > 0 ? true : false;
		m_kHelpMgr = Spawn(class'SU_HelpManager');
		m_kSoundMgr = Spawn(class'SU_SoundMgr', self);
		CacheTickMutator();
		m_kRankMgr.BuildCareerPaths();
		InitTrainingCenter();
		UpdateShipTemplates();
		UpdateShipWeaponsTemplates();
		UpdateAllShipLoadouts();
		InitPilotQuarters();
		FigureOutRefuellingHours();
		UpdateWatchVars();
		InitWatchShipManagers();
		ClearInterceptions();
		SignUpToModManager();
		if(class'SU_Utils'.static.GetGameCore().GEOSCAPE().m_kDateTime.DifferenceInDays(class'SU_Utils'.static.GetGameCore().AI().m_kStartDate) <= 1)
		{
			TutorialDialog();
		}
		SetTimer(1.0, false, 'GetCanvas');
		m_bInitialized=true;
		//`Log(GetFuncName() @ GetDebugName() @ "PackagesToFullyLoad.Length=" @ XComEngine(class'Engine'.static.GetEngine()).PackagesToFullyLoad.Length);
	}
}
function GetCanvas()
{
	if(GetALocalPlayerController().myHUD.Canvas == none)
	{
		GetALocalPlayerController().myHUD.Canvas = new (GetALocalPlayerController().myHUD) class'Canvas';
	}
}
function InitPilotQuarters()
{
	local SU_PilotQuarters kQuarters;

	foreach DynamicActors(class'SU_PilotQuarters', kQuarters)
	{
		m_kPilotQuarters = kQuarters;
		m_kPilotQuarters.Init(true);
	}
	if(m_kPilotQuarters == none)
	{
		m_kPilotQuarters = Spawn(class'SU_PilotQuarters');
		m_kPilotQuarters.Init(false);
	}
}
function InitTrainingCenter()
{
	local SU_PilotTrainingCentre kTraining;
	local bool bFromSave;

	foreach DynamicActors(class'SU_PilotTrainingCentre', kTraining)
	{
		m_kPilotTrainingCenter = kTraining;
		bFromSave = true;
	}
	if(m_kPilotTrainingCenter == none)
	{
		m_kPilotTrainingCenter = Spawn(class'SU_PilotTrainingCentre');
	}
	m_kPilotTrainingCenter.Init(bFromSave);
}
function CacheTickMutator()
{
	foreach DynamicActors(class'SUTickMutator', m_kTickMutator)
	{
		break;
	}
	if(m_kTickMutator == none)
	{
		WorldInfo.Game.AddMutator("SquadronUnleashed.SUTickMutator", true);
	}
}
function UpdateWatchVars()
{
	if(!m_bInitialized)
	{
		m_iWatchHangarBays = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(class'SU_Utils'.static.HANGAR(), 'm_arrInts', self, UpdateWatchShipManagers);
		WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_aStateStack', self, OnPresentationLayerStateChange);
		WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(class'SU_Utils'.static.GetGameCore().ENGINEERING(), 'm_arrFoundryHistory', self, UpdateVulcanCannon);
	}
	if(m_iWatchShipTemplates != -1)
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchShipTemplates);
	m_iWatchShipTemplates = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(class'SU_Utils'.static.ITEMTREE(), 'm_arrShips', self, UpdateShipTemplates);

	if(m_iWatchWeaponTemplates != -1)
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchWeaponTemplates);
	m_iWatchWeaponTemplates = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(class'SU_Utils'.static.ITEMTREE(), 'm_arrShipWeapons', self, UpdateShipWeaponsTemplates);

		`Log(m_strDebugTxt, bVerboseLog && m_strDebugTxt != "", 'SquadronUnleashed');
}
function FigureOutRefuellingHours()
{
	local XGShip_Interceptor kTestJet;

	kTestJet = Spawn(class'XGShip_Interceptor');
	kTestJet.Init(class'SU_Utils'.static.ITEMTREE().GetShip(eShip_Interceptor));
	kTestJet.m_fFlightTime = 10000;
	class'SU_Utils'.static.HANGAR().DetermineInterceptorStatus(kTestJet);
	m_iRefuellingHours = kTestJet.m_iHoursDown;
	if(default.INTERCEPTOR_REFUEL_HOURS != 0)
	{
		m_iRefuellingHours = default.INTERCEPTOR_REFUEL_HOURS;
	}
	kTestJet.Destroy();
}
function UpdateShipTemplates()
{
	local array<TShipBalanceMod> arrShipBalanceMods;
	local TShipBalanceMod tShipMod;
	local XGItemTree kItems;
	local int i, iDifficultyLevel;

	if(m_iWatchShipTemplates != -1)
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchShipTemplates);
	}
	kItems = class'SU_Utils'.static.ITEMTREE();
	arrShipBalanceMods.Add(kItems.m_arrShips.Length);
	iDifficultyLevel = class'SU_Utils'.static.GetGameCore().GetDifficulty();
	foreach class'SquadronUnleashed'.default.Balance_Ships(tShipMod)
	{
		if(tShipMod.iDifficulty == iDifficultyLevel)
		{
			if(arrShipBalanceMods.Length < tShipMod.iShipType + 1)
			{
				arrShipBalanceMods.Length = tShipMod.iShipType;
			}
			arrShipBalanceMods[tShipMod.iShipType] = tShipMod;
		}
	}
	if(kItems.m_arrShips[5].iArmor > class'XGTacticalGameCore'.default.ContBalance_Classic[5].iScientists2)
	{
		//current destroyer template has armor higher than normal destroyer, so it's improved
		arrShipBalanceMods[5] = arrShipBalanceMods[15];
	}
	for(i=0; i < kItems.m_arrShips.Length; ++i)
	{
		if(arrShipBalanceMods[i].fHPMod > 0.0)
		{
			kItems.m_arrShips[i].iHP *= arrShipBalanceMods[i].fHPMod;
		}
		if(UFO_HP_MODIFIER_GLOBAL != 0.0 && i > 3)
		{
			kItems.m_arrShips[i].iHP *= UFO_HP_MODIFIER_GLOBAL;		
		}
		kItems.m_arrShips[i].iHP += arrShipBalanceMods[i].iHPMod;
		kItems.m_arrShips[i].iArmor += arrShipBalanceMods[i].iArmorMod;
		kItems.m_arrShips[i].iAP += arrShipBalanceMods[i].iAPMod;
		kItems.m_arrShips[i].iEngagementSpeed += arrShipBalanceMods[i].iSpeedMod;
	}
	kItems.UpdateAllShipTemplates();
	UpdateWatchVars();
}
function UpdateShipWeaponsTemplates()
{
	local array<TShipWeaponBalanceMod> arrWeaponBalanceMods;
	local TShipWeaponBalanceMod tWeaponMod;
	local XGItemTree kItems;
	local int i, iDifficultyLevel;

	if(m_iWatchWeaponTemplates != -1)
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchWeaponTemplates);
	}
	UpdateVulcanCannon();
	kItems = class'SU_Utils'.static.ITEMTREE();
	arrWeaponBalanceMods.Add(kItems.m_arrShipWeapons.Length);
	iDifficultyLevel = class'SU_Utils'.static.GetGameCore().GetDifficulty();
	foreach class'SquadronUnleashed'.default.Balance_ShipWeapons(tWeaponMod)
	{
		if(tWeaponMod.iDifficulty == iDifficultyLevel)
		{
			arrWeaponBalanceMods[tWeaponMod.iWeaponType] = tWeaponMod;
		}
	}
	for(i=0; i < kItems.m_arrShipWeapons.Length; ++i)
	{
		if(arrWeaponBalanceMods[i].fDmgMod > 0.0)
		{
			kItems.m_arrShipWeapons[i].iDamage *= arrWeaponBalanceMods[i].fDmgMod;
		}
		if(XCOM_DMG_MODIFIER_GLOBAL != 0 && i < 8)
		{
			kItems.m_arrShipWeapons[i].iDamage *= XCOM_DMG_MODIFIER_GLOBAL;
		}
		kItems.m_arrShipWeapons[i].iDamage *= class'SU_Utils'.static.GetWeaponDmgModPct(i);
		kItems.m_arrShipWeapons[i].iDamage += class'SU_Utils'.static.GetWeaponDmgModFlat(i);
		kItems.m_arrShipWeapons[i].iToHit += arrWeaponBalanceMods[i].iAimMod;
		kItems.m_arrShipWeapons[i].iToHit += class'SU_Utils'.static.GetWeaponAimMod(i);
		kItems.m_arrShipWeapons[i].iAP += arrWeaponBalanceMods[i].iAPMod;
	}
	UpdateWatchVars();
}

function UpdateVulcanCannon()
{
	if(default.VulcanCannon.iDamage > 0)
	{
		class'SU_Utils'.static.ITEMTREE().BuildShipWeapon(eShipWeapon_None, class'SU_Utils'.static.GetAmmoForWeaponType(0), 100, float(VulcanCannon.iCooldown)/100.0, VulcanCannon.iDamage, VulcanCannon.iArmorPen, VulcanCannon.iToHit + (class'SU_Utils'.static.GetGameCore().ENGINEERING().IsFoundryTechResearched(31) ? VulcanCannon.iAvionicsBonus : 0) + (class'SU_Utils'.static.GetGameCore().IsOptionEnabled(24) ? int(class'XGTacticalGameCore'.default.ABDUCTION_REWARD_SCI) : 0));
	}
	else
	{
		class'SU_Utils'.static.ITEMTREE().BuildShipWeapon(eShipWeapon_None, class'SU_Utils'.static.GetAmmoForWeaponType(0), 100, float(class'XGTacticalGameCore'.default.ContBalance_Classic[21].iEngineers1) / 100.0, class'XGTacticalGameCore'.default.ContBalance_Classic[21].iScientists1 * 3/4, 0, class'XGTacticalGameCore'.default.ContBalance_Classic[21].iScientists2 + (class'SU_Utils'.static.GetGameCore().ENGINEERING().IsFoundryTechResearched(31) ? class'XGTacticalGameCore'.default.ContBalance_Classic[21].iEngineers3 : 0) + (class'SU_Utils'.static.GetGameCore().IsOptionEnabled(24) ? int(class'XGTacticalGameCore'.default.ABDUCTION_REWARD_SCI) : 0));
	}
	class'SU_Utils'.static.ITEMTREE().m_arrShipWeapons[0].strName = class'SU_UIShipLoadout'.default.m_strVulcanCannonName;
}
function TestStuff()
{
}
function OnPresentationLayerStateChange()
{
	if(GetStateName() == PRES().m_LastPoppedState && !PRES().IsInStack(PRES().m_LastPoppedState))
	{
		PopState();
	}
	else if(GetStateName() == 'State_MC' && !PRES().IsInState('State_MC', true))
	{
		PopState();
	}
	if (GetStateName() != PRES().GetStateName() && StateIsModdable(PRES().GetStateName()) && !IsInState(PRES().GetStateName(), true))
	{
		PushState(PRES().GetStateName());
	}
	else if(PRES().GetStateName() == 'State_MC' && GetStateName() == 'State_MC')
	{
		ContinuedState();
	}
}
function bool StateIsModdable(name nTestState)
{
	switch(nTestState)
	{
	case 'State_MC':
	case 'State_HangarShipLoadout':
	case 'State_HangarShipList':
	case 'State_HangarShipSummary':
	case 'State_HangarMenu':
	case 'State_ItemCard':
	case 'State_WorldReport':
		return true;
	default:
		return false;
	}
}
function UIAssignPilot(XGShip_Interceptor kShip)
{
	m_kPilotRosterUI = PRES().Spawn(class'SU_UIPilotRoster', PRES());
	m_kPilotRosterUI.m_iView = 7;
	SU_XGHangarUI(class'SU_Utils'.static.PRES().GetMgr(class'SU_XGHangarUI', (m_kPilotRosterUI),7)).m_kShip = kShip;
	class'SU_Utils'.static.GetSquadronMod().PushState('State_HangarPilotRoster');
}
/** @param InitView 0 - main view, 1 - career view*/
function UIShowPilotCard(SU_Pilot kInitPilot, optional int InitView)
{
	m_kPilotCard = PRES().Spawn(class'SU_UIPilotCard', PRES());
	m_kPilotCard.InitWitPilot(kInitPilot, InitView);
}
function SU_UIInputGate GetMyInputGate(optional UI_FxsScreen kParentScreen)
{
	if(MyInputGate == none)
	{
		MyInputGate = class'SU_Utils'.static.PRES().Spawn(class'SU_UIInputGate', class'SU_Utils'.static.PRES());
		MyInputGate.PanelInit(XComPlayerController(class'SU_Utils'.static.PRES().Owner), class'SU_Utils'.static.PRES().GetHUD(), kParentScreen);
		MyInputGate.m_kMutator = self;
	}
	if(kParentScreen != none)
	{
		MyInputGate.screen = kParentScreen;
	}
	return MyInputGate;
}
function ClearInterceptions()
{
	local XGInterception kInterception;
	local XGShip_Interceptor kShip;
	local int iCount, iDebugShips;

	foreach DynamicActors(class'XGInterception', kInterception)
	{
		class'SU_Utils'.static.GEOSCAPE().RemoveInterception(kInterception);
		++iCount;
	}
	foreach DynamicActors(class'XGShip_Interceptor', kShip)
	{
		if(kShip.IsFlying() && kShip.m_kEngagement == none)
		{
			kShip.ReturnToBase();
			++iDebugShips;
		}
	}

	`Log("Destroyed" @ string(iCount) @ "redundant interceptions. NumShips sent to base:" @ iDebugShips, bVerboseLog, 'SquadronUnleashed');
}

function XGShip_UFO GetUFOFromAlert(optional UIMissionControl_UFOAlert kAlert)
{
	local XGMissionControlUI kMgr;
	local int iUFOindex;
	local XGShip_UFO kUFO;
	
	m_strDebugTxt = GetFuncName() @ kAlert $ ". Failed to find UFO!";
	kMgr = PRES().m_kUIMissionControl.GetMgr();
	if(UIMissionControl_UFORadarContactAlert(kAlert) != none && UIMissionControl_UFORadarContactAlert(kAlert).m_kInterceptMgr != none && UIMissionControl_UFORadarContactAlert(kAlert).m_kInterceptMgr.m_kUFO != none)
	{
		kUFO = UIMissionControl_UFORadarContactAlert(kAlert).m_kInterceptMgr.m_kUFO;
		m_strDebugTxt = GetFuncName() @ kAlert $ ". Picked UFO-" $ string(kUFO.m_iCounter) @ "from" @ string(kAlert);
	}
	else if(kMgr != none)
	{
		iUFOindex = int(Split(kMgr.m_kCurrentAlert.arrLabeledText[0].StrValue, class'XGMissionControlUI'.default.m_strLabelUFOPrefix,true));
		foreach class'SU_Utils'.static.AI().m_arrUFOs(kUFO)
		{
			if(kUFO.m_iCounter == iUFOindex)
			{
				m_strDebugTxt = GetFuncName() @ kAlert $ ". Picked UFO-" $ string(kUFO.m_iCounter) @ "from alert text data.";
				break;
			}
		}
	}
	`Log(m_strDebugTxt, bVerboseLog, 'SquadronUnleashed');
	return kUFO;
}

function SetRandomUFOStance()
{
	class'SU_Utils'.static.SetStance(m_kInterceptedUFO, Rand(3));
}
/** DEPRACATED*/
static function InitEngagementScreen(XGInterception kInterception)
{
	PRES().m_kInterceptionEngagement = PRES().Spawn(class'SU_UIInterceptionEngagement', PRES());
	PRES().Get3DMovie().LoadScreen(PRES().m_kInterceptionEngagement);
    PRES().Get3DMovie().ShowDisplay(class'UIInterceptionEngagement'.default.DisplayTag);
    PRES().CAMLookAtNamedLocation(class'UIInterceptionEngagement'.default.m_strCameraTag, 1.0);
    PRES().m_kInterceptionEngagement.Init(XComPlayerController(PC()), class'SU_Utils'.static.PRES().Get3DMovie(), kInterception);
    class'SU_Utils'.static.GEOSCAPE().m_bGlobeHidden = true;
}
function OnEnterExitShipLoadout()
{
	if(PRES().m_kShipLoadout != none && !IsInState('ModdingShipLoadout', true))
		PushState('ModdingShipLoadout');
	else if(GetStateName() == 'ModdingShipLoadout')
		PopState();
}
/** Ensures 2 weapons in ship arrays and fills arrWeapons[1] with correct SecondaryWeapon value.*/
function UpdateShipLoadout(XGShip_Interceptor kJet)
{
	local string sVal;

	kJet.m_kTShip.arrWeapons.Length = 2;
	sVal = class'SU_Utils'.static.GetSavedValue(kJet, "SecondaryWeapon");
	if(sVal != "")
	{
		kJet.m_kTShip.arrWeapons[1] = int(sVal);
	}
	else
	{
		kJet.m_kTShip.arrWeapons[1] = 0;
		class'SU_Utils'.static.SaveValue(kJet, "SecondaryWeapon", 0);
	}
}
/**Updates SecondaryWeapon slots for all xcom ships.*/
function UpdateAllShipLoadouts()
{
	local XGShip_Interceptor kJet;
	local XGFacility_Hangar kHangar;

	kHangar = class'SU_Utils'.static.HANGAR();
	foreach kHangar.m_arrInts(kJet)
	{
		UpdateShipLoadout(kJet);
	}
}
function SU_WatchShipMgr GetWatchShipMgr(XGShip_Interceptor kShip)
{
	local int i;

	for(i=0; i < m_arrWatchShipManagers.Length; ++i)
	{
		if(m_arrWatchShipManagers[i].m_kShip == kShip)
		{
			return m_arrWatchShipManagers[i];
		}
	}
	return none;
}
function InitWatchShipMgrFor(XGShip_Interceptor kInt)
{
	local SU_WatchShipMgr kNewMgr;

	kNewMgr = Spawn(class'SU_WatchShipMgr');
	kNewMgr.Init(kInt);
	m_arrWatchShipManagers.AddItem(kNewMgr);
}
function InitWatchShipManagers()
{
	local XGShip_Interceptor kJet;

	foreach DynamicActors(class'XGShip_Interceptor', kJet)
	{
		InitWatchShipMgrFor(kJet);
	}
}
function UpdateWatchShipManagers()
{
	local int i;
	local XGFacility_Hangar kHangar;
	local XGShip_Interceptor kJet;

	for(i=m_arrWatchShipManagers.Length-1; i >=0; --i)
	{
		if(!m_arrWatchShipManagers[i].IsValid())
		{
			m_arrWatchShipManagers.Remove(i, 1);
		}
	}
	kHangar = class'SU_Utils'.static.HANGAR();
	foreach kHangar.m_arrInts(kJet)
	{
		if(GetWatchShipMgr(kJet) == none)
		{
			InitWatchShipMgrFor(kJet);
		}
	}

}
/** Destroys all Squadron-related actors to enable savegame that can be loaded later on without Squadron Unleashed.*/
function UnInit()
{
	local int i;
	local XGShip_Interceptor kJet;
	local SU_UFOSquadron kUFOs;

	WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchHangarBays);
	WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchMissionControl);
	WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchShipTemplates);
	WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchWeaponTemplates);
	for(i=0; i<WorldInfo.MyWatchVariableMgr.WatchVariables.Length; ++i)
	{
		if(WorldInfo.MyWatchVariableMgr.WatchVariables[i].CallbackOwner == self)
		{
			WorldInfo.MyWatchVariableMgr.WatchVariables[i].Enabled = false;
		}
	}
	for(i=m_arrWatchShipManagers.Length-1; i >=0; --i)
	{
		if(!class'SU_Utils'.static.GetGameCore().STORAGE().IsInfinite(EItemType(class'SU_Utils'.static.ShipWeaponToItemType(m_arrWatchShipManagers[i].m_kShip.m_kTShip.arrWeapons[1]))))
		{
			class'SU_Utils'.static.GetGameCore().STORAGE().AddItem(EItemType(class'SU_Utils'.static.ShipWeaponToItemType(m_arrWatchShipManagers[i].m_kShip.m_kTShip.arrWeapons[1])));
			m_arrWatchShipManagers[i].m_kShip.m_kTShip.arrWeapons[1] = 0;
		}
		m_arrWatchShipManagers[i].m_kShip = none;//invalidate the WatchShipMgr
		if(!m_arrWatchShipManagers[i].IsValid())
		{
			m_arrWatchShipManagers.Remove(i,1);
		}
	}
	m_kPilotQuarters.UnInit();//destroy pilots
	m_kPilotQuarters.Destroy();//destroy quarters
	m_kPilotTrainingCenter.Destroy();//destroy the training center
	m_kSaveData.Destroy();//not compulsory but better keep the save file truly clear
	foreach class'SU_Utils'.static.HANGAR().m_arrInts(kJet)
	{
		if(kJet.m_strCallsign ~= m_strNoPilotAssigned)
		{
			if(kJet.IsFirestorm())
			{
				kJet.m_strCallsign = class'SU_Utils'.static.HANGAR().m_strCallsignFireStorm $"-"$ class'SU_Utils'.static.HANGAR().m_iFirestormCounter++;
			}
			else
			{
				kJet.m_strCallsign = class'SU_Utils'.static.HANGAR().m_strCallsignInterceptor $"-"$ class'SU_Utils'.static.HANGAR().m_iInterceptorCounter++;
			}
		}
	}
	foreach DynamicActors(class'SU_UFOSquadron', kUFOs)
	{
		kUFOs.SeekAndDestroyEscortActors();
		kUFOs.Destroy();
	}
}
function ToggleTutorial()
{

	m_bTutorial = !m_bTutorial;
	`Log(GetFuncName() @ m_bTutorial, bVerboseLog, 'SquadronUnleashed');
	if(m_bTutorial && HasHiddenTutorialScreens())
	{
		TutorialResetDialog();
	}
	class'XGSaveHelper'.static.SetProfileStat("SquadronUnleashed.m_bTutorial", m_bTutorial ? 1 : 0);
	XComOnlineEventMgr(GameEngine(Class'Engine'.static.GetEngine()).OnlineEventManager).SaveProfileSettings();
}
function bool HasHiddenTutorialScreens()
{
	local int iSetting;
	local bool bHasHiddenScreens;

	for(iSetting=0; iSetting < m_kHelpMgr.arrHelpMsg.Length; ++iSetting)
	{
		if(class'XGSaveHelper'.static.GetProfileStatValue("SU_HelpManager.arrHelpMsg."$iSetting) > 0)
		{
			bHasHiddenScreens=true;
			break;
		}
	}
	return bHasHiddenScreens;
}
function TutorialDialog()
{
	local TDialogueBoxData kDialogData;

	BuildDataForModManager();
	kDialogData.strTitle = Caps(m_kOptionsContainer.GetUINameForVar("SquadronUnleashed"));
	kDialogData.strText = Localize("UIShellDifficulty", "m_strFirstTimeTutorialTitle", "XComGame");
	//kDialogData.strImagePath = "img:///gfxMissionControl.portrait_pilot";
	kDialogData.strAccept = ParseLocalizedPropertyPath("XComGame.UIShellDifficulty.m_strFirstTimeTutorialYes");
	kDialogData.strCancel = ParseLocalizedPropertyPath("XComGame.UIShellDifficulty.m_strFirstTimeTutorialNo");
	kDialogData.fnCallback = TutorialDialogCallback;
	PRES().UIRaiseDialog(kDialogData);
}
function TutorialDialogCallback(EUIAction eAction)
{
	if(eAction == eUIAction_Cancel && m_bTutorial || eAction == eUIAction_Accept && !m_bTutorial)
	{
		ToggleTutorial();
	}
	else if(eAction == eUIAction_Accept && m_bTutorial && HasHiddenTutorialScreens())
	{
		TutorialResetDialog();
	}
}
function TutorialResetDialog()
{
	local TDialogueBoxData kDialogData;

	kDialogData.strTitle = m_strResetTutorialTitle;
	kDialogData.strText = m_strResetTutorialText;
	kDialogData.strAccept = ParseLocalizedPropertyPath("XComGame.UIShellDifficulty.m_strFirstTimeTutorialYes");
	kDialogData.strCancel = ParseLocalizedPropertyPath("XComGame.UIShellDifficulty.m_strFirstTimeTutorialNo");
	kDialogData.fnCallback = TutorialResetCallback;
	PRES().UIRaiseDialog(kDialogData);
}
function TutorialResetCallback(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		m_kHelpMgr.ResetTutorialSettings();
		if(!IsInState('State_PauseMenu', true))
		{
			m_kHelpMgr.QueueHelpMsg(eSUHelp_TutorialWelcome);
		}
	}
}
//--------------------------------------------------------------------------
// UTILITY FUNCTIONS BLOCK
//--------------------------------------------------------------------------
static function PlayerController PC()
{
	return class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController();
}
static function XComHQPresentationLayer PRES()
{
	return XComHQPresentationLayer(XComHeadquartersController(PC()).m_Pres);
}
//--------------------------------------------------------------------------
// STATES' BLOCK
//--------------------------------------------------------------------------
function RaiseInputGate();

state ModdedState
{
	event PushedState()
	{
		`Log(GetFuncName() @ GetStateName(), bVerboseLog, 'SquadronUnleashed');
	}
	event PausedState()
	{
		`Log(GetFuncName() @ GetStateName(), bVerboseLog, 'SquadronUnleashed');
	}
	event ContinuedState()
	{
		`Log(GetFuncName() @ GetStateName(), bVerboseLog, 'SquadronUnleashed');
	}
	event PoppedState()
	{
		`Log(GetFuncName() @ GetStateName(), bVerboseLog, 'SquadronUnleashed');
	}
}

state State_MC extends ModdedState
{
	//the idea behind this state is to jump in when the ufo contact panel is being loaded
	//let original code load the gfx layer but replace Unreal actors (UI_FxsScreen) that control the gfx

	event PushedState()
	{
		super.PushedState();
		if(class'SU_Utils'.static.GetGameCore().HQ().m_arrFacilities.Find(m_kPilotQuarters) < 0)
		{
			class'SU_Utils'.static.GetGameCore().HQ().m_arrFacilities.AddItem(m_kPilotQuarters);
		}
	}
	event PausedState()
	{
		super.PausedState();
		if(m_iWatchActiveAlert != -1)
		{
			WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchActiveAlert, false);
		}
		class'SU_Utils'.static.GetGameCore().HQ().m_arrFacilities.RemoveItem(m_kPilotQuarters);
	}
	event ContinuedState()
	{
		super.ContinuedState();
		if(class'SU_Utils'.static.GetGameCore().HQ().m_arrFacilities.Find(m_kPilotQuarters) < 0)
		{
			class'SU_Utils'.static.GetGameCore().HQ().m_arrFacilities.AddItem(m_kPilotQuarters);
		}
		if(m_iWatchActiveAlert != -1)
		{
			WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchActiveAlert, true);
		}
		else
		{
			m_iWatchActiveAlert = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES().m_kUIMissionControl, 'm_kActiveAlert', self, OnActiveAlertChange);
			m_strDebugTxt = "\n"$Chr(9)$"Adding m_kActiveAlert to WatchVariable list";
			`Log(m_strDebugTxt, bVerboseLog, 'SquadronUnleashed');
		}
	}
	event PoppedState()
	{
		super.PoppedState();
		if(m_iWatchActiveAlert != -1)
		{
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchActiveAlert);
			m_iWatchActiveAlert = -1;
			m_strDebugTxt = "\n"$Chr(9)$"Removed m_kActiveAlert from WatchVariable list";
			`Log(m_strDebugTxt, bVerboseLog, 'SquadronUnleashed');
		}
		class'SU_Utils'.static.GetGameCore().HQ().m_arrFacilities.RemoveItem(m_kPilotQuarters);
		//bug fix (Labs need attention flag);
		PRES().GetStrategyHUD().m_kMenu.m_arrUIFacilities[0].bNeedsAttention = !class'SU_Utils'.static.GetGameCore().LABS().RequiresAttention();
		PRES().GetStrategyHUD().m_kMenu.UpdateData();
	}
	function OnActiveAlertChange()
	{
		local UIMissionControl kMC;
		local UI_FxsPanel kAlert;

		`Log(GetFuncName() @ "(current:" @PRES().m_kUIMissionControl.m_kActiveAlert $")", bVerboseLog, 'SquadronUnleashed');
		kMC = PRES().m_kUIMissionControl;
		if(kMC.m_kActiveAlert != none && kMC.GetMgr().m_kCurrentAlert.iAlertType == 0 && !kMC.m_kActiveAlert.IsA('SU_UFORadarContactAlert'))
		{
			kAlert = kMC.m_kActiveAlert;
			kAlert.Invoke("UFOAlertFinishedLoading");//this completes OnInit procedure of the original alert
			ReplaceUFOAlert(UIMissionControl_UFOAlert(PRES().m_kUIMissionControl.m_kActiveAlert));			
		}
	}

	function bool ClearInterceptionUI()
	{
		local XGInterceptionUI kUI;
		local bool bFound;

		//ClearInterceptions();
		foreach DynamicActors(class'XGInterceptionUI', kUI)
		{
			bFound = true;
			LogInternal(GetFuncName() @ "destroying" @ kUI, 'SquadronUnleashed');
			kUI.Destroy();
		}
		//bFound determines the need for BeginInterception call
		return bFound;
	}
	function ReplaceUFOAlert(UIMissionControl_UFOAlert kAlertToReplace)
	{
		local bool bSelectShips;
		local SU_UFORadarContactAlert kSQUFOAlert;

		`Log(GetFuncName() @ kAlertToReplace, bVerboseLog, 'SquadronUnleashed');
		if(kAlertToReplace != none && !kAlertToReplace.IsA('SU_UFORadarContactAlert'))
		{
			kSqUFOAlert = Spawn(class'SU_UFORadarContactAlert', PRES().m_kUIMissionControl);
			kSqUFOAlert.m_kUFO = GetUFOFromAlert(kAlertToReplace);
			PRES().m_kUIMissionControl.m_kActiveAlert = kSqUFOAlert;
			kAlertToReplace.screen.panels.RemoveItem(kAlertToReplace);
			kAlertToReplace.screen.panels.InsertItem(0, kSqUFOAlert);
			bSelectShips = ClearInterceptionUI();
			if(bSelectShips)
			{
				kSqUFOAlert.m_nCachedState = 'ShipSelection';
			}
			kSqUFOAlert.Init(PRES().m_kUIMissionControl.controllerRef, PRES().m_kUIMissionControl.manager, PRES().m_kUIMissionControl);
			if(bSelectShips)
			{
				kSqUFOAlert.BeginInterception(kSqUFOAlert.m_kUFO);
			}
			kAlertToReplace.Destroy();
		}
	}
Begin:
	if(m_iWatchActiveAlert != -1)
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchActiveAlert);
	}
	m_iWatchActiveAlert = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES().m_kUIMissionControl, 'm_kActiveAlert', self, OnActiveAlertChange);
	m_strDebugTxt = "\n"$Chr(9)$"Adding m_kActiveAlert to WatchVariable list";

	`Log(m_strDebugTxt, bVerboseLog, 'SquadronUnleashed');
}
state State_HangarMenu extends ModdedState
{
	event PausedState()
	{
		super.PausedState();
		m_kHangarMenu.OnLoseFocus();
		GetMyInputGate().PopFromScreenStack();
	}
	event ContinuedState()
	{
		super.ContinuedState();
		m_kHangarMenu.OnReceiveFocus();
		SetTimer(0.05, false, 'RaiseInputGate');
	}
	event PoppedState()
	{
		super.PoppedState();
		GetMyInputGate().PopFromScreenStack();
		m_kHangarMenu.screen.panels.RemoveItem(m_kHangarMenu);
		m_kHangarMenu.Destroy();
		m_kHangarMenu=none;
		PRES().RemoveMgr(class'SU_XGHangarUI');
		if(!m_bTutorial && m_bTutorialPrompt)
		{
			class'XGSaveHelper'.static.SetProfileStat("eSUHelp_FirstVisitHangar", 1);
		}
	}
	function RaiseInputGate()
	{
		if(PRES().IsInState('State_HangarMenu'))
		{
			GetMyInputGate(PRES().GetStrategyHUD()).BringToTopOfScreenStack();
		}
	}
Begin:
	while(!PRES().GetStrategyHUD().m_kMenu.m_kSubMenu.IsInited())
	{
		Sleep(0.0);
	}
	m_kHangarMenu = SU_UIStrategyHUD_FSM_Hangar(class'UIModUtils'.static.DuplicateFxsPanel(PRES().GetStrategyHUD().m_kMenu.m_kSubMenu, class'SU_UIStrategyHUD_FSM_Hangar'));
	m_kHangarMenu.OnInit();
	RaiseInputGate();
	Sleep(0.50);
	m_bTutorialPrompt = !PRES().m_kNarrative.m_bSilenceNewbieMoments;
	if(m_bTutorialPrompt && !m_bTutorial && class'XGSaveHelper'.static.GetProfileStatValue("eSUHelp_FirstVisitHangar")==0)
	{
		TutorialDialog();
	}
	class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_FirstVisitHangar);
}
state State_HangarShipLoadout extends ModdedState
{
	event PausedState()
	{
		super.PausedState();
		GetMyInputGate().PopFromScreenStack();
	}
	event ContinuedState()
	{
		super.ContinuedState();
		SetTimer(0.05, false, 'RaiseInputGate');
	}
	event PoppedState()
	{
		super.PoppedState();
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(SU_XGHangarUI(m_kShipLoadoutSecondary.GetMgr()).m_iWatchShipWeapons);
		m_kShipLoadoutSecondary.Destroy();
		m_kShipLoadoutSecondary = none;
		m_kShipLoadoutPrimary = none;
	}
	function DuplicateMainPanel()
	{
		if(m_kShipLoadoutSecondary == none)
		{
			//spawn UI_FxsPanel for manipulation of gfx layer
			m_kShipLoadoutSecondary = Spawn(class'SU_UIShipLoadout');
		}
		m_kShipLoadoutPrimary = PRES().m_kShipLoadout;
		m_kShipLoadoutSecondary.PanelInit(m_kShipLoadoutPrimary.controllerRef, m_kShipLoadoutPrimary.manager, m_kShipLoadoutPrimary);
	}
	function RaiseInputGate()
	{
		`Log(GetFuncName() @ GetStateName(), bVerboseLog, 'SquadronUnleashed');
		if(PRES().IsInState('State_HangarShipLoadout'))
		{
			if(PRES().m_kShipLoadout.IsFocused())
				GetMyInputGate(m_kShipLoadoutPrimary).BringToTopOfScreenStack();
			else
			{
				`Log(GetFuncName() @ "failed due to" @ PRES().m_kShipLoadout @ "not yet focused.", bVerboseLog, 'SquadronUnleashed');
				SetTimer(0.05, false, GetFuncName());
			}
		}
	}
Begin:
	DuplicateMainPanel();
	while(!m_kShipLoadoutPrimary.IsVisible() || !m_kShipLoadoutPrimary.IsInited())
	{
		Sleep(0.10);
	}
	RaiseInputGate();
}
state State_HangarShipList extends ModdedState
{
	event PushedState()
	{
		super.PushedState();
		m_iWatchHangarOrders = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(class'SU_Utils'.static.GetGameCore().HQ(), 'm_akInterceptorOrders', self, FixLayout);
		m_iWatchHangarTransfers= WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES().m_kShipList, 'm_bTransferingShip', self, FixLayout);
		SetTimer(0.05, false, 'FixLayout');
	}
	event PausedState()
	{
		super.PausedState();
		ClearAllTimers();
		WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchHangarOrders,false);
		WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchHangarTransfers,false);
	}
	event ContinuedState()
	{
		super.ContinuedState();
		WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchHangarOrders,true);
		WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchHangarTransfers,true);
		SetTimer(0.05, false, 'FixLayout');
		if(!PRES().m_kShipList.IsFocused())
		{
			PRES().m_kShipList.b_IsFocused=true;
		}
	}
	event PoppedState()
	{
		super.PoppedState();
		ClearAllTimers();
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchHangarOrders);
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchHangarTransfers);
		m_iWatchHangarOrders = -1;
		m_iWatchHangarTransfers = -1;
	}
	function FixLayout()
	{
		local GFxObject gfxButton;
		local UIShipList kList;
		local int iContinent, iShip;
		local array<TContinentInfo> arrContinents;
		local string strShipNameTxt, strWeaponTxt, strStatusTxt;
		local array<ASValue> arrParams;

		m_strDebugTxt ="\n"$Chr(9)$GetFuncName();
		if(!PRES().IsInState('State_HangarShipList'))
		{
			m_strDebugTxt $= "...too late, skipping";
		}
		else if(PRES().m_kShipList.manager.GetVariableObject(PRES().m_kShipList.GetMCPath() $ ".hangarsMC.option0.theItems.0") == none)
		{
			SetTimer(0.05, false, GetFuncName());
		}
		else
		{
			kList = PRES().m_kShipList;
			kList.AS_SetTitle(kList.m_strScreenTitle);
			arrContinents = kList.GetMgr().m_arrContinents;
			for(iContinent=0; iContinent < arrContinents.Length; ++iContinent)
			{
				for(iShip=0; iShip < arrContinents[iContinent].arrCraft.Length + arrContinents[iContinent].m_arrInterceptorOrderIndexes.Length; ++iShip)
				{
					m_strDebugTxt $= ("\n"$Chr(9)$"Processing"@ kList.GetMCPath() $ ".hangarsMC.option"$iContinent$".theItems."$iShip);
					gfxButton = kList.manager.GetVariableObject(kList.GetMCPath() $ ".hangarsMC.option"$iContinent$".theItems."$iShip);
				
					strShipNameTxt = gfxButton.GetString("m_shipNameText");
					m_strDebugTxt $= ("\n"$Chr(9)$"Current m_shipNameText="@strShipNameTxt);
					if( !(Left(strShipNameTxt, 15) ~= "<font size='16'") )
					{
						if(class'SU_Utils'.static.GetPilot(arrContinents[iContinent].arrCraft[iShip]) != none && class'SU_Utils'.static.GetPilot(arrContinents[iContinent].arrCraft[iShip]).GetStatus() == ePilotStatus_Ready)
						{
							strShipNameTxt = "<font size='16'>"$strShipNameTxt$"</font>";
						}
						else
						{
							strShipNameTxt = class'UIUtilities'.static.GetHTMLColoredText(strShipNameTxt, 4, 16);
						}
						gfxButton.SetString("m_shipNameText", strShipNameTxt);
						m_strDebugTxt $= ("\n"$Chr(9)$"New m_shipNameText="@strShipNameTxt);
					}
				
					strWeaponTxt = gfxButton.GetString("m_weaponTypeText");
					m_strDebugTxt $= ("\n"$Chr(9)$"Current m_weaponTypeText="@strWeaponTxt);
					if(iShip < arrContinents[iContinent].arrCraft.Length)
					{
						strWeaponTxt = "<font size='16'>          ";
						strWeaponTxt $= class'SU_Utils'.static.GetGameCore().SHIPWEAPON(arrContinents[iContinent].arrCraft[iShip].m_kTShip.arrWeapons[0]).strName;
						if(arrContinents[iContinent].arrCraft[iShip].m_kTShip.arrWeapons.Length > 1)
						{
							strWeaponTxt $= " | ";
							strWeaponTxt $= class'SU_Utils'.static.GetGameCore().SHIPWEAPON(arrContinents[iContinent].arrCraft[iShip].m_kTShip.arrWeapons[1]).strName;
						}
						strWeaponTxt $="</font>";
					}
					gfxButton.SetString("m_weaponTypeText", strWeaponTxt);
					m_strDebugTxt $= ("\n"$Chr(9)$"New m_weaponTypeText="@strWeaponTxt);
	
					strStatusTxt = gfxButton.GetString("m_statusText");
					m_strDebugTxt $= ("\n"$Chr(9)$"Current m_statusText="@strStatusTxt);
					if( !(Left(strStatusTxt, 26) ~= "<font size='16'>          ") )
					{
						strStatusTxt= "<font size='16'>          "$strStatusTxt$"</font>";
						gfxButton.SetString("m_statusText", strStatusTxt);
						m_strDebugTxt $= ("\n"$Chr(9)$"New m_statusText="@strStatusTxt);
					}
					arrParams.Add(1);//dummy
					gfxButton.Invoke("realize", arrParams);
				}
			}
		}
		//`Log(m_strDebugTxt, bVerboseLog, 'SquadronUnleashed');
	}
}
state State_HangarShipSummary extends ModdedState
{
	event PausedState()
	{
		super.PausedState();
		GetMyInputGate().PopFromScreenStack();
	}
	event ContinuedState()
	{
		super.ContinuedState();
		if(!PRES().m_kShipSummary.IsFocused())
		{
			PRES().m_kShipSummary.b_IsFocused = true;
		}
		ModShipSummary();
		SetTimer(0.05, false, 'RaiseInputGate');
	}
	event PoppedState()
	{
		super.PoppedState();
		GetMyInputGate().PopFromScreenStack();
	}
	function RaiseInputGate()
	{
		if(PRES().IsInState('State_HangarShipSummary'))
		{
			m_strDebugTxt = GetFuncName() @ GetStateName();
			if(PRES().m_kShipSummary.IsFocused())
				GetMyInputGate(PRES().m_kShipSummary).BringToTopOfScreenStack();
			else
			{
				m_strDebugTxt $="\n"$Chr(9)$GetFuncName() @ "failed due to" @ PRES().m_kShipSummary @ "not yet focused.";
				SetTimer(0.05, false, GetFuncName());
			}
			`Log(m_strDebugTxt, bVerboseLog, 'SquadronUnleashed');
		}
	}
	function ModShipSummary(optional bool bInitial)
	{
		if(!XComPlayerController(GetALocalPlayerController()).IsMouseActive())
		{
			PRES().m_kShipSummary.m_kNavBar.ClearButtonHelp();
			PRES().m_kShipSummary.m_kNavBar.AddLeftHelp(PRES().m_kShipSummary.m_strWeaponInfoBtnHelp, class'UI_FxsGamepadIcons'.const.ICON_LT_L2, ShowMainWeaponInfo);
			PRES().m_kShipSummary.m_kNavBar.AddRightHelp(PRES().m_kShipSummary.m_strShipInfoBtnHelp, class'UI_FxsGamepadIcons'.const.ICON_X_SQUARE, ShowShipInfo);	
		}
		PRES().m_kShipSummary.AS_SetWeaponName("");
		PRES().m_kShipSummary.AS_SetWeaponLabel(class'SU_Utils'.static.GetShipWeaponName(PRES().m_kShipSummary.m_kShip.m_kTShip.arrWeapons[0]));
		SU_XGHangarUI(PRES().GetMgr(class'SU_XGHangarUI')).AS_AddSecondaryWeaponInfoButton();
		SU_XGHangarUI(PRES().GetMgr(class'SU_XGHangarUI')).AS_ShipSummarySetSecondaryWeaponData();
		SU_XGHangarUI(PRES().GetMgr(class'SU_XGHangarUI')).UpdateShipSummaryHeader();
		SU_XGHangarUI(PRES().GetMgr(class'SU_XGHangarUI')).OverrideRenameButton();
		PRES().GetStrategyHUD().SetBackButtonMouseClickDelegate(SU_XGHangarUI(PRES().GetMgr(class'SU_XGHangarUI')).OnCloseShipSummary);
	}
	function ShowMainWeaponInfo()
	{
		if(!PRES().IsInState('State_ItemCard'))
		{
			PRES().m_kShipSummary.OnMouseWeaponInfo();
		}
	}
	function ShowShipInfo()
	{
		if(!PRES().IsInState('State_ItemCard'))
		{
			PRES().m_kShipSummary.OnMouseShipInfo();
		}
	}
Begin:
	while(!PRES().m_kShipSummary.IsInited() || !PRES().m_kShipSummary.IsFocused())
	{
		Sleep(0.0);
	}
	SU_XGHangarUI(PRES().GetMgr(class'SU_XGHangarUI')).ExtendShipSummaryGfx();
	ModShipSummary();
	GetMyInputGate(PRES().m_kShipSummary).BringToTopOfScreenStack();
}
state State_HangarPilotRoster extends ModdedState
{
	event ContinuedState()
	{
		super.ContinuedState();
		if(PRES().GetStateName() == 'State_HangarMenu')
		{
			PRES().m_kSubMenu.OnLoseFocus();
		}
		m_kPilotRosterUI.OnReceiveFocus();
	}
	event PoppedState()
	{
		super.PoppedState();
		m_kPilotRosterUI.OnLoseFocus();
		m_kPilotRosterUI.Hide();
		if(!PRES().IsInState('State_HangarShipList', true))
		{
			m_kPilotRosterUI.manager.RemoveScreen(m_kPilotRosterUI);
		}
		else
		{
			m_kPilotRosterUI.manager.movieMgr.PopFirstInstanceOfScreen(m_kPilotRosterUI);
			m_kPilotRosterUI.manager.screens.RemoveItem(m_kPilotRosterUI);
			m_kPilotRosterUI.Destroy();
		}
		m_kPilotRosterUI = none;
		if(PRES().GetStateName() == 'State_HangarMenu' && !IsInState('State_HangarPilotTraining',true))
		{
			m_kHangarMenu.OnReceiveFocus();
		}
	}
Begin:
	if(m_kPilotRosterUI == none)
	{
		m_kPilotRosterUI = PRES().Spawn(class'SU_UIPilotRoster', PRES());
	}
	m_kPilotRosterUI.Init(XComPlayerController(PRES().Owner), PRES().GetHUD());
}
state State_ItemCard extends ModdedState
{
	event PushedState()
	{
		super.PushedState();
		if(PRES().m_kShipSummary != none)
		{
			PRES().m_kShipSummary.SetInputState(eInputState_None);//disable OnUnrealCommand
			PRES().m_kShipSummary.b_IsInitialized=false;//cheat, to disable OnMouseEvent
		}
	}
	event PoppedState()
	{
		super.PoppedState();
		if(PRES().m_kShipSummary != none)
		{
			PRES().m_kShipSummary.SetInputState(eInputState_Evaluate);//re-eanble OnUnrealCommand
			PRES().m_kShipSummary.b_IsInitialized=true;//cheat, re-enable OnMouseEvent
		}
	}
	function FixShipWeaponCard()
	{
		local EItemType eWeapon;
		local TShipWeapon kWeapon;
		local TItemCard tCardData;
		local int iWeaponIdx;
		local string tmpStr;

		eWeapon = PRES().m_kItemCard.m_tItemCard.m_item;
		kWeapon = class'SU_Utils'.static.GetGameCore().SHIPWEAPON(class'SU_Utils'.static.ItemTypeToShipWeapon(eWeapon));
		tCardData = class'SU_XGHangarUI'.static.BuildShipWeaponCard(eWeapon); 
		if(PRES().IsInState('State_HangarShipSummary', true))
		{
			iWeaponIdx = PRES().m_kShipSummary.m_kShip.m_kTShip.arrWeapons.Find(kWeapon.eType);
			if(class'SU_Utils'.static.IsShortDistanceWeapon(kWeapon.eType))
			{
				tmpStr = "--";
			}
			else
			{
				tmpStr = string(class'SU_Utils'.static.GetHitChance(PRES().m_kShipSummary.m_kShip,,iWeaponIdx, true, false));
			}
			tmpStr @= "/";
			tmpStr @= string(class'SU_Utils'.static.GetHitChance(PRES().m_kShipSummary.m_kShip,,iWeaponIdx,true, true));
		}
		else
		{
			if(class'SU_Utils'.static.IsShortDistanceWeapon(kWeapon.eType))
			{
				tmpStr = "--";
			}
			else
			{
				tmpStr = string(kWeapon.iToHit);
			}
			tmpStr @= "/";
			tmpStr @= kWeapon.iToHit + class'SU_Utils'.static.GetWeaponAimModClose(kWeapon.eType) + (class'SU_Utils'.static.IsShortDistanceWeapon(kWeapon.eType) ? 0 : class'SquadronUnleashed'.default.AIM_BONUS_CLOSE_DISTANCE_GLOBAL);
		}
 		PRES().m_kItemCard.AS_SetStatData(0, "("$class'UIItemCards'.default.m_strRangeLong @ "/" @ class'UIItemCards'.default.m_strRangeShort$")" @ class'UIUtilities'.static.InjectHTMLImage("img:///gfxMessageMgr.Attack",22,22,-2) $":", tmpStr);
		
 		switch(tCardData.m_shipWpnRange)
		{
			case 0:
				tmpStr = class'UIItemCards'.default.m_strRangeShort;
				break;
			case 1:
				tmpStr = class'UIItemCards'.default.m_strRangeMedium;
				break;
			case 2:
				tmpStr = class'UIItemCards'.default.m_strRangeLong;
				break;
		}
		PRES().m_kItemCard.AS_SetStatData(1, class'UIItemCards'.default.m_strRangeLabel, tmpStr);
		
		switch(tCardData.m_shipWpnFireRate)
		{
			case 0:
				tmpStr = class'UIItemCards'.default.m_strRateSlow;
				break;
			case 1:
				tmpStr = class'UIItemCards'.default.m_strRateMedium;
				break;
			case 2:
				tmpStr = class'UIItemCards'.default.m_strRateRapid;
				break;
		}
		PRES().m_kItemCard.AS_SetStatData(2, class'UIItemCards'.default.m_strFireRateLabel, tmpStr);
		
		switch(tCardData.m_iBaseDamage)
		{
			case 0:
				tmpStr = class'UIItemCards'.default.m_strGenericScaleLow;
				break;
			case 1:
				tmpStr = class'UIItemCards'.default.m_strGenericScaleMedium;
				break;
			case 2:
				tmpStr = class'UIItemCards'.default.m_strGenericScaleHigh;
				break;
		}
		PRES().m_kItemCard.AS_SetStatData(3, class'UIItemCards'.default.m_strDamageLabel, tmpStr);

		switch(tCardData.m_shipWpnArmorPen)
		{
			case 0:
				tmpStr = class'UIItemCards'.default.m_strGenericScaleLow;
				break;
			case 1:
				tmpStr = class'UIItemCards'.default.m_strGenericScaleMedium;
				break;
			case 2:
				tmpStr = class'UIItemCards'.default.m_strGenericScaleHigh;
				break;
		}
		PRES().m_kItemCard.AS_SetStatData(4, class'UIItemCards'.default.m_strArmorPenetrationLabel, tmpStr);		
		if(tCardData.m_item == 0)
		{
			PRES().m_kItemCard.AS_SetCardImage("img:///"$class'SquadronUnleashed'.default.m_strVulcanCanonImgPath, eItemCard_ShipWeapon);
		}
		PRES().m_kItemCard.AS_SetCardTitle(class'SU_Utils'.static.GetShipWeaponName(kWeapon.eType));
	}
Begin:
	while(!PRES().m_kItemCard.IsInited())
	{
		Sleep(0.0);
	}
	if(PRES().m_kItemCard.m_tItemCard.m_type == 3 && (class'SU_Utils'.static.ITEMTREE().IsShipWeapon(PRES().m_kItemCard.m_tItemCard.m_item) || PRES().m_kItemCard.m_tItemCard.m_item == 0))
	{
		FixShipWeaponCard();
	}
}
state State_HangarAirforceCommand extends ModdedState
{
	event PoppedState()
	{
		super.PoppedState();
		GetMyInputGate().PopFromScreenStack();
		PRES().GetHUD().RemoveScreen(m_kAirforceCommand);
		m_kAirforceCommand = none;
	}
Begin:
	m_kAirforceCommand = PRES().Spawn(class'SU_UIAirforceCommand');
	m_kAirforceCommand.Init(XComPlayerController(PRES().Owner), PRES().GetHUD(), 0);
	while(!m_kAirforceCommand.IsInited() || !m_kAirforceCommand.IsVisible())
	{
		Sleep(0.10);
	}
	GetMyInputGate(m_kAirforceCommand).BringToTopOfScreenStack();
}
state State_HangarPilotTraining extends ModdedState
{
	event PausedState()
	{
		super.PausedState();
		m_kPilotTrainingUI.OnLoseFocus();
	}
	event ContinuedState()
	{
		super.ContinuedState();
		m_kPilotTrainingUI.OnReceiveFocus();
	}
	event PoppedState()
	{
		super.PoppedState();
		GetMyInputGate().PopFromScreenStack();
		PRES().GetHUD().RemoveScreen(m_kPilotTrainingUI);
		m_kPilotTrainingUI = none;
		PRES().GetStrategyHUD().m_kMenu.m_kSubMenu.OnReceiveFocus();
	}
Begin:
	PRES().GetStrategyHUD().m_kMenu.m_kSubMenu.OnLoseFocus();
	m_kPilotTrainingUI = PRES().Spawn(class'SU_UIPilotTraining');
	m_kPilotTrainingUI.Init(XComPlayerController(PRES().Owner), PRES().GetHUD());
	while(!m_kPilotTrainingUI.IsInited() || !m_kPilotTrainingUI.IsVisible())
	{
		Sleep(0.10);
	}
	GetMyInputGate(m_kPilotTrainingUI).BringToTopOfScreenStack();
}
state State_WorldReport extends ModdedState
{
Begin:
	m_kPilotTrainingCenter.OnEndOfMonth();
}
defaultproperties
{
	m_iWatchMissionControl=-1
	m_iWatchActiveAlert=-1
	m_strBuildVersion="v. 1.10.2"
}