class SU_UIStrategyHUD_FSM_Hangar extends UIStrategyHUD_FSM_Hangar;

var int m_iOptionPilotRoster;
var int m_iOptionAirforceCommand;
var int m_iOptionTrainingCenter;
var localized string m_strViewPilotsLabel;
var localized string m_strViewPilotsHelp;
var localized string m_strAirforceCommandLabel;
var localized string m_strAirforceCommandHelp;
var localized string m_strTrainingCenterLabel;
var localized string m_strTrainingCenterHelp;

simulated function XGHangarUI GetMgr(optional int iStartView=-1)
{
	return SU_XGHangarUI(XComHQPresentationLayer(controllerRef.m_Pres).GetMgr(class'SU_XGHangarUI', (self), iStartView));
}
simulated function OnInit()
{
	super(UI_FxsPanel).OnInit();
	ExtendMenuOptions();
	m_iCurrentSelection = -1;
}
function ExtendMenuOptions()
{
	GetMgr().UpdateMain();
	CreateMenuOptions(GetMgr().m_kMainMenu.mnuOptions);
}
simulated function bool OnMouseEvent(int Cmd, array<string> args)
{
	local bool bHandled;

	m_iCurrentSelection = int(Split(args[args.Length - 1], "option", true));
	if(m_iCurrentSelection < XComHQPresentationLayer(controllerRef.m_Pres).m_kSubMenu.m_arrUIOptions.Length)
	{
		return XComHQPresentationLayer(controllerRef.m_Pres).m_kSubMenu.OnMouseEvent(Cmd, args);
	}
	else
	{
		bHandled = true;
		RealizeSelected();
		switch(Cmd)
		{
			case 391:
				OnAccept();
				GetMgr().PlayScrollSound();
				break;
			default:
				bHandled = false;
		}
		return bHandled;
	}
}
simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
	return super(UIStrategyHUD_FacilitySubMenu).OnUnrealCommand(Cmd, Arg);	
}
simulated function OnReceiveFocus()
{
	UIStrategyHUD(screen).m_kMenu.m_kSubMenu.OnReceiveFocus();
	ExtendMenuOptions();
}
simulated function OnLoseFocus()
{
	UIStrategyHUD(screen).m_kMenu.m_kSubMenu.OnLoseFocus();
}
simulated function OnAccept()
{
	if(m_iCurrentSelection < XComHQPresentationLayer(controllerRef.m_Pres).m_kSubMenu.m_arrUIOptions.Length)
	{
		XComHQPresentationLayer(controllerRef.m_Pres).m_kSubMenu.OnAccept();
	}
	else if(m_iCurrentSelection == m_iOptionPilotRoster)
	{
		class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.Enter(0);//0 is just a dummy parameter
		UIPilotList();
	}
	else if(m_iCurrentSelection == m_iOptionAirforceCommand)
	{
		UIAirforceCommand();
	}
	else if(m_iCurrentSelection == m_iOptionTrainingCenter)
	{
		UIPilotTraining();
	}
}
function UIPilotList()
{
	OnLoseFocus();
	class'SU_Utils'.static.PRES().GetMgr(class'SU_XGHangarUI').GoToView(6);
	class'SU_Utils'.static.GetSquadronMod().PushState('State_HangarPilotRoster');
}
function UIAirforceCommand()
{
	GetMgr().PlayOpenSound();
	class'SU_Utils'.static.GetSquadronMod().PushState('State_HangarAirforceCommand');
}
function UIPilotTraining()
{
	GetMgr().PlayOpenSound();
	class'SU_Utils'.static.GetSquadronMod().PushState('State_HangarPilotTraining');
}
DefaultProperties
{
}