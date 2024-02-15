
class SU_UFORadarContactAlert extends UIMissionControl_UFORadarContactAlert
	config(SquadronUnleashed);

var XGShip_UFO m_kUFO;
var localized string m_strLabelChanceToWin;
var localized string m_strLabelLeaderBonus;

simulated function GoToView(int iView);

simulated function PanelInit(XComPlayerController _controller, UIFxsMovie _manager, UI_FxsScreen _screen, optional delegate<OnCommandCallback> CommandFunction)
{
   if(_screen != none && _controller != none && _manager != none)
   {
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
		//screen.AddPanel(self);
		if(!DependantVariablesAreInitialized())
		{
			PushState('PanelInit_WaitForDependantVariablesToInit');
		}
		else
		{
			BaseOnDependantVariablesInitialized();
		}
   }
}
event Destroyed()
{
	if(m_kInterceptMgr != none)
	{
		m_kInterceptMgr.Destroy();
	}
}
simulated function CloseAlert(optional int inputCode=-1)
{
	`Log(inputCode @ self, class'SquadronUnleashed'.default.bVerboseLog,GetFuncName());
	switch(inputCode)
	{
	case 0:
		if(GetStateName() == 'UFOContact')
		{
			GetMgr().GoToView(4);
			BeginInterception(m_kUFO);
			break;
		}
	default:
		if(screen == none)
		{
			GetMgr().OnAlertInput(inputCode);
		}
		else
		{
			//fix the bug of not destroying XGInterception on BackButton press
			if(InStr(GetScriptTrace(), "OnLaunchButtonPress") < 0 && m_kInterceptMgr != none && m_kInterceptMgr.m_kInterception != none)
			{
				m_kInterceptMgr.m_kInterception.Destroy();
			}
			super.CloseAlert(inputCode);
		}
	}
}
simulated function BeginInterception(XGShip_UFO kTarget)
{
	`Log("BeginInterception within SU_UFORadarContactAlert starting", class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
    m_kUFO = kTarget;
    if(SU_XGInterceptionUI(m_kInterceptMgr) == none)
    {
		if(m_kInterceptMgr != none)
		{
			m_kInterceptMgr.Destroy();
		}
		`Log("Spawning SU_XGInterceptionUI", class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
        m_kInterceptMgr = Spawn(class'SU_XGInterceptionUI', self);
        m_kInterceptMgr.m_kUFO = kTarget;
        SU_XGInterceptionUI(m_kInterceptMgr).Init(0);
    }
	SelfGfx().SetupGfx();//FIXME
    if(m_kInterceptMgr.m_akIntDistance.Length > 0)
    {
        m_nCachedState = 'ShipSelection';
        if(IsInited())
        {
			GotoState(m_nCachedState);
        }
    }
}

simulated function UpdateData()
{
    local int I, colorState;
    local TMCAlert kAlert;
    local array<string> speciesList;
    local string formattedSpecies1, formattedSpecies2;
	local SU_UFOSquadron kUFOS;

    if(m_kUFO != none && m_kUFO.m_iStatus == 0)
	{
		class'SU_Utils'.static.DetermineUFOStance(m_kUFO);
		SU_XGInterceptionUI(m_kInterceptMgr).m_iUFOStance = class'SU_Utils'.static.GetStance(m_kUFO);
	}
	kAlert = GetMgr().m_kCurrentAlert;
//	`Log("Starting UpdateUFOData for: " $ string(m_kUFO), true, 'SquadronUnleashed');
    colorState = ((XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().IsHyperwaveActive()) ? 10 : 3);
    AS_SetTitle(class'UIUtilities'.static.GetHTMLColoredText(Caps(kAlert.txtTitle.StrValue), colorState));
	if(m_kInterceptMgr != none)
	{
		AS_SetContact(class'UIUtilities'.static.GetHTMLColoredText(Caps(kAlert.arrLabeledText[0].strLabel), colorState), kAlert.arrLabeledText[0].StrValue @ ((m_kInterceptMgr.m_kInterception.m_arrInterceptors.Length > 0) ? " (" $ class'SU_Utils'.static.StanceToString(m_kUFO) $ ", " @ SU_XGInterception(m_kInterceptMgr.m_kInterception).EscapeTimeToString() $ "s)" : " (" $ class'SU_Utils'.static.StanceToString(m_kUFO) $ ")"));
	}
	else
	{
		AS_SetContact(class'UIUtilities'.static.GetHTMLColoredText(Caps(kAlert.arrLabeledText[0].strLabel), colorState), kAlert.arrLabeledText[0].StrValue @ " (" $ class'SU_Utils'.static.StanceToString(m_kUFO) $ ")");
	}
	AS_SetLocation(class'UIUtilities'.static.GetHTMLColoredText(Caps(kAlert.arrLabeledText[1].strLabel), colorState), kAlert.arrLabeledText[1].StrValue);
    
	//combine separated Size and Class into combined 'Size (UFO Class):'
	AS_SetSize(class'UIUtilities'.static.GetHTMLColoredText(Caps(Left(kAlert.arrLabeledText[2].strLabel, InStr(kAlert.arrLabeledText[2].strLabel, ":")) @ "(" $ Left(kAlert.arrLabeledText[3].strLabel, InStr(kAlert.arrLabeledText[3].strLabel, ":")) $ "):"), colorState), kAlert.arrLabeledText[2].StrValue @ "(" $ (m_kLocalMgr.GEOSCAPE().CanIdentifyCraft(m_kUFO.GetType()) ? kAlert.arrLabeledText[3].StrValue : " ??? ") $ ")");
	
	//display HP / Hull for researched UFO or 'Unidentified' for not researched
    AS_SetClass(class'UIUtilities'.static.GetHTMLColoredText(Caps(class'SquadronUnleashed'.default.m_strLabelHullStrength $ ":"), colorState), (GetMgr().LABS().IsResearched(m_kUFO.GetType() + 57)) ? string(m_kUFO.m_iHP) @ "/" @ string(m_kUFO.GetHullStrength()) : CAPS(Left(class'XGGreyMarketUI'.default.m_strNotResearched,1)) $ Locs(Mid(class'XGGreyMarketUI'.default.m_strNotResearched, 1)));
    if(colorState == 10)
    {
        ParseStringIntoArray(kAlert.arrLabeledText[5].StrValue, speciesList, "//", true);
        while(I < speciesList.Length)
        {
           if(I < 6)
            {
                formattedSpecies1 $= speciesList[++I];
                if((I < 6) && I < speciesList.Length)
                {
                    formattedSpecies1 $= "\\n";
                }
            }
            else
            {
                formattedSpecies2 $= speciesList[++I];
                if(I < speciesList.Length)
                {
                    formattedSpecies2 $= "\\n";
                }
            }
        }
        AS_SetHyperwaveData(m_strHyperwavePanelTitle, Caps(kAlert.arrLabeledText[4].strLabel), kAlert.arrLabeledText[4].StrValue, Caps(kAlert.arrLabeledText[3].strLabel), kAlert.arrLabeledText[3].StrValue $ (" (" $ (string(I) $ " species) ")), Caps(kAlert.arrLabeledText[5].strLabel), formattedSpecies1, formattedSpecies2);
    }
    if(m_nCachedState == 'UFOContact')
    {
    if(colorState == 10)
    {
        AS_SetHyperwaveDataSlim(m_strHyperwavePanelTitle, Caps(kAlert.arrLabeledText[4].strLabel), kAlert.arrLabeledText[4].StrValue);
    }
        UpdateButtonText();
    }
	SelfGfx().SetEscortTitle(CAPS(class'XGFundingCouncil'.default.m_strMissionNames[eFCM_CommercialExtraction])$":");
	kUFOS = class'SU_Utils'.static.GetUFOSquadron(m_kUFO);
	kUFOS.CleanUpEscortList();
	if(kUFOS.m_arrEscort.Length > 0)
	{
		formattedSpecies1 ="";
		for(I=0; I < kUFOS.m_arrEscort.Length; I++)
		{
			formattedSpecies1 $= GetMgr().ITEMTREE().GetShip(EShipType(kUFOS.m_arrEscort[I].iType)).strName @ class'SU_Utils'.static.StanceToString(none, kUFOS.m_arrEscort[I].iStance);
			if(I+1 < kUFOS.m_arrEscort.Length)
			{
				formattedSpecies1 $= "\n";
			}
		}
		SelfGfx().SetEscortInfo(formattedSpecies1);
	}
	else
	{
		SelfGfx().SetEscortInfo("None");
	}
}
function AS_FixHTMLTextForShip(int iShipIdx)
{
	local GfxObject gfxObj;
	local UIModGfxTextField gfxText;

	gfxObj = screen.manager.GetVariableObject(GetMCPath() $ ".shipListMC.ship" $ iShipIdx);
	gfxText = UIModGfxTextField(gfxObj.GetObject("name", class'UIModGfxTextField'));
	gfxText.SetFloat("_height", 64);
	gfxText.SetFloat("_y", 25);
	gfxText.m_FontSize = 18.0;
	gfxText.m_sFontFace="$TitleFont";
	gfxText.SetHTMLText(gfxText.GetString("htmlText"));
	
	gfxText = UIModGfxTextField(gfxObj.GetObject("weapon", class'UIModGfxTextField'));
	gfxText.m_FontSize=17.0;
	gfxText.m_sFontFace="$NormalFont";
	gfxText.SetHTMLText(gfxText.GetString("htmlText"));
	
	gfxText = UIModGfxTextField(gfxObj.GetObject("status", class'UIModGfxTextField'));
	gfxText.m_FontSize=17.0;
	gfxText.SetHTMLText(gfxText.GetString("htmlText"));
}
function int GetSelectedShip()
{
	return m_iSelectedShip & 255;
}
state ShipSelection
{
	event BeginState(name PreviousStateName)
	{
		`Log("BeginState ShipSelection within SU_UFORadarContactAlert", class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
		m_bShowBackButtonOnMissionControl = true;
		SU_XGInterceptionUI(m_kInterceptMgr).bSortShipList = class'SquadronUnleashed'.default.bAutoSortShipList;
		UIMissionControl(screen).ShowBackButtonForAlert();
		if(IsInited())
		{
			SU_XGInterception(m_kInterceptMgr.m_kInterception).UpdateContactTime(0, true);
			SelfGfx().SetupGfx();
			UpdateData();
			UIMissionControl(screen).m_kHelpBar.AddCenterHelp(CAPS(class'XGInterceptionUI'.default.m_strLabelChooseInterceptors), "Icon_X_SQUARE", OnLaunchButtonPress, true);
			SetTimer(0.10,true,'AdjustLaunchButtonPosition');
			InitTutorial();
		}
	}
	function InitTutorial()
	{
		local XGShip_Interceptor kJet;
		local TIntDistance tInt;
		local bool bDamaged, bLeaderBuffs;

		if(class'SU_Utils'.static.GetSquadronMod().m_bTutorial)
		{
			foreach m_kInterceptMgr.m_akIntDistance(tInt)
			{
				kJet = tInt.kInterceptor;
				if(!bDamaged && kJet.IsDamaged() && class'SU_XGInterceptionUI'.static.CanBeLaunched(kJet, true))
				{
					bDamaged = true;
				}
				else if(!bLeaderBuffs && class'SU_Utils'.static.GetPilot(kJet).GivesTeamBuffs())
				{
					bLeaderBuffs = true;
				}
			}
			class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_SelectShips);
			class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_MeaningOfTactics);
			class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_UFOTactics);
			if(SU_XGInterception(m_kInterceptMgr.m_kInterception).m_arrUFOs.Length > 1)
			{
				class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_UFOSquadron);	
			}
			if(m_kUFO.m_iCounter > 3)
			{
				class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_WeaponToggling);
			}
			if(bDamaged)
			{
				class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_SendingDamagedShips);
			}
			if(bLeaderBuffs)
			{
				class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_LeaderBuffs);	
			}
		}
	}
	simulated function OnReceiveFocus()
	{
		super.OnReceiveFocus();
		UIMissionControl(screen).ShowBackButtonForAlert();
		UIMissionControl(screen).m_kHelpBar.AddCenterHelp(CAPS(SU_XGInterceptionUI(m_kInterceptMgr).GetLaunchButtonLabel()), "Icon_X_SQUARE", OnLaunchButtonPress, m_kInterceptMgr.m_kInterception.m_arrInterceptors.Length == 0);
		SetTimer(0.10, true, 'AdjustLaunchButtonPosition');
		m_kInterceptMgr.UpdateLaunchButton();
	}
	simulated function OnLoseFocus()
	{
		super.OnLoseFocus();
		UIMissionControl(screen).m_kHelpBar.ClearButtonHelp();
	}
	simulated function UpdateData()
	{
		local TIntJet kJet;

		`Log("UpdateData within SU_UFORadarContactAlert starting", class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
		global.UpdateData();
		foreach m_kInterceptMgr.m_kSquadron.arrJets(kJet)
		{
			AS_AddShip(kJet.txtJetName.StrValue, kJet.txtOffense.StrValue, class'UIUtilities'.static.GetHTMLColoredText(kJet.txtStatus.StrValue, kJet.txtStatus.iState, 17), class'UIUtilities'.static.GetShipIconLabel(kJet.EShipType), kJet.iState == 1);
		}        
		AS_ActivateShipList(Caps(m_kInterceptMgr.m_strLabelLaunchFightersPC));
		SelfGfx().m_gfxLeaderFlag.SetVisible(false);
		foreach m_kInterceptMgr.m_kSquadron.arrJets(kJet)
		{
			AS_SetShipHighlight(kJet.iIndex, m_kInterceptMgr.m_kInterception.HasInterceptor(m_kInterceptMgr.m_akIntDistance[kJet.iIndex].kInterceptor), m_kInterceptMgr.m_akIntDistance[kJet.iIndex].kInterceptor.IsDamaged());
			UpdateShipAmmoDisplay(kJet.iIndex);
			UpdateDistanceIndicator(kJet.iIndex);
			if(SU_XGInterception(m_kInterceptMgr.m_kInterception).m_kSquadronLeader != none &&  class'SU_Utils'.static.GetPilot(m_kInterceptMgr.m_akIntDistance[kJet.iIndex].kInterceptor) == SU_XGInterception(m_kInterceptMgr.m_kInterception).m_kSquadronLeader)
			{
				UpdateLeaderFlag(kJet.iIndex);
			}
		}
		UpdateSquadronBuffsInfo();
		UpdateOddsInfo();
		SelfGfx().SetObject("highlighted", none);
		RealizeSelected(m_iSelectedShip == 0 ? 256 : m_iSelectedShip);
		SelfGfx().HideButton2();
	}

	simulated function bool OnUnrealCommand(int Cmd, int Arg)
	{
		local bool bHandled;

		bHandled = super.OnUnrealCommand(Cmd, Arg); //let the original code handle the command first
		if(!bHandled)
		{
			switch(Cmd)
			{
				case 526:
				case 302:
					OnLaunchButtonPress();
					break;
				case 571:
				case 303:
					ToggleInterceptor(m_kInterceptMgr.m_akIntDistance[255 & m_iSelectedShip].kInterceptor);
					break;
				default:
					bHandled = false;
			}
		}
		return bHandled;
	}
	function ToggleInterceptor(XGShip_Interceptor kJet)
	{
		local int iErrorCode;

		iErrorCode = -1;
		if(class'SU_XGInterceptionUI'.static.CanBeLaunched(kJet))
		{
			m_kInterceptMgr.m_kInterception.ToggleInterceptor(kJet);
			UpdateStartingDistance(kJet);
			AS_DeactivateShipList();
			m_kInterceptMgr.UpdateView();
			UpdateData();
		}
		else if(class'SU_XGInterceptionUI'.static.CanBeLaunched(kJet, true, iErrorCode))
		{
			class'SU_Utils'.static.GetSquadronMod().UIAssignPilot(kJet);
		}
		else
		{
			GetMgr().PlayBadSound();
			class'SU_Utils'.static.GetHelpMgr().ShowErrorMsg(iErrorCode, 0.70);
		}
	}
	simulated function bool OnMouseEvent(int Cmd, array<string> args)
	{
		local string callbackObj, tmp;
		local int buttonCode;
		
		//callbackObj is the gfx id of screen element: "ship1, ship2..." or "button_0, button_1)
		callbackObj = args[args.Length - 1];
		if(InStr(callbackObj, "ship") != -1 && Cmd == 391)
		{
			tmp = Split(callbackObj, "ship", true);
			buttonCode = int(tmp);
			ToggleInterceptor(m_kInterceptMgr.m_akIntDistance[buttonCode].kInterceptor);
			return true;
		}
		return super.OnMouseEvent(Cmd, args);
	}
	function OnLaunchButtonPress()
	{
		if(!IsFocused())
		{
			return;
		}
		//if no ships selected
		if(m_kInterceptMgr.m_kInterception.m_arrInterceptors.Length == 0)
		{
			m_kInterceptMgr.PlayBadSound();
		}
		//otherwise...
		else
		{
			//force sorting of the array of jets
			if(SU_XGInterceptionUI(m_kInterceptMgr).bSortShipList == false)
			{
				SU_XGInterceptionUI(m_kInterceptMgr).bSortShipList = true;
				m_kInterceptMgr.UpdateSquadron();
			}
			//close alert and launch jets
			//Remove();//FIXME ? CloseAlert() calls Remove
			CloseAlert();
			m_kInterceptMgr.OnLaunch();
		}
	}
	simulated function RealizeSelected(int newSelection)
	{
		local TIntJet kJet;
		local int iJet;

        super.RealizeSelected(newSelection);
		if(m_kInterceptMgr.m_iCurrentJet != GetSelectedShip())
		{
			//update ship list and m_iCurrentJet
			AS_DeactivateShipList();
			m_kInterceptMgr.UpdateView();
			m_kInterceptMgr.m_iCurrentJet = GetSelectedShip();
			UpdateData();
			return;
		}
		foreach m_kInterceptMgr.m_kSquadron.arrJets(kJet, iJet)
		{
			AS_FixHTMLTextForShip(kJet.iIndex);//force set html attribute of all textfields to TRUE
			if(!manager.IsMouseActive() && iJet == GetSelectedShip())
			{
				AS_SetToggleShipHelp(iJet, class'UI_FxsGamepadIcons'.const.ICON_Y_TRIANGLE);
			}
		}
		AS_SetStanceButtonLabel("def", class'UIUtilities'.static.GetHTMLColoredText(class'SU_Utils'.static.StanceToString(m_kInterceptMgr.m_akIntDistance[m_kInterceptMgr.m_iCurrentJet].kInterceptor), eUIState_Warning, 16));
		AS_SetStanceButtonLabel("bal", class'UIUtilities'.static.GetHTMLColoredText(GetCurrentWeaponStateString(m_kInterceptMgr.m_akIntDistance[m_kInterceptMgr.m_iCurrentJet].kInterceptor), eUIState_Warning, 16));
		AS_SetStanceButtonLabel("agg", class'UIUtilities'.static.GetHTMLColoredText(GetStartingDistanceLabel(m_kInterceptMgr.m_akIntDistance[m_kInterceptMgr.m_iCurrentJet].kInterceptor), eUIState_Warning, 16));
	}
	simulated function OnAccept()
	{
		local int iIndex;
		local array<TIntJet> aShipCards;
		local array<TIntDistance> aShipsOnContinent;
		
		//& 255 extracts left 8 bits from m_iSelectedShip and that is index of ship-card or launch button
		iIndex = GetSelectedShip();
		aShipCards = m_kInterceptMgr.m_kSquadron.arrJets;
		aShipsOnContinent = m_kInterceptMgr.m_akIntDistance;
		//if the jet-card is disabled (iState==1)
		if(aShipCards.Length == 0 || aShipCards[iIndex].iState == 1)
		{
			m_kInterceptMgr.PlayBadSound();
			return;
		}
		//if the ship-card is not toggled-in (the ship cannot be found in the m_arrInterceptors)
		if(!m_kInterceptMgr.m_kInterception.HasInterceptor(aShipsOnContinent[iIndex].kInterceptor))
		{
			//toggle the jet in (toggling out is handled in OnMouseEvent without calling OnAccept)
			m_kInterceptMgr.m_kInterception.ToggleInterceptor(aShipsOnContinent[iIndex].kInterceptor);
		}
		//update the stance stored in bits 9-16, stance is 1, 2 or 3, hence "-1" to turn it into 0, 1, or 2.
		if(m_iSelectedShip >> 8 == 3)//left-most small button click
		{
			ToggleStance(aShipsOnContinent[iIndex].kInterceptor);
		}
		else if(m_iSelectedShip >> 8 == 1)//center small button click
		{
			ToggleWeaponState(aShipsOnContinent[iIndex].kInterceptor);
		}
		else if(m_iSelectedShip >> 8 == 2)//right-most small button click
		{
			//class'SU_Utils'.static.GetSquadronMod().UIAssignPilot(aShipsOnContinent[iIndex].kInterceptor);
			//return;
			ToggleStartingDistance(aShipsOnContinent[iIndex].kInterceptor);
		}
		UpdateStartingDistance(aShipsOnContinent[iIndex].kInterceptor);
		AS_DeactivateShipList();
		m_kInterceptMgr.UpdateView();
		UpdateData();
	}
	simulated function OnCancel()
	{
		super.OnCancel();      
	}
	function ToggleStance(XGShip_Interceptor kShip)
	{
		++m_kInterceptMgr.m_akIntDistance[GetSelectedShip()].kInterceptor.m_kTShip.iRange;
		if(m_kInterceptMgr.m_akIntDistance[GetSelectedShip()].kInterceptor.m_kTShip.iRange > 2)
		{
			m_kInterceptMgr.m_akIntDistance[GetSelectedShip()].kInterceptor.m_kTShip.iRange = 0;
		}
	}
	function ToggleWeaponState(XGShip_Interceptor kShip)
	{
		if(kShip.m_afWeaponCooldown[0] == 0.0 && kShip.m_afWeaponCooldown[1] == 0.0)
		{
			kShip.m_afWeaponCooldown[1] = 1000.0;
		}
		else if(kShip.m_afWeaponCooldown[1] == 1000.0)
		{
			kShip.m_afWeaponCooldown[1] = 0.0;
			kShip.m_afWeaponCooldown[0] = 1000.0;
		}
		else
		{
			kShip.m_afWeaponCooldown[0] = 0.0;
			kShip.m_afWeaponCooldown[1] = 0.0;
		}
		UpdateShipAmmoDisplay(m_kInterceptMgr.m_akIntDistance.Find('kInterceptor', kShip));
	}
	function string GetCurrentWeaponStateString(XGShip_Interceptor kShip)
	{
		local string sRetVal;

		if(kShip.m_afWeaponCooldown[0] == 0.0 && kShip.m_afWeaponCooldown[1] == 0.0)
		{
			sRetVal = class'SU_XGInterceptionUI'.default.m_strLabelWeaponBtnAll;
		}
		else if(kShip.m_afWeaponCooldown[1] == 1000.0)
		{
			sRetVal = class'SU_XGInterceptionUI'.default.m_strLabelWeaponBtnPrimary;
		}
		else
		{
			sRetVal = class'SU_XGInterceptionUI'.default.m_strLabelWeaponBtnSecondary;
		}
		return sRetVal;
	}
	function ToggleStartingDistance(XGShip_Interceptor kShip)
	{
		local SU_Pilot kPilot;

		kPilot = class'SU_Utils'.static.GetPilot(kShip);
		if(kPilot != none)
		{
			if(++kPilot.m_iForcedStartingDistance > 1)
			{
				kPilot.m_iForcedStartingDistance = -1;
			}
		}
	}
	function UpdateStartingDistance(XGShip_Interceptor kShip)
	{
		local bool bStartClose;
		local SU_Pilot kPilot;
		local int iStance, iLongDPS, iCloseDPS;

		kPilot = class'SU_Utils'.static.GetPilot(kShip);
		kPilot.m_bStartBattleClose = false;
		if(kPilot.m_iForcedStartingDistance < 0)
		{
			bStartClose = false;//forced back start
		}
		else if(kPilot.m_iForcedStartingDistance > 0)
		{
			bStartClose = true;//forced front start
		}
		else
		{
			iStance = class'SU_Utils'.static.GetStance(kShip);
			bStartClose = class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.m_arrTactics[iStance].bStartClose;//front start forced by tactic
			//FIXME: maybe calc auto-distance through total DPS over first 3/4/5 seconds??
			if(!bStartClose)
			{
				kPilot.m_iForcedStartingDistance = -1;//temporary override
				iLongDPS = class'SU_Utils'.static.CalculateShipDPS(kShip, m_kUFO);
				kPilot.m_iForcedStartingDistance = 1;//temporary override
				iCloseDPS = class'SU_Utils'.static.CalculateShipDPS(kShip, m_kUFO);
				kPilot.m_iForcedStartingDistance=0;//restoring 0
				`Log(kShip.GetCallsign() @ "iLongDPS="$iLongDPS @ "iCloseDPS="$iCloseDPS,,GetFuncName());
				if(iCloseDPS > iLongDPS)
				{
					bStartClose = true;
				}
			}
		}
		kPilot.m_bStartBattleClose = bStartClose;
	}
	function string GetStartingDistanceLabel(XGShip_Interceptor kShip)
	{
		local SU_Pilot kPilot;
		local string sRetVal;

		sRetVal = "AUTO";
		kPilot = class'SU_Utils'.static.GetPilot(kShip);
		if(kPilot != none)
		{
			if(kPilot.m_iForcedStartingDistance > 0)
			{
				sRetVal = class'SU_Utils'.static.GetDistanceToUFOstring(kShip.IsFirestorm(), true);
			}
			else if(kPilot.m_iForcedStartingDistance < 0)
			{
				sRetVal = class'SU_Utils'.static.GetDistanceToUFOstring(kShip.IsFirestorm(), false);
			}
		}
		return sRetVal;
	}
	function UpdateShipAmmoDisplay(int iShip)
	{
		local XGShip_Interceptor kInt;
		
		kInt = m_kInterceptMgr.m_akIntDistance[iShip].kInterceptor;
		SelfGfx().SetShipAmmo(iShip, 1, kInt.m_afWeaponCooldown[0] > 0.0 ? 0 : class'SU_Utils'.static.GetAmmoForWeaponType(kInt.m_kTShip.arrWeapons[0]));
		SelfGfx().SetShipAmmo(iShip, 2, kInt.m_afWeaponCooldown[1] > 0.0 ? 0 : class'SU_Utils'.static.GetAmmoForWeaponType(kInt.m_kTShip.arrWeapons[1]));
	}
	function UpdateSquadronBuffsInfo()
	{
		local string strBonuses;

		strBonuses = SquadronBuffsToString();
		AS_SetSquadronInfoText(strBonuses);
		AS_SetSquadronInfoTitle(strBonuses != "" ? m_strLabelLeaderBonus : "");
		SelfGfx().m_gfxLeaderInfoBox.SetVisible(strBonuses != "");
	}
	function string SquadronBuffsToString()
	{
		local SU_Pilot kLeader;
		local string sBuffs;
		local int iAimMod, iDefMod, iTimeMod;
		local XGParamTag kTag;

		kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
		kLeader = SU_XGInterception(m_kInterceptMgr.m_kInterception).m_kSquadronLeader;
		if(kLeader != none)
		{
			iAimMod = SU_XGInterception(m_kInterceptMgr.m_kInterception).m_iSquadronAimBonus;
			iDefMod = SU_XGInterception(m_kInterceptMgr.m_kInterception).m_iSquadronDefBonus;
			if(kLeader.IsTraitActive())
			{
				iTimeMod += kLeader.GetCareerTrait().iBonusTime;
			}
			if(kLeader.IsFirestormTraitActive())
			{
				iTimeMod += kLeader.GetFirestormTrait().iBonusTime;
			}
			if(iAimMod != 0)
			{
				sBuffs = class'SU_UIPilotRoster'.default.m_strAim @ (iAimMod > 0 ? "+" : "") @ iAimMod;
			}
			if(iDefMod != 0)
			{
				sBuffs @= class'SU_UIPilotRoster'.default.m_strDef @ (iDefMod > 0 ? "+" : "") @ iDefMod;
			}
			if(iTimeMod != 0)
			{
				kTag.StrValue0 = "+" @iTimeMod;
				sBuffs @= class'XComLocalizer'.static.ExpandString(class'SU_PilotRankMgr'.default.m_strTraitModTime);
			}
		}
		return sBuffs;
	}
	function UpdateOddsInfo()
	{
		local int iOdds;
		local string sInfo;
		
		iOdds = SU_XGInterceptionUI(m_kInterceptMgr).CalcOdds();//for numerous ufos
		sInfo = m_strLabelChanceToWin;
		if(m_kInterceptMgr.LABS().IsResearched(m_kUFO.GetType() + 57))
		{
			sInfo @= iOdds $ "%";
		}
		else
		{
			sInfo @= "???";
		}
		if(iOdds < 25)
		{
			sInfo = class'UIUtilities'.static.GetHTMLColoredText(sInfo, eUIState_Bad);
		}
		else if(iOdds < 50)
		{
			sInfo = class'UIUtilities'.static.GetHTMLColoredText(sInfo, eUIState_Warning);
		}
		else if(iOdds > 75)
		{
			sInfo = class'UIUtilities'.static.GetHTMLColoredText(sInfo, eUIState_Good);
		}
		AS_SetOddsInfo(sInfo);
	}
	function UpdateLeaderFlag(int iShip)
	{
		SelfGfx().SetLeaderFlag(iShip);
	}
	function UpdateDistanceIndicator(int iShip)
	{
		SelfGfx().SetStartingDistance(iShip, class'SU_Utils'.static.GetPilot(m_kInterceptMgr.m_akIntDistance[iShip].kInterceptor).m_bStartBattleClose, m_kInterceptMgr.m_akIntDistance[iShip].kInterceptor.IsFirestorm());
		if(!m_kInterceptMgr.m_kInterception.HasInterceptor(m_kInterceptMgr.m_akIntDistance[iShip].kInterceptor))
		{
			SelfGfx().HideDistanceIndicator(iShip);
		}
	}
	function AdjustLaunchButtonPosition()
	{
		local GfxObject gfxLaunchButton;
		local float x, y;

		gfxLaunchButton = class'SU_Utils'.static.AS_GetCenterContainerItem(0);
		if(gfxLaunchButton != none)
		{
			ClearTimer(GetFuncName());
			gfxLaunchButton.GetPosition(x, y);
			y -= 50.0;
			gfxLaunchButton.SetPosition(x, y);
		}
	}

	function AS_SetShipHighlight(int iShipIdx, bool bHighlighted, optional bool bDamaged)
	{
		local GfxObject gfxObj;

		gfxObj = screen.manager.GetVariableObject(GetMCPath() $ ".shipListMC.ship" $ iShipIdx);
		class'UIModUtils'.static.ObjectAddColor(gfxObj, 0,0,0);
		if(bHighlighted)
		{
			if(!bDamaged)
			{
				class'UIModUtils'.static.ObjectAddColor(gfxObj, 0, GetSelectedShip() == iShipIdx ? 64 : 128, 0);
			}
			else if(iShipIdx == GetSelectedShip())
			{
				class'UIModUtils'.static.ObjectAddColor(gfxObj, 96, 48, 0);
			}
			else
			{
				class'UIModUtils'.static.ObjectAddColor(gfxObj, 128, 64, 0);
			}
		}
	}
	function AS_SetStanceButtonLabel(string sButtonName, string sButtonLabel)
	{
		local array<ASValue> arrParams;

		arrParams.Length=1;
		arrParams[0].Type = AS_String;
		arrParams[0].s = sButtonLabel;
		manager.GetVariableObject(GetMCPath() $ "." $ sButtonName).SetFloat("textY", -0.20);
		manager.GetVariableObject(GetMCPath() $ "." $ sButtonName).Invoke("setHTMLText", arrParams);
	}

	function AS_SetOddsInfo(string strText)
	{
		SelfGfx().SetOddsInfoText(strText);
	}
	function AS_SetToggleShipHelp(int iShip, string strIcon)
	{
		SelfGfx().ShowToggleShipHelpIcon(iShip, strIcon);
	}
	function AS_SetSquadronInfoTitle(string strTitle)
	{
		SelfGfx().SetLeaderTitle(strTitle);
	}
	function AS_SetSquadronInfoText(string strInfo)
	{
		SelfGfx().SetTeamBuffsText(strInfo);
	}
}
function SUGfx_RadarContactAlert SelfGfx()
{
	return SUGfx_RadarContactAlert(manager.GetVariableObject(string(GetMCPath()), class'SUGfx_RadarContactAlert'));
}
DefaultProperties
{
	s_alertName="RadarContactAlert"
}