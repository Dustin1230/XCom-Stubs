class SU_UIPilotRoster extends UIShipList;

var SUGfx_PilotRoster m_gfxScreen;
var SU_Pilot m_kSelectedPilot;
var bool m_bCompactView;
var UI_FxsPanel m_kBackgroundScreen;
var localized string m_strPilotRosterTitle;
var localized string m_strColumnLabelName;
var localized string m_strColumnLabelCareer;
var localized string m_strColumnLabelStatus;
var localized string m_strKills;
var localized string m_strAim;
var localized string m_strDef;
var localized string m_strDamage;
var localized string m_strXP;
var localized string m_strSize;
var localized string m_strNextRank;
var localized string m_strMaxedRank;
var localized string m_strLabelSquadron;
var localized string m_strHirePilotLabel;
var localized string m_strHirePilotDialog;

function SUGfx_PilotRoster SelfGfx()
{
	if(m_gfxScreen == none)
	{
		m_gfxScreen = SUGfx_PilotRoster(manager.GetVariableObject(string(GetMCPath()), class'SUGfx_PilotRoster'));
	}
	return m_gfxScreen;
}
simulated function Init(XComPlayerController _controllerRef, UIFxsMovie _manager)
{
	BaseInit(_controllerRef, _manager);
	m_fnOnCommand = OnCommand;
	if(SelfGfx() == none)
	{
		manager.LoadScreen(self);
	}
	else 
	{
		manager.screens.InsertItem(0, self);
		controllerRef.m_Pres.GetUIMgr().PushScreen(self);
		SetTimer(0.10, false, 'OnInit');
//		SetTimer(0.15, false, 'OnCommand');
	}
	if(controllerRef.m_Pres.IsInState('State_HangarShipSummary') || controllerRef.m_Pres.IsInState('State_MC') && XComHQPresentationLayer(controllerRef.m_Pres).m_kUIMissionControl.m_kActiveAlert.IsA('UIMissionControl_UFORadarContactAlert'))
	{
		m_iView = 7;
	}
}

