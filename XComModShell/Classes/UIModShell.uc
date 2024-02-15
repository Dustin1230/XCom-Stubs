/** This is the main UI class of Mod Manager. 
   It handles display of the in-game menu and its navigation. */

class UIModShell extends UI_FxsScreen
    notplaceable
    config(ModsProfile);

var bool m_bDebugLog;

var bool m_bAnyChangesMade;

/** Stores reference to the main mod manager object.*/
var UIModManager m_kModMgr;

var array<int> m_arrTabsOrder;

/** Indicates which top-screen button has been clicked. Controls content of the list*/
var int m_iCurrentTab;

/** Helper variable for iterating in state's code*/
var int m_iCurrentWidget;

/** Helper variable to restore focus on parent option while navigating through nested options.*/
var int m_iRestoreSelection;

/** ModName of currently selected mod - determines the list of options in mod's configuration menu.*/
var string m_strSelectedMod;

/** Stores name of selected mod during configuration of Mod Manager*/
var string m_strSelectedModBackup;

/** Set by code - a helper indicating the lenght of the list (of options, or of mods).*/
var int m_iNumListOptions;

/** Holds helpers for widgets' management. Only the one with index 2 is actually used.*/
var array<UIWidgetHelper> m_arrWidgetHelpers;

/** A helper for pushing data to Flash widgets and handling input events.*/
var UIWidgetHelper m_kWidgetHelper;

var UIModMenuDepthHelper m_kDepthHelper;

/** Used to store settings when entering the menu.*/
var array<TModSetting> m_CachedSettings;

/** Holds options of currently selected mod for quick access.*/
var array<TModOption> m_arrCurrentModOptions;

/** Stores reference to the list's movie clip.*/
var UIModGfxOptionsList m_gfxModList;

var GFxObject m_gfxProgressBox;

/** Helper array required for delayed UI update with multiple comboboxes*/
var array<UIWidget_Combobox> m_arrAllComboboxes;

/** When this is set to 'true' the screen ignores OnMouseEvent and OnUnrealCommand*/
var bool m_bWaitingForUI;

/** This is set 'true' when switching between tabs and is set back to 'false' when new widgets get refreshed*/
var bool m_bNewWidgetsPending;

/** Alters response to controller keys. When set to true - Up/Down scroll description text. Otherwise scroll widgets.*/
var bool m_bControllerFocusOnDescField;

/** The current title of the menu window - indicates currently configured mod/option.*/
var string m_strCurrentTitleLabel;

var array<int> m_arrModProfileIndexes;

/** The main title label used for "Mod Manager"*/
var localized string m_strTitle;

/** Name of the button for selecting mods.*/
var localized string m_strSelectModsButton;
var localized string m_strBackToModsButton;

/** Name of the button for showing mod's options.*/
var localized string m_strConfigureModsButton;

/** Name of the button for showing mod manager's options.*/
var localized string m_strConfigureModMgrButton;

/** Name of the button for reset all defaults.*/
var localized string m_strResetAllButton;

/** Name of the button for reset current mod's defaults.*/
var localized string m_strResetModButton;

/** Question about what to reset: list of mods or all mods' options.*/
var localized string m_strRestoreDefaultsDialog;
var localized string m_strRestoreDefaultsModOptions;
var localized string m_strRestoreDefaultsModList;

/** Warning about resetting the list of mods.*/
var localized string m_strResetModListWarning;

/** Name of the button for showing list of packages.*/
var localized string m_strSelectPackagesButton;

/** Label for disabled "config" button.*/
var localized string m_strNoOptions;

/** Tag attached to gamepad help icon.*/
var localized string m_strGamepadScrollHelp;

/** Tag attached to gamepad help icon.*/
var localized string m_strGamepadBackToListHelp;

var localized string m_strResetDefaults;
var localized string m_strResetAllDefaults;
var localized string m_strSettingsChanged;
var localized string m_strDontShowAnymore;
var localized string m_strBuildingOptionsProgress;
var localized string m_strProfilesButton;
var localized string m_strEmptyProfile;
var localized string m_strEmptyProfileWarning;
var localized string m_strNewProfileTitle;
var localized string m_strNewProfileButton;
var localized string m_strLoadProfileTitle;
var localized string m_strLoadProfileButton;
var localized string m_strLoadProfileDialog;
var localized string m_strEditProfileTitle;
var localized string m_strEditProfileButton;
var localized string m_strEditProfileNameButton;
var localized string m_strEditProfileDescButton;
var localized string m_strEditProfileDialog;
var localized string m_strSaveProfileTitle;
var localized string m_strSaveProfileButton;
var localized string m_strSaveProfileDialog;
var localized string m_strSaveProfileConfirmOverwrite;
var localized string m_strDeleteProfileButton;
var localized string m_strDeleteProfileTitle;
var localized string m_strDeleteProfileDialog;
var localized string m_strDeleteProfileFailedTitle;
var localized string m_strDeleteProfileFailed;
var config bool m_bShowResetWarning;
var config bool m_bShowExitWarning;
var config bool m_bShowChangesWarning;
var config bool m_bSortMods_ByAlphabet;
var config bool m_bSortMods_SelectedFirst;
var config bool m_bEnsurePerformance;

/** A helper to store custom progress dialog for the Mods Menu*/
var UIProgressDialogue m_kProgressDialog;

