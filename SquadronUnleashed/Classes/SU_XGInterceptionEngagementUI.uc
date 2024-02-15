class SU_XGInterceptionEngagementUI extends XGInterceptionEngagementUI;

function PostInit(XGInterception kXGInterception)
{
    m_kInterceptionEngagement = Spawn(class'SU_XGInterceptionEngagement');
    m_kInterceptionEngagement.Init(kXGInterception);
    m_kInterceptionEngagement.m_kInterception.m_kUFOTarget.m_bWasEngaged = true;	
	SU_XGInterception(m_kInterceptionEngagement.m_kInterception).GetRandomPilot().Speak(ePVC_EnemySighted);
    GEOSCAPE().UpdateSound();
}
function OnEngagementOver()
{
	local XGShip_UFO kAlienShip;
	local int i;

	WorldInfo.Game.SetGameSpeed(1.0);
	DeterminePilotStatus();
	GoToView(1);
	kAlienShip = SU_UIInterceptionEngagement(m_kInterface).m_kUFOs.GetMotherShip();
	switch(m_kInterceptionEngagement.m_kInterception.m_eUFOResult)
	{
		case eUR_Escape:
			if(kAlienShip.GetType() < 5)
			{
				Sound().PlaySFX(SNDLIB().SFX_Int_SmallUFOEscape);                
			}
			else
			{
				Sound().PlaySFX(SNDLIB().SFX_Int_BigUFOEscape);
			}
			class'SU_Utils'.static.GetPilot(SU_XGInterception(m_kInterceptionEngagement.m_kInterception).GetRandomCapableShip()).Speak(ePVC_UFOEscaped);
			//no break, let fall through
		case eUR_Disengaged:
			SU_UIInterceptionEngagement(m_kInterface).SelfGfx().GetShip(kAlienShip).UFOMoveEvent(-1, true, 2.0);
	}
	for(i=0; i < SU_XGInterception(m_kInterceptionEngagement.m_kInterception).m_arrUFOs.Length; ++i)
	{
		kAlienShip = SU_XGInterception(m_kInterceptionEngagement.m_kInterception).m_arrUFOs[i];
		if(kAlienShip != none && kAlienShip != SU_UIInterceptionEngagement(m_kInterface).m_kUFOs.GetMotherShip())
		{
			SU_UIInterceptionEngagement(m_kInterface).m_kUFOs.m_arrEscort[kAlienShip.m_iCounter].iHP = kAlienShip.GetHP();
		}
	}
	Sound().PlayMusic(1);
}
function DeterminePilotStatus()
{
	local SU_Pilot kPilot;
	local XGShip_Interceptor kJet;

	foreach m_kInterceptionEngagement.m_kInterception.m_arrInterceptors(kJet)
	{
		kPilot = class'SU_Utils'.static.GetPilot(kJet);
		if(kJet.GetHP() <= 0)
		{
			if(kPilot.GetSurvivalChancePct() < FRand())
			{
				kPilot.m_iStatus = ePilotStatus_Dead;
			}
			else if(class'SquadronUnleashed'.default.PILOT_WOUND_CHANCE_ON_SHOTDOWN > Rand(100))
			{
				kPilot.m_iStatus = ePilotStatus_Wounded;
				kPilot.m_iHoursUnavailable = 24 * class'SquadronUnleashed'.default.PILOT_HEAL_DAYS + class'SquadronUnleashed'.default.PILOT_TRANSFER_HOURS;
			}
			else
			{
				kPilot.m_iStatus = ePilotStatus_InTransfer;
				kPilot.m_iHoursUnavailable = class'SquadronUnleashed'.default.PILOT_TRANSFER_HOURS;
			}
		}
		else
		{
			kPilot.m_iStatus = ePilotStatus_Recovering;
			kPilot.m_iHoursUnavailable = class'SquadronUnleashed'.default.PILOT_RECOVER_AFTER_COMBAT_HOURS;
			if(kPilot.m_iHoursUnavailable == 1 && GEOSCAPE().m_kDateTime.GetMinute() > 20)
			{
				++kPilot.m_iHoursUnavailable;
			}
		}
		if(kPilot.GetStatus() != ePilotStatus_Dead)
		{
			GrantXP(kPilot);
		}
		`Log(GetFuncName() @ kPilot.GetCallsign() @ "status after combat" @ kPilot.GetStatusString(), class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	}
}
function GrantXP(SU_Pilot kPilot)
{
    local SU_UIInterceptionEngagement kInterface;
	local int iNewXP;
	local XGShip_Interceptor kJet;

	kInterface = SU_UIInterceptionEngagement(m_kInterface);
	iNewXP += class'SU_PilotRankMgr'.default.XP_PER_ENGAGMEMENT_SECOND * kInterface.m_fPlaybackTimeElapsed;
	if(m_kInterceptionEngagement.m_kInterception.m_eUFOResult == eUR_Crash || m_kInterceptionEngagement.m_kInterception.m_eUFOResult == eUR_Destroyed)
	{
		iNewXP += class'SU_PilotRankMgr'.default.XP_FOR_WIN;
	}
	kPilot.m_iKills += kPilot.m_iLastBattleKills;
	foreach m_kInterceptionEngagement.m_kInterception.m_arrInterceptors(kJet)
	{
		class'SU_Utils'.static.GetPilot(kJet).m_fTeamKills += float(kPilot.m_iLastBattleKills) / float(m_kInterceptionEngagement.m_kInterception.m_arrInterceptors.Length);		
	}
	kPilot.UpdateShipConfirmedKills();
	kPilot.m_fTotalDogfightTime += kInterface.m_fPlaybackTimeElapsed;
	kPilot.m_iNumDogfights++;
	kPilot.m_iLastBattleXP += iNewXP;
	kPilot.m_iXP += kPilot.m_iLastBattleXP;
}
function OnResultLeave()
{
    local SU_UIInterceptionEngagement kInterface;
	local XGInterception kInterception; 
	local array<XGShip_Interceptor> arrJets;

	WorldInfo.Game.SetGameSpeed(1.0);
	kInterception = m_kInterceptionEngagement.m_kInterception;
	arrJets = kInterception.m_arrInterceptors;
	kInterface = SU_UIInterceptionEngagement(m_kInterface);
	//increase the index of result screen shown
	++ kInterface.m_iResultScreenIterator;

    //check if there are more ships to show result screen for
	if(kInterface.m_iResultScreenIterator < arrJets.Length)
    {
        kInterface.ShowResultScreen();
        return;
    }
    //move the ship that delivered killing blow to position 0 in m_arrInterceptors
	//as it will be grabbed from there in CompleteEngagement() to determine loot based on its weapon
	if(kInterface.m_iKillerShipIndex > 0)
	{
	    arrJets.InsertItem(0, arrJets[kInterface.m_iKillerShipIndex - 1]);
		arrJets.Remove(kInterface.m_iKillerShipIndex, 1);
	}
	m_kInterceptionEngagement.m_kInterception.m_arrInterceptors = arrJets;
    
    //tell presentation layer to leave state 'InterceptionEngagement'
    PRES().PopState();

	//if not UFOCrashed...
    if(kInterception.m_eUFOResult != eUR_Crash)
    {        
    	//if any jet is returning home...
    	if(arrJets.Length > 0)
    	{
			//focus on the jets' base
    		PRES().CAMLookAtEarth(arrJets[0].GetHomeCoords());
    	}
		else
		{
    		//else focus geoscape on HQ
    		PRES().CAMLookAtEarth(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().GetCoords());
		}
    }
	//determine loot, update pilot ranks and send jets home - namely complete engagement
    kInterception.CompleteEngagement();
    Sound().PlayMusic(1);
    m_kInterceptionEngagement.Destroy();
    PRES().GetCamera().ForceEarthViewImmediately();
    PRES().m_kUIMissionControl.UpdateButtonHelp(); 
}
function SFXShipHit(XGShip kShip, int iDamage)
{
	local SoundCue kCustomCue;
	local SU_Pilot kPilot;

	if(!kShip.IsAlienShip())
	{
		kPilot = class'SU_Utils'.static.GetPilot(XGShip_Interceptor(kShip));
		kCustomCue = kPilot.m_tVoice.SFX_JetBelow50HP;
	}
	if(kCustomCue != none && kShip.m_iHP > 0 && (XGShip_Interceptor(kShip).GetHPPct() < 0.50 || kShip.m_iHP <= iDamage * 2 ))
	{
		if(!kPilot.m_bHPWarningPlayed)
		{
			kPilot.Speak(ePVC_JetBelow50HP);
			kPilot.m_bHPWarningPlayed=true;
		}
	}
	else
		super.SFXShipHit(kShip, iDamage);
}
function SFXShipDestroyed(XGShip kShip)
{
    if(kShip.IsAlienShip())
    {
		if(kShip.GetType() < 5)
		{
			Sound().PlaySFX(SNDLIB().SFX_Int_SmallUFOGoingDown);            
		}
		else
		{
			Sound().PlaySFX(SNDLIB().SFX_Int_BigUFOGoingDown);
		}        	
		class'SU_Utils'.static.GetPilot( XGShip_Interceptor(m_kInterceptionEngagement.GetShip(SU_UIInterceptionEngagement(PRES().m_kInterceptionEngagement).m_iKillerShipIndex)) ).Speak(ePVC_UFODown);
    }
    else
	{
		Sound().PlaySFX(SNDLIB().SFX_Int_JetExplode);
		class'SU_Utils'.static.GetPilot(XGShip_Interceptor(kShip)).Speak(ePVC_JetDown);
	}
}
//this is called for final Disengagement (no more jets fighting)
function Abort()
{
	class'SU_Utils'.static.GetPilot(SU_XGInterception(m_kInterceptionEngagement.m_kInterception).GetRandomCapableShip()).Speak(ePVC_UFOEscaped);
	STAT_AddStat(38, 1);
}