simulated function XGHangarUI GetMgr(optional int iStaringView = -1)
{
	if(m_kLocalMgr == none)
	{
		//make it return SU_XGHangarUI screen manager instead of XGHangarUI
		m_kLocalMgr = SU_XGHangarUI(XComHQPresentationLayer(controllerRef.m_Pres).GetMgr(class'SU_XGHangarUI', (self)));
	}
	return m_kLocalMgr;
}
simulated function OnInit()
{
    super(UI_FxsScreen).OnInit();
	SelfGfx().SetupHangarsList();
    UpdateTitle();
    AS_SetColumnLabels(m_strColumnLabelName, m_strColumnLabelCareer, m_strColumnLabelStatus);
	DetermineBackgroundScreen();
	if(XComHQPresentationLayer(controllerRef.m_Pres).GetStateName() == 'State_HangarShipSummary')
	{
		m_kBackgroundScreen.Hide();
	}
	BackgroundScreenSetFocus(false);
	GetMgr().m_iCurrentView = m_iView;
	m_bUpdateDataOnReceiveFocus=true;
	b_IsInitialized = true;
	OnReceiveFocus();
	class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_PilotRoster);
}
simulated function OnReceiveFocus()
{
	super(UI_FxsPanel).OnReceiveFocus();
	if(m_kLocalMgr != none)
	{
		m_kLocalMgr.m_kInterface = (self);
	}
	else
	{
		GetMgr();
	}
	if(m_bUpdateDataOnReceiveFocus)
	{
		UpdateData();
		m_bUpdateDataOnReceiveFocus = false;
	}
//	XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).CAMLookAtFacility(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().m_kHangar);
	XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).GetStrategyHUD().ShowBackButton(OnMouseCancel,,true);
	SelfGfx().SetVisible(true);
}
simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	BackgroundScreenSetFocus(true);
}
function DetermineBackgroundScreen()
{
	if(XComHQPresentationLayer(controllerRef.m_Pres).GetStateName() == 'State_HangarShipSummary')
	{
		m_kBackgroundScreen = XComHQPresentationLayer(controllerRef.m_Pres).m_kShipSummary;
	}
	else if(XComHQPresentationLayer(controllerRef.m_Pres).GetStateName() == 'State_MC' && XComHQPresentationLayer(controllerRef.m_Pres).m_kUIMissionControl.m_kActiveAlert != none)
	{
		m_kBackgroundScreen = XComHQPresentationLayer(controllerRef.m_Pres).m_kUIMissionControl.m_kActiveAlert;
	}
	else if(class'SU_Utils'.static.GetSquadronMod().m_kPilotTrainingUI != none)
	{
		m_kBackgroundScreen = class'SU_Utils'.static.GetSquadronMod().m_kPilotTrainingUI;
	}
}
function BackgroundScreenSetFocus(bool bGiveFocusToBackgroundScreen)
{
	if(m_kBackgroundScreen != none)
	{
		if(bGiveFocusToBackgroundScreen && !m_kBackgroundScreen.IsFocused())
		{
			if(UI_FxsScreen(m_kBackgroundScreen) != none)
			{
				UI_FxsScreen(m_kBackgroundScreen).SetInputState(eInputState_Evaluate);
			}
			m_kBackgroundScreen.b_IsInitialized = true;
			m_kBackgroundScreen.OnReceiveFocus();
		}
		else if(!bGiveFocusToBackgroundScreen && m_kBackgroundScreen.IsFocused())
		{
			if(UI_FxsScreen(m_kBackgroundScreen) != none)
			{
				UI_FxsScreen(m_kBackgroundScreen).SetInputState(eInputState_None);
			}
			m_kBackgroundScreen.b_IsInitialized = false;
			m_kBackgroundScreen.OnLoseFocus();
		}
	}
}
simulated function UpdateData()
{
	local array<TContinentInfoWithPilots> arrContinents;
	local TContinentInfoWithPilots tContinent;
	local SUGfx_ContinentList gfxList;
	local SU_Pilot kPilot;
	local int i, iContinent, iNumPilots, iButtonStatus, iStatusColorCode;
	local string strPilotRecord, strPilotRankData, strHelp;
	
	Invoke("ClearAll");
	UpdateTitle();
	if(m_iView == 7)
	{
		AS_SetContinentTitle(0, "");
		AS_SetContinentTitle(1, "");
		AS_SetContinentTitle(2, "");
		AS_SetContinentTitle(3, "");
		AS_SetContinentTitle(4, "");
		AS_SetContinentTitle(5, "");
	}
	GetMgr().UpdateShipList();
	SU_XGHangarUI(GetMgr()).UpdatePilotList();//caches continent info
	arrContinents = SU_XGHangarUI(GetMgr()).m_arrContinentsInfo;
	foreach arrContinents(tContinent, iContinent)
	{
		gfxList = SUGfx_ContinentList(SelfGfx().m_gfxHangarsMC.GetObject("option"$iContinent, class'SUGfx_ContinentList'));
		gfxList.AS_SetRealizePositionsDelegate(gfxList.RealizePositions);
		SelfGfx().CacheContinent(gfxList);
		iNumPilots = 0;
		for(i=0; i < tContinent.arrPilots.Length; ++i)
		{
			kPilot = tContinent.arrPilots[i];
			strPilotRecord = class'UIUtilities'.static.GetHTMLColoredText(kPilot.GetCallsign(), 5, 18);
			strPilotRecord $= class'UIUtilities'.static.GetHTMLColoredText("\n" $ kPilot.StatsToString(), 0, 18);
			strPilotRecord $= class'UIUtilities'.static.GetHTMLColoredText("\n"$ CAPS(m_strLabelSquadron) @ kPilot.TeamBuffsToString(), 0, 15);

			strPilotRankData = class'UIUtilities'.static.GetHTMLColoredText(class'SU_Utils'.static.GetRankMgr().GetFullRankName(kPilot.GetRank()) @ class'SU_Utils'.static.GetRankMgr().GetCareerPathName(kPilot.GetCareerType()), 5, 18);
			if(kPilot.m_bCareerChoicePending)
			{
				strPilotRankData = "<font color='#"$ class'UIUtilities'.const.WARNING_HTML_COLOR $"'>!</font>" @ strPilotRankData;
			}
			strPilotRankData $= class'UIUtilities'.static.GetHTMLColoredText("\n"$kPilot.CareerProgressToString(false, true), 0, 18);
			if(kPilot.GetRank() < kPilot.m_kTCareerPath.arrTRanks.Length - 1)
			{
				strPilotRankData $= class'UIUtilities'.static.GetHTMLColoredText("\n"$m_strNextRank @ kPilot.RankUpReqsToString(,true), 4, 15);
			}
			else
			{
				strPilotRankData $= class'UIUtilities'.static.GetHTMLColoredText("\n"$m_strMaxedRank, 4, 15);
			}
			iStatusColorCode = eUIState_Good;
			iButtonStatus = eUIState_Normal;
			if(manager.IsMouseActive())
			{
				strHelp = m_bTransferingShip ? m_strCancelTransferButtonHelp : m_strTransferShipButtonHelp;
			}
			if(kPilot.GetStatus() != ePilotStatus_Ready || m_iView == 7 && m_kBackgroundScreen.IsA('SU_UIPilotTraining') && !class'SU_Utils'.static.GetSquadronMod().m_kPilotTrainingCenter.PilotCanSignUpForTraining(kPilot))
			{
				iStatusColorCode = eUIState_Warning;
				iButtonStatus = eUIState_Disabled;
			}
			//LogInternal("Adding row for" @ kPilot.GetCallsign() @ "button help:" @ strHelp);
			AS_AddShip(iContinent, strPilotRecord, strPilotRankData, class'UIUtilities'.static.GetHTMLColoredText(kPilot.GetStatusString(), iStatusColorCode, 18), m_iView == 7 ? "" : strHelp, iButtonStatus);
			SelfGfx().SetupButtonGfx(iContinent, iNumPilots);
			++iNumPilots;
			
		}
		if(iNumPilots < class'SquadronUnleashed'.default.HANGAR_CAPACITY || m_iView == 7 && !m_kBackgroundScreen.IsA('SU_UIPilotTraining'))
		{
			if(manager.IsMouseActive())
			{
				strHelp = m_bTransferingShip ? m_strTransferShipHereButtonHelp : "";
			}
			AS_AddShip(iContinent, m_iView == 7 ? class'XGBuildUI'.default.m_strLabelRemove : m_strHirePilotLabel, "", "", strHelp, -1);
		}
		AS_SetContinentTitle(iContinent, tContinent.strContinentName.StrValue @ "("$iNumPilots$"/"$class'SquadronUnleashed'.default.HANGAR_CAPACITY$")");
	}
}
simulated function bool OnCancel(optional string selectedOption="")
{
	`Log(GetFuncName());
	if(m_bTransferingShip)
    {
        GetMgr().PlayBadSound();
		GetMgr().GoToView(6);
    }
    else
    {
		if(m_iView == 7 && m_kBackgroundScreen != none)
		{
			if(m_kBackgroundScreen.IsA('UIShipSummary'))
			{
				UIShipSummary(m_kBackgroundScreen).m_bUpdateDataOnReceiveFocus = true;
				XComHQPresentationLayer(controllerRef.m_Pres).m_kShipList.m_bUpdateDataOnReceiveFocus = true;
			}
			else if(m_kBackgroundScreen.IsA('SU_UFORadarContactAlert'))
			{
				SU_UFORadarContactAlert(m_kBackgroundScreen).AS_DeactivateShipList();
				SU_UFORadarContactAlert(m_kBackgroundScreen).m_kInterceptMgr.UpdateView();
				SU_UFORadarContactAlert(m_kBackgroundScreen).UpdateData();
			}
		}
		BackgroundScreenSetFocus(true);
        class'SU_Utils'.static.GetSquadronMod().PopState();
    }
    return true;
}
simulated function bool OnAccept(optional string selectedOption="")
{
	local int selectedContinentNumPilots;
	local bool bExit;

	selectedContinentNumPilots = SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iSelectedContinent].arrPilots.Length;
	if(m_bTransferingShip)
	{
		if(m_iContinentTransferingTo != -1)
		{
			TransferShip();
		}
		else
		{
			GetMgr().PlayBadSound();
		}
		if(SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iSelectedContinent].arrPilots.Length != selectedContinentNumPilots)
		{
			UpdateData();
		}
	}
	else if(m_iView == 7)//assign pilot
	{
		if(m_kBackgroundScreen.IsA('UIMissionControl_UFORadarContactAlert') || m_kBackgroundScreen.IsA('UIShipSummary'))
		{
			if(m_kSelectedPilot != none && m_kSelectedPilot.GetStatus() != ePilotStatus_Ready)
			{
				GetMgr().PlayBadSound();
				class'SU_Utils'.static.GetHelpMgr().ShowErrorMsg(eSUError_PilotStatusNotValid);
			}
			else
			{
				GetMgr().PlayGoodSound();
				AssignSelectedPilotToShip(XGShip_Interceptor(GetMgr().m_kShip));
				bExit = true;
			}
		}
		else if(m_kBackgroundScreen.IsA('SU_UIPilotTraining'))
		{
			if(m_kSelectedPilot != none && !class'SU_Utils'.static.GetSquadronMod().m_kPilotTrainingCenter.PilotCanSignUpForTraining(m_kSelectedPilot))
			{
				GetMgr().PlayBadSound();
				if(!class'SU_Utils'.static.GetSquadronMod().m_kPilotTrainingCenter.PilotCanBenefitFromTraining(m_kSelectedPilot))
					class'SU_Utils'.static.GetHelpMgr().ShowErrorMsg(eSUError_BetterStaffRequired);
				else if(class'SU_Utils'.static.GetSquadronMod().m_kPilotTrainingCenter.m_arrTrainedPilots.Find('kPilot', m_kSelectedPilot) != -1)
					class'SU_Utils'.static.GetHelpMgr().ShowErrorMsg(eSUError_PilotInTraining);
				else				
					class'SU_Utils'.static.GetHelpMgr().ShowErrorMsg(eSUError_PilotStatusNotValid);
			}
			else if(m_kSelectedPilot != none)
			{
				GetMgr().PlayGoodSound();
				class'SU_Utils'.static.GetSquadronMod().m_kPilotTrainingCenter.AddTrainee(m_kSelectedPilot);
				bExit = true;
			}
			else
			{
				GetMgr().PlayCloseSound();
				bExit = true;
			}
		}
	}
	else if(m_kSelectedPilot != none)
	{
		GetMgr().PlayGoodSound();
		ShowPilotCard();
	}
	else//empty slot (new pilot)
	{
		GetMgr().PlaySmallOpenSound();
		HirePilotDialog();
	}
	if(bExit)
	{
		OnCancel();
	}
	return true;
}
function AssignSelectedPilotToShip(XGShip_Interceptor kShip)
{
	local SU_Pilot kPreviousPilot;

	kPreviousPilot = class'SU_Utils'.static.GetPilot(kShip);
	if(kPreviousPilot != none)
	{
		kPreviousPilot.SetShip(none);
	}
	if(m_kSelectedPilot != none)
	{
		m_kSelectedPilot.SetShip(kShip);
	}
}
function HirePilotDialog()
{
	local TDialogueBoxData kData;

	kData.strTitle = m_strHirePilotLabel;
	kData.strText = m_strHirePilotDialog;
	if(class'SquadronUnleashed'.default.PILOT_COST_TO_HIRE > 0)
	{
		kData.strText $="\n"$class'XGHangarUI'.default.m_strLabelHireCost @ class'XGScreenMgr'.static.ConvertCashToString(class'SquadronUnleashed'.default.PILOT_COST_TO_HIRE);
	}
	if(class'SquadronUnleashed'.default.PILOT_COST_MONTHLY > 0)
	{
		kData.strText $="\n"$class'XGHangarUI'.default.m_strLabelHireMonthlyCost @ class'XGScreenMgr'.static.ConvertCashToString(class'SquadronUnleashed'.default.PILOT_COST_MONTHLY);
	}
	kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	kData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	kData.fnCallback = OnHirePilotConfirmed;
	XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).UIRaiseDialog(kData);
}
function OnHirePilotConfirmed(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		GetMgr().HQ().AddResource(eResource_Money, -class'SquadronUnleashed'.default.PILOT_COST_TO_HIRE);
		class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.AddPilot(none,,SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iSelectedContinent].eCont);
		UpdateData();
	}
}
/** This should not be called directly - rather indirectly by GetMgr().GoToView*/
simulated function GoToView(int iView)
{
	`Log(self @ GetFuncName() @ iView @ "bIsInitialized?" @ b_IsInitialized);
	if(!IsFocused())
	{
		return;
	}
    if(b_IsInitialized && iView > 5)
    {
	    m_iView = iView;
        m_bTransferingShip = false;
		UpdateData();
		SelfGfx().SetVisible(true);
    }
	else
	{
		super.GoToView(iView);
	}
}
simulated function bool OnMouseEvent(int Cmd, array<string> args)
{
	local TContinentInfoWithPilots kContinentInfo;
	local int I;
	local string S, callbackObj;
	local bool bHandled, bIsSelectingEmptySlot, bClickingOnSlotBeingTransferred;

	if(Cmd != 391 || !IsFocused())
	{
		return false;
	}
	bHandled = true;
	for(I = 0; I < args.Length; ++I)
	{
		S = args[I];
		if(InStr(S, "option") != -1)
		{
			S -= "option";
			m_iSelectedContinent = int(S);
		}
		else
		{
			if(InStr(S, "theItems") != -1)
			{
				S = args[I + 1];
				m_iSelectedShip = int(S);
			}
		}
	}
	RealizeSelected();
	callbackObj = args[args.Length - 1];
	kContinentInfo = SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iSelectedContinent];
	bIsSelectingEmptySlot = m_iSelectedShip > kContinentInfo.arrPilots.Length - 1;
	if(!bIsSelectingEmptySlot)
	{
		m_kSelectedPilot = kContinentInfo.arrPilots[m_iSelectedShip];
	}
	else if(m_iView == 7)
	{
		m_kSelectedPilot = none;
	}
	switch(callbackObj)
	{
		case "theButton":
			if(m_bTransferingShip)
			{
				if(bIsSelectingEmptySlot && m_iSelectedContinent != m_iContinentTransferingFrom)
				{
					m_iContinentTransferingTo = m_iSelectedContinent;
					TransferShip();
					GetMgr().PlayGoodSound();
				}
				else
				{
					GetMgr().PlayBadSound();
				}
			}
			else
			{
				OnAccept();
			}
			break;
		case "clickableButton":
			if(m_bTransferingShip)
			{
				bClickingOnSlotBeingTransferred = m_iContinentTransferingFrom == m_iSelectedContinent;
				if(bClickingOnSlotBeingTransferred)
				{
					OnCancel();
				}
				else
				{
					if(bIsSelectingEmptySlot && m_iSelectedContinent != m_iContinentTransferingFrom)
					{
						m_iContinentTransferingTo = m_iSelectedContinent;
						TransferShip();
						GetMgr().PlayGoodSound();
					}
				}
			}
			else
			{
				if(bIsSelectingEmptySlot)
				{
					OnAccept();
				}
				else
				{
					OnTransferInterceptor();
				}
			}
			break;
		default:
			bHandled = false;
	}
	return bHandled;
}
simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
	local bool bHandled;

	if(m_iView != 5 && m_iView != 3 && m_iView != 6 && m_iView != 7)
	{
		return false;
	}
	if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg))
	{
		return false;
	}
	bHandled = true;
	switch(Cmd)
	{
		case 350:
		case 500:
		case 370:
		case 537:
			AlterSelection(-1);
			break;
		case 354:
		case 502:
		case 371:
		case 533:
			AlterSelection(1);
			break;
		case 300:
		case 511:
		case 513:
			OnAccept();
			break;
		case 301:
		case 510:
		case 405:
			OnCancel();
			break;
		case 302:
		case 538:
		//case 571:
			if(!m_bTransferingShip)
			{
				OnTransferInterceptor();
			}
			else
			{
				TransferShip();
			}
		case 303:
		case 539:
			break;
		case 571:
		case 311:
		case 600:
			ShowPilotCard();
			break;
		case 501:
		case 352:
		case 503:
		case 356:
		case 515:
		case 518:
		case 330:
		case 331:
			break;
		default:
			bHandled = false;
			break;
	}
	return bHandled;
}
simulated function AlterSelection(int Direction)
{
	local bool bFound;
	local int iCurrContinent, iCurrShip;

	LogInternal(GetFuncName() @ Direction @ "(m_iSelectedContinent" @ m_iSelectedContinent $", m_iSelectedShip" @ m_iSelectedShip$")");
	if(m_bTransferingShip)
	{
		bFound = false;
		if(m_iContinentTransferingTo == -1)
		{
			m_iContinentTransferingTo = m_iSelectedContinent;
		}
		iCurrContinent = m_iContinentTransferingTo;
		do
		{
			iCurrContinent += Direction;
			class'UIUtilities'.static.ClampIndexToArrayRange(SU_XGHangarUI(GetMgr()).m_arrContinentsInfo.Length, iCurrContinent);
			if(iCurrContinent == m_iSelectedContinent)
			{
				m_iContinentTransferingTo = -1;
				bFound = true;
			}
			else
			{
				if(SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[iCurrContinent].arrPilots.Length < class'SquadronUnleashed'.default.HANGAR_CAPACITY)
				{
					m_iContinentTransferingTo = iCurrContinent;
					iCurrShip = SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[iCurrContinent].arrPilots.Length;
					bFound = true;
				}
			}
		}
		until(bFound || iCurrContinent != m_iContinentTransferingTo);
		
		if(bFound)
		{
			GetMgr().PlayScrollSound();
			if(m_iContinentTransferingTo == -1)
			{
				RealizeSelected();
			}
			else
			{
				RealizeSelected(m_iContinentTransferingTo, iCurrShip);
			}
		}
		else
		{
			GetMgr().PlayBadSound();
		}
	}
	else
	{
		m_iSelectedShip += Direction;
		if(m_iSelectedShip == class'SquadronUnleashed'.default.HANGAR_CAPACITY || m_iSelectedShip > SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iSelectedContinent].arrPilots.Length)
		{
			++ m_iSelectedContinent;
			class'UIUtilities'.static.ClampIndexToArrayRange(SU_XGHangarUI(GetMgr()).m_arrContinentsInfo.Length, m_iSelectedContinent);
			m_iSelectedShip = 0;
		}
		else
		{
			if(m_iSelectedShip < 0)
			{
				-- m_iSelectedContinent;
				class'UIUtilities'.static.ClampIndexToArrayRange(SU_XGHangarUI(GetMgr()).m_arrContinentsInfo.Length, m_iSelectedContinent);
				if(SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iSelectedContinent].arrPilots.Length == class'SquadronUnleashed'.default.HANGAR_CAPACITY)
				{
					m_iSelectedShip = class'SquadronUnleashed'.default.HANGAR_CAPACITY - 1;
				}
				else
				{
					m_iSelectedShip = SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iSelectedContinent].arrPilots.Length;
				}
			}
		}
		GetMgr().PlayScrollSound();
		RealizeSelected();
	}
}
simulated function UpdateButtonHelpOnSelectedItem()
{
	local TContinentInfoWithPilots kContinentInfo;
	local string strHelpTxt;
	local bool bCanSelect, bCanTransfer;
	local int iShipIndex;

	AS_SetMoreInfoHotlink();
	if(m_bTransferingShip)
	{
		strHelpTxt = class'UI_FxsGamepadIcons'.static.HTML_BODYFONT("Icon_DPAD_VERTICAL") $ m_strTransferShipUpDownNavigationHelp;
		if(m_iContinentTransferingTo == -1)
		{
			if(!manager.IsMouseActive())
			{
				AS_UpdateShipHelp(m_iSelectedContinent, m_iSelectedShip, strHelpTxt);
				AS_SetMoreInfoHotlink(m_strMoreInfoHotlinkLabel, "Icon_LSCLICK_L3");
			}
		}
		else
		{
			iShipIndex = SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iContinentTransferingTo].arrPilots.Length;
			if(!manager.IsMouseActive())
			{
				AS_UpdateShipHelp(m_iContinentTransferingTo, iShipIndex, strHelpTxt);
				strHelpTxt = (class'UI_FxsGamepadIcons'.static.HTML_BODYFONT(class'UI_FxsGamepadIcons'.static.GetAdvanceButtonIcon()) $ class'UIUtilities'.static.GetHTMLColoredText(m_strTransferShipHereButtonHelp, 0)) $ " ";
				AS_UpdateShipStatusHelp(m_iContinentTransferingTo, iShipIndex, strHelpTxt);
			}
		}
		XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).GetStrategyHUD().ShowBackButton(OnMouseCancel, m_strCancelTransferButtonHelp, true);
		return;
	}
	XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).GetStrategyHUD().ShowBackButton(OnMouseCancel,,true);
	kContinentInfo = SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iSelectedContinent];
	if((kContinentInfo.arrPilots.Length < class'SquadronUnleashed'.default.HANGAR_CAPACITY) && m_iSelectedShip == kContinentInfo.arrPilots.Length)
	{
		m_kSelectedPilot = none;
		strHelpTxt = class'UI_FxsGamepadIcons'.static.HTML_BODYFONT(class'UI_FxsGamepadIcons'.static.GetAdvanceButtonIcon()) $ m_strHirePilotLabel;
		if(!manager.IsMouseActive())
		{
			AS_UpdateShipHelp(m_iSelectedContinent, m_iSelectedShip, strHelpTxt);
		}
	}
	else
	{
		if(m_iSelectedShip >= kContinentInfo.arrPilots.Length)
		{
			m_kSelectedPilot = none;
			if(!manager.IsMouseActive())
			{
				if(m_iSelectedShip >= kContinentInfo.arrPilots.Length)
				{
					strHelpTxt = "";
					AS_UpdateShipHelp(m_iSelectedContinent, m_iSelectedShip, strHelpTxt);
				}
				else
				{
					strHelpTxt = class'UI_FxsGamepadIcons'.static.HTML_BODYFONT(class'UI_FxsGamepadIcons'.static.GetAdvanceButtonIcon()) $ class'UIUtilities'.static.GetHTMLColoredText(m_strCancelHireButtonHelp, 3);
					AS_UpdateShipHelp(m_iSelectedContinent, m_iSelectedShip, strHelpTxt);
				}
			}
		}
		else
		{
			m_kSelectedPilot = kContinentInfo.arrPilots[m_iSelectedShip];
			bCanSelect = true;
			bCanTransfer = true;
			strHelpTxt = "";
			if(GetMgr().ISCONTROLLED() || !HangarSlotAvailable())
			{
				bCanTransfer = false;
			}
			if(bCanSelect)
			{
				strHelpTxt $= ((class'UI_FxsGamepadIcons'.static.HTML_BODYFONT(class'UI_FxsGamepadIcons'.static.GetAdvanceButtonIcon()) $ class'UIUtilities'.static.GetHTMLColoredText(m_strViewShipButtonHelp, 0)) $ " ");
			}
			if(bCanTransfer)
			{
				strHelpTxt $= (class'UI_FxsGamepadIcons'.static.HTML_BODYFONT("Icon_X_SQUARE") $ class'UIUtilities'.static.GetHTMLColoredText(m_strTransferShipButtonHelp, 0));
			}
			if(!manager.IsMouseActive())
			{
				AS_UpdateShipHelp(m_iSelectedContinent, m_iSelectedShip, strHelpTxt);
				AS_SetMoreInfoHotlink(m_strMoreInfoHotlinkLabel, "Icon_LSCLICK_L3");
			}
		}
	}
	if(m_kSelectedPilot != none)
	{
		m_kSelectedShip = m_kSelectedPilot.GetShip();
	}
	else
	{
		m_kSelectedShip = none;
	}
}
simulated function bool HangarSlotAvailable()
{
	local int I;

	for(I=0; I < SU_XGHangarUI(GetMgr()).m_arrContinentsInfo.Length; ++I)
	{
		if(I != m_iSelectedContinent && SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[I].arrPilots.Length < class'SquadronUnleashed'.default.HANGAR_CAPACITY)
		{
			return true;
		}
	}
	return false;
}

