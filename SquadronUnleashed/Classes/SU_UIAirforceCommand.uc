class SU_UIAirforceCommand extends UI_FxsScreen
	config(SquadronUnleashed);

var int m_iView;
var SU_XGHangarUI m_kMgr;
var SUGfx_AirforceCommand m_gfxScreen;
var UIWidgetHelper m_kWidgetHelper;
var Vector2D m_vLastUpdateMouseLoc;
var SquadronUnleashed m_kSquadronMod;
var float m_fMouseUpdateStepSq;
var int m_iUpgradeStaffCost;
var int m_iUpgradeFacilitiesCost;
var int m_iUpgradeProgramsCost;
var localized string m_strAirforceCommand;
var localized string m_strSelectTacticLabel;
var localized string m_strSelectTacticHelp;
var localized string m_strAutoCloseDistanceLabel;
var localized string m_strAutoCloseDistanceDescription;
var localized string m_strAutoAbortThresholdLabel;
var localized string m_strAutoAbortDescription;
var localized string m_strAutoBackOffThresholdLabel;
var localized string m_strAutoBackOffDescription;
var localized string m_strCombatTacticsTitle;
var localized string m_strTrainingGuidelinesTitle;
var localized string m_strTacticsTabLabel;
var localized string m_strTrainingTabLabel;
var localized string m_strTrainingDuration;
var localized string m_strTrainingXPBonus;
var localized string m_strTrainingCapacity;
var localized string m_strTrainingXPLimit;
var localized string m_strMonthlyMaintananceCosts;
var localized string m_strTrainingProgramsLabel;
var localized string m_strTrainingStaffLabel;
var localized string m_strTrainingFacilitiesLabel;
var localized string m_strTrainingProgramsHelp;
var localized string m_strTrainingFacilitiesHelp;
var localized string m_strTrainingStaffHelp;
var localized string m_strLevel;
var localized string m_strConfirmNewTrainingGuidelinesTitle;
var localized string m_strConfirmNewTrainingGuidelinesDialog;
var config string m_strCombatTacticsImgPath;
var config string m_strTrainingGuidelinesImgPth;
var config string m_strTacticsTabImgPath;
var config string m_strTrainingTabImgPth;

simulated function Init(XComPlayerController _controllerRef, UIFxsMovie _manager, int iView)
{
	BaseInit(_controllerRef, _manager);
	m_iView = iView;
	manager.LoadScreen(self);
}
function SU_XGHangarUI GetMgr()
{
	if(m_kMgr == none)
	{
		m_kMgr = SU_XGHangarUI(XComHQPresentationLayer(controllerRef.m_Pres).GetMgr(class'SU_XGHangarUI', self));
	}
	return m_kMgr;
}
simulated function OnInit()
{
	super.OnInit();
	SelfGfx().OnLoad();
	m_kSquadronMod = class'SU_Utils'.static.GetSquadronMod();
	m_kWidgetHelper = Spawn(class'UIWidgetHelper', self);
	XComHQPresentationLayer(controllerRef.m_Pres).m_kStrategyHUD.ShowBackButton(OnUCancel);
	AS_SetLabels(m_strAirforceCommand, "", "");
	SelfGfx().LoadCategoryImg(0, m_strTacticsTabImgPath);	
	SelfGfx().SetCategoryLabel(0, m_strTacticsTabLabel);
	if(!m_kSquadronMod.m_bDisablePilotXP)
	{
		SelfGfx().LoadCategoryImg(1, m_strTrainingTabImgPth);	
		SelfGfx().SetCategoryLabel(1, m_strTrainingTabLabel);
	}
	else
	{
		AS_SetTabState(1,1);
	}
	AS_SetTabState(2,1);
	AS_SetSelectedCategory(m_iView);
	class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_FirstVisitAirCommand);
	UpdateLayout(m_iView);
	UpdateData();
	Show();