/** This delegate will replace functionality of "SetSelected" function in WidgetHelper flash class */
delegate SetSelectedWidget(int iNewItemIndex)
{
	WidgetHelperGfx(2).SetFloat("iSelected", float(iNewItemIndex));//probably irrelevant Firaxis' artifact from flash-debug mode
	if(m_iCurrentTab == 2) //tab 2 points to "Select mods"
	{
		m_strSelectedMod = GetModMgr().m_arrModMenuOptions[iNewItemIndex].strText;
		if(GetModMgr().m_arrModMenuOptions[iNewItemIndex].iState > 0)
		{
			AS_SetDescTextColorNormal();
		}
		else
		{
			AS_SetDescTextColorBad();
		}
		AS_SetDescription(GetModMgr().GetDescriptionForMod(m_strSelectedMod));
	}
	GetModList().AS_SetFocus(string(iNewItemIndex));
}
function Init(XComPlayerController _controllerRef, UIFxsMovie _manager)
{
	local XComMod kMod;

    BaseInit(_controllerRef, _manager);
	foreach XComGameInfo(WorldInfo.Game).Mods(kMod)
	{
		if(UIModManager(kMod) != none)
		{
			m_kModMgr = UIModManager(kMod);
			break;
		}
	}
	e_InputState = class'UIOptionsPCScreen'.default.e_InputState;
	manager.LoadScreen(self);
	`Log("No UIModManager object found!!!", m_bDebugLog && m_kModMgr == none, name);
}
/** This function is automatically called by ActionScript after LoadScreen(...) call*/
simulated function OnInit()
{ 
    super.OnInit();
	SelfGfx().SetVisible(false);
	UpdateModManagerSettings();
	CacheExistingSettings();
	m_arrWidgetHelpers.Add(3);
	m_arrWidgetHelpers[2] = Spawn(class'UIModWidgetHelper', self);//it's 2 because tab2 is the left most tab
	m_kWidgetHelper = m_arrWidgetHelpers[2];
	m_kDepthHelper = new (self) class'UIModMenuDepthHelper';
	SetSelectedDelegate(WidgetHelperGfx(2), SetSelectedWidget);
	AttachModList();
	GetModList().AS_SetVersionTxt(default.m_strTitle @ "v." $ class'UIModManager'.default.BuildVersion);
	AttachAdditionalMasterButton();
	SetupTitleField();
	SortMods(GetModMgr().m_arrModMenuOptions);
	m_strSelectedMod = GetModMgr().m_arrModMenuOptions[0].strText;
	if(controllerRef.m_Pres.m_kDifficulty != none)
	{
		controllerRef.m_Pres.m_kDifficulty.Hide();
	}
	if(controllerRef.m_Pres.m_kPCOptions != none)
	{
		controllerRef.m_Pres.m_kPCOptions.Hide();
	}
	SetSelectedTab(2);
	AS_SelectTab(2);
	UpdatePanelFocusFX();
	if(!manager.IsMouseActive())
	{
		FixButtonsLayout();
	}
	SetTimer(0.50, false, 'OnInitialized');
}
function OnInitialized()
{
	GetModMgr().ToggleSimpleProgressDialog(false);
	SelfGfx().SetVisible(true);
	//a little trick here, I hope no player ever reaches Game 1618 for their 
	if(!XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data.IfGameStatsSubmitted(1618, true))
	{
		m_strSelectedMod = "UIModManager";
		ShowCredits();
		m_strSelectedMod = GetModMgr().m_arrModMenuOptions[0].strText;
		XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data.GameStatsSubmitted(1618, true);
		XComOnlineEventMgr(GameEngine(class'Engine'.static.GetEngine()).OnlineEventManager).SaveProfileSettings();
	}
}
function UpdateModManagerSettings()
{
	local array<TModSetting> arrSettings;

	arrSettings = class'XComModsProfile'.static.ReadModSettings("UIModManager");
	m_bShowChangesWarning = class'XComModsProfile'.static.ReadSettingBool("m_bShowChangesWarning", "UIModManager", arrSettings);
	m_bShowExitWarning = class'XComModsProfile'.static.ReadSettingBool("m_bShowExitWarning", "UIModManager", arrSettings);
	m_bShowResetWarning = class'XComModsProfile'.static.ReadSettingBool("m_bShowResetWarning", "UIModManager", arrSettings);
	m_bSortMods_ByAlphabet = class'XComModsProfile'.static.ReadSettingBool("m_bSortMods_ByAlphabet", "UIModManager", arrSettings);
	m_bSortMods_SelectedFirst = class'XComModsProfile'.static.ReadSettingBool("m_bSortMods_SelectedFirst", "UIModManager", arrSettings);
	m_bEnsurePerformance = class'XComModsProfile'.static.ReadSettingBool("m_bEnsurePerformance", "UIModManager", arrSettings);
}
/** This event is called when the screen is purged*/
event Destroyed()
{
	super.Destroyed();
	if(GetModMgr().m_kBackgroundScreen != none)
	{
		GetModMgr().m_kBackgroundScreen.OnReceiveFocus();
	}
	m_kDepthHelper = none;
	m_kModMgr = none;
}
function UIModManager GetModMgr()
{
	return m_kModMgr;
}
function UIModGfxOptionsList GetModList()
{
	return m_gfxModList;
}

/** Ensures text-highlight of current option and fixes minor gfx issues related to comboboxes, sliders and spinners*/
function FixWidgetFocusFX()
{
	local GfxObject gfxCurrentWidget;
	local int iCurrentWidget;
	local UIWidgetHelper kWidgetHelper;

	kWidgetHelper = m_kWidgetHelper;
	iCurrentWidget = kWidgetHelper.m_iCurrentWidget;
	gfxCurrentWidget = GetModList().AS_GetItemAt(iCurrentWidget);
	if(GetModList().IsCombobox(gfxCurrentWidget))
	{
		AS_BringComboboxToTop(gfxCurrentWidget);
		CloseAllComboboxesExcept(UIWidget_Combobox(kWidgetHelper.m_arrWidgets[iCurrentWidget]), kWidgetHelper);
	}
	else if(GetModList().IsSlider(gfxCurrentWidget))
	{
		UpdateSliderLabel(iCurrentWidget);
	}
	GetModList().SetFocusFX(gfxCurrentWidget, true);
	if(GetModList().IsSpinner(gfxCurrentWidget))
	{
		OnSpinnerNewValue();
	}
}

/** Toggles helper-FX for gamepad users*/
function ToggleControllerFocus()
{
	m_bControllerFocusOnDescField = !m_bControllerFocusOnDescField;
	UpdatePanelFocusFX();
}

/** Sets a special FX for gamepad users - lighter-shaded background of currently navigated panel: description box or list box*/
function UpdatePanelFocusFX()
{
	if(!manager.IsMouseActive())
	{
		if(m_bControllerFocusOnDescField)
		{
			class'UIModUtils'.static.ObjectAddColor( GetModList().GetObject("listbox"), 0, 0, 0);
			class'UIModUtils'.static.ObjectAddColor( GetModList().GetObject("descBG"), 40, 40, 40);
		}
		else
		{
			class'UIModUtils'.static.ObjectAddColor( GetModList().GetObject("listbox"), 40, 40, 40);
			class'UIModUtils'.static.ObjectAddColor( GetModList().GetObject("descBG"), 0, 0, 0);
		}
		GetModList().UpdatePanelFocusHelp(m_bControllerFocusOnDescField);
	}
}
/** A helper to scroll (up) large description text*/
function OnUDPadUp()
{
	local float fScroll;

	if(m_bControllerFocusOnDescField || manager.IsMouseActive())
	{
		fScroll = float(AS_GetDescTextScroll());
		AS_SetDescTextScroll(fScroll - 1.0);
	}
}
/** A helper to scroll (down) large description text*/
function OnUDPadDown()
{
	local float fScroll;

	if(m_bControllerFocusOnDescField || manager.IsMouseActive())
	{
		fScroll = float(AS_GetDescTextScroll());
		AS_SetDescTextScroll(fScroll + 1.0);
	}
}
function OnTabRight()
{
	m_kWidgetHelper.CloseAllComboboxes();
	if(m_iCurrentTab == 2 && !SelectedModHasOptions())
	{
		PlayBadSound();
		AlterTabSelection(2);
	}
	else
	{
		AlterTabSelection(1);
	}
	SetSelectedTab(m_iCurrentTab);
}
function OnTabLeft()
{
	m_kWidgetHelper.CloseAllComboboxes();
	if(m_iCurrentTab == 4 && !SelectedModHasOptions())
	{
		PlayBadSound();
		AlterTabSelection(-2);
	}
	else
	{
		AlterTabSelection(-1);
	}
	SetSelectedTab(m_iCurrentTab);
}
function AlterTabSelection(int iDirectionCount)
{
	local int iSelection;

	iSelection = m_arrTabsOrder.Find(m_iCurrentTab);
	iSelection += iDirectionCount;
	if(iSelection < 0)
	{
		iSelection = 4;
	}
	else if(iSelection > m_arrTabsOrder.Length - 1)
	{
		iSelection = 0;
	}
	m_iCurrentTab = m_arrTabsOrder[iSelection];
}
/** Updates highlighting of a given list-item (and updates text in the description-box) based on the selection*/
function UpdateSelection(int iOption, optional int iHelper=-1)
{
	if(m_iCurrentTab == 2)
	{
		m_strSelectedMod = GetModMgr().m_arrModMenuOptions[iOption].strText;
		AS_SetDescription(GetModMgr().m_arrModMenuOptions[iOption].strHelp);
		UpdateButtonTabState(false);
	}
	else if(m_iCurrentTab == 0)
	{
		m_kWidgetHelper.SetSelected(iOption);
		UpdateProfileSelection();
		if(GetProfileSettings().Data.m_aMPLoadoutSquadDataRemote[m_arrModProfileIndexes[iOption]].strLanguageCreatedWith == "")
		{
			AS_SetDescription(m_strEmptyProfile$"\n\n"$ GetModProfileDesc());
		}
		else
		{
			AS_SetDescription(GetModProfileDesc());
		}
	}
	else if(m_arrCurrentModOptions.Length > 0)
	{
		if(!m_arrCurrentModOptions[iOption].bReadOnly)
		{   
			AS_SetDescription("<font color='#ffff00'>"$Localize("UIControllerMap", "m_sDefaults", "XComGame")$": </font><font color='#ffffff'>"$m_arrCurrentModOptions[iOption].strDefault$"</font>\n\n"$ m_arrCurrentModOptions[iOption].VarDescription);
		}
		else
		{
			AS_SetDescription(m_arrCurrentModOptions[iOption].VarDescription);
		}
	}
	if(!UIModWidgetHelper(m_kWidgetHelper).m_bFocusOnConfigButton)
	{
		GetModList().del_SetFocus(string(iOption)); //handles highligting
	}
	if(iHelper != -1)
	{
		m_arrWidgetHelpers[iHelper].m_iCurrentWidget = iOption; //update selection for gamepad/keyboard
	}
}
function RefreshHelp()
{
	if(m_iCurrentTab == 0)
	{
		AS_SetHelp(0, m_strNewProfileButton, class'UI_FxsGamepadIcons'.static.GetBackButtonIcon());
		AS_SetHelp(1, m_strEditProfileButton, "Icon_LT_L2");
		AS_SetHelp(2, m_strLoadProfileButton, "Icon_Y_TRIANGLE");
		AS_SetHelp(3, m_strSaveProfileButton, "Icon_X_SQUARE");
		if(!manager.IsMouseActive())
		{
			AS_SetHelp(4, m_strDeleteProfileButton, "Icon_BACK_SELECT");
			GetModList().UpdatePanelFocusHelp(m_bControllerFocusOnDescField);
		}
		else
		{
			AS_SetHelp(4, m_strDeleteProfileButton, "");
		}
	}
	else
	{
		AS_SetHelp(0, class'UINavigationHelp'.default.m_strBackButtonLabel, class'UI_FxsGamepadIcons'.static.GetBackButtonIcon());
		AS_SetHelp(1, m_strSelectPackagesButton, "Icon_LT_L2");
		AS_SetHelp(2, m_iCurrentTab == 2 ? m_strResetAllButton : m_strResetModButton, "Icon_Y_TRIANGLE");
		AS_SetHelp(3, class'UIOptionsPCScreen'.default.m_strExitAndSaveSettings, "Icon_X_SQUARE");
		if(!manager.IsMouseActive())
		{
			AS_SetHelp(4, class'UIOptionsPCScreen'.default.m_strCreditsLink, "Icon_BACK_SELECT");
			GetModList().UpdatePanelFocusHelp(m_bControllerFocusOnDescField);
		}
		else
		{
			AS_SetHelp(4, class'UIOptionsPCScreen'.default.m_strCreditsLink, "");
		}
	}
}
//This function handles key presses. 
//Function CheckInputIsReleaseOrDirectionRepeat blocks all non-controller and non-arrow/space/enter keys. 
//Plus it only passes "release key" events (skips mouseOver, press etc.) - coded in ActionMask
simulated function bool OnUnrealCommand(int Cmd, int Actionmask)
{
	if(!IsInited() || m_bWaitingForUI || IsInState('RemovingWidgets') || IsInState('RefreshingWidgets')  || IsInState('RefreshingModsMenu'))
	{
		return true;
	}
	if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Actionmask))
	{
		if( !(Cmd == 571 && Actionmask == 32) || Cmd == 400 || Cmd == 421 ) //let Tab key press sneak through (for tests), stop 421 (mouse scroll) and 400 (mouseLeftDelayedUp)
		{
			return true;
		}
	}
	if(m_iCurrentTab == 2 && GetModMgr().m_arrModMenuOptions[m_kWidgetHelper.GetCurrentSelection()].iState <= 0)
	{
		if(Cmd == 300 || Cmd == 511)
		{
			PlayBadSound();
			return true;
		}
	}
	if(!m_bControllerFocusOnDescField && m_kWidgetHelper.OnUnrealCommand(Cmd, Actionmask))
	{
		FixWidgetFocusFX();
		UpdateSelection(m_kWidgetHelper.GetCurrentSelection());
		return true;
	}
	switch(Cmd)
	{
	case 300:
	case 511:
	case 513:
		if(UIModWidgetHelper(m_kWidgetHelper).m_bFocusOnConfigButton)
		{
			ShowSubOptions();
		}
		break;
	case 571://TAB key
		OnTabRight();		
		break;
	case 301:
	case 510:
	case 405:
		OnBackButtonClick();
		break;
	case 303:
		if(m_iCurrentTab == 0)
		{
			LoadModProfileRequested();
		}
		else
		{
			DialogResetDefaults(m_iCurrentTab == 2);
		}
		break;
	case 302:
		if(m_iCurrentTab == 0)
		{
			SaveModProfileRequested();
		}
		else
		{
			DialogSettingsChanged();
		}
		break;
	case 350:
	case 500:
	case 370:
		OnUDPadUp();
		break;
	case 354:
	case 502:
	case 371:
		OnUDPadDown();
		break;
	case 320:
		if(m_iCurrentTab == 0)
		{
			DeleteModProfileDialog();
		}
		else
		{
			ShowCredits();
		}
		break;
	case 330:
		OnTabLeft();
		break;
	case 331:
		OnTabRight();
		break;
	case 332:
		if(m_iCurrentTab == 0)
		{
			EditModProfileDialog();
		}
		else
		{
			GetModMgr().ShowModToggles();
		}
		break;
	case 333:
		ToggleControllerFocus();
		break;
	default:
		break;
	}
	return true;
}
simulated function bool OnMouseEvent(int Cmd, array<string> args)
{
	local bool bHandled;
	local int iTargetOption, iTargetBox;
	local string strArgs;

	bHandled = (m_bWaitingForUI || IsInState('RemovingWidgets') || IsInState('RefreshingWidgets')  || IsInState('RefreshingModsMenu'));
	if(!bHandled)
	{
		switch(Cmd)
		{
		case 391:
			JoinArray(args, strArgs);
			//`Log(GetFuncName() @ strArgs, m_bDebugLog, name);
			if(InStr(args[args.Length - 1], "button",,true) > -1 && OnMasterButtonClicked(args[args.Length - 1]))
			{
				break;
			}
			else if(InStr(args[args.Length - 1], "descBG") > -1) 
			{
				//click on description (descBG) should be ignored
				break;
			}
			else
			{
				if(InStr(args[args.Length - 1], "textDownArrow",true,true) > -1)
				{
					OnUDPadDown();
					break;
				}
				else if(InStr(args[args.Length - 1], "textUpArrow",true,true) > -1)
				{
					OnUDPadUp();
					break;
				}
				if(InStr(args[args.Length - 1], "listbox",true,true) > -1) //click on the list outside any widget
				{
					iTargetOption = GetModList().GetItemIDFromMouse();
					UpdateSelection(iTargetOption, 2);
					CloseAllComboboxesExcept(none, m_kWidgetHelper);
					break;
				}
				iTargetOption = int(args[7]); //click on widget
				UpdateSelection(iTargetOption);
				if(args.Length == 8)
				{
					iTargetBox = -1;
				}
				else if(args[8] == "theButton") //only a Combobox could have passed "theButton"
				{
					if(args.Length > 9) //there's another arg after "theButton" so this is the index of item in dropdown list
					{
						iTargetBox = int(args[args.Length - 1]);
					}
					else //this is a click on combo button itself, not on one of items
					{
						iTargetBox = -1; 
						if(HandledComboButtonClick(2, iTargetOption))
						{
							break;
						}	
					}
				}
				else if(args[8] == "configButton") //this is checkbox with "settings/suboptions" button
				{
					//CloseAllComboboxesExcept(none, m_kWidgetHelper); 
					break;//only this, the click itself is handled by OnClick delegate
				}
				else
				{
					//this is for spinner/slider; the last arg is -1 or -2 for left/right arrow OR 1-100 number for slider indicating currentPercent drag
					iTargetBox = int(args[args.Length - 1]);
				}
			}
			CloseAllComboboxesExcept(none, m_kWidgetHelper); //this is a click on non-combo widget, so close all combos and process
			if(m_iCurrentTab == 2 && GetModMgr().m_arrModMenuOptions[iTargetOption].iState <= 0) //this is a click on non-combo widget, so close all combos and process
			{
				PlayBadSound();
				bHandled = false;
			}
			else
			{
				if(GetModList().IsSlider(GetModList().AS_GetItemAt(iTargetOption)))
				{
					ProcessSliderMouseEvent(iTargetOption, iTargetBox);
				}
				else
				{
					m_kWidgetHelper.ProcessMouseEvent(iTargetOption, iTargetBox);
			}	}
			break;
		default:
			bHandled = false;
		}
	}
	return bHandled;
}
function bool OnMasterButtonClicked(string strButtonName)
{
	local bool bHandled;

	bHandled = true;
	if(strButtonName == "centerButton1")
	{
		if(m_iCurrentTab == 0)
		{
			EditModProfileDialog();
		}
		else
		{
			GetModMgr().ShowModToggles();
		}
	}
	else if(strButtonName == "centerButton2")
	{
		if(m_iCurrentTab == 0)
		{
			LoadModProfileRequested();
		}
		else
		{
			DialogResetDefaults(m_iCurrentTab == 2);
		}
	}
	else if(strButtonName == "centerButton3")
	{
		if(m_iCurrentTab == 0)
		{
			DeleteModProfileDialog();
		}
		else
		{
			ShowCredits();
		}
	}	
	else if(strButtonName == "theStartButton")
	{
		if(m_iCurrentTab == 0)
		{
			SaveModProfileRequested();
		}
		else
		{
			DialogSettingsChanged();
		}
	}
	else if(strButtonName == "theBackButton")
	{
		OnBackButtonClick();
	}
	else if(InStr(strButtonName, "buttonTab") > -1)
	{
		SetSelectedTab(int(Split(strButtonName, "buttonTab", true)));
	}
	else
	{
		bHandled = false;
	}
	return bHandled;
}
/** This function handles opening/closing of a combobox. */
function bool HandledComboButtonClick(int iHelper, int iWidget)
{
    local UIWidget_Combobox kCombobox;
	local UIWidgetHelper kHelper;
	local bool bHandled;

	kHelper = m_arrWidgetHelpers[iHelper];
	kCombobox = UIWidget_Combobox(kHelper.m_arrWidgets[iWidget]);
	bHandled = true;
	if(kCombobox == none)
	{
		bHandled = false;
	}
	else if(m_iCurrentTab == 2 && GetModMgr().m_arrModMenuOptions[iWidget].iState <= 0)
	{
		//this is "Select Mods" menu and the combobox is disabled
		PlayBadSound();
	}
	else
	{
		//so this is an enabled combobox - let's start with closing other combos first
		CloseAllComboboxesExcept(kCombobox, kHelper);	
	
		//ensure that the dropdown list is visually on top of other widgets
		AS_BringComboboxToTop(GetModList().AS_GetItemAt(iWidget));

		kHelper.m_iCurrentWidget = iWidget;
		if(!kCombobox.m_bComboBoxHasFocus)
		{
			//if the click was on the button (not the label) open the combobox
			if(GetModList().AS_GetItemAt(iWidget).GetFloat("_xmouse") > -30.0)
			{
				kHelper.OpenCombobox(iWidget);
				PlaySelectSound();
			}
		}
		else
		{
			//otherwise  (click was on a dropdown item) update the value 
			kCombobox.iCurrentSelection = kCombobox.iBoxSelection;
			kHelper.SetComboboxValue(iWidget, kCombobox.iCurrentSelection);
			kHelper.CloseCombobox(iWidget);
			PlayCancelSound();
		}
	}
	return bHandled;
}
/** Makes all comboboxes be closed except the one specified as parameter.
 *  @param kFocusBox This combobox will not be force-closed.
 *  @param kHelper Specify widget helper which holds the comboboxes to be closed.
 */
