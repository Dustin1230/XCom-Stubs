class SU_UIPilotCard extends UIItemCards;

/** 0-pilot summary, 1-career summary, 2-pilot customization*/
var int m_iView;

var SU_Pilot m_kPilot;
var SUGfx_PilotCard m_gfxMC;
var int m_iCurrentCareerSelection;
var SU_PilotRankMgr m_kRankMgr;
var localized string m_strConfirmNewNameDialogTitle;
var localized string m_strConfirmNewNameDialogText;
var localized string m_strConfirmNewCareerDialogText;
var localized string m_strConfirmNewCareerDialogTitle;
var localized string m_strLabelRenameButton;
var localized string m_strLabelDismissButton;
var localized string m_strLabelChangeCareerButton;
var localized string m_strTitleDismissPilot;
var localized string m_strTitleChooseCareer;
var localized string m_strLabelSummary;
var localized string m_strLabelRankRequirements;
var localized string m_strLabelRankBonuses;
var localized string m_strLabelSpecialTrait;
var localized string m_strLabelTotalDogfightTime;
var localized string m_strLabelServiceDuration;
var localized string m_strLabelNumDogfights;
var localized string m_strLabelSquadronBuffs;
var localized string m_strLabelTraitRestrictions;
var localized string m_strLabelGetRandomName;

