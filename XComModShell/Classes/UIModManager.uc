class UIModManager extends XComMod
	dependson(UIModOptionsContainer);

`define MutateFromHere XComGameInfo(Outer).BaseMutator.Mutate(string(Class) $ "." $ GetFuncName() $":"$self, PRES().GetALocalPlayerController())

var string BuildVersion;
var bool m_bInitDone;
var bool m_bDifficultyBoxesDone;

/** Holds reference to "Mod Packages" menu; a twin of SW options screen*/
var UIModToggles m_kModToggles;

/** Holds reference to the UI panel of the mod manager*/
var UIModShell m_kModShell;

/** Holds reference to the background panel on top of which UIModShell is currently displayed*/
var UI_FxsScreen m_kBackgroundScreen;

var UIModButtonHelper m_kButtonHelper;

var int m_iAdvOptionsWatchVar;
var int m_iPauseMenuWatchVar;
var int m_iMutatorListButtonID;

/** Informs if the current GameInfo is XComShell*/
var bool m_bIsInShell;

/** A helper for tracking if the "Mods Menu" button has been added to UIShellDifficulty*/
var bool m_bButtonAdded;

/** A helper for tracking if the "Mods Menu" button has been added to UIFinalShell*/
var bool m_bShellButtonAdded;
/** A helper for tracking if the "Mods Info" button has been added to UIPauseMenu*/
var bool m_bPauseButtonAdded;

/** A helper - set to true when SaveAndExit had been called*/
var bool m_bModsNeedUpdate;

/** Holds paths to all main mod classes ever recorded. Can hold duplicated paths.*/
var array<string> m_arrMasterClassPaths;

/** A helper to prevent double caching of base Long War UI data*/
var UIModOptionsContainer m_kLWContainer;

/** A helper to prevent double caching of Mod Manager options*/
var UIModOptionsContainer m_kOptionsContainer;

/** Holds data required to build menus - mods, packages, config option*/
var array<TModUIData> m_arrUIModData;

/** Holds base info for Select Mods menu (mod names, availability and description).*/
var array<TMenuOption> m_arrModMenuOptions;

/** Holds base info for Mod Packages menu (packages' names, availability and list of included mods)*/
var array<TMenuOption> m_arrPackageMenuOptions;

/** Holds all credits to mod developers*/
var array<localized string> m_arrCreditsModMgr;

/** A helper array to avoid runaway loops when sorting mod list*/
var array<string> m_arrEnabledModNames;

var int m_iModProfileArrayIdx;
var int m_iModProfileID;

var localized string m_strModsMenuButton;
var localized string m_strNoDescription;
var localized string m_strMissingPackage;
var localized string m_strDisabledPackage;
var localized string m_strModsInPackage;
var localized string m_sModProfilePrefix;
var localized array<string> m_arrVarName;
var localized array<string> m_arrVarFriendlyName;
var localized array<string> m_arrVarDescription;
var array< delegate<OnUpdateOptionsCallback> > m_arrCallbackDelegates;
var array< delegate<OnUpdateOptionsCallback> > m_arrStartUpDelegates;
var array< delegate<OnInitWidgetDataCallback> > m_arrInitWidgetDelegates;

delegate OnUpdateOptionsCallback();
delegate OnInitWidgetDataCallback(out UIWidget kWidget, out TModOption tOption);

simulated function StartMatch()
{
	if(WaitingForPRES())
	{
		return;
	}
	if(!m_bInitDone)
	{
		super.StartMatch();
		UpdateMasterClassPaths();
		UpdateCurrentModProfile();
		UpdateGameCoreSettings();
		PRES().SubscribeToUIUpdate(UpdatePresState);//this is a patch for the lack of Tick
		m_bIsInShell = (DynamicLoadObject("XComUIShell.XComShellPresentationLayer", class'Class', true) != none && PRES().IsA('XComShellPresentationLayer'));
		m_bInitDone = true;
		`Log(GetFuncName() @ Class.Name @ BuildVersion @ "online",, name);
	}
}
function bool WaitingForPRES()
{
	local bool bPressIsReady;

	bPressIsReady = PRES() != none;
	if(!bPressIsReady)
	{
		LogInternal("Cannot find PRES actor, retrying in 0.5 seconds", 'UIModManager');
		GameInfo(Outer).SetTimer(0.50, false, 'StartMatch', self);
	}
	return !bPressIsReady;
}
function XComPresentationLayerBase PRES()
{
	return XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).m_Pres;
}
/** This function is called by Tick event of the current XComPresentationLayerBase actor*/
function UpdatePresState()
{
	if(m_bIsInShell)
	{
		if( PRES().m_kDifficulty == none || (PRES().m_kDifficulty != none && !PRES().IsInState('State_ShellDifficulty') && !PRES().IsInState('State_GameplayToggles')) )
		{
			if(m_iAdvOptionsWatchVar != -1)
			{
				//stop tracing UIShellDifficulty for m_bViewingAdvancedOptions
				class'Engine'.static.GetCurrentWorldInfo().MyWatchVariableMgr.UnRegisterWatchVariable(m_iAdvOptionsWatchVar);
				m_iAdvOptionsWatchVar = -1;
			}
			if(XComShellPresentationLayer(PRES()).m_kFinalShellScreen != none && XComShellPresentationLayer(PRES()).m_kFinalShellScreen.IsInited() && PRES().IsInState('State_FinalShell'))
			{
				m_bShellButtonAdded = XComShellPresentationLayer(PRES()).m_kFinalShellScreen.m_iMP != 1;
				if(!m_bShellButtonAdded)
				{
					AddShellButton();
				}
			}
			m_bButtonAdded = false;
			return;
		}
		if(m_iAdvOptionsWatchVar == -1 && PRES().m_kDifficulty != none)
		{   
			//start tracing UIShellDifficulty for m_bViewingAdvancedOptions
			if(!m_bButtonAdded)
			{
				ButtonsNeedUpdate();
			}
			m_iAdvOptionsWatchVar = class'Engine'.static.GetCurrentWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(XComPlayerController(XComGameInfo(Outer).GetALocalPlayerController()).m_Pres.m_kDifficulty,'m_bViewingAdvancedOptions', self, ButtonsNeedUpdate);
			CacheExtraDifficultyBoxes(class'UIShellDifficulty'.default.m_arrDifficultyTypeStrings.Length-4);
		}
	}
	else
	{
		//outside of Shell the Difficulty menu is only available during PAUSE menu when MyWatchVariableMgr does not work (cause is paused)
		//hence the need for m_bButtonAdded instead of a watchVar
		if(m_bButtonAdded && PRES().m_kDifficulty == none)
		{
			m_bButtonAdded = false;
			PopButtonHelper();
		}
		else if(!m_bButtonAdded && PRES().m_kDifficulty != none)
		{
			ButtonsNeedUpdate();
		}
		else if(PRES().m_kPauseMenu != none && PRES().m_kPauseMenu.IsInited() && !m_bPauseButtonAdded)
		{
			AddPauseMenuButton();
		}
		else if(m_bPauseButtonAdded && PRES().m_kPauseMenu == none)
		{
			m_bPauseButtonAdded = false;
			PopButtonHelper();
		}
	}
}
function CacheExtraDifficultyBoxes(optional int iExtraBoxes=2)
{
	local GFxObject gfxWidgetHelper, gfxBox;
	local int i, iNumBoxes;


	gfxWidgetHelper = PRES().m_kDifficulty.manager.GetVariableObject(PRES().m_kDifficulty.GetMCPath() $ ".difficultyWidgetHelper");
	iNumBoxes = int(gfxWidgetHelper.GetFloat("MAX_widgets"));
	for(i = iNumBoxes; i < iNumBoxes + iExtraBoxes; ++i)
	{
		gfxBox = gfxWidgetHelper.GetObject("_parent").GetObject("option"$i);
		if(gfxBox == none)
		{
			gfxBox = class'UIModUtils'.static.AS_DuplicateMovieClip(class'UIModUtils'.static.AS_GetPath(gfxWidgetHelper.GetObject("_parent").GetObject("option"$(i-1))), "option"$i, PRES().m_kDifficulty.manager);
			gfxBox.SetFloat("_y", gfxWidgetHelper.GetObject("_parent").GetObject("option"$(i-1)).GetFloat("_y") + gfxWidgetHelper.GetObject("_parent").GetObject("option"$(i-1)).GetFloat("_height"));
		}
		gfxWidgetHelper.GetObject("widgets").SetElementObject(i, gfxBox);
		gfxBox.SetVisible(true);
	}
}
function PopButtonHelper()
{
	if(m_kButtonHelper != none)
	{
		PRES().GetUIMgr().PopFirstInstanceOfScreen(m_kButtonHelper);
		m_kButtonHelper.Destroy();
		m_kButtonHelper = none;
	}
}
function ButtonsNeedUpdate()
{
	//calling with timer to let UIShellDifficulty init itself first
	//the timer must be on m_kDifficulty cause other actors are paused
	//if timer is too short the button will not spawn on low-performance PC/laptop
	if(!PRES().m_kDifficulty.IsTimerActive('UpdateButtonHelp', self))
	{
		PRES().m_kDifficulty.SetTimer(0.30, false, 'UpdateButtonHelp', self);
	}
}
function UpdateButtonHelp()
{
	//good practice: for timer-called functions check if the relevant actor != none
	if(PRES().m_kDifficulty != none)
	{
		PRES().m_kDifficulty.m_kHelpBar.AddCenterHelp(m_strModsMenuButton, "Icon_BACK_SELECT", ShowModsMenu);
		m_kBackgroundScreen = PRES().m_kDifficulty;
		SetupButtonHelper();
		m_bButtonAdded = true;
	}
}
function SetupButtonHelper()
{
	if(m_kButtonHelper != none)
	{
		m_kButtonHelper.screen = m_kBackgroundScreen;
		m_kButtonHelper.BecomeFirstToReceiveInput();
	}
	else
	{
		m_kButtonHelper = PRES().Spawn(class'UIModButtonHelper');
		m_kButtonHelper.PanelInit(XComPlayerController(PRES().GetALocalPlayerController()), PRES().GetHUD(), m_kBackgroundScreen);
		m_kButtonHelper.m_kModMgr = self;
	}
}
function AddShellButton()
{
	local GfxObject gfxFinalShell, gfxShellButtonMP;
	local UIFinalShell kShell;

	SetupShellButtons(); //ensure 6 buttons appear
	kShell = XComShellPresentationLayer(PRES()).m_kFinalShellScreen;
	gfxFinalShell = PRES().GetHUD().GetVariableObject( string(kShell.GetMCPath()) );
	gfxShellButtonMP = gfxFinalShell.GetObject("theShellMenu").GetObject("option1");
	class'UIModUtils'.static.AS_OverrideClickButtonDelegate(gfxShellButtonMP, ShowModsMenu); //makes clicking on Multiplayer button call "function ShowModsMenu"
	m_kBackgroundScreen = kShell;
	SetupButtonHelper();
	m_bShellButtonAdded=true;
}
function AddPauseMenuButton()
{
	local GfxObject gfxPauseMenu, gfxNewButton;
	local UIPauseMenu kPauseMenu;
	local int iCount;
	local Mutator mut;
	
	iCount=-1;
	mut = class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator;
	while(mut != none)
	{
		iCount++;
		mut = mut.NextMutator;
	}
	kPauseMenu = PRES().m_kPauseMenu;
	gfxPauseMenu = PRES().GetHUD().GetVariableObject( string(kPauseMenu.GetMCPath()) );
	m_iMutatorListButtonID = kPauseMenu.MAX_OPTIONS;
	kPauseMenu.AS_AddOption(kPauseMenu.MAX_OPTIONS++, "Active Mutators ("$iCount$")", 0);
	gfxNewButton = gfxPauseMenu.GetObject("listMC").GetObject("itemRoot").GetObject(string(m_iMutatorListButtonID));
	class'UIModUtils'.static.AS_OverrideClickButtonDelegate(gfxNewButton, ShowMutatorsList);
	if(m_kBackgroundScreen != kPauseMenu)
	{
		m_kBackgroundScreen = kPauseMenu;
		SetupButtonHelper();
	}
	m_bPauseButtonAdded=true;
}
function ShowModsMenu()
{	
	m_kBackgroundScreen.OnLoseFocus(); //hide the screen on top of which the mods menu is shown (either shell or difficulty screen)
	ToggleSimpleProgressDialog(true);//showing dialog manually cause UIProgressDialog would mess the screens' stack
	m_kButtonHelper.GoToState('CachingDataForModMgr');//somehow XComMod does NOT work with states, must be an actor, hence the helper
}
function ToggleSimpleProgressDialog(bool bVisible)
{
	local ASDisplayInfo tDisplay;

	if(bVisible)
	{
		PRES().GetHUD().DialogBox.AS_SetStyleNormal();
		PRES().GetHUD().DialogBox.AS_SetHelp(0,"","");
		PRES().GetHUD().DialogBox.AS_SetHelp(1,"","");
		PRES().GetHUD().DialogBox.AS_SetTitle("");
		PRES().GetHUD().DialogBox.AS_SetText("<font size='24'>\n\n          "$class'UIModShell'.default.m_strBuildingOptionsProgress$"</font>");
		tDisplay = PRES().GetHUD().GetVariableObject(string(PRES().GetHUD().DialogBox.GetMCPath())).GetDisplayInfo();
		tDisplay.XScale=200.0;
		tDisplay.YScale=200.0;
		tDisplay.X -= PRES().GetHUD().m_v2ScaledDimension.X / 2.0;
		tDisplay.Y -= PRES().GetHUD().m_v2ScaledDimension.Y / 2.0;
		PRES().GetHUD().GetVariableObject(string(PRES().GetHUD().DialogBox.GetMCPath())).SetDisplayInfo(tDisplay);
		PRES().GetHUD().DialogBox.m_arrData.Add(1);
		PRES().GetHUD().DialogBox.Show();
	}
	else
	{
		PRES().GetHUD().DialogBox.m_arrData.Length=0;
		tDisplay = PRES().GetHUD().GetVariableObject(string(PRES().GetHUD().DialogBox.GetMCPath())).GetDisplayInfo();
		tDisplay.X += PRES().GetHUD().m_v2ScaledDimension.X / 2.0;
		tDisplay.Y += PRES().GetHUD().m_v2ScaledDimension.Y / 2.0;
		tDisplay.XScale=100.0;
		tDisplay.YScale=100.0;
		PRES().GetHUD().GetVariableObject(string(PRES().GetHUD().DialogBox.GetMCPath())).SetDisplayInfo(tDisplay);
		PRES().GetHUD().DialogBox.Hide();
	}
}
function ShowModList()
{
	EnsureModShell(); //spawn m_kModShell screen (if missing)
	//m_kBackgroundScreen.OnLoseFocus(); //hide the screen on top of which the mods menu is shown (either shell or difficulty screen)
	m_kModShell.Show(); //show the screen
}
function EnsureModShell()
{
	if(m_kModShell == none)
	{
		m_kModShell = PRES().Spawn(class'UIModShell');
		m_kModShell.Init(XComPlayerController(XComGameInfo(Outer).GetALocalPlayerController()), PRES().GetHUD());
	}
}
function ShowModToggles()
{
	if(m_kModToggles != none)
	{
		PRES().PlaySound(SoundCue(DynamicLoadObject("SoundUI.MenuSelectCue", class'SoundCue', true)));
		m_kModToggles.OnReceiveFocus();
	}
	else
	{
		EnsureModShell();
		m_kModToggles = m_kModShell.Spawn(class'UIModToggles', m_kModShell);
		m_kModToggles.m_kModMgr = self;
		m_kModToggles.Init(m_kModShell.controllerRef, m_kModShell.manager);
	}
}
function ShowMutatorsList()
{
	local TDialogueBoxData tData;
	local Mutator mut;
	local XComMod mod;
	local string strRecord;
	local Guid tGuid;

	mut = class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator;
	while(mut != none)
	{
		strRecord = mut.GetDebugName();
		if(strRecord == string(mut))
		{
			tGuid = mut.GetPackageGuid(mut.Class.GetPackageName());
			strRecord @= "<font size='14'>(GUID "$ Locs(ToHex(tGuid.A)$"-"$ToHex(tGuid.B)$"-"$ToHex(tGuid.C)$"-"$ToHex(tGuid.D)) $")</font>";
		}
		tData.strText $= "\n" $ strRecord;
		mut = mut.NextMutator;
	}
	if(XComGameInfo(class'Engine'.static.GetCurrentWorldInfo().Game).Mods.Length > 0)
	{
		tData.strText $= "\n\nMODS:\n";
	}
	foreach XComGameInfo(class'Engine'.static.GetCurrentWorldInfo().Game).Mods(mod)
	{
		tGuid = class'Actor'.static.GetPackageGuid(mod.Class.GetPackageName());
		strRecord = string(mod) @ "<font size='14'>(GUID "$ Locs(ToHex(tGuid.A)$"-"$ToHex(tGuid.B)$"-"$ToHex(tGuid.C)$"-"$ToHex(tGuid.D)) $")</font>";
		tData.strText $= "\n" $ strRecord;
	}
	tData.strTitle = "LIST OF ACTIVE MUTATORS";
	tData.strCancel = class'UIUtilities'.default.m_strGenericBack;
	tData.strAccept = m_strModsMenuButton;
	tData.fnCallback = OnCloseMutatorListCallback;
	PRES().UIRaiseDialog(tData);
}
function OnCloseMutatorListCallback(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		ShowModsMenu();
	}
}
function UpdateMasterClassPaths()
{
	local int I;
	local array<string> arrTacMutators, arrStratMutators, arrTempPaths;
	local string strSetting;

	m_arrMasterClassPaths.Length = 0;
	arrTacMutators = SplitString(class'XComModsProfile'.static.ReadSetting("arrTacticalMutators", "XComMutatorLoader"), ",");
	arrStratMutators = SplitString(class'XComModsProfile'.static.ReadSetting("arrStrategicMutators", "XComMutatorLoader"), ",");

	//ensure SightlinesMenu updater
	if(arrTacMutators.Find("Sightlines_UI.SightlinesMenu") < 0)
	{
		arrTacMutators.AddItem("Sightlines_UI.SightlinesMenu");
	}
	//add paths from possibly new entries in DefaultMutatorLoader.ini
	for(I = 0; I < class'XComMutatorLoader'.default.arrStrategicMutators.Length; ++I)
	{
		if(arrStratMutators.Find(class'XComMutatorLoader'.default.arrStrategicMutators[I]) < 0)
		{
			arrStratMutators.AddItem(class'XComMutatorLoader'.default.arrStrategicMutators[I]);
		}	
	}
	for(I = 0; I < class'XComMutatorLoader'.default.arrTacticalMutators.Length; ++I)
	{
		if(arrTacMutators.Find(class'XComMutatorLoader'.default.arrTacticalMutators[I]) < 0)
		{
			arrTacMutators.AddItem(class'XComMutatorLoader'.default.arrTacticalMutators[I]);
		}
	}
	//cache all paths ever registered in XComModsProfile.ini
	for(I = 0; I < class'XComModsProfile'.default.ModSettings.Length; ++I)
	{
		if(class'XComModsProfile'.default.ModSettings[I].ModName ~= "UIModManager" && class'XComModsProfile'.default.ModSettings[I].Value ~= "ClassPath" && class'XComModsProfile'.default.ModSettings[I].ValueType == eVType_String)
		{
			arrTempPaths.AddItem(class'XComModsProfile'.default.ModSettings[I].PropertyName);
		}
	}
	//add paths from updated arrStratMutators and arrTacMutators
	for(I = 0; I < arrStratMutators.Length; I++)
	{
		arrTempPaths.AddItem(arrStratMutators[I]);
	}
	for(I = 0; I < arrTacMutators.Length; I++)
	{
		arrTempPaths.AddItem(arrTacMutators[I]);
	}	
	//add paths from DefaultGame.ini
	for(I = 0; I < class'XComGameInfo'.default.ModNames.Length; ++I)
	{
		arrTempPaths.AddItem(class'XComGameInfo'.default.ModNames[I]);
	}
	//add paths from DefaultModBridge.ini
	for(I = 0; I < class'ModBridge'.default.ModList.Length; ++I)
	{
		arrTempPaths.AddItem(class'ModBridge'.default.ModList[I]);
	}

	//deduplicate arrTempPaths and cache in m_arrMasterClassPaths
	for(I = 0; I < arrTempPaths.Length; ++I)
	{
		if(arrTempPaths[I] != "" && m_arrMasterClassPaths.Find(arrTempPaths[I]) < 0)
		{
			m_arrMasterClassPaths.AddItem(arrTempPaths[I]);
		}
	}
	//finally update XComModsProfile.ini with the updated list of classes
	for(I = 0; I < m_arrMasterClassPaths.Length; ++I)
	{
		class'XComModsProfile'.static.SaveSetting("UIModManager", m_arrMasterClassPaths[I], "ClassPath", eVType_String);
	}

	JoinArray(arrTacMutators, strSetting, ",", true);
	class'XComModsProfile'.static.SaveSetting("XComMutatorLoader", "arrTacticalMutators", strSetting, eVType_String);
	
	JoinArray(arrStratMutators, strSetting, ",", true);
	class'XComModsProfile'.static.SaveSetting("XComMutatorLoader", "arrStrategicMutators", strSetting, eVType_String);
}

