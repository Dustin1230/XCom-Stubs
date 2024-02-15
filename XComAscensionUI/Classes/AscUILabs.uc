class AscUILabs extends UI_FxsScreen;

var AscUILabs_ProjectList m_kProjectList;
var bool m_bListHasFocus;
var int m_iCurrentSelection;
var int m_iToggleListButtonID;
var Color COLOR_GREEN;
var Color COLOR_RED;
var Color COLOR_CYAN;
var Color COLOR_YELLOW;
var Color COLOR_ORANGE;
var string m_strExpandProjectList;
var string m_strContractProjectList;

simulated function PanelInit(XComPlayerController _controller, UIFxsMovie _manager, UI_FxsScreen _screen, optional delegate<OnCommandCallback> CommandFunction)
{
	//just base initialization; no AddPanel or LoadScreen (the content will be created dynamically)
	controllerRef = _controller;
	manager = _manager;
	screen = _screen;//this is disposable (relevant to UI_FxsPanel which needs _screen parent)
	m_fnOnCommand = (CommandFunction != none ? CommandFunction : _screen.OnCommand);
	b_IsInitialized = true;
	SetInputState(eInputState_Evaluate);
	class'UIModUtils'.static.MakeScreenFirstToReceiveIpunt(self); //relevant to OnUnrealCommand 
	OnInit();
}
simulated function OnInit()
{
	//this function is subject to FlashRaiseInit call and requires corresponding s_name which is lacking here
	//it must be called manually if ever required for any reason
	m_kProjectList = Spawn(class'AscUILabs_ProjectList');
	m_kProjectList.PopulateGfxContainer(OnEditButtonClick, "Icon_X_SQUARE");
	m_kProjectList.ToggleVisibility(false);
	UpdateButtonHelp();
}
function AscUILabs_ProjectList GetListGfx()
{
	return m_kProjectList;
}
function UpdateSelectionFromMouseCursor()
{
	m_iCurrentSelection = GetListGfx().UpdateSelectionFromMouseCursor();
}
function OnEditButtonClick()
{
	//just a testing code
	if(manager.IsMouseActive() && InStr(GetScriptTrace(), "OnUnrealCommand") < 0)
	{
		m_iCurrentSelection = GetListGfx().UpdateSelectionFromMouseCursor();
	}
	GetListGfx().m_arrGfxProjects[m_iCurrentSelection].AS_SetResearchProgress("", "DummyProject"$m_iCurrentSelection, "Y Days", FRand());
}
//OnUnrealCommand is passed through all screens (not panels) until it returns "true"
//this screen is on top of UIScienceLabs which is on top of UIStrategyHUD - so they are next in queue
//check UI_FxsInput class (XComGame.upk) for possible Cmd codes
simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
    local bool bHandled;

    if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg)) //this filters ActionMask (that is Arg) to only pass button release event (good for performance)
    {
        return false;
    }
	if(Cmd != 571 && Cmd != 333 && !m_bListHasFocus)
	{
		return false;
	}
    switch(Cmd)
    {
    case 500:
    case 350:
    case 370:
		if(++m_iCurrentSelection > GetListGfx().m_iNumListedProjects-1)
		{
			m_iCurrentSelection = 0;
		}
		GetListGfx().RealizeSelected(m_iCurrentSelection);
		bHandled=true;
		break;
    case 502:
    case 354:
    case 371:
		if(--m_iCurrentSelection < 0)
		{
			m_iCurrentSelection = Max(0, GetListGfx().m_iNumListedProjects-1);
		}
		GetListGfx().RealizeSelected(m_iCurrentSelection);
		bHandled=true;
		break;
	case 511:
	case 302:
		if(m_bListHasFocus)
		{
			OnEditButtonClick();
		}
		bHandled=true;
		break;
	case 571:
	case 333:
		ToggleProjectList();
	default:
		bHandled=false;
    }
	return bHandled;
}
function UpdateButtonHelp()
{
	local UINavigationHelp kHelpBar;
	local UIModGfxButton gfxButton;

	kHelpBar = XComHQPresentationLayer(controllerRef.m_Pres).m_kStrategyHUD.m_kHelpBar;
	if(!kHelpBar.HasDelegate(ToggleProjectList))
	{
		XComHQPresentationLayer(controllerRef.m_Pres).m_kStrategyHUD.m_kHelpBar.AddRightHelp(m_strExpandProjectList, "Icon_RT_R2", ToggleProjectList, false);
		m_iToggleListButtonID = kHelpBar.m_arrButtonClickDelegates.Find(ToggleProjectList);
	}
	gfxButton = UIModGfxButton(manager.GetVariableObject(kHelpBar.GetMCPath() $ ".rightContainer.itemRoot.buttonHelp_" $ m_iToggleListButtonID, class'UIModGfxButton'));
	gfxButton.AS_SetText(m_bListHasFocus ? m_strContractProjectList : m_strExpandProjectList);
}
function ToggleProjectList()
{
	m_bListHasFocus = !m_bListHasFocus;
	m_iCurrentSelection = (m_bListHasFocus ? 0 : -1);
	GetListGfx().RealizeSelected(m_iCurrentSelection);
	GetListGfx().ToggleVisibility(m_bListHasFocus);
	UpdateButtonHelp();
	if(m_bListHasFocus)
	{
		if(m_kProjectList.Base().GetFacility3DLocation(7) != vect(0.0,0.0,0.0))
		{
			XComHQPresentationLayer(controllerRef.m_Pres).GetCamera().StartRoomView('FreeMovement', 0.50);
			XComCamState_HQ_FreeMovement(XComHQPresentationLayer(controllerRef.m_Pres).GetCamera().CameraState).SetTargetFocus(m_kProjectList.Base().GetFacility3DLocation(7) + vect(480.0,0.0,480));
			XComCamState_HQ_FreeMovement(XComHQPresentationLayer(controllerRef.m_Pres).GetCamera().CameraState).SetViewDistance(1000.0);
		}
	}
	else
	{
		XComHQPresentationLayer(controllerRef.m_Pres).CAMLookAtFacility(m_kProjectList.LABS());
	}
}
function AS_AddProject(string strDescription, string strETA, float fPercentComplete=0.0, optional Color kProgressColor)
{
	GetListGfx().AS_AddProject(strDescription, strETA, fPercentComplete, kProgressColor);
}
DefaultProperties
{
	m_iCurrentSelection=-1
	COLOR_GREEN=(R=0,G=128,B=0)     //xcom green
	COLOR_RED=(R=238,G=28,B=37)     //xcom red
	COLOR_YELLOW=(R=255,G=208,B=56) //xcom yellow
	COLOR_ORANGE=(R=247,G=128,B=0)  //xcom orange(hyperwave)
	COLOR_CYAN=(R=103,G=232,B=237)  //xcom cyan
	m_strExpandProjectList="SHOW CURRENT RESEARCH"
	m_strContractProjectList="HIDE CURRENT RESEARCH"
}