//	if(manager.IsMouseActive())
//	{
//		XComHQPresentationLayer(controllerRef.m_Pres).GetStrategyHUD().m_kHelpBar.SetButtonType("XComButtonIconPC");
//		XComHQPresentationLayer(controllerRef.m_Pres).GetStrategyHUD().m_kHelpBar.AddLeftHelp("3", "", OnUAccept);
//		XComHQPresentationLayer(controllerRef.m_Pres).GetStrategyHUD().m_kHelpBar.SetButtonType("");
//	}
//	else
//	{
//		XComHQPresentationLayer(controllerRef.m_Pres).GetStrategyHUD().m_kHelpBar.AddLeftHelp("DETAILS", "Icon_LSCLICK_L3", OnUAccept);
//	}
}
function PostInit()
{
	
}
event Tick(float fDeltaT)
{
	if(manager.IsMouseActive() && V2DSizeSq(controllerRef.m_Pres.m_kUIMouseCursor.m_v2MouseLoc - m_vLastUpdateMouseLoc) > m_fMouseUpdateStepSq)
	{
		m_vLastUpdateMouseLoc = controllerRef.m_Pres.m_kUIMouseCursor.m_v2MouseLoc;
		UpdateSelectionFromMouseCursor();
	}
}
simulated function bool OnUnrealCommand(int Cmd, int Arg)
{	
	local bool bHandled;

	if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg) || Cmd == 400)
	{
		bHandled = false;
	}
	else
	{
		`Log(self @ GetFuncName() @ Cmd @ Arg);
		switch(Cmd)
		{
		case class'UI_FxsInput'.const.FXS_KEY_ESCAPE:
		case class'UI_FxsInput'.const.FXS_BUTTON_B:
			bHandled = OnCancel();
			break;
		case class'UI_FxsInput'.const.FXS_BUTTON_RTRIGGER:
		case class'UI_FxsInput'.const.FXS_BUTTON_RBUMPER:
			if(m_iView == 0 && !m_kSquadronMod.m_bDisablePilotXP)
			{
				GoToView(1);
				bHandled = true;
			}
			break;
		case class'UI_FxsInput'.const.FXS_BUTTON_LTRIGGER:
		case class'UI_FxsInput'.const.FXS_BUTTON_LBUMPER:
			if(m_iView == 1)
			{
				GoToView(0);
				bHandled = true;
			}
			break;
		case class'UI_FxsInput'.const.FXS_ARROW_LEFT:
		case class'UI_FxsInput'.const.FXS_DPAD_LEFT:
			if(m_iView == 1 && UIWidget_Spinner(m_kWidgetHelper.GetCurrentWidget()).iCurrentSelection == 0)
			{
				GetMgr().PlayBadSound();
				bHandled = true;
			}
			else if(m_iView == 0 && m_kWidgetHelper.m_iCurrentWidget == 1)
			{
				bHandled = true;//the checkbox on Combat Tactics view
			}
			break;
		case class'UI_FxsInput'.const.FXS_ARROW_RIGHT:
		case class'UI_FxsInput'.const.FXS_DPAD_RIGHT:
			if(m_iView == 0 && m_kWidgetHelper.m_iCurrentWidget == 1)
			{
				bHandled = true;//the checkbox on Combat Tactics view
			}
			else if(m_iView == 1 && UIWidget_Spinner(m_kWidgetHelper.GetCurrentWidget()).iCurrentSelection == UIWidget_Spinner(m_kWidgetHelper.GetCurrentWidget()).arrValues.Length-1)
			{
				GetMgr().PlayBadSound();
				bHandled = true;
			}
			break;
		case class'UI_FxsInput'.const.FXS_BUTTON_Y:
			if(m_iView == 0)
			{
				bHandled = OnAccept();
			}
			break;
		case class'UI_FxsInput'.const.FXS_BUTTON_A:
			if(m_iView == 1)
			{
				bHandled = OnAccept();//confirm button on training view
				break;
			}
		default:
		}
		if(!bHandled)
		{
			bHandled = m_kWidgetHelper.OnUnrealCommand(Cmd, Arg);
		}
	}
	if(bHandled)
	{
		UpdateData();
	}
	return bHandled;
}
simulated function bool OnMouseEvent(int Cmd, array<string> args)
{
	local int iWidget, iOption;
	local bool bHandled;
	
	bHandled = true;
	if(args.Length >= 8)//pattern: _level0.theInterfaceMgr.gfxBuildItem.theBuildScreen.itemList.theItems.1.[iOption]
	{
		iWidget = int(args[6]);
		iOption = int(args[args.Length-1]); //"theButton" standing for checkbox returns 0, spinner arrows are -1 or -2
		if(m_iView == 1 && iOption == -2 && UIWidget_Spinner(m_kWidgetHelper.GetCurrentWidget()).iCurrentSelection == 0)
		{
			GetMgr().PlayBadSound();
		}
		else if(m_iView == 1 && iOption == -1 && UIWidget_Spinner(m_kWidgetHelper.GetCurrentWidget()).iCurrentSelection == UIWidget_Spinner(m_kWidgetHelper.GetCurrentWidget()).arrValues.Length-1)
		{
			GetMgr().PlayBadSound();
		}
		else
		{
			m_kWidgetHelper.ProcessMouseEvent(iWidget, iOption);
		}
	}
	else if(InStr(args[args.Length-1], "cat") != -1)
	{
		GoToView(int(Split(args[args.Length-1], "cat", true)));
	}
	else if(args[args.Length-1] == "theConfirmButton")
	{
		OnAccept();
	}
	else
		bHandled = false;

	return bHandled;

}
function UpdateSelectionFromMouseCursor()
{
	local float fWidgetY, fClosest;
	local int iWidget, iClosest;

	if(manager.IsMouseActive())
	{
		if(controllerRef.m_Pres.m_kUIMouseCursor.m_v2MouseLoc.X < 480)
		{
			fClosest = 999;
			for(iWidget=0; iWidget < SelfGfx().m_iNumOptions; iWidget++)
			{
				fWidgetY = SelfGfx().m_gfxOptionsList.AS_GetItemAt(iWidget).GetFloat("_ymouse");
				if(fWidgetY > 0 && fWidgetY < fClosest)
				{
					fClosest = fWidgetY;
					iClosest = iWidget;
				}
			}
			if(iClosest != m_kWidgetHelper.m_iCurrentWidget)
			{
				m_kWidgetHelper.SetSelected(iClosest);
				UpdateData();
			}
		}
	}
}
function OnUCancel()
{
	OnCancel();
}
function OnUAccept()
{
	OnAccept();
}
simulated function bool OnCancel(optional string strOption)
{
	if(m_iView == 1 && TrainingGuidelinesChanged())
	{
		ConfirmTrainingDialogue(true);
	}
	else
	{
		Exit();
	}
	return true;
}
function Exit()
{
	if(m_kSquadronMod.IsInState('State_HangarAirforceCommand'))
	{
		GetMgr().PlayCloseSound();
		Hide();
		m_kSquadronMod.PopState();
	}
}
function bool CanAffordUpgrades()
{
	return GetMgr().HQ().GetResource(eResource_Money) >= (m_iUpgradeFacilitiesCost + m_iUpgradeProgramsCost + m_iUpgradeStaffCost);
}
simulated function bool OnAccept(optional string strOption)
{
	if(m_iView == 1 && TrainingGuidelinesChanged())
	{
		if(!CanAffordUpgrades())
		{
			GetMgr().PlayBadSound();
		}
		else
		{
			GetMgr().PlaySmallOpenSound();
			ConfirmTrainingDialogue();
		}
	}
	else if(m_iView == 0 && !BeDefaultCombatTactics())
	{
		ConfirmResetTacticsDialogue();
	}
	return true;
}
function GoToView(int iNewView)
{
	if(m_iView != iNewView)
	{
		m_iView = iNewView;
		UpdateLayout();
	}
	UpdateData();
}
function UpdateLayout(optional int iView=m_iView)
{
	AS_UpdateLayout(iView);
	AS_SetSelectedCategory(iView);
	AS_SetLabels(m_strAirforceCommand, "", "");
	if(iView == 0)
	{
		AS_UpdateInfo(m_strCombatTacticsTitle,"","", m_strCombatTacticsImgPath);
		class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_CombatTacticsManagement);
	}
	else if(iView == 1)
	{
		AS_UpdateInfo(m_strTrainingGuidelinesTitle,"","", m_strTrainingGuidelinesImgPth); 
		class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_TrainingCenterManagement);
	}
	UpdateWidgets();
	UpdateConfirmButton();
}
function UpdateWidgets()
{
	local UIWidget_Spinner kSpinner;
	local UIWidget_Checkbox kCheckbox;
	local int i, iMin, iMax, iColor;

	switch(m_iView)
	{
	case 0:
		m_kWidgetHelper.Clear();
		//tactic spinner
		kSpinner = m_kWidgetHelper.NewSpinner();
		kSpinner.strTitle = m_strSelectTacticLabel;
		kSpinner.arrValues.AddItem(0);
		kSpinner.arrValues.AddItem(1);
		kSpinner.arrValues.AddItem(2);
		kSpinner.arrLabels.AddItem(class'SquadronUnleashed'.default.m_strStanceBAL);
		kSpinner.arrLabels.AddItem(class'SquadronUnleashed'.default.m_strStanceAGG);
		kSpinner.arrLabels.AddItem(class'SquadronUnleashed'.default.m_strStanceDEF);
		kSpinner.del_OnValueChanged = UpdateSelectedTactic;
		kSpinner.iCurrentSelection = 0;

		//auto close checkbox
		kCheckbox =	m_kWidgetHelper.NewCheckbox(0);
		kCheckbox.strTitle = m_strAutoCloseDistanceLabel;
		kCheckbox.bChecked = m_kSquadronMod.m_kPilotQuarters.GetTactic(0).bStartClose;
		kCheckbox.del_OnValueChanged = UpdateCombatTactics;
				
		//auto back-off spinner
		kSpinner = m_kWidgetHelper.NewSpinner();
		kSpinner.strTitle = class'UIUtilities'.static.GetHTMLColoredText(m_strAutoBackOffThresholdLabel, eUIState_Normal, 18);
		for(i=0; i <=100; ++i)
		{
			kSpinner.arrValues.AddItem(i);
			kSpinner.arrLabels.AddItem(i $"%");
		}
		kSpinner.iCurrentSelection = Round(m_kSquadronMod.m_kPilotQuarters.GetTactic(0).fAutoBackOffHP * 100.0f);
		kSpinner.del_OnValueChanged = UpdateCombatTactics;

		//auto abort spinner
		kSpinner = m_kWidgetHelper.NewSpinner();
		kSpinner.strTitle = class'UIUtilities'.static.GetHTMLColoredText(m_strAutoAbortThresholdLabel, eUIState_Normal, 18);
		for(i=0; i <=100; ++i)
		{
			kSpinner.arrValues.AddItem(i);
			kSpinner.arrLabels.AddItem(i $"%");
		}
		kSpinner.iCurrentSelection = Round(m_kSquadronMod.m_kPilotQuarters.GetTactic(0).fAutoAbortHP * 100.0f);
		kSpinner.del_OnValueChanged = UpdateCombatTactics;
		break;
	case 1:
		m_kWidgetHelper.Clear();
		//training programs spinner
		kSpinner = m_kWidgetHelper.NewSpinner();
		kSpinner.strTitle = class'UIUtilities'.static.GetHTMLColoredText(m_strTrainingProgramsLabel, eUIState_Normal, 18);
		iMin = m_kSquadronMod.m_kPilotTrainingCenter.GetMinTrainingProgramsLvl();
		iMax = m_kSquadronMod.m_kPilotTrainingCenter.m_arrTrainingProgramsLvl.Length;
		for(i=iMin; i < iMax; ++i)
		{
			kSpinner.arrValues.AddItem(i);
			iColor = i == m_kSquadronMod.m_kPilotTrainingCenter.m_iPendingProgramsLvl ? eUIState_Warning : eUIState_Good;
			kSpinner.arrLabels.AddItem(class'UIUtilities'.static.GetHTMLColoredText(m_strLevel @ i, i == m_kSquadronMod.m_kPilotTrainingCenter.m_iTrainingProgramsLvl ? eUIState_Normal : iColor, iColor == eUIState_Normal ? 18 : 20));
		}
		kSpinner.iCurrentSelection = kSpinner.arrValues.Find(m_kSquadronMod.m_kPilotTrainingCenter.m_iPendingProgramsLvl);
		kSpinner.del_OnValueChanged = UpdateTrainingGuidelines;

		//training facilities spinner
		kSpinner = m_kWidgetHelper.NewSpinner();
		kSpinner.strTitle = class'UIUtilities'.static.GetHTMLColoredText(m_strTrainingFacilitiesLabel, eUIState_Normal, 18);
		iMin = m_kSquadronMod.m_kPilotTrainingCenter.GetMinFacilitiesLvl();
		iMax = m_kSquadronMod.m_kPilotTrainingCenter.m_arrTrainingFacilitiesLvl.Length;
		for(i=iMin; i < iMax; ++i)
		{
			kSpinner.arrValues.AddItem(i);
			iColor = i == m_kSquadronMod.m_kPilotTrainingCenter.m_iPendingFacilitiesLvl ? eUIState_Warning : eUIState_Good;
			kSpinner.arrLabels.AddItem(class'UIUtilities'.static.GetHTMLColoredText(m_strLevel @ i, i == m_kSquadronMod.m_kPilotTrainingCenter.m_iFacilitiesLvl ? eUIState_Normal : iColor, iColor == eUIState_Normal ? 18 : 20));

		}
		kSpinner.iCurrentSelection = kSpinner.arrValues.Find(m_kSquadronMod.m_kPilotTrainingCenter.m_iPendingFacilitiesLvl);
		kSpinner.del_OnValueChanged = UpdateTrainingGuidelines;

		//training staff spinner
		kSpinner = m_kWidgetHelper.NewSpinner();
		kSpinner.strTitle = class'UIUtilities'.static.GetHTMLColoredText(m_strTrainingStaffLabel, eUIState_Normal, 18);
		iMin = m_kSquadronMod.m_kPilotTrainingCenter.GetMinStaffLvl();
		iMax = m_kSquadronMod.m_kPilotTrainingCenter.m_arrTrainingStaffLvl.Length;
		for(i=iMin; i < iMax; ++i)
		{
			kSpinner.arrValues.AddItem(i);
			iColor = i == m_kSquadronMod.m_kPilotTrainingCenter.m_iPendingStaffLevel ? eUIState_Warning : eUIState_Good;
			kSpinner.arrLabels.AddItem(class'UIUtilities'.static.GetHTMLColoredText(m_strLevel @ i, i == m_kSquadronMod.m_kPilotTrainingCenter.m_iStaffLevel ? eUIState_Normal : iColor, iColor == eUIState_Normal ? 18 : 20));
		}
		kSpinner.iCurrentSelection = kSpinner.arrValues.Find(m_kSquadronMod.m_kPilotTrainingCenter.m_iPendingStaffLevel);
		kSpinner.del_OnValueChanged = UpdateTrainingGuidelines;
	}
	SetTimer(0.10, false, 'RefreshWidgets');
}
function RefreshWidgets()
{
	m_kWidgetHelper.RefreshAllWidgets();
	if(m_iView == 0)
	{
		UIModGfxTextField(SelfGfx().m_gfxOptionsList.AS_GetItemAt(1).GetObject("displayLabelField", class'UIModGfxTextField')).SetHTMLText("<p align='right'>"$class'UIUtilities'.static.GetHTMLColoredText(m_strAutoCloseDistanceLabel, eUIState_Normal, 20)$"</p>");
	}
}
function UpdateData()
{
	switch(m_iView)
	{
	case 0:
		UpdateSelectedTactic();
		UpdateCombatTacticsInfo();
		UpdateConfirmButton();
		break;
	case 1:
		UpdateTrainingGuidelines();
	}
}
function UpdateSelectedTactic()
{
	local int iSelectedTactic;

	iSelectedTactic = m_kWidgetHelper.GetCurrentValue(0);
	UIWidget_Checkbox(m_kWidgetHelper.GetWidget(1)).bChecked = m_kSquadronMod.m_kPilotQuarters.GetTactic(iSelectedTactic).bStartClose;
	UIWidget_Spinner(m_kWidgetHelper.GetWidget(2)).iCurrentSelection = Round(m_kSquadronMod.m_kPilotQuarters.GetTactic(iSelectedTactic).fAutoBackOffHP * 100.0);
	UIWidget_Spinner(m_kWidgetHelper.GetWidget(3)).iCurrentSelection = Round(m_kSquadronMod.m_kPilotQuarters.GetTactic(iSelectedTactic).fAutoAbortHP * 100.0);
	RefreshWidgets();
	UpdateConfirmButton();
}
function UpdateCombatTactics()
{
	local int iTactic, iAutoAbortHP, iAutoBackOffHP;

	iTactic = m_kWidgetHelper.GetCurrentValue(0);
	iAutoBackOffHP = m_kWidgetHelper.GetCurrentValue(2);
	iAutoAbortHP = m_kWidgetHelper.GetCurrentValue(3);

	m_kSquadronMod.m_kPilotQuarters.m_arrTactics[iTactic].bStartClose = UIWidget_Checkbox(m_kWidgetHelper.GetWidget(1)).bChecked;
	m_kSquadronMod.m_kPilotQuarters.m_arrTactics[iTactic].fAutoBackOffHP = float(iAutoBackOffHP) / 100.0;
	m_kSquadronMod.m_kPilotQuarters.m_arrTactics[iTactic].fAutoAbortHP = float(iAutoAbortHP) / 100.0;
	UpdateCombatTacticsInfo();
	UpdateConfirmButton();
}

function UpdateCombatTacticsInfo()
{
	local string strHelp;
	local XGParamTag kTag;
	local int iTactic;

	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
	iTactic = m_kWidgetHelper.GetCurrentValue(0);

	switch(m_kWidgetHelper.m_iCurrentWidget)
	{
	case 0:
		strHelp = m_strSelectTacticHelp;
		break;
	case 1:
		strHelp = m_strAutoCloseDistanceDescription;
		break;
	case 2:
		kTag.IntValue0 = Round(m_kSquadronMod.m_kPilotQuarters.GetTactic(iTactic).fAutoBackOffHP * 100.0f);
		strHelp = class'XComLocalizer'.static.ExpandString(m_strAutoBackOffDescription);
		break;
	case 3:
		kTag.IntValue0 = Round(m_kSquadronMod.m_kPilotQuarters.GetTactic(iTactic).fAutoAbortHP * 100.0f);
		strHelp = class'XComLocalizer'.static.ExpandString(m_strAutoAbortDescription);
	}
	AS_SetInfo(strHelp);
	if(m_kWidgetHelper.m_iCurrentWidget == 1)
	{
		UIModGfxTextField(SelfGfx().m_gfxOptionsList.AS_GetItemAt(1).GetObject("displayLabelField", class'UIModGfxTextField')).SetHTMLText("<p align='right'>"$class'UIUtilities'.static.GetHTMLColoredText(m_strAutoCloseDistanceLabel, eUIState_Normal, 20)$"</p>");
	}
}
function UpdateTrainingGuidelines()
{
	local SU_PilotTrainingCentre kTC;

	kTC = m_kSquadronMod.m_kPilotTrainingCenter;
	m_iUpgradeProgramsCost = Max(0, kTC.GetTrainingProgramsUnlockCost(m_kWidgetHelper.GetCurrentValue(0)) - kTC.m_iTotalTrainingInvestment);
	m_iUpgradeFacilitiesCost = Max(0, kTC.GetFacilitiesUnlockCost(m_kWidgetHelper.GetCurrentValue(1)) - kTC.m_iTotalFacilitieslInvestment);
	m_iUpgradeStaffCost = Max(0, kTC.GetStaffUnlockCost(m_kWidgetHelper.GetCurrentValue(2)) - kTC.m_iTotalStaffInvestment);
	UpdateTrainingInfo();
	UpdateConfirmButton();
}
function UpdateTrainingInfo()
{
	local string strInfo, strHelp;
	local int iColor, iCycleXP, iXPLimit, iCycleDays, iCapacity, iMonthlyCost, iUpgradeCost;
	local int iNewCycleXP, iNewXPLimit, iNewCycleDays, iNewCapacity, iNewMonthlyCost;
	local SU_PilotTrainingCentre kTC;
	
	switch(m_kWidgetHelper.m_iCurrentWidget)
	{
	case 0:
		strHelp=m_strTrainingProgramsHelp;
		break;
	case 1:
		strHelp=m_strTrainingFacilitiesHelp;
		break;
	case 2:
		strHelp=m_strTrainingStaffHelp;
	}
	strHelp = class'UIUtilities'.static.GetHTMLColoredText(strHelp, eUIState_Normal, 18);

	kTC = m_kSquadronMod.m_kPilotTrainingCenter;
	iCycleXP =      kTC.GetTrainingCycleXPBonus(kTC.m_iPendingProgramsLvl);
	iNewCycleXP =   kTC.GetTrainingCycleXPBonus(m_kWidgetHelper.GetCurrentValue(0));
	iCycleDays =    kTC.GetTrainingCycleDurationDays(kTC.m_iPendingProgramsLvl);
	iNewCycleDays = kTC.GetTrainingCycleDurationDays(m_kWidgetHelper.GetCurrentValue(0));
	iCapacity =     kTC.GetCapacity(kTC.m_iPendingFacilitiesLvl);
	iNewCapacity =  kTC.GetCapacity(m_kWidgetHelper.GetCurrentValue(1));
	iXPLimit =      kTC.GetXPLimit(kTC.m_iPendingStaffLevel);
	iNewXPLimit =   kTC.GetXPLimit(m_kWidgetHelper.GetCurrentValue(2));
	iMonthlyCost= kTC.GetTotalMonthlyCost();
	iNewMonthlyCost =  kTC.GetTotalMonthlyCost(m_kWidgetHelper.GetCurrentValue(0), m_kWidgetHelper.GetCurrentValue(1), m_kWidgetHelper.GetCurrentValue(2));
	iUpgradeCost = m_iUpgradeProgramsCost + m_iUpgradeFacilitiesCost + m_iUpgradeStaffCost;

	iColor = iCycleXP != kTC.GetTrainingCycleXPBonus() ? eUIState_Warning : eUIState_Normal;
	strInfo = class'UIUtilities'.static.GetHTMLColoredText(m_strTrainingXPBonus @ (kTC.GetTrainingCycleXPBonus() != iCycleXP ? "+"$kTC.GetTrainingCycleXPBonus() @ "-> " : "") $ "+"$iNewCycleXP, iNewCycleXP != iCycleXP ? eUIState_Good : iColor, 20);
	strInfo $= "\n";

	iColor = iCycleDays != kTC.GetTrainingCycleDurationDays() ? eUIState_Warning : eUIState_Normal;
	strInfo $= class'UIUtilities'.static.GetHTMLColoredText(m_strTrainingDuration @ (kTC.GetTrainingCycleDurationDays() != iCycleDays ? kTC.GetTrainingCycleDurationDays() @ "-> " : "") $iNewCycleDays @ class'UIUtilities'.default.m_strDays, iNewCycleDays != iCycleDays ? eUIState_Good : iColor, 20);
	strInfo $= "\n";

	iColor = iXPLimit != kTC.GetXPLimit() ? eUIState_Warning : eUIState_Normal;
	strInfo $= class'UIUtilities'.static.GetHTMLColoredText(m_strTrainingXPLimit @ (kTC.GetXPLimit() != iXPLimit ? kTC.GetXPLimit() @ "-> " : "") $iNewXPLimit, iNewXPLimit != iXPLimit ? eUIState_Good : iColor, 20);
	strInfo $= "\n";

	iColor = iCapacity != kTC.GetCapacity() ? eUIState_Warning : eUIState_Normal;
	strInfo $= class'UIUtilities'.static.GetHTMLColoredText(m_strTrainingCapacity @  (kTC.GetCapacity() != iCapacity? kTC.GetCapacity() @ "-> " : "") $iNewCapacity, iNewCapacity != iCapacity ? eUIState_Good : iColor, 20);
	strInfo $= "\n\n";

	iColor = iMonthlyCost != kTC.GetTotalMonthlyCost(kTC.m_iTrainingProgramsLvl, kTC.m_iFacilitiesLvl, kTC.m_iStaffLevel) ? eUIState_Warning : eUIState_Normal;
	strInfo $= class'UIUtilities'.static.GetHTMLColoredText(CAPS(class'XGHangarUI'.default.m_strLabelHireMonthlyCost) @ (iNewMonthlyCost != iMonthlyCost ? class'XGScreenMgr'.static.ConvertCashToString(iMonthlyCost) @ "-> " : "") $class'XGScreenMgr'.static.ConvertCashToString(iNewMonthlyCost), iNewMonthlyCost != iMonthlyCost ? eUIState_Warning : iColor, 20);

	AS_UpdateInfo(m_strTrainingGuidelinesTitle, strInfo, strHelp, m_strTrainingGuidelinesImgPth); 

	if(iUpgradeCost != 0)
	{
		SelfGfx().m_gfxQuantityField.m_sFontColor =	CanAffordUpgrades() ? "0xFF"$class'UIUtilities'.const.GOOD_HTML_COLOR : "0xFF"$class'UIUtilities'.const.BAD_HTML_COLOR;
		AS_SetLabels(m_strAirforceCommand, class'XGCyberneticsUI'.default.m_strUpgradeCostLabel, class'XGScreenMgr'.static.ConvertCashToString(iUpgradeCost));
	}
	else
	{
		AS_SetLabels(m_strAirforceCommand, "", "");
	}
}
function bool TrainingGuidelinesChanged()
{
	local bool bProgramsChanged, bFacilChanged, bStaffChanged;
	local SU_PilotTrainingCentre kTrainCenter;

	kTrainCenter = m_kSquadronMod.m_kPilotTrainingCenter;
	bProgramsChanged= kTrainCenter.m_iPendingProgramsLvl != m_kWidgetHelper.GetCurrentValue(0);
	bFacilChanged   = kTrainCenter.m_iPendingFacilitiesLvl != m_kWidgetHelper.GetCurrentValue(1);
	bStaffChanged   = kTrainCenter.m_iPendingStaffLevel != m_kWidgetHelper.GetCurrentValue(2);

	return bProgramsChanged || bFacilChanged || bStaffChanged;
}
function bool BeDefaultCombatTactics()
{
	local bool bDefault;

	bDefault = m_kSquadronMod.m_kPilotQuarters.m_arrTactics[0].bStartClose == class'SquadronUnleashed'.default.BAL_TACTIC_START_CLOSE;
	bDefault = bDefault && m_kSquadronMod.m_kPilotQuarters.m_arrTactics[1].bStartClose == class'SquadronUnleashed'.default.AGG_TACTIC_START_CLOSE;
	bDefault = bDefault && m_kSquadronMod.m_kPilotQuarters.m_arrTactics[2].bStartClose == class'SquadronUnleashed'.default.DEF_TACTIC_START_CLOSE;
	bDefault = bDefault && Round(m_kSquadronMod.m_kPilotQuarters.m_arrTactics[0].fAutoAbortHP * 100.0) == Round(class'SquadronUnleashed'.default.BAL_TACTIC_AUTOABORT_HP_PCT * 100.0);
	bDefault = bDefault && Round(m_kSquadronMod.m_kPilotQuarters.m_arrTactics[1].fAutoAbortHP * 100.0) == Round(class'SquadronUnleashed'.default.AGG_TACTIC_AUTOABORT_HP_PCT * 100.0);
	bDefault = bDefault && Round(m_kSquadronMod.m_kPilotQuarters.m_arrTactics[2].fAutoAbortHP * 100.0) == Round(class'SquadronUnleashed'.default.DEF_TACTIC_AUTOABORT_HP_PCT * 100.0);
	bDefault = bDefault && Round(m_kSquadronMod.m_kPilotQuarters.m_arrTactics[0].fAutoBackOffHP * 100.0) == Round(class'SquadronUnleashed'.default.BAL_TACTIC_AUTOBACKOFF_HP_PCT * 100.0);
	bDefault = bDefault && Round(m_kSquadronMod.m_kPilotQuarters.m_arrTactics[1].fAutoBackOffHP * 100.0) == Round(class'SquadronUnleashed'.default.AGG_TACTIC_AUTOBACKOFF_HP_PCT * 100.0);
	bDefault = bDefault && Round(m_kSquadronMod.m_kPilotQuarters.m_arrTactics[2].fAutoBackOffHP * 100.0) == Round(class'SquadronUnleashed'.default.DEF_TACTIC_AUTOBACKOFF_HP_PCT * 100.0);

	return bDefault;
}
function UpdateConfirmButton()
{
	if(m_iView == 1 && TrainingGuidelinesChanged())
	{
		AS_SetConfirmButton("<p align='center'>"$ (manager.IsMouseActive() ? "" : class'UI_FxsGamepadIcons'.static.HTML("Icon_A_X", 20, -4) $"  ") $class'UIUtilities'.default.m_strGenericConfirm $"</p>");
	}
	else if(m_iView == 0 && !BeDefaultCombatTactics())
	{
		AS_SetConfirmButton("<p align='center'>"$ (manager.IsMouseActive() ? "" : class'UI_FxsGamepadIcons'.static.HTML("Icon_Y_TRIANGLE", 20, -4) $"  ") $class'UIOptionsPCScreen'.default.m_strResetAllSettings $"</p>");
	}
	else
	{
		AS_SetConfirmButton("");
	}
}
function ApplyNewTrainingGuidelines()
{
	local SU_PilotTrainingCentre kTrainCenter;

	kTrainCenter = m_kSquadronMod.m_kPilotTrainingCenter;
	
	kTrainCenter.HQ().AddResource(eResource_Money, -m_iUpgradeProgramsCost);
	kTrainCenter.m_iTotalTrainingInvestment += m_iUpgradeProgramsCost;
	kTrainCenter.m_iPendingProgramsLvl = m_kWidgetHelper.GetCurrentValue(0);

	kTrainCenter.HQ().AddResource(eResource_Money, -m_iUpgradeFacilitiesCost);
	kTrainCenter.m_iTotalFacilitieslInvestment += m_iUpgradeFacilitiesCost;
	kTrainCenter.m_iPendingFacilitiesLvl = m_kWidgetHelper.GetCurrentValue(1);

	kTrainCenter.HQ().AddResource(eResource_Money, -m_iUpgradeStaffCost);
	kTrainCenter.m_iTotalStaffInvestment += m_iUpgradeStaffCost;
	kTrainCenter.m_iPendingStaffLevel = m_kWidgetHelper.GetCurrentValue(2);

	kTrainCenter.UpdateHangarMaintenanceCost();
	kTrainCenter.PRES().GetStrategyHUD().UpdateDefaultResources();
}
function ConfirmResetTacticsDialogue()
{
	local TDialogueBoxData tData;

	tData.eType = eDialog_Normal;
	tData.strTitle = Localize("UIKeybindingsPCScreen", "m_strConfirmResetBindingsDialogTitle", "XComGame");
	tData.strText = Localize("UIOptionsPCScreen", "m_strWantToResetToDefaults", "XComGame");
	tData.strAccept = class'UIUtilities'.default.m_strGenericConfirm;
	tData.strCancel = class'UIUtilities'.default.m_strGenericCancel;
	tData.fnCallback = OnConfirmResetTatcics;
	controllerRef.m_Pres.UIRaiseDialog(tData);
}
function OnConfirmResetTatcics(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		GetMgr().PlayGoodSound();
		m_kSquadronMod.m_kPilotQuarters.InitTactics(true);
		UpdateData();
	}
	else
	{
		GetMgr().PlaySmallCloseSound();
	}
}
function ConfirmTrainingDialogue(optional bool bDiscardDialog)
{
	local TDialogueBoxData tData;

	if(bDiscardDialog)
	{
		tData.eType = eDialog_Warning;
		tData.strTitle = Localize("UIKeybindingsPCScreen", "m_strConfirmDiscardChangesTitle", "XComGame");
		tData.strText = Localize("UIOptionsPCScreen", "m_strIgnoreChangesDialogue", "XComGame");
		tData.strAccept = Localize("UIKeybindingsPCScreen", "m_strConfirmDiscardChangesAcceptButton", "XComGame");
		tData.strCancel = Localize("UIKeybindingsPCScreen", "m_strConfirmDiscardChangesCancelButton", "XComGame");
		tData.fnCallback = OnDiscardAndExit;
	}
	else
	{
		tData.eType = eDialog_Normal;
		tData.strTitle = m_strConfirmNewTrainingGuidelinesTitle;
		tData.strText = m_strConfirmNewTrainingGuidelinesDialog;
		tData.strAccept = class'UIUtilities'.default.m_strGenericConfirm;
		tData.strCancel = class'UIUtilities'.default.m_strGenericCancel;
		tData.fnCallback = OnNewTrainingConfirmed;
	}
	controllerRef.m_Pres.UIRaiseDialog(tData);
}
function OnNewTrainingConfirmed(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		GetMgr().PlayGoodSound();
		ApplyNewTrainingGuidelines();
		UpdateWidgets();
		UpdateData();
	}
	else
	{
		GetMgr().PlaySmallCloseSound();
	}
}
function OnDiscardAndExit(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		GetMgr().PlayCloseSound();
		Exit();
	}
	else
	{
		GetMgr().PlaySmallCloseSound();
	}
}
//-----------------
//AS helpers
//-----------------
function AS_UpdateLayout(optional int iSelectedCategory=m_iView)
{
	SelfGfx().UpdateLayout(iSelectedCategory);
}
function AS_SetSelectedCategory(int iSelectedCategoryIndex)
{
	SelfGfx().SetCategoryFocus(iSelectedCategoryIndex);
//    manager.ActionScriptVoid(string(screen.GetMCPath()) $ ".SetSelectedCategory");
}

/**@param iState 1-disabled, 5-enabled*/
function AS_SetTabState(int iIndex, int iState)
{
	SelfGfx().GetObject("cat"$iIndex).SetVisible(iState != 1);
    manager.ActionScriptVoid(string(screen.GetMCPath()) $ ".SetTabState");
}

function AS_SetLabels(string displayString, string itemLabel, string quantityLabel)
{
	SelfGfx().m_gfxTitleField.SetHTMLText(displayString);
	SelfGfx().m_gfxItemField.SetHTMLText(itemLabel);
	SelfGfx().m_gfxQuantityField.SetHTMLText(quantityLabel);
//    manager.ActionScriptVoid(string(screen.GetMCPath()) $ ".SetLabels");
}
function AS_AddOption(int iIndex, string sLabel, bool IsDisabled, int iQuantity)
{
    manager.ActionScriptVoid(string(GetMCPath()) $ ".AddOption");
}
/**@param strType List of types: XComCheckbox, XComSpinner, XComSlider, XComButton, XComCombobox.*/
function GfxObject AS_AddWidget(string strType)
{
	return SelfGfx().NewWidget(strType);
}
function AS_UpdateInfo(string techName, string infoText, string descText, string imgPath)
{
    manager.ActionScriptVoid(string(GetMCPath()) $ ".UpdateInfo");
}

function AS_SetFocus(string Id)
{
    manager.ActionScriptVoid(string(GetMCPath()) $ ".SetFocus");
}

function AS_SetConfirmButton(string Desc)
{
    manager.ActionScriptVoid(string(GetMCPath()) $ ".SetConfirmButton");
	UIModGfxTextField(SelfGfx().GetObject("theConfirmButton").GetObject("tf", class'UIModGfxTextField')).SetHTMLText(Desc);
}
function SUGfx_AirforceCommand SelfGfx()
{
	if(m_gfxScreen == none)
	{
		m_gfxScreen = SUGfx_AirforceCommand(manager.GetVariableObject(string(GetMCPath()), class'SUGfx_AirforceCommand'));
	}
	return m_gfxScreen;
}
function AS_SetInfo(string sInfo)
{
	SelfGfx().m_gfxInfoField.SetHTMLText(sInfo);
}
DefaultProperties
{
	m_iView = -1
	s_package="/ package/gfxBuildItem/BuildItem"
	s_screenId="gfxBuildItem"
	e_InputState=eInputState_Evaluate
	s_name="theBuildScreen"
	m_fMouseUpdateStepSq=25.0
}