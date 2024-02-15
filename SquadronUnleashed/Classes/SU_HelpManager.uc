class SU_HelpManager extends Actor
	config(SquadronUnleashed);

enum ESUModErrorMsg
{
	eSUError_PilotStatusNotValid,
	eSUError_BetterStaffRequired,
	eSUError_PilotRankTooLow,
	eSUError_PilotInTraining,
	eSUError_JetAlreadyRearming,
	eSUError_JetInTransfer,
	eSUError_JetRepairing,
	eSUError_JetRefuelling,
	eSUError_MAX
};
enum ESUModHelpMsg
{
	eSUHelp_TutorialWelcome,
	eSUHelp_FirstVisitHangar,
	eSUHelp_FirstVisitTraining,
	eSUHelp_FirstVisitAirCommand,
	eSUHelp_CombatTacticsManagement,
	eSUHelp_TrainingCenterManagement,
	eSUHelp_ShipLoadout,
	eSUHelp_SelectShips,
	eSUHelp_MeaningOfTactics,
	eSUHelp_WeaponToggling,
	eSUHelp_SendingDamagedShips,
	eSUHelp_LeaderBuffs,
	eSUHelp_UFOTactics,
	eSUHelp_CombatIntro,
	eSUHelp_CombatDistance,
	eSUHelp_CombatShipControl,
	eSUHelp_CombatLeader,
	eSUHelp_CombatXP,
	eSUHelp_PilotRoster,
	eSUHelp_PilotCard,
	eSUHelp_PilotCareer,
	eSUHelp_UFOSquadron,
	eSUHelp_TeamKills,
	eSUHelp_MAX
};
var localized array<string> arrErrorMsg;
var localized array<string> arrHelpMsg;
var config array<string> arrHelpImgPath;
var array<int> m_arrMessageQueue;
var bool m_bSaveProfileWhenDone;

event PostBeginPlay()
{
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(self, 'm_arrMessageQueue', self, UpdateQueue);
}
static function XComHQPresentationLayer PRES()
{
	return XComHQPresentationLayer(XComHeadquartersController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).m_Pres);
}
function ShowErrorMsg(int iErrorMsg, optional float fOffsetY=0.92, optional EUIIcon eIcon=eIcon_ExclamationMark)
{
	local float fDisplayTime;

	fDisplayTime = FClamp(Len(default.arrErrorMsg[iErrorMsg]) / 10.0, 2.0, 3.0);

	PRES().GetAnchoredMessenger().Message(default.arrErrorMsg[iErrorMsg], 0.5, fOffsetY, Center, fDisplayTime,,eIcon);
}
function ShowHelpMsg(int iHelpMsg, optional delegate<UIDialogueBox.ActionCallback> fnCallbackFunction)
{
	local TDialogueBoxData kDialogData;
	local SquadronUnleashed kMasterMod;

	kMasterMod =class'SU_Utils'.static.GetSquadronMod();
	if(!kMasterMod.m_bTutorial || class'XGSaveHelper'.static.GetProfileStatValue(Class $ ".arrHelpMsg." $ iHelpMsg) > 0)
	{
		return;
	}
	kDialogData.strTitle = "SQUADRON UNLEASHED -" @ Localize("UIControllerMap", "m_sInformation", "XComGame");
	kDialogData.strText = default.arrHelpMsg[iHelpMsg];
	if(default.arrHelpImgPath.Length > iHelpMsg)
	{
		kDialogData.strImagePath = default.arrHelpImgPath[iHelpMsg];
	}
	kDialogData.strCancel = class'UI_FxsShellScreen'.default.m_strDefaultHelp_Accept;
	kDialogData.strAccept = Localize("UIModShell", "m_strDontShowAnymore", "XComModShell");
	if(fnCallbackFunction != none)
	{
		kDialogData.fnCallback = fnCallbackFunction;
	}
	PRES().UIRaiseDialog(kDialogData);
	//use dialog box to show help messages
}
function QueueHelpMsg(int iHelpMsg, optional float fUpdateWithTimer)
{
	`Log(GetFuncName() @ (Class $ ".arrHelpMsg." $ iHelpMsg));
	if(class'SU_Utils'.static.GetSquadronMod().m_bTutorial && class'XGSaveHelper'.static.GetProfileStatValue(Class $ ".arrHelpMsg." $ iHelpMsg) == 0)
	{
		m_arrMessageQueue.AddItem(iHelpMsg);
		if(fUpdateWithTimer > 0.0)
		{
			SetTimer(fUpdateWithTimer, false, 'UpdateQueue');
		}
	}
}
function ClearQueue()
{
	m_arrMessageQueue.Length = 0;
}
function ResetTutorialSettings()
{
	local int i;

	for(i = 0; i < default.arrHelpMsg.Length; ++i)
	{
		class'XGSaveHelper'.static.SetProfileStat((Class $ ".arrHelpMsg." $ i), 0); 
	}
	XComOnlineEventMgr(GameEngine(Class'Engine'.static.GetEngine()).OnlineEventManager).SaveProfileSettings();
}
function UpdateQueue()
{
	`Log(GetFuncName() @ "queue length:" @ m_arrMessageQueue.Length);
	if(m_arrMessageQueue.Length > 0 && !IsInState('ProcessingQueue'))
	{
		PushState('ProcessingQueue');
	}
}
function CloseMessageCallback(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		class'XGSaveHelper'.static.SetProfileStat((Class $ ".arrHelpMsg." $ m_arrMessageQueue[0]), 1); 
		m_bSaveProfileWhenDone = true;
	}
	m_arrMessageQueue.Remove(0, 1);
}
function bool TutorialDone()
{
	return m_arrMessageQueue.Length == 0;
}

state ProcessingQueue
{
Begin:
	if(IsTimerActive('UpdateQueue'))
	{
		Sleep( GetTimerRate('UpdateQueue') - GetTimerCount('UpdateQueue'));
	}
	else
	{
		Sleep(0.10);
	}
	do
	{
		while(PRES().UIIsShowingDialog())
		{	
			Sleep(0.10);	
		}
		if(m_arrMessageQueue.Length > 0)
		{
			ShowHelpMsg(m_arrMessageQueue[0], CloseMessageCallback);
		}
	}until(m_arrMessageQueue.Length == 0);
	if(m_bSaveProfileWhenDone)
	{
		XComOnlineEventMgr(GameEngine(Class'Engine'.static.GetEngine()).OnlineEventManager).SaveProfileSettings();
		m_bSaveProfileWhenDone = false;
	}
	PopState();
}
DefaultProperties
{
	bAlwaysTick=true;
}
