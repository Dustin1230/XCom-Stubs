class XComShellController extends XComPlayerController
    config(Game)
    hidecategories(Navigation);
//complete stub

var XComShell m_kShell;
var int m_iMPRankedDeathmatchRank;

simulated function XComShellPresentationLayer GetPres(){}
reliable client simulated function ClientSetOnlineStatus(){}
