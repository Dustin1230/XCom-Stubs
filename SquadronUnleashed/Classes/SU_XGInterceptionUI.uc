class SU_XGInterceptionUI extends XGInterceptionUI
  config(SquadronUnleashed);

var bool bSortShipList;
var localized string m_strLabelFighterToLaunch;
var localized string m_strLabelPilotBtn;
var localized string m_strLabelWeaponBtnPrimary;
var localized string m_strLabelWeaponBtnSecondary;
var localized string m_strLabelWeaponBtnAll;
var config int DAMAGED_SELECTED_AGGRO_COLOR;
var config int GOOD_SELECTED_AGGRO_COLOR;
var config int DAMAGED_CAPABLE_COLOR;
var config int GENERAL_SELECTED_COLOR;
var int m_iTotalSquadronDPS;
var int m_iTotalSquadronDmgOutput;
var int m_iUFOStance;

function Init(int iView)
{
	m_imgBG.iImage = 216;
	m_iCurrentJet = 0;
	m_kInterception = Spawn(class'SU_XGInterception');
	m_kInterception.Init(m_kUFO);
	class'SU_Utils'.static.DetermineUFOStance(m_kUFO);
	m_iUFOStance = class'SU_Utils'.static.GetStance(m_kUFO);
	BuildInterceptorList();
	super(XGScreenMgr).Init(iView);
}
function BuildInterceptorList()
{
	local int i;
	local XGShip_Interceptor kShip;

	for(i=0; i<HANGAR().m_arrInts.Length; ++i)
	{
		kShip = HANGAR().m_arrInts[i];
		if(kShip.m_iHoursDown >= 0 && kShip.GetStatus() != eShipStatus_Rearming && kShip.GetStatus() != eShipStatus_Transfer)
		{
			//ensure update to prevent chain-launch abuse
			HANGAR().DetermineInterceptorStatus(kShip);
		}
		kShip.m_kTShip.iSpeed = ITEMTREE().m_arrShips[kShip.GetType()].iSpeed * (kShip.IsDamaged() ? class'SquadronUnleashed'.default.DAMAGED_SPEED_PENALTY : 1.0);
		kShip.m_kTShip.iEngagementSpeed= ITEMTREE().m_arrShips[kShip.GetType()].iEngagementSpeed * (kShip.IsDamaged() ? class'SquadronUnleashed'.default.DAMAGED_SPEED_PENALTY : 1.0);
		kShip.m_afWeaponCooldown.Length = 2;
		kShip.ResetWeapons();
	}
	super.BuildInterceptorList();
}
function int IntDistanceSort(TIntDistance A, TIntDistance B)
{
	//iMiles stores aggro of a ship
    if(m_kInterception.HasInterceptor(A.kInterceptor) == m_kInterception.HasInterceptor(B.kInterceptor))
    {
        return ((A.iMiles < B.iMiles) ? -1 : 0);
    }
    return ((m_kInterception.HasInterceptor(A.kInterceptor)) ? 0 : -1);
}

function OnLaunch()
{
    local XGShip_Interceptor kInterceptor;

    foreach m_kInterception.m_arrInterceptors(kInterceptor)
    {
        kInterceptor.m_kTShip.iSpeed = SU_XGInterception(m_kInterception).m_iSquadronGeoSpeed;
		kInterceptor.m_iStatus = eShipStatus_OnMission;
		ConsoleCommand("set XGInterception m_iSquadronSpeed" @ SU_XGInterception(m_kInterception).m_iSquadronGeoSpeed, false);
    }
	PRES().m_bHasRequestedInterceptionLoad=false;
	super.OnLaunch();
}

function OnLeaveJetSelection()
{
	//FIXME: destroy dummy ufos and clean up m_arrUFOS?
	class'SU_Utils'.static.SetStance(m_kUFO, m_iUFOStance);
	super.OnLeaveJetSelection();
}

function UpdateCurrentTarget()
{
   local XGParamTag kTag;

   m_kTarget.imgTarget.iImage = 178;
   m_kTarget.txtSize.strLabel = m_strLabelSize;
   m_kTarget.txtSize.StrValue = m_kInterception.m_kUFOTarget.GetSizeString();
   m_kTarget.txtSpeed.bNumber = true;
   m_kTarget.txtSpeed.strLabel = m_strLabelSpeed;
   m_kTarget.txtSpeed.StrValue = string(m_kInterception.m_kUFOTarget.GetSpeed());
   kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
   kTag.StrValue0 = m_kInterception.m_kUFOTarget.m_kTShip.strName;
   kTag.StrValue1 = Continent(m_kInterception.m_kUFOTarget.GetContinent()).GetName();
   m_kTarget.txtTitle.StrValue = class'XComLocalizer'.static.ExpandString(m_strLabelShipOverRegion);
}

