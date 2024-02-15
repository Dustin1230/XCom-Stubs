class UIModButtonHelper extends UI_FxsScreen;

var XComMutator m_kMutator;
var UIModManager m_kModMgr;

simulated function PanelInit(XComPlayerController _controller, UIFxsMovie _manager, UI_FxsScreen _screen, optional delegate<OnCommandCallback> CommandFunction)
{
	//just base initialization; no AddPanel or LoadScreen - this is a dummy actor
	controllerRef = _controller;
	manager = _manager;
	screen = _screen;
	uicache = new (self) class'UICacheMgr';
	if(CommandFunction != none)
	{
	   m_fnOnCommand = CommandFunction;
	}
	else
	{
		m_fnOnCommand = _screen.OnCommand;
	}
	b_IsInitialized = true;
	SetInputState(eInputState_Evaluate);

	//register the dummy-panel as the first to receive input-checks:
	BecomeFirstToReceiveInput();
	m_kModMgr = GetModMgr();
}
simulated function OnInit()
{
	local ASDisplayInfo tDisplay;

	UIInterfaceMgr(manager).DialogBox.AS_SetStyleNormal(); //this is just to pre-init progress dialog box
	tDisplay = manager.GetVariableObject(string(controllerRef.m_Pres.GetHUD().DialogBox.GetMCPath())).GetDisplayInfo();
		tDisplay.XScale=200.0;
		tDisplay.YScale=200.0;
		tDisplay.X -= controllerRef.m_Pres.GetHUD().m_v2ScaledDimension.X / 2.0;
		tDisplay.Y -= controllerRef.m_Pres.GetHUD().m_v2ScaledDimension.Y / 2.0;
	manager.GetVariableObject(string(controllerRef.m_Pres.GetHUD().DialogBox.GetMCPath())).SetDisplayInfo(tDisplay);
}
function BecomeFirstToReceiveInput()
{
	class'UIModUtils'.static.GetPresBase().GetUIMgr().m_arrScreenInputStack.RemoveItem(self);
	class'UIModUtils'.static.GetPresBase().GetUIMgr().m_arrScreenInputStack.InsertItem(0,self);
}
event Destroyed()
{
	m_kModMgr = none;
	//controllerRef.m_Pres.GetMessenger().Message(GetFuncName() @ self);
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
				//break;
			}
		}
	}
	return m_kModMgr;
}
simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
	local bool bHandled;

	if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg))
	{
		if( !(Cmd == 571 && Arg == 32) ) //let Tab key sneak through for tests
		{
			return false;
		}
	}
	switch(Cmd)
	{
		case 320:
		case 571:
			if(screen.IsA('UIShellDifficulty') && GetModMgr().PRES().IsInState('State_ShellDifficulty'))
			{
				GetModMgr().ShowModsMenu();
				bHandled=true;
			}
			break;
		case 300:
		case 302:
		case 511:
		case 513:
			if(screen.IsA('UIFinalShell') && GetModMgr().PRES().IsInState('State_FinalShell'))
			{
				if(UIFinalShell(screen).m_iCurrentSelection == 1)
				{
					GetModMgr().ShowModsMenu();
					bHandled=true;
				}
			}
			else if(screen.IsA('UIPauseMenu') && GetModMgr().PRES().IsInState('State_PauseMenu'))
			{
				if(UIPauseMenu(screen).GetSelected() == GetModMgr().m_iMutatorListButtonID)
				{
					GetModMgr().ShowMutatorsList();
					bHandled=true;
				}
			}
			break;
		default:
			bHandled = false;
	}
	return bHandled;
}
state CachingDataForModMgr
{
Begin:
	Sleep(0.10);//let the "progress box" set up peacefully :)
	GetModMgr().CacheUIModData(); //cache data from loaded mod containers
	Sleep(0.05);
	GetModMgr().UpdatePackages(); //update available packages based on cached data
	Sleep(0.05);
	GetModMgr().UpdatePackageMenuOptions(); //build data for "Mod Packages" menu
	Sleep(0.05);
	GetModMgr().UpdateModMenuOptions(); //build data for "Select Mods" menu
	Sleep(0.05);
	GetModMgr().ShowModList();
	GotoState('None');
}

DefaultProperties
{
}
