class UIModToggles extends UIGameplayToggles;

var localized string m_strModTogglesTitle;
var UIModManager m_kModMgr;

simulated function Init(XComPlayerController _controllerRef, UIFxsMovie _manager, optional bool bViewOnly=false)
{
	local XComMod kMod;

	BaseInit(_controllerRef, _manager);
	m_bViewOnly = bViewOnly;
	m_hWidgetHelper = Spawn(class'UIWidgetHelper', self);
	m_kHelpBar = Spawn(class'UINavigationHelp', self);
	m_kHelpBar.Init(_controllerRef, _manager, self, UpdateButtonHelp);
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
	GetModMgr().m_kModToggles = self;
	manager.LoadScreen(self);
}
function UIModManager GetModMgr()
{
	return m_kModMgr;
}
function UpdateButtonHelp()
{
	m_kHelpBar.AddBackButton(OnUCancel);
}
simulated function OnUCancel()
{
	local UIModShell kModShell;

	class'XComModsProfile'.static.StaticSaveConfig();
	PlaySound(SoundCue(DynamicLoadObject("SoundUI.MenuCancelCue", class'SoundCue')), true);
	GetModMgr().UpdateModMenuOptions();
	kModShell = GetModMgr().m_kModShell;
	if(kModShell.m_iCurrentTab == 2)
	{
		kModShell.RefreshData(true);
		kModShell.UpdateSelection(kModShell.m_kWidgetHelper.GetCurrentSelection());
	}
	GetModMgr().m_kModToggles = none;
	OnLoseFocus();
	manager.RemoveScreen(self);
}

simulated function OnInit()
{
	local GfxObject gfxBackButton;

	super.OnInit();
	UpdateData();
	RefreshDescInfo();
	if(UIModShell(Owner) == none)
	{
		OnReceiveFocus();
	}
	else
	{
		UIModShell(Owner).Hide();
	}
	if(!class'UIModManager'.static.IsLongWarBuild())
	{
		gfxBackButton =	manager.GetVariableObject(m_kHelpBar.GetMCPath() $".leftContainer.itemRoot.buttonHelp_0");
		if(gfxBackButton != none)
		{
			gfxBackButton.SetFloat("_x", gfxBackButton.GetFloat("_x") - 40.0);
		}
	}
}
simulated function OnReceiveFocus()
{
	if(UIModShell(Owner) != none)
	{
		UIModShell(Owner).Hide();
	}
	Show();
}
simulated function OnLoseFocus()
{
	if(UIModShell(Owner) != none)
	{
		UIModShell(Owner).Show();
	}
	Hide();
}
simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
	local bool bHandled;

    if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg))
    {
        bHandled = true;
    }
	if(!bHandled)
	{
		switch(Cmd)
		{
		case 300:
		case 511:
		case 513:
			if(GetModMgr().m_arrPackageMenuOptions[m_hWidgetHelper.GetCurrentSelection()].iState == 0)
			{
				PlaySound(SoundCue(DynamicLoadObject("SoundUI.MenuCancelCue", class'SoundCue')), true);	
				bHandled = true;
				break;
			}
		default:
			bHandled = super.OnUnrealCommand(Cmd, Arg);
		}
	}
	return bHandled;
}
simulated function bool OnMouseEvent(int Cmd, array<string> args)
{
	local bool bHandled;
    local int iSelection;

    if(args[args.Length - 2] != "optionsList" && Cmd == 391)
    {
        iSelection = int(args[args.Length - 2]);
		if(GetModMgr().m_arrPackageMenuOptions[iSelection].iState == 0)
		{
			PlaySound(SoundCue(DynamicLoadObject("SoundUI.MenuCancelCue", class'SoundCue')), true);	
			bHandled = true;
		}
    }
	if(!bHandled)
	{
        bHandled = super.OnMouseEvent(Cmd, args);
	}
	return bHandled;
}
simulated function UpdateData()
{
    local UIWidget_Checkbox kCheckbox;
    local int I, ActiveWidgetIndex;

    AS_SetTitle(m_strModTogglesTitle);
	EnsureEnoughGfxWidgets();
	GetModMgr().m_arrPackageMenuOptions.Sort(SortPackages);
	for(I = 0; I < GetModMgr().m_arrPackageMenuOptions.Length; ++I)
	{
		if(m_hWidgetHelper.GetNumWidgets() <= ActiveWidgetIndex)
		{
			kCheckbox = m_hWidgetHelper.NewCheckbox();
			ActiveWidgetIndex = m_hWidgetHelper.GetNumWidgets() - 1;
		}
		else
		{
			kCheckbox = UIWidget_Checkbox(m_hWidgetHelper.GetWidget(ActiveWidgetIndex));
		}
		kCheckbox.strTitle = GetModMgr().m_arrPackageMenuOptions[I].strText;
		kCheckbox.bChecked = (GetModMgr().m_arrPackageMenuOptions[I].iState > 0 && (!class'XComModsProfile'.static.HasSetting(kCheckbox.strTitle, "UIModManager") || class'XComModsProfile'.static.ReadSettingBool(kCheckbox.strTitle, "UIModManager")));
		if(kCheckbox.strTitle == "XComModShell" || kCheckbox.strTitle == "XComSaveHelp")
		{
			kCheckbox.bChecked = true;
			kCheckbox.bReadOnly = true;
		}
		m_hWidgetHelper.RefreshWidget(ActiveWidgetIndex);
		kCheckbox.__del_OnValueChanged__Delegate = UpdateToggle;
		m_hWidgetHelper.SetActive(ActiveWidgetIndex, true);
		if(GetModMgr().m_arrPackageMenuOptions[I].iState == 0)
		{
			class'UIModUtils'.static.ObjectMultiplyColor(manager.GetVariableObject(GetMCPath() $ ".option" $ string(ActiveWidgetIndex)), 5.0, 0.0, 0.0);
		}
		++ ActiveWidgetIndex;
	}
	m_hWidgetHelper.RefreshAllWidgets();
	m_hWidgetHelper.SetSelected(0);
	RefreshDescInfo();
}
simulated function UpdateToggle()
{
	local int iOption;
	local bool bTurnedOn;

	iOption = m_hWidgetHelper.GetCurrentSelection();
	bTurnedOn = bool(m_hWidgetHelper.GetCurrentValue(iOption));
	class'XComModsProfile'.static.SaveSetting("UIModManager", m_hWidgetHelper.m_arrWidgets[m_hWidgetHelper.GetCurrentSelection()].strTitle, bTurnedOn ? "true" : "false", eVType_Bool);
	PlaySound(SoundCue(DynamicLoadObject("SoundUI.MenuSelectCue", class'SoundCue')), true);
}

