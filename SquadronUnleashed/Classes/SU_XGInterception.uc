class SU_XGInterception extends XGInterception
config(SquadronUnleashed);

var int m_iSquadronGeoSpeed;
var int m_iSquadronSize;
var int m_iSquadronAimBonus;
var int m_iSquadronDefBonus;
var SwfMovie m_kInterceptionMovie;
var SU_Pilot m_kSquadronLeader;
var SU_CombatSimulator m_kCombatSimulator;

/**Helper array to cache the whole UFO squadron.*/
var array<XGShip_UFO> m_arrUFOs;

/**Holds the initial total contact time.*/
var float m_fContactTime;

/**Index of jet in m_arrInterceptors which is the preferred target.*/
var int m_iPreferredUFOTarget;

function Init(XGShip_UFO kUFO)
{
	local SU_UFOSquadron kUFOS;
	local int iEscort;

    m_kUFOTarget = kUFO;
	m_arrUFOs.Length = 0;
	kUFOS = class'SU_Utils'.static.GetUFOSquadron(kUFO);
	if(kUFOS == none)
	{
		kUFOS = Spawn(class'SU_UFOSquadron', m_kUFOTarget);
		kUFOS.SetMotherShip(m_kUFOTarget, true);
		`log(self @ "spawned" @ kUFOS @ "|"@ "num escorts" @ kUFOS.GetNumEscorts(), class'SU_Utils'.static.GetSquadronMod().bVerboseLog,GetFuncName());
	}
	else
	{
		`log(self @ "found" @ kUFOS @ "|"@ "num escorts" @ kUFOS.GetNumEscorts(), class'SU_Utils'.static.GetSquadronMod().bVerboseLog, GetFuncName());
		kUFOS.SetMotherShip(m_kUFOTarget, false);
		`log(self @ "set mother ship to" @ kUFO @ "|"@ "num escorts" @ kUFOS.GetNumEscorts(), class'SU_Utils'.static.GetSquadronMod().bVerboseLog, GetFuncName());
	}
	kUFOS.Init(eEntityGraphic_UFO_Large);//this is not relevant for the mod actually
	kUFOS.CleanUpEscortList();
	if(kUFOS.GetNumEscorts() > 0)
	{
		for(iEscort=0; iEscort < kUFOS.GetNumEscorts(); ++iEscort)
		{
			kUFO = Spawn(class'XGShip_UFO', self);
			kUFO.Init(ITEMTREE().GetShip(EShipType(kUFOS.m_arrEscort[iEscort].iType)));
			kUFO.m_iHP = kUFOS.m_arrEscort[iEscort].iHP;
			kUFO.m_iCounter = iEscort;
			kUFO.m_kEntity.m_iData = kUFOS.m_iData;
			class'SU_Utils'.static.SetStance(kUFO, kUFOS.m_arrEscort[iEscort].iStance);
			m_arrUFOs.AddItem(kUFO);
		}
	}
	//mother ship always the last in line	
	m_arrUFOs.RemoveItem(m_kUFOTarget);
	m_arrUFOs.AddItem(m_kUFOTarget);
}

function string EscapeTimeToString(optional bool bUpdateTarget=true)
{
	if(bUpdateTarget)
	{
		UpdateContactTime();
	}
	return Left(string(m_fContactTime), 2 + InStr(string(m_fContactTime), "."));
}
function UpdateContactTime(optional int iBoostMultiplier, optional bool bLeaderBonus=true)
{
	local SU_UFOSquadron kUFOFleet;
	local int i;

	m_fContactTime = 0.0;
	kUFOFleet = class'SU_Utils'.static.GetUFOSquadron(m_kUFOTarget);
	if(kUFOFleet != none && kUFOFleet.GetNumEscorts() > 0)
	{
		m_fContactTime = UFOTypeToContactTime(kUFOFleet.GetMotherShip().GetType(), class'SU_Utils'.static.GetStance(kUFOFleet.GetMotherShip()), iBoostMultiplier, bLeaderBonus);
		for(i=0; i< kUFOFleet.GetNumEscorts(); ++i)
		{
			m_fContactTime += EscortTypeToContactTime(kUFOFleet.m_arrEscort[i].iType);
		}
	}
	else
	{
		m_fContactTime = UFOTypeToContactTime(m_kUFOTarget.GetType(), class'SU_Utils'.static.GetStance(m_kUFOTarget), iBoostMultiplier, bLeaderBonus);
	}
}
function float UFOTypeToContactTime(int iUFOType, int iUFOStance, optional int iBoostMultiplier, optional bool bLeaderBonus)
{
	local XGShip_Interceptor kInterceptor;
	local float fUFOSpeed, fTimeUntilOutrun;
	local int iSlowestInterceptorSpeed;
    
	iSlowestInterceptorSpeed = 9999.0;
	foreach m_arrInterceptors(kInterceptor)
    {
         iSlowestInterceptorSpeed = Min(iSlowestInterceptorSpeed, kInterceptor.m_kTShip.iEngagementSpeed);
    }
    iSlowestInterceptorSpeed += (iSlowestInterceptorSpeed / 2) * iBoostMultiplier;
    fUFOSpeed = float(ITEMTREE().GetShip(EShipType(iUFOType)).iEngagementSpeed);
    if(iUFOStance == 1)
    {
		fUFOSpeed *= class'SquadronUnleashed'.default.AGG_UFO_SPEED_DOWN;
    }
    if(iUFOStance == 2)
    {
         fUFOSpeed *= class'SquadronUnleashed'.default.DEF_UFO_SPEED_BOOST;
    }
    if(fUFOSpeed != 0.0)
    {
		fTimeUntilOutrun = 30.0 * (float(iSlowestInterceptorSpeed) / fUFOSpeed);
    }
    else
    {
		fTimeUntilOutrun = float(iSlowestInterceptorSpeed);
    }
	if(class'SquadronUnleashed'.default.GLOBAL_ENGAGEMENT_TIME_MULTIPLIER != 0.0)
	{
		fTimeUntilOutrun *= class'SquadronUnleashed'.default.GLOBAL_ENGAGEMENT_TIME_MULTIPLIER;
	}
	if(bLeaderBonus && m_kSquadronLeader != none)
	{
		kInterceptor = m_kSquadronLeader.GetShip();
		if(m_kSquadronLeader.IsTraitActive(false) )
			fTimeUntilOutrun += float(m_kSquadronLeader.GetCareerTrait().iBonusTime);
		if(m_kSquadronLeader.IsFirestormTraitActive(false) )
			fTimeUntilOutrun += float(m_kSquadronLeader.GetFirestormTrait().iBonusTime);
	}
	fTimeUntilOutrun = FMin(fTimeUntilOutrun, 60.0);
	return fTimeUntilOutrun;
}
function float EscortTypeToContactTime(int iUFOType)
{
	switch(iUFOType)
	{
	case 10:
	case 11:
	case 12:
	case 13:
	case 14:
		return (iUFOType - 9) * 2.0;
	case 9:
		return 4.0;
	default:
		return FMax(0.0, (iUFOType - 3) * 2.0);
	}
}
function UpdateSquadronSize()
{
	local XGShip_Interceptor kJet;
	local int iRank;

	m_iSquadronSize = 1;
    foreach m_arrInterceptors(kJet)
    {
        iRank = class'SU_Utils'.static.GetPilotRank(kJet);
    	m_iSquadronSize = Max(m_iSquadronsize, class'SU_Utils'.static.GetSquadronSizeAtRank(iRank, class'SU_Utils'.static.GetPilot(kJet).GetCareerType()));
    }    
    m_iSquadronSize = Clamp(m_iSquadronSize, class'SquadronUnleashed'.default.MIN_SQUADRON_SIZE, class'SquadronUnleashed'.default.MAX_SQUADRON_SIZE);
}
function UpdateSquadronGeoSpeed()
{
	local XGShip_Interceptor kJet;

	m_iSquadronGeoSpeed = 9999;
    foreach m_arrInterceptors(kJet)
    {
        m_iSquadronGeoSpeed = Min(m_iSquadronGeoSpeed, kJet.GetSpeed());
    }
}
function UpdateSquadronTeamBonuses(optional bool bDuringCombat)
{
	m_iSquadronAimBonus = 0;
	m_iSquadronDefBonus = 0;
	if(bDuringCombat && m_kSquadronLeader != none && class'SU_Utils'.static.GetStance(m_kSquadronLeader.GetShip()) == 3)
	{
		return;
	}
	else if(!bDuringCombat)
	{
		UpdateSquadronLeader();
	}
	if(m_kSquadronLeader != none )
	{
		m_iSquadronAimBonus = class'SU_Utils'.static.GetRankTeamAimBonus( m_kSquadronLeader.GetRank(), m_kSquadronLeader.GetCareerType() );
		m_iSquadronDefBonus = class'SU_Utils'.static.GetRankTeamDefBonus( m_kSquadronLeader.GetRank(), m_kSquadronLeader.GetCareerType() );
		if(m_kSquadronLeader.IsTraitActive())
		{
			m_iSquadronAimBonus += m_kSquadronLeader.GetCareerTrait().iBonusTeamAim;
			m_iSquadronDefBonus += m_kSquadronLeader.GetCareerTrait().iBonusTeamDef;
		}
		if(m_kSquadronLeader.IsFirestormTraitActive())
		{
			m_iSquadronAimBonus += m_kSquadronLeader.GetFirestormTrait().iBonusTeamAim;
			m_iSquadronDefBonus += m_kSquadronLeader.GetFirestormTrait().iBonusTeamDef;
		}
	}
}
function UpdateSquadronLeader()
{
	local XGShip_Interceptor kJet;
	local SU_Pilot kPilot;

	m_kSquadronLeader = none;
	foreach m_arrInterceptors(kJet)
	{
		kPilot = class'SU_Utils'.static.GetPilot(kJet);
		if(kPilot.GivesTeamBuffs())
		{
			if(m_kSquadronLeader == none || kPilot.GivesBetterTeamBuffThan(m_kSquadronLeader))
			{
				m_kSquadronLeader = kPilot;
			}
		}
	}
}
function ToggleInterceptor(XGShip_Interceptor kInterceptor)
{
    local int iLastSquadronSize;
	
	//record current number of jets in squadron
	iLastSquadronSize = m_arrInterceptors.Length;

	//check if selected ship is refuelled and not in transfer
    if(kInterceptor.m_iStatus != 0 && kInterceptor.m_iStatus != 4)
    {
        Sound().PlaySFX(SNDLIB().SFX_UI_No);
        return;
    }
	else
	{
		Sound().PlaySFX(SNDLIB().SFX_UI_ToggleSelectContinent);
	}
    if(HasInterceptor(kInterceptor))
    {
        m_arrInterceptors.RemoveItem(kInterceptor);
		kInterceptor.m_kEngagement = none;
    }
    else
    {
        m_arrInterceptors.AddItem(kInterceptor);
		kInterceptor.m_kEngagement = self;
    }
	//recalculate max squadron size after toggling the jet in/out
    UpdateSquadronSize();
	//if new max squadron size is below current squadron size (including selected jet)
    if(m_arrInterceptors.Length > m_iSquadronSize)
    {
        //... if there is still only 1 ship allowed
    	if(iLastSquadronSize == 1)
        {
			//remove previously selected ship and replace it with the new one
        	m_arrInterceptors.Remove(0, 1);
        }
		else
		{
    		//otherwise adjust squadron size by cutting off ships from the end of list
			m_arrInterceptors.Length = m_iSquadronSize;
			PlaySound(Sound().SNDLIB().SFX_UI_No);
			class'SU_Utils'.static.GetHelpMgr().ShowErrorMsg(eSUError_PilotRankTooLow, 0.72);
		}
    }
	UpdateSquadronGeoSpeed();
	UpdateSquadronTeamBonuses();
}
function OnArrival()
{
	local XGShip_Interceptor kInterceptor;

	if(!CheckForGood())
	{
		foreach m_arrInterceptors(kInterceptor)
		{
			kInterceptor.ReturnToBase();
		}        
		GEOSCAPE().RemoveInterception(self);
		return;
	}
	//PRES().StartInterceptionEngagement(self);
	StartInterceptionEngagement();
}
function StartInterceptionEngagement()
{
	LogInternal(GetFuncName()@ "PRES().m_bHasRequestedInterceptionLoad=" $ PRES().m_bHasRequestedInterceptionLoad,'SquadronUnleashed');
	if(!PRES().m_bHasRequestedInterceptionLoad)
	{
		PRES().m_kXGInterception = self;
		m_kInterceptionMovie = PRES().m_kInterceptionMovie;//to keep it in memory
		PRES().m_kInterceptionMovie = none;//to cheat PRES (step 1)
		PRES().m_bHasRequestedInterceptionLoad = true;//to cheat PRES (step 2) - now it will loop infinitely in State_InterceptionEngagement, waiting for the movie
		InitEngagementUI();//this will run all the PRES stuff manually...
		PRES().PushState('State_InterceptionEngagement');//yes - we do push the state to keep the PRES states' stack in order
	}
}
function InitEngagementUI()
{
	`Log(GetFuncName(),class'SquadronUnleashed'.default.bVerboseLog,'SquadronUnleashed');
	PRES().m_kInterceptionEngagement = PRES().Spawn(class'SU_UIInterceptionEngagement', PRES());
	PRES().Get3DMovie().LoadScreen(PRES().m_kInterceptionEngagement);
	PRES().Get3DMovie().ShowDisplay(class'UIInterceptionEngagement'.default.DisplayTag);
	PRES().CAMLookAtNamedLocation(class'UIInterceptionEngagement'.default.m_strCameraTag, 1.0);
	PRES().m_kInterceptionEngagement.Init(XComPlayerController(PRES().Owner), PRES().Get3DMovie(), self);
	GEOSCAPE().m_bGlobeHidden = true;
}

function CompleteEngagement()
{
    local int I;
	local XGShip_Interceptor kJet;
	local SU_Pilot kPilot;
	local string strDebug;

    if(m_eUFOResult == eUR_Crash)
    {
		strDebug $= ("\n"$Chr(9)$GetFuncName() @ "kufo=" @ m_kUFOTarget);
        ClearOtherEngagements(m_kUFOTarget);
		strDebug $= ("\n"$Chr(9)$"After ClearOtherEngagements kufo=" @ m_kUFOTarget);
		//determine loot based on killer's weapon; killer has already been moved to position 0 of the array for that purpose
        AI().OnUFOShotDown(m_arrInterceptors[0], m_kUFOTarget);
    }
    else if(m_eUFOResult == eUR_Destroyed)
	{
		AI().OnUFODestroyed(m_kUFOTarget);
		//this line is copied from Campaign Summary by 'tracktwo'; records killer ship
        GetRecapSaveData().RecordEvent(((((((GEOSCAPE().m_kDateTime.GetDateString() @ GEOSCAPE().m_kDateTime.GetTimeString()) @ ":") @ m_arrInterceptors[0].GetCallsign()) @ "destroyed a") @ string(m_kUFOTarget.GetType())) @ "over") @ Country(m_kUFOTarget.GetCountry()).GetName());
	}
    else
    {
		AI().OnUFOAttacked(m_kUFOTarget);
	}
	for(I = 0; I < m_arrInterceptors.Length; ++ I)
    {
		kJet = m_arrInterceptors[I];
		kPilot = class'SU_Utils'.static.GetPilot(kJet);

		strDebug $= ("\n"$Chr(9)$"Updating " @ kJet.m_strCallsign $ "'s rank.");
		kJet.m_strCallsign = class'SU_Utils'.static.GetPilot(kJet).GetCallsignWithRank(true);//'true' updates the rank
		strDebug $= ("\n"$Chr(9)$"Current rank: " @ kJet.m_strCallsign);

        if(kJet.GetHP() <= 0)
        {
            HANGAR().OnInterceptorDestroyed(kJet);
			if(kPilot.GetStatus() == ePilotStatus_Dead)
			{
				class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.RemovePilot(class'SU_Utils'.static.GetPilot(kJet));
			}
        }
        else
        {
            //reset default stance to BAL
            kJet.m_kTShip.iRange = 0;
			kJet.m_kTShip.iSpeed = ITEMTREE().m_arrShips[kJet.m_kTShip.eType].iSpeed * (kJet.IsDamaged() ? class'SquadronUnleashed'.default.DAMAGED_SPEED_PENALTY : 1.0);
            //send jet home
            kJet.ReturnToBase();
			//reset m_iLastBattleXP
			kPilot.m_iLastBattleXP = 0;
			//reset m_iLastBatttleKills
			kPilot.m_iLastBattleKills = 0;
        }
    }
	`Log(strDebug, class'SquadronUnleashed'.default.bVerboseLog, GetFuncName());
    GEOSCAPE().RemoveInterception(self);
}
event Destroyed()
{
	local XGShip_Interceptor kShip;

	`Log(GetFuncName() @ self, class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	foreach m_arrInterceptors(kShip)
	{
		`Log(kShip @ "m_kEngagement set to None.", class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
		kShip.m_kEngagement = none;
	}
	if(m_kCombatSimulator != none)
	{
		m_kCombatSimulator.Destroy();
	}
	DestroyEscortActors();
}
function SU_Pilot GetRandomPilot()
{
	return class'SU_Utils'.static.GetPilot(m_arrInterceptors[Rand(m_arrInterceptors.Length)]);
}
function SU_Pilot GetSquadronLeader(optional bool bTrueLeader=true)
{
	local SU_Pilot kLead;

	kLead = m_kSquadronLeader;
	if(kLead == none && !bTrueLeader)
	{
		kLead = GetRandomPilot();
	}
	return kLead;
}
function XGShip_Interceptor GetRandomCapableShip()
{
	local int iJet;
	local array<XGShip_Interceptor> arrCapableJets;
	local XGShip_Interceptor kShip;

	arrCapableJets = m_arrInterceptors;
	for(iJet=0; iJet < arrCapableJets.Length; ++iJet)
	{
		if(arrCapableJets[iJet].m_iHP <= 0)
		{
			arrCapableJets.Remove(iJet, 1);
			iJet--;
		}
	}
	kShip = arrCapableJets[Rand(arrCapableJets.Length)];
	return kShip;
}
function UpdatePreferredUFOTarget(optional out array<int> arrScores, optional XGShip_UFO kForThisUFO)
{
	local int iShipID, iScore, iHighestScore;
	local XGShip_Interceptor kShip;

	//bits 1-6 (lowest priority)- hold Rand(63) factor
	//bit  7                    - holds IsCurrentTarget flag (0/1)
	//bits 8-21                 - hold current dmg (0-16383)
	//bits 22-28                - hold Aggro stat (0-127)
	//bit  29 (highest priority)- holds m_bClosedIn (short distance) flag (0/1)
	arrScores.Length = 0;
	arrScores.Add(m_arrInterceptors.Length);
	for(iShipID=0; iShipID < m_arrInterceptors.Length; ++iShipID)
	{
		kShip = m_arrInterceptors[iShipID];
		iScore = 0;
		if(kShip.m_kTShip.iRange == 3)
		{
			iScore = -1;
		}
		else
		{
			if(class'SU_Utils'.static.ShipCloseOn(kShip, SU_UIInterceptionEngagement(PRES().m_kInterceptionEngagement) != none))
			{
				iScore += 1 << 28;
			}
			iScore += Min(127, class'SU_Utils'.static.GetAggroForShip(kShip, kForThisUFO != none? kForThisUFO : m_kUFOTarget)) << 21;
			iScore += Min(16383, (kShip.GetHullStrength() - kShip.m_iHP)) << 7;
			if( iShipID == m_iPreferredUFOTarget)
			{
				iScore += 1 << 6;
			}
			else
			{
				iScore += Rand(64);
			}
		}
		arrScores[iShipID] = iScore;
	}
	iHighestScore = -1;
	foreach arrScores(iScore)
	{
		iHighestScore = Max(iScore, iHighestScore);
	}
	iShipID = arrScores.Find(iHighestScore);
	if(iHighestScore != -1 && m_iPreferredUFOTarget != iShipID)
	{
		m_iPreferredUFOTarget = iShipID;
	}
}
function SU_CombatSimulator CombatSimulator()
{
	if(m_kCombatSimulator == none)
	{
		m_kCombatSimulator = Spawn(class'SU_CombatSimulator', self);
		m_kCombatSimulator.Init(self);
	}
	return m_kCombatSimulator;
}
function DestroyEscortActors()
{
	local XGShip_UFO kUFO;

	foreach m_arrUFOs(kUFO)
	{
		if(kUFO.Owner == self)
		{
			kUFO.Destroy();
		}
	}
	m_arrUFOs.Length = 0;
}