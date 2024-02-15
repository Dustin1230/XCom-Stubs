class XComHexMods extends XComMutator
	config(HexMods);

var string m_strVersion;
var config bool m_bLoadoutManager;
var config bool m_bSightlines;
var config bool m_bQuietBradford;
var config bool m_bEnhancedTacInfo;

var XHHelper_LoadoutMgr m_kLoadoutMgr;
var XHHelper_Sightlines m_kSightlines;
var XHHelper_EnhancedTacInfo m_kTacInfo;

var UIModManager m_kModMgr;

//UTILITY FUNCTIONS
function XComTacticalGRI XGRI()
{
	return XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI);
}
function XGBattle_SP GetBattle()
{
	return XGBattle_SP(XGRI().GetBattle());
}
function XComPresentationLayerBase BasePRES()
{
	return XComTacticalController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).m_Pres;
}
function XComPresentationLayer PRES()
{
	return XComPresentationLayer(BasePRES());
}
function XComHQPresentationLayer HQPRES()
{
	return XComHQPresentationLayer(BasePRES());
}
function string GetDebugName()
{
	return "XComHexMods" @ m_strVersion;
}
static function Mutator GetMutator(string sMutatorClass)
{
	local Mutator kM;
	local class<Mutator> kMutClass;

	kMutClass = class<Mutator>(DynamicLoadObject(sMutatorClass, class'Class', true));
	if(kMutClass != none)
	{
		kM = class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator;
		while(kM != none)
		{
			if(kM.Class == kMutClass)
			{
				return kM;
			}
			kM = kM.NextMutator;
		}
	}
	return none;
}
function UIModManager GetModMgr()
{
	local XComMod kMod;

	if(m_kModMgr == none)
	{
		foreach XComGameInfo(WorldInfo.Game).Mods(kMod)
		{
			if(UIModManager(kMod) != none)
			{
				m_kModMgr = UIModManager(kMod);
				break;
			}
		}
	}
	return m_kModMgr;
}