function LoadMutators(bool bLoadStrategic, bool bLoadTactical)
{
	local string MutatorName;
	local class MutatorClass;
	local Mutator kM;
	local array<string> arrMutators;

	if(bLoadTactical)
	{
		arrMutators = SplitString(class'XComModsProfile'.static.ReadSetting("arrTacticalMutators", "XComMutatorLoader"), ",");
		foreach arrMutators(MutatorName)
		{
			MutatorClass = class<Mutator>(DynamicLoadObject(MutatorName, class'Class', true));
			if(MutatorClass != none)
			{
				XComGameInfo(Outer).AddMutator(MutatorName, false);
			}
		}
	}
	if(bLoadStrategic)
	{
		arrMutators = SplitString(class'XComModsProfile'.static.ReadSetting("arrStrategicMutators", "XComMutatorLoader"), ",");
		foreach arrMutators(MutatorName)
		{
			MutatorClass = class<Mutator>(DynamicLoadObject(MutatorName, class'Class', true));
			if(MutatorClass != none)
			{
				XComGameInfo(Outer).AddMutator(MutatorName, false);
			}
		}
	}
	
	kM = XComGameInfo(Outer).BaseMutator.NextMutator;
	PRES().ConsoleCommand("suppress Warning");
	while(kM != none)
	{
		if(!kM.IsInState('UpdatingOptions'))
		{
			kM.PushState('UpdatingOptions');
		}
		if(!kM.bUserAdded)
		{
			kM.SetTickIsDisabled(true);
		}
		kM = kM.NextMutator;
	}
	PRES().ConsoleCommand("unsuppress Warning");
	`MutateFromHere;
}
function CleanUpMutators()
{
	local array<Mutator> arrAllMutators;
	local Mutator kM;

	kM = XComGameInfo(Outer).BaseMutator.NextMutator;
	while(kM != none)
	{
		arrAllMutators.AddItem(kM);
		kM = kM.NextMutator;
	}
	foreach arrAllMutators(kM)
	{	
		if(kM.IsInState('UpdatingOptions'))
		{
			kM.PopState();
		}
		if(!kM.bUserAdded)
		{
			XComGameInfo(Outer).RemoveMutator(kM);
		}
	}
}
function OnCleanUp(bool bUpdateOptions)
{
	if(bUpdateOptions || m_bModsNeedUpdate)
	{
		OnUpdateOptions();
	}
	CleanUpMutators();
	KillModContainers();
}
function OnUpdateOptions()
{
	`MutateFromHere;
	CallUpdateDelegates();
	UpdateMutatorLists();
	m_bModsNeedUpdate = false;
}
function CacheUIModData()
{
	local UIModOptionsContainer kModContainer;
	local int i;

	UpdateMasterClassPaths();
	LoadMutators(true, true);
	CallStartUpDelegates();
	/*FIXME*/
	//...some sort of call to ModBridge should be here - when (if) AzXeus finishes the job
	class'Engine'.static.GetCurrentWorldInfo().Spawn(class'UIModSharedContainer');
	m_arrUIModData.Length = 0;
	foreach XComGameInfo(Outer).DynamicActors(class'UIModOptionsContainer', kModContainer)
	{
		if(kModContainer.m_strMasterClass != "XComModShell.UIModManager" && m_arrMasterClassPaths.Find(kModContainer.m_strMasterClass) < 0)
		{
			m_arrMasterClassPaths.AddItem(kModContainer.m_strMasterClass);
			class'XComModsProfile'.static.SaveSetting("UIModManager", kModContainer.m_strMasterClass, "ClassPath", eVType_String);
		}
		for(i=0; i < kModContainer.m_arrModsData.Length; ++i)
		{
			m_arrUIModData.AddItem(kModContainer.m_arrModsData[i]);
			if(kModContainer.m_arrModsData[i].arrRequiredClassPaths.Length > 0 && kModContainer.m_arrModsData[i].arrRequiredClassPaths[0] != "" && m_arrMasterClassPaths.Find(kModContainer.m_arrModsData[i].arrRequiredClassPaths[0]) < 0)
			{
				m_arrMasterClassPaths.AddItem(kModContainer.m_arrModsData[i].arrRequiredClassPaths[0]);
				class'XComModsProfile'.static.SaveSetting("UIModManager", kModContainer.m_arrModsData[i].arrRequiredClassPaths[0], "ClassPath", eVType_String);
			}
		}
	}
}
function KillModContainers()
{
	local UIModOptionsContainer kModContainer;

	foreach XComGameInfo(Outer).DynamicActors(class'UIModOptionsContainer', kModContainer)
	{
		kModContainer.Destroy();
	}
	m_kLWContainer = none;
	m_kOptionsContainer = none;
}
/** Updates XComModsProfile.ini entries considering current content of m_arrMasterClassPaths*/
function UpdatePackages()
{
	local array<string> arrPackageNames;
	local string strPackage;

	GetAllPackageNames(arrPackageNames);
	foreach arrPackageNames(strPackage)
	{
		if(!IsPackageAvailable(strPackage))
		{
			class'XComModsProfile'.static.SaveSetting("UIModManager", strPackage, "false", eVType_Bool);
		}
	}
}
/** Caches data for main Mods Menu (list of mods).*/
function UpdateModMenuOptions()
{
	local TModUIData tModData;
	local TMenuOption tOption;
	local string strTestClass, strTestPackage;
	local XGParamTag kTag;
	
	m_arrModMenuOptions.Length = 0;
	m_arrEnabledModNames.Length = 0;
	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
	foreach m_arrUIModData(tModData)
	{
		if(tModData.ModName ~= "UIModManager")
		{
			continue;
		}
		if(class'XComModsProfile'.static.ReadSettingBool("bModEnabled", tModData.ModName))
		{
			m_arrEnabledModNames.AddItem(tModData.ModName);
		}
		tOption.strText = tModData.ModName;
		tOption.iState = 1;
		tOption.strHelp = (tModData.strDescription != "" ? tModData.strDescription : m_strNoDescription);
		foreach tModData.arrRequiredClassPaths(strTestClass)
		{
			strTestPackage = Left(strTestClass, InStr(strTestClass, "."));
			if(DynamicLoadObject(strTestClass, class'Class', true) != none)
			{
				if(!class'XComModsProfile'.static.ReadSettingBool(strTestPackage, "UIModManager"))
				{
					tOption.iState = 0;
					kTag.StrValue0 = strTestPackage;
					tOption.strHelp = class'XComLocalizer'.static.ExpandString(m_strDisabledPackage) $"\n\n"$ tOption.strHelp;
					break;
				}
			}
			else 
			{
				//the required class did not get loaded so the package is probably missing
				tOption.iState = -1;
				kTag.StrValue0 = strTestPackage $ ".u";
				tOption.strHelp = class'XComLocalizer'.static.ExpandString(m_strMissingPackage) $"\n\n"$ tOption.strHelp;
				break;
			}
		}
		//add option to the list
		m_arrModMenuOptions.AddItem(tOption);
	}
}
/** Converts m_arrMasterClassPaths and all arrRequiredClassPaths to an out array of PackageNames*/
function GetAllPackageNames(out array<string> arrPackageNames)
{
	local int I;
	local string strPackageName, strClass;
	local array<string> arrAllClassPaths;

	//cache all possible classes ever registered
	arrAllClassPaths = m_arrMasterClassPaths;
	for(I = 0; I < m_arrUIModData.Length; ++I)
	{
		foreach m_arrUIModData[I].arrRequiredClassPaths(strClass)
		{
			if(arrAllClassPaths.Find(strClass) < 0)
			{
				arrAllClassPaths.AddItem(strClass);
			}
		}
	}
	arrPackageNames.Length = 0;
	//strip class paths to package names
	for(I = 0; I < arrAllClassPaths.Length; ++I)
	{
		strPackageName = arrAllClassPaths[I];
		while(InStr(strPackageName, ".", true) > 0)
		{
			strPackageName = Left(strPackageName, InStr(strPackageName, ".", true));
		}
		if(arrPackageNames.Find(strPackageName) < 0)
		{
			arrPackageNames.AddItem(strPackageName);
		}
	}
}
/** Caches data for Mod Packages menu*/
function UpdatePackageMenuOptions()
{
	local TModUIData tModData;
	local TMenuOption tOption;
	local string strMasterClass, strPackage;
	local XGParamTag kTag;
	local array<string> arrAllPackages;
	local bool bFound;

	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
	m_arrPackageMenuOptions.Length = 0;
	GetAllPackageNames(arrAllPackages);
	foreach arrAllPackages(strPackage)
	{
		if(strPackage == "")
		{
			continue;
		}
		tOption.strText = strPackage;
		if(IsPackageAvailable(strPackage))
		{
			bFound = false;
			tOption.iState = 1;
			tOption.strHelp = m_strModsInPackage;
			//loop over all UIModData in search for MasterClass matching strPackage 
			//if match found add UIModData.ModName to the list of enabled mods
			foreach m_arrUIModData(tModData)
			{
				if(tModData.arrRequiredClassPaths.Length > 0)
				{
					strMasterClass = tModData.arrRequiredClassPaths[0];
				}
				else
				{
					strMasterClass = "";
				}
				if(strPackage ~= Left(strMasterClass, InStr(strMasterClass, ".")))
				{
					tOption.strHelp @= (tModData.strDisplayName != "" ? tModData.strDisplayName : tModData.ModName);
					tOption.strHelp $= ",";
					bFound = true;
				}			
			}
			//loop done -> cut off the last comma and add dot
			if(bFound)
			{
				tOption.strHelp = Left(tOption.strHelp, Len(tOption.strHelp) - 1) $ ".";
			}
			else
			{
				tOption.strHelp = m_strNoDescription;
			}
		}
		else
		{
			tOption.iState = 0;
			kTag.StrValue0 = strPackage $ ".u";
			tOption.strHelp = class'UIUtilities'.static.GetHTMLColoredText(class'XComLocalizer'.static.ExpandString(m_strMissingPackage), 3);
		}
		//saving initial setting - crucial for newly added packages and for the very 1st launch of Mod Manager
		bFound = !class'XComModsProfile'.static.HasSetting(tOption.strText, "UIModManager") || class'XComModsProfile'.static.ReadSettingBool(tOption.strText, "UIModManager");
		class'XComModsProfile'.static.SaveSetting("UIModManager", tOption.strText, (tOption.iState == 1 && bFound) ? "true" : "false", eVType_Bool);
		m_arrPackageMenuOptions.AddItem(tOption);
	}
}
/** Tries to load any class from the package using m_arrMasterClassPaths and arrRequiredClassPaths. If success - returns true.*/
function bool IsPackageAvailable(string strPackageName)
{
	local array<string> arrTestClassNames;
	local string strClass;
	local TModUIData tMod;
	local bool bFound, bAvailable;
	
	//start with master classes then add any other arrRequiredClassPaths (this is to handle .ini added mods)
	arrTestClassNames = m_arrMasterClassPaths;
	foreach m_arrUIModData(tMod)
	{
		foreach tMod.arrRequiredClassPaths(strClass)
		{
			if(arrTestClassNames.Find(strClass) < 0)
			{
				arrTestClassNames.AddItem(strClass);
			}
		}
	}
	foreach arrTestClassNames(strClass)
	{
		if(Left(strClass, InStr(strClass, ".")) ~= strPackageName)
		{
			bFound = true;
			bAvailable = DynamicLoadObject(strClass, class'Class', true) != none;
			if(bAvailable)
			{
				break;
			}
		}
	}
	//LogInternal("Testing" @ strPackageName @ "bFound="$(bFound ? "true" : "false") @ "bAvailable="$(bAvailable ? "true" : "false"), 'UIModManager');
	return (bFound && bAvailable);
}
/** Reads the setting from XComModsProfile.ini*/
function bool IsPackageEnabled(string strPackageName)
{
	return class'XComModsProfile'.static.ReadSettingBool(strPackageName, "UIModManager");
}
function UpdateMutatorLists()
{
	local int iEntry;
	local string strClassPath, strPackage;
	local array<string> arrTacMutators, arrStratMutators, arrDependentMods, arrEnabled, arrAvailable, arrDisposable;
	local TModUIData tModData;
	local bool bRemove, bAdd;
	local XComMutatorLoader kMutatorLoader;

	kMutatorLoader = XComMutatorLoader(GetMutator("XComMutator.XComMutatorLoader"));

	//these 2 helper arrays store paths ever recorded as tactical or strategic mutators 
	//(so that we know to which array a path should be re-added)
	arrTacMutators = SplitString(class'XComModsProfile'.static.ReadSetting("arrTacticalMutators", "XComMutatorLoader"), ",");
	arrStratMutators = SplitString(class'XComModsProfile'.static.ReadSetting("arrStrategicMutators", "XComMutatorLoader"), ",");

	foreach arrTacMutators(strClassPath)
	{
		strPackage = Left(strClassPath, InStr(strClassPath, "."));
		if(IsPackageEnabled(strPackage) && arrEnabled.Find(strClassPath) < 0)
		{
			arrEnabled.AddItem(strClassPath);
		}
		if(IsPackageAvailable(strPackage) && arrAvailable.Find(strClassPath) < 0)
		{
			arrAvailable.AddItem(strClassPath);
		}
		if(IsPathDisposable(strClassPath) && arrDisposable.Find(strClassPath) < 0)
		{
			arrDisposable.AddItem(strClassPath);
		}
	}
	foreach arrStratMutators(strClassPath)
	{
		strPackage = Left(strClassPath, InStr(strClassPath, "."));
		if(IsPackageEnabled(strPackage) && arrEnabled.Find(strClassPath) < 0)
		{
			arrEnabled.AddItem(strClassPath);
		}
		if(IsPackageAvailable(strPackage) && arrAvailable.Find(strClassPath) < 0)
		{
			arrAvailable.AddItem(strClassPath);
		}
		if(IsPathDisposable(strClassPath) && arrDisposable.Find(strClassPath) < 0)
		{
			arrDisposable.AddItem(strClassPath);
		}
	}	//remove (from XComMutatorLoader arrays) the paths that have no dependent ModName enabled or have their package disabled
	for(iEntry = kMutatorLoader.arrTacticalMutators.Length - 1; iEntry >=0; --iEntry)
	{
		strClassPath = kMutatorLoader.arrTacticalMutators[iEntry];
		bRemove = arrEnabled.Find(strClassPath) < 0 || arrDisposable.Find(strClassPath) >= 0;
		if(bRemove)
		{
			kMutatorLoader.arrTacticalMutators.Remove(iEntry, 1);
		}
	}
	for(iEntry = kMutatorLoader.arrStrategicMutators.Length - 1; iEntry >=0; --iEntry)
	{
		strClassPath = kMutatorLoader.arrStrategicMutators[iEntry];
		bRemove = arrEnabled.Find(strClassPath) < 0 || arrDisposable.Find(strClassPath) != -1;
		if(bRemove)
		{
			kMutatorLoader.arrStrategicMutators.Remove(iEntry, 1);
		}
	}
	//add mutators required by enabled ModNames but missing in XComMutatorLoader arrays
	for(iEntry=0; iEntry < m_arrEnabledModNames.Length; ++iEntry)
	{
		tModData = GetUIDataForMod(m_arrEnabledModNames[iEntry]);
		foreach tModData.arrRequiredClassPaths(strClassPath)
		{
			if(arrEnabled.Find(strClassPath) >= 0 && arrAvailable.Find(strClassPath) >= 0 && arrTacMutators.Find(strClassPath) >= 0 && kMutatorLoader.arrTacticalMutators.Find(strClassPath) < 0)
			{
				kMutatorLoader.arrTacticalMutators.AddItem(strClassPath);
			}
			if(arrEnabled.Find(strClassPath) >=0 && arrAvailable.Find(strClassPath) >=0 && arrStratMutators.Find(strClassPath) >= 0 && kMutatorLoader.arrStrategicMutators.Find(strClassPath) < 0)
			{
				kMutatorLoader.arrStrategicMutators.AddItem(strClassPath);
			}
		}
	}
	//add re-enabled "non-talking" tactical mutators
	for(iEntry=0; iEntry < arrTacMutators.Length; ++iEntry)
	{
		strClassPath = arrTacMutators[iEntry];
		arrDependentMods = GetDependentModNames(strClassPath);
		bAdd = arrDependentMods.Length == 0 && arrAvailable.Find(strClassPath) >= 0 && arrEnabled.Find(strClassPath) >= 0;
		if(bAdd && kMutatorLoader.arrTacticalMutators.Find(strClassPath) < 0)
		{
			kMutatorLoader.arrTacticalMutators.AddItem(strClassPath);
		}
	}
	//add re-enabled "non-talking" strategic mutators
	for(iEntry=0; iEntry < arrStratMutators.Length; ++iEntry)
	{
		strClassPath = arrStratMutators[iEntry];
		arrDependentMods = GetDependentModNames(strClassPath);
		bAdd = arrDependentMods.Length == 0 && arrAvailable.Find(strClassPath) >= 0 && arrEnabled.Find(strClassPath) >= 0;
		if(bAdd && kMutatorLoader.arrStrategicMutators.Find(strClassPath) < 0)
		{
			kMutatorLoader.arrStrategicMutators.AddItem(strClassPath);
		}
	}
	kMutatorLoader.SaveConfig();
}
function array<string> GetDependentModNames(string strClassPath)
{
	local TModUIData tData;
	local array<string> arrModNames;

	foreach m_arrUIModData(tData)
	{
		if(tData.arrRequiredClassPaths.Find(strClassPath) != -1)
		{
			arrModNames.AddItem(tData.ModName);
		}
	}
	return arrModNames;
}
function bool IsPathDisposable(string strClassPath)
{
	local array<string> arrModNames;
	local string strModName;
	local bool bFound;

	arrModNames = GetDependentModNames(strClassPath);
	if(arrModNames.Length > 0)
	{
		foreach arrModNames(strModName)
		{
			bFound = IsModEnabled(strModName);
			if(bFound)
			{
				break;
			}
		}
	}
//	LogInternal(GetFuncName() @ strClassPath @ "?:" @ (!bFound && arrModNames.Length > 0) $ ". HasAnyDependentMods:"@ (arrModNames.Length > 0) $". HasAnyEnabledMods:" @ bFound);
	return !bFound && arrModNames.Length > 0;
}
/** Returns a cached TModUIData struct for the matching strModName*/
function TModUIData GetUIDataForMod(string strModName)
{
	local int iFound;

	iFound = m_arrUIModData.Find('ModName', strModName);
	return m_arrUIModData[iFound];
}
/** Returns filtered arrModOptions for the mod from the cached UIModData
 *  @param strModName String matching some existing .ModName property.
 *  @param strIdxPrefix A filter applied to .Index property to sort out only the matching suboptions.
 *  @param bSort Defaults to FALSE. Forces return of sorted array.
 *  @param bIncludeSuboptions Defaults to FALSE. When set to TRUE includes suboptions with the provided strIdxPrefix.
 */
