class XComShell extends XComGameInfo
    config(Game)
    hidecategories(Navigation,Movement,Collision);

const EXECUTE_COMMAND_TIMEOUT = 0.5;

var UIShell m_kShell;
var UIFxsMovie m_kUIMgr;
var string m_sCommand;
var string m_sMapName;
var float m_commandExecuteTimeout;
var XComShellController m_kController;

event InitGame(string Options, out string ErrorMessage){}
event PostLogin(PlayerController NewPlayer){}
simulated function ShutDownAndExecute(string Command);

state Running
{
    ignores Tick;

    simulated function ShutDownAndExecute(string Command){}
}
state ShuttingDown
{
    simulated function Tick(float dt){}
}