simulated function RefreshDescInfo()
{
	local int iSelection;

	iSelection = m_hWidgetHelper.GetCurrentSelection();
	AS_SetDesc( GetModMgr().m_arrPackageMenuOptions[iSelection].strHelp);
}
function EnsureEnoughGfxWidgets()
{
	local int i;

	if(GetModMgr().m_arrPackageMenuOptions.Length > AS_GetNumOptions())
	{
		for(i = AS_GetNumOptions(); i < GetModMgr().m_arrPackageMenuOptions.Length; i++)
		{
			AS_AddOption();
		}
		AS_RealizePositions();
	}
}
function int SortPackages(TMenuOption tOptionA, TMenuOption tOptionB)
{
	local bool bEnabledA, bEnabledB;
	local int iScoreA, iScoreB;

	bEnabledA = GetModMgr().IsPackageEnabled(tOptionA.strText);
	bEnabledB = GetModMgr().IsPackageEnabled(tOptionB.strText);

	if(UIModShell(Owner).m_bSortMods_ByAlphabet)
	{
		if(CAPS(tOptionA.strText) < CAPS(tOptionB.strText))
		{
			iScoreA ++;
		}
		else
		{
			iScoreB ++;
		}
	}
	if(UIModShell(Owner).m_bSortMods_SelectedFirst)
	{
		iScoreA += 10 * int(bEnabledA && !bEnabledB);
		iScoreB += 10 * int(bEnabledB && !bEnabledA);
	}
	return int(iScoreA >= iScoreB) - 1;
}
event Destroyed()
{
	m_kModMgr = none;
}
function AS_AddOption()
{
	manager.ActionScriptVoid(GetMCPath() $ ".optionsList.AddOption");
}
function AS_RealizePositions()
{
	manager.ActionScriptVoid(GetMCPath() $ ".optionsList.realizePositions");
}
function int AS_GetNumOptions()
{
	return	int(manager.GetVariableNumber(GetMCPath() $ ".optionsList.numOptions"));
}
DefaultProperties
{
}