simulated function OnTransferInterceptor()
{
	local int I;
	local bool bCanTransfer;
	local TDialogueBoxData kData;

	if(m_kSelectedPilot == none)
	{
		return;
	}
	bCanTransfer = false;
	for(I=0; I < SU_XGHangarUI(GetMgr()).m_arrContinentsInfo.Length; I++)
	{
		if(I != m_iSelectedContinent)
		{
			if(!GetMgr().ISCONTROLLED() && SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[I].arrPilots.Length < class'SquadronUnleashed'.default.HANGAR_CAPACITY)
			{
				GetMgr().AI().CostAlienSquad();//check for pending AirBase or HQ raid, if so Stat(106) would be 1
				if(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().STAT_GetStat(106) == 0)
				{
					bCanTransfer = true;
				}
			}
		}
	}
	if(bCanTransfer)
	{
		if(m_kSelectedPilot.GetShip() != none)
			GetMgr().m_kShip = m_kSelectedPilot.GetShip();
		if(m_kSelectedPilot.GetStatus() != ePilotStatus_Ready)
		{
			GetMgr().PlayBadSound();
		}
		else
		{
			GetMgr().PlayGoodSound();
			if(manager.IsMouseActive())
			{
				//this is a fix to UpdateShipHelp which used to ignore m_strCancelTransferButtonHelp (wrong filter in ActionScript)
				AS_UpdateShipHelp(m_iSelectedContinent, m_iSelectedShip, m_strCancelTransferButtonHelp);
			}
			GetMgr().GoToView(3);
		}			
	}
	else
	{
		if(!GetMgr().ISCONTROLLED())
		{
			GetMgr().AI().CostAlienSquad();//check for pending AirBase or HQ raid, if so Stat(106) would be 1
			if(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().STAT_GetStat(106) != 1)
			{
				kData.strTitle = "";
				kData.strText = m_strHangarsFullDialogText;
				kData.strCancel = "";
				XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).UIRaiseDialog(kData);
			}
			else
			{
				kData.strTitle = "";
				kData.strText = m_strHangarsFullDialogTitle;
				kData.strCancel = "";
				XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).UIRaiseDialog(kData);
			}
		}
	}
}
/** Transfer pilot*/
simulated function TransferShip()
{
	local XGParamTag kTag;
	local TDialogueBoxData kData;

	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
	kTag.StrValue0 = m_kSelectedPilot.GetCallsignWithRank();
	kTag.StrValue1 = SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iContinentTransferingFrom].strContinentName.StrValue;
	kTag.StrValue2 = SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iContinentTransferingTo].strContinentName.StrValue;
	kTag.IntValue0 = class'SquadronUnleashed'.default.PILOT_TRANSFER_HOURS;
	kData.strTitle = m_strConfirmTransferDialogTitle;
	kData.strText = class'XComLocalizer'.static.ExpandString(class'UIShipList'.default.m_strConfirmTransferDialogText);
	kData.strAccept = m_strConfirmTransferDialogAcceptText;
	kData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	kData.fnCallback = OnTransferDialogConfirm;
	XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).UIRaiseDialog(kData);
}
simulated function OnTransferDialogConfirm(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.TransferPilot(m_kSelectedPilot, SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iContinentTransferingTo].eCont);
		m_iSelectedContinent = m_iContinentTransferingTo;
		m_iSelectedShip = SU_XGHangarUI(GetMgr()).m_arrContinentsInfo[m_iSelectedContinent].arrPilots.Length;
	}
	GetMgr().GoToView(6);
}
function ShowPilotCard()
{	
	if(!m_bTransferingShip || m_iContinentTransferingTo == -1)
	{
		if(m_kSelectedPilot != none)
		{
			if(m_kSelectedPilot.GetShip() != none && m_iView != 7)
			{
				GetMgr().m_kShip = m_kSelectedPilot.GetShip();//not important yet just in case...
			}
			GetMgr().PlayGoodSound();
			OnLoseFocus();
			Hide();
			class'SU_Utils'.static.GetSquadronMod().UIShowPilotCard(m_kSelectedPilot);
		}
		else
		{
			GetMgr().PlayBadSound();
		}
	}
	else
	{
		GetMgr().PlayBadSound();
	}
}
simulated function OnCommand(string Cmd, string Arg)
{
	LogInternal(GetFuncName() @ Cmd);
	if(Cmd == "HangarsLoaded")
    {
		RealizeSelected();
    }
}
simulated function RealizeSelected(optional int iContinentOverride=-1, optional int iShipOverride=-1)
{
	`Log(GetFuncName() @ (iContinentOverride != -1 ? string(iContinentOverride) : string(m_iSelectedContinent)) @ (iShipOverride != -1 ? string(iShipOverride) : string(m_iSelectedShip)));
    AS_SetSelection(iContinentOverride != -1 ? iContinentOverride : m_iSelectedContinent, iShipOverride != -1 ? iShipOverride : m_iSelectedShip);
    UpdateButtonHelpOnSelectedItem();
}
function UpdateTitle()
{
	local string strTitle, strCost;
	local int iCosts;

	strTitle = m_strPilotRosterTitle;
	iCosts = class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.CalcMonthlyCosts();
	if(iCosts > 0)
	{
		strCost = "  ("$ class'XGHangarUI'.default.m_strLabelHireMonthlyCost @ class'XGScreenMgr'.static.ConvertCashToString(iCosts) $")";
		strTitle @= class'UIUtilities'.static.GetHTMLColoredText(strCost, eUIState_Good, 21);
	}
	SelfGfx().GetObject("titleField").SetString("htmlText", strTitle);
}
simulated function AS_SetSelection(int continentIndex, int shipIndex)
{
    SelfGfx().SetSelection(continentIndex, shipIndex);
}
simulated function AS_UpdateShipHelp(int continentIndex, int shipIndex, string Help)
{
	super.AS_UpdateShipHelp(continentIndex, shipIndex, Help);
}
DefaultProperties
{
	m_iView=6
	m_bCompactView=false
}