function CloseAllComboboxesExcept(optional UIWidget_Combobox kFocusBox=none, optional UIWidgetHelper kHelper=m_kWidgetHelper)
{
	local UIWidget_Combobox kBox;
	local UIWidget kWidget;
	local int i;

	foreach kHelper.m_arrWidgets(kWidget, i)
	{
		kBox = UIWidget_Combobox(kWidget);
		if(kBox != none && kBox != kFocusBox && kBox.m_bComboBoxHasFocus)
		{
			kHelper.CloseCombobox(i);
		}
	}
}
function ProcessSliderMouseEvent(int iWidgetIndex, int iValue)
{
	if(m_iCurrentTab != 2)
	{
		if(iValue >=0 ) //this is dragging the thumb (iValue represents CurrentPercentDrag)
		{
			while(iValue > 0 && m_arrCurrentModOptions[iWidgetIndex].arrListValues.Find(iValue) < 0)
			{
				--iValue;
			}
		}
	}
	m_kWidgetHelper.ProcessMouseEvent(iWidgetIndex, iValue);
	GetModList().SetFocusFX(GetModList().AS_GetItemAt(iWidgetIndex),true);
	GetModList().FixWidgetLabelFontSize(GetModList().AS_GetItemAt(iWidgetIndex));
	UpdateSliderLabel(iWidgetIndex);
	m_bAnyChangesMade = true;
}
function OnSliderIncreaseValue()
{
	local UIWidget_Slider kSlider;
	local array<int> arrValues;
	
	kSlider = UIWidget_Slider(m_kWidgetHelper.m_arrWidgets[m_kWidgetHelper.GetCurrentSelection()]);
	arrValues = m_arrCurrentModOptions[m_kWidgetHelper.GetCurrentSelection()].arrListValues;
	if(kSlider.iValue < 100)
	{
		do{	kSlider.iValue ++; }
		until(arrValues.Find(kSlider.iValue) != -1 || kSlider.iValue == 100);
	}
	kSlider.iValue -= kSlider.iStepSize;
	m_bAnyChangesMade = true;
}
function OnSliderDecreaseValue()
{
	local UIWidget_Slider kSlider;
	local array<int> arrValues;

	kSlider = UIWidget_Slider(m_kWidgetHelper.m_arrWidgets[m_kWidgetHelper.GetCurrentSelection()]);
	arrValues = m_arrCurrentModOptions[m_kWidgetHelper.GetCurrentSelection()].arrListValues;
	if(kSlider.iValue > 0)
	{
		do{	kSlider.iValue --;  } 
		until(arrValues.Find(kSlider.iValue) != -1 || kSlider.iValue == 0);
	}
	kSlider.iValue += kSlider.iStepSize;
	m_bAnyChangesMade = true;
}
function OnSpinnerNewValue()
{
	local GfxObject kSpinner;

	kSpinner = GetModList().AS_GetItemAt(m_kWidgetHelper.GetCurrentSelection());
	GetModList().FixSpinnerValueFontSize(kSpinner);
	GetModList().FixWidgetLabelFontSize(kSpinner);
	m_bAnyChangesMade = true;
}
function OnWidgetValueChanged()
{
	m_bAnyChangesMade=true;
}
function ShowCredits()
{
	local UIModCredits kCredits;
	local TModUIData tModData;
	local array<TModSetting> arrTempSettings;

	kCredits = controllerRef.m_Pres.Spawn(class'UIModCredits', self);
	tModData = GetModMgr().GetUIDataForMod(m_strSelectedMod);
	if(tModData.arrCredtis.Length > 0)
	{
		kCredits.m_arrModCredits = tModData.arrCredtis;
	}
	else
	{
		kCredits.m_arrModCredits.AddItem("\n");
		kCredits.m_arrModCredits.AddItem("<h1>AUTHOR</h1>");
		kCredits.m_arrModCredits.AddItem("\n");
		kCredits.m_arrModCredits.AddItem(class'UIModManager'.default.m_strNoDescription);
		kCredits.m_arrModCredits.AddItem("\n");
	}
	if(!class'XComModsProfile'.static.ReadSettingBool("CreditsShown", m_strSelectedMod))
	{
		kCredits.m_iNumCreditsEntries = -1;
		RegisterCreditsShown(m_strSelectedMod);
		arrTempSettings = class'XComModsProfile'.default.ModSettings;
			class'XComModsProfile'.default.ModSettings = m_CachedSettings;
			RegisterCreditsShown(m_strSelectedMod);
			m_CachedSettings = class'XComModsProfile'.default.ModSettings;
		class'XComModsProfile'.default.ModSettings = arrTempSettings;
	}
	kCredits.Init(controllerRef, manager, false);
	kCredits.Show();
	controllerRef.m_Pres.m_kCredits = kCredits;
}
function RegisterCreditsShown(string strModName)
{
	local array<string> arrAllModsInPackage;
	local array<string> arrTestClasses, arrModNames;
	local string strClass, strMod;

	arrTestClasses = GetModMgr().GetUIDataForMod(strModName).arrRequiredClassPaths;
	foreach arrTestClasses(strClass)
	{
		arrModNames = GetModMgr().GetDependentModNames(strClass);
		foreach arrModNames(strMod)
		{
			if(arrAllModsInPackage.Find(strMod) < 0)
			{
				arrAllModsInPackage.AddItem(strMod);
			}
		}
	}
	foreach arrAllModsInPackage(strMod)
	{
		class'XComModsProfile'.static.SaveSetting(strMod, "CreditsShown", "true", eVType_Bool);		
	}
}
function DebugRefreshData()
{
	local UIWidget kWidget;
	local int i;

	AS_SetTitle(m_strTitle @ class'UIUtilities'.static.GetHTMLColoredText("(v." $ class'UIModManager'.default.BuildVersion $ ")",1,14));
	AS_SetTabTitle(2, m_strSelectModsButton);
	AS_SetTabTitle(3, m_strConfigureModsButton);
	m_kWidgetHelper.Clear();
	for(i=0; i<m_iNumListOptions;++i)
	{
		switch(i)
		{
		//case 2:
		//case 3:
		//	kWidget = m_arrWidgetHelpers[0].NewButton();
		//	UIWidget_Button(kWidget).strTitle="Test Button"@string(i);
		//	break;
		case 4:
		case 9:
			kWidget = m_kWidgetHelper.NewCombobox();
			UIWidget_Combobox(kWidget).arrLabels.AddItem("option 1");
			UIWidget_Combobox(kWidget).arrValues.AddItem(1);
			UIWidget_Combobox(kWidget).arrLabels.AddItem("option 2");
			UIWidget_Combobox(kWidget).arrValues.AddItem(2);
			UIWidget_Combobox(kWidget).arrLabels.AddItem("option 3");
			UIWidget_Combobox(kWidget).arrValues.AddItem(3);
			UIWidget_Combobox(kWidget).arrLabels.AddItem("option 4");
			UIWidget_Combobox(kWidget).arrValues.AddItem(3);
			UIWidget_Combobox(kWidget).arrLabels.AddItem("option 5");
			UIWidget_Combobox(kWidget).arrValues.AddItem(3);
			UIWidget_Combobox(kWidget).arrLabels.AddItem("option 6");
			UIWidget_Combobox(kWidget).arrValues.AddItem(3);
			UIWidget_Combobox(kWidget).strTitle="Test ComboBox";
			UIWidget_Combobox(kWidget).iCurrentSelection = 2;
			UIWidget_Combobox(kWidget).iBoxSelection = 2;
			break;
		case 5:
			kWidget = m_kWidgetHelper.NewSlider();
			UIWidget_Slider(kWidget).iValue=5;
			UIWidget_Slider(kWidget).iStepSize=1;
			UIWidget_Slider(kWidget).strTitle="Test Slider";
			break;
		case 6:
			kWidget = m_kWidgetHelper.NewSpinner();
			UIWidget_Spinner(kWidget).arrLabels.AddItem("option 1");
			UIWidget_Spinner(kWidget).arrValues.AddItem(1);
			UIWidget_Spinner(kWidget).arrLabels.AddItem("option 2");
			UIWidget_Spinner(kWidget).arrValues.AddItem(2);
			UIWidget_Spinner(kWidget).arrLabels.AddItem("option 3");
			UIWidget_Spinner(kWidget).arrValues.AddItem(3);
			UIWidget_Spinner(kWidget).bCanSpin = true;
			UIWidget_Spinner(kWidget).bIsHorizontal = true;
			UIWidget_Spinner(kWidget).strTitle = " Test Spinner";
			break;
		default:
			kWidget = m_kWidgetHelper.NewCheckbox();
			UIWidget_Checkbox(kWidget).strTitle = "Check option test"@i;
			UIWidget_Checkbox(kWidget).bChecked = i % 2 == 0;
			UIWidget_Checkbox(kWidget).iTextStyle=int(i >= 7);
		}
	}
	SetSelectedTab(2);
	//Call RefreshWidgets with a small delay due to issues with combobox' initialization
	SetTimer(0.10, false, 'DeferredRefreshWidgets');
}
function RefreshData(optional bool bCreateWidgets=true)
{	
	AS_SetTitle(GetTitleLabel());
	AS_SetTabTitle(2, m_iCurrentTab != 3 ? m_strSelectModsButton : m_strBackToModsButton);
	AS_SetTabTitle(4, m_strConfigureModMgrButton);
	AS_SetTabTitle(0, m_strProfilesButton);
	UpdateButtonTabState(false);
	if(bCreateWidgets)
	{
		m_bNewWidgetsPending = true;
		ClearList(); //delete all widgets and reset the helper
	}
	RefreshWidgets();
	if(bCreateWidgets && !m_bNewWidgetsPending)
	{
		OnNewWidgetsUpdate();
	}
}
function RefreshWidgets()
{
	//ClearList might have pushed state RemovingWidgets which will call this later with timer
	if(!IsInState('RemovingWidgets'))
	{
		ClearTimer(GetFuncName());
		switch(m_iCurrentTab)
		{
		case 0:
			RefreshModProfilesMenu();
			break;
		case 2:
			RefreshModsMenu();
			break;
		case 3:
		case 4:
			RefreshConfigOptionsMenu(m_bNewWidgetsPending);
			break;
		}
		FixButtonsLayout();
		//m_bNewWidgetsPending = false;
	}
}
function RefreshModsMenu()
{
	PushState('RefreshingModsMenu');
}
function OnNewWidgetsUpdate()
{
	RefreshHelp();
	UpdateButtonTabState(true);
	if(m_bControllerFocusOnDescField)
	{
		ToggleControllerFocus();
	}
	if(m_iCurrentTab != 2)
	{
		if(m_iRestoreSelection != -1)
		{
			m_kWidgetHelper.SetSelected(m_iRestoreSelection);
			m_iRestoreSelection = -1;
		}
		else
		{
			m_kWidgetHelper.SelectInitialAvailable();
		}
		UpdateSelection(m_kWidgetHelper.GetCurrentSelection());
	}
	if(m_iCurrentTab != 4)
	{
		m_strSelectedModBackup = "";
	}
	m_bNewWidgetsPending = false;
	CloseProgressBox();
}
/** A helper for updating current selection to the last selected mod after coming back from "config options" tab.*/
function int  GetSelectedModIndex(string strName)
{
	local int i, iReturn;

	if(m_iCurrentTab != 2)
	{
		iReturn = 0;
	}
	else
	{
		for(i=0; i < m_iNumListOptions; ++i)
		{
			if(GetModMgr().m_arrModMenuOptions[i].strText == m_strSelectedMod)
			{
				iReturn = i;
				break;
			}
		}
	}
	return iReturn;
}
function string GetTitleLabel()
{
	local array<TModOption> arrOptions;
	local TModOption tO;
	local string strDepthIdx, strTitle, strOption;
	local int i;


	switch(m_iCurrentTab)
	{
	case 0:
		strTitle = m_strProfilesButton;
		break;
	case 2:
		strTitle=class'UIModManager'.default.m_strModsMenuButton;
		break;
	case 3:
		strDepthIdx = m_kDepthHelper.GetCurrentDepthIndex();
		if(strDepthIdx != "")
		{
			//this is some sub-option
			arrOptions = GetModMgr().GetConfigOptionsForMod(m_strSelectedMod,,true,true);
			foreach arrOptions(tO, i)
			{
				if(tO.Index == strDepthIdx)
				{
					break;
				}
			}
			strOption = tO.VarDisplayLabel;
			if(strOption == "" || strOption == " ")
			{
				strOption = arrOptions[i-1].VarDisplayLabel;
			}
			if(InStr(m_strCurrentTitleLabel, strOption) != -1)
			{
				//the sub-option is already included in the title label
				m_strCurrentTitleLabel = Left(m_strCurrentTitleLabel, Len(m_strCurrentTitleLabel) - Len(Split(m_strCurrentTitleLabel,strOption,true)));
			}
			else
			{
				//the sub-option must be added to the title
				m_strCurrentTitleLabel @= "|";
				m_strCurrentTitleLabel @= strOption;
			}
		}
		else
		{
			//this is the list of main options
			m_strCurrentTitleLabel = GetModMgr().GetDisplayNameForMod(m_strSelectedMod);
		}
		strTitle = m_strCurrentTitleLabel;
		break;
	default:		
		strTitle = default.m_strTitle;
	}
	SetupTitleField(strTitle);
	return strTitle;
}
function SetupTitleField(optional string strTestTxt)
{
	local UIModGfxTextField gfxTitle;

	gfxTitle = UIModGfxTextField(SelfGfx().GetObject("titleField", class'UIModGfxTextField'));
	gfxTitle.m_sFontFace = "$TitleFont";
	gfxTitle.m_bWordwrap = true;
	gfxTitle.m_bMultiline = true;
	gfxTitle.SetFontSize(32.0);
	if(strTestTxt != "")
	{
		if(gfxTitle.AS_GetTextExtent(strTestTxt).GetFloat("width") < 2 * gfxTitle.GetFloat("_width"))
		{
			gfxTitle.m_bAutoFontResize = true;
			gfxTitle.m_FontSize=32.0;       //it will be applied during SetHTMLText
		}
		else
		{
			gfxTitle.m_bAutoFontResize = false;
			gfxTitle.m_FontSize=16.0;       //it will be applied during SetHTMLText
		}
	}
	gfxTitle.RealizeProperties();

}
function bool SelectedModHasOptions()
{
	local array<TModOption> arrOptions;
	
	arrOptions = GetModMgr().GetConfigOptionsForMod(m_iCurrentTab == 4 ? m_strSelectedModBackup : m_strSelectedMod);
	return arrOptions.Length > 0;
}
/** Checks if the option for currently selected mod has furter suboptions. Works only in "Configure Selected Mod" tab.*/
function bool HasSuboptions(TModOption tInOption)
{
	local array<TModOption> arrOptions;

	if(m_iCurrentTab == 3 && tInOption.Index != "")
	{
		arrOptions = GetModMgr().GetConfigOptionsForMod(m_strSelectedMod, tInOption.Index, false, true);
	}
	return arrOptions.Length > 0;

}
function UpdateModToggle()
{
	local bool bChecked;
	local int iSelected;

	if(m_iCurrentTab == 2)
	{
		iSelected = GetSelectedModIndex(m_strSelectedMod);
		bChecked = UIWidget_Checkbox(m_kWidgetHelper.m_arrWidgets[iSelected]).bChecked;
		if(GetModMgr().m_arrEnabledModNames.Find(m_strSelectedMod) >= 0 && !bChecked)
		{
			GetModMgr().m_arrEnabledModNames.RemoveItem(m_strSelectedMod);
		}
		else if(GetModMgr().m_arrEnabledModNames.Find(m_strSelectedMod) < 0 && bChecked)
		{
			GetModMgr().m_arrEnabledModNames.AddItem(m_strSelectedMod);
		}
		class'XComModsProfile'.static.SaveSetting(m_strSelectedMod, "bModEnabled", (bChecked ? "true" : "false"), eVType_Bool, GetModMgr().GetUIDataForMod(m_strSelectedMod).VarPath);
	}
	m_bAnyChangesMade = true;
}
/** @param bCreateWidgets Defaults to true*/
function RefreshConfigOptionsMenu(optional bool bCreateWidgets=true)
{
	local TModOption tOption;
	local int iOption, iComboItems;
	local UIWidgetHelper kHelper;
	local UIWidget kWidget;
	local bool bForceComboboxToSpinner;
	local GfxObject gfxWidget;
	local UIModGfxButton gfxCheckbox;

	kHelper = m_kWidgetHelper;
	m_arrCurrentModOptions = GetModMgr().GetConfigOptionsForMod(m_strSelectedMod, m_iCurrentTab == 3 ? m_kDepthHelper.GetCurrentDepthIndex() : "", true);
	foreach m_arrCurrentModOptions(tOption, iOption)
	{
		if(tOption.eWidgetType == eWidget_Combobox )
		{
			iComboItems += tOption.arrListValues.Length;
			bForceComboboxToSpinner = m_bEnsurePerformance && (iComboItems > 256);
			if(bForceComboboxToSpinner)
			{
				m_arrCurrentModOptions[iOption].eWidgetType = eWidget_Spinner; 
			}
		}
		else if(tOption.eWidgetType == eWidget_Slider)
		{
			if(tOption.eVarType == eVType_String || tOption.eVarType == eVType_Bool || tOption.arrListLabels.Length > 101)//debugging of faulty eWidgetType (slider is not suitable for bool or string)
			{
				tOption.eWidgetType = eWidget_Spinner;
			}
			else
			{
				SetupValuesForSlider(tOption);
				m_arrCurrentModOptions[iOption] = tOption; //this assignment AFTER SetupValuesForSlider is crucial for later UpdateSliderLabel
			}
		}
	}
	foreach m_arrCurrentModOptions(tOption, iOption)
	{
		if(bCreateWidgets)
		{
			switch(tOption.eWidgetType)
			{
			case eWidget_Checkbox:
				kWidget = AddNewCheckbox();
				if(HasSuboptions(tOption))
				{
					gfxWidget = GetModList().AS_GetItemAt(iOption);
					GetModList().AttachConfigOptionButton(gfxWidget, ShowSubOptions).AS_SetHTMLText(class'UIOptionsPCScreen'.default.m_strTitle);
					if(tOption.bReadOnly)
					{
						gfxCheckbox = UIModGfxButton(gfxWidget.GetObject("configButton").GetObject("_parent", class'UIModGfxButton'));
						gfxCheckbox.AS_SetRealizeReadOnlyDelegate(gfxCheckbox.del_RealizeReadOnlyVisuals);
					}
				}
				break;
			case eWidget_Spinner:
				kWidget = AddNewSpinner();
				break;
			case eWidget_Slider:
				kWidget = AddNewSlider();
				break;
			case eWidget_Combobox:
				kWidget = AddNewCombobox();
				m_arrAllComboboxes.AddItem(UIWidget_Combobox(kWidget));
				break;
			default:
				kWidget = AddNewSpinner();
			}
		}
		else
		{
			kWidget = m_kWidgetHelper.GetWidget(iOption);
		}
		InitWidgetDataFromTOption(kWidget, tOption);
		if( (tOption.eWidgetType == eWidget_Combobox || bForceComboboxToSpinner) && !IsTimerActive('DeferredRefreshWidgets'))
		{
			ShowProgressBox();
			SetTimer(0.30, false, 'DeferredRefreshWidgets'); //wait for all combos before refreshing
		}
		if(tOption.eWidgetType == eWidget_Slider && !IsTimerActive('DeferredUpdateSliders'))
		{				
			SetTimer(0.15, false, 'DeferredUpdateSliders', self); //this will correctly init labels attached to the tick/thumb (combo-like issue)
		}
		if(!IsTimerActive('DeferredRefreshWidgets'))
		{
			kHelper.RefreshWidget(iOption);
			if(!bCreateWidgets && iOption == m_kWidgetHelper.GetCurrentSelection())
			{
				//FIXME? del_SetFocus like in RefreshingWidgets state?
				//GetModList().SetFocusFX(GetModList().AS_GetItemAt(iOption), true); //RefreshWidget resets highlighting, so this fixes it
				GetModList().del_SetFocus(string(iOption)); //RefreshWidget resets highlighting, so this fixes it	
			}
		}	
	}
	if(bCreateWidgets && !IsTimerActive('DeferredRefreshWidgets'))
	{
		OnNewWidgetsUpdate();
	}
}
function DeferredRefreshWidgets()
{
	PushState('RefreshingWidgets');
}
function ShowProgressBox(optional string strProgressText)
{
	local GFxObject gfxEmblem;
	local UIModGfxTextField gfxTextField;
	local ASDisplayInfo tDisplayInfo;

	if(m_gfxProgressBox == none)
	{
		m_gfxProgressBox = class'UIModUtils'.static.AS_BindMovie(Tab(2), "bgBox", "ProgressBox");
		m_gfxProgressBox.SetFloat("_width", Tab(2).GetFloat("_width") / 2);
		m_gfxProgressBox.SetFloat("_height", Tab(2).GetFloat("_height") / 2);
		m_gfxProgressBox.SetPosition(Tab(2).GetFloat("_width") / 4, Tab(2).GetFloat("_height") / 3 );
	
		gfxEmblem = class'UIModUtils'.static.AS_BindMovie(m_gfxProgressBox, "loading anim", "emblemAnim");
		tDisplayInfo = gfxEmblem.GetDisplayInfo();
		tDisplayInfo.hasXScale = true;
		tDisplayInfo.hasYScale = true;
		tDisplayInfo.XScale = 60.0;
		tDisplayInfo.YScale = 60.0;
		tDisplayInfo.X = 60.0;
		tDisplayInfo.Y = 100.0;
		//gfxEmblem.SetPosition(gfxEmblem.GetFloat("_width"), (m_gfxProgressBox.GetFloat("_height") - gfxEmblem.GetFloat("_height")) / 2);
		gfxEmblem.SetDisplayInfo(tDisplayInfo);

		gfxTextField = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(m_gfxProgressBox, "ProgressText", 120, gfxEmblem.GetFloat("_y"), m_gfxProgressBox.GetFloat("_width") - 150.0, 30.0,,class'UIModGfxTextField'));
		gfxTextField.m_FontSize = 24.0;
		gfxTextField.m_sFontFace = "$TitleFont";
		gfxTextField.SetHTMLText(m_strBuildingOptionsProgress);
	}
	if(strProgressText != "")
	{
		UIModGfxTextField(m_gfxProgressBox.GetObject("ProgressText", class'UIModGfxTextField')).SetHTMLText(strProgressText);
	}
	else
	{
		UIModGfxTextField(m_gfxProgressBox.GetObject("ProgressText", class'UIModGfxTextField')).SetHTMLText(m_strBuildingOptionsProgress);
	}
	m_gfxProgressBox.SetVisible(true);
	GetModList().SetVisible(false);
}
function CloseProgressBox()
{
	if(m_gfxProgressBox != none)
	{
		m_gfxProgressBox.SetVisible(false);
		GetModList().SetVisible(true);
	}
	m_bWaitingForUI = false;
}
function IgnoreChangesAndExit()
{
	RestoreSettings(true);
	PlayCancelSound();
	SaveAndExit(false);
}
function RestoreSettings(bool bOnExit)
{
	class'XComModsProfile'.default.ModSettings = m_CachedSettings;
	if(!bOnExit)
	{
		RefreshData();
	}
}
function RestoreModDefaults(string strModName)
{
	local array<TModOption> arrOptions;
	local TModOption tO;
	local int iOption;

	arrOptions = GetModMgr().GetUIDataForMod(strModName).arrModOptions;
	for(iOption=0; iOption < arrOptions.Length; ++iOption)
	{
		tO = arrOptions[iOption];
		class'XComModsProfile'.static.SaveSetting(strModName, tO.VarName, tO.strDefault, tO.eVarType);
	}
	if(strModName == "UIModManager")
	{
		UpdateModManagerSettings();
	}
}
function RestoreAllDefaults()
{
	local TMenuOption tOption;

	foreach GetModMgr().m_arrModMenuOptions(tOption)
	{
		RestoreModDefaults(tOption.strText);
	}
	RestoreModDefaults("UIModManager");
}
function CacheExistingSettings()
{
	UpdateInitialSettings();
	m_CachedSettings = class'XComModsProfile'.default.ModSettings;
}
function UpdateInitialSettings()
{
	local TModUIData tModData;
	local TModOption tOption;

	foreach GetModMgr().m_arrUIModData(tModData)
	{
		if(!class'XComModsProfile'.static.HasSetting("bModEnabled", tModData.ModName))
		{
			class'XComModsProfile'.static.SaveSetting(tModData.ModName, "bModEnabled", tModData.bEnabledByDefault ? "true" : "false", eVType_Bool, tModData.VarPath);
			if(tModData.bEnabledByDefault && GetModMgr().m_arrEnabledModNames.Find(tModData.ModName) < 0)
			{
				GetModMgr().m_arrEnabledModNames.AddItem(tModData.ModName);
			}
		}
		foreach tModData.arrModOptions(tOption)
		{
			class'XComModsProfile'.static.SaveSetting(tModData.ModName, tOption.VarName, tOption.strInitial, tOption.eVarType, tOption.VarPath);
		}
	}
}
function SaveAndExit(optional bool bUpdateOptions=true)
{
	if(m_iCurrentTab == 3)
	{
		SaveCurrentModOptions();
	}
	class'XComModsProfile'.static.StaticSaveConfig();
	if(bUpdateOptions)
	{
		RealizeModSettings();
	}
	GetModMgr().m_bModsNeedUpdate = bUpdateOptions;
	GetModMgr().OnCleanUp(bUpdateOptions);
	GetModMgr().m_kModShell = none;
	manager.RemoveScreen(self);
}
function SaveCurrentModOptions()
{
	local UIWidget kWidget;
	local int iOption;
	local string strValue;
	local TModOption tO;

	if(m_iCurrentTab != 2)
	{
		foreach m_kWidgetHelper.m_arrWidgets(kWidget, iOption)
		{
			tO = m_arrCurrentModOptions[iOption];
			switch(kWidget.eType)
			{
			case eWidget_Checkbox:
				if(UIWidget_Checkbox(kWidget).bChecked)
				{
					strValue = "true";
				}
				else
				{
					strValue = "false";
				}
				break;
			case eWidget_Spinner:
				if(UIWidget_Spinner(kWidget).arrValues.Length > 0)
				{
					if(tO.eVarType == eVType_Float)
					{
						strValue = string(float(UIWidget_Spinner(kWidget).arrValues[UIWidget_Spinner(kWidget).iCurrentSelection])/100.0);
						strValue = Left(strValue, InStr(strValue, ".") + 3);
					}
					else 
					{
						strValue = string(UIWidget_Spinner(kWidget).arrValues[UIWidget_Spinner(kWidget).iCurrentSelection]);
					}
				}
				else
				{
					strValue = UIWidget_Spinner(kWidget).arrLabels[UIWidget_Spinner(kWidget).iCurrentSelection];
				}
				break;
			case eWidget_Combobox:
				if(UIWidget_Combobox(kWidget).arrValues.Length > 0)
				{
					if(tO.eVarType == eVType_Float)
					{
						strValue = string(float(UIWidget_Combobox(kWidget).arrValues[UIWidget_Combobox(kWidget).iCurrentSelection])/100.0);
						strValue = Left(strValue, InStr(strValue, ".") + 3);
					}
					else 
					{
						strValue = string(UIWidget_Combobox(kWidget).arrValues[UIWidget_Combobox(kWidget).iCurrentSelection]);
					}
				}
				else
				{
					strValue = UIWidget_Combobox(kWidget).arrLabels[UIWidget_Combobox(kWidget).iCurrentSelection];
				}
				break;
			case eWidget_Slider:
				strValue = GetModList().AS_GetItemAt(iOption).GetObject("tickMC").GetObject("Value_txt").GetString("htmlText");
				while(InStr(strValue, "</") != -1)
				{
					strValue = Left(strValue, InStr(strValue, "</"));
				}
				strValue = Right(strValue, Len(strValue) - InStr(strValue, ">", true) - 1);
				break;
			default:
				break;
			}
			class'XComModsProfile'.static.SaveSetting(m_strSelectedMod, tO.VarName, strValue, tO.eVarType, tO.VarPath);
		}
	}
}
/**Applies all ModSettings to actual game variables specified in PropertyPath*/
function RealizeModSettings()
{
	local int i;
	local TModSetting tSetting;

	for(i=0; i < class'XComModsProfile'.default.ModSettings.Length; ++i)
	{
		tSetting = class'XComModsProfile'.default.ModSettings[i];
		if(tSetting.PropertyPath != "")
		{
			if(InStr(tSetting.PropertyPath, ".") != -1)
			{
				//can't let XGTacticalGameCore. sneak through; it is wrong for LW - it messes up half of XComGameCore.ini
				//instead XGTacticalGameCoreNativeBase should be used - to assign values to the parent
				//on launching the game all settings with XGTacticalGameCore. in path are applied the same way and it's fine then
				tSetting.PropertyPath = Repl(tSetting.PropertyPath, "XGTacticalGameCore.", "XGTacticalGameCoreNativeBase.");
				
				//bool values are translated by player's engine to localized version false->"false", "Nie", "Non", "Nein"
				//these should be converted back to universal "false" / "true" for reliability
				if(tSetting.ValueType == eVType_Bool)
				{
					if(tSetting.Value ~= string(true))
					{
						tSetting.Value = "true";
					}
					else if(tSetting.Value ~= string(false))
					{
						tSetting.Value = "false";
					}
				}
				class'UIModOptionsContainer'.static.ConsoleSetSetting(tSetting.PropertyPath, tSetting.Value);
			}
			else
			{
				LogInternal("Warning: Invalid path" @ tSetting.PropertyPath @  "for" @ tSetting.ModName @ tSetting.PropertyName $". Missing a dot.", 'UIModManager'); 
			}
		}
	}
}
/** Puts all menu buttons in one row at the bottom. Lines up tab buttons. Hides the not used tab buttons*/
function FixButtonsLayout()
{
	local float fBackButtonX, fBackButtonWidth, fCenterButtonX, fY, fX, fWidth;
	local GfxObject gfxObj;

	SelfGfx().GetObject("theBackButton").GetPosition(fBackButtonX, fY);
	fCenterButtonX = SelfGfx().GetObject("centerButton1").GetFloat("_x");
	fBackButtonWidth = SelfGfx().GetObject("theBackButton").GetFloat("_width");
	fWidth = SelfGfx().GetObject("centerButton2").GetFloat("_width");
	fX = (fCenterButtonX + fBackButtonX + fBackButtonWidth - fWidth) / 2.0;
	SelfGfx().GetObject("centerButton2").SetPosition(fX, fY);

	SelfGfx().GetObject("centerButton1").GetPosition(fBackButtonX, fY);
	fCenterButtonX = SelfGfx().GetObject("theStartButton").GetFloat("_x");
	fBackButtonWidth = SelfGfx().GetObject("centerButton1").GetFloat("_width");
	
	gfxObj = SelfGfx().GetObject("centerButton3");
	fWidth = gfxObj.GetFloat("_width");
	fX = (fCenterButtonX + fBackButtonX + fBackButtonWidth - fWidth) / 2.0;
	gfxObj.SetPosition(fX, fY);
	if(!manager.IsMouseActive())
	{
		FixCreditsButtonForNonMouse();
	}
	//fX = ButtonTab(1).GetFloat("_x") - ButtonTab(0).GetFloat("_x") - ButtonTab(0).GetFloat("_width");//fX stands for padding
	ButtonTab(3).SetFloat("_x", ButtonTab(2).GetFloat("_x") + ButtonTab(2).GetFloat("_width") + 12.5);
	ButtonTab(4).SetFloat("_x", ButtonTab(3).GetFloat("_x") + ButtonTab(3).GetFloat("_width") + 12.5);
	ButtonTab(0).SetFloat("_x", ButtonTab(4).GetFloat("_x") + ButtonTab(4).GetFloat("_width") + 12.5);
	SelfGfx().GetObject("buttonTab1").SetVisible(false);
	gfxObj.SetVisible(true);
}
function FixCreditsButtonForNonMouse()
{
	local float fX;
	local GfxObject gfxCreditsButton;

	gfxCreditsButton = SelfGfx().GetObject("centerButton3");
	if(gfxCreditsButton.GetObject("buttonHelpMC") != none)
	{
		fX = gfxCreditsButton.GetObject("buttonHelpMC").GetFloat("_width");
		gfxCreditsButton.SetFloat("textX", fX + 4.0);
	}
	if(gfxCreditsButton.GetObject("textField") != none)
	{
		gfxCreditsButton.GetObject("textField").SetFloat("_x", fX + 4.0);
		gfxCreditsButton.GetObject("buttonMC").SetVisible(false);
	}
}
function AttachModList()
{
	m_gfxModList = UIModGfxOptionsList(class'UIModUtils'.static.BindMovie(Tab(2), "XComList", "ModList", class'UIModGfxOptionsList'));
	GetModList().Init(true);
}
function AttachAdditionalMasterButton()
{
	local GFxObject kNewButton;
	local string strMCPath;
	local float fCenterButtonX, fCenterButtonWidth, fStartButtonX, fY, fX, fWidth;

	strMCPath = class'UIModUtils'.static.AS_GetPath(SelfGfx().GetObject("centerButton1"));
	kNewButton = class'UIModUtils'.static.AS_DuplicateMovieClip(strMCPath, "centerButton3");
	kNewButton.SetVisible(false);
	SelfGfx().GetObject("centerButton1").GetPosition(fCenterButtonX, fY);
	fStartButtonX = SelfGfx().GetObject("theStartButton").GetFloat("_x");
	fCenterButtonWidth = SelfGfx().GetObject("centerButton1").GetFloat("_width");
	fWidth = kNewButton.GetFloat("_width");
	fX = (fStartButtonX + fCenterButtonX + fCenterButtonWidth - fWidth) / 2.0;
	kNewButton.SetPosition(fX, fY);
}
function SetSelectedTab(int iSelect)
{
	if( iSelect == 3 && !SelectedModHasOptions() )
	{
		PlayBadSound();
		return;
	}
	m_bWaitingForUI = true;
	if(iSelect != m_iCurrentTab)
	{
		m_iRestoreSelection = -1;
		switch(m_iCurrentTab)
		{
			case 3:
			case 4:
				SaveCurrentModOptions();
				break;
			case 2:
				GetModList().SPINNER_FORCEWIDTH = class'UIModGfxOptionsList'.default.SPINNER_FORCEWIDTH;
				//limit the textfields' width so that text does not overlap widgets
				break;
			default:
		}
		if(iSelect == 4)
		{
			m_strSelectedModBackup = m_strSelectedMod;
			m_strSelectedMod = "UIModManager";
		}
		else if(m_iCurrentTab == 4)
		{
			m_strSelectedMod = m_strSelectedModBackup;
		}
		m_iCurrentTab = iSelect;
	}
	RefreshData();
	if( !(GetModMgr().m_kBackgroundScreen.IsA('UIFinalShell') && InStr(GetScriptTrace(), "OnInit") != -1))
	{
		PlaySelectSound();
	}
}
function UpdateButtonTabState(optional bool bUpdateFocus=true)
{
	local array<ASValue> arrHelper;
	local int iTabToLoseFocus;

	arrHelper.Add(1); //helper to pass as param to Invoke call
	if(m_iCurrentTab == 2)
	{
		if(!SelectedModHasOptions())
		{
			AS_SetTabTitle(3, m_strNoOptions);
			ButtonTab(3).Invoke("disable", arrHelper);
			class'UIModUtils'.static.ObjectMultiplyColor(ButtonTab(3), 1.0, 1.0, 1.0, 1.0);
		}
		else
		{
			AS_SetTabTitle(3, m_strConfigureModsButton);
			ButtonTab(3).Invoke("enable", arrHelper);
			class'UIModUtils'.static.ObjectMultiplyColor(ButtonTab(3), 1.0, 1.0, 1.0, 0.67);
		}
		FixButtonsLayout();
	}
	if(bUpdateFocus)
	{
		for(iTabToLoseFocus=0; iTabToLoseFocus <=4; ++iTabToLoseFocus)
		{
			if(m_arrTabsOrder.Find(iTabToLoseFocus) < 0)
			{
				continue;
			}
			if(iTabToLoseFocus != m_iCurrentTab)
			{
				ButtonTab(iTabToLoseFocus).Invoke("onLoseFocus", arrHelper);
				class'UIModUtils'.static.ObjectMultiplyColor(ButtonTab(iTabToLoseFocus), 1.0, 1.0, 1.0, 0.67);
			}
		}
		ButtonTab(m_iCurrentTab).Invoke("onReceiveFocus", arrHelper);
		class'UIModUtils'.static.ObjectMultiplyColor(ButtonTab(m_iCurrentTab), 1.0, 1.0, 1.0, 1.0);
	}
	if(!manager.IsMouseActive())
	{
		SetTimer(0.10, false, 'FixCreditsButtonForNonMouse');
	}
}
function ClearList()
{
	if(m_arrAllComboboxes.Length > 1 && !IsInState('RemovingWidgets'))
	{
		//comboboxes are multi-widget objects and might require more than one tick to get removed
		PushState('RemovingWidgets');
	}
	else
	{
		GetModList().AS_Clear();
		m_arrAllComboboxes.Length=0;
		m_iNumListOptions = 0;
		GetModList().m_iNumOptions=0;
		m_kWidgetHelper.Clear();
	}
}
function AddNewWidgetToList(string strASClass)
{
	local GFxObject gfxNewWidget;

	gfxNewWidget = GetModList().AS_AddOption(strASClass);
	WidgetHelperGfx(2).GetObject("widgets").SetElementObject(m_iNumListOptions, gfxNewWidget);
	m_iNumListOptions++;
}
function UIWidget_Checkbox AddNewCheckbox()
{
	AddNewWidgetToList("XComCheckbox");
	return m_kWidgetHelper.NewCheckbox();
}
function UIWidget_Combobox AddNewCombobox()
{
	AddNewWidgetToList("XComCombobox");
	return m_kWidgetHelper.NewCombobox();
}
function UIWidget_Spinner AddNewSpinner()
{
	AddNewWidgetToList("XComSpinner");
	return m_kWidgetHelper.NewSpinner();
}
function UIWidget_Slider AddNewSlider()
{
	AddNewWidgetToList("XComSlider");
	return m_kWidgetHelper.NewSlider();
}
function InitWidgetDataFromTOption(UIWidget kWidget, TModOption tOption)
{
	local string strText;
	local int iTemp;

	kWidget.strTitle = tOption.VarDisplayLabel;
	switch(tOption.eWidgetType)
	{
	case eWidget_Checkbox:
		UIWidget_Checkbox(kWidget).bChecked = class'XComModsProfile'.static.HasSetting(tOption.VarName, m_strSelectedMod, strText) ? bool(strText) : bool(tOption.strDefault);
		UIWidget_Checkbox(kWidget).bReadOnly = tOption.bReadOnly;
		break;
	case eWidget_Spinner:
		UIWidget_Spinner(kWidget).bCanSpin = !tOption.bReadOnly;
		if(tOption.eVarType == eVType_Bool)
		{
			UIWidget_Spinner(kWidget).iCurrentSelection = class'XComModsProfile'.static.HasSetting(tOption.VarName, m_strSelectedMod, strText) ? int(bool(strText)) : int(bool(tOption.strDefault));
		}
		if(tOption.eVarType == eVType_Int)
		{
			iTemp = class'XComModsProfile'.static.HasSetting(tOption.VarName, m_strSelectedMod, strText) ? int(strText) : int(tOption.strDefault); 
			UIWidget_Spinner(kWidget).iCurrentSelection = GetInitialSelection_Int(tOption, iTemp);
		}
		if(tOption.eVarType == eVType_Float)
		{
			iTemp = class'XComModsProfile'.static.HasSetting(tOption.VarName, m_strSelectedMod, strText) ? int(float(strText) * 100.0) : int(float(tOption.strDefault) * 100.0); 
			UIWidget_Spinner(kWidget).iCurrentSelection = GetInitialSelection_Float(tOption, float(iTemp) / 100.0);
		}
		UIWidget_Spinner(kWidget).arrLabels = tOption.arrListLabels;
		UIWidget_Spinner(kWidget).arrValues = tOption.arrListValues;
		UIWidget_Spinner(kWidget).__del_OnValueChanged__Delegate = OnSpinnerNewValue;
		break;
	case eWidget_Slider:
		//slider is specific cause it works with values in range 0-100
		if(!class'XComModsProfile'.static.HasSetting(tOption.VarName, m_strSelectedMod, strText))
		{
			strText = tOption.strDefault;
		}
		iTemp = tOption.eVarType == eVType_Int ? GetInitialSelection_Int(tOption, int(strText)) : GetInitialSelection_Float(tOption, float(strText));
		UIWidget_Slider(kWidget).iValue = tOption.arrListValues[iTemp];
		UIWidget_Slider(kWidget).__del_OnIncrease__Delegate = OnSliderIncreaseValue;
		UIWidget_Slider(kWidget).__del_OnDecrease__Delegate = OnSliderDecreaseValue;
		if(tOption.arrListValues.Length > 1)
		{
			UIWidget_Slider(kWidget).iStepSize = 100 / (tOption.arrListValues.Length - 1);
		}
		else
		{
			UIWidget_Slider(kWidget).bReadOnly = true;
		}
		break;
	case eWidget_Combobox:
		UIWidget_Combobox(kWidget).bReadOnly = !tOption.bReadOnly;
		if(tOption.eVarType == eVType_Bool)
		{
			UIWidget_Combobox(kWidget).iCurrentSelection = class'XComModsProfile'.static.HasSetting(tOption.VarName, m_strSelectedMod, strText) ? int(bool(strText)) : int(bool(tOption.strDefault));
		}
		if(tOption.eVarType == eVType_Int)
		{
			iTemp = class'XComModsProfile'.static.HasSetting(tOption.VarName, m_strSelectedMod, strText) ? int(strText) : int(tOption.strDefault); 
			UIWidget_Combobox(kWidget).iCurrentSelection = GetInitialSelection_Int(tOption, iTemp);
		}
		if(tOption.eVarType == eVType_Float)
		{
			iTemp = class'XComModsProfile'.static.HasSetting(tOption.VarName, m_strSelectedMod, strText) ? int(float(strText) * 100.0) : int(float(tOption.strDefault) * 100.0); 
			UIWidget_Combobox(kWidget).iCurrentSelection = GetInitialSelection_Float(tOption, float(iTemp) / 100.0);
		}
		UIWidget_Combobox(kWidget).arrLabels = tOption.arrListLabels;
		UIWidget_Combobox(kWidget).arrValues = tOption.arrListValues;
	default:
		break;
	}
	if(m_strSelectedMod == "UIModManager" || m_iCurrentTab == 4)
	{
		kWidget.__del_OnValueChanged__Delegate = OnModMgrSettingsChanged;
	}
	if(kWidget.__del_OnValueChanged__Delegate == none)
	{
		kWidget.__del_OnValueChanged__Delegate = OnWidgetValueChanged;
	}
	GetModMgr().CallInitWidgetDelegates(kWidget, tOption);
}
function SetupValuesForSlider(out TModOption tO)
{
	//Slider uses arrValues purely as percentage values (varrying between 0 and 100)
	//Therefore arrLabels will be used to display actual values of the option
	//whereas arrValues must be set up to "slide" through the labels as smoothly as possible
	local float fValue, fMinimum, fMaximum, fSpread;
	local int idx, iValue;
	local bool bMissingDefault;

	tO.arrListValues.Length = 0;
	bMissingDefault = tO.arrListLabels.Find(tO.strDefault) < 0;
	fMinimum = float(tO.arrListLabels[0]);
	fMaximum = float(tO.arrListLabels[tO.arrListLabels.Length - 1]);
	fSpread = fMaximum - fMinimum;
	for(idx=0; idx < tO.arrListLabels.Length; ++ idx)
	{
		fValue = float(tO.arrListLabels[idx]);
		if(bMissingDefault && fValue > float(tO.strDefault))
		{
			tO.arrListLabels.InsertItem(idx, tO.strDefault);
			bMissingDefault = false;
			fValue = float(tO.strDefault);
		}
		iValue = int((fValue - fMinimum) / fSpread * 100.0);
		tO.arrListValues.AddItem(iValue);
	}
}
function UpdateSliderLabel(optional int iWidget=-1)
{
	local int iValue, iFound, iLoopCount; 
	local string strValue;
	local GfxObject gfxLabel;
	local UIWidget_Slider kSlider;

	if(iWidget < 0)
	{
		iWidget = m_kWidgetHelper.GetCurrentSelection();
	}
	kSlider = UIWidget_Slider(m_kWidgetHelper.m_arrWidgets[iWidget]); 
	iValue = kSlider.iValue;
	iFound = m_arrCurrentModOptions[iWidget].arrListValues.Find(iValue);
	if(iFound != -1)
	{
		strValue = m_arrCurrentModOptions[iWidget].arrListLabels[iFound];
	}
	else if(!GetModList().AS_GetItemAt(iWidget).GetBool("bDraggingThumb"))
	{
		while(m_arrCurrentModOptions[iWidget].arrListValues.Find(kSlider.iValue) < 0 && iLoopCount <= 100)
		{
			--kSlider.iValue;
			++iLoopCount;
		}
		iFound = m_arrCurrentModOptions[iWidget].arrListValues.Find(kSlider.iValue);
		strValue = m_arrCurrentModOptions[iWidget].arrListLabels[iFound];
		m_kWidgetHelper.RefreshWidget(iWidget);
	}
	strValue = Left(strValue, InStr(strValue, ".") + 3);
	gfxLabel = GetModList().AS_GetItemAt(iWidget).GetObject("tickMC").GetObject("Value_txt");
	gfxLabel.SetString("htmlText", "<p align=\"center\"><font face=\"$NormalFont\" size=\"16\" color=\"#67e8ed\">"$strValue$"</font></p>");
}
function DeferredUpdateSliders()
{
	local int i;

	for(i = 0; i < m_iNumListOptions; ++i)
	{
		if(GetModList().IsSlider(GetModList().AS_GetItemAt(i)))
		{
			UpdateSliderLabel(i);
		}
	}
}
/** Loops through an array of numbers looking for iTestValue. In case of failure iTestValue is added to the array (assumes the values in array being sorted in increasing order). Returns index of iTestValue (either found or added one)*/
function int GetInitialSelection_Int(out TModOption tO, int iTestValue)
{
	local int iValue, idx;
	local bool bFound;
	
	if( tO.eWidgetType == eWidget_Slider)
	{
		idx = tO.arrListLabels.Find(string(iTestValue));
	}
	else
	{
		idx = tO.arrListValues.Find(iTestValue);
	}
	if(idx < 0 && tO.eWidgetType != eWidget_Slider)
	{
		foreach tO.arrListValues(iValue, idx)
		{
			if(iValue >= iTestValue)
			{
				bFound = true;
				break;
			}
		}
		if(bFound)
		{
			tO.arrListValues.InsertItem(idx, iTestValue);
			tO.arrListLabels.InsertItem(idx, string(iTestValue));
		}
		else
		{
			tO.arrListValues.AddItem(iTestValue);
			tO.arrListLabels.AddItem(string(iTestValue));
			idx++;
		}
	}
	idx = Max(0, idx);
	return idx;
}
function int GetInitialSelection_Float(out TModOption tO, float fTestValue)
{
	local int iValue, idx;
	local bool bFound;
	local string strTestValue;

	strTestValue = Left(fTestValue, InStr(fTestValue, ".") + 3);
	if( tO.eWidgetType == eWidget_Slider)
	{
		idx = tO.arrListLabels.Find(strTestValue);
	}
	else
	{
		idx = tO.arrListValues.Find(fTestValue * 100.0);
	}
	if(idx < 0 && tO.eWidgetType != eWidget_Slider)
	{
		foreach tO.arrListValues(iValue, idx)
		{
			if(float(iValue) / 100.0 >= fTestValue)
			{
				bFound = true;
				break;
			}
		}
		if(bFound)
		{
			tO.arrListValues.InsertItem(idx, int(fTestValue * 100.0));
			tO.arrListLabels.InsertItem(idx, Left(fTestValue, InStr(fTestValue, ".") + 3));
		}
		else
		{
			tO.arrListValues.AddItem(int(fTestValue * 100.0));
			tO.arrListLabels.AddItem(Left(fTestValue, InStr(fTestValue, ".") + 3));
			idx++;
		}
	}
	idx = Max(0, idx);
	return idx;
}
function OnBackButtonClick()
{
	local array<TModOption> arrOptions;
	local TModOption tO;
	local int iCount;
	local string strParentIndex;

	if(m_iCurrentTab == 3 && m_kDepthHelper.GetCurrentDepthIndex() != "")
	{
		SaveCurrentModOptions();
		iCount = InStr(m_kDepthHelper.GetCurrentDepthIndex(), ".", true);
		if(iCount != -1)
		{
			strParentIndex = Left(m_kDepthHelper.GetCurrentDepthIndex(), iCount);
		}
		arrOptions = GetModMgr().GetConfigOptionsForMod(m_strSelectedMod, strParentIndex, true);
		foreach arrOptions(tO, iCount)
		{
			if(tO.Index == m_kDepthHelper.GetCurrentDepthIndex())
			{
				m_iRestoreSelection = iCount;
				break;
			}
		}
		m_kDepthHelper.DecreaseDepth();
		RefreshData();
	}
	else if(m_iCurrentTab == 3)
	{
		SetSelectedTab(2);
	}
	else if(m_iCurrentTab == 0)
	{
		NewModProfileDialog();
	}
	else
	{
		DialogIgnoreChanges();
	}
}
function DialogIgnoreChanges()
{
	local TDialogueBoxData kDialog;

	if(m_bShowExitWarning && m_bAnyChangesMade)
	{
		kDialog.strText = class'UIOptionsPCScreen'.default.m_strIgnoreChangesDialogue;
		kDialog.strAccept = class'UIOptionsPCScreen'.default.m_strIgnoreChangesConfirm;
		kDialog.strCancel = class'UIOptionsPCScreen'.default.m_strIgnoreChangesCancel;
		kDialog.fnCallback = OnAcceptIgnoreChangesCallback;
		//show the dialog:
		controllerRef.m_Pres.UIRaiseDialog(kDialog);
	}
	else
	{
		IgnoreChangesAndExit();
	}
}
function OnAcceptIgnoreChangesCallback(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		IgnoreChangesAndExit();
	}
}
function DialogSettingsChanged()
{
	local TDialogueBoxData kDialog;

	if(m_bShowChangesWarning)
	{
		kDialog.strText = m_strSettingsChanged;
		kDialog.strAccept = class'UIUtilities'.default.m_strGenericOK;
		kDialog.strCancel = m_strDontShowAnymore;
		kDialog.fnCallback = OnAcceptSettingsCallback;
		//show the dialog:
		controllerRef.m_Pres.UIRaiseDialog(kDialog);
	}
	else
	{
		OnAcceptSettingsCallback(eUIAction_Accept);
	}
}
function OnAcceptSettingsCallback(EUIAction eAction)
{
	if(eAction == eUIAction_Cancel)
	{
		//"Cancel" stands for "Don't show anymore"
		class'XComModsProfile'.static.SaveSetting("UIModManager", "m_bShowChangesWarning", "False", eVType_Bool);
	}
	SaveAndExit();
}
function DialogResetDefaults(bool bModList)
{
	local TDialogueBoxData kDialog;

	if(bModList)
	{
		kDialog.eType = eDialog_Normal;
		kDialog.strText = m_strRestoreDefaultsDialog;
		kDialog.fnCallback = DialogResetDefaultsCallback;
		kDialog.strAccept = m_strRestoreDefaultsModOptions;
		kDialog.strCancel = m_strRestoreDefaultsModList;	
		//show the dialog:
		controllerRef.m_Pres.UIRaiseDialog(kDialog);
	}
	else
	{
		DialogResetDefaultOptions();
	}
}
function DialogResetDefaultsCallback(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		DialogResetDefaultOptions();
	}
	else
	{
		DialogResetDefaultMods();
	}
}
function DialogResetDefaultOptions()
{
	local TDialogueBoxData kDialog;
	local bool bResetAll;

	bResetAll = m_iCurrentTab == 2;
	if(m_bShowResetWarning)
	{
		kDialog.eType = bResetAll ? eDialog_Warning : eDialog_Normal;
		kDialog.strText = bResetAll ? m_strResetAllDefaults : m_strResetDefaults;
		kDialog.fnCallback = bResetAll ? OnAcceptResetAllDefaultsCallback : OnAcceptResetDefaultsCallback;
		kDialog.strAccept = class'UIUtilities'.default.m_strGenericConfirm;
		kDialog.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;	
		//show the dialog:
		controllerRef.m_Pres.UIRaiseDialog(kDialog);
	}
	else if(bResetAll)
	{
		OnAcceptResetAllDefaultsCallback(eUIAction_Accept);
	}
	else
	{
		OnAcceptResetDefaultsCallback(eUIAction_Accept);
	}
}
function OnAcceptResetDefaultsCallback(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		RestoreModDefaults(m_strSelectedMod);
		RefreshData(false);
	}
}
function OnAcceptResetAllDefaultsCallback(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		RestoreAllDefaults();
	}
}
function DialogResetDefaultMods()
{
	local TDialogueBoxData kDialog;

	if(m_bShowResetWarning)
	{
		kDialog.eType = eDialog_Warning;
		kDialog.strText = m_strResetModListWarning;
		kDialog.fnCallback = OnAcceptResetModListCallback;
		kDialog.strAccept = class'UIUtilities'.default.m_strGenericConfirm;
		kDialog.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;	
		//show the dialog:
		controllerRef.m_Pres.UIRaiseDialog(kDialog);
	}
	else
	{
		OnAcceptResetModListCallback(eUIAction_Accept);
	}
}
function OnAcceptResetModListCallback(EUIAction eAction)
{
	local int iWidget;
	local bool bEnabled;
	local string  strModName;

	if(eAction == eUIAction_Accept)
	{
		for(iWidget=0; iWidget < m_iNumListOptions; ++iWidget)
		{
			strModName = GetModMgr().m_arrModMenuOptions[iWidget].strText;
			bEnabled = GetModMgr().GetUIDataForMod(strModName).bEnabledByDefault;
			UIWidget_Checkbox(m_kWidgetHelper.m_arrWidgets[iWidget]).bChecked = bEnabled;
			if(bEnabled && GetModMgr().m_arrEnabledModNames.Find(strModName) < 0)
			{
				GetModMgr().m_arrEnabledModNames.AddItem(strModName);
			}
			else if(!bEnabled && GetModMgr().m_arrEnabledModNames.Find(strModName) != -1)
			{
				GetModMgr().m_arrEnabledModNames.RemoveItem(strModName);
			}
			class'XComModsProfile'.static.SaveSetting(strModName, "bModEnabled", bEnabled ? "true" : "false", eVType_Bool);
		}
		PushState('RefreshingWidgets');
	}
}
function OnModMgrSettingsChanged()
{
	SaveCurrentModOptions();
	UpdateModManagerSettings();
}

