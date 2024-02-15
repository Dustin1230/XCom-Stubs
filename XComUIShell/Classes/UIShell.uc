class UIShell extends UI_FxsScreen
    hidecategories(Navigation);
//complete stub

var const localized string m_strDemo;
var const localized string m_sLoad;
var const localized string m_sSpecial;
var const localized string m_sOptions;
var const localized string m_sStrategy;
var const localized string m_sTactical;
var const localized string m_sTutorial;
var const localized string m_sFinalShellDebug;
var int m_iCurrentSelection;
var int m_iMaxSelection;
var bool m_bDisableActions;
var bool bLoginInitialized;
var bool m_bCanceledTouchPrompt;
var const localized string m_sTouchedNotifyTitle;
var const localized string m_sTouchedNotifyText;

simulated function Init(XComPlayerController _controllerRef, UIFxsMovie _manager){}
simulated function OnInit(){}
event PreBeginPlay(){}
event Destroyed(){}
simulated event OnCleanupWorld(){}
simulated function Cleanup(){}
simulated function OnGameInviteAccepted(bool bWasSuccessful){}
simulated function OnGameInviteComplete(ESystemMessageType MessageType, bool bWasSuccessful){}
simulated function OnTouched(){}
function ConfirmTouchEnableCallback(EUIAction eAction){}
simulated function Show(){}
simulated function Hide(){}
function OnMusicLoaded(Object LoadedObject){}
function DelayedLogin(){}
simulated function bool OnUnrealCommand(int Cmd, int Arg){}
simulated function bool OnMouseEvent(int Cmd, array<string> args){}
simulated function RealizeSelected(){}
simulated function SetText(){}
simulated function AcceptMenu(){}
simulated function OnReceiveFocus(){}
simulated function OnLoseFocus(){}
simulated function OnDeactivate();
simulated function ExecuteSonOfFacemelt(){}
simulated function ExecuteFarmDemo(){}
