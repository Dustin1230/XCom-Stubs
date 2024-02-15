class MiniModsStrategy extends XComMutator
	dependson(MMCustomItemCharges)
	config(MiniMods);

var string m_strBuildVersion;
var string m_strCallback;
var int m_iWatchSoldierPromotion;
var int m_iWatchSoldierSummary;
var int m_iWatchStorage;
var int m_iWatchSoldierPerks;
var int m_iWatchSkyrangerSoldiers;
var int m_iWatchSkyranger;
var int m_iWatchCurrentView;
var int m_iWatchSquadSelectView;
var config bool bDebugLog;
var config bool bClearPerksButton;
var config bool bStripGearButton;
var config int CLEARPERKS_MISSIONS_INTERVAL;
var config int CLEARPERKS_TIMEOUT_DAYS;
var config int CLEARPERKS_MELD_COST;
var config EOTSTech CLEARPERKS_OTS_REQ;
var config bool bMeldHealButton;
var config bool bShowMeldHealInfo;
var config int MELDHEAL_DAYS_PER_CHARGE;
var config float MELDHEAL_FRACTION_PER_CHARGE;
var config int MELDHEAL_MELD_PER_CHARGE;
var config int MELDHEAL_MINIMUM_WOUND_DAYS;
var config bool MELDHEAL_FATIGUE_PURGE;
var config bool MELDHEAL_NOT_FOR_SHIVS;
var config ETechType MELDHEAL_TECH_REQUIRED;
var config bool MELDHEAL_CONFIRM_POPUP;
var config bool bManufactureExaltLoot;
var config bool bMapImageOnSquadSelect;
var config bool m_bMapImageRequiresSat;
var config bool m_bMapImageReqSatOverCountry;
var config bool m_bMapImageOnlyOnce;
var config bool bAbductionMapManager;
var config bool m_bContinentalFellowArchives;
var config bool m_bSquadSelectProgressIndicator;
var config bool m_bSquadSelectProgressShowBar;
var config bool m_bSquadSelectProgressShowTxt;
var config bool m_bShowAlienResources;
var config bool m_bShowPerksOnSoldierLists;
var config bool m_bDisableSortingSoldierLists;
var localized string m_strClearPerksButton;
var localized string m_strClearPerksTitle;
var localized string m_strClearPerksWarning;
var localized string m_strClearPerksConfirm;
var localized string m_strClearPerksCancel;
var localized string m_strClearPerksNeedMeld;
var localized string m_strMeldHealButton;
var localized string m_strMeldHealDesc;
var localized string m_strMeldHealFatiguePurge;
var localized string m_strMissingInInventory;
var localized string m_strPerkGivesItemCharges;
var localized string m_strAlienResourcesLabel;
var localized string m_strAlienResearchLabel;
var localized string m_strAlienResourceLvlLabel;
var localized string m_strXComThreatLabel;
var XGStrategySoldier m_kUISoldier;
var name m_nUISoldierCurrState;
var int m_iCurrentRespecSoldierID;
var TCharacter m_kTSavedChar;
var TSoldier m_kTSavedSoldier;
var int m_iLvlPicked;
var int m_iCurrentMissionID;
var UIHelpBar_MiniMods m_kButtons;
var MMSoldierListHelper m_kSoldierListHelper;
var int m_iSoldierListSortingCategory;
var bool m_bSoldierListReversedOrder;//FIXME

delegate OnButtonLoaded();
//--------------------------------------------------------------------------
// UTILITY FUNCTIONS BLOCK
//--------------------------------------------------------------------------

function XComHeadquartersController PC()
{
	return XComHeadquartersController(GetGame().GetALocalPlayerController());
}

function XComHQPresentationLayer PRES()
{
	return XComHQPresentationLayer(PC().m_Pres);
}

function XComHeadquartersGame GetGame()
{
	return XComHeadquartersGame(WorldInfo.Game);
}
function XGStrategy GetCore()
{
	if(GetGame() != none)
	{
		return GetGame().GetGameCore();
	}
	else return none;
}

static function string GetParameterString(int iParameterID, string strParams, optional string strSeparator=",")
{
	return class'MiniModsTactical'.static.GetParameterString(iParameterID, strParams, strSeparator);
}

function actor GetActor(class<actor> ActorClass, string strName)
{
	return class'MiniModsTactical'.static.GetActor(ActorClass, strName);
}
static function bool IsLongWarBuild()
{
	return class'XComPerkManager'.default.SoldierPerkTrees.Length > 15;
}
function bool SoldierIsFatigued(XGStrategySoldier kSoldier)
{
	return IsLongWarBuild() && (kSoldier.GetStatus() == 8 || (kSoldier.GetStatus() == eStatus_OnMission && kSoldier.m_bAllIn));
}
static function MiniModsStrategy GetSelf()
{
	local Mutator kM;

	kM = class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator;
	while(!kM.IsA('MiniModsStrategy') && kM.NextMutator != none)
	{
		kM = kM.NextMutator;
	}
	return MiniModsStrategy(kM);
}
//--------------------------------------------------------------------------
// END OF UTILS
//--------------------------------------------------------------------------

function string GetDebugName()
{
	return GetItemName(string(Class)) @ m_strBuildVersion;
}
event PostBeginPlay()
{
	SetTimer(2.0, true, 'StrategyLoadedCheck');
	`Log(GetFuncName() @ GetDebugName());
}
function RegisterWatchVars()
{
	local string strLog;

	if(bClearPerksButton)
	{
		strLog = "\n    Adding m_kSoldierPromote to WatchVariable list";
		m_iWatchSoldierPromotion = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kSoldierPromote', self, OnSoldierPromotion);
	}
	if(bMeldHealButton || bStripGearButton)
	{
		strLog $= "\n   Adding m_kSoldierSummary to WatchVariable list";
		m_iWatchSoldierSummary = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kSoldierSummary', self, OnSoldierSummary);
	}
	if(bManufactureExaltLoot && (GetCore().EXALT().m_eSimulationState > 0 || GetCore().IsOptionEnabled(eGO_NoExalt)) )
	{
		strLog $= "\n   Adding m_eSimulationState to WatchVariable list";
		WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(GetCore().EXALT(), 'm_eSimulationState', self, EnableBuildExaltLoot);
	}
	strLog $= "\n   Adding m_kSquadSelect to WatchVariable list";
	strLog $= "\n   Adding m_kDebriefUI to WatchVariable list";
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kScienceLabs', self, OnScienceLabs);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kSquadSelect', self, OnSquadSelect);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kDebriefUI', self, OnDebrief);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kSituationRoom', self, OnSituationRoom);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kSoldierList', self, OnSoldierList);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kMemorial', self, OnUIMemorial);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(GetCore().BARRACKS(), 'm_kAwardCeremonySoldier', self, OnAwardCeremony);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(GetCore().GEOSCAPE(), 'm_fGameTimer', self, GameTickUpdate);
	`Log(strLog, bDebugLog, name);
}

function StrategyLoadedCheck()
{
	if(PRES() != none && PRES().m_bPresLayerReady)
	{
		ClearTimer(GetFuncName());
		//anything to do when HQ game has been loaded:
		RegisterWatchVars();
		if(bManufactureExaltLoot)
		{
			EnableBuildExaltLoot();
		}
		else
		{
			DisableBuildExaltLoot();
		}
		if(class'MiniModsTactical'.default.m_bShadowStep || class'MiniModsTactical'.default.m_bPerksGiveItemCharges)
		{
			UpdatePerkDescriptions();
		}
		if(class'MiniModsTactical'.default.m_bFuelConsumption && class'MiniModsTactical'.default.ADJUST_FUEL_MULTIPLIER > 1.0)
		{
			class'MiniModsTactical'.static.AdjustCoreArmorFuel();
		}
		if(bAbductionMapManager)
		{
			GetGame().AddMutator("MiniModsCollection.MapOrganizer", true);
		}
	}
}

