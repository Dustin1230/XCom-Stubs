class UIHelpBar_MiniMods extends UI_FxsScreen;

var XComMutator m_kMutator;

simulated function PanelInit(XComPlayerController _controller, UIFxsMovie _manager, UI_FxsScreen _screen, optional delegate<OnCommandCallback> CommandFunction)
{
	//just base initialization; no AddPanel or LoadScreen - this is a dummy actor
	controllerRef = _controller;
	manager = _manager;
	screen = _screen;
	uicache = new (self) class'UICacheMgr';
	if(CommandFunction != none)
	   m_fnOnCommand = CommandFunction;
	else
	   m_fnOnCommand = _screen.OnCommand;
	b_IsInitialized = true;
	SetInputState(eInputState_Evaluate);

	//register the dummy-panel for input-checks:
	XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetALocalPlayerController()).m_Pres.GetUIMgr().m_arrScreenInputStack.AddItem(self);
}
function BringToTopOfScreenStack()
{
	XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetALocalPlayerController()).m_Pres.GetUIMgr().m_arrScreenInputStack.RemoveItem(self);
	XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetALocalPlayerController()).m_Pres.GetUIMgr().m_arrScreenInputStack.InsertItem(0,self);
}
simulated function OnInit()
{
}
event Destroyed()
{
	XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetALocalPlayerController()).m_Pres.GetUIMgr().PopFirstInstanceOfScreen(self);
}
simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
	local bool bHandled;

	if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg) && !(Cmd == 571 && Arg == 32)) //let Tab sneak through, for tests
	{
		return false;
	}
	bHandled = false;
	if(!XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetALocalPlayerController()).m_Pres.IsInState('State_Customize'))
	{
		switch(Cmd)
		{
			case 333:
				if(screen.IsA('UISoldierSummary') || (screen.IsA('UISoldierPromotion') && !UISoldierPromotion(screen).m_bPsiPromotion) )
				{
					MiniModsStrategy(m_kMutator).OnMeldInject();
					bHandled=true;
				}
				break;
			case 313:
				if(screen.IsA('UISoldierPromotion') && !UISoldierPromotion(screen).m_bPsiPromotion)
				{
					MiniModsStrategy(m_kMutator).ClearPerksDialogue();
					bHandled=true;
				}
				break;
			case 332:
				if(screen.IsA('UISoldierSummary') || screen.IsA('UISoldierLoadout'))
				{
					MiniModsStrategy(m_kMutator).OnStripGear();
					bHandled=true;
				}
				break;
			default:
				bHandled = false;
		}
	}
	return bHandled;
}
DefaultProperties
{
}