//CORE EVENTS
event PostBeginPlay()
{
	`Log(GetDebugName() @ "online",, 'XComHexMods');
	if(class'Engine'.static.GetEngine().IsA('MyXComEngine'))
	{
		RegisterCallbacks();
	}
	UpdateMods();
}
event Destroyed()
{
	if(m_kLoadoutMgr != none)
	{
		m_kLoadoutMgr.Destroy();
	}
	if(m_kSightlines != none)
	{
		m_kSightlines.Destroy();
	}
}
//DATA FLOW CONTROL
function UpdateMods()
{
	if(m_bLoadoutManager && m_kLoadoutMgr == none && class'Engine'.static.GetCurrentWorldInfo().Game.IsA('XComHeadquartersGame'))
	{
		m_kLoadoutMgr = Spawn(class'XHHelper_LoadoutMgr');
	}
	if(m_bSightlines && m_kSightlines == none && class'Engine'.static.GetCurrentWorldInfo().Game.IsA('XComTacticalGame'))
	{
		m_kSightlines = Spawn(class'XHHelper_Sightlines');
	}
	m_kTacInfo = Spawn(class'XHHelper_EnhancedTacInfo');
}
function UpdateOptions()
{
	m_bLoadoutManager = class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "LoadoutManager");
	m_bSightlines = class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "Sightlines");

	UpdateMods();
}
function RegisterCallbacks()
{
	//strategy callbacks
	class'MyXCom'.static.RegisterModCallback("UISoldierSummary.GoToView", OnUISoldierSummary_GoToView);
	class'MyXCom'.static.RegisterModCallback("UISoldierSummary.OnUnrealCommand", OnUISoldierSummary_OnUnrealCommand );
	class'MyXCom'.static.RegisterModCallback("UISoldierSummary.UpdateData", OnUISoldierSummary_UpdateData);
	class'MyXCom'.static.RegisterModCallback("UISoldierSummary.OnInit", OnUISoldierSummary_OnInit);
	class'MyXCom'.static.RegisterModCallback("UISoldierSummary.AS_SetDescription", OnUISoldierSummary_SetDescription);
	class'MyXCom'.static.RegisterModCallback("XGSoldierUI.OnLeaveSoldierUI", OnXGSoldierUI_LeaveSoldierUI);
	class'MyXCom'.static.RegisterModCallback("XGSoldierUI.OnMainMenuOption", OnXGSoldierUI_OnMainMenuOption);
	class'MyXCom'.static.RegisterModCallback("XGSoldierUI.UpdateView", OnXGSoldierUI_UpdateView);
	class'MyXCom'.static.RegisterModCallback("UISquadSelect.OnUnrealCommand", OnUISquadSelect_OnUnrealCommand);

	//tactical callbacks
	class'MyXCom'.static.RegisterModCallback("XGUnit.UpdateInteractClaim", OnXGUnit_UpdateInteractClaim);
	class'MyXCom'.static.RegisterModCallback("XGUnit.OnUpdatedVisibility", OnXGUnit_OnUpdatedVisibility);
	class'MyXCom'.static.RegisterModCallback("XGUnit.OnEnterPoison", OnXGUnit_OnEnterPoison);
	class'MyXCom'.static.RegisterModCallback("XGUnit.SetBETemplate", OnXGUnit_SetBETemplate);
	class'MyXCom'.static.RegisterModCallback("UITacticalHUD_Radar.UpdateBlips", OnUITacticalHUD_Radar_UpdateBlips);
	class'MyXCom'.static.RegisterModCallback("UIUnitFlag.RealizeEKG", OnUIUnitFlag_RealizeEKG);
	class'MyXCom'.static.RegisterModCallback("UIUnitFlag.OnInit", OnUIUnitFlag_OnInit);
	class'MyXCom'.static.RegisterModCallback("XGAIPlayer_Animal.OnUnitEndMove", OnXGAIPlayerAnimal_OnUnitEndMove);

}
function InitMutator(string strMessage, out string strCallback)
{
	super.InitMutator(strMessage, strCallback);
}
function ModifyLogin(out string strMessage, out string strCallback)
{
	if(class'Engine'.static.GetCurrentWorldInfo().Game.IsA('XComHeadquartersGame'))
	{
		ModifyLoginStrategy(strMessage, strCallback);
	}
	else if(class'Engine'.static.GetCurrentWorldInfo().Game.IsA('XComTacticalGame'))
	{
		ModifyLoginTactical(strMessage, strCallback);
	}
	super.ModifyLogin(strMessage, strCallback);
}
function ModifyLoginStrategy(out string strMessage, out string strCallback)
{
}
function ModifyLoginTactical(out string strMessage, out string strCallback)
{
}
function RegisterWatchVarsTactical()
{
	class'Engine'.static.GetCurrentWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kGermanMode', self, OnInfoPanel);
}
function RegisterWatchVarsStrategy()
{
}
function OnUISoldierSummary_GoToView(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bLoadoutManager)
		m_kLoadoutMgr.UISoldierSummaryGoToView(strMessage, strCallback);
}
function OnXGSoldierUI_LeaveSoldierUI(Object kObj, out string strMessage, out string strCallback)
{
		if(m_bLoadoutManager)
			m_kLoadoutMgr.OnLeaveSoldierUI(strMessage, strCallback);
}
function OnXGSoldierUI_OnMainMenuOption(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bLoadoutManager)
			m_kLoadoutMgr.OnMainMenuOption(strMessage, strCallback);
}
function OnXGSoldierUI_UpdateView(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bLoadoutManager)
		m_kLoadoutMgr.SoldierUpdateView(strMessage, strCallback);
}
function OnUISoldierSummary_OnUnrealCommand(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bLoadoutManager)
		m_kLoadoutMgr.UISummaryOnUnrealCommand(strMessage, strCallback);
}
function OnUISoldierSummary_UpdateData(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bLoadoutManager)
		m_kLoadoutMgr.UISummaryUpdateData(strMessage, strCallback);
}
function OnUISoldierSummary_OnInit(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bLoadoutManager)
		m_kLoadoutMgr.UISummaryOnInit();
}
function OnUISquadSelect_OnUnrealCommand(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bLoadoutManager)
		m_kLoadoutMgr.UISquadSelectOnCommand(strMessage, strCallback);
}
function OnUISoldierSummary_SetDescription(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bLoadoutManager)
		m_kLoadoutMgr.LM_SetDescription(strMessage, strCallback);
}
function OnXGUnit_UpdateInteractClaim(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bSightlines)
		m_kSightlines.FixUpdateInteractclaim(XGUnit(kObj), strMessage, strCallback);
}
function OnXGUnit_OnUpdatedVisibility(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bSightlines)
		m_kSightlines.FixIndicatorsOnGrapple(XGUnit(kObj), strMessage, strCallback);
}
function OnUITacticalHUD_Radar_UpdateBlips(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bSightlines)
		m_kSightlines.UpdateBlipsForHelpers();
}
function OnUIUnitFlag_RealizeEKG(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bSightlines)
		m_kSightlines.UpdateOWIcon(UIUnitFlag(kObj));
}
function OnXGAIPlayerAnimal_OnUnitEndMove(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bSightlines)
		m_kSightlines.OnUnitEndMove(strMessage);
}
function OnXGUnit_OnEnterPoison(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bSightlines)
		m_kSightlines.FixOnEnterPoison(XGUnit(kObj), strMessage, strCallback);
}
function OnUIUnitFlag_OnInit(Object kObj, out string strMessage, out string strCallback)
{
	if(m_kSightlines != none)
		m_kSightlines.SubscribeToUnitFlagUpdate(UIUnitFlag(kObj));
}
function OnXGUnit_SetBETemplate(Object kObj, out string strMessage, out string strCallback)
{
	if(m_bSightlines)
		m_kSightlines.FixBioelectricSkin(XGUnit(kObj), strMessage, strCallback);
}
//MODDING STUFF
function PostLevelLoaded(PlayerController PC)
{
	RegisterWatchVarsTactical();
	if(m_bQuietBradford)
		ImplementQuietBradford();
}
function PostLoadSaveGame(PlayerController PC)
{
	RegisterWatchVarsTactical();
}
function MutateNotifyKismetOfLoad(PlayerController PC)
{
}
function ImplementQuietBradford(optional bool bLoadedFromSave=true)
{
	local array<SequenceObject> arrSequences;
	local int iSeq;
	local SequenceAction kSeqAct, kSeqNewObjective;

	//let's find the SeqAct which stands for announcement of new objective 
	//the ObjComment had been retrieved by decompressing URBCommercialAlley_SF.upk and studying SeqAct_Delay_7
	class'Engine'.static.GetCurrentWorldInfo().GetGameSequence().FindSeqObjectsByClass(class'SeqAct_ActivateNarrative',true,arrSequences);
	for(iSeq=0; iSeq < arrSequences.Length; ++iSeq)
	{
		kSeqAct = SequenceAction(arrSequences[iSeq]);
		if(kSeqAct.ObjComment ~= "Play New Objective" && kSeqAct.OutputLinks[0].Links.Length == 0)
		{
			kSeqNewObjective= kSeqAct;
			break;
		}
	}
	//find sequences (there's just one actually) which have OutputLink with LinkedOp commented as "...Intro"
	//and replace the OutputLink with already found "Play New Objective"
	class'Engine'.static.GetCurrentWorldInfo().GetGameSequence().FindSeqObjectsByClass(class'SequenceAction',true,arrSequences);
	for(iSeq=0; iSeq < arrSequences.Length; ++iSeq)
	{
		kSeqAct = SequenceAction(arrSequences[iSeq]);
		if( kSeqAct.OutputLinks.Length > 0
			&& kSeqAct.OutputLinks[0].Links.Length > 0
			&& (kSeqAct.OutputLinks[0].Links[0].LinkedOp.ObjComment ~= "Play Intro" || kSeqAct.OutputLinks[0].Links[0].LinkedOp.ObjComment ~= "Play CovExt_Intro"))
		{
			kSeqAct.OutputLinks[0].Links[0].LinkedOp = kSeqNewObjective;
			break;
		}
	}
	//ensure yellow arrows pointing to radar arrays
	if(GetBattle().IsA('XGBattle_SPCovertOpsExtraction'))
	{
		PRES().InitializeSpecialMissionUI();
	}
}
function OnInfoPanel()
{
	if(PRES().IsInState('State_GermanMode'))
	{
		PushState('ModdingInfoPanel');
	}
	else if(IsInState('ModdingInfoPanel'))
	{
		PopState();
	}
}
function BuildDataForModMgr()
{
	Spawn(class'XHModsOptionsContainer');
}
state UpdatingOptions
{
	event PushedState()
	{
		BuildDataForModMgr();
		class'UIModManager'.static.RegisterUpdateCallback(UpdateOptions);
	}
}
function RequestStrategyComponents()
{
	XComContentManager(class'Engine'.static.GetEngine().GetContentManager()).RequestObjectAsync("UICollection_Strategy.ARC_UICollection_Strategy");
}
state ModdingInfoPanel
{
	event PushedState()
	{
		RequestStrategyComponents();
	}
	event PoppedState()
	{
		m_kTacInfo.m_gfxStats = none;
	}
Begin:
	while(!PRES().IsInState('State_GermanMode'))
	{
		Sleep(0.10);
	}
	m_kTacInfo.AttachStatIcons();
	while(m_kTacInfo.m_gfxStats == none || !m_kTacInfo.m_gfxStats.m_bGfxReady)
	{
		Sleep(0.0);
	}
	m_kTacInfo.Init(PRES().m_kGermanMode.m_kUnit);
	m_kTacInfo.SetUnitStats();
	m_kTacInfo.SetAlienCounts(PRES().m_kGermanMode.m_kUnit.IsAlien());
}
DefaultProperties
{
	m_strVersion="beta 1.0"
}