function AS_SetHelp(int Index, string Text, string buttonIcon)
{
    manager.ActionScriptVoid(string(screen.GetMCPath()) $ ".SetHelp");
}
simulated function AS_SetTitle(string Title)
{
    UIModGfxTextField(manager.GetVariableObject(string(GetMCPath()) $ ".titleField", class'UIModGfxTextField')).SetHTMLText(Title);
}
simulated function AS_SetTabTitle(int Index, string Title)
{
    manager.ActionScriptVoid(string(GetMCPath()) $ ".SetTabTitle");
}
simulated function AS_SelectTab(int Index)
{
    manager.ActionScriptVoid(string(GetMCPath()) $ ".SelectTab");
}
function AS_SetDescription(string strText)
{
	local UIModGfxTextField kDescField;

	kDescField = UIModGfxTextField(GetModList().GetObject("descText", class'UIModGfxTextField'));
	kDescField.SetHTMLText(strText);
	AS_SetDescTextScroll(0);
}
/** @param strColorHex Color code in hex notation: "0x000000".*/
function AS_SetDescTextColor(string strColorHex)
{
	GetModList().GetObject("descText").SetString("textColor", strColorHex);
}
function AS_SetDescTextColorNormal()
{
	AS_SetDescTextColor("0x" $ class'UIUtilities'.const.NORMAL_HTML_COLOR);
}
function AS_SetDescTextColorBad()
{
	AS_SetDescTextColor("0x" $ class'UIUtilities'.const.BAD_HTML_COLOR);
}
function int AS_GetDescTextScrollMax()
{
	return int(GetModList().GetObject("descText").GetString("maxscroll"));
}
function int AS_GetDescTextScroll()
{
	return int(GetModList().GetObject("descText").GetString("scroll"));
}
function AS_SetDescTextScroll(coerce float fScroll)
{
	GetModList().GetObject("descText").SetFloat("scroll", fScroll);
}
function GfxObject Tab(int iTab)
{
	return manager.GetVariableObject(GetMCPath() $ ".tab" $ string(iTab));
}
function GfxObject ButtonTab(int iTab)
{
	return manager.GetVariableObject(GetMCPath() $ ".buttonTab" $ string(iTab));
}
/** Returns reference to flash object being this screen*/
function GfxObject SelfGfx()
{
	return manager.GetVariableObject(string(GetMCPath()));
}