function EnableBuildExaltLoot()
{
    local TItemBalance kBalance;
    local array<TItemBalance> arrItemBalance;
	local int iTime, iEng;
	local string strVarName, strSetting;
	local bool bUseModsProfile;

	if(!bManufactureExaltLoot || GetCore().GetHQ().m_kEngineering == none)
	{
		return;
	}
	arrItemBalance = class'XGTacticalGameCore'.default.ItemBalance_Normal;
	foreach arrItemBalance(kBalance)
	{
		if(kBalance.eItem == 209 || kBalance.eItem == 223 || kBalance.eItem == 224)
		{
			iTime = -1;
			iEng = -1;
			if(GetCore().EXALT().m_eSimulationState == eExaltSimulationState_Finished || GetCore().IsOptionEnabled(eGO_NoExalt))
			{
				switch(int(kBalance.eItem))
				{
				case 209:
					strVarName = "Gunsight";
					break;
				case 223:
					strVarName = "Enhancer";
					break;
				case 224:
					strVarName = "Neuroregulator";
				}
				bUseModsProfile = class'XComModsProfile'.static.HasSetting("Build"$strVarName, "ManufactureExaltLoot", strSetting);
				if(bUseModsProfile && bool(strSetting) == true)
				{
					iTime = class'XComModsProfile'.static.ReadsettingInt(strVarName$".iTime", "ManufactureExaltLoot");
					iEng = class'XComModsProfile'.static.ReadSettingInt(strVarName$".iEng", "ManufactureExaltLoot");
				}
				else if(!bUseModsProfile)
				{
					iTime = (kBalance.iTime > 0 ? kBalance.iTime : 10);
					iEng = (kBalance.iEng > 0 ? kBalance.iEng : 70);
				}
			}
			GetCore().ITEMTREE().m_arrItems[kBalance.eItem].iMaxEngineers = iEng;
			GetCore().ITEMTREE().m_arrItems[kBalance.eItem].iHours = GetCore().ITEMTREE().GetItemBuildTime(kBalance.eItem, EItemCategory(GetCore().ITEMTREE().m_arrItems[kBalance.eItem].iCategory), iTime * int(Abs(iEng)));
		}
	}
}
function DisableBuildExaltLoot()
{
	if(!bManufactureExaltLoot && GetCore() != none && GetCore().GetHQ().m_kEngineering != none)
	{
		GetCore().ITEMTREE().m_arrItems[209].iMaxEngineers = -1;
		GetCore().ITEMTREE().m_arrItems[209].iHours = -1;
		GetCore().ITEMTREE().m_arrItems[223].iMaxEngineers = -1;
		GetCore().ITEMTREE().m_arrItems[223].iHours = -1;
		GetCore().ITEMTREE().m_arrItems[224].iMaxEngineers = -1;
		GetCore().ITEMTREE().m_arrItems[224].iHours = -1;
	}
}
function UpdatePerkDescriptions()
{
	local XComPerkManager kPerkMgr;
	local TPerk kTPerk;
	local int  iPerk;
	local bool bScout, bShadow, bShadowBuster, bPerkGivesItems;
	local string strDescription;

	foreach DynamicActors(class'XComPerkManager', kPerkMgr)
	{
		foreach kPerkMgr.m_arrPerks(kTPerk, iPerk)
		{
			strDescription = kPerkMgr.m_arrPerks[iPerk].strDescription[0];
			if(strDescription != "")
			{
				CleanPerkDescription(strDescription);
				kPerkMgr.m_arrPerks[iPerk].strDescription[0] = strDescription;
			}
			bShadow = class'MiniModsTactical'.default.m_bShadowStep && class'MiniModsTactical'.default.m_arrShadowStepPerks.Find(iPerk) != -1;
			bShadowBuster = class'MiniModsTactical'.default.m_bShadowStep && class'MiniModsTactical'.default.m_arrShadowBusterPerks.Find(iPerk) != -1;
			bScout = class'MiniModsTactical'.default.m_bScoutSense && IsScoutSensePerk(iPerk);
			bPerkGivesItems = class'MiniModsTactical'.default.m_bPerksGiveItemCharges && PerkGivesItems(iPerk);

			if(bShadow || bShadowBuster || bScout || bPerkGivesItems)
			{
				kPerkMgr.SetPerkStrings(iPerk);
			}
			strDescription = kPerkMgr.m_arrPerks[iPerk].strDescription[0];

			//update shadow step prefix
			if(bShadow)
			{
				GetShadowStepPrefix(strDescription);
			}
			if(bShadowBuster)
			{
				GetShadowBusterPrefix(strDescription);
			}
			if(bScout)
			{
				GetScoutSenseSuffix(strDescription);
			}
			if(bPerkGivesItems)
			{
				GetItemsFromPerksSuffix(strDescription, iPerk);
			}
			kPerkMgr.m_arrPerks[iPerk].strDescription[0] = strDescription;
		}
	}
}
function bool PerkGivesItems(int iPerk)
{
	return class'MMCustomItemCharges'.default.PerkGivesItems.Find('iPerk', iPerk) != -1;
}
function CleanPerkDescription(out string strOutDesc)
{
	local int iFound, iStart, iEnd;
	local string strTest;

	//clean shadow perk text
	iFound = class'MiniModsOptionsContainer'.default.m_arrVarName.Find("ShadowStep.m_arrShadowStepPerks");
	strTest = class'MiniModsOptionsContainer'.default.m_arrVarDescription[iFound];
	if(Right(strTest,1) == ".")
	{
		strTest = Left(strTest, Len(strTest) -1);
	}
	iFound = InStr(strOutDesc, strTest,,true);
	if(iFound != -1)
	{
		iStart = iFound;
		iEnd = InStr(strOutDesc, ".",,true,iFound) + 2;
		strTest = Mid(strOutDesc, iStart, iEnd - iStart);
		strOutDesc = Repl(strOutDesc, strTest, "");
	}

	//clean shadow buster perk text
	iFound = class'MiniModsOptionsContainer'.default.m_arrVarName.Find("ShadowStep.m_arrShadowBusterPerks");
	strTest = class'MiniModsOptionsContainer'.default.m_arrVarDescription[iFound];
	strTest $= " ";
	strOutDesc = Repl(strOutDesc, strTest, "");

	//clean scout sense text
	strTest = class'MiniModsTactical'.default.m_strScoutSensePerkDesc;
	strOutDesc = Repl(strOutDesc, strTest, "");
	strTest = Left(strTest, InStr(strTest, ".", true) + 1);
	strOutDesc = Repl(strOutDesc, strTest, "");

	//clean perk to items text
	iFound = InStr(strOutDesc, m_strPerkGivesItemCharges,,true);
	if(iFound != -1)
	{
		iStart = iFound;
		iEnd = InStr(strOutDesc, ".",,true,iFound) + 1;
		strTest = Mid(strOutDesc, iStart, iEnd - iStart);
		strOutDesc = Repl(strOutDesc, strTest, "");
	}
}
function GetItemsFromPerksSuffix(out string strDesc, int iPerk)
{
	local TPerkToItem tItemFromPerk;
	local bool bPrefixAdded;

	foreach class'MMCustomItemCharges'.default.PerkGivesItems(tItemFromPerk)
	{
		if(tItemFromPerk.iPerk == iPerk && tItemFromPerk.iCharges > 0)
		{
			if(!bPrefixAdded)
			{
				strDesc = strDesc @ m_strPerkGivesItemCharges;
				bPrefixAdded = true;
			}
			strDesc @= string(tItemFromPerk.iCharges);
			strDesc = strDesc @ tItemFromPerk.iCharges > 1 ? GetCore().ITEMTREE().GetItem(tItemFromPerk.iItem).strNamePlural : GetCore().ITEMTREE().GetItem(tItemFromPerk.iItem).strName;
			strDesc $= ",";
		}
	}
	if(bPrefixAdded)
	{
		strDesc = Left(strDesc, Len(strDesc) - 1) $ ".";
	}
}
function GetShadowStepPrefix(out string strDesc)
{
	local int iFound;
	local string strPrefix;

	iFound = class'MiniModsOptionsContainer'.default.m_arrVarName.Find("ShadowStep.m_arrShadowStepPerks");
	strPrefix = class'MiniModsOptionsContainer'.default.m_arrVarDescription[iFound];
	if(Right(strPrefix,1) == ".")
	{
		strPrefix = Left(strPrefix, Len(strPrefix) -1);
	}
	if(class'MiniModsTactical'.default.m_bShadowStepOnlyOnMove)
	{
		strPrefix $= class'MiniModsTactical'.default.m_strShadowStepMoveSuffix;
	}
	else if(class'MiniModsTactical'.default.m_bShadowStepRequiresDash)
	{
		strPrefix $= class'MiniModsTactical'.default.m_strShadowStepDashSuffix;
	}
	strPrefix $= ".";
	strDesc = strPrefix @ strDesc;
}
function GetShadowBusterPrefix(out string strDesc)
{
	local int iFound;
	local string strPrefix;

	iFound = class'MiniModsOptionsContainer'.default.m_arrVarName.Find("ShadowStep.m_arrShadowBusterPerks");
	strPrefix = class'MiniModsOptionsContainer'.default.m_arrVarDescription[iFound];
	strDesc = strPrefix @ strDesc;
}
function GetScoutSenseSuffix(out string strDesc)
{
	local string strSuffix;

	strSuffix = class'MiniModsTactical'.default.m_strScoutSensePerkDesc;
	if(!class'MiniModsTactical'.default.m_bScoutSenseScalesWithRank)
	{
		strSuffix = Left(strSuffix, InStr(strSuffix, ".") + 1);
	}
	strDesc = strDesc @ strSuffix;
}
function bool IsScoutSensePerk(int iPerk)
{
	local int iScoutSense;

	iScoutSense = class'MiniModsTactical'.default.m_iScoutSensePerk;
	if(iScoutSense <= 0)
	{
		iScoutSense = GetCore().perkMgr().GetPerkInTree(eSC_Sniper, 1, 2);
	}
	if(iScoutSense == 0)
	{
		iScoutSense = GetCore().perkMgr().GetPerkInTree(eSC_Sniper, 0, 0);
	}
	return iPerk == iScoutSense;
}
function OnSoldierPromotion()
{
	if(PRES().m_kSoldierPromote != none && !PRES().IsInStack('State_Debrief'))
	{
		PushState('ModdingSoldierPromotion');
	}
	else if(PRES().m_kSoldierPromote == none && GetStateName() == 'ModdingSoldierPromotion')
	{
		PopState();
		SetTimer(1.0, false, 'CheckCleanUp');
	}
}
function CheckCleanUp()
{
	if(!IsInState('ModdingSoldierSummary',true) && PRES().GetStrategyHUD().m_kHelpBar != none)
	{
		`Log("Clearing delegate overrides", bDebugLog, name);
		AS_SetItemsLoadedDelegate(none);
	}
}
function OnSoldierSummary()
{
	if(PRES().m_kSoldierSummary != none && !PRES().IsInStack('State_Debrief'))
	{
		PushState('ModdingSoldierSummary');
	}
	else if(PRES().m_kSoldierSummary == none && GetStateName() == 'ModdingSoldierSummary')
	{
		PopState();
		if(m_kButtons != none)
		{
			m_kButtons.Destroy();
		}
		if(PRES().GetAnchoredMessenger().IsMessageShown("MeldHeal"))
		{
			PRES().GetAnchoredMessenger().RemoveMessage("MeldHeal");
		}
		//GotoState('none');
		CheckCleanUp();
	}
}
//declarations - to enable calls from other classes or watchVar callbacks:
function OnMeldHealing(EUIAction eAction);
function ClearPerksDialogue();
function OnStripGear();
function OnMeldInject();
function UpdateItemsFromPerks();

function DeferredRealizePositions()
{
	local GFxObject gfxAbilities;
	local float fH, fBracketY;

	GetMiniInventory().RealizePositions();
	fH = GetMiniInventory().GetTotalHeight();
	gfxAbilities = PRES().m_kSoldierLoadout.manager.GetVariableObject(string(PRES().m_kSoldierLoadout.m_kAbilityList.GetMCPath()));

	fH = FMax(fH + 35.0, gfxAbilities.GetObject("bg").GetFloat("_height"));
	fBracketY = fH - gfxAbilities.GetObject("bg").GetFloat("_height") + gfxAbilities.GetObject("bottomBracket").GetFloat("_y");

	gfxAbilities.GetObject("bg").SetFloat("_height", fH);
	gfxAbilities.GetObject("bottomBracket").SetFloat("_y", fBracketY);
}
function OnScienceLabs()
{
	if(PRES().m_kScienceLabs != none)
	{
		SetTimer(1.0, true, 'UpdateArchives');
	}
	else
	{
		ClearTimer('UpdateArchives');
	}
}
function UpdateArchives()
{
	local UIScienceLabs kLabsUI;
	local UIScienceLabs.UIOption tDummyOption;
	local int idx, iContFellow;

	if(!m_bContinentalFellowArchives)
	{
		ClearTimer(GetFuncName());
	}
	else
	{
		kLabsUI = PRES().m_kScienceLabs;
		if(kLabsUI.IsInited())
		{
			if(kLabsUI.m_iView == 2 && kLabsUI.m_arrUIOptions.Length == kLabsUI.GetMgr().m_kArchives.mnuArchives.arrOptions.Length)
			{
				tDummyOption.iIndex = kLabsUI.GetMgr().m_kArchives.mnuArchives.arrOptions.Length;
				tDummyOption.strLabel = "Achievements Help";
				kLabsUI.m_arrUIOptions.AddItem(tDummyOption);
				kLabsUI.AS_AddOption(tDummyOption.iIndex, tDummyOption.strLabel, false);
			}
			else if(kLabsUI.m_iView == 3 && kLabsUI.GetMgr().m_kReport.txtCodename.StrValue == (class'XGResearchUI'.default.m_strLabelCodeName $ " "))
			{
				kLabsUI.AS_SetReportTitles("Achievements Help", "Continental Fellow");
				iContFellow = GetCore().STAT_GetProfileStat(eProfile_FLContinentsWonFrom);
				tDummyOption.strHelp = "Games completed after start from:";
				for(idx=0; idx<5; ++idx)
				{
					tDummyOption.strHelp $= "\n";
					tDummyOption.strHelp $= GetCore().Continent(idx).m_strName;
					tDummyOption.strHelp $= ":";
					if((iContFellow & (1 << idx)) > 0)
					{
						tDummyOption.strHelp @= "OK";
					}
					else
					{
						tDummyOption.strHelp @= "NOT COMPLETE";
					}
				}
				kLabsUI.AS_SetReportItem("Completed games",tDummyOption.strHelp,class'UIUtilities'.static.GetTechImagePath(7));
			}
		}
	}
}
function OnSquadSelect()
{
	if(PRES().m_kSquadSelect!= none && !IsInState('ModdingSquadSelect'))
	{
		PushState('ModdingSquadSelect');
	}
	else if(GetStateName() == 'ModdingSquadSelect')
	{
		PopState();
	}
}
function OnDebrief()
{
	if(PRES().m_kDebriefUI != none)
	{
		ApplyCashCostFromJournal();
	}
}
function ApplyCashCostFromJournal()
{
	local int i;
	local array<string> aJournal;
	local string strData;

	aJournal = GetCore().GetRecapSaveData().m_aJournalEvents;
	for(i=aJournal.Length-1; i >= 0; --i)
	{
		if(InStr(aJournal[i], "CashBalance:") != -1)
		{
			GetCore().GetRecapSaveData().m_aJournalEvents.Remove(i,1);
		}
		if(InStr(aJournal[i], "CashMod:") != -1)
		{
			strData = Split(aJournal[i], "CashMod:", true);
			GetCore().AddResource(eResource_Money, int(strData));
			GetCore().GetRecapSaveData().m_aJournalEvents.Remove(i,1);
		}
	}
}

function RecordCashBalance()
{
	class'XGSaveHelper'.static.SaveValueString(class'XGSaveHelper'.static.GetSaveData("MiniModsCollection"),"HQ", "CashBalance",  string(GetCore().GetResource(eResource_Money)));
}
static function TItemBalance GetItemBalanceNormalFor(int iItem)
{
    local TItemBalance kBalance;

	foreach class'XGTacticalGameCore'.default.ItemBalance_Normal(kBalance)
	{
		if(kBalance.eItem == iItem)
			break;
	}
	return kBalance;
}
static function bool IsGeneMod(int iPerk)
{
	switch(iPerk)
	{
	case class'XComPerkManager'.default.GeneModPerkTree.Brain1:
	case class'XComPerkManager'.default.GeneModPerkTree.Brain2:
	case class'XComPerkManager'.default.GeneModPerkTree.Chest1:
	case class'XComPerkManager'.default.GeneModPerkTree.Chest2:
	case class'XComPerkManager'.default.GeneModPerkTree.Eyes1:
	case class'XComPerkManager'.default.GeneModPerkTree.Eyes2:
	case class'XComPerkManager'.default.GeneModPerkTree.Legs1:
	case class'XComPerkManager'.default.GeneModPerkTree.Legs2:
	case class'XComPerkManager'.default.GeneModPerkTree.Skin1:
	case class'XComPerkManager'.default.GeneModPerkTree.Skin2:
		return true;
	default:
		return false;
	}
}
static function bool IsPsiPerk(int iPerk)
{
	local int I;

	if(!IsLongWarBuild())
	{
		for(I = 1; I < 4; ++I)
		{
			if(iPerk == XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kPerkTree.GetPerkInTreePsi(I, 0)
				|| iPerk == XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kPerkTree.GetPerkInTreePsi(I, 1))
			{
				return true;
			}
		}
		return false;
	}
	for(I=0; I < class'XGTacticalGameCore'.default.ItemBalance_Easy.Length; ++I)
	{
		if(iPerk == class'XGTacticalGameCore'.default.ItemBalance_Easy[I].eItem && !IsGeneMod(iPerk))
		{
			return true;
		}
	}
	return false;
}
function ClearButtons()
{
	PRES().GetStrategyHUD().m_kHelpBar.ClearButtonHelp();
}
function OnUIMemorial()
{
	if(PRES().m_kMemorial != none && !IsInState('ModdingMemorial', true))
	{
		PushState('ModdingMemorial');
	}
	else if(PRES().m_kMemorial == none && GetStateName() == 'ModdingMemorial')
	{
		PopState();
	}
}
function OnAwardCeremony()
{
	if(GetCore().BARRACKS().m_kAwardCeremonySoldier != none && !IsInState('ModdingAwardCeremony'))
	{
		PushState('ModdingAwardCeremony');
	}
	else if(GetCore().BARRACKS().m_kAwardCeremonySoldier == none && GetStateName() == 'ModdingAwardCeremony')
	{
		PopState();
		if(PRES().m_kSoldierSummary != none)
		{
			PRES().m_kSoldierSummary.GetMgr().UpdateView();
			PRES().m_kSoldierSummary.m_kAbilityList.UpdateData();
		}
	}
}
function MyCheckAllItemsLoaded()
{
//original code in ActionScript:
      //if(this.waitingForLeftButtonHelp == false && this.waitingForRightButtonHelp == false && this.waitingForCenterButtonHelp == false)
      //{
      //   this._visible = true;
      //   this.UpdateButtonHelpScaling(this.leftContainer);
      //   this.UpdateButtonHelpScaling(this.rightContainer);
      //   this.UpdateButtonHelpScaling(this.centerContainer);
      //}
	local GFxObject gfxBar, kContainer, kButton;
	local UINavigationHelp kHelpBar;
	local float fX, fY;

	kHelpBar = PRES().GetStrategyHUD().m_kHelpBar;
	gfxBar = kHelpBar.manager.GetVariableObject(string(kHelpBar.GetMCPath()));
	//my center container adjustment
	if(!gfxBar.GetBool("waitingForCenterButtonHelp"))
	{
		kButton = AS_GetCenterContainerItem(0);
		if(kButton != none)
		{
			fX = kHelpBar.manager.GetVariableNumber(kHelpBar.GetMCPath() $ ".centerContainerStartPos.x");
			fY = kHelpBar.manager.GetVariableNumber(kHelpBar.GetMCPath() $ ".centerContainerStartPos.y");
			fX = fX - kButton.GetFloat("_width") - kHelpBar.manager.GetVariableNumber(kHelpBar.GetMCPath() $ ".centerContainer.padding") * 0.5;
			fY = fY - kButton.GetFloat("_height");
			kContainer = AS_GetContainer("center");
			kContainer.SetPosition(fX, fY);
		}
	}
	//original stuff
	if(!gfxBar.GetBool("waitingForLeftButtonHelp") && !gfxBar.GetBool("waitingForRightButtonHelp") && !gfxBar.GetBool("waitingForCenterButtonHelp"))
	{
		gfxBar.SetBool("_visible", true);
		AS_UpdateButtonHelpScaling(gfxBar.GetObject("leftContainer"));
		AS_UpdateButtonHelpScaling(gfxBar.GetObject("rightContainer"));
		AS_UpdateButtonHelpScaling(gfxBar.GetObject("centerContainer"));
		//more of my stuff
		AS_AdjustRightContainerY();
		kButton = AS_GetLeftContainerItem(1);
		if(kButton !=none)
		{
			AdjustLeftContainerAlignment(true);
			SetTimer(0.20, false, 'AdjustLeftContainerAlignment');
		}
	}
}
function AdjustLeftContainerAlignment(optional bool bHide=false)
{
	local GFxObject kButton;
	local float fX, fY;
	local int i;

	for(i = 1; i < AS_GetLeftContainerSize(); ++i )
	{
		kButton = AS_GetLeftContainerItem(i);
		if(kButton !=none)
		{
			kButton.SetBool("_visible", !bHide);
			if(!bHide)
			{
				AS_GetLeftContainerItem(i-1).GetPosition(fX, fY);
				kButton.SetPosition(fX + AS_GetLeftContainerItem(i-1).GetFloat("_width") + (i == 1 ? 60.0 : 30.0), fY);
			}
		}
	}
}
function FixVerticalScrollingField(UI_FxsPanel kPanel)
{
	local GFxObject gfxTextField, gfxPanel;
	local float fH, fY, fOrigScale;

		gfxPanel = kPanel.manager.GetVariableObject(string(kPanel.GetMCPath()));
	//scale bg border: resize whole MC, then restore "header" and "description"
		fH = gfxPanel.GetObject("promotionBG").GetFloat("_height");
		gfxPanel.GetObject("promotionBG").SetFloat("_height", fH + 72.0);
		fOrigScale = fH / (fH + 72.0) * 100.0;
		gfxPanel.GetObject("promotionBG").GetObject("header").SetFloat("_yscale", fOrigScale);
		gfxPanel.GetObject("promotionBG").GetObject("theDescription").SetFloat("_yscale", fOrigScale);

	//move the perk name to freed space above the horizontal line
		fY = gfxPanel.GetObject("descriptionMC").GetObject("name").GetFloat("_y");
		gfxPanel.GetObject("descriptionMC").GetObject("name").SetFloat("_y", fY - 50.0);
	//move the text field up, increase the mask height and decrease font
		gfxTextField = gfxPanel.GetObject("descriptionMC").GetObject("description");
		fY = gfxTextField.GetFloat("_y");
		gfxTextField.SetFloat("_y", fY - 36.0);
		gfxTextField.GetObject("mask").SetFloat("_height", 143.0);
	//finally tune scrolling params
		gfxTextField.SetFloat("PIXELS_PER_SEC", 50.0);
		gfxTextField.SetFloat("repeatDelay", 6.0);
	//override ResetLocation flash function to jump-in with font size adjustment
		AS_SetResetLocationDelegate_PerkDesc(PerkDescription_ResetLocation, kPanel);
}
function PerkDescription_ResetLocation()
{
	local GFxObject gfxTextField, gfxPanel;
	local ASDisplayInfo tDI;

	gfxPanel = PRES().m_kSoldierPromote.manager.GetVariableObject(string(PRES().m_kSoldierPromote.GetMCPath()));
	gfxTextField = gfxPanel.GetObject("descriptionMC").GetObject("description").GetObject("textfield", class'UIModGfxTextField');
	UIModGfxTextField(gfxTextField).SetFontSize(20.0);
	tDI = gfxTextField.GetDisplayInfo();
	tDI.y = gfxPanel.GetObject("descriptionMC").GetObject("description").GetFloat("initialTextfieldY");
	gfxTextField.SetDisplayInfo(tDI);

	if(!PRES().m_kSoldierPromote.manager.IsMouseActive())
	{
		gfxTextField = gfxPanel.GetObject("descriptionMC").GetObject("description");
		gfxTextField.GetObject("mask").SetFloat("_height", 143.0);
	}
}
function AS_AdjustRightContainerY()
{
	AS_GetContainer("right").SetFloat("_y", AS_GetContainer("left").GetFloat("_y"));
}
function float AS_GetCenterContainerTotalWidth()
{
	return PRES().GetStrategyHUD().m_kHelpBar.manager.ActionScriptFloat(PRES().GetStrategyHUD().m_kHelpBar.GetMCPath() $ ".centerContainer.getTotalWidth");
}
function int AS_GetCenterContainerSize()
{
	return PRES().GetStrategyHUD().m_kHelpBar.manager.ActionScriptInt(PRES().GetStrategyHUD().m_kHelpBar.GetMCPath() $ ".centerContainer.getSize");
}
function int AS_GetLeftContainerSize()
{
	return PRES().GetStrategyHUD().m_kHelpBar.manager.ActionScriptInt(PRES().GetStrategyHUD().m_kHelpBar.GetMCPath() $ ".leftContainer.getSize");
}
function GfxObject AS_GetContainer(string strPosition)
{
	return PRES().GetStrategyHUD().m_kHelpBar.manager.GetVariableObject(PRES().GetStrategyHUD().m_kHelpBar.GetMCPath() $ "." $ Locs(strPosition) $ "Container");
}
function GfxObject AS_GetLeftContainerItem(int iButton)
{
	return PRES().GetStrategyHUD().m_kHelpBar.manager.ActionScriptObject(PRES().GetStrategyHUD().m_kHelpBar.GetMCPath() $ ".leftContainer.getItemAt");
}
function GfxObject AS_GetCenterContainerItem(int iButton)
{
	return PRES().GetStrategyHUD().m_kHelpBar.manager.ActionScriptObject(PRES().GetStrategyHUD().m_kHelpBar.GetMCPath() $ ".centerContainer.getItemAt");
}
function AS_UpdateButtonHelpScaling(GFxObject kContainer)
{
	PRES().GetStrategyHUD().m_kHelpBar.manager.ActionScriptVoid(PRES().GetStrategyHUD().m_kHelpBar.GetMCPath() $ ".UpdateButtonHelpScaling");
}
function AS_SetItemsLoadedDelegate(optional delegate<OnButtonLoaded> fnFunction)
{
	local GFxObject kGfxBar;
	local UINavigationHelp kHelpBar;

	kHelpBar = PRES().GetStrategyHUD().m_kHelpBar;
	kGfxBar = kHelpBar.manager.GetVariableObject(string(kHelpBar.GetMCPath()));
	kHelpBar.manager.ActionScriptSetFunction(kGfxBar, "checkAllItemsLoaded");
}
function AS_SetResetLocationDelegate_PerkDesc(delegate<OnButtonLoaded> fnFunction, optional UI_FxsPanel kPromotionScreen = PRES().m_kSoldierPromote)
{
	local GfxObject gfxDescription, gfxPanel;

	gfxPanel = kPromotionScreen.manager.GetVariableObject(string(kPromotionScreen.GetMCPath()));
	gfxDescription = gfxPanel.GetObject("descriptionMC").GetObject("description");
	kPromotionScreen.manager.ActionScriptSetFunction(gfxDescription, "ResetLocation");
}
function GetOptionsContainer(out MiniModsOptionsContainer kContainer)
{
	foreach DynamicActors(class'MiniModsOptionsContainer', kContainer)
	{
		if(kContainer != none)
		{
			break;
		}
	}
	if(kContainer == none)
	{
		kContainer = Spawn(class'MiniModsOptionsContainer');
		kContainer.Init(self);
	}
}
function AddBasicData(MiniModsOptionsContainer kContainer, out TModUIData tMod, optional bool bAddRecord)
{
	tMod.strDisplayName=kContainer.GetUINameForVar(tMod.ModName);
	tMod.strDescription=kContainer.GetDescForVar(tMod.ModName);
	tMod.arrRequiredClassPaths[0]="MiniModsCollection.MiniModsStrategy";
	tMod.arrCredtis=kContainer.m_arrCreditsMiniMods;
	if(bAddRecord)
	{
		kContainer.AddModDataRecord(tMod);
	}
}

function BuildDataForModMgr()
{
	local MiniModsOptionsContainer kContainer;
	local TModUIData tMod;
	local TModOption tOption;
	local int i;
	local string strSetting;

	class'UIModManager'.static.RegisterUpdateCallback(UpdateOptions);
	foreach DynamicActors(class'MiniModsOptionsContainer', kContainer)
	{
		if(kContainer != none)
		{
			break;
		}
	}
	if(kContainer == none)
	{
		kContainer = Spawn(class'MiniModsOptionsContainer');
		kContainer.Init(self); //
	}
	//container for Abduction Map Organizer
	kContainer = Spawn(class'MiniModsOptionsContainer');
	kContainer.m_strMasterClass = "MiniModsCollection.MapOrganizer";
	kContainer.m_arrModsData.Length=0;//clear stuff possibly initialized from ini config

	tMod.ModName = "AbductionMapOrganizer";
	tMod.arrModOptions.Length=0;
	tMod.arrRequiredClassPaths.Length=0;
	tMod.bEnabledByDefault = default.bAbductionMapManager;
	AddBasicData(kContainer, tMod, false);
	tMod.arrCredtis = kContainer.m_arrCreditsMapOrganizer;
	kContainer.AddModDataRecord(tMod);

	for(i=0; i < class'MapOrganizer'.default.AbductionMapRules.Length; ++i)
	{
		strSetting = class'MapOrganizer'.default.AbductionMapRules[i].Map;
		tOption = kContainer.BuildConfigVarInt(tMod.ModName$".AbductionMapRules."$strSetting, class'MapOrganizer'.default.AbductionMapRules[i].iMaxDifficulty,,3,,class'MapOrganizer'.static.GetDefaultDifficultyForMap(strSetting), strSetting, strSetting $ "\n" $ kContainer.GetDescForVar(tMod.ModName$".AbductionMapRules"));
		tOption.arrListLabels[0] = class'XGLocalizedData'.default.MissionDifficultyNames[0];
		tOption.arrListLabels[1] = class'XGLocalizedData'.default.MissionDifficultyNames[1];
		tOption.arrListLabels[2] = class'XGLocalizedData'.default.MissionDifficultyNames[2];
		tOption.arrListLabels[3] = class'XGLocalizedData'.default.MissionDifficultyNames[3];
		kContainer.AddModOption(tMod.ModName, tOption);
	}
}
function UpdateOptions()
{
	local array<TModSetting> arrUISettings;
	local TModSetting tSetting;
	local string strMapName;
	local MapOrganizer kMapMutator;
	local int i;

	bManufactureExaltLoot=      class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "ManufactureExaltLoot");
	bMapImageOnSquadSelect=     class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "MapImageOnSquadSelect");
	bStripGearButton=           class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "StripGearButton");
	bMeldHealButton=            class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "MeldHealing");
	bClearPerksButton=          class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "ClearPerks");

	class'XComModsProfile'.static.GetModSettings("AbductionMapOrganizer", arrUISettings);
	bAbductionMapManager = class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "AbductionMapOrganizer", arrUISettings);

	kMapMutator = MapOrganizer(class'UIModManager'.static.GetMutator("MiniModsCollection.MapOrganizer"));
	foreach arrUISettings(tSetting)
	{
		if(InStr(tSetting.PropertyName, "AbductionMapRules") != -1)
		{
			strMapName = Split(Split(tSetting.PropertyName, ".", true), ".", true);
			i = kMapMutator.AbductionMapRules.Find('Map', strMapName);
			if(i >= 0)
			{
				kMapMutator.AbductionMapRules[i].iMaxDifficulty = int(tSetting.Value);
			}
		}
	}
	if(GetGame() != none)
	{
		kMapMutator.bUserAdded = bAbductionMapManager;
		if(!bManufactureExaltLoot)
		{
			DisableBuildExaltLoot();
		}
		else
		{
			EnableBuildExaltLoot();
		}
	}
	kMapMutator.SaveConfig();

	SaveConfig();
}
function AttachMiniInventoryList()
{
	local GFxObject gfxAbilities;
	local MMGfxInventoryList gfxMiniInv;
	local UIFxsMovie UIMgr;

	if(PRES().m_kSoldierLoadout != none)
	{
		UIMgr = PRES().m_kSoldierLoadout.manager;
		gfxAbilities = UIMgr.GetVariableObject(string(PRES().m_kSoldierLoadout.m_kAbilityList.GetMCPath()));
		gfxMiniInv = MMGfxInventoryList(class'UIModUtils'.static.BindMovie(gfxAbilities, "_inventory list", "MiniModsInventory", class'MMGfxInventoryList', UIMgr));
		gfxMiniInv.Init();
	}
}

function MMGfxInventoryList GetMiniInventory()
{
	if(PRES().m_kSoldierLoadout != none)
	{
		return  MMGfxInventoryList(PRES().m_kSoldierLoadout.manager.GetVariableObject(PRES().m_kSoldierLoadout.m_kAbilityList.GetMCPath() $ ".MiniModsInventory", class'MMGfxInventoryList'));
	}
	else
	{
		return none;
	}
}
function OnSituationRoom()
{
	if(PRES().IsInState('State_SitRoom') && !IsInState('ModdingSituationRoom'))
	{
		PushState('ModdingSituationRoom');
	}
	else if(!PRES().IsInState('State_SitRoom') && IsInState('ModdingSituationRoom'))
	{
		PopState();
	}
}
function OnSoldierList()
{
	if(PRES().IsInState('State_SoldierList') && !IsInState('ModdingSoldierList'))
	{
		PushState('ModdingSoldierList');
	}
	else if(!PRES().IsInStack('State_SoldierList') && IsInState('ModdingSoldierList'))
	{
		PopState();
	}
}
function GameTickUpdate()
{
	if(GetCore().GEOSCAPE().m_fGameTimer <= 1800.0)
	{
	}
}
//just declaration for from-state timer/callback purposes
function ScaleBackpackItems();

state ModdingSoldierSummary
{
	simulated event ContinuedState()
	{
		GotoState('ModdingSoldierSummary', 'Continued');
	}
	event PoppedState()
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchSoldierPerks);
		if(m_iWatchStorage != -1)
		{
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchStorage);
			m_iWatchStorage = -1;
		}
	}
	function AddStripGearButton()
	{
		local UINavigationHelp kHelpBar;
		if(!bStripGearButton || PRES().IsInStack('State_ChooseSquad') || PRES().m_kSoldierSummary == none || PRES().m_kSoldierSummary.GetMgr().m_bCovertOperativeMode || !PRES().IsInStack('State_Soldier'))
		{
			return;
		}
		kHelpBar = PRES().GetStrategyHUD().m_kHelpBar;
		kHelpBar.AddLeftHelp(class'UISquadSelect'.default.m_strStripGearLabel, "Icon_LT_L2", OnStripGear);
		if(m_kButtons != none)
		{
			m_kButtons.BringToTopOfScreenStack();
		}
	}

	function AddMeldHealButton()
	{
		local UISoldierSummary kUI;
		local bool bDisableButton;
		local UINavigationHelp kHelpBar;

		if(!bMeldHealButton || (!MELDHEAL_FATIGUE_PURGE && SoldierIsFatigued(m_kUISoldier)) )
		{
			return;
		}
		if(MELDHEAL_TECH_REQUIRED > 0 && !GetCore().LABS().IsResearched(MELDHEAL_TECH_REQUIRED))
		{
			return;
		}
		kUI = PRES().m_kSoldierSummary;
		kHelpBar = PRES().GetStrategyHUD().m_kHelpBar;
		if(bShowMeldHealInfo)
		{
			AddInfobox();
		}
		bDisableButton = false;
		if(GetCore().GetResource(eResource_Meld) < MELDHEAL_MELD_PER_CHARGE)
		{
			bDisableButton = true;
		}
		else if (m_kUISoldier.GetStatus() == eStatus_Healing && m_kUISoldier.m_iTurnsOut <= 24 * MELDHEAL_MINIMUM_WOUND_DAYS)
		{
			bDisableButton = true;
		}
		if(kUI.manager.IsMouseActive())
		{
			kHelpBar.AddCenterHelp(m_strMeldHealButton,"", OnMeldInject, bDisableButton);
			kHelpBar.SetButtonType("");
		}
		else
		{
			kHelpBar.AddCenterHelp(m_strMeldHealButton,"Icon_RT_R2", OnMeldInject, bDisableButton);
		}
		if(m_kButtons != none)
		{
			m_kButtons.SetInputState(1);
			m_kButtons.BringToTopOfScreenStack();
		}
		kUI.GetMgr().UpdateView();
	}
	function OnMeldInject()
	{
		local TDialogueBoxData kDialogData;

		if(MELDHEAL_CONFIRM_POPUP)
		{
			kDialogData.eType = 0;
			kDialogData.strTitle = m_strMeldHealButton;
			kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
			kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
			kDialogData.fnCallback = OnMeldHealing;
			PRES().UIRaiseDialog(kDialogData);
		}
		else
		{
			OnMeldHealing(eUIAction_Accept);
		}
	}
	function OnMeldHealing(EUIAction eAction)
	{
		if(eAction != eUIAction_Accept)
		{
			return;
		}
		if(GetCore().GetResource(eResource_Meld) < MELDHEAL_MELD_PER_CHARGE)
		{
			return;
		}
		if(!SoldierIsFatigued(m_kUISoldier) && m_kUISoldier.GetStatus() != eStatus_Healing)
		{
			return;
		}
		if(SoldierIsFatigued(m_kUISoldier) && MELDHEAL_FATIGUE_PURGE)
		{
			m_kUISoldier.m_iTurnsOut = 0;
			m_kUISoldier.m_bAllIn = false;
			if(m_kUISoldier.GetStatus() != eStatus_OnMission)
			{
				m_kUISoldier.SetStatus(eStatus_Active);
			}
			GetCore().STORAGE().RestoreBackedUpInventory(m_kUISoldier);
			PRES().m_kSoldierSummary.SetSoldier(m_kUISoldier);
			GetCore().AddResource(eResource_Meld, -MELDHEAL_MELD_PER_CHARGE);
		}
		else if(m_kUISoldier.GetStatus() == eStatus_Healing && m_kUISoldier.m_iTurnsOut > 24 * MELDHEAL_MINIMUM_WOUND_DAYS)
		{
			m_kUISoldier.m_iTurnsOut = Max(m_kUISoldier.m_iTurnsOut * (1.0 - MELDHEAL_FRACTION_PER_CHARGE) - 24 * MELDHEAL_DAYS_PER_CHARGE, 24 * MELDHEAL_MINIMUM_WOUND_DAYS);
			GetCore().AddResource(eResource_Meld, -MELDHEAL_MELD_PER_CHARGE);
		}
		PRES().m_kSoldierSummary.m_kSoldierHeader.UpdateData();
		ClearButtons();
		PRES().m_kSoldierSummary.UpdateButtonHelp();
		AddStripGearButton();
		if( (m_kUISoldier.GetStatus() == eStatus_Healing || SoldierIsFatigued(m_kUISoldier)) && (!MELDHEAL_NOT_FOR_SHIVS || !m_kUISoldier.IsATank()))
		{
			AddMeldHealButton();
		}
		else
		{
			if(PRES().GetAnchoredMessenger().IsMessageShown("MeldHeal"))
			{
				PRES().GetAnchoredMessenger().RemoveMessage("MeldHeal");
			}
		}
	}
	function AddInfoBox(optional string strDescription="")
	{
		local XGParamTag kTag;

		if(strDescription == "")
		{
			kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
			kTag.IntValue0 = Min((m_kUISoldier.m_iTurnsOut * MELDHEAL_FRACTION_PER_CHARGE) / 24 + MELDHEAL_DAYS_PER_CHARGE, m_kUISoldier.m_iTurnsOut / 24 - MELDHEAL_MINIMUM_WOUND_DAYS);
			kTag.IntValue0 = Max(0, kTag.IntValue0);
			kTag.IntValue1 = MELDHEAL_MINIMUM_WOUND_DAYS;
			kTag.IntValue2 = MELDHEAL_MELD_PER_CHARGE;
			if(m_kUISoldier.GetStatus() == eStatus_Healing)
			{
				strDescription = class'XComLocalizer'.static.ExpandString(m_strMeldHealDesc);
			}
			else if(MELDHEAL_FATIGUE_PURGE && SoldierIsFatigued(m_kUISoldier))
			{
				strDescription = class'XComLocalizer'.static.ExpandString(m_strMeldHealFatiguePurge);
			}
		}
		if(PRES().GetAnchoredMessenger() != none)
		{
			ClearInfoBox();
			PRES().GetAnchoredMessenger().Message(strDescription, (SoldierIsFatigued(m_kUISoldier) ? 0.4 : 0.2), 0.0, TOP_LEFT, 20.0, "MeldHeal");
		}
	}
	function ClearInfoBox()
	{
		if(PRES().GetAnchoredMessenger().IsMessageShown("MeldHeal"))
		{
			PRES().GetAnchoredMessenger().RemoveMessage("MeldHeal");
		}
	}
	function UpdateSoldier(XGStrategySoldier kSoldier, optional bool bForceUpdate)
	{
		local UISoldierSummary kUI;

		kUI = PRES().m_kSoldierSummary;
		if(kUI==none || kSoldier == none)
		{
			return;
		}
		if(m_kUISoldier != kSoldier || bForceUpdate)
		{
			ClearButtons();
			kUI.UpdateButtonHelp();
			m_kUISoldier = kSoldier;
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchSoldierPerks);
			m_iWatchSoldierPerks = WorldInfo.MyWatchVariableMgr.RegisterWatchVariableStructMember(kSoldier, 'm_kChar', 'aUpgrades', self, UpdateItemsFromPerks);
			if( (kSoldier.GetStatus() == eStatus_Healing || SoldierIsFatigued(kSoldier)) && (!MELDHEAL_NOT_FOR_SHIVS || !kSoldier.IsATank()))
			{
				AddMeldHealButton();
			}
			else
			{
				ClearInfoBox();
			}
			UpdateAbilitiesList();
		}
		if(!PRES().GetStrategyHUD().m_kHelpBar.HasDelegate(OnStripGear))
		{
			AddStripGearButton();
		}
	}
	function StripGearArmory()
	{
		local XGStrategySoldier kSoldier;

		foreach GetCore().BARRACKS().m_arrSoldiers(kSoldier)
		{
			if(kSoldier == m_kUISoldier)
			{
				continue;
			}
			if(kSoldier.GetStatus() != eStatus_Dead && kSoldier.GetHQLocation() != 1)
			{
				if(kSoldier.GetStatus() != eStatus_OnMission && kSoldier.GetStatus() != eStatus_CovertOps)
				{
					GetCore().STORAGE().BackupAndReleaseInventory(kSoldier);
				}
			}
		}
		if(PRES().IsInState('State_SoldierLoadout'))
		{
			PRES().m_kSoldierLoadout.GetMgr().UpdateGear();
			PRES().m_kSoldierLoadout.GetMgr().UpdateLocker();
			PRES().m_kSoldierLoadout.UpdateData();
		}
	}
	function OnStripGear()
	{
		local TDialogueBoxData kDialogData;

		kDialogData.eType = 0;
		kDialogData.strTitle = class'UISquadSelect'.default.m_strStripGearLabel;
		kDialogData.strText = class'UISquadSelect'.default.m_strStripGearConfirmDesc;
		kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
		kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
		kDialogData.fnCallback = OnConfirmStripGear;
		PRES().UIRaiseDialog(kDialogData);
		PRES().m_kHUD.DialogBox.Hide();
		SetTimer(0.10, false, 'Show', PRES().m_kHUD.DialogBox);
	}

	simulated function OnConfirmStripGear(EUIAction eAction)
	{
		if(eAction == 0)
		{
			StripGearArmory();
		}
	}
	function UpdateAbilitiesList()
	{
		local bool bHasShadowPerk;
		local UIStrategyComponent_SoldierAbilityList kAbilitiesList;
		local int iPerk;

		for(iPerk = 0; iPerk < class'MiniModsTactical'.default.m_arrShadowStepPerks.Length; ++iPerk)
		{
			if(m_kUISoldier.HasPerk(class'MiniModsTactical'.default.m_arrShadowStepPerks[iPerk]))
			{
				bHasShadowPerk = true;
				break;
			}
		}
		kAbilitiesList=PRES().m_kSoldierSummary.m_kAbilityList;
		if(PRES().GetStateName() == 'State_SoldierLoadout')
		{
			kAbilitiesList = PRES().m_kSoldierLoadout.m_kAbilityList;
		}
		if(class'MiniModsTactical'.default.m_bShadowStep && bHasShadowPerk)
		{
			if(kAbilitiesList != none  && kAbilitiesList.IsVisible())
			{
				kAbilitiesList.AS_AddAbility(class'MiniModsTactical'.default.m_strShadowStepping, "Sprinter", false);
			}
		}
	}
	function UpdateItemsFromPerks()
	{
		local bool bInfinite, bEquipped, bAvailable;
		local TPerkToItem tItemFromPerk;
		local int iNumIcons;
		local string strTitle;

		if(PRES().IsInState('State_SoldierLoadout'))
		{
			AdjustSlotHeights();
		}
		if( !class'MiniModsTactical'.default.m_bPerksGiveItemCharges || !PRES().IsInState('State_SoldierLoadout') )
		{
			return;
		}
		GetMiniInventory().AS_Clear();
		if(!m_kUISoldier.IsAugmented() && !m_kUISoldier.IsATank())
		{
			foreach class'MMCustomItemCharges'.default.PerkGivesItems(tItemFromPerk)
			{
				if(m_kUISoldier.HasPerk(tItemFromPerk.iPerk) && tItemFromPerk.iCharges > 0)
				{
					if(IsLongWarBuild())
						bInfinite = GetItemBalanceNormalFor(tItemFromPerk.iItem).iTime == -1;
					else
						bInfinite = GetGame().GetGameCore().STORAGE().IsInfinite(EItemType(tItemFromPerk.iItem));
					bEquipped = class'XGTacticalGameCoreNativeBase'.static.TInventoryHasItemType(m_kUISoldier.m_kChar.kInventory, tItemFromPerk.iItem);
					bAvailable = (bInfinite  ||  bEquipped);
					iNumIcons = Min(3, tItemFromPerk.iCharges);
					strTitle = CAPS(m_kUISoldier.PERKS().GetPerkName(tItemFromPerk.iPerk));
					if(!bAvailable)
					{
						strTitle = class'UIUtilities'.static.GetHTMLColoredText(m_strMissingInInventory, 3);
					}
					GetMiniInventory().AddInventoryItem(3, strTitle, class'UIUtilities'.static.GetInventoryImagePath(IsLongWarBuild() ? tItemFromPerk.iItem : GetGame().GetGameCore().Item(tItemFromPerk.iItem).iImage), iNumIcons, ,bAvailable);
					//just in case of crazy setting iCharges > 3:
					if(tItemFromPerk.iCharges > iNumIcons)
					{
						GetMiniInventory().AddInventoryItem(3, strTitle, class'UIUtilities'.static.GetInventoryImagePath(IsLongWarBuild() ? tItemFromPerk.iItem : GetGame().GetGameCore().Item(tItemFromPerk.iItem).iImage), tItemFromPerk.iCharges - iNumIcons, ,bAvailable);
					}
				}
			}
		}
		GetMiniInventory().RealizePositions();
		SetTimer(0.10, false, 'DeferredRealizePositions');
	}
	function AdjustSlotHeights()
	{

	}
Begin:
	while(!PRES().IsInState('State_Soldier'))
	{
		Sleep(0.10);
	}
	AS_SetItemsLoadedDelegate(none); //clear previous just in case
	AS_SetItemsLoadedDelegate(MyCheckAllItemsLoaded);
Continued:
	if(m_iWatchSoldierPerks != -1)
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchSoldierPerks);
	}
	while(PRES().m_kSoldierSummary == none)
	{
		Sleep(0.10);
	}
	m_kUISoldier = PRES().m_kSoldierSummary.m_kSoldier;
	m_iWatchSoldierPerks = WorldInfo.MyWatchVariableMgr.RegisterWatchVariableStructMember(m_kUISoldier, 'm_kChar', 'aUpgrades', self, UpdateItemsFromPerks);
	Sleep(0.30);
	if(m_kButtons == none && bClearPerksButton)
	{
		m_kButtons = Spawn(class'UIHelpBar_MiniMods');
		m_kButtons.PanelInit(PC(), PRES().m_kSoldierSummary.manager, PRES().m_kSoldierSummary);
		m_kButtons.m_kMutator = self;
	}
	else
	{
		m_kButtons.screen = PRES().m_kSoldierSummary;
	}
	ClearButtons();
	PRES().m_kSoldierSummary.UpdateButtonHelp();
	AddStripGearButton();
	UpdateAbilitiesList();
	if( (m_kUISoldier.GetStatus() == eStatus_Healing || SoldierIsFatigued(m_kUISoldier)) && (!MELDHEAL_NOT_FOR_SHIVS || !m_kUISoldier.IsATank()))
	{
		AddMeldHealButton();
	}
	m_nUISoldierCurrState = PRES().GetStateName();
	while(PRES().IsInState('State_Soldier', true))
	{
		if(PRES().GetStateName() == 'State_Soldier')
		{
			if(m_nUISoldierCurrState == 'State_SoldierLoadout')
			{
				WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchStorage, false);
				goto('Continued');//coming back from loadout view
			}
			else if(m_nUISoldierCurrState == 'State_Customize')
			{
				goto('Continued');//coming back from soldier's customize view
			}
			else
			{
				UpdateSoldier(PRES().m_kSoldierSummary.m_kSoldier);
			}
		}
		else if(PRES().GetStateName() == 'State_SoldierLoadout')
		{
			if(m_nUISoldierCurrState == 'State_Soldier')
			{
				if(m_iWatchStorage == -1)
				{
					m_iWatchStorage = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kUISoldier.STORAGE(), 'm_arrItems', self, UpdateItemsFromPerks);
				}
				else
				{
					WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchStorage, true);
				}
				if(PRES().GetAnchoredMessenger().IsMessageShown("MeldHeal"))
				{
					PRES().GetAnchoredMessenger().RemoveMessage("MeldHeal");
				}
				m_kButtons.screen = PRES().m_kSoldierLoadout;
				m_nUISoldierCurrState = 'State_SoldierLoadout';
				UpdateAbilitiesList();//entering loadout view
				if(GetMiniInventory() == none)
				{
					AttachMiniInventoryList();
				}
				UpdateItemsFromPerks();
			}
			else
			{
				if(!PRES().GetStrategyHUD().m_kHelpBar.HasDelegate(OnStripGear))
				{
					AddStripGearButton();
				}
				if(m_kUISoldier != PRES().m_kSoldierLoadout.m_kSoldier)
				{
					m_kUISoldier = PRES().m_kSoldierLoadout.m_kSoldier;
					UpdateAbilitiesList();
					UpdateItemsFromPerks();
				}
			}
		}
		else if(PRES().GetStateName() == 'State_Customize')
		{
			if(m_nUISoldierCurrState == 'State_Soldier' && PRES().GetAnchoredMessenger().IsMessageShown("MeldHeal"))
			{
				PRES().GetAnchoredMessenger().RemoveMessage("MeldHeal");
				m_kButtons.screen = PRES().m_kSoldierCustomize;
			}
			m_nUISoldierCurrState = 'State_Customize';
		}
		Sleep(0.30);
	}
}
function AttachSelectionProgressBox();
function UpdateSelectionProgress();

state ModdingSoldierPromotion extends ModdingSoldierSummary
{
	simulated event PoppedState()
	{
		if(IsSoldierInReSpec())
		{
			RestoreSoldierData();
		}
		m_kTSavedChar = default.m_kTSavedChar;
		m_kTSavedSoldier = default.m_kTSavedSoldier;
		m_iCurrentRespecSoldierID = -1;
		if(PRES().GetAnchoredMessenger().IsMessageShown("MeldHeal"))
		{
			PRES().GetAnchoredMessenger().RemoveMessage("MeldHeal");
		}
	}
	function SaveSoldierData()
	{
		m_kTSavedSoldier = m_kUISoldier.m_kSoldier;
		m_kTSavedChar = m_kUISoldier.m_kChar;
	}
	function RestoreSoldierData()
	{
		m_kUISoldier.m_kChar = m_kTSavedChar;
		m_kUISoldier.m_kSoldier = m_kTSavedSoldier;
	}
	function RestoreSoldierStatsAndRank()
	{
		local int i;

		m_kUISoldier.m_kSoldier.iRank = m_kTSavedSoldier.iRank;
		for(i = 0; i < 19; ++i)
		{
			m_kUISoldier.m_kChar.aStats[i] = m_kTSavedChar.aStats[i];
		}
	}
	function AddClearPerkButton()
	{
		local UISoldierPromotion kUI;
		local UINavigationHelp kHelpBar;

		if(!bClearPerksButton)
		{
			return;
		}
		if(CLEARPERKS_OTS_REQ > 0 && !GetCore().BARRACKS().HasOTSUpgrade(CLEARPERKS_OTS_REQ))
		{
			return;
		}
		kUI = PRES().m_kSoldierPromote;
		kHelpBar = PRES().GetStrategyHUD().m_kHelpBar;
		if(kUI.manager.IsMouseActive())
		{
			kHelpBar.AddRightHelp(m_strClearPerksButton,"", ClearPerksDialogue);
			kHelpBar.SetButtonType("");
		}
		else
		{
			kHelpBar.AddRightHelp(m_strClearPerksButton,"Icon_RSCLICK_R3", ClearPerksDialogue);
		}
		if(m_kButtons != none)
		{
			m_kButtons.SetInputState(1);
			m_kButtons.BringToTopOfScreenStack();
		}
		kUI.GetMgr().UpdateView();
	}
	function int GetLowestUnassignedBranch(optional XGStrategySoldier kSoldier=m_kUISoldier)
	{
		local int iBranch;

		do
		{
			++iBranch;
		}
		until(!kSoldier.HasPerk(kSoldier.GetPerkInClassTree(iBranch, 0, false)) && !kSoldier.HasPerk(kSoldier.GetPerkInClassTree(iBranch, 1, false)) && !kSoldier.HasPerk(kSoldier.GetPerkInClassTree(iBranch, 2, false)));
		return iBranch;
	}
	function bool IsReSpecValidForSoldier(XGStrategySoldier kSoldier)
	{
		return (kSoldier.GetStatus() == eStatus_Active && kSoldier.GetRank() >= 2 && kSoldier.GetNumMissions() >= kSoldier.m_kSoldier.kClass.aAbilityUnlocks[0] );
	}
	function RecordSoldierReSpecStart(optional XGStrategySoldier kSoldier=m_kUISoldier)
	{
		if(m_iCurrentRespecSoldierID != kSoldier.m_kSoldier.iID)
		{
			m_iCurrentRespecSoldierID = kSoldier.m_kSoldier.iID;
		}
		m_kTSavedChar = kSoldier.m_kChar;
		m_kTSavedSoldier = kSoldier.m_kSoldier;
	}
	function bool IsSoldierInReSpec(optional XGStrategySoldier kSoldier=m_kUISoldier)
	{
		return kSoldier.m_kSoldier.iID == m_iCurrentRespecSoldierID;
	}
	function RecordSoldierReSpecEnd(optional XGStrategySoldier kSoldier=m_kUISoldier)
	{
		m_iCurrentRespecSoldierID = -1;
		kSoldier.m_kSoldier.kClass.aAbilityUnlocks[0] = kSoldier.GetNumMissions() + CLEARPERKS_MISSIONS_INTERVAL;
		kSoldier.m_kSoldier.kClass.aAbilityUnlocks[1] = kSoldier.GetNumMissions();
		kSoldier.m_iTurnsOut += CLEARPERKS_TIMEOUT_DAYS * 24;
		kSoldier.BARRACKS().UpdateFoundryPerksForSoldier(kSoldier);//bug fix
		if(kSoldier.GetStatus() == eStatus_OnMission)
		{
			kSoldier.BARRACKS().UnloadSoldier(kSoldier);
		}
		if(kSoldier.GetStatus() == eStatus_Active)
		{
			if(IsLongWarBuild())
			{
				kSoldier.SetStatus(ESoldierStatus(8));
				kSoldier.m_bAllIn = true;
			}
			else
			{
				kSoldier.SetStatus(eStatus_Healing);
			}

		}
		GetCore().AddResource(eResource_Meld, -CLEARPERKS_MELD_COST);
		ClearButtons();
		PRES().m_kSoldierPromote.UpdateButtonHelp();
		if( (kSoldier.GetStatus() == eStatus_Healing || SoldierIsFatigued(kSoldier)) && (!MELDHEAL_NOT_FOR_SHIVS || !kSoldier.IsATank()) )
		{
			AddMeldHealButton();
		}
		WorldInfo.Game.Mutate("MiniModsStrategy.RecordSoldierReSpecEnd:"$string(kSoldier), none);
		PRES().m_kSoldierPromote.m_kSoldierHeader.UpdateData();
		PRES().m_kSoldierPromote.GetMgr().SetActiveSoldier(kSoldier);
		GetCore().BARRACKS().ReorderRanks();
	}
	function ClearPerksDialogue()
	{
		local TDialogueBoxData kDialogData;
		local XGParamTag kTag;

		if(!IsReSpecValidForSoldier(m_kUISoldier))
		{
			return;
		}
		if(IsSoldierInReSpec())
		{
			ClearPerksCallback(eUIAction_Accept);
			return;
		}
		kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
		if(CLEARPERKS_MELD_COST > 0 && GetCore().GetResource(eResource_Meld) < CLEARPERKS_MELD_COST)
		{
			kTag.IntValue2 = CLEARPERKS_MELD_COST;
			kDialogData.eType = eDialog_Warning;
			kDialogData.strTitle = m_strClearPerksTitle;
			kDialogData.strText = class'XComLocalizer'.static.ExpandString(m_strClearPerksNeedMeld);
			kDialogData.strAccept = PRES().m_strOK;
		}
		else
		{
			kTag.IntValue0 = CLEARPERKS_TIMEOUT_DAYS;
			kTag.IntValue1 = CLEARPERKS_MISSIONS_INTERVAL;
			kTag.IntValue2 = CLEARPERKS_MELD_COST;
			kTag.StrValue1 = (CLEARPERKS_MELD_COST > 0 ? class'XComLocalizer'.static.ExpandString(m_strClearPerksNeedMeld) : "");
			kDialogData.eType = eDialog_Warning;
			kDialogData.strTitle = m_strClearPerksTitle;
			kDialogData.strText = class'XComLocalizer'.static.ExpandString(m_strClearPerksWarning);
			kDialogData.strAccept = m_strClearPerksConfirm;
			kDialogData.strCancel = m_strClearPerksCancel;
			kDialogData.fnCallback = ClearPerksCallback;
		}
		PRES().m_kSoldierPromote.SetInputState(0);
		PRES().UIRaiseDialog(kDialogData);
	}
	function ClearPerksCallback(EUIAction eAction)
	{
		local UISoldierPromotion kUI;

		kUI = PRES().m_kSoldierPromote;
		kUI.SetInputState(1);
		if(eAction == eUIAction_Accept)
		{
			if(!IsSoldierInReSpec())
			{
				RecordSoldierReSpecStart(kUI.m_kSoldier);
			}
			PRES().GetStrategyHUD().m_kHelpBar.ClearButtonHelp();
			AddClearPerkButton();
			ClearPerks(kUI.m_kSoldier);
			kUI.GetMgr().UpdateView();
			kUI.InitializeTree();
			kUI.UpdateAbilityData();
			kUI.m_kSoldierStats.UpdateData();
			kUI.m_kSoldierHeader.UpdateData();
			if(kUI.m_kMecSoldierStats != none)
			{
				kUI.m_kMecSoldierStats.UpdateData();
			}
			PRES().m_kSoldierSummary.UpdateData();
			PRES().m_kSoldierSummary.UpdatePanels();
		}
		else
		{
			kUI.GetMgr().UpdateView();
		}
	}
	function ClearPerks(XGStrategySoldier kSoldier)
	{
		local int i, iPerk;

		for(iPerk = 0; iPerk < 172; ++iPerk)
		{
			//do not clear OneForAll and CombinedArms for MECs
			if(kSoldier.IsAugmented() && (iPerk == 136 || iPerk == 138) )
			{
				continue;
			}
			//do not clear officer perks, gene mods, psi perks or TacticalRigging
			if(!class'XGTacticalGameCoreNativeBase'.static.IsMedalPerk(EPerkType(iPerk)) && !IsGeneMod(iPerk) && !IsPsiPerk(iPerk) && iPerk != 165)
			{
				if(iPerk != kSoldier.GetPerkInClassTree(1, 0) && iPerk != kSoldier.GetPerkInClassTree(1, 1) && iPerk != kSoldier.GetPerkInClassTree(1, 2))
				{
					kSoldier.m_kChar.aUpgrades[iPerk] = 0;
				}
				else
				{
					for(i = 2; i <= 7; ++i)
					{
						if(iPerk == kSoldier.GetPerkInClassTree(i, 0) || iPerk == kSoldier.GetPerkInClassTree(i, 1) || iPerk == kSoldier.GetPerkInClassTree(i, 2))
						{
							kSoldier.m_kChar.aUpgrades[iPerk] = 0;
						}
					}
				}
			}
		}
		m_iLvlPicked = 1;
	}
	function AddMeldHealButton()
	{
		local UISoldierPromotion kUI;
		local UINavigationHelp kHelpBar;
		local bool bDisableButton;

		if(!bMeldHealButton || (!MELDHEAL_FATIGUE_PURGE && SoldierIsFatigued(m_kUISoldier)))
		{
			return;
		}
		if(MELDHEAL_TECH_REQUIRED > 0 && !GetCore().LABS().IsResearched(MELDHEAL_TECH_REQUIRED))
		{
			return;
		}
		kUI = PRES().m_kSoldierPromote;
		kHelpBar = PRES().GetStrategyHUD().m_kHelpBar;
		if(bShowMeldHealInfo)
		{
			AddInfobox();
		}
		bDisableButton = false;
		if(GetCore().GetResource(eResource_Meld) < MELDHEAL_MELD_PER_CHARGE)
		{
			bDisableButton = true;
		}
		else if (m_kUISoldier.GetStatus() == eStatus_Healing && m_kUISoldier.m_iTurnsOut <= 24 * MELDHEAL_MINIMUM_WOUND_DAYS)
		{
			bDisableButton = true;
		}
		if(kUI.manager.IsMouseActive())
		{
			kHelpBar.AddCenterHelp(m_strMeldHealButton,"", OnMeldInject, bDisableButton);
			kHelpBar.SetButtonType("");
		}
		else
		{
			kHelpBar.AddCenterHelp(m_strMeldHealButton,"Icon_RT_R2", OnMeldInject, bDisableButton);
		}
		if(m_kButtons != none)
		{
			m_kButtons.SetInputState(1);
			m_kButtons.BringToTopOfScreenStack();
		}
		kUI.GetMgr().UpdateView();
	}
	function OnMeldInject()
	{
		local TDialogueBoxData kDialogData;

		if(MELDHEAL_CONFIRM_POPUP)
		{
			kDialogData.eType = 0;
			kDialogData.strTitle = m_strMeldHealButton;
			kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
			kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
			kDialogData.fnCallback = OnMeldHealing;
			PRES().UIRaiseDialog(kDialogData);
		}
		else
		{
			OnMeldHealing(eUIAction_Accept);
		}
	}
	function OnMeldHealing(EUIAction eAction)
	{
		if(eAction != eUIAction_Accept)
		{
			return;
		}
		if(GetCore().GetResource(eResource_Meld) < MELDHEAL_MELD_PER_CHARGE)
		{
			return;
		}
		if(m_kUISoldier.GetStatus() != 8 && m_kUISoldier.GetStatus() != eStatus_Healing)
		{
			return;
		}
		if(SoldierIsFatigued(m_kUISoldier) && MELDHEAL_FATIGUE_PURGE)
		{
			m_kUISoldier.m_iTurnsOut = 0;
			m_kUISoldier.m_bAllIn = false;
			if(m_kUISoldier.GetStatus() != eStatus_OnMission)
			{
				m_kUISoldier.SetStatus(eStatus_Active);
			}
			GetCore().STORAGE().RestoreBackedUpInventory(m_kUISoldier);
			GetCore().BARRACKS().ReorderRanks();
			GetCore().AddResource(eResource_Meld, -MELDHEAL_MELD_PER_CHARGE);
		}
		else if(m_kUISoldier.GetStatus() == eStatus_Healing && m_kUISoldier.m_iTurnsOut > 24 * MELDHEAL_MINIMUM_WOUND_DAYS)
		{
			m_kUISoldier.m_iTurnsOut = Max(m_kUISoldier.m_iTurnsOut * (1.0 - MELDHEAL_FRACTION_PER_CHARGE) - 24 * MELDHEAL_DAYS_PER_CHARGE, 24 * MELDHEAL_MINIMUM_WOUND_DAYS);
			GetCore().AddResource(eResource_Meld, -MELDHEAL_MELD_PER_CHARGE);
		}
		PRES().m_kSoldierPromote.m_kSoldierHeader.UpdateData();
		ClearButtons();
		PRES().m_kSoldierPromote.UpdateButtonHelp();
		if( (m_kUISoldier.GetStatus() == eStatus_Healing || SoldierIsFatigued(m_kUISoldier)) && (!MELDHEAL_NOT_FOR_SHIVS || !m_kUISoldier.IsATank()))
		{
			AddMeldHealButton();
		}
		else if(PRES().GetAnchoredMessenger().IsMessageShown("MeldHeal"))
		{
			PRES().GetAnchoredMessenger().RemoveMessage("MeldHeal");
		}
		if(IsReSpecValidForSoldier(m_kUISoldier))
		{
			AddClearPerkButton();
		}
	}
	function UpdateSoldier(XGStrategySoldier kSoldier, optional bool bForceUpdate)
	{
		local UISoldierPromotion kUI;

		kUI = PRES().m_kSoldierPromote;
		if(kUI==none || kSoldier == none)
		{
			return;
		}
		if(m_kUISoldier != kSoldier || bForceUpdate)
		{
			ClearButtons();
			kUI.UpdateButtonHelp();
			if(IsSoldierInReSpec())
			{
				RestoreSoldierData();
			}
			m_kUISoldier = kSoldier;
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchSoldierPerks);
			m_iWatchSoldierPerks = WorldInfo.MyWatchVariableMgr.RegisterWatchVariableStructMember(kSoldier, 'm_kChar', 'aUpgrades', self, UpdateItemsFromPerks);
			kSoldier.m_kSoldier.kClass.aAbilityUnlocks[0] = kSoldier.m_kSoldier.kClass.aAbilityUnlocks[1] + CLEARPERKS_MISSIONS_INTERVAL;
			if(IsReSpecValidForSoldier(kSoldier))
			{
				SaveSoldierData();
				AddClearPerkButton();
			}
			if( (kSoldier.GetStatus() == eStatus_Healing || SoldierIsFatigued(kSoldier)) && (!MELDHEAL_NOT_FOR_SHIVS || !kSoldier.IsATank()))
			{
				AddMeldHealButton();
			}
			else
			{
				ClearInfoBox();
			}
			UpdateAbilitiesList();
		}
		if(IsSoldierInReSpec() && m_iLvlPicked <= m_kTSavedSoldier.iRank && GetLowestUnassignedBranch() > m_iLvlPicked + 1)
		{
			`Log(m_kUISoldier.GetName(eNameType_Full) @ "levels up during ReSpec procedure. Restoring stats and rank" @ m_kTSavedSoldier.iRank, bDebugLog, name);
			++m_iLvlPicked;
			RestoreSoldierStatsAndRank();
			kUI.GetMgr().UpdateView();
			kUI.m_kSoldierStats.UpdateData();
			kUI.m_kSoldierHeader.UpdateData();
			if(kUI.m_kMecSoldierStats != none)
			{
				kUI.m_kMecSoldierStats.UpdateData();
			}
			PRES().m_kSoldierSummary.UpdateData();
			PRES().m_kSoldierSummary.UpdatePanels();
			if(!m_kUISoldier.HasAvailablePerksToAssign(false) || GetLowestUnassignedBranch() > m_kTSavedSoldier.iRank)
			{
				RecordSoldierReSpecEnd();
			}
		}
	}
	function AS_SetAbilityIcon(int column, int Row, string iconLabel, bool isHighlighted)
	{
		local GfxObject gfxIcon, gfxTree, gfxObj;
		local float fX, fY;
		local array<ASValue> arrParams;

		if(iconLabel ~= "shrekk")
		{
			gfxObj = PRES().m_kSoldierPromote.manager.GetVariableObject("_level0.theInterfaceMgr.gfxSoldierPromotion.SoldierPromotion");
			LogInternal("Screen path:" @ class'UIModUtils'.static.AS_GetPath(gfxObj), 'MiniModsStrategy');
			gfxTree = PRES().m_kSoldierPromote.manager.GetVariableObject(PRES().m_kSoldierPromote.GetMCPath() $".abilityTree");//get the root MC on which to place new icon
			gfxIcon = gfxTree.CreateEmptyMovieClip("xicon"$column$"_"$Row); //create empty place holder on the root MC
			arrParams.Add(1);
			arrParams[0].Type = AS_String;
			arrParams[0].s = "img:///MiniMods.PerkIcons.shrekk";
			gfxIcon.Invoke("loadMovie", arrParams); //now sth like xicon0_1 holds shrekk face
			//class'UIModUtils'.static.AS_BindImage(
			gfxObj = gfxTree.GetObject("icon"$column$"_"$Row);//grab original icon MC
			gfxObj.GetPosition(fX, fY);
			fX -= 20.0; //original icons are drawn so that registration point 0,0 is at center of the icon
			fY -= 20.0;//whereas "shrekk" has registration at top-left corner
			gfxIcon.SetPosition(fX, fY);
			gfxIcon.SetVisible(true);
		}
		else
		{
			PRES().m_kSoldierPromote.manager.ActionScriptVoid(PRES().m_kSoldierPromote.GetMCPath() $ ".SetAbilityIcon");
		}
	}