simulated function Init(XComPlayerController _controller, UIFxsMovie _manager, TItemCard cardData)
{
	super.Init(_controller, _manager, cardData);
	manager.LoadScreen(self);
	m_kRankMgr = class'SU_Utils'.static.GetRankMgr();
}
function InitWitPilot(SU_Pilot kPilot, optional int InitView)
{
	m_kPilot = kPilot;
	m_iView = InitView;
	Init(XComPlayerController(class'SU_Utils'.static.PC()), class'SU_Utils'.static.PRES().GetHUD(), m_tItemCard);
	uicache.sAdd("SavedName", m_kPilot.GetCallsign());
	uicache.sAdd("SavedVoice", m_kPilot.VoiceSetPath);
}
simulated function OnInit()
{
    super(UI_FxsScreen).OnInit();
	Hide();
	SelfGfx().ExtendGfx();
	class'UIModUtils'.static.AS_OverrideClickButtonDelegate(SelfGfx().GetButton("button0"), OnCustomizeUI);
	class'UIModUtils'.static.AS_OverrideClickButtonDelegate(SelfGfx().GetButton("button1"), OnCareerUI);
	class'UIModUtils'.static.AS_OverrideClickButtonDelegate(SelfGfx().GetButton("button2"), OnDismissPilot);
	AS_InitializationComplete();
	PostInit();
}
function PostInit()
{
	if(!SelfGfx().m_bGfxReady)
	{
		SetTimer(0.05, false, GetFuncName());
		return;
	}
	GoToView(m_iView);
	Show();
	class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_PilotCard);
	if(m_kPilot.GetTeamKills() > 0)
	{
		class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_TeamKills);
	}
	uicache.bAdd("PilotCardTutorialShown", true);
	uicache.bAdd("PilotCareerTutorialShown", false);
}
function GoToView(int iNewView)
{
	if(m_iView != iNewView)
	{
		m_iView = iNewView;
	}
	if(m_iView == 1)
	{
		uicache.bUpdate("ConfirmNewCareer", false);
		if(!uicache.bFind("PilotCareerTutorialShown"))
		{
			class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_PilotCareer);
			uicache.bUpdate("PilotCareerTutorialShown", true);
		}
		SelfGfx().AS_SetCardImage(m_kRankMgr.GetCareerImgPath(m_kPilot.GetCareerPath().iType));
		SelfGfx().m_gfxCareerLabel.SetVisible(true);
		m_iCurrentCareerSelection = m_kRankMgr.m_arrCareers.Find('iType', m_kPilot.GetCareerPath().iType);
		class'UIUtilities'.static.ClampIndexToArrayRange(m_kRankMgr.m_arrCareers.Length, m_iCurrentCareerSelection);
	}
	else
	{
		SelfGfx().AS_SetCardImage("img:///gfxXcomIcons.XComIcons_I27B");//FIXME: career-specific images?
		SelfGfx().m_gfxCareerLabel.SetVisible(false);
	}
	RefreshNavigationHelp();
	UpdateData();
}
simulated function UpdateData()
{
	local int iLvl, iTempXPLoss;

	AS_ClearFlavorText();
	switch(m_iView)
	{
	case 0:
		SelfGfx().AS_SetCardTitle(m_kPilot.GetCallsignWithRank());
		AS_AddTacticalInfoCardData(m_strLabelSummary, BuildPilotSummary());
		if(m_kPilot.m_iCareerTrait + m_kPilot.m_iFirestormTrait > 0)
		{
			AS_AddTacticalInfoCardData(m_strLabelSpecialTrait, BuildTraitsSummary());
		}
		break;
	case 1:
		class'UIUtilities'.static.ClampIndexToArrayRange(m_kRankMgr.m_arrCareers.Length, m_iCurrentCareerSelection);
		SelfGfx().AS_SetCardTitle(m_strTitleChooseCareer);
		SelfGfx().AS_SetCardImage(m_kRankMgr.GetCareerImgPath(m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].iType));
		//SelfGfx().SetCareerLabel(Caps(m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].strName));
		SelfGfx().SetCareerSpinnerValue(Caps(m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].strName));
		AS_AddTacticalInfoCardData(m_strLabelSummary, m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].strDesc);
		if(m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].iType != m_kPilot.GetCareerType())
		{
			//cheat while showing alternative careeer
			iTempXPLoss = CalcXPLossOnCareerSwap();
			m_kPilot.m_iXP -= iTempXPLoss;
		}
		for(iLvl=1; iLvl < m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].arrTRanks.Length; ++iLvl)
		{
			if(m_kPilot.QualifiesForRank(iLvl, m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].iType) && (!m_kPilot.QualifiesForRank(iLvl+1, m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].iType) || iLvl == m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].arrTRanks.Length -1))
			{
				AS_AddTacticalInfoCardData(class'UIUtilities'.static.GetHTMLColoredText(m_kRankMgr.GetFullRankName(iLvl), eUIState_Good), GetRankSummary(iLvl, eUIState_Good));
			}
			else
			{
				AS_AddTacticalInfoCardData(m_kRankMgr.GetFullRankName(iLvl), GetRankSummary(iLvl));
			}
		}
		//revert the cheat
		m_kPilot.m_iXP += iTempXPLoss;
		break;
	case 2:
		SelfGfx().SetCareerSpinnerValue(m_kPilot.VoiceSetPath);
		AS_AddTacticalInfoCardData(m_strLabelSummary, m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].strDesc);
		uicache.bUpdate("ConfirmNewVoice", m_kPilot.VoiceSetPath != uicache.sFind("SavedVoice"));
		RefreshNavigationHelp();
		break;
	default:
	}
	uicache.bUpdate("ConfirmNewCareer", m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].iType != m_kPilot.GetCareerType());
}
function RefreshNavigationHelp()
{
	local string sCloseButtonLabel;

	switch(m_iView)
	{
	case 0:
		class'UIModUtils'.static.AS_OverrideClickButtonDelegate(SelfGfx().GetButton("button0"), OnCustomizeUI);
		class'UIModUtils'.static.AS_OverrideClickButtonDelegate(SelfGfx().GetButton("button2"), OnDismissPilot);
		AS_SetButtonHelp(0, CAPS(class'XGSoldierUI'.default.m_strLabelCustomize), manager.IsMouseActive() ? "" : class'UI_FxsGamepadIcons'.const.ICON_A_X);
		AS_SetButtonHelp(2, m_strLabelDismissButton, manager.IsMouseActive() ? "" : class'UI_FxsGamepadIcons'.const.ICON_Y_TRIANGLE);
		if(!class'SU_Utils'.static.GetSquadronMod().m_bDisablePilotXP)
		{
			AS_SetButtonHelp(1, m_kPilot.m_bCareerChoicePending ? class'UIUtilities'.static.GetHTMLColoredText(m_strTitleChooseCareer, eUIState_Warning) : m_strLabelChangeCareerButton, manager.IsMouseActive() ? "" : class'UI_FxsGamepadIcons'.const.ICON_X_SQUARE);
			AS_SetButtonEnabled(1, m_kPilot.GetStatus() == ePilotStatus_Ready || m_kPilot.m_bCareerChoicePending);
		}
		else
		{
			AS_SetButtonHelp(1, "");
		}
		AS_SetSpinnerVisibility(false);
		sCloseButtonLabel = m_strCloseCardLabel;
		break;
	case 1:
		AS_SetButtonHelp(0, "");
		AS_SetButtonHelp(1, "");
		AS_SetButtonHelp(2, "");
		AS_SetSpinnerVisibility(true);
		sCloseButtonLabel = m_strCloseCardLabel;
		break;
	case 2:
		class'UIModUtils'.static.AS_OverrideClickButtonDelegate(SelfGfx().GetButton("button0"), RenamePilotDialog);
		class'UIModUtils'.static.AS_OverrideClickButtonDelegate(SelfGfx().GetButton("button2"), PlayVoiceSample);
		AS_SetButtonHelp(0, m_strLabelRenameButton, manager.IsMouseActive() ? "" : class'UI_FxsGamepadIcons'.const.ICON_A_X);
		AS_SetButtonHelp(1, "");
		AS_SetSpinnerVisibility(true);
		AS_SetButtonHelp(2, CAPS(Localize("UITellMeMore", "PlayAudioText", "XComStrategyGame")), manager.IsMouseActive() ? "" : class'UI_FxsGamepadIcons'.const.ICON_Y_TRIANGLE);	
		sCloseButtonLabel = uicache.bFind("ConfirmNewVoice") ? class'UIUtilities'.default.m_strGenericConfirm : m_strCloseCardLabel;
		break;
	default:
		sCloseButtonLabel = m_strCloseCardLabel;
	}
    AS_SetHelp(sCloseButtonLabel, class'UI_FxsGamepadIcons'.static.GetBackButtonIcon());
}
simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
	local bool bHandled;

	if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg))
	{
		switch(Cmd)
		{
		case 501:
		case 352:
		case 373:
			if(m_iView == 1 || m_iView == 2)
			{
				PlayScrollSound();
				AlterSelection(1);
				UpdateData();
				bHandled = true;
				break;
			}
		case 503:
		case 356:
		case 372:
			if(m_iView == 1 || m_iView == 2)
			{
				PlayScrollSound();
				AlterSelection(-1);
				UpdateData();
				bHandled = true;
				break;
			}
		case class'UI_FxsInput'.const.FXS_BUTTON_A:
			if(m_iView == 2)
			{
				RenamePilotDialog();
				bHandled = true;
				break;
			}
			else if(m_iView == 0)
			{
				OnCustomizeUI();
				bHandled = true;
				break;
			}
		case class'UI_FxsInput'.const.FXS_BUTTON_X:
			if(m_iView == 0)
			{
				OnCareerUI();
				bHandled = true;
				break;
			}
		case class'UI_FxsInput'.const.FXS_BUTTON_Y:
			if(m_iView == 0)
			{
				OnDismissPilot();
				bHandled = true;
				break;
			}
			else if(m_iView == 2)
			{
				PlayVoiceSample();
				bHandled = true;
				break;
			}
		default:
			bHandled = false;
		}
	}
	if(!bHandled)
	{
		bHandled = super.OnUnrealCommand(Cmd, Arg);
	}
	return bHandled;
}
simulated function bool OnMouseEvent(int Cmd, array<string> args)
{
	local string targetCallback;
	local bool bHandled;

	if(Cmd == 391)
	{
		targetCallback = args[args.Length - 1];
		if(args[args.Length - 3] == "spinnerMC")
		{
			PlayScrollSound();
			if(targetCallback == "-1")
			{
				AlterSelection(1);
			}
			else if(targetCallback == "-2")
			{
				AlterSelection(-1);
			}
			UpdateData();
			bHandled = true;
		}
	}
	if(!bHandled)
	{
		bHandled = super.OnMouseEvent(Cmd, args);
	}
	return bHandled;
}
function AlterSelection(int iDirection)
{
	if(m_iView == 1)
	{
		m_iCurrentCareerSelection += iDirection;
		if(m_iCurrentCareerSelection > m_kRankMgr.m_arrCareers.Length-1)
		{
			m_iCurrentCareerSelection = 0;
		}
		else if(m_iCurrentCareerSelection < 0)
		{
			m_iCurrentCareerSelection = m_kRankMgr.m_arrCareers.Length-1;
		}
	}
	else if(m_iView == 2)
	{
		if(iDirection > 0)
		{
			m_kPilot.SetNextPossibleVoice();
		}
		else if(iDirection < 0)
		{
			m_kPilot.SetPreviousPossibleVoice();
		}
		if(IsTimerActive('PlayVoiceSample'))
		{
			ClearTimer('PlayVoiceSample');
		}
		SetTimer(0.50, false, 'PlayVoiceSample');
	}
}
function string BuildPilotSummary()
{
	local string strSummary;
	local int iMod;

	//SERVICE RECORD
	strSummary = m_strLabelServiceDuration $ ":" @ class'UIUtilities'.static.GetHTMLColoredText(string(m_kPilot.GetServiceDurationInDays()), eUIState_Highlight);
	strSummary $= "\n";
	strSummary $= m_strLabelNumDogfights $ ":" @ class'UIUtilities'.static.GetHTMLColoredText(string(m_kPilot.m_iNumDogfights), eUIState_Highlight);
	strSummary $= "\n";
	strSummary $= m_strLabelTotalDogfightTime $"  "$ class'UIUtilities'.static.GetHTMLColoredText(m_kPilot.DogfightTimeToString(), eUIState_Highlight);
	strSummary $= "\n";
	strSummary $= CAPS(class'SU_UIPilotRoster'.default.m_strKills) @ class'UIUtilities'.static.GetHTMLColoredText(m_kPilot.GetKills() @ "("$ m_kPilot.GetTeamKills() $")", eUIState_Highlight) $ (class'SU_Utils'.static.GetSquadronMod().m_bDisablePilotXP ? "" : "  "$ CAPS(class'SU_UIPilotRoster'.default.m_strXP) @ class'UIUtilities'.static.GetHTMLColoredText(string(m_kPilot.GetXP()), eUIState_Highlight));
	strSummary $= "\n\n";
	//CURRENT STATS
	iMod = m_kPilot.CalcTotalAimBonus();
	strSummary $= CAPS(class'SU_UIPilotRoster'.default.m_strAim) @ class'UIUtilities'.static.GetHTMLColoredText((iMod > 0 ? "+":"") $ string(iMod), eUIState_Highlight);
	iMod = class'SU_Utils'.static.GetRankDefBonus(m_kPilot.GetRank(), m_kPilot.GetCareerPath().iType);
	strSummary @= CAPS(class'SU_UIPilotRoster'.default.m_strDef) @ class'UIUtilities'.static.GetHTMLColoredText((iMod > 0 ? "+":"") $ string(iMod), eUIState_Highlight);
	iMod = 100 * (m_kPilot.CalcTotalDamageModifier() - 1.0f);
	strSummary @= CAPS(class'SU_UIPilotRoster'.default.m_strDamage) @ class'UIUtilities'.static.GetHTMLColoredText(iMod >= 0 ? "+"$string(iMod)$"%" : string(iMod)$"%", eUIState_Highlight);
	iMod = class'SU_Utils'.static.GetSquadronSizeAtRank(m_kPilot.GetRank(), m_kPilot.GetCareerType());
	strSummary $= "\n" $ CAPS(class'SU_UIPilotRoster'.default.m_strLabelSquadron) @ class'SU_UIPilotRoster'.default.m_strSize @ class'UIUtilities'.static.GetHTMLColoredText(string(iMod), eUIState_Highlight);
	iMod = class'SU_Utils'.static.GetRankTeamAimBonus(m_kPilot.GetRank(), m_kPilot.GetCareerType());
	strSummary @= CAPS(class'SU_UIPilotRoster'.default.m_strAim) @ class'UIUtilities'.static.GetHTMLColoredText((iMod > 0 ? "+":"") $ string(iMod), eUIState_Highlight);
	iMod = class'SU_Utils'.static.GetRankTeamDefBonus(m_kPilot.GetRank(), m_kPilot.GetCareerType());
	strSummary @= CAPS(class'SU_UIPilotRoster'.default.m_strDef) @ class'UIUtilities'.static.GetHTMLColoredText((iMod > 0 ? "+":"") $ string(iMod), eUIState_Highlight);

	return "<font size='18'>"$strSummary$"</font>";
}
function string BuildTraitsSummary()
{
	local string strSummary, strBuffs, strReqs;

	if(m_kPilot.m_iCareerTrait != 0)
	{
		strBuffs = class'UIUtilities'.static.GetHTMLColoredText(m_kPilot.TraitBuffsToString(), eUIState_Highlight);
		strReqs = m_kPilot.TraitReqsToString();
		strSummary = "'" $ CAPS(m_kRankMgr.m_arrTraitNames[m_kPilot.m_iCareerTrait]) $"'\n"$strBuffs;
		if(strReqs != "")
		{
			strSummary $= class'UIUtilities'.static.GetHTMLColoredText("\n"$ m_strLabelTraitRestrictions $":\n"$ strReqs, eUIState_Warning, 12);
		}
	}
	if(m_kPilot.m_iFirestormTrait != 0)
	{
		strBuffs = class'UIUtilities'.static.GetHTMLColoredText(m_kPilot.TraitBuffsToString(m_kPilot.m_iFirestormTrait), eUIState_Highlight);
		strReqs = m_kPilot.TraitReqsToString(m_kPilot.m_iFirestormTrait);
		strSummary $= (strSummary != "" ? "\n" : "");
		strSummary $= "'" $ CAPS(m_kRankMgr.m_arrTraitNames[m_kPilot.m_iFirestormTrait]) $"'\n"$strBuffs;
		strSummary $= class'UIUtilities'.static.GetHTMLColoredText("\n"$ m_strLabelTraitRestrictions $":\n"$ strReqs, eUIState_Warning, 12);
	}
	return strSummary;
}
function string BuildRankRequirementsSummary()
{
	local string strReqsSummary, strRankReqs;
	local int iLvl, iReq;
	local TPilotRank tRank;
	local TPilotCareerPath tCareer;
	local UIModGfxTextField gfxProbe;

	//gfxProbe is just "any" TextField - used to measure text width in pixels before pushing it on screen
	gfxProbe = UIModGfxTextField(manager.GetVariableObject(GetMCPath() $".theItemCard.stat0.statDiff", class'UIModGfxTextField'));
	tCareer = m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection];
	foreach tCareer.arrTRanks(tRank, iLvl)
	{
		if(iLvl != 0)
		{
			strRankReqs = m_kRankMgr.GetFullRankName(iLvl);
			while(100.0 - gfxProbe.AS_GetTextExtent(strRankReqs).GetFloat("width") > 2.5)
			{
				strRankReqs $= " ";
			}
			iReq = m_kRankMgr.GetKillsForRank(iLvl, tCareer.iType);
			strRankReqs @= class'SU_UIPilotRoster'.default.m_strKills @ iReq $ (iReq < 10 ? "  " : " ");
			if(!class'SU_Utils'.static.GetSquadronMod().m_bDisablePilotXP)
			{
				strRankReqs @= class'SU_UIPilotRoster'.default.m_strXP @ m_kRankMgr.GetXPForRank(iLvl, tCareer.iType);
			}
			if(m_kPilot.QualifiesForRank(iLvl, tCareer.iType) && (!m_kPilot.QualifiesForRank(iLvl+1, tCareer.iType) || iLvl == tCareer.arrTRanks.Length-1))
			{
				if(m_kPilot.GetKills() < iReq)//implies qualification based on TeamKills
				{
					strRankReqs = Repl(strRankReqs, class'SU_UIPilotRoster'.default.m_strKills @ iReq, "("$class'SU_UIPilotRoster'.default.m_strKills @ iReq$")"); 
				}
				strRankReqs = class'UIUtilities'.static.GetHTMLColoredText(strRankReqs, eUIState_Highlight);
			}
			strReqsSummary $= strRankReqs $"\n";
		}
	}
	return strReqsSummary;
	
}
/**DEPRACATED (though usable) - builds a table-style summary of career bonuses per rank*/
function string BuildRankBonusesSummary()
{
	local string strBuffsSummary, strRankBuffs, strRankName;
	local int iLvl, iMod;
	local float fOffest;
	local TPilotRank tRank;
	local TPilotCareerPath tCareer;
	local UIModGfxTextField gfxProbe;

	gfxProbe = UIModGfxTextField(manager.GetVariableObject(GetMCPath() $".theItemCard.stat0.statDiff", class'UIModGfxTextField'));
	tCareer = m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection];
	foreach tCareer.arrTRanks(tRank, iLvl)
	{
		if(iLvl != 0)
		{
			strRankBuffs = "";
			fOffest = 90.0;
			iMod = m_kRankMgr.GetRankAimBonus(iLvl, tCareer.iType);
			if(iMod > 0)
			{
				strRankBuffs $= class'SU_UIPilotRoster'.default.m_strAim @ "+" $ iMod;
				while(fOffest - gfxProbe.AS_GetTextExtent(strRankBuffs).GetFloat("width") > 2.5)
				{
					strRankBuffs $= " ";
				}
				fOffest += 90.0;
			}
			iMod = class'SU_Utils'.static.GetRankDefBonus(iLvl, tCareer.iType);
			if(iMod > 0)
			{
				strRankBuffs $= class'SU_UIPilotRoster'.default.m_strDef @ "+" $ iMod;
				while(fOffest - gfxProbe.AS_GetTextExtent(strRankBuffs).GetFloat("width") > 2.5)
				{
					strRankBuffs $= " ";
				}
				fOffest += 90.0;
			}
			iMod = 100 * (m_kRankMgr.GetRankDmgBonus(iLvl, tCareer.iType) - 1.0f);
			if(iMod > 0)
			{
				strRankBuffs $= class'SU_UIPilotRoster'.default.m_strDamage @ "+" $ iMod $ "%";
			}
			if(strRankBuffs != "")
			{
				strRankName = m_kRankMgr.GetShortRankName(iLvl);
				while(70.0 - gfxProbe.AS_GetTextExtent(strRankName).GetFloat("width") > 2.5)
				{
					strRankName $= " ";
				}
				strRankBuffs = strRankName $ strRankBuffs;
				strBuffsSummary $= strRankBuffs;
				strBuffsSummary $= "\n";
			}
		}
	}
	return strBuffsSummary;	
}
/**DEPRACATED (though usable) - builds a table-style summary of career team bonuses per rank*/
function string BuildRankTeamBonusesSummary()
{
	local string strBuffsSummary, strRankBuffs;
	local int iLvl, iMod;
	local float fOffset;
	local TPilotRank tRank;
	local TPilotCareerPath tCareer;
	local UIModGfxTextField gfxProbe;

	gfxProbe = UIModGfxTextField(manager.GetVariableObject(GetMCPath() $".theItemCard.stat0.statDiff", class'UIModGfxTextField'));
	tCareer = m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection];
	foreach tCareer.arrTRanks(tRank, iLvl)
	{
		if(iLvl != 0)
		{
			strRankBuffs = m_kRankMgr.GetShortRankName(iLvl);
			fOffset = 70.0;
			while(fOffset - gfxProbe.AS_GetTextExtent(strRankBuffs).GetFloat("width") > 2.5)
			{
				strRankBuffs $= " ";
			}
			
			iMod = m_kRankMgr.GetSquadronSizeAtRank(iLvl, tCareer.iType);
			strRankBuffs $= class'SU_UIPilotRoster'.default.m_strSize @ iMod;
			fOffset += 90;
			while(fOffset - gfxProbe.AS_GetTextExtent(strRankBuffs).GetFloat("width") > 2.5)
			{
				strRankBuffs $= " ";
			}
			
			iMod = m_kRankMgr.GetRankTeamAimBonus(iLvl, tCareer.iType);
			if(iMod > 0)
			{
				strRankBuffs @= " "$ class'SU_UIPilotRoster'.default.m_strAim @ "+" $ iMod;
				fOffset += 90.0;
				while(fOffset - gfxProbe.AS_GetTextExtent(strRankBuffs).GetFloat("width") > 2.5)
				{
					strRankBuffs $= " ";
				}
			}
			
			iMod = m_kRankMgr.GetRankTeamDefBonus(iLvl, tCareer.iType);
			if(iMod > 0)
			{
				strRankBuffs @= class'SU_UIPilotRoster'.default.m_strDef @ "+" $ iMod;
			}
			strBuffsSummary $= strRankBuffs;
			strBuffsSummary $= "\n";
		}
	}
	return strBuffsSummary;
}
/** Returns a text-style summary of rank requirements and bonuses for a given rank in the currently selected career type.*/
function string GetRankSummary(int iRank, optional int iColorState=eUIState_Highlight)
{
	local string strRankReqs, strRankPilotBuffs, strRankSquadronBuffs, strTraitBuffs, strTraitReqs;
	local int iNum;
	local TPilotCareerPath tCareer;

	tCareer = m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection];
	
	//rank requirements
	iNum = m_kRankMgr.GetKillsForRank(iRank, tCareer.iType);
	strRankReqs = class'SU_UIPilotRoster'.default.m_strKills @ iNum $ (iNum < 10 ? "  " : " ");
	if(!class'SU_Utils'.static.GetSquadronMod().m_bDisablePilotXP)
	{
		strRankReqs @= class'SU_UIPilotRoster'.default.m_strXP @ m_kRankMgr.GetXPForRank(iRank, tCareer.iType);
	}
	strRankReqs = m_strLabelRankRequirements $ "\n" $ class'UIUtilities'.static.GetHTMLColoredText(strRankReqs, iColorState);

	//rank individual pilot bonuses
	iNum = m_kRankMgr.GetRankAimBonus(iRank, tCareer.iType);
	if(iNum > 0)
	{
		strRankPilotBuffs $= class'SU_UIPilotRoster'.default.m_strAim @ "+" $ iNum $ "  ";
	}
	iNum = class'SU_Utils'.static.GetRankDefBonus(iRank, tCareer.iType);
	if(iNum > 0)
	{
		strRankPilotBuffs $= class'SU_UIPilotRoster'.default.m_strDef @ "+" $ iNum $ "  ";
	}
	iNum = 100 * (m_kRankMgr.GetRankDmgBonus(iRank, tCareer.iType) - 1.0f);
	if(iNum > 0)
	{
		strRankPilotBuffs $= class'SU_UIPilotRoster'.default.m_strDamage @ "+" $ iNum $ "%";
	}
	if(strRankPilotBuffs != "")
	{
		strRankPilotBuffs = m_strLabelRankBonuses $ "\n" $ class'UIUtilities'.static.GetHTMLColoredText(strRankPilotBuffs, iColorState);
	}
	else
	{
		strRankPilotBuffs = m_strLabelRankBonuses $ "\n" $ class'UIUtilities'.static.GetHTMLColoredText( class'UISituationRoom'.default.m_strNone, iColorState);
	}
	
	//rank squadron bonuses			
	iNum = m_kRankMgr.GetSquadronSizeAtRank(iRank, tCareer.iType);
	strRankSquadronBuffs $= class'SU_UIPilotRoster'.default.m_strSize @ iNum $ "  ";

	iNum = m_kRankMgr.GetRankTeamAimBonus(iRank, tCareer.iType);
	if(iNum > 0)
	{
		strRankSquadronBuffs $= class'SU_UIPilotRoster'.default.m_strAim @ "+" $ iNum $ "  ";
	}
			
	iNum = m_kRankMgr.GetRankTeamDefBonus(iRank, tCareer.iType);
	if(iNum > 0)
	{
		strRankSquadronBuffs $= class'SU_UIPilotRoster'.default.m_strDef @ "+" $ iNum;
	}
	strRankSquadronBuffs = m_strLabelSquadronBuffs $ "\n" $ class'UIUtilities'.static.GetHTMLColoredText(strRankSquadronBuffs, iColorState);

	//trait buffs and restrictions
	if(tCareer.arrTRanks[iRank].iTraitType > 0)
	{
		strTraitBuffs = m_strLabelSpecialTrait $ ": "$ class'UIUtilities'.static.GetHTMLColoredText("'" $ m_kRankMgr.m_arrTraitNames[tCareer.arrTRanks[iRank].iTraitType] $"'\n" $ m_kPilot.TraitBuffsToString(tCareer.arrTRanks[iRank].iTraitType), iColorState);
		strTraitReqs = m_kPilot.TraitReqsToString(tCareer.arrTRanks[iRank].iTraitType);
		if(strTraitReqs != "")
		{
			strTraitReqs = m_strLabelTraitRestrictions $ "\n" $ class'UIUtilities'.static.GetHTMLColoredText(strTraitReqs, iColorState);
		}
	}
	return strRankReqs $ "\n" $ strRankPilotBuffs $ (strRankSquadronBuffs != "" ? "\n" $ strRankSquadronBuffs : "") $ "\n" $ strTraitBuffs $ "\n" $ strTraitReqs;
}
function SUGfx_PilotCard SelfGfx()
{
	if(m_gfxMC == none)
	{
		m_gfxMC = SUGfx_PilotCard(manager.GetVariableObject(string(GetMCPath()), class'SUGfx_PilotCard'));
	}
	return m_gfxMC;
}
function RenamePilotDialog()
{
	local TInputDialogData tData;

	tData.strTitle = m_strLabelRenameButton;
	tData.strInputBoxText = m_kPilot.GetCallsign();
	tData.fnCallback = OnCloseRenameDialog;
	controllerRef.m_Pres.UIInputDialog(tData);
	PushState('RenamingPilot');
}
function OnRandomPilotNameRequest();//just a declaration to pass as callback, the function is defined in state 'RenamingPilot'