/** Returns reference to flash object representing the given helper*/
function GfxObject WidgetHelperGfx(int iHelperID)
{
	local string strPath;

	strPath = GetMCPath() $ "." $ m_arrWidgetHelpers[iHelperID].s_name;
	//cut off "." from the end
	strPath = Left(strPath, Len(strPath) - 1); 
	return manager.GetVariableObject(strPath);
}
/** This function redirects all calls of SetSelected function in ActionScript (inside OptionsPCScreen class) 
	to be handled by Unreal function passed as the parameter fnSetSelected*/
function SetSelectedDelegate(GfxObject gfxWidgetHelper, delegate<SetSelectedWidget> fnSetSelected)
{
	manager.ActionScriptSetFunction(gfxWidgetHelper, "SetSelected"); 
}
/** Pulls specified combobox to the highest (top) layer, so that when opened it would cover the widgets below*/
function AS_BringComboboxToTop(GFxObject kCombobox)
{
	local array<ASValue> arrParams;
	local ASValue myParam;

	myParam.Type=AS_Number;
	myParam.n=GetModList().m_iHighestDepth;
	arrParams.AddItem(myParam);
	kCombobox.Invoke("swapDepths",arrParams);
}
function PlayBadSound()
{
	PlaySound(SoundCue(DynamicLoadObject("SoundUI.NegativeSelection2Cue", class'SoundCue', true)));
}
function PlayCancelSound()
{
	PlaySound(SoundCue(DynamicLoadObject("SoundUI.MenuCancelCue", class'SoundCue', true)));
}
function PlaySelectSound()
{
	PlaySound(SoundCue(DynamicLoadObject("SoundUI.MenuSelectCue", class'SoundCue', true)));
}