function UpdateLaunchButton()
{
	local GFxObject gfxButton;
	local string strDisplayText;
	local bool bEnabled;
	local ASValue myParam;
	local array<ASValue> arrParams;

	//call original code
	super.UpdateLaunchButton();

	//add custom code
	gfxButton = class'SU_Utils'.static.AS_GetCenterContainerItem(0);
	if(gfxButton != none)
	{
		bEnabled=m_kInterception.m_arrInterceptors.Length > 0;
		strDisplayText = GetLaunchButtonLabel();
		myParam.s=CAPS(strDisplayText);
		myParam.Type=AS_String;
		arrParams.AddItem(myParam);
		gfxButton.Invoke("setHTMLText", arrParams);

		arrParams.Length=0;
		if(bEnabled)
		{
			gfxButton.Invoke("enable", arrParams);
		}
		else
		{
			gfxButton.Invoke("disable", arrParams);
		}
	}
}
function string GetLaunchButtonLabel()
{
	local string sLabel;

	switch(m_kInterception.m_arrInterceptors.Length)
	{
	case 0:
		sLabel = m_strLabelChooseInterceptors;
		break;
	case 1:
		sLabel = class'SquadronUnleashed'.default.m_strLabelLaunchFighter;
		break;
	default:
		sLabel = class'SquadronUnleashed'.default.m_strLabelLaunchFighters;
	}
	sLabel @="(" $ m_kInterception.m_arrInterceptors.Length $"/"$ SU_XGInterception(m_kInterception).m_iSquadronSize $")";
	return sLabel;
}
function UpdateSquadron()
{
    local XGShip_Interceptor kInterceptor;
    local int iIndex, iJet;
    local XGParamTag kTag;
	local SU_Pilot kPilot;

    //clear arrJets (array of ship-cards)
    m_kSquadron.arrJets.Remove(0, m_kSquadron.arrJets.Length);
	m_iTotalSquadronDPS = 0;
    //for every ship on continent
    for(iJet=0; iJet < m_akIntDistance.Length; ++ iJet)
    {
    	//get a ship
    	kInterceptor = m_akIntDistance[iJet].kInterceptor;
        //calculate its aggro and store it as iMiles of ship-card
    	m_akIntDistance[iJet].iMiles = class'SU_Utils'.static.GetAggroForShip(kInterceptor, m_kUFO);
    }
	//sort the list if AutoSort not disabled
    if((SU_UFORadarContactAlert(Owner).m_iSelectedShip & 255) != m_iCurrentJet && bSortShipList)
    {
        m_akIntDistance.Sort(IntDistanceSort);
    } 
    iJet = 0;
    //for every jet on continent
    for(iIndex=0; iIndex < m_akIntDistance.Length; ++iIndex)
    {
        kInterceptor = m_akIntDistance[iIndex].kInterceptor;
        if(kInterceptor != none)
        {
			kPilot = class'SU_Utils'.static.GetPilot(kInterceptor);
            //create basic data for the ship-card
        	m_kSquadron.arrJets.Add(1);
            m_kSquadron.arrJets[iJet].EShipType = kInterceptor.GetType();
            m_kSquadron.arrJets[iJet].iIndex = iIndex;
			if(kPilot != none)
			{
	            m_kSquadron.arrJets[iJet].txtJetName.StrValue = kPilot.GetCallsignWithRank(false, true);
				m_kSquadron.arrJets[iJet].txtJetName.StrValue $= "\n"$class'UIUtilities'.static.GetHTMLColoredText(CAPS(class'SU_Utils'.static.GetRankMgr().GetCareerPathName(kPilot.GetCareerType())) $"  "$ kPilot.CareerProgressToString(true, true), eUIState_Normal, 14);
			}
			else
			{
	            m_kSquadron.arrJets[iJet].txtJetName.StrValue = class'SquadronUnleashed'.default.m_strNoPilotAssigned;
				if(m_kInterception.HasInterceptor(kInterceptor))
				{
					m_kInterception.m_arrInterceptors.RemoveItem(kInterceptor);
				}
			}
            //if ship is damaged but capable of fighting
            if(kInterceptor.IsDamaged() && CanBeLaunched(kInterceptor))
            {
                //change the color of its launch label
            	m_kSquadron.arrJets[iJet].txtStatus.iState = DAMAGED_CAPABLE_COLOR;
            }
			else if(kPilot == none && CanBeLaunched(kInterceptor, true))
			{
				m_kSquadron.arrJets[iJet].txtStatus.iState = eUIState_Cash;
			}
            else
            {
                //set color base on ship's state (green for good, red for disabled)
            	m_kSquadron.arrJets[iJet].txtStatus.iState = kInterceptor.GetStatusUIState();
            }
            if(iJet == m_iCurrentJet)
            {
                m_kSquadron.arrJets[iJet].bHighlighted = true;
            }
			//m_afWeaponCooldown[0] and [1] hold current state of weapon's toggle
			if(kInterceptor.m_afWeaponCooldown[0] == 0.0)//if primary toggled in
			{
	            m_kSquadron.arrJets[iJet].txtOffense.StrValue = SHIPWEAPON(kInterceptor.m_kTShip.arrWeapons[0]).strName;
			}
			if(kInterceptor.m_afWeaponCooldown[1] == 0.0)//if secondary toggled in
			{
				if(m_kSquadron.arrJets[iJet].txtOffense.StrValue != "")
				{
					m_kSquadron.arrJets[iJet].txtOffense.StrValue $= " | ";
				}
	            m_kSquadron.arrJets[iJet].txtOffense.StrValue $= SHIPWEAPON(kInterceptor.m_kTShip.arrWeapons[1]).strName;
			}
            m_kSquadron.arrJets[iJet].txtOffense.StrValue = class'UIUtilities'.static.GetHTMLColoredText(m_kSquadron.arrJets[iJet].txtOffense.StrValue, CanBeLaunched(kInterceptor, true) ? eUIState_Normal : eUIState_Disabled, 17);
            //HANDLING "SELECTED SHIPS", DISPLAY COLORED AGGRO LABELS ETC.
            if(m_kInterception.HasInterceptor(kInterceptor))
            {
            	m_kSquadron.arrJets[iJet].iState = 5;//highlighted
                
            	//the two lines below handle the sorting of selected-ships in the order they appear on the ship-card list
	           	m_kInterception.m_arrInterceptors.RemoveItem(kInterceptor);
				m_kInterception.m_arrInterceptors.AddItem(kInterceptor);

				if(kInterceptor.IsDamaged())
                {
                    //setting color of launch label for selected damaged jet
                	m_kSquadron.arrJets[iJet].txtStatus.iState = DAMAGED_SELECTED_AGGRO_COLOR;
                }
                else
                {
                    m_kSquadron.arrJets[iJet].txtStatus.iState = GOOD_SELECTED_AGGRO_COLOR;
                }
                //preparing data for localization string...
                kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
				kTag.StrValue0 = string(m_akIntDistance[iJet].iMiles);//aggro
				kTag.IntValue0 = class'SU_Utils'.static.CalculateShipDPS(kInterceptor, m_kUFO, false, kPilot.m_bStartBattleClose);
				m_iTotalSquadronDPS += kTag.IntValue0;
				kTag.IntValue1 = class'SU_Utils'.static.GetHitChance(kInterceptor, m_kUFO, 0, kPilot.m_bStartBattleClose);
				kTag.IntValue2 = class'SU_Utils'.static.GetRankDefBonus(kPilot.GetRank(), kPilot.GetCareerType()) + SU_XGInterception(m_kInterception).m_iSquadronDefBonus;
				//and injecting the data into localization strings...
                m_kSquadron.arrJets[iJet].txtStatus.StrValue = class'XComLocalizer'.static.ExpandString(m_strLabelFighterToLaunch);
                //coloring the labales
	            m_kSquadron.arrJets[iJet].txtOffense.StrValue = class'UIUtilities'.static.GetHTMLColoredText(m_kSquadron.arrJets[iJet].txtOffense.StrValue, GENERAL_SELECTED_COLOR, 17);
                m_kSquadron.arrJets[iJet].txtJetName.StrValue = class'UIUtilities'.static.GetHTMLColoredText(m_kSquadron.arrJets[iJet].txtJetName.StrValue, GENERAL_SELECTED_COLOR);
            }
            //for not-selected ships...
            else
            {
	            //m_kSquadron.arrJets[iJet].txtOffense.StrValue = class'UIUtilities'.static.GetHTMLColoredText(m_kSquadron.arrJets[iJet].txtOffense.StrValue, CanBeLaunched(kInterceptor) ? eUIState_Normal : eUIState_Disabled, 17);
                if(kPilot != none && kPilot.GetStatus() != ePilotStatus_Ready)
                {
					m_kSquadron.arrJets[iJet].txtStatus.StrValue = kPilot.GetStatusString();
					m_kSquadron.arrJets[iJet].txtStatus.iState = eUIState_Bad;
                }
				else
				{
	            	m_kSquadron.arrJets[iJet].txtStatus.StrValue = kInterceptor.GetStatusString();
				}
                if(!CanBeLaunched(kInterceptor) || m_akIntDistance[iIndex].bOutOfRange)
                {
                    //this marks a ship-card as 'disabled'; the iState==1 is checked in UFORadarConactAlert.ShipSelection.UpdateData
                	m_kSquadron.arrJets[iJet].iState = 1;
                }
                else
                {
                    //and this one marks 'ready for launch'
                	m_kSquadron.arrJets[iJet].iState = 0;
                }
            }
            iJet++;
        }
    }
}
static function bool CanBeLaunched(XGShip_Interceptor kShip, optional bool bIgnorePilot, optional out int iErrorCode)
{
	local bool bCanFight;

	bCanFight = true;
	if(kShip.GetHPPct() < class'SquadronUnleashed'.default.DAMAGED_JET_HP_PCT_CAN_FIGHT)
	{
		bCanFight = false;
		iErrorCode = eSUError_JetRepairing;
	}
	else if(kShip.GetFuelPct() < 1.0)
	{
		bCanFight = false;
		iErrorCode = eSUError_JetRefuelling;
	}
	else if(!bIgnorePilot && (class'SU_Utils'.static.GetPilot(kShip) == none || class'SU_Utils'.static.GetPilot(kShip).GetStatus() != ePilotStatus_Ready))
	{
		bCanFight = false;
		iErrorCode = eSUError_PilotStatusNotValid;
	}
	else if(kShip.GetStatus() == eShipStatus_Transfer || kShip.GetStatus() == eShipStatus_Rearming)
	{
		bCanFight = false;
		iErrorCode = (kShip.GetStatus() == eShipStatus_Transfer ? eSUError_JetInTransfer : eSUError_JetAlreadyRearming);
	}
	return bCanFight;
}
function int GetWinChance()
{
	local float fEscapeTime, fJetMaxTankingTime, fExpectedContactTime, fChance, fRequiredSquadronDPS, fMinSquadronDPS, fMaxSquadronDPS;
	local XGShip_Interceptor kJet;
	local SU_UFOSquadron kUFOFleet;
	local int iEscort, iUFOHPPool;

	if(m_iTotalSquadronDPS <=0)
	{
		return 0;
	}
	m_kUFO.m_afWeaponCooldown.Length = 2;
	fEscapeTime = SU_XGInterception(m_kInterception).m_fContactTime;
	foreach m_kInterception.m_arrInterceptors(kJet)
	{
		fJetMaxTankingTime = kJet.m_iHP / class'SU_Utils'.static.CalculateShipDPS(m_kUFO, kJet);
		fExpectedContactTime += FMin(fEscapeTime, fJetMaxTankingTime);
	}
	fExpectedContactTime = FMin(fEscapeTime, fExpectedContactTime);
	iUFOHPPool = m_kUFO.m_iHP;
	kUFOFleet = class'SU_Utils'.static.GetUFOSquadron(m_kUFO);
	if(kUFOFleet != none && kUFOFleet.GetNumEscorts() > 0)
	{
		for(iEscort=0; iEscort < kUFOFleet.m_arrEscort.Length; ++iEscort)
			iUFOHPPool += kUFOFleet.m_arrEscort[iEscort].iHP;
	}
	fRequiredSquadronDPS = iUFOHPPool / (fExpectedContactTime - 1.0);//1.0s margin for StaggerWeapons
	fMinSquadronDPS = m_iTotalSquadronDPS * 0.80;
	fMaxSquadronDPS = m_iTotalSquadronDPS * 1.20;
	fChance = FClamp( FMin(fExpectedContactTime / 10, 1.0) - FPctByRange(fRequiredSquadronDPS, fMinSquadronDPS, fMaxSquadronDPS), 0.0f, 1.0f);
	return fChance * 100;
}
function int CalcOdds()
{
	local SU_CombatSimulator kSim;
	local float fEscapeTime, fChance, fLowTime, fHighTime, fShortBattleAdj;

	kSim = SU_XGInterception(m_kInterception).CombatSimulator();
	kSim.SimCombat();
	if(kSim.m_bXComWins)
	{
		fEscapeTime = SU_XGInterception(m_kInterception).m_fContactTime;
		fLowTime = kSim.m_iTotalBattleSeconds * 0.80;
		fHighTime = kSim.m_iTotalBattleSeconds * 1.20;
		fShortBattleAdj = 1.0 - FMin(fEscapeTime / 10, 1.0);
		fChance = FClamp( FPctByRange(fEscapeTime, fLowTime, fHighTime) - fShortBattleAdj, 0.0f, 1.0f);
	}
	else
	{
		fChance = 0.0;
	}
	return fChance * 100;
}