function OnCloseRenameDialog(string strInputName)
{
	class'UIUtilities'.static.StripUnsupportedCharactersFromUserInput(strInputName);
	if(strInputName != "")
	{
		RenamePilot(strInputName);
	}
}
/** Applies new name to the pilot. If the param is skipped it will give a random name.*/
function RenamePilot(optional string strNewName)
{
	if(m_kPilot != none)
	{
		m_kPilot.Rename(strNewName, true);
		uicache.bAdd("ConfirmNewName", true);
		UpdateData();
		PilotRosterSetForceUpdate();
	}
	else
		LogInternal("WARNING:" @ GetFuncName() @ "called without valid pilot actor (kPilot=none).");
}
function OnDismissPilot()
{
	local XGParamTag kTag;
	local TDialogueBoxData kData;

	if(class'SU_Utils'.static.PRES().ISCONTROLLED() || m_kPilot == none)
	{
		PlayBadSound();
		return;
	}
	else
	{
		PlayOpenSound();
	}
	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
	kTag.StrValue0 = m_kPilot.GetCallsignWithRank();
	kData.eType = 2;
	kData.strTitle = m_strTitleDismissPilot;
	kData.strText = class'XComLocalizer'.static.ExpandString(class'UIShipSummary'.default.m_strDismissShipConfirmDialogText);
	kData.strAccept = class'UIShipSummary'.default.m_strDismissShipConfirmDialogAcceptText;
	kData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	kData.fnCallback = OnDismissDialogConfirm;
	XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).UIRaiseDialog(kData);
}
simulated function OnDismissDialogConfirm(EUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		PlayGoodSound();
		DismissPilot();
	}
	else
	{
		PlayCloseSound();
	}
}
function DismissPilot()
{
	if(m_kPilot != none)
	{
		class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.RemovePilot(m_kPilot);
		PilotRosterSetForceUpdate();
		OnClose("Dismissed");
	}
	else
		LogInternal("WARNING:" @ GetFuncName() @ "called without valid pilot actor (kPilot=none).");
}

