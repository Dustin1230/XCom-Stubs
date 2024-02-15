class SU_PilotRankMgr extends Actor
	config(SquadronUnleashed);

struct TPilotRank
{
	var int CareerPath;
	var int iReqXP;
	var int iKills;
	var int iSize;
	var int iAim;
	var int iDef;
	var int iTeamAim;
	var int iTeamDef;
	var float fDamage;
	var int iTraitType;
};
struct TPilotCareerPath
{
	var int iType;
	var string strName;
	var string strDesc;
	var string strImg;
	var array<TPilotRank> arrTRanks;
};
struct TPilotTrait
{
	var int iTraitType;
	var int iBonusAim;
	var int iBonusTeamAim;
	var int iBonusDef;
	var int iBonusTeamDef;
	var int iBonusDodge;
	var int iBonusDmgPct;
	var int iBonusCritChance;
	var int iBonusCritDmgPct;
	var int iBonusTime;
};
struct TPilotTraitReqs
{
	var int iTraitType;
	var bool bCloseDistance;
	var bool bFireStorm;
	var int iSquadronSize;
	var int iTactic;
	
	structdefaultproperties
	{
		iTactic=-1
	}
};
var config array<TPilotRank> m_PilotRank;
var config array<TPilotTrait> m_PilotTraits;
var config array<TPilotTraitReqs> m_TraitReqs;
var config array<string> m_strCareerImgPath;
var localized array<string> m_arrPilotRankNames;
var localized array<string> m_arrPilotRankShort;
var localized array<string> m_arrCareerPathNames;
var localized array<string> m_arrCareerSummaries;
var localized array<string> m_arrTraitNames;
var localized string m_strTraitModAim;
var localized string m_strTraitModTeamAim;
var localized string m_strTraitModDef;
var localized string m_strTraitModTeamDef;
var localized string m_strTraitModDodge;
var localized string m_strTraitModDmgPct;
var localized string m_strTraitModCrit;
var localized string m_strTraitModCritDmgPCt;
var localized string m_strTraitModTime;
var localized string m_strTraitReqClose;
var localized string m_strTraitReqSquadronSize;
var localized string m_strTraitReqFirestorm;
var array<TPilotCareerPath> m_arrCareers;
var config int PILOT_SWAP_CAREER_DAYS_FIXED;
var config int PILOT_SWAP_CAREER_DAYS_PER_RANK;
var config int XP_PER_ENGAGMEMENT_SECOND;
var config int XP_FOR_KILL_SHOT;
var config int XP_FOR_WIN;
var config int XP_FOR_HIT;