function array<TModOption> GetConfigOptionsForMod(string strModName, optional string strIdxPrefix, optional bool bSort, optional bool bIncludeSuboptions)
{
	local array<TModOption> arrOptions;

	arrOptions = GetUIDataForMod(strModName).arrModOptions;
	FilterOptionsByIndexPrefix(arrOptions, strIdxPrefix, bIncludeSuboptions);
	if(bSort)
	{
		SortOptionsByIndex(arrOptions);
	}
	return arrOptions;
}
function FilterOptionsByIndexPrefix(out array<TModOption> arrOutOptions, string strIdxPrefix, optional bool bWithSuboptions)
{
	local string sIndex, sRemainder;
	local int i, iPrefixLength;
	local bool bRemove, bPrefixMatch, bDepthMatch;

	iPrefixLength = Len(strIdxPrefix);
	for(i = arrOutOptions.Length - 1; i >= 0; --i) //iteration from the end of array allows safe removal of iterated elements
	{
		sIndex = arrOutOptions[i].Index;
		bPrefixMatch = false;
		bDepthMatch = false;
		bRemove = false;
		if(strIdxPrefix == "")//no prefix so it's for main options, not for sub-options
		{
			bPrefixMatch = true;
			bDepthMatch = InStr(sIndex, ".") < 0; //a dot in Index would indicate a sub-option
		}
		else
		{
			bPrefixMatch = (Left(sIndex, iPrefixLength + 1) == (strIdxPrefix $ ".") );
			if(bPrefixMatch)
			{
				sRemainder = Right(sIndex, Len(sIndex) - iPrefixLength - 1);
				bDepthMatch = InStr(sRemainder, ".") < 0; //again, more dots would indicate a lower level sub-option
			}
		}
		if(bWithSuboptions)
		{
			bDepthMatch = true;
		}
		bRemove = !bPrefixMatch || !bDepthMatch;
		if(bRemove)
		{
			arrOutOptions.Remove(i, 1); //remove current option if not matching
		}
	}
}
function SortOptionsByIndex(out array<TModOption> arrOutOptions)
{
	local int iOption, iCount;
	local bool bInsert;
	local array<TModOption> arrSorted, arrNotSorted;
	local TModOption tO;

	foreach arrOutOptions(tO, iCount)
	{
		bInsert = false;
		if(tO.Index != "") //if Index is provided...
		{
			for(iOption = 0; iOption < arrSorted.Length; ++iOption)
			{
				if(arrSorted[iOption].Index > tO.Index) //this is string-to-string comparison, so alphabetical rules apply
				{
					bInsert = true;
					break;
				}
			}
			if(bInsert)
			{
				arrSorted.InsertItem(iOption, tO);
			}
			else
			{
				arrSorted.AddItem(tO);
			}
		}
		else //if index had not been provided
		{
			arrNotSorted.AddItem(tO); //skip sorting and postpone
		}
	}
	foreach arrNotSorted(tO) 
	{
		arrSorted.AddItem(tO); //add all postponed, not sorted items
	}
	arrOutOptions = arrSorted;
}
/** Reads strDescription for the mod from cached UIModData.*/
function string GetDescriptionForMod(string strModName)
{
	local string strDesc;

	strDesc = GetUIDataForMod(strModName).strDescription;
	if(strDesc == "")
	{
		strDesc = m_strNoDescription;
	}
	return strDesc;
}
/** Reads strDisplayName for the mod from cached UIModData.*/
function string GetDisplayNameForMod(string strModName)
{
	local string strName;

	strName = GetUIDataForMod(strModName).strDisplayName;
	if(strName == "")
	{
		strName = strModName;
	}
	return strName;
}
/** Checks if a mod in "Select Mods" menu can be toggled-in*/
function bool IsModAvailable(string strModName)
{
	local TMenuOption tOption;
	local bool bFound;

	foreach m_arrModMenuOptions(tOption)
	{
		if(CAPS(tOption.strText) == CAPS(strModName))
		{
			bFound = true;
			break;
		}
	}
	return (bFound && tOption.iState > 0);
}
function bool IsModEnabled(string strModName)
{
	return m_arrEnabledModNames.Find(strModName) != -1;
}
static function UIModManager GetModMgr()
{
	local array<XComMod> arrMods;
	local XComMod kMod;

	arrMods = XComGameInfo(class'Engine'.static.GetCurrentWorldInfo().Game).Mods;
	foreach arrMods(kMod)
	{
		if(kMod.IsA('UIModManager'))
		{
			break;
		}
	}
	if(UIModManager(kMod) == none)
	{
		ScriptTrace();
		return none;
	}
	return UIModManager(kMod);
}

