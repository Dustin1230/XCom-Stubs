class SU_XGInterceptionEngagement extends XGInterceptionEngagement
	config(SquadronUnleashed);

var config int HP_BAR_LENGTH;
var config int HP_BAR_GOOD_COLOR_INDEX;
var config float UFO_DESTRUCTION_CHANCE_MODIFICATOR;
var config array<int> HP_OVERKILL_PER_ONE_PCT_DESTR_CHANCE;
var config array<int> HP_OVERKILL_THRESHOLD;
var float m_fTimeUntilOutrun;

function int ShipNameToShipID(string strShipGfxObjectName)
{
	local int i;
	local bool bFound;

	for(i=0; i < m_kInterception.m_arrInterceptors.Length; ++i)
	{
		if(string(m_kInterception.m_arrInterceptors[i]) == strShipGfxObjectName)
		{
			bFound = true;
			break;
		}
	}
	return (bFound ? i+1 : -1);
}
function Init(XGInterception kInterception)
{
    local int iOffset, I, iScore, iLowestScore, iHighestScore;

    local array<int> aiInterceptorScores;
    
	LogInternal(GetFuncName() @ kInterception);
    HANGAR().m_bNarrLostJet = false;
    m_kInterception = kInterception;
    m_fTimeElapsed = 0.0;
    m_iPlaybackIndex = 0;
    m_fEncounterStartingRange = 0.0;
    m_fInterceptorTimeOffset = 0.0;
    iOffset = 124 + 1;
    m_iUFOTarget = 0;
    m_aiConsumableQuantitiesInEffect.Add(128 - iOffset);

	//ALL THE CODE BELOW IS IRRELEVANT IN NEW SQUADRON MOD
    m_kCombat.m_aInterceptorExchanges.Remove(0, m_kCombat.m_aInterceptorExchanges.Length);
    m_kCombat.m_aUFOExchanges.Remove(0, m_kCombat.m_aUFOExchanges.Length);
    iLowestScore = 99999;
    iHighestScore = -1;
    for(I=0; I < kInterception.m_arrInterceptors.Length; ++I)
    {
        iScore = class'SU_Utils'.static.GetAggroForShip(m_kInterception.m_arrInterceptors[I], XGShip_UFO(GetShip(0)));
        if(iScore < iLowestScore)
        {
            iLowestScore = iScore;
        }
        if(iScore > iHighestScore)
        {
            iHighestScore = iScore;
        }
        aiInterceptorScores.AddItem(iScore);
    }
    if(iLowestScore == iHighestScore)
    {
        m_iUFOTarget = Rand(kInterception.m_arrInterceptors.Length) + 1;
        kInterception.m_arrInterceptors.InsertItem(0, kInterception.m_arrInterceptors[m_iUFOTarget - 1]);
        kInterception.m_arrInterceptors.Remove(m_iUFOTarget, 1);
        m_iUFOTarget = 1;
    }
    else
    {
        for(I = 0; I < kInterception.m_arrInterceptors.Length; ++I)
        {
            if(aiInterceptorScores[I] == iHighestScore)
            {
                m_iUFOTarget = I + 1;
                break;
            }
        }
    }
}
/** Sets initial cooldown at start of battle. Respects cooldown already set during ship selection.*/
function StaggerWeaponsForShip(int iShip)
{
	local int I;
	local XGShip kShip;
	local array<TShipWeapon> akShipWeapons;

	kShip = GetShip(iShip);
	akShipWeapons = kShip.GetWeapons();
	if(akShipWeapons.Length < 2)
	{
		//GetWeapons skips vulcan cannon, so...
		akShipWeapons.AddItem(SHIPWEAPON(0));
	}
	for(I = 0; I < akShipWeapons.Length; ++I)
	{
		if(kShip.m_afWeaponCooldown[I] <= 0.0)
		{
			kShip.m_afWeaponCooldown[I] = float(Rand(20)) / 10.0;
		}
		else `Log(GetFuncName() @ XGShip_Interceptor(kShip).GetCallsign()  @ "cooldown already set to" @ kShip.m_afWeaponCooldown[I] @ "s");
	}
}
function float GetTimeUntilOutrun(int iShip)
{
	return FMin(CalcTimeUntilOutrun(), 60.0);
}
function bool IsUfo(int iShip)
{
    return iShip <= 0;
}
/**DEPRECATED Not used in new squadron mod.*/
function string GetSquadronStatusBrief()
{
    local int I;
    local string strStatusBrief;
    local XGShip_Interceptor kShip;
    local int iLength, iChar;
    local string strTemp;

    strStatusBrief = "";
    foreach m_kInterception.m_arrInterceptors(kShip)
    {
        //do not print a row for current leader
    	if(kShip == XGShip_Interceptor(GetShip(m_iUFOTarget)))
        {
            continue;
        }
        //for others start with ship icon
        strStatusBrief = strStatusBrief $ ((("<img src='img:///" $ ((kShip.IsFirestorm()) ? "LongWar.Icons.IC_Firestorm" : "LongWar.Icons.IC_Raven")) $ "' height='16' width='16'>") $ " ");
        iLength = 0;
        //pick characters from pilot's name one by one...
        for(I=0; I < Len(kShip.m_strCallsign); ++I)
        {
            //pick next char...
        	strTemp = Mid(kShip.m_strCallsign, I, 1);
            
        	//find char's position in a string with characters sorted based on their screen-width 
        	iChar = InStr("ijl|ft. IrcksvxyzJadbeghnopquLFTZABEKSVXYwPCDHNRUmMGOQW", strTemp);
            
        	//if character is not found in the list
        	if(iChar == -1)
            {
            	//increase length estimation by 100 which stands for "a"
            	iLength += 100;
            }
            //otherwise increase length estimation depending on the position
			//wider character increases the length more; this has been determined with visual comparison
            else
            {
                if(iChar >= 0)
                {
                    iLength += 40;
                }
                if(iChar >= 3)
                {
                    iLength += 5;
                }
                if(iChar >= 4)
                {
                    iLength += 5;
                }
                if(iChar >= 9)
                {
                    iLength += 10;
                }
                if(iChar >= 10)
                {
                    iLength += 5;
                }
                if(iChar >= 11)
                {
                    iLength += 25;
                }
                if(iChar >= 19)
                {
                    iLength += 10;
                }
                if(iChar >= 30)
                {
                    iLength += 10;
                }
                if(iChar >= 34)
                {
                    iLength += 10;
                }
                if(iChar >= 37)
                {
                    iLength += 5;
                }
                if(iChar >= 44)
                {
                    iLength += 5;
                }
                if(iChar >= 50)
                {
                    iLength += 5;
                }
                if(iChar >= 52)
                {
                    iLength += 5;
                }
                if(iChar == 55)
                {
                    iLength += 30;
                }
            }
            //print the character and pick next
            strStatusBrief = strStatusBrief $ strTemp;
        }
        
//now when name is printed, print blank spaces to the right until length estimation hits 2500 (= width of 25 'a' letters)
        while(iLength < 2500)
        {
            strStatusBrief = strStatusBrief $ ("<font size='10'>" $ (" " $ "</font>"));
            iLength += 25;
        }
        
		//now check if the ship is still in fight and if not (iRange=3) print status-text instead od HP bar
        if(kShip.GetRange() == 3)
        {
            if(kShip.m_iHP <= 0)
            {
                strStatusBrief = strStatusBrief @ class'SU_UIInterceptionEngagement'.default.m_strInterceptorDestroyed;
            }
            else
            {
                strStatusBrief = strStatusBrief @ class'SU_UIInterceptionEngagement'.default.m_strInterceptorAborted;
            }
        }
        //otherwise print HP bar
        else
        {
            //printing 24 "|" characters colored based on HPPct of a ship
            for(I=0; I < 24; ++I)
            {
                strStatusBrief = strStatusBrief $ class'UIUtilities'.static.GetHTMLColoredText("|", ((I < int(kShip.GetHPPct() * float(HP_BAR_LENGTH))) ? HP_BAR_GOOD_COLOR_INDEX : 3));
            }
        }
        //if there is any ship left
        if(kShip != m_kInterception.m_arrInterceptors[m_kInterception.m_arrInterceptors.Length - 1])
        {
            //add new line
        	strStatusBrief = strStatusBrief $ "\n";
        }        
    }    
    //finally print that MEGA multi-row string
    return strStatusBrief;
}


/** DEPRECATED - air battle is handled dynamically in SU 2.0, see SU_UIInterceptionEngagement.FireWeaponsCheck*/
function UpdateWeapons(float fDeltaT)
{
    local CombatExchange kCombatExchange;
    local array<TShipWeapon> akShipWeapons;
    local array<CombatExchange> akCombatExchange;
    local XGShip kShip;
    local int iShip, iWeapon, I;

    for(iShip=0; iShip < GetNumShips(); ++iShip)
    {
        kShip = GetShip(iShip);
        kShip.UpdateWeapons(fDeltaT);
        if(AreAllWeaponsInRange(iShip))
        {
            akShipWeapons = kShip.GetWeapons();
			if(akShipWeapons.Length < 2)
			{
				//vulcan must have been skipped, so...
				akShipWeapons.AddItem(SHIPWEAPON(0));
			}
			if(akShipWeapons.Length < 2)//Vulcan Cannon missing...
				akShipWeapons.AddItem(SHIPWEAPON(0));
            for(iWeapon = 0; iWeapon < akShipWeapons.Length; ++iWeapon)
            {
                if(akShipWeapons[iWeapon].eType >= 0)
                {
                    if(m_afShipDistance[iShip] <= float(akShipWeapons[iWeapon].iRange))
                    {
                        if(kShip.m_afWeaponCooldown[iWeapon] <= 0.0)
                        {
                            kShip.m_afWeaponCooldown[iWeapon] += akShipWeapons[iWeapon].fFiringTime;
                            kCombatExchange.iSourceShip = iShip;
                            kCombatExchange.iWeapon = iWeapon;
                            if(iShip == 0)
                            {
                                if(!IsShipDead(m_iUFOTarget))
                                {
                                    kCombatExchange.iTargetShip = m_iUFOTarget;
                                }
                                else
                                {
                                    kCombatExchange.iTargetShip = 1;
                                }
                            }
                            else
                            {
                                kCombatExchange.iTargetShip = 0;
                            }
                            I = akShipWeapons[iWeapon].iToHit + ((iShip == 0) ? 0 : Clamp(3 * m_kInterception.m_arrInterceptors[iShip - 1].m_iConfirmedKills, 0, 30));
                            if(kShip.m_kTShip.iRange == 1)
                            {
                                I += 15;
                            }
                            if(kShip.m_kTShip.iRange == 2)
                            {
                                I -= 15;
                            }
                            if(!IsUFO(iShip) && kShip.IsDamaged())
                            {
                                I -= 25;
                            }
                            I = Clamp(I, 5, 95);
                            kCombatExchange.iDamage = GetShipDamage(akShipWeapons[iWeapon], kCombatExchange);
                            kCombatExchange.iDamage = kCombatExchange.iDamage + Rand(kCombatExchange.iDamage / 2);
                            if(iShip != 0)
                            {
                                if(LABS().IsResearched(GetShip(kCombatExchange.iTargetShip).m_kTShip.eType + 57))
                                {
                                    kCombatExchange.iDamage *= 1.10;                                                                        
                                }
                                kCombatExchange.iDamage *= (float(1) + (float(m_kInterception.m_arrInterceptors[iShip - 1].m_iConfirmedKills) / float(100)));
                                if(iWeapon != 0)
                                {
                                    kCombatExchange.iDamage /= 2.0;
                                }
                            }
                            if(Rand(100) <= I)
                            {
                                kCombatExchange.bHit = true;
                            }
                            else
                            {
                                kCombatExchange.bHit = false;
                            }
                            kCombatExchange.fTime = m_fTimeElapsed;
                            akCombatExchange.AddItem(kCombatExchange);
                        }
                    }
                }
            }
        }
    }
    for(I = 0; I < akCombatExchange.Length; ++I)
    {
        if(akCombatExchange[I].iSourceShip == 0)
        {
            m_kCombat.m_aUFOExchanges.AddItem(akCombatExchange[I]);
        }
        else
        {
            m_kCombat.m_aInterceptorExchanges.AddItem(akCombatExchange[I]);
        }
        if(akCombatExchange[I].bHit)
        {
            m_aiShipHP[akCombatExchange[I].iTargetShip] -= akCombatExchange[I].iDamage;
        }
    }
}
/** DEPRECATED - air battle is handled dynamically in SU 2.0, see SU_UIInterceptionEngagement.AnyInterceptorsChasing*/
function bool AnyInterceptorsChasing()
{
    local int I;

    for(I=1; I < GetNumShips(); ++I)
    {
        if((!IsShipDead(I) && !IsShipOutrun(I)) && GetShip(I).m_kTShip.iRange < 3)
        {
            return true;
        }
    }
    return false;
}
function XGShip GetShip(int iIndex)
{
	if(iIndex <= 0)
	{
		return SU_XGInterception(m_kInterception).m_arrUFOs[-iIndex];
	}
    else
    {
        return m_kInterception.m_arrInterceptors[iIndex - 1];
    }
}
function UpdateEngagementResult(float fElapsedTime)
{
    local int I, iHP;
    local bool bAnyInterceptorsChasing;
	local XGShip_UFO kUFO;

	kUFO = m_kInterception.m_kUFOTarget;
    //if result has already been decided (UFO escaped/won actually)
	if(m_kInterception.m_eUFOResult != 0)
    {
        return;
    }
	if(class'SquadronUnleashed'.static.IsLWR())
	{
		super(XGInterceptionEngagement).UpdateEngagementResult(fElapsedTime);
		if(m_kInterception.m_eUFOResult == eUR_Crash || m_kInterception.m_eUFOResult == eUR_Destroyed)
		{
			return;
		}
	}
    //else if UFO defeated
    if(kUFO.m_iHP <= 0)
    {
		if(class'SquadronUnleashed'.static.IsLWR())
		{
			GEOSCAPE().m_arrCraftEncounters[kUFO.GetType()] += 1;
			if(kUFO.GetType() == 5 || kUFO.GetType() == 10)
			{
				m_kInterception.m_eUFOResult = eUR_Destroyed;
				return;
			}
		}
		m_kInterception.m_eUFOResult = eUR_Destroyed;//ensure basic result
        //in the first month guaranteed crash
    	if(AI().GetMonth() == 0)
        {
            m_kInterception.m_eUFOResult = eUR_Crash;
			return;
        }
		iHP = kUFO.m_iHP;
    	//if InterceptionTweak mod is on, scale up the HP for overkill
        if(class'SquadronUnleashed'.default.bInterceptionTweakOn)
        {
    		iHP *= class'SquadronUnleashed'.default.INTERCEPTION_TWEAK_SCALER;
        }
		//get type of UFO
		I = kUFO.m_kTShip.eType;
        switch(I)
        {
            //scout size
			case 4:
            case 10:
                iHP += HP_OVERKILL_THRESHOLD[0];
            	if(Rand(100) >= (iHP / (0 - HP_OVERKILL_PER_ONE_PCT_DESTR_CHANCE[0])))
                {
                    m_kInterception.m_eUFOResult = eUR_Crash;
                    return;
                }
                break;
            //large scout size
            case 5:
            case 11:
				iHP += HP_OVERKILL_THRESHOLD[1];
                if(Rand(100) >= (iHP / (0 - HP_OVERKILL_PER_ONE_PCT_DESTR_CHANCE[1])))
                {
                    m_kInterception.m_eUFOResult = eUR_Crash;
                    return;
                }
                break;
			//medium size
            case 6:
            case 12:
				iHP += HP_OVERKILL_THRESHOLD[2];
                if(Rand(100) >= (iHP / (0 - HP_OVERKILL_PER_ONE_PCT_DESTR_CHANCE[2])))
                {
                    m_kInterception.m_eUFOResult = eUR_Crash;
                    return;
                }
                break;
			//large size
            case 7:
            case 13:
				iHP += HP_OVERKILL_THRESHOLD[3];
                if(Rand(100) >= (iHP / (0 - HP_OVERKILL_PER_ONE_PCT_DESTR_CHANCE[3])))
                {
                    m_kInterception.m_eUFOResult = eUR_Crash;
                    return;
                }
                break;
			//very large size
            case 8:
            case 14:
				iHP += HP_OVERKILL_THRESHOLD[4];
                if(Rand(100) >= (iHP / (0 - HP_OVERKILL_PER_ONE_PCT_DESTR_CHANCE[4])))
                {
                    m_kInterception.m_eUFOResult = eUR_Crash;
                    return;
                }
                break;
			//Overseer
            case 9:
				iHP += HP_OVERKILL_THRESHOLD[5];
				if(Rand(100) >= (iHP / (0 - HP_OVERKILL_PER_ONE_PCT_DESTR_CHANCE[5])))
                {
					m_kInterception.m_eUFOResult = eUR_Crash;
                }
                return;
            default:
				m_kInterception.m_eUFOResult = eUR_Crash;
        }            
    }
	//if the battle has not been decided yet
    else
    {
        //set 'no chasers' by default
    	bAnyInterceptorsChasing = false;
        //and loop over all fighters searching for any still fighting
        for(I=0; I < m_kInterception.m_arrInterceptors.Length; ++I)
        {
            //if jet is alive and not outrun
            if(m_kInterception.m_arrInterceptors[I].m_iHP > 0 && m_kInterception.m_arrInterceptors[I].m_kTShip.iRange < 3 && fElapsedTime <= (GetTimeUntilOutrun(1)))
            {
                //toggle the default to true
            	bAnyInterceptorsChasing = true;
            }
        }
        //if still no chasers after loop
        if(!bAnyInterceptorsChasing)
        {
            //decide: UFO escaped
        	m_kInterception.m_eUFOResult = eUR_Escape;
        }
    }
}
function float CalcTimeUntilOutrun(optional int iBoostMultiplier=GetNumConsumableInEffect(126), optional bool bLeaderBonus=true)
{
	SU_XGInterception(m_kInterception).UpdateContactTime(iBoostMultiplier, bLeaderBonus);
	return SU_XGInterception(m_kInterception).m_fContactTime;
}
defaultproperties
{
}