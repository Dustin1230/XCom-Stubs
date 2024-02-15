/**A helper actor to simulate combat results based on DPS values and calculate win chance.*/
class SU_CombatSimulator extends Actor;

var SU_XGInterception m_kInterception;
var int MAX_SIMCOMBAT_TIME;
var int m_iTotalBattleSeconds;
var array<int> m_aPostCombatUFOHP;
var array<int> m_aPostCombatXComHP;
var array<XGShip_Interceptor> m_arrBackLine;
var array<XGShip_Interceptor> m_arrFrontLine;
var array<int> m_arrMaxFiringTime1;
var array<int> m_arrMaxFiringTime2;
var array <XGShip_UFO> m_arrUFOs;
var int m_iCurrentXcomDPS;
var int m_iCurrentEnemyDPS;
var XGShip_Interceptor m_kJetTarget;
var XGShip_UFO m_kUFOTarget;
var XGShip_UFO m_kMotherShip;
var bool m_bUpdatePending;
var bool m_bEnemyWins;
var bool m_bXComWins;

function Init(SU_XGInterception kInterception)
{
	m_kInterception = kInterception;
}

function SimCombat()
{
	SetupCombatStart();
	for(m_iTotalBattleSeconds=0; m_iTotalBattleSeconds <= MAX_SIMCOMBAT_TIME; m_iTotalBattleSeconds++)
	{
		if(m_bUpdatePending)
		{
			UpdateUFOTarget();
			UpdateTargetedJet();
			UpdateXComDPS();
			UpdateEnemyDPS();
			m_bUpdatePending = false;
		}
		XComDealsDamage();
		EnemyDealsDamage();
		if(CheckBattleDone())
		{
			break;
		}
	}
	PostCombatCleanup();
}
function SetupCombatStart()
{
	local int i, iAmmo;
	local SU_Pilot kPilot;
	local XGShip_Interceptor kShip;
	local array<TShipWeapon> arrShipWeapons;	

	m_aPostCombatUFOHP.Length = 0;
	m_aPostCombatXComHP.Length = 0;
	m_arrBackLine.Length = 0;
	m_arrFrontLine.Length = 0;
	m_arrUFOs.Length = 0;
	for(i=0; i < m_kInterception.m_arrUFOs.Length; ++i)
	{
		m_aPostCombatUFOHP.AddItem(m_kInterception.m_arrUFOs[i].m_iHP);
		m_arrUFOs.AddItem(m_kInterception.m_arrUFOs[i]);
	}
	m_kMotherShip = m_arrUFOs[--i];
	for(i=0; i < m_kInterception.m_arrInterceptors.Length; ++i)
	{
		kShip = m_kInterception.m_arrInterceptors[i];
		m_aPostCombatXComHP.AddItem(kShip.m_iHP);
		kPilot = class'SU_Utils'.static.GetPilot(kShip);
		if(kPilot.m_bStartBattleClose || kPilot.m_iForcedStartingDistance > 0)
		{
			m_arrFrontLine.AddItem(kShip);
		}
		else
		{
			m_arrBackLine.AddItem(kShip);
		}
		arrShipWeapons = kShip.GetWeapons();
		if(kShip.m_afWeaponCooldown[0] == 0.0)
		{
			iAmmo = class'SU_Utils'.static.GetAmmoForWeaponType(arrShipWeapons[0].eType);
			m_arrMaxFiringTime1[i] = iAmmo == -1 ? MAX_SIMCOMBAT_TIME : FCeil(float(iAmmo) * arrShipWeapons[0].fFiringTime);
		}
		else
		{
			m_arrMaxFiringTime1[i] = -1;
		}
		if(kShip.m_afWeaponCooldown[1] == 0.0)
		{
			iAmmo = class'SU_Utils'.static.GetAmmoForWeaponType(arrShipWeapons[1].eType);
			m_arrMaxFiringTime2[i] = iAmmo == -1 ? MAX_SIMCOMBAT_TIME : FCeil(float(iAmmo) * arrShipWeapons[1].fFiringTime);
		}
		else
		{
			m_arrMaxFiringTime2[i] = -1;
		}
	}
	m_bUpdatePending = true;
}
function UpdateTargetedJet()
{
	local int iShipID, iScore, iHighestScore;
	local XGShip_Interceptor kShip;
	local array<int> arrScores;

	//bits 1-6 (lowest priority)- hold Rand(63) factor
	//bit  7                    - holds IsCurrentTarget flag (0/1)
	//bits 8-21                 - hold current dmg (0-16383)
	//bits 22-28                - hold Aggro stat (0-127)
	//bit  29 (highest priority)- holds m_bClosedIn (short distance) flag (0/1)
	arrScores.Length = 0;
	arrScores.Add(m_kInterception.m_arrInterceptors.Length);
	for(iShipID=0; iShipID < m_kInterception.m_arrInterceptors.Length; ++iShipID)
	{
		kShip = m_kInterception.m_arrInterceptors[iShipID];
		iScore = 0;
		if(m_arrBackLine.Find(kShip) < 0 && m_arrFrontLine.Find(kShip) < 0)
		{
			iScore = -1;
		}
		else
		{
			if(m_arrFrontLine.Find(kShip) != -1)
			{
				iScore += 1 << 28;
			}
			iScore += Min(127, class'SU_Utils'.static.GetAggroForShip(kShip, m_kUFOTarget)) << 21;
			iScore += Min(16383, (kShip.GetHullStrength() - m_aPostCombatXComHP[m_kInterception.m_arrInterceptors.Find(kShip)])) << 7;
			if( kShip == m_kJetTarget)
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
	if(iHighestScore != -1 && kShip != m_kJetTarget)
	{
		m_kJetTarget = kShip;
	}
}
function UpdateUFOTarget()
{
	local int i;

	for(i=0; i<m_aPostCombatUFOHP.Length; ++i)
	{
		if(m_aPostCombatUFOHP[i] > 0)
		{
			m_kUFOTarget = m_arrUFOs[i];
			break;
		}
	}
}
function UpdateEnemyDPS()
{
	local XGShip_UFO kUFO;
	local int idx;
	local bool bCloseTarget;

	m_iCurrentEnemyDPS=0;
	bCloseTarget = m_arrFrontLine.Find(m_kJetTarget) != -1;
	foreach m_arrUFOs(kUFO, idx)
	{
		if(m_aPostCombatUFOHP[idx] >= 0)
		{
			if(bCloseTarget || kUFO == m_kUFOTarget)
			{
				m_iCurrentEnemyDPS += class'SU_Utils'.static.CalculateShipDPS(kUFO, m_kJetTarget, true, bCloseTarget && kUFO == m_kUFOTarget);
			}
		}
	}
	`log(m_iCurrentEnemyDPS,,GetFuncName());
}
function UpdateXComDPS()
{
	local XGShip_Interceptor kShip;
	local int idx, iDPS;
	local bool bDmgHack;

	m_iCurrentXcomDPS=0;
	foreach m_kInterception.m_arrInterceptors(kShip, idx)
	{
		if(m_arrFrontLine.Find(kShip) < 0 && m_arrBackLine.Find(kShip) < 0)
		{
			continue;
		}
		if(m_aPostCombatXComHP[idx] >= 0)
		{
			if(m_aPostCombatXComHP[idx] < kShip.GetHullStrength())
			{
				kShip.m_iHP -= 1;
				bDmgHack = true;
			}
			iDPS = class'SU_Utils'.static.CalculateShipDPS(kShip, m_kUFOTarget, false, m_arrFrontLine.Find(kShip) != -1);
			m_iCurrentXcomDPS += iDPS;
			if(bDmgHack)
			{
				kShip.m_iHP += 1;
				bDmgHack = false;
			}
		}
	}
	`log(m_iCurrentXcomDPS,,GetFuncName());
}
function UpdateXComAmmo()
{
	local XGShip_Interceptor kShip;
	local int idx;

	foreach m_kInterception.m_arrInterceptors(kShip, idx)
	{
		if(m_arrMaxFiringTime1[idx] != -1 && m_iTotalBattleSeconds > m_arrMaxFiringTime1[idx])
		{
			m_bUpdatePending = true;
			kShip.m_afWeaponCooldown[0] = 1.0;//hack to make CalculateDPS skip primary weapon
		}
		if(m_arrMaxFiringTime2[idx] != -1 && m_iTotalBattleSeconds > m_arrMaxFiringTime2[idx])
		{
			m_bUpdatePending = true;
			kShip.m_afWeaponCooldown[1] = 1.0;//hack to make CalculateDPS skip primary weapon
		}
		if(m_arrBackLine.Find(kShip) != -1 && HasOnlyShortRangeWeapons(kShip))
		{
			m_arrBackLine.RemoveItem(kShip);
			m_arrFrontLine.AddItem(kShip);
		}
	}
}
function bool HasOnlyShortRangeWeapons(XGShip_Interceptor kShip)
{
	local bool bHasLongAmmo, bHasShortAmmo;

	if(class'SU_Utils'.static.IsShortDistanceWeapon(kShip.m_kTShip.arrWeapons[0]))
	{
		bHasShortAmmo = kShip.m_afWeaponCooldown[0] == 0.0;
	}
	else
	{
		bHasLongAmmo = kShip.m_afWeaponCooldown[0] == 0.0;
	}
	if(class'SU_Utils'.static.IsShortDistanceWeapon(kShip.m_kTShip.arrWeapons[1]))
	{
		bHasShortAmmo = bHasShortAmmo || kShip.m_afWeaponCooldown[1] == 0.0;
	}
	else
	{
		bHasLongAmmo = bHasLongAmmo || kShip.m_afWeaponCooldown[1] == 0.0;
	}
	
	return bHasShortAmmo && !bHasLongAmmo;
}
function PostCombatCleanup()
{
	local XGShip_Interceptor kShip;
	local int i;
	local string sDebug;

	foreach m_kInterception.m_arrInterceptors(kShip)
	{
		if(kShip.m_afWeaponCooldown[0] == 1.0)
		{
			kShip.m_afWeaponCooldown[0] = 0.0f;
		}
		if(kShip.m_afWeaponCooldown[1] == 1.0)
		{
			kShip.m_afWeaponCooldown[1] = 0.0f;
		}
	}
	for(i=0; i < m_aPostCombatXComHP.Length; ++i)
	{
		sDebug $="\n"$Chr(9);
		sDebug $="XComHP["$i$"]="$ m_aPostCombatXComHP[i];
	}
	for(i=0; i < m_aPostCombatUFOHP.Length; ++i)
	{
		sDebug $="\n"$Chr(9);
		sDebug $="UFOHP["$i$"]="$ m_aPostCombatUFOHP[i];
	}
	`log(sDebug,,GetFuncName());
}
function XComDealsDamage()
{
	local int i;

	i =	m_arrUFOs.Find(m_kUFOTarget);
	m_aPostCombatUFOHP[i] -= m_iCurrentXcomDPS;
	if(m_aPostCombatUFOHP[i] <= 0)
	{
		m_bUpdatePending = true;
	}
}
function EnemyDealsDamage()
{
	local int i;

	i =	m_kInterception.m_arrInterceptors.Find(m_kJetTarget);
	m_aPostCombatXComHP[i] -= m_iCurrentEnemyDPS;
	if(m_aPostCombatXComHP[i] <= 0 || m_aPostCombatXComHP[i] <= class'SU_Utils'.static.GetAutoDisengageHPTreshold(m_kJetTarget))
	{
		m_arrFrontLine.RemoveItem(m_kJetTarget);
		m_arrBackLine.RemoveItem(m_kJetTarget);
		m_bUpdatePending = true;
	}
	else if(m_arrFrontLine.Find(m_kJetTarget) != -1 && m_aPostCombatXComHP[i] <= class'SU_Utils'.static.GetAutoBackOffHPTreshold(m_kJetTarget))
	{
		m_arrFrontLine.RemoveItem(m_kJetTarget);
		m_arrBackLine.AddItem(m_kJetTarget);
		m_bUpdatePending = true;
	}
}
function bool CheckBattleDone()
{
	local int i;
	local bool bAnyRemainingUFO, bAnyRemainingJet;

	for(i=0; i<m_aPostCombatUFOHP.Length; ++i)
	{
		if(m_aPostCombatUFOHP[i] > 0)
		{
			bAnyRemainingUFO = true;
			break;
		}
	}
	for(i=0; i<m_aPostCombatXComHP.Length; ++i)
	{
		if(m_aPostCombatXComHP[i] > 0)
		{
			bAnyRemainingJet = true;
			break;
		}
	}
	m_bXComWins = bAnyRemainingJet && !bAnyRemainingUFO;
	m_bEnemyWins = bAnyRemainingUFO && !bAnyRemainingJet;
	`log("TotalBattleSecond" @ m_iTotalBattleSeconds @ "any mor jet?" @ bAnyRemainingJet @ ", any more UFO" @ bAnyRemainingUFO @ ", xcom wins" @ m_bXComWins @ ", enemy wins" @ m_bEnemyWins, m_bXComWins || m_bEnemyWins, GetFuncName());
	return !(bAnyRemainingJet && bAnyRemainingUFO);
}
// function int CalcWinChance()
// {
// 	local float fEscapeTime, fJetMaxTankingTime, fExpectedContactTime, fChance, fRequiredSquadronDPS, fMinSquadronDPS, fMaxSquadronDPS;
// 	local XGShip_Interceptor kJet;
// 	local SU_UFOSquadron kUFOFleet;
// 	local int iEscort, iUFOHPPool;

// 	if(m_iTotalSquadronDPS <=0)
// 	{
// 		return 0;
// 	}
// 	m_kUFO.m_afWeaponCooldown.Length = 2;
// 	fEscapeTime = SU_XGInterception(m_kInterception).m_fContactTime;
// 	foreach m_kInterception.m_arrInterceptors(kJet)
// 	{
// 		fJetMaxTankingTime = kJet.m_iHP / class'SU_Utils'.static.CalculateShipDPS(m_kUFO, kJet);
// 		fExpectedContactTime += FMin(fEscapeTime, fJetMaxTankingTime);
// 	}
// 	fExpectedContactTime = FMin(fEscapeTime, fExpectedContactTime);
// 	iUFOHPPool = m_kUFO.m_iHP;
// 	kUFOFleet = class'SU_Utils'.static.GetUFOSquadron(m_kUFO);
// 	if(kUFOFleet != none && kUFOFleet.GetNumEscorts() > 0)
// 	{
// 		for(iEscort=0; iEscort < kUFOFleet.m_arrEscort.Length; ++iEscort)
// 			iUFOHPPool += kUFOFleet.m_arrEscort[iEscort].iHP;
// 	}
// 	fRequiredSquadronDPS = iUFOHPPool / (fExpectedContactTime - 1.0);//1.0s margin for StaggerWeapons
// 	fMinSquadronDPS = m_iTotalSquadronDPS * 0.80;
// 	fMaxSquadronDPS = m_iTotalSquadronDPS * 1.20;
// 	fChance = FClamp( FMin(fExpectedContactTime / 10, 1.0) - FPctByRange(fRequiredSquadronDPS, fMinSquadronDPS, fMaxSquadronDPS), 0.0f, 1.0f);
// 	return fChance * 100;
// }
DefaultProperties
{
	MAX_SIMCOMBAT_TIME=60
}