function BuildCareerPaths()
{
	local TPilotRank tRank;
	local bool bXPReqFound;
	
	`Log(GetFuncName() @ self);
	m_arrCareers.Length = 0;
	if(default.m_PilotRank.Length > 0)
	{
		foreach default.m_PilotRank(tRank)
		{
			if(m_arrCareers.Find('iType', tRank.CareerPath) < 0)
			{
				`Log("Caching career type" @ tRank.CareerPath);
				m_arrCareers.Add(1);
				m_arrCareers[m_arrCareers.Length-1].iType = tRank.CareerPath;
				m_arrCareers[m_arrCareers.Length-1].strName = m_arrCareerPathNames[tRank.CareerPath];
				m_arrCareers[m_arrCareers.Length-1].strDesc = m_arrCareerSummaries[tRank.CareerPath];
				m_arrCareers[m_arrCareers.Length-1].strImg = m_strCareerImgPath[tRank.CareerPath];
			}
			if(tRank.iReqXP > 0)
			{
				bXPReqFound = true;
			}
			m_arrCareers[m_arrCareers.Find('iType', tRank.CareerPath)].arrTRanks.AddItem(tRank);
		}
	}
	else
	{
		EnsureBasicCareerPath();
	}
	class'SU_Utils'.static.GetSquadronMod().m_bDisablePilotXP = !bXPReqFound;
	`Log("Total career types cached:" @ m_arrCareers.Length$". m_bDisablePilotXP=" $class'SU_Utils'.static.GetSquadronMod().m_bDisablePilotXP);
}
function EnsureBasicCareerPath()
{
	m_arrCareers.Add(1);
	m_arrCareers[m_arrCareers.Length-1].iType = m_arrCareers.Length-1;
	m_arrCareers[m_arrCareers.Length-1].strImg = "gfxXcomIcons.XComIcons_I27B";
	m_arrCareers[m_arrCareers.Length-1].arrTRanks.Add(6);

	m_arrCareers[m_arrCareers.Length-1].arrTRanks[0].CareerPath = m_arrCareers.Length-1;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[0].iKills= 0;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[0].iSize= 1;

	m_arrCareers[m_arrCareers.Length-1].arrTRanks[1].CareerPath = m_arrCareers.Length-1;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[1].iKills= 1;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[1].iSize= 2;

	m_arrCareers[m_arrCareers.Length-1].arrTRanks[2].CareerPath = m_arrCareers.Length-1;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[2].iKills= 3;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[2].iSize= 3;

	m_arrCareers[m_arrCareers.Length-1].arrTRanks[3].CareerPath = m_arrCareers.Length-1;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[3].iKills= 5;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[3].iSize= 4;

	m_arrCareers[m_arrCareers.Length-1].arrTRanks[4].CareerPath = m_arrCareers.Length-1;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[4].iKills= 7;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[4].iSize= 5;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[5].iTeamAim= 5;

	m_arrCareers[m_arrCareers.Length-1].arrTRanks[5].CareerPath = m_arrCareers.Length-1;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[5].iKills= 10;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[5].iSize= 6;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[5].iTeamAim= 5;
	m_arrCareers[m_arrCareers.Length-1].arrTRanks[5].iTeamDef= 5;
}
/** Returns TPilotCareerPath struct for specified career type. Debugs invalid type. 
 *  @param iType Career type, negative values are force-debugged to 0.
 */
function TPilotCareerPath GetCareerPathByType(int iType)
{
	local int idx;

	idx = m_arrCareers.Find('iType', iType);
	idx = Max(0, idx);//debug for the case when iType was not found
	return m_arrCareers[idx];
}
/** Returns rank's full UI name. Debugs invalid rank.*/
function string GetFullRankName(int iRank)
{
	iRank = Clamp(iRank, 0, m_arrPilotRankNames.Length - 1);
	return m_arrPilotRankNames[iRank];
}
/** Returns rank's short UI name. Debugs invalid rank.*/
function string GetShortRankName(int iRank)
{
	iRank = Clamp(iRank, 0, m_arrPilotRankShort.Length - 1);
	return m_arrPilotRankShort[iRank];
}
/** Returns career UI name. Debugs invalid career.*/
function string GetCareerPathName(int iType)
{
	return GetCareerPathByType(iType).strName;
}
/** Returns career summary. Debugs invalid career.*/
function string GetCareerSummary(int iType)
{
	return GetCareerPathByType(iType).strDesc;
}
/** Returns size of squadron for a given rank in the given career. Debugs invalid rank or career.*/
function int GetSquadronSizeAtRank(int iRank, int iCareerPath)
{
	iRank = Clamp(iRank, 0, GetCareerPathByType(iCareerPath).arrTRanks.Length - 1);
	return GetCareerPathByType(iCareerPath).arrTRanks[iRank].iSize;
}
/** Returns kills' requirement for a given rank in the given career. Debugs invalid rank or career.*/
function int GetKillsForRank(int iRank, int iCareerPath, optional bool bAdjustForDynamicWar=class'SU_Utils'.static.GetGameCore().IsOptionEnabled(9))
{
	local int iKillsForRank;

	iRank = Clamp(iRank, 0, GetCareerPathByType(iCareerPath).arrTRanks.Length - 1);
	iKillsForRank = GetCareerPathByType(iCareerPath).arrTRanks[iRank].iKills;
	if(bAdjustForDynamicWar)
	{
		iKillsForRank *= class'XGTacticalGameCore'.default.SW_MARATHON;
	}
	return iKillsForRank;
}
/** Returns XP requirement for a given rank in the given career. Debugs invalid rank or career.*/
function int GetXPForRank(int iRank, int iCareerPath, optional bool bAdjustForDynamicWar=class'SU_Utils'.static.GetGameCore().IsOptionEnabled(9))
{
	local int iXP;

	iRank = Clamp(iRank, 0, GetCareerPathByType(iCareerPath).arrTRanks.Length - 1);
	iXP = GetCareerPathByType(iCareerPath).arrTRanks[iRank].iReqXP;
	if(bAdjustForDynamicWar)
	{
		iXP *= class'XGTacticalGameCore'.default.SW_MARATHON;
	}
	return iXP;
}
function int GetXPGap(int iLowRank, int iHighRank, int iCareerPath, optional bool bAdjustForDynamicWar=class'SU_Utils'.static.GetGameCore().IsOptionEnabled(9))
{
	return GetXPForRank(iHighRank, iCareerPath, bAdjustForDynamicWar) - GetXPForRank(iLowRank, iCareerPath, bAdjustForDynamicWar);
}
/** Returns aim bonus for a pilot of a given rank in the given career. Debugs invalid rank or career.*/
function int GetRankAimBonus(int iRank, int iCareerPath)
{	
	iRank = Clamp(iRank, 0, GetCareerPathByType(iCareerPath).arrTRanks.Length - 1);
	return GetCareerPathByType(iCareerPath).arrTRanks[iRank].iAim;
}
/** Returns defense (evasion) bonus for a pilot of a given rank in the given career. Debugs invalid rank or career.*/
function int GetRankDefBonus(int iRank, int iCareerPath)
{
	iRank = Clamp(iRank, 0, GetCareerPathByType(iCareerPath).arrTRanks.Length - 1);
	return GetCareerPathByType(iCareerPath).arrTRanks[iRank].iDef;
}
/** Returns dmg multiplier for a pilot of a given rank in the given career. Debugs invalid rank or career.*/
function float GetRankDmgBonus(int iRank, int iCareerPath)
{
	iRank = Clamp(iRank, 0, GetCareerPathByType(iCareerPath).arrTRanks.Length - 1);
	return GetCareerPathByType(iCareerPath).arrTRanks[iRank].fDamage;
}
/** Returns squadron aim bonus for a pilot of a given rank in the given career. Debugs invalid rank or career.*/
function int GetRankTeamAimBonus(int iRank, int iCareerPath)
{	
	iRank = Clamp(iRank, 0, GetCareerPathByType(iCareerPath).arrTRanks.Length - 1);
	return GetCareerPathByType(iCareerPath).arrTRanks[iRank].iTeamAim;
}
/** Returns squadron defense (evasion) bonus for a pilot of a given rank in the given career. Debugs invalid rank or career.*/
function int GetRankTeamDefBonus(int iRank, int iCareerPath)
{
	iRank = Clamp(iRank, 0, GetCareerPathByType(iCareerPath).arrTRanks.Length - 1);
	return GetCareerPathByType(iCareerPath).arrTRanks[iRank].iTeamDef;
}
/** Returns number of days out of service for a pilot who swaps career path at iRank*/
function int CalcDaysToSwapCareer(int iRank)
{
	return PILOT_SWAP_CAREER_DAYS_FIXED + iRank * PILOT_SWAP_CAREER_DAYS_PER_RANK;
}
function string GetCareerImgPath(int iCareerPath)
{
	return "img:///" $ GetCareerPathByType(iCareerPath).strImg;
}
function TPilotTrait GetTrait(int iType)
{
	local TPilotTrait Trait;
	local int iFound;

	 iFound = m_PilotTraits.Find('iTraitType', iType);
	 if(iFound != -1)
	 {
		Trait = m_PilotTraits[iFound];
	 }
	 return Trait;
}
function TPilotTraitReqs GetTraitRestrictions(int iType)
{
	local TPilotTraitReqs tReqs;
	local int iFound;

	iFound = m_TraitReqs.Find('iTraitType', iType);
	if(iFound != -1)
	{
		tReqs = m_TraitReqs[iFound];
	}
	return tReqs;
}
DefaultProperties
{
}