Begin:
	while(!PRES().IsInState('State_SoldierPromotion'))
	{
		Sleep(0.10);
	}
	FixVerticalScrollingField(PRES().m_kSoldierPromote);
	m_kUISoldier = PRES().m_kSoldierPromote.m_kSoldier;
	Sleep(0.30);
	//AS_SetAbilityIcon(1,1,"shrekk",false);
	//AS_SetAbilityIcon(2,0,"shrekk",false);
	//AS_SetAbilityIcon(3,2,"shrekk",false);
	if(m_kButtons == none && bClearPerksButton)
	{
		m_kButtons = Spawn(class'UIHelpBar_MiniMods');
		m_kButtons.PanelInit(PC(), PRES().m_kSoldierPromote.manager, PRES().m_kSoldierPromote);
		m_kButtons.m_kMutator = self;
	}
	else
	{
		m_kButtons.screen = PRES().m_kSoldierPromote;
	}
	m_kUISoldier.m_kSoldier.kClass.aAbilityUnlocks[0] = m_kUISoldier.m_kSoldier.kClass.aAbilityUnlocks[1] + CLEARPERKS_MISSIONS_INTERVAL;
	if(!PRES().m_kSoldierPromote.m_bPsiPromotion && IsReSpecValidForSoldier(m_kUISoldier))
	{
		SaveSoldierData();
		AddClearPerkButton();
	}
	if( (m_kUISoldier.GetStatus() == eStatus_Healing || SoldierIsFatigued(m_kUISoldier)) && (!MELDHEAL_NOT_FOR_SHIVS || !m_kUISoldier.IsATank()))
	{
		AddMeldHealButton();
	}
	while(PRES().IsInState('State_SoldierPromotion'))
	{
		UpdateSoldier(PRES().m_kSoldierPromote.m_kSoldier);
		Sleep(0.30);
	}
}
state ModdingSquadSelect
{
	event PushedState()
	{
		if(class'MiniModsTactical'.default.m_bSalvageMod)
		{
			RecordCashBalance();
		}
		if(m_iWatchSkyrangerSoldiers != -1)
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchSkyrangerSoldiers);
		if(m_iWatchSkyranger != -1)
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchSkyranger);

		if(PRES().m_kNarrativePopup != none && PRES().m_kNarrativePopup.b_IsVisible)
		{
			PRES().m_kNarrativePopup.Hide();
		}

	}
	event PoppedState()
	{
		PRES().GetHUD().DialogBox.RemoveDialog();
		if(m_iWatchSkyrangerSoldiers != -1)
		{
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchSkyrangerSoldiers);
			m_iWatchSkyrangerSoldiers = -1;
		}
		if(m_iWatchSquadSelectView != -1)
		{
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchSquadSelectView);
			m_iWatchSquadSelectView = -1;
		}
		if(m_iWatchSkyranger != -1)
		{
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchSkyranger);
			m_iWatchSkyranger = -1;
		}
	}
	event ContinuedState()
	{
		ScaleBackpackItems();
		if(m_bSquadSelectProgressIndicator)
			UpdateSelectionProgress();
	}
	function DetermineMap()
	{
		local XGMission kMission;
		local int PlayCount;

		kMission = PRES().m_kSquadSelect.GetMgr().m_kMission;
		GetCore().GEOSCAPE().DetermineMap(kMission); //this will determine the MapName and call IncrementMapPlayHistory (must be reverted)
		class'XComMapManager'.static.DecrementMapPlayHistory(kMission.m_kDesc.m_strMapName, XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_arrMapHistory, PlayCount);
		XComOnlineEventMgr(GameEngine(class'Engine'.static.GetEngine()).OnlineEventManager).SaveProfileSettings();
		kMission.m_bScripted = true; //this will make any other calls of DetermineMap only run IncrementMapPlayHistory (without re-determining map)
	}
	function string GetImagePath()
	{
		local string strMapPath;

		strMapPath = PRES().m_kSquadSelect.GetMgr().m_kMission.m_kDesc.m_strMapName;
		if(InStr(strMapPath, " ") != -1)
		{
			strMapPath = Left(strMapPath, InStr(strMapPath, " "));
		}
		class'UIUtilities'.static.StripSpecialMissionFromMapName(strMapPath);
		return strMapPath;
	}
	function InitializeImage()
	{
		local TDialogueBoxData kBox;
		local string strMapPath, sLog;
	    local Texture2D mapTextureTest;
		local GFxObject gfxBox;

		kBox.strTitle = Caps(PRES().m_kSquadSelect.GetMgr().m_strCurrObj);
		kBox.strAccept = class'UIObjectivesPopup'.default.m_strAcceptLabel;
		if(!IsLongWarBuild())
		{
			sLog $= "Determining map path for vanilla XCom EW game.";
			DetermineMap();
		}
		//strMapPath = PRES().m_kSquadSelect.GetMgr().m_kMission.m_kDesc.m_strMapName;
		//if(InStr(strMapPath, " ") != -1)
		//{
		//	strMapPath = Left(strMapPath, InStr(strMapPath, " "));
		//}
		//class'UIUtilities'.static.StripSpecialMissionFromMapName(strMapPath);
		strMapPath = GetImagePath();
		mapTextureTest = Texture2D(DynamicLoadObject(class'UIUtilities'.static.GetMapImagePackagePath(name(strMapPath)), class'Texture2D'));
		sLog $="\n"$Chr(9)$"DisplayName="$PRES().m_kSquadSelect.GetMgr().m_kMission.m_kDesc.m_strMapName @ "\n"$Chr(9)$"MapName="$strMapPath @ "\n"$Chr(9)$"MapImagePath="$class'UIUtilities'.static.GetMapImagePath(name(strMapPath));
		if(mapTextureTest != none)
		{
			kBox.eType = eDialog_NormalWithImage;
			kBox.strImagePath = class'UIUtilities'.static.GetMapImagePath(name(strMapPath));
		}
		else
		{
			kBox.eType = eDialog_Normal;
			kBox.strText = PRES().m_kSquadSelect.GetMgr().m_strLabelSimMission[10];
		}
		kBox.fnCallback = AnchorMapImage;
		PRES().UIRaiseDialog(kBox);
		gfxBox = PRES().GetHUD().GetVariableObject(string(PRES().GetHUD().DialogBox.GetMCPath()) );
		gfxBox.SetFloat("_y", -60.0);
		`log(sLog,,GetFuncName());
	}
	function bool ShouldDisplayMap()
	{
		local bool bAlreadyShown;
		local bool bHasSatCoverageOverContinent;
		local bool bHasSatCoverageOverCountry;

		bAlreadyShown = PRES().m_kSquadSelect.GetMgr().m_kMission.m_iID == m_iCurrentMissionID;
		bHasSatCoverageOverContinent = PRES().m_kSquadSelect.GetMgr().m_kMission.GetContinent().HasSatelliteCoverage();
		bHasSatCoverageOverCountry = PRES().m_kSquadSelect.GetMgr().Country(PRES().m_kSquadSelect.GetMgr().m_kMission.GetCountry()).HasSatelliteCoverage();
		return (!m_bMapImageOnlyOnce || !bAlreadyShown) && (!m_bMapImageRequiresSat || bHasSatCoverageOverContinent) && (!m_bMapImageReqSatOverCountry || bHasSatCoverageOverCountry);
	}
	function AnchorMapImage(EUIAction eAction)
	{
		local GFxObject gfxObjectiveMC, gfxMapImg;
		local ASDisplayInfo tD;

		gfxObjectiveMC = class'UIModUtils'.static.AS_DuplicateMovieClip(PRES().m_kSquadSelect.GetMCPath() $ ".objectiveMC", "satIntelMC", PRES().m_kSquadSelect.manager);
		gfxMapImg = gfxObjectiveMC.CreateEmptyMovieClip("mapImage");
		class'UIModUtils'.static.AS_BindImage(gfxMapImg, class'UIUtilities'.static.GetMapImagePath(name(GetImagePath())));
		tD = gfxMapImg.GetDisplayInfo();
			tD.x = gfxObjectiveMC.GetObject("bodyText").GetFloat("_x") + gfxObjectiveMC.GetObject("bodyText").GetFloat("_width") - 256;
			tD.y = gfxObjectiveMC.GetObject("bodyText").GetFloat("_y");
			tD.hasXScale = true;
			tD.hasYScale = true;
			tD.XScale=50;
			tD.YScale=50;
			tD.Visible=true;
		gfxMapImg.SetDisplayInfo(tD);
		tD = gfxObjectiveMC.GetDisplayInfo();
			tD.x = 1280 - 256 - 50;
		gfxObjectiveMC.SetDisplayInfo(tD);
		SetTimer(0.30, false, 'DrawMapImgBorder');
	}
	function DrawMapImgBorder()
	{
		local UIModGfxSimpleShape mapImg;

		mapImg = UIModGfxSimpleShape(PRES().m_kSquadSelect.manager.GetVariableObject(PRES().m_kSquadSelect.GetMCPath() $ ".satIntelMC.mapImage", class'UIModGfxSimpleShape'));
		mapImg.DrawRectangle(512 + 4, 256 + 4, false,,,true,0x67e8ed,2);
	}
	function AttachSelectionProgressBox()
	{
		local GFxObject ScreenGfx;
		local UIModGfxSimpleProgressBar gfxBox;
		local float x, y;

		ScreenGfx = PRES().m_kSquadSelect.manager.GetVariableObject(string(PRES().m_kSquadSelect.GetMCPath()));
		if(ScreenGfx.GetObject("SelectionProgress") == none)
		{
			class'UIModUtils'.static.AttachSimpleProgressBarTo(ScreenGfx,"SelectionProgress",,m_bSquadSelectProgressShowBar,"0x67E8ED","0x58C9CD","0x58C9CD");
			gfxBox = UIModGfxSimpleProgressBar(ScreenGfx.GetObject("SelectionProgress", class'UIModGfxSimpleProgressBar'));
			gfxBox.SetBackgroundVisibility(false);
			gfxBox.SetProgressTxtColor("0x4AA957");
			gfxBox.SetFloat("_xscale", 200.0);
			gfxBox.SetFloat("_yscale", 200.0);
			gfxBox.GetPosition(x, y);
			x = 640 - gfxBox.GetFloat("_width") / 2;
			gfxBox.SetPosition(x, y);
			m_iWatchSkyrangerSoldiers = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES().m_kSquadSelect.GetMgr().HANGAR().GetDropship(), 'm_arrSoldiers', self, UpdateSelectionProgress);
			m_iWatchSkyranger = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES().m_kSquadSelect.GetMgr().HANGAR(), 'm_kSkyranger', self, UpdateSelectionProgress);
		}
		UpdateSelectionProgress();
	}
	function UpdateSelectionProgress()
	{
		local GFxObject ScreenGfx;
		local UIModGfxSimpleProgressBar gfxBox;
		local int iSlot, iSelected, iMax;
		local XGShip_Dropship kDropShip;

		kDropShip = PRES().m_kSquadSelect.GetMgr().m_kMission.GetAssignedSkyranger();
		for(iSlot=0; iSlot < kDropShip.m_arrSoldiers.Length; ++ iSlot)
		{
			if(kDropShip.m_arrSoldiers[iSlot] != none)
			{
				++iSelected;
			}
		}
		iMax = PRES().m_kSquadSelect.m_kSquadList.m_iMaxSlots;
		ScreenGfx = PRES().m_kSquadSelect.manager.GetVariableObject(string(PRES().m_kSquadSelect.GetMCPath()));
		gfxBox = UIModGfxSimpleProgressBar(ScreenGfx.GetObject("SelectionProgress", class'UIModGfxSimpleProgressBar'));
		gfxBox.SetProgressTxt(m_bSquadSelectProgressShowTxt ? iSelected $ "/" $ iMax : "");
		gfxBox.SetProgress(m_bSquadSelectProgressShowBar ? float(iSelected)/float(iMax) : 0.0);
		gfxBox.SetBorderVisibility(m_bSquadSelectProgressShowBar);
		ScaleBackpackItems();
	}
	function ScaleBackpackItems()
	{
		local GFxObject gfxBackpack, gfxList, gfxMask;
		local int iBox, iNumItems;
		local ASDisplayInfo tD;
		local array<ASValue> arrParams;
		local float x, y;

		gfxList = PRES().m_kSquadSelect.manager.GetVariableObject(string(PRES().m_kSquadSelect.GetMCPath()) $ ".theSquadList");
		for(iBox=0; iBox < 12; iBox++)
		{
			gfxBackpack = gfxList.GetObject("unit"$iBox).GetObject("backpack");
			if(gfxBackpack != none)
			{
				//backpack is a XComScrollingTextField so it has a textField attached (to scroll it)
				//the items are attached to the textField, each item named backpack0, backpack1 etc.
				iNumItems=0;
				while(gfxBackpack.GetObject("textField").GetObject("backpack"$iNumItems) != none)
				{
					++iNumItems;
				}
				if(iNumItems > 2)
				{
					tD = gfxBackpack.GetObject("textField").GetDisplayInfo();
					tD.XScale = 66;
					tD.YScale = 66;
					gfxBackpack.SetFloat("displayWidth", gfxBackpack.GetFloat("displayWidth") - 87.50);
					if(iNumItems == 4)
					{
						tD.XScale = 60;
						tD.YScale = 60;
						x = gfxBackpack.GetObject("textField").GetObject("backpack1").GetFloat("_x");
						y = gfxBackpack.GetObject("textField").GetObject("backpack1").GetFloat("_y") + gfxBackpack.GetObject("textField").GetObject("backpack1").GetFloat("_height") + 1.0;
						gfxBackpack.GetObject("textField").GetObject("backpack3").SetPosition(x, y);
						gfxBackpack.SetFloat("displayWidth", gfxBackpack.GetFloat("displayWidth") - 87.50);
					}
					gfxBackpack.GetObject("textField").SetDisplayInfo(tD);
				}
				AS_RemoveTweens(gfxBackpack.GetObject("textField"));
				gfxBackpack.GetObject("textField").SetFloat("_x", 0);
				arrParams.Length=0;
				gfxMask = gfxBackpack.getobject("_parent").GetObject("backpackMC");
				//gfxMask.SetFloat("_y", 0);
				gfxMask.SetFloat("_height", 96);
				gfxBackpack.Invoke("realize", arrParams);
			}
		}
	}
	function AS_RemoveTweens(GfxObject gfxInObj)
	{
		PRES().m_kSquadSelect.manager.ActionScriptVoid(PRES().m_kSquadSelect.manager.GetMCPath() $ "._global.caurina.transitions.Tweener.removeTweens");
	}

Begin:
	Sleep(0.10);
	ScaleBackpackItems();
	m_iWatchSquadSelectView = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES().m_kSquadSelect.m_kSquadList, 'm_bInSoldierView', self, ScaleBackpackItems);
	if(XComHeadquartersCamera(PC().PlayerCamera).IsMoving())
	{
		Sleep(0.50);
	}
	if(bMapImageOnSquadSelect && ShouldDisplayMap())
	{
		m_iCurrentMissionID = PRES().m_kSquadSelect.GetMgr().m_kMission.m_iID;
		InitializeImage();
		PRES().m_kHUD.DialogBox.Hide();
		PRES().m_kHUD.DialogBox.Show();
	}

	if(m_bSquadSelectProgressIndicator)
		AttachSelectionProgressBox();
}
state ModdingSituationRoom
{
	event PoppedState()
	{
		if(m_iWatchCurrentView != -1)
		{
			WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchCurrentView);
		}
	}
	function ExposeAlienStats()
	{
		local string sResearch, sResources, sXComThreat, sResourceLvl;

		//1 - alien research
		//19 - alien resources
		//21 - xcom threat
		if(!IsLongWarBuild())
		{
			return;
		}
		sResearch = m_strAlienResearchLabel $":"@ GetGame().GetGameCore().STAT_GetStat(1);
		sResources = m_strAlienResourcesLabel $":"@ GetGame().GetGameCore().STAT_GetStat(19);
		sResourceLvl = m_strAlienResourceLvlLabel $":"@ Clamp(GetGame().GetGameCore().STAT_GetStat(19) / 50, 0 , 4);
		if(!GetGame().GetGameCore().IsOptionEnabled(eGO_DynamicWar))
		{
			sXComThreat = m_strXComThreatLabel $":"@ Clamp(GetGame().GetGameCore().STAT_GetStat(21) / 2, 0,4);
		}
		else
		{
			sXComThreat = m_strXComThreatLabel $":"@ Clamp(GetGame().GetGameCore().STAT_GetStat(21), 0, 8);
		}
		PRES().GetStrategyHUD().AS_AddResource(sResearch);
		PRES().GetStrategyHUD().AS_AddResource(sResources);
		PRES().GetStrategyHUD().AS_AddResource(sResourceLvl);
		PRES().GetStrategyHUD().AS_AddResource(sXComThreat);
	}
	function UpdateView()
	{
		ExposeAlienStats();
	}
Begin:
	while(PRES().m_kSituationRoom == none || !PRES().m_kSituationRoom.IsInited())
	{
		Sleep(0.10);
	}
	if(m_bShowAlienResources)
	{
		ExposeAlienStats();
		m_iWatchCurrentView = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES().GetStrategyHUD().m_kMenu.m_kSubMenu, 'm_arrUIOptions', self, UpdateView);
	}
}
state ModdingSoldierList
{
	event PushedState()
	{
		`Log(GetFuncName() @ GetStateName(),, 'MiniModsStrategy');
	}
	event PoppedState()
	{
		`Log(GetFuncName() @ GetStateName(),, 'MiniModsStrategy');
		if(m_kSoldierListHelper != none)
		{
			m_iSoldierListSortingCategory = m_kSoldierListHelper.m_iCurrentSortingCategory;
			m_bSoldierListReversedOrder = m_kSoldierListHelper.m_bReverseOrderApplied;
			m_kSoldierListHelper.Uninit();
			m_kSoldierListHelper.Destroy();
			m_kSoldierListHelper = none;
		}
	}
Begin:
	while(PRES().m_kSoldierList == none || !PRES().m_kSoldierList.IsInited())
	{
		Sleep(0.10);
	}
	if(m_kSoldierListHelper != none)
	{
		m_kSoldierListHelper.Uninit();
	}
	else
	{
		m_kSoldierListHelper = Spawn(class'MMSoldierListHelper');
	}
	m_kSoldierListHelper.m_bShowingPerksEnabled = m_bShowPerksOnSoldierLists;
	m_kSoldierListHelper.m_bSortingModEnabled = !m_bDisableSortingSoldierLists;
	m_kSoldierListHelper.Init(m_iSoldierListSortingCategory, m_bSoldierListReversedOrder);
	m_kSoldierListHelper.m_kInputGate.m_kMutator = self;
}
state UpdatingOptions
{
	event PushedState()
	{
		//XComContentManager(class'Engine'.static.GetEngine().GetContentManager()).RequestObjectAsync("UILibrary_MapImages.URB_Bar");
		BuildDataForModMgr();
	}
	event  PoppedState()
	{
		if(GetGame() != none)
		{
			UpdatePerkDescriptions();
		}
		if(class'MiniModsTactical'.default.m_bFuelConsumption && class'MiniModsTactical'.default.ADJUST_FUEL_MULTIPLIER > 0.0)
		{
			class'MiniModsTactical'.static.AdjustCoreArmorFuel();
		}
		CleanUpModsProfile();
		SaveConfig();
	}
	function CleanUpModsProfile()
	{
		class'XComModsProfile'.static.ClearAllSettingsForMod("MapImageOnSquadSelect");
		class'XComModsProfile'.static.ClearAllSettingsForMod("MeldHealing");
		class'XComModsProfile'.static.ClearAllSettingsForMod("ClearPerks");
		class'XComModsProfile'.static.ClearAllSettingsForMod("MiscMiniMods");
		class'XComModsProfile'.static.ClearAllSettingsForMod("OfficerIronWill");
		class'XComModsProfile'.static.ClearAllSettingsForMod("AbductionMapOrganizer");
	}
}
state ModdingMemorial
{
	event PushedState()
	{
		`log(string(GetStateName()),,GetFuncName());
		AddMemorialBindings();
	}
	event PoppedState()
	{
		`log(string(GetStateName()),,GetFuncName());
		ClearMemorialBindings();
	}
	function AddMemorialBindings()
	{
		local KeyBind NewBinding;

		NewBinding.Name='One';
		NewBinding.Control=true;
		NewBinding.Command="Mutate Resurrect:1";
		class'MiniModsTactical'.static.AddBinding(NewBinding);

		NewBinding.Name='Two';
		NewBinding.Command="Mutate Resurrect:2";
		class'MiniModsTactical'.static.AddBinding(NewBinding);

		NewBinding.Name='Three';
		NewBinding.Command="Mutate Resurrect:3";
		class'MiniModsTactical'.static.AddBinding(NewBinding);

		NewBinding.Name='Four';
		NewBinding.Command="Mutate Resurrect:4";
		class'MiniModsTactical'.static.AddBinding(NewBinding);

		NewBinding.Name='Five';
		NewBinding.Command="Mutate Resurrect:5";
		class'MiniModsTactical'.static.AddBinding(NewBinding);

		NewBinding.Name='Six';
		NewBinding.Command="Mutate Resurrect:6";
		class'MiniModsTactical'.static.AddBinding(NewBinding);

		NewBinding.Name='Seven';
		NewBinding.Command="Mutate Resurrect:7";
		class'MiniModsTactical'.static.AddBinding(NewBinding);

		NewBinding.Name='Eight';
		NewBinding.Command="Mutate Resurrect:8";
		class'MiniModsTactical'.static.AddBinding(NewBinding);

		NewBinding.Name='Nine';
		NewBinding.Command="Mutate Resurrect:9";
		class'MiniModsTactical'.static.AddBinding(NewBinding);

		NewBinding.Name='Zero';
		NewBinding.Command="Mutate Resurrect:10";
		class'MiniModsTactical'.static.AddBinding(NewBinding);
	}
	function ClearMemorialBindings()
	{
		local PlayerInput kInput;
		local int i;

		kInput = class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().PlayerInput;
		i = kInput.Bindings.Length - 1;
		while(i >= 0)
		{
			if(InStr(kInput.Bindings[i].Command, "mutate resurrect",,true) != -1)
			{
				kInput.Bindings.Remove(i, 1);
			}
			i--;
		}
	}
	function Mutate(string MutateString, PlayerController PC)
	{
		if(InStr(MutateString, "resurrect:",,true) != -1)
		{
			`log(MutateString,,GetFuncName());
			ResurrectSoldier(int(GetParameterString(0, MutateString)) - 1);
		}
		super.Mutate(MutateString, PC);
	}
	function ResurrectSoldier(int iFallenIDX)
	{
		local UIMemorial kUI;
		local XGMemorialUI kMgr;
		local XGStrategySoldier kSoldier;
		local array<XGStrategySoldier> arrFallen;

		`log(iFallenIDX,,GetFuncName());
		kUI = PRES().m_kMemorial;
		kMgr = kUI.GetMgr();
		foreach kMgr.BARRACKS().m_arrFallen(kSoldier)
		{
			if(kSoldier.IsATank())
			{
				continue;
			}
			else
			{
				arrFallen.AddItem(kSoldier);
			}
		}
		if(iFallenIDX >=0 && iFallenIDX < arrFallen.Length)
		{
			kSoldier = arrFallen[iFallenIDX];
			kSoldier.m_strCauseOfDeath = "";
			kSoldier.m_strKIADate = "";
			kSoldier.m_strKIAReport = "";
			kSoldier.m_bMIA = false;
			kSoldier.m_aStatModifiers[0] = Max(kSoldier.m_aStatModifiers[0] - 1, 1 - kSoldier.GetMaxStat(0));
			kMgr.BARRACKS().m_arrFallen.RemoveItem(kSoldier);
			kMgr.BARRACKS().m_arrSoldiers.AddItem(kSoldier);
			kMgr.BARRACKS().MoveToInfirmary(kSoldier);
			kMgr.BARRACKS().DetermineTimeOut(kSoldier);
			kSoldier.CreatePawn();
			kSoldier.OnLoadoutChange();
			kMgr.UpdateFallen();
			kUI.Invoke("ClearSoldierList");
			kUI.UpdateData();
		}
	}
}
state ModdingAwardCeremony
{
	event PushedState()
	{
		AddMedalCeremonyBindings();
	}
	event PoppedState()
	{
		ClearMedalCeremonyBindings();
	}
	function AddMedalCeremonyBindings()
	{
		local KeyBind NewBinding;

		NewBinding.Name='D';
		NewBinding.Control=true;
		NewBinding.Command="Mutate DemoteOfficer";
		class'MiniModsTactical'.static.AddBinding(NewBinding);
	}
	function ClearMedalCeremonyBindings()
	{
		local PlayerInput kInput;
		local int i;

		kInput = class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().PlayerInput;
		i = kInput.Bindings.Length - 1;
		while(i >= 0)
		{
			if(InStr(kInput.Bindings[i].Command, "Mutate DemoteOfficer",,true) != -1)
			{
				kInput.Bindings.Remove(i, 1);
			}
			i--;
		}
	}
	function Mutate(string MutateString, PlayerController PC)
	{
		if(InStr(MutateString, "DemoteOfficer",,true) != -1)
		{
			DemoteOfficer();
		}
		super.Mutate(MutateString, PC);
	}
	function DemoteOfficer(optional XGStrategySoldier kSoldier=GetCore().BARRACKS().m_kAwardCeremonySoldier)
	{
		local int i;

		if(kSoldier != none)
		{
			for(i=0; i < 172; ++i)
			{
				if(Class'XGTacticalGameCoreNativeBase'.static.IsMedalPerk(EPerkType(i)) || i==171 ||i==12)
				{
					kSoldier.m_kChar.aUpgrades[i] = 0;
				}
			}
			RecycleMedals(kSoldier);
			kSoldier.m_bPsiTested = false;
			kSoldier.m_iNumMissions = kSoldier.m_iNumMissions & 65535;
		}
	}
	function RecycleMedals(XGStrategySoldier kSoldier)
	{
		local RecycledMedals tMedals;
		local int iMedal;

		for(iMedal=0; iMedal < 6; ++iMedal)
		{
			if(kSoldier.m_arrMedals[iMedal] > 0)
			{
				kSoldier.m_arrMedals[iMedal] = 0;
				tMedals.m_arrMedalsToRecycle.AddItem(EMedalType(iMedal));
			}
		}
		if(tMedals.m_arrMedalsToRecycle.Length > 0)
		{
			tMedals.m_iNumMissions = kSoldier.BARRACKS().NUM_RECYCLE_MISSIONS;
			kSoldier.BARRACKS().m_arrRecycledMedals.AddItem(tMedals);
		}
	}
}
DefaultProperties
{
	m_strBuildVersion="v.2.33.1"
	m_iCurrentRespecSoldierID=-1
	m_iLvlPicked=1
	m_iCurrentMissionID=-1
	m_iWatchStorage=-1
	m_iSoldierListSortingCategory=-1
}