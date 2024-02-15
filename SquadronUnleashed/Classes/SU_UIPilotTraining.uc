class SU_UIPilotTraining extends UISoldierSlots;

var SquadronUnleashed m_kSquadronMod;
var localized string m_strAddPilot;
var localized string m_strRemovePilot;
var localized string m_strNameColumnHeader;
var localized string m_strBreakTrainingDialogTitle;
var localized string m_strBreakTrainingDialogText;

simulated function OnInit()
{
    super.OnInit();
	m_kSquadronMod = class'SU_Utils'.static.GetSquadronMod();
	AS_SetTitleLabels(m_strNameColumnHeader, m_strSoldierSlotBaseStatusLabel);
	UpdateDataFromGame(m_kSquadronMod.m_kPilotTrainingCenter.GetUITable());
//	SetInputState(eInputState_None);
	class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_FirstVisitTraining);
}
simulated function bool OnAccept(optional string strIndex)
{
	if(m_iCurrentSelection > m_arrUIOptions.Length-1)
	{
		m_kSquadronMod.UIAssignPilot(none);
	}
	else
	{
		RemovePilotDialogue();
	}
	return true;
}
simulated function bool OnCancel(optional string strOption)
{
	if(class'SU_Utils'.static.GetSquadronMod().IsInState('State_HangarPilotTraining'))
	{
		Hide();
		class'SU_Utils'.static.PlayCancelSound();
		class'SU_Utils'.static.GetSquadronMod().PopState();
		return true;
	}
	else
	{
		return false;
	}
}
simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateDataFromGame(m_kSquadronMod.m_kPilotTrainingCenter.GetUITable());
}
simulated function Hide()
{
	super.Hide();
	if(controllerRef.m_Pres.UIIsShowingDialog())
	{
//		controllerRef.m_Pres.m_kHUD.DialogBox.RemoveDialog();
	}
}
simulated function UpdateDataFromGame(TTableMenu kTable)
{
	local int i;

	super.UpdateDataFromGame(kTable);
	m_iNumAvailableSlots = m_kSquadronMod.m_kPilotTrainingCenter.GetCapacity();
	for(i=m_arrUIOptions.Length; i < m_iNumAvailableSlots; ++i)
	{
		AS_AddEmptySlot(class'XGGeneLabUI'.default.m_strLabelEmpty, m_strAddPilot);
	}
}
function RemovePilotDialogue()
{
	local TDialogueBoxData tDialog;
	local XGParamTag kTag;

	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));

	tDialog.eType = eDialog_Warning;
	tDialog.strTitle=m_strBreakTrainingDialogTitle;
	kTag.StrValue0 = m_arrUIOptions[m_iCurrentSelection].strName; 
	tDialog.strText= class'XComLocalizer'.static.ExpandString(m_strBreakTrainingDialogText);
	tDialog.strAccept=class'UIUtilities'.default.m_strGenericConfirm;
	tDialog.strCancel=class'UIUtilities'.default.m_strGenericCancel;
	tDialog.fnCallback=OnRemovePilotConfirm;
	XComHQPresentationLayer(controllerRef.m_Pres).UIRaiseDialog(tDialog);
}
function OnRemovePilotConfirm(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		class'SU_Utils'.static.PlaySelectSound();
		m_kSquadronMod.m_kPilotTrainingCenter.RemoveTrainee(m_kSquadronMod.m_kPilotTrainingCenter.m_arrTrainedPilots[m_iCurrentSelection].kPilot);
		UpdateDataFromGame(m_kSquadronMod.m_kPilotTrainingCenter.GetUITable());
	}
	else
	{
		class'SU_Utils'.static.PlayCancelSound();
	}
}
function TutorialMsgCallback(EUIAction eAction)
{
	SetInputState(eInputState_Evaluate);
	if(eAction == eUIAction_Cancel)
	{
		class'XGSaveHelper'.static.SetProfileStat("eSUHelp_FirstVisitTraining", 1);
	}
}
DefaultProperties
{
}