/** Registers a callback function that will be called by ModManager when ModsMenu is closed.*/
static function RegisterUpdateCallback(delegate<OnUpdateOptionsCallback> fnCallbackFunction)
{
	if(GetModMgr().m_arrCallbackDelegates.Find(fnCallbackFunction) < 0)
	{
		GetModMgr().m_arrCallbackDelegates.AddItem(fnCallbackFunction);
	}
}
/** Registers a callback function that will be called by ModManager when ModsMenu is opened.*/
static function RegisterStartUpCallback(delegate<OnUpdateOptionsCallback> fnCallbackFunction)
{
	if(GetModMgr().m_arrStartUpDelegates.Find(fnCallbackFunction) < 0)
	{
		GetModMgr().m_arrStartUpDelegates.AddItem(fnCallbackFunction);
	}
}
/** Registers a callback function that will be called by ModManager when a widget in ModsMenu is initialized*/
static function RegisterInitWidgetCallback(delegate<OnInitWidgetDataCallback> fnCallbackFunction)
{
	if(GetModMgr().m_arrInitWidgetDelegates.Find(fnCallbackFunction) < 0)
	{
		GetModMgr().m_arrInitWidgetDelegates.AddItem(fnCallbackFunction);
	}
}

function CallUpdateDelegates()
{
	foreach m_arrCallbackDelegates(__OnUpdateOptionsCallback__Delegate)
	{
		OnUpdateOptionsCallback();
	}
}
function CallStartUpDelegates()
{
	foreach m_arrStartUpDelegates(__OnUpdateOptionsCallback__Delegate)
	{
		OnUpdateOptionsCallback();
	}
}
function CallInitWidgetDelegates(out UIWidget kWidget, out TModOption tOption)
{
	foreach m_arrInitWidgetDelegates(__OnInitWidgetDataCallback__Delegate)
	{
		OnInitWidgetDataCallback(kWidget, tOption);
	}
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
function AS_OverrideClickButtonDelegate(GfxObject kButton, delegate<OnUpdateOptionsCallback> fnCallback)
{
	PRES().GetHUD().ActionScriptSetFunction(kButton, "release");
}
function SetupShellButtons()
{
	local ASValue myValue;
	local array<ASValue> myArray;
	local int iCurrentSel;
	local UIFinalShell kShell;

	kShell = XComShellPresentationLayer(PRES()).m_kFinalShellScreen;
	if(kShell == none)
	{
		return;
	}
	myValue.Type = AS_String;
	iCurrentSel = 0;

	myValue.S = kShell.m_sSinglePlayer;
	myArray.AddItem(myValue);
	kShell.m_iSP = iCurrentSel ++;

	myValue.S = m_strModsMenuButton; //replace Multiplayer button with ModsMenu button
	myArray.AddItem(myValue);

	myValue.S = kShell.m_sLoad;
	myArray.AddItem(myValue);
	kShell.m_iLoad = ++ iCurrentSel;

	myValue.S = kShell.m_sOptions;
	myArray.AddItem(myValue);
	kShell.m_iOptions = ++ iCurrentSel;

	myValue.S = kShell.m_sMultiplayer;
	myArray.AddItem(myValue);
	kShell.m_iMP = ++ iCurrentSel;
	if(!PRES().WorldInfo.IsConsoleBuild(0))
	{
		myValue.S = kShell.m_sExitToDesktop;
		myArray.AddItem(myValue);
		kShell.m_iExit = ++ iCurrentSel;
	}
	kShell.m_iMaxSelection = myArray.Length;
	kShell.Invoke("SetDisplay", myArray);
}
function UpdateGameCoreSettings()
{
	local int i;
	local TModSetting tSetting;

	for(i=0; i < class'XComModsProfile'.default.ModSettings.Length; ++i)
	{
		tSetting = class'XComModsProfile'.default.ModSettings[i];
		if(InStr(tSetting.PropertyPath, "XGTacticalGameCore.",,true) != -1)
		{
			tSetting.PropertyPath = Repl(tSetting.PropertyPath, "XGTacticalGameCore.", "XGTacticalGameCoreNativeBase.");
			class'UIModOptionsContainer'.static.ConsoleSetSetting(tSetting.PropertyPath, tSetting.Value);
		}
	}
}
static function bool IsLongWarBuild()
{
	return class'XComPerkManager'.default.SoldierPerkTrees.Length > 5;
}
//to do: saving defaults
function bool IsModProfileData(UIMPLoadout_Squad tData)
{
	return class'GameInfo'.static.ParseOption(tData.strLoadoutName, "ModProfileName") != "";
}
/**Returns the first unoccupied .iLoadoutID in m_aMPLoadoutSquadRemote*/
function int GetNextLowestModID()
{
	local UIMPLoadout_Squad tProfileInfo;
	local XComOnlineProfileSettingsDataBlob kData;
	local array<int> arrOccupied;
	local int iFreeID;

	kData = XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data;
	foreach kData.m_aMPLoadoutSquadDataRemote(tProfileInfo)
	{
		if(IsModProfileData(tProfileInfo))
		{
			arrOccupied.AddItem(tProfileInfo.iLoadoutId);
		}
	}
	iFreeID = -1;
	do
	{
		iFreeID++;
	}
	until(arrOccupied.Find(iFreeID) < 0);
	
	return iFreeID;
}
/**Retruns the frist found m_aMPLoadoutSquadDataRemote entry which holds mod profile data.*/
function int GetFirstAvailableModID()
{
	local UIMPLoadout_Squad tProfileInfo;
	local XComOnlineProfileSettingsDataBlob kData;

	kData = XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data;
	foreach kData.m_aMPLoadoutSquadDataRemote(tProfileInfo)
	{
		if(IsModProfileData(tProfileInfo))
		{
			return tProfileInfo.iLoadoutId;
		}
	}	
	return -1;
}
/** Iterates over m_aMPLoadoutSquadDataRemote in search for ModProfile entries and returns their count. 
	Optionally puts all the found entries in <out> array.
	@param arrAllProfileIndexes Placeholder for all the indexes of the found IDs in m_aMPLoadoutSquadDataRemote. WARNING: the provided array is cleared before getting filled.*/
function int GetNumModProfiles(optional out array<int> arrAllProfileIndexes)
{
	local UIMPLoadout_Squad tProfileInfo;
	local XComOnlineProfileSettingsDataBlob kData;
	local int idx;

	arrAllProfileIndexes.Length = 0;
	kData = XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data;
	foreach kData.m_aMPLoadoutSquadDataRemote(tProfileInfo, idx)
	{
		if(IsModProfileData(tProfileInfo))
		{
			arrAllProfileIndexes.AddItem(idx);
		}
	}	
	return arrAllProfileIndexes.Length;
}
/** Updates the value of m_iModProfileID and m_iModProfileArrayIdx. If the param is missing reads the value from user profile.
	@param iNewProfileID Provide the new ID (should match .iLoadoutID value in some m_aMPLoadoutSquadDataRemote struct). Defaults to user profile stat "UIModManager.CurrentProfileID".*/
function UpdateCurrentModProfile(optional int iNewProfileID=-1)
{
	local UIMPLoadout_Squad tProfileInfo;
	local XComOnlineProfileSettingsDataBlob kData;
	local bool bFound;
	local int idx;

	if(iNewProfileID != -1)
	{
		m_iModProfileID = iNewProfileID;
	}
	else
	{
		m_iModProfileID = class'XComModsProfile'.static.GetProfileSetting("UIModManager.CurrentProfileID");
	}
	class'XComModsProfile'.static.SetProfileSetting("UIModManager.CurrentProfileID", m_iModProfileID);
	kData = XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data;
	foreach kData.m_aMPLoadoutSquadDataRemote(tProfileInfo, idx)
	{
		if(IsModProfileData(tProfileInfo) && tProfileInfo.iLoadoutId == m_iModProfileID)
		{
			bFound = true;
			break;
		}
	}
	if(bFound)
	{
		m_iModProfileArrayIdx = idx;
	}
	else
	{
		AddModProfile("", true);
	}
}
/**Adds entry to m_aMPLoadoutSquadRemote caching it with basic mod-profile data.*/
function AddModProfile(string strProfileName, optional bool bSetAsCurrent)
{
	local UIMPLoadout_Squad tProfileInfo;
	local XComOnlineProfileSettingsDataBlob kData;
	local int iNewID;

	iNewID = GetNextLowestModID();
	if(strProfileName == "")
	{
		strProfileName = m_sModProfilePrefix @ iNewID;
	}
	kData = XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data;
	tProfileInfo.iLoadoutId = iNewID;
	//strLoadoutName will follow the pattern: ?ModProfileName=[strProfileName]?ModProfileDesc="Some Description To Be Added Later"
	tProfileInfo.strLoadoutName = "?ModProfileName="$strProfileName $"?ModProfileDesc="$m_strNoDescription;
	tProfileInfo.strLanguageCreatedWith="";
	kData.m_aMPLoadoutSquadDataRemote.AddItem(tProfileInfo);
	if(bSetAsCurrent)
	{
		m_iModProfileID = iNewID;
		m_iModProfileArrayIdx = kData.m_aMPLoadoutSquadDataRemote.Length - 1;
	}
}
/**Deletes entry for the current mod profile from m_aMPLoadoutSquadDataRemote array - ensures clearing the m_aProfileStats to avoid bloating of the profile.*/
function bool DeleteCurrentModProfile()
{
	local string strProperty;
	local array<string> arrProfileSettingNames;
	local XComOnlineProfileSettingsDataBlob kData;
	local bool bSuccess;

	if(GetNumModProfiles() == 1)
	{	
		bSuccess = false;
	}
	else
	{
		kData = XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data;
		ParseStringIntoArray(kData.m_aMPLoadoutSquadDataRemote[m_iModProfileArrayIdx].strLanguageCreatedWith, arrProfileSettingNames,",",true);
		foreach arrProfileSettingNames(strProperty)
		{
			class'XComModsProfile'.static.ClearProfileSetting("profile" $m_iModProfileID $"." $ strProperty);
		}
		kData.m_aMPLoadoutSquadDataRemote.Remove(m_iModProfileArrayIdx, 1);
		UpdateCurrentModProfile(GetFirstAvailableModID());	
		XComOnlineEventMgr(GameEngine(Class'Engine'.static.GetEngine()).OnlineEventManager).SaveProfileSettings(true);
		bSuccess = true;
	}
	return bSuccess;
}
/**Retrieves "profileN.ModName.PropertyName" for the provided TModSetting - to be used for SetProfileStat or GetProfileStat.*/
function string GetProfileStatName(TModSetting tSetting, optional bool bSkipPrefix)
{
	local string sProfileStatName;

	sProfileStatName = tSetting.PropertyPath;
	if(tSetting.PropertyPath == "")
	{
		sProfileStatName = tSetting.PropertyName;
		if(Left(sProfileStatName, Len(tSetting.ModName)) != tSetting.ModName)
		{
			sProfileStatName = tSetting.ModName $"."$ sProfileStatName;
		}
	}
	if(!bSkipPrefix)
	{
		sProfileStatName = "profile" $m_iModProfileID $"." $sProfileStatName;
	}
	return sProfileStatName;
}
/**Caches the provided tSetting with the data from current mod profile.*/
function UpdateSettingFromProfile(out TModSetting tSetting)
{
	local string sProfileStatName;
	local int iProfileValue;

	sProfileStatName = GetProfileStatName(tSetting);
	if(class'XComModsProfile'.static.HasProfileSetting(sProfileStatName, iProfileValue))
	{
		switch(tSetting.ValueType)
		{
		case eVType_String:
		case eVType_Undefined:
			class'XComModsProfile'.static.ClearProfileSetting(sProfileStatName);
			`log(sProfileStatName @ "not updated due to incompatible ValueType="$tSetting.ValueType$". Setting removed from profile.",,GetFuncName());
			break;
		case eVType_Bool:
			tSetting.Value = iProfileValue == 0 ? "false" : "true";
			break;
		case eVType_Float:
			tSetting.Value = Left(string(float(iProfileValue) / 100.0), InStr(string(float(iProfileValue)), ".") + 3);
			break;
		default:
			tSetting.Value = string(iProfileValue);
		}
	}
}
/**Caches the user profile with the data for the provided tSetting.*/
function bool SaveSettingToProfile(TModSetting tSetting)
{
	local int iProfileValue;
	local bool bSuccess;
	local string sProfileStatName;

	sProfileStatName = GetProfileStatName(tSetting);
	if(tSetting.ValueType == eVType_String || tSetting.ValueType == eVType_Undefined)
	{
		`log(sProfileStatName @ "not saved due to incompatible ValueType="$tSetting.ValueType,,GetFuncName());
		bSuccess = false;
	}
	else
	{
		switch(tSetting.ValueType)
		{
			case eVType_Bool:
				iProfileValue = tSetting.Value ~= "true" ? 1 : 0;
				break;
			case eVType_Float:
				iProfileValue = int(float(tSetting.Value) * 100.0);
				break;
			default:
				iProfileValue = int(tSetting.Value);
		}
		class'XComModsProfile'.static.SetProfileSetting(sProfileStatName, iProfileValue);
		bSuccess = true;
	}
	return bSuccess;
}
/**Saves the whole mods profile data to user profile.*/
function SaveModProfile()
{
	local TModSetting tSetting;
	local string strName, strAllNames;
	local array<string> arrProfileSettingNames;

	foreach class'XComModsProfile'.default.ModSettings(tSetting)
	{
		strName = GetProfileStatName(tSetting, true);
		if(SaveSettingToProfile(tSetting))
		{
			arrProfileSettingNames.AddItem(strName);
		}
	}
	JoinArray(arrProfileSettingNames, strAllNames,,true);
	XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_aMPLoadoutSquadDataRemote[m_iModProfileArrayIdx].strLanguageCreatedWith = strAllNames;
	XComOnlineEventMgr(GameEngine(Class'Engine'.static.GetEngine()).OnlineEventManager).SaveProfileSettings(true);
}
/**Updates the mod with provided ModName with the date cached in user profile.*/
function UpdateModFromProfile(string strModName)
{
	local TModSetting tS;
	local int idx;

	foreach class'XComModsProfile'.default.ModSettings(tS, idx)
	{
		if(tS.ModName ~= strModName)
		{
			UpdateSettingFromProfile(tS);
			class'XComModsProfile'.default.ModSettings[idx] = tS;
		}
	}
}
function UpdateAllModsFromProfile()
{
	local TModSetting tS;
	local int idx;

	foreach class'XComModsProfile'.default.ModSettings(tS, idx)
	{
		UpdateSettingFromProfile(tS);
		class'XComModsProfile'.default.ModSettings[idx] = tS;
	}
}
DefaultProperties
{
	BuildVersion="1.4.1"
	m_iAdvOptionsWatchVar=-1
}