function PilotRosterSetForceUpdate()
{
	local SU_UIPilotRoster kPilotList;

	kPilotList = class'SU_Utils'.static.GetSquadronMod().m_kPilotRosterUI;
	if(kPilotList != none)
	{
	 	kPilotList.m_bUpdateDataOnReceiveFocus = true;
	}
}
function OnCustomizeUI()
{
	GoToView(2);
}
function OnCareerUI()
{
	if(m_kPilot.GetStatus() != ePilotStatus_Ready && !m_kPilot.m_bCareerChoicePending || class'SU_Utils'.static.GetSquadronMod().m_bDisablePilotXP)
	{
		class'SU_Utils'.static.GetHelpMgr().ShowErrorMsg(eSUError_PilotStatusNotValid);
		PlayBadSound();
	}
	else
	{
		GoToView(1);
	}
}
simulated function bool OnClose(optional string strOption)
{
	if(strOption == "Dismissed")
	{
		CloseScreen();
	}
	else if(m_iView == 1)
	{
		if(uicache.bFind("ConfirmNewCareer"))
		{
			ConfirmNewCareerDialog();
		}
		else
		{
			GoToView(0);
		}
	}
	else if(m_iView == 2)
	{
		if(uicache.bFind("ConfirmNewName"))
		{
			ConfirmNewNameDialog();
		}
		else if(uicache.bFind("ConfirmNewVoice"))
		{
			ConfirmNewVoiceDialog();
		}
		else
		{
			GoToView(0);
		}
	}
	else
	{
		CloseScreen();
	}
	return true;
}
function CloseScreen()
{
	PlayCloseSound();
	manager.RemoveScreen(self);
	class'SU_Utils'.static.GetSquadronMod().m_kPilotCard = none;
	if(class'SU_Utils'.static.GetSquadronMod().m_kPilotRosterUI != none)
	{
		class'SU_Utils'.static.GetSquadronMod().m_kPilotRosterUI.OnReceiveFocus();
	}
	Destroy();
}
function ConfirmNewNameDialog()
{
	local TDialogueBoxData kData;

	kData.strTitle = m_strConfirmNewNameDialogTitle;
	kData.strText = m_strConfirmNewNameDialogText;
	kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	kData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	kData.fnCallback = OnNewNameDialogConfirm;
	XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).UIRaiseDialog(kData);
}
function OnNewNameDialogConfirm(EUIAction eAction)
{
	uicache.bUpdate("ConfirmNewName", false);
	if(eAction != eUIAction_Accept)
	{
		m_kPilot.Rename(uicache.sFind("SavedName"));
	}
	OnClose();
}
function ConfirmNewCareerDialog()
{
	local TDialogueBoxData kData;
	local XGParamTag kTag;

	kData.strTitle = m_strConfirmNewCareerDialogTitle;
	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
	kTag.StrValue0 = m_kPilot.GetCallsignWithRank();
	kTag.StrValue1 = m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].strName;
	kData.strText = class'XComLocalizer'.static.ExpandString(m_strConfirmNewCareerDialogText);
	kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	kData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	if(!m_kPilot.m_bCareerChoicePending)
	{
		kTag.IntValue0 = m_kRankMgr.CalcDaysToSwapCareer(m_kPilot.GetRank());
		kData.strText $= "\n\n";
		kData.strText $= class'XComLocalizer'.static.ExpandString(class'SquadronUnleashed'.default.m_strDaysOutOfService);
	}
	kData.fnCallback = OnNewCareerDialogConfirm;
	XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).UIRaiseDialog(kData);
}
function OnNewCareerDialogConfirm(EUIAction eAction)
{
	uicache.bUpdate("ConfirmNewCareer", false);
	if(eAction == eUIAction_Accept)
	{
		if(!m_kPilot.m_bCareerChoicePending && m_kPilot.GetRank() > 0)
		{
			m_kPilot.m_iHoursUnavailable = m_kRankMgr.CalcDaysToSwapCareer(m_kPilot.GetRank()) * 24;
			m_kPilot.m_iXP -= CalcXPLossOnCareerSwap();
			m_kPilot.m_iStatus = ePilotStatus_Retraining;
		}
		m_kPilot.SetCareerPath(m_kRankMgr.m_arrCareers[m_iCurrentCareerSelection].iType, true);//true forces new career
		m_kPilot.UpdateRank();
		PilotRosterSetForceUpdate();
	}
	OnClose();
}
function ConfirmNewVoiceDialog()
{
	local TDialogueBoxData tData;

	tData.strTitle = CAPS(class'XGCustomizeUI'.default.m_strVoiceSpinner);
	tData.strText = CAPS(Localize("UIKeybindingsPCScreen", "m_strSaveAndExitButtonLabel", "XComGame") @ "?");
	tData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	tData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	tData.fnCallback = OnCloseConfirmVoiceCallback;
	controllerRef.m_Pres.UIRaiseDialog(tData);
}
function OnCloseConfirmVoiceCallback(EUIAction eAction)
{
	uicache.bUpdate("ConfirmNewVoice", false);
	if(eAction == eUIAction_Accept)
	{
		PlayGoodSound();
		uicache.sUpdate("SavedVoice", m_kPilot.VoiceSetPath);
	}
	else
	{
		PlayCloseSound();
		m_kPilot.VoiceSetPath = uicache.sFind("SavedVoice");
	}
	OnClose();
}
function int CalcXPLossOnCareerSwap()
{
	local int iXPLoss;
	
	if(m_kPilot.IsAtMaxRank())
	{
		iXPLoss = class'SU_Utils'.static.GetRankMgr().GetXPGap(m_kPilot.GetRank()-1, m_kPilot.GetRank(), m_kPilot.GetCareerType()); 
	}
	else
	{
		iXPLoss = class'SU_Utils'.static.GetRankMgr().GetXPGap(m_kPilot.GetRank(), m_kPilot.GetRank() + 1, m_kPilot.GetCareerType()); 
	}
	return iXPLoss;
}
function PlayVoiceSample()
{
	m_kPilot.PlayRandomCue();
}
function AS_ClearFlavorText()
{
	SelfGfx().ClearFlavorTxt();
}
function PlayGoodSound()
{
    Sound().PlaySFX(SNDLIB().SFX_UI_Yes);
}
function PlayBadSound()
{
    Sound().PlaySFX(SNDLIB().SFX_UI_No);
}
function PlayOpenSound()
{
    Sound().PlaySFX(SNDLIB().SFX_UI_BigOpen);
}
function PlayCloseSound()
{
    Sound().PlaySFX(SNDLIB().SFX_UI_BigClose);
}
function PlayScrollSound()
{
	PlaySound(SoundCue(DynamicLoadObject("SoundUI.MenuScrollCue", class'SoundCue', true)));
}
function XGSoundMgr Sound()
{
    return XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).m_kSoundMgr;
}
function XComHQSoundCollection SNDLIB()
{
    return XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).m_kSoundMgr.m_kSounds;
}
function AS_SetButtonHelp(int iButton, string strButtonLabel, optional string strIcon)
{
	SelfGfx().SetButonLabel("button"$iButton, strButtonLabel);
	SelfGfx().GetButton("button"$iButton).AS_SetIcon(strIcon);
	SelfGfx().GetButton("button"$iButton).SetVisible(strButtonLabel != "");
}
function AS_SetButtonEnabled(int iButton, bool bEnableButton)
{
	if(bEnableButton)
	{
		SelfGfx().SetEnabled("button"$iButton);
	}
	else
	{
		SelfGfx().SetDisabled("button"$iButton);
	}
}
function AS_SetSpinnerVisibility(bool bSpinnerVisible)
{
	SelfGfx().GetCareerSpinner().SetVisible(bSpinnerVisible);
}
state RenamingPilot
{
	function UpdateRenameButtonHelp()
	{
		local UINavigationHelp kHelpBar;
		local UIInputDialogue kDialogUI;

		kDialogUI = controllerRef.m_Pres.m_kInputDialog;
		kHelpBar = kDialogUI.m_kHelpBar;
		kHelpBar.ClearButtonHelp();
		kHelpBar.AddLeftHelp(m_strLabelGetRandomName, Class'UI_FxsGamepadIcons'.static.GetBackButtonIcon(), OnRandomPilotNameRequest);
		kHelpBar.AddRightHelp(Class'UIUtilities'.default.m_strGenericConfirm, Class'UI_FxsGamepadIcons'.static.GetAdvanceButtonIcon(), kDialogUI.OnMouseAccept);
	}
	function OnRandomPilotNameRequest()
	{
		controllerRef.m_Pres.m_kInputDialog.SetData(m_strLabelRenameButton, 27, Split(class'XGLocalizedData'.default.ShipWeaponFlavorTxt[Rand(245) + 11], " ",true));
		//FIXME: in test phase randomization of name scrolls through PossibleVoiceSet list
		m_kPilot.SetNextPossibleVoice();
		m_kPilot.PlayRandomCue();
	}
Begin:
	while(controllerRef.m_Pres.m_kInputDialog == none 
	|| controllerRef.m_Pres.m_kInputDialog.m_kHelpBar == none 
	|| controllerRef.m_Pres.m_kInputDialog.m_kHelpBar.m_arrButtonClickDelegates.Length < 2)
	{
		Sleep(0.0);
	}

	UpdateRenameButtonHelp();

	while(controllerRef.m_Pres.m_kInputDialog != none)
	{
		Sleep(0.0);
	}
	PopState();
}
DefaultProperties
{
}