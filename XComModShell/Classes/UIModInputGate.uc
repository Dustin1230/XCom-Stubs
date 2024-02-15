/** This is a template for a dummy helper-screen actor to be put on top of screens' stack 
 *  ...to hijack input events like OnMouseEvent and OnUnrealCommand.
 *  After spawning this actor you should call PanelInit passing GetALocalPlayerController() as _controller 
 *  ...and PRES().GetHUD() as _manager, whereas _screen can be "none".
 *  This actor does not need to be destroyed - it actually takes very little memory as it has no gfx layer. 
 *  Use .BringToTopOfScreenStack() when necessary and .PopFromScreenStack() when not required at the moment.
 *  Consider assigning _screen=... when a screen of interest is up.
 *  With such a setup you can check screen.IsA(...) to handle stuff differently for certain screens.*/
class UIModInputGate extends UI_FxsScreen;

var XComMutator m_kMutator;

delegate bool OnMouseEventDelegate(int Cmd, array<string> parsedArgs);
delegate bool OnUnrealCommandDelegate(int Cmd, int Arg);

function GateInit(UI_FxsPanel kPanel, optional delegate<OnMouseEventDelegate> delOnMouseEvent, optional delegate<OnUnrealCommandDelegate> delOnUnrealCommand, optional delegate<OnCommandCallback> CommandFunction)
{
	local UI_FxsScreen kScreen;

	kScreen = UI_FxsScreen(kPanel);
	if(kScreen == none)
	{
		kScreen = kPanel.screen;
	}
	if(kScreen != none)
	{
		PanelInit(kScreen.controllerRef, kScreen.manager, kScreen, CommandFunction);
	}
	else
	{
		PanelInit(XComPlayerController(GetALocalPlayerController()),XComPlayerController(GetALocalPlayerController()).m_Pres.GetHUD(), none, CommandFunction); 
	}
	OnMouseEventDelegate = delOnMouseEvent;
	OnUnrealCommandDelegate = delOnUnrealCommand;
}
simulated function PanelInit(XComPlayerController _controller, UIFxsMovie _manager, UI_FxsScreen _screen, optional delegate<OnCommandCallback> CommandFunction)
{
	//just base initialization; no AddPanel or LoadScreen - this is a dummy actor
	controllerRef = _controller;
	manager = _manager;
	if(_screen != none)
	{
		screen = _screen;
	}
	uicache = new (self) class'UICacheMgr';
	if(CommandFunction != none)
	   m_fnOnCommand = CommandFunction;
	b_IsInitialized = true;
	SetInputState(eInputState_Evaluate);
	
	//register the dummy-panel for input-checks:
	BringToTopOfScreenStack();
}
function BringToTopOfScreenStack()
{
	if(screen != none)
	{
		MCPath = screen.GetMCPath();
		screen.panels.RemoveItem(self);
		screen.panels.InsertItem(0, self);
	}
	XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetALocalPlayerController()).m_Pres.GetUIMgr().m_arrScreenInputStack.RemoveItem(self);
	XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetALocalPlayerController()).m_Pres.GetUIMgr().m_arrScreenInputStack.InsertItem(0,self);
}
/** This must be called directly - normally it's auto-called from state PanelInit_WaitForDependantVariablesToInit.*/
simulated function OnInit()
{
}
event Destroyed()
{
	PopFromScreenStack();
	super.Destroyed();
}
simulated function Remove()
{
	if(screen != none)
	{
		screen.panels.RemoveItem(self);
	}
	super.Remove();
}
function PopFromScreenStack()
{
	XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetALocalPlayerController()).m_Pres.GetUIMgr().PopFirstInstanceOfScreen(self);
	MCPath = default.MCPath;
	if(screen != none)
	{
		screen.panels.RemoveItem(self);
	}
}
/**Filters out CheckInputIsReleaseOrDirectionRepeat except "Tab key press" which is allowed for testing with keyboard*/
simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
	if(controllerRef.IsA('XComHeadquartersController') && !CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg) && !(Cmd == 571 && Arg == 32)) //let Tab sneak through, for tests
	{
		return false;
	}
	else if(OnUnrealCommandDelegate != none)
	{
		return OnUnrealCommandDelegate(Cmd, Arg);
	}
	//shape the code to your liking depending on screen.
	return false;
}
simulated function bool OnMouseEvent(int Cmd, array<string> args)
{
	if(OnMouseEventDelegate != none)
	{
		return OnMouseEventDelegate(Cmd, args);
	}
	else if(screen != none)
	{
		return screen.OnMouseEvent(Cmd, args);
	}
	return false;
}
DefaultProperties
{
}