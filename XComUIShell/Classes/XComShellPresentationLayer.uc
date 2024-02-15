class XComShellPresentationLayer extends XComPresentationLayerBase
    hidecategories(Navigation);

const UNCANCELLABLE_PROGRESS_DIALOGUE_TIMEOUT = 10;

var XComShell m_kXComShell;
//var XComMultiplayerShellUI m_kMPInterface;
//var UIStartScreen m_kStartScreen;
//var UISaveExplanationScreen m_kSaveExplanationScreen;
//var UIShell m_kShellScreen;
var UIFinalShell m_kFinalShellScreen;
//var UIMapList m_kMapList;
//var UISinglePlayerLoadout m_kSPLoadout;
//var UIMultiplayerShell m_kMPShell;
//var UIMultiplayerCustomMatch m_kMPCustomMatch;
//var UIMultiplayerLoadout m_kMPLoadoutScreen;
//var UIMultiplayerPlayerStats m_kMultiplayerPlayerStats;
//var UIMiniLoadoutEditor m_kMiniLoadoutEditor;
//var UIMultiplayerLoadoutList m_kMPLoadoutList;
//var UIPerkSelector m_kPerkSelector;
//var UISPMiniLoadoutEditor m_kSPMiniLoadoutEditor;
//var UIMultiplayerServerBrowser m_kServerBrowser;
//var UIMultiplayerLeaderboards m_kLeaderboards;
//var int m_iMPTurnTimeSeconds;
//var int m_iMPMaxSquadCost;
var EMPGameType m_eMPGameType;
var EMPNetworkType m_eMPNetworkType;
var bool m_bMPIsRanked;
var bool m_bCreatingOnlineGame;
var bool m_bOnlineGameSearchInProgress;
var bool m_bCanStartOnlineGameSearch;
var bool m_bOnlineGameSearchAborted;
var bool m_bOnlineGameSearchCooldown;
var bool m_bRankedAutomatchStatsReadInProgress;
var bool m_bRankedAutomatchStatsReadSuccessful;
var bool m_bRankedAutomatchStatsReadCanceled;
var name m_nmMPMapName;
//var XComOnlineGameSearch m_kOnlineGameSearch;
var OnlineGameSearchResult m_kAutomatchGameSearchResult;
var private int m_iNumAutomatchSearchAttempts;
var int m_iPlayerSkillRating;
var const localized string m_strOnlineRankedAutomatchFailed_Title;
var const localized string m_strOnlineRankedAutomatchFailed_Text;
var const localized string m_strOnlineRankedAutomatchFailed_ButtonText;
var const localized string m_strOnlineUnrankedAutomatchFailed_Title;
var const localized string m_strOnlineUnrankedAutomatchFailed_Text;
var const localized string m_strOnlineUnrankedAutomatchFailed_ButtonText;
var const localized string m_strOnlineReadRankedStatsFailed_Title;
var const localized string m_strOnlineReadRankedStatsFailed_Text;
var const localized string m_strOnlineReadRankedStatsFailed_ButtonText;
var const localized string m_strOnlineReadRankedStats_Text;
var const localized string m_strOnlineSearchForRankedAutomatch_Title;
var const localized string m_strOnlineSearchForRankedAutomatch_Text;
var const localized string m_strOnlineSearchForUnrankedAutomatch_Title;
var const localized string m_strOnlineSearchForUnrankedAutomatch_Text;
var const localized string m_strOnlineCancelCreateOnlineGame_Title;
var const localized string m_strOnlineCancelCreateLANGame_Title;
var const localized string m_strOnlineCancelCreateSystemLinkGame_Title;
var const localized string m_strOnlineCancelCreateOnlineGame_Text;
var const localized string m_strOnlineCancelCreateOnlineGame_ButtonText;
var const localized string m_strSelectSaveDeviceForEditSquadPrompt;
var string m_strMatchOptions;
//var XComOnlineStatsReadDeathmatchRanked m_kRankedDeathmatchStatsRead;
var delegate<OnSaveExplanationScreenComplete> m_dOnSaveExplanationScreenComplete;
var delegate<Callback> __Callback__Delegate;
//var delegate<delActionAccept_MiniLoadoutEditor> __delActionAccept_MiniLoadoutEditor__Delegate;
//var delegate<delActionCancel_MiniLoadoutEditor> __delActionCancel_MiniLoadoutEditor__Delegate;
var delegate<delActionAccept_SPMiniLoadoutEditor> __delActionAccept_SPMiniLoadoutEditor__Delegate;
var delegate<delActionCancel_SPMiniLoadoutEditor> __delActionCancel_SPMiniLoadoutEditor__Delegate;
var delegate<OnSaveExplanationScreenComplete> __OnSaveExplanationScreenComplete__Delegate;
var delegate<m_dOnFindOnlineGamesComplete> __m_dOnFindOnlineGamesComplete__Delegate;

delegate Callback();

//delegate delActionAccept_MiniLoadoutEditor(UIMiniLoadoutEditor_Unit kUnitLoadout);

delegate delActionCancel_MiniLoadoutEditor();

delegate delActionAccept_SPMiniLoadoutEditor(UISPLoadout_Unit kSPUnitLoadout);

delegate delActionCancel_SPMiniLoadoutEditor();

delegate OnSaveExplanationScreenComplete();

delegate m_dOnFindOnlineGamesComplete(bool bWasSuccessful);

simulated function Init(){}
simulated function InitUIScreens(){}
simulated function TravelToNextScreen(){}
simulated function OnShellLoginComplete(bool bWasSuccessful){}
simulated function EnterMainMenu(){}
private final simulated function ShuttleToMPMainMenu(){}
simulated function ClearUIToHUD(){}
simulated event Destroyed(){}
//simulated function UIMultiplayerShell GetMPShell()
//simulated function UIMiniLoadoutEditor GetLoadoutEditor()
//simulated function UIMultiplayerCustomMatch GetCustomMatch()
event PreBeginPlay(){}
//simulated event OnCleanupWorld()
//private final simulated function Cleanup()
//simulated function UIShellScreen()
//simulated function UIFinalShellScreen()
//simulated function UIStartScreenState()
//simulated function UISaveExplanationScreenStateEx(delegate<OnSaveExplanationScreenComplete> dOnSaveExplanationScreenComplete)
//simulated function UISaveExplanationScreenState()
//simulated function UIMapListScreen()
//simulated function UISinglePlayerLoadout()
//simulated function UISPMiniLoadoutEditorScreen(UISPLoadout_Unit kEditorLoadout, delegate<delActionAccept_SPMiniLoadoutEditor> del_OnAccept, delegate<delActionCancel_SPMiniLoadoutEditor> del_OnCancel)
//simulated function UISPMiniLoadoutEditorScreen(UISPLoadout_Unit kEditorLoadout, delegate<delActionAccept_SPMiniLoadoutEditor> del_OnAccept, delegate<delActionCancel_SPMiniLoadoutEditor> del_OnCancel)
//simulated function UIMultiplayerShell()

simulated state State_FinalShell extends BaseScreenState
{
    simulated function Activate()
    {
    }

    simulated function Deactivate()
    {
    }

    simulated function OnReceiveFocus()
    {
    }

    simulated function OnLoseFocus()
    {
    }
}

DefaultProperties
{
}