function int SortModsDelegate(TMenuOption tOptionA, TMenuOption tOptionB)
{
	local bool bEnabledA, bEnabledB;
	local int iScoreA, iScoreB;

	bEnabledA = GetModMgr().IsModEnabled(tOptionA.strText);
	bEnabledB = GetModMgr().IsModEnabled(tOptionB.strText);

	if(m_bSortMods_ByAlphabet)
	{
		if(CAPS(GetModMgr().GetDisplayNameForMod(tOptionA.strText)) < CAPS(GetModMgr().GetDisplayNameForMod(tOptionB.strText)))
		{
			iScoreA ++;
		}
		else
		{
			iScoreB ++;
		}
	}
	if(m_bSortMods_SelectedFirst)
	{
		iScoreA += 10 * int(bEnabledA && !bEnabledB);
		iScoreB += 10 * int(bEnabledB && !bEnabledA);
	}
	return int(iScoreA >= iScoreB) - 1;
}
function SortMods(out array<TMenuOption> arrOptions)
{
	local array<TMenuOption> arrDisabled, arrEnabled, arrUnsorted;
	local TMenuOption tOption;
	local int idx;
	local string strCurrent;
	local bool bInserted;

	if(m_bSortMods_ByAlphabet)
	{
		arrUnsorted = arrOptions;
		arrOptions.Length = 1;
		arrUnsorted.Remove(0,1);
		while(arrUnsorted.Length > 0)
		{
			bInserted=false;
			strCurrent = GetModMgr().GetDisplayNameForMod(arrUnsorted[0].strText);
			foreach arrOptions(tOption, idx)
			{
				if(CAPS(strCurrent) < CAPS(GetModMgr().GetDisplayNameForMod(tOption.strText)))
				{
					arrOptions.InsertItem(idx, arrUnsorted[0]);
					bInserted = true;
					break;
				}
			}
			if(!bInserted)
			{
				arrOptions.AddItem(arrUnsorted[0]);
			}
			arrUnsorted.Remove(0,1);
		}
	}
	if(m_bSortMods_SelectedFirst)
	{
		for(idx = arrOptions.Length - 1; idx >=0; --idx)
		{
			if(GetModMgr().IsModEnabled(arrOptions[idx].strText) && arrOptions[idx].iState == 1)
			{
				arrEnabled.InsertItem(0, arrOptions[idx]);
			}
			else
			{
				arrDisabled.InsertItem(0, arrOptions[idx]);
			}
		}
		arrOptions.Length = 0;
		foreach arrEnabled(tOption)
		{
			arrOptions.AddItem(tOption);
		}
		foreach arrDisabled(tOption)
		{
			arrOptions.AddItem(tOption);
		}
	}
}
function ShowSubOptions()
{
	local int iOption;
	local bool bFromUnrealCommand;

	PlaySelectSound();
	bFromUnrealCommand = InStr(GetScriptTrace(), "OnUnrealCommand") != -1;
	iOption = bFromUnrealCommand ? m_kWidgetHelper.m_iCurrentWidget : GetModList().GetItemIDFromMouse();
	m_kDepthHelper.IncreaseDepth(m_arrCurrentModOptions[iOption].Index);
	SaveCurrentModOptions();
	m_iRestoreSelection = -1;
	RefreshData();
}
function UpdateModProfileIndexes()
{
	local int iNumProfiles;

	iNumProfiles = GetModMgr().GetNumModProfiles(m_arrModProfileIndexes);
	if(iNumProfiles == 0)
	{
		GetModMgr().AddModProfile(class'UIModManager'.default.m_sModProfilePrefix @ "0", true);
		m_arrModProfileIndexes.AddItem(GetProfileSettings().Data.m_aMPLoadoutSquadDataRemote.Length -1);
	}
}
function string GetModProfileName(optional int iProfileIndex = GetModMgr().m_iModProfileArrayIdx)
{
	return class'GameInfo'.static.ParseOption(GetProfileSettings().Data.m_aMPLoadoutSquadDataRemote[iProfileIndex].strLoadoutName, "ModProfileName");	
}
function string GetModProfileDesc(optional int iProfileIndex = GetModMgr().m_iModProfileArrayIdx)
{
	return class'GameInfo'.static.ParseOption(GetProfileSettings().Data.m_aMPLoadoutSquadDataRemote[iProfileIndex].strLoadoutName, "ModProfileDesc");	
}
function SetModProfileName(string strNewName)
{
	GetProfileSettings().Data.m_aMPLoadoutSquadDataRemote[GetModMgr().m_iModProfileArrayIdx].strLoadoutName = "?ModProfileName="$strNewName$"?ModProfileDesc="$GetModProfileDesc();
}
function SetModProfileDesc(string strNewDesc)
{
	GetProfileSettings().Data.m_aMPLoadoutSquadDataRemote[GetModMgr().m_iModProfileArrayIdx].strLoadoutName = "?ModProfileName="$GetModProfileName()$"?ModProfileDesc="$strNewDesc;
}
function RefreshModProfilesMenu()
{
	local UIMPLoadout_Squad tProfileInfo;
	local XComOnlineProfileSettingsDataBlob kData;
	local UIWidget_Checkbox kCheckbox;
	local int iProfileIdx;

	UpdateModProfileIndexes();
	kData = GetProfileSettings().Data;
	foreach m_arrModProfileIndexes(iProfileIdx)
	{
		tProfileInfo = kData.m_aMPLoadoutSquadDataRemote[iProfileIdx];
		kCheckbox = AddNewCheckbox();
		kCheckbox.iTextStyle = 0; //box to the right, text on left
		kCheckbox.strTitle = GetModProfileName(iProfileIdx);
		kCheckbox.bChecked = tProfileInfo.iLoadoutId == GetModMgr().m_iModProfileID;
		`Log("Adding checkbox for profile name:" @ kCheckbox.strTitle @ "with ID" @ tProfileInfo.iLoadoutId @ "current is" @ GetModMgr().m_iModProfileID,,GetFuncName());
		kCheckbox.__del_OnValueChanged__Delegate = UpdateProfileSelection;
	}
	PushState('RefreshingWidgets');
}
/** Ensures that only one checkbox (for selected profile) is checked.*/
function UpdateProfileSelection()
{
	local int i, iSelected;
	local UIWidget_Checkbox kBox;

	iSelected = m_kWidgetHelper.GetCurrentSelection();
	for(i=0; i < m_kWidgetHelper.GetNumWidgets(); ++i)
	{
		kBox = UIWidget_Checkbox(m_kWidgetHelper.GetWidget(i));
		kBox.bChecked = (i == iSelected);
	}
	m_kWidgetHelper.RefreshAllWidgets();
	GetModMgr().UpdateCurrentModProfile( GetProfileSettings().Data.m_aMPLoadoutSquadDataRemote[m_arrModProfileIndexes[iSelected]].iLoadoutId );
}
function NewModProfileDialog()
{
	local TInputDialogData tData;

	tData.strTitle = m_strNewProfileTitle;
	tData.strInputBoxText = GetModMgr().m_sModProfilePrefix @ GetModMgr().GetNextLowestModID();
	tData.fnCallbackAccepted = OnConfirmAddModProfile;
	tData.fnCallback = OnCloseInputDialog;
	controllerRef.m_Pres.UIInputDialog(tData);
}
function OnCloseInputDialog(string strInput)
{
	GetModMgr().m_kBackgroundScreen.OnLoseFocus();
}
function OnConfirmAddModProfile(string strProfileName)
{
	class'UIUtilities'.static.StripUnsupportedCharactersFromUserInput(strProfileName);
	if(strProfileName != "")
	{
		m_iRestoreSelection = m_kWidgetHelper.GetCurrentSelection();
		GetModMgr().AddModProfile(strProfileName);
		RefreshData();
	}
}
function EditModProfileDialog()
{
	local TDialogueBoxData tData;

	tData.eType = eDialog_Normal;
	tData.strTitle = m_strEditProfileTitle;
	tData.strText = m_strEditProfileDialog;
	tData.strAccept = m_strEditProfileNameButton;
	tData.strCancel = m_strEditProfileDescButton;
	tData.fnCallback = OnEditProfileCallback;
	controllerRef.m_Pres.UIRaiseDialog(tData);
}
function OnEditProfileCallback(EUIAction eOption)
{
	if(eOption == eUIAction_Accept)
	{
		EditProfileNameDialog();
	}
	else
	{
		EditProfileDescDialog();
	}
}
function EditProfileNameDialog()
{
	local TInputDialogData tData;

	tData.strTitle = m_strEditProfileNameButton;
	tData.strInputBoxText = GetModProfileName();
	tData.fnCallbackAccepted = OnNewProfileName;
	tData.fnCallback = OnCloseInputDialog;
	controllerRef.m_Pres.UIInputDialog(tData);
}
function OnNewProfileName(string strInput)
{
	class'UIUtilities'.static.StripUnsupportedCharactersFromUserInput(strInput);
	if(strInput != "")
	{
		SetModProfileName(strInput);
		UIWidget_Checkbox(m_kWidgetHelper.GetCurrentWidget()).strTitle = strInput;
		m_kWidgetHelper.RefreshWidget(m_kWidgetHelper.GetCurrentSelection());
	}
}
function EditProfileDescDialog()
{
	local TInputDialogData tData;

	tData.strTitle = m_strEditProfileDescButton;
	tData.strInputBoxText = GetModProfileDesc();
	tData.iMaxChars = 60;
	tData.fnCallbackAccepted = OnNewProfileDesc;
	tData.fnCallback = OnCloseInputDialog;
	controllerRef.m_Pres.UIInputDialog(tData);
}
function OnNewProfileDesc(string strInput)
{
	class'UIUtilities'.static.StripUnsupportedCharactersFromUserInput(strInput);
	if(strInput != "")
	{
		SetModProfileDesc(strInput);
		if(GetProfileSettings().Data.m_aMPLoadoutSquadDataRemote[m_arrModProfileIndexes[m_kWidgetHelper.GetCurrentSelection()]].strLanguageCreatedWith == "")
		{
			AS_SetDescription(m_strEmptyProfile$"\n\n"$ strInput);
		}
		else
		{
			AS_SetDescription(strInput);
		}
	}
}
function DeleteModProfileDialog()
{
	local TDialogueBoxData tData;

	if(GetModMgr().GetNumModProfiles() == 1)
	{
		tData.eType = eDialog_Normal;
		tData.strTitle = m_strDeleteProfileFailedTitle;
		tData.strText = m_strDeleteProfileFailed;
		tData.strAccept = class'UIUtilities'.default.m_strGenericOK;
	}
	else
	{
		tData.eType = eDialog_Warning;
		tData.strTitle = m_strDeleteProfileTitle;
		tData.strText = m_strDeleteProfileDialog @ GetModProfileName() @ "?";
		tData.strAccept = class'UIUtilities'.default.m_strGenericConfirm;
		tData.strCancel = class'UIUtilities'.default.m_strGenericCancel;
		tData.fnCallback = OnDeleteProfileCallback;
	}
	controllerRef.m_Pres.UIRaiseDialog(tData);
}
function OnDeleteProfileCallback(EUIAction eOption)
{
	if(eOption == eUIAction_Accept)
	{
		if(GetModMgr().DeleteCurrentModProfile())
		{
			RefreshData();
		}
	}
}
function LoadModProfileRequested()
{
	local TDialogueBoxData tData;

	if(GetProfileSettings().Data.m_aMPLoadoutSquadDataRemote[m_arrModProfileIndexes[m_kWidgetHelper.GetCurrentSelection()]].strLanguageCreatedWith != "")
	{
		LoadModProfileDialog();
	}
	else
	{
		tData.eType = eDialog_Warning;
		tData.strTitle = class'UILoadGame'.default.m_sLoadFailedTitle;
		tData.strText = m_strEmptyProfileWarning;
		tData.strAccept = class'UIUtilities'.default.m_strGenericOK;
		controllerRef.m_Pres.UIRaiseDialog(tData);
	}
}
function LoadModProfileDialog()
{
	local TDialogueBoxData tData;

	tData.strTitle = m_strLoadProfileTitle;
	tData.strText = m_strLoadProfileDialog;
	tData.strAccept = class'UIUtilities'.default.m_strGenericConfirm;
	tData.strCancel = class'UIUtilities'.default.m_strGenericCancel;
	tData.fnCallback = OnConfirmLoadModProfile;
	controllerRef.m_Pres.UIRaiseDialog(tData);
}
function OnConfirmLoadModProfile(EUIAction eOption)
{
	if(eOption == eUIAction_Accept)
	{
		ShowProgressBox(class'XComOnlineEventMgr'.default.m_sLoadingProfile);
		SetTimer(1.0, false, 'CloseProgressBox');
		GetModMgr().UpdateAllModsFromProfile();
		m_bAnyChangesMade=true;
	}
}
function SaveModProfileRequested()
{
	local TDialogueBoxData tData;

	tData.strTitle = m_strSaveProfileTitle;
	tData.strText = m_strSaveProfileDialog;
	if(GetProfileSettings().Data.m_aMPLoadoutSquadDataRemote[m_arrModProfileIndexes[m_kWidgetHelper.GetCurrentSelection()]].strLanguageCreatedWith != "")
	{
		tData.strText $= "\n\n"$m_strSaveProfileConfirmOverwrite;
	}
	tData.strAccept = class'UIUtilities'.default.m_strGenericConfirm;
	tData.strCancel = class'UIUtilities'.default.m_strGenericCancel;
	tData.fnCallback = OnConfirmSaveModProfile;
	controllerRef.m_Pres.UIRaiseDialog(tData);
}
function OnConfirmSaveModProfile(EUIAction eOption)
{
	if(eOption == eUIAction_Accept)
	{
		ShowProgressBox(class'XComOnlineEventMgr'.default.m_strSaving);
		SetTimer(1.0, false, 'CloseProgressBox');
		GetModMgr().SaveModProfile();
	}
}
function XComOnlineProfileSettings GetProfileSettings()
{
	return XComOnlineProfileSettings(Class'Engine'.static.GetEngine().GetProfileSettings());
}
state InitingUI
{
//DEPRECATED
Begin:
//	AttachModList();
//	AttachAdditionalMasterButton();
//	SortMods(GetModMgr().m_arrModMenuOptions);
	m_strSelectedMod = GetModMgr().m_arrModMenuOptions[0].strText;
	if(controllerRef.m_Pres.m_kDifficulty != none)
	{
		controllerRef.m_Pres.m_kDifficulty.Hide();
	}
	if(controllerRef.m_Pres.m_kPCOptions != none)
	{
		controllerRef.m_Pres.m_kPCOptions.Hide();
	}
	SetSelectedTab(2);
	AS_SelectTab(2);
	UpdatePanelFocusFX();
	if(!class'XComModsProfile'.static.ReadSettingBool("CreditsShown", "UIModManager"))
	{
		m_strSelectedMod = "UIModManager";
		ShowCredits();
		m_strSelectedMod = GetModMgr().m_arrModMenuOptions[0].strText;		
	}
	SelfGfx().SetVisible(true);
	PopState();
}
state RefreshingModsMenu
{
	function BuildWidgets()
	{
		local UIWidget kWidget;
		local GFxObject gfxWidget;
		local int i;
		local TMenuOption tOption;
		local string strModName;

		for(i=0; i< GetModMgr().m_arrModMenuOptions.Length;++i)
		{
			kWidget = AddNewCheckbox();
			gfxWidget = GetModList().AS_GetItemAt(i);
			tOption = GetModMgr().m_arrModMenuOptions[i];
			strModName = tOption.strText;
			UIWidget_Checkbox(kWidget).strTitle = GetModMgr().GetDisplayNameForMod(strModName);
			UIWidget_Checkbox(kWidget).bChecked = (tOption.iState > 0 && class'XComModsProfile'.static.ReadSettingBool("bModEnabled", strModName));
			UIWidget_Checkbox(kWidget).iTextStyle = 1; //text on left, box on right
			kWidget.__del_OnValueChanged__Delegate = UpdateModToggle; //sets a function to be called whenever the box is checked/unchecked
			if(tOption.iState == 0)
			{
				class'UIModUtils'.static.ObjectMultiplyColor(gfxWidget.GetObject("displayLabelField"), 128.0/103.0, 128.0/232.0, 128.0/237.0);
			}
			else if(tOption.iState == -1)
			{
				class'UIModUtils'.static.ObjectMultiplyColor(gfxWidget.GetObject("displayLabelField"), 255.0/103.0, 0.0, 0.0);
			}

		}
	}
Begin:
	m_iNumListOptions = 0;
	m_kDepthHelper.ResetDepth();
	SortMods(GetModMgr().m_arrModMenuOptions);
	GetModList().SPINNER_FORCEWIDTH = -30.0;
	Sleep(0.05);
	BuildWidgets();
	Sleep(0.05);
	PushState('RefreshingWidgets');
	m_kWidgetHelper.SetSelected(GetSelectedModIndex(m_strSelectedMod));
	UpdateSelection(m_kWidgetHelper.GetCurrentSelection());
	PopState();
}
state RefreshingWidgets
{
	event PoppedState()
	{
		CloseProgressBox();
	}
Begin:
    for(m_iCurrentWidget = 0; m_iCurrentWidget < m_kWidgetHelper.GetNumWidgets();  ++ m_iCurrentWidget)
    {
		m_kWidgetHelper.m_iCurrentWidget = m_iCurrentWidget;
        m_kWidgetHelper.RefreshWidget(m_iCurrentWidget);
		if(m_kWidgetHelper.GetWidget(m_iCurrentWidget).eType == eWidget_Combobox)
		{
			Sleep(0.05);
		}
    }
	Sleep(0.01);//sleep(0.01) allows to avoid infinite loop with too many widgets 
	GetModList().AS_RealizePositions();
	if(m_bNewWidgetsPending)
	{
		OnNewWidgetsUpdate();
	}
	if(m_iCurrentTab != 2)
	{
		//GetModList().SetFocusFX(GetModList().AS_GetItemAt(m_iRestoreSelection != -1 ? m_iRestoreSelection : 0), true);
		GetModList().del_SetFocus(string(m_iRestoreSelection));
	}
	GetModList().SetVisible(true);
	PopState();
}
state RemovingWidgets
{
	event PoppedState()
	{
		if(m_bNewWidgetsPending)
		{
			SetTimer(0.10, true, 'RefreshWidgets');
		}
	}
	function RemoveWidgetClip(int iListIdx)
	{
		//warning: this only removes the clip without clearing dictionaries
		GetModList().AS_RemoveWidget(GetModList().AS_GetItemAt(iListIdx));
	}
Begin:
	ShowProgressBox();
	while(GetModList().AS_GetItemAt(0) != none)
	{
		RemoveWidgetClip(0);
		Sleep(0.01);
	}
	ClearList();
	PopState();
}
DefaultProperties
{
	s_package="/ package/gfxOptionsPCScreen/OptionsPCScreen"
	s_screenId="gfxOptionsPCScreen"
	s_name="theScreen"
    e_InputState=eInputState_Consume
	m_bDebugLog=true
	m_bControllerFocusOnDescField=false;
	m_arrTabsOrder[0]=2
	m_arrTabsOrder[1]=3
	m_arrTabsOrder[2]=4
	m_arrTabsOrder[3]=0
	m_iCurrentTab=2
	m_iRestoreSelection=-1;
}