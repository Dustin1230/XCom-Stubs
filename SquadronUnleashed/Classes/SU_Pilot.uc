class SU_Pilot extends XGEntity
	dependson(SU_PilotRankMgr);
//extending XGEntity subscribes this class to ActorClassesToRecord

enum EPilotStatus
{
	ePilotStatus_Ready,
	ePilotStatus_Retraining,
	ePilotStatus_InTransfer,
	ePilotStatus_Incoming,
	ePilotStatus_Recovering,
	ePilotStatus_Wounded,
	ePilotStatus_Unknown,
	ePilotStatus_Dead
};
struct CheckpointRecord_SU_Pilot extends CheckpointRecord
{
	var int m_iCareerPath;
	var int m_iKills;
	var float m_fTeamKills;
	var int m_iXP;
	var int m_iContinent;
	var int m_iStatus;
	var int m_iHoursUnavailable;
	var int m_iNumDogfights;
	var float m_fTotalDogfightTime;
	var XGDateTime m_kJoinServiceDate;
	var string m_strCallSign;
	var string VoiceSetPath;
};
struct TPilotVoice
{
	var SoundCue SFX_EnemySighted;
	var SoundCue SFX_ClosingOnTarget;
	var SoundCue SFX_Aborting;
	var SoundCue SFX_JetBelow50HP;
	var SoundCue SFX_JetDown;
	var SoundCue SFX_UFODown;
	var SoundCue SFX_UFOEscaped;
};
enum EPilotVoiceCue
{
	ePVC_EnemySighted,
	ePVC_ClosingOnTarget,
	ePVC_Aborting,
	ePVC_JetBelow50HP,
	ePVC_JetDown,
	ePVC_UFODown,
	ePVC_UFOEscaped,
};

var int m_iPilotRank;
var int m_iCareerPath;
var int m_iKills;
var float m_fTeamKills;
var int m_iXP;
var int m_iLastBattleXP;
var int m_iLastBattleKills;
var int m_iContinent;
var int m_iStatus;
var int m_iHoursUnavailable;
var int m_iNumDogfights;
var float m_fTotalDogfightTime;
var XGDateTime m_kJoinServiceDate;
var string m_strCallSign;
var bool m_bCareerChoicePending;
var int m_iForcedStartingDistance;//-1 for long, 1 for short, 0 for none
var bool m_bStartBattleClose;
var TPilotCareerPath m_kTCareerPath;
var int m_iCareerTrait;
var int m_iFirestormTrait;
var string VoiceSetPath;
var TPilotVoice m_tVoice;
var bool m_bHPWarningPlayed;
var localized string m_arrPilotStatus[EPilotStatus];

function ApplyCheckpointRecord()
{
    //super.ApplyCheckpointRecord();
}
function Init(EEntityGraphic eGraphic)
{
	SetCareerPath(m_iCareerPath);
	UpdateRank();
	Rename(m_strCallSign, true);
	UpdateShipConfirmedKills();
	InitVoice();
	m_kJoinServiceDate = Spawn(class'XGDateTime');
	m_kJoinServiceDate.CopyDateTime(class'SU_Utils'.static.GetGameCore().GEOSCAPE().m_kDateTime);
	m_kJoinServiceDate.m_fTime = 0;
}
function PostLoadInit()
{
	SetCareerPath(m_iCareerPath);
	UpdateRank();
	Rename(m_strCallSign);
	InitVoice();
	if(GetStatus() == ePilotStatus_Retraining && class'SU_Utils'.static.GetRankMgr().m_arrCareers.Length < 2)
	{
		m_iHoursUnavailable = 0;
		m_iStatus = ePilotStatus_Ready;
	}
}
function UnInit()
{
	if(GetShip() != none)
	{
		UpdateShipConfirmedKills();
		GetShip().m_strCallsign = GetCallsign();
		m_kGameActor = none;
	}
	m_kJoinServiceDate.Destroy();
}
function FeedDataMidCampaign()
{
	m_kJoinServiceDate.CopyDateTime(class'SU_Utils'.static.GetGameCore().AI().m_kStartDate);
	m_kJoinServiceDate.m_fTime=0;
	if(GetServiceDurationInDays() > 30)
	{
		//estimate roughly some initial date, better than "0" or "?"
		m_fTotalDogfightTime = GetServiceDurationInDays() / 30 * (30.0 + FRand() * 15.0) + m_iKills * 10.0;
		m_iNumDogfights = m_fTotalDogfightTime / 12.0;
	}
	m_iXP = GetKills() * (class'SU_PilotRankMgr'.default.XP_FOR_KILL_SHOT + class'SU_PilotRankMgr'.default.XP_FOR_WIN) + m_fTotalDogfightTime * (class'SU_PilotRankMgr'.default.XP_PER_ENGAGMEMENT_SECOND + class'SU_PilotRankMgr'.default.XP_FOR_HIT * 0.30);
	m_fTeamKills = float(m_iNumDogfights) * 0.25;
	VoiceSetPath = "Default";
}
function Rename(optional string strNewCallsign = class'XGLocalizedData'.default.ShipWeaponFlavorTxt[Rand(245) + 11], optional bool bCheckPrefixCut)
{
	local SU_WatchShipMgr kWatchVars;

	if(bCheckPrefixCut && InStr(strNewCallsign, " \"") != -1)
	{
		strNewCallsign = "\"" $ Split(strNewCallsign, " \"", true);
	}
	m_strCallSign = strNewCallsign;
	if(!CallsignIsUnique())
	{
		Rename();	//risk of infinite loop due to recursive call from Rename
	}
	else if(m_kGameActor != none)
	{
		kWatchVars = class'SU_WatchShipMgr'.static.GetWatchShipMgr(GetShip());
		if(kWatchVars != none)
		{
			kWatchVars.StopWatchingCallsign();
		}
		GetShip().m_strCallsign = GetCallsignWithRank(true);
		if(kWatchVars != none)
		{
			kWatchVars.StartWatchingCallsign();
		}
		`Log("Setting" @ GetShip() @ "m_strCallsign to" @ GetShip().m_strCallsign);		
	}
}
function bool CallsignIsUnique()
{
	local bool bValid;
	local SU_Pilot kPilot;
	
	bValid=true;
	foreach DynamicActors(class'SU_Pilot', kPilot)
	{
		if(kPilot.m_strCallSign == m_strCallSign && kPilot != self)
			bValid = false;
	}
	return bValid;
}
/** Updates the rank based on current career path.
 *  @param bUpdateTrait Defaults to TRUE. Updates the pilot's trait based on the updated rank.*/
function UpdateRank(optional bool bUpdateTrait=true)
{
	local int iRank;

	for(iRank = 0; iRank < m_kTCareerPath.arrTRanks.Length - 1; ++iRank)
	{
		if( !QualifiesForRank(iRank+1, m_iCareerPath) )
		{
			break;
		}
	}
	m_iPilotRank = iRank;
	if(bUpdateTrait)
	{
		UpdateTraits();
	}
}
function bool QualifiesForRank(int iRank, optional int iType=m_iCareerPath)
{
	local int iKillsReq, iXPReq;

	if(iType != m_iCareerPath)
	{
		iKillsReq = class'SU_Utils'.static.GetRankMgr().GetKillsForRank(iRank, iType);
		iXPReq = class'SU_Utils'.static.GetRankMgr().GetXPForRank(iRank, iType);
	}
	else
	{
		iKillsReq = m_kTCareerPath.arrTRanks[iRank].iKills;
		iXPReq = m_kTCareerPath.arrTRanks[iRank].iReqXP;
	}
	return ((GetKills() >= iKillsReq || GetTeamKills() >= iKillsReq) && m_iXP >= iXPReq);
}
function bool IsAtMaxRank()
{
	return GetRank() >= GetCareerPath().arrTRanks.Length - 1;
}
function UpdateTraits()
{
	local int iRank;

	m_iCareerTrait=0;
	m_iFirestormTrait=0;
	for(iRank=0; iRank <= GetRank(); ++iRank)
	{
		if(m_kTCareerPath.arrTRanks[iRank].iTraitType != 0)
		{
			if(class'SU_Utils'.static.GetRankMgr().GetTraitRestrictions(m_kTCareerPath.arrTRanks[iRank].iTraitType).bFireStorm)
			{
				m_iFirestormTrait = m_kTCareerPath.arrTRanks[iRank].iTraitType;
			}
			else
			{
				m_iCareerTrait = m_kTCareerPath.arrTRanks[iRank].iTraitType;
			}
		}
	}
}
function TPilotTrait GetCareerTrait()
{
	return class'SU_Utils'.static.GetRankMgr().GetTrait(m_iCareerTrait);
}
function TPilotTrait GetFirestormTrait()
{
	return class'SU_Utils'.static.GetRankMgr().GetTrait(m_iFirestormTrait);
}
function bool IsTraitActive(optional bool bCloseDistance, optional bool bFirestorm)
{
	local SU_XGInterception kInterception;
	local TPilotTraitReqs tReqs;
	local bool bValid;
	local int iTrait;

	iTrait = bFirestorm ? m_iFirestormTrait : m_iCareerTrait;
	if(iTrait <= 0)
	{
		bValid = false;
	}
	else
	{
		tReqs = class'SU_Utils'.static.GetRankMgr().GetTraitRestrictions(iTrait);
		bValid = (!tReqs.bCloseDistance || bCloseDistance);
		bValid = bValid && (!tReqs.bFireStorm || bFirestorm);
		bValid = bValid && (tReqs.iTactic < 0 || GetShip() != none && class'SU_Utils'.static.GetStance(GetShip()) == tReqs.iTactic);
		if(bValid && (tReqs.iSquadronSize > 0))
		{
			bValid = false;
			foreach DynamicActors(class'SU_XGInterception', kInterception)
			{
				if(kInterception.m_arrInterceptors.Find(GetShip()) != -1)
				{
					bValid = kInterception.m_arrInterceptors.Length == tReqs.iSquadronSize;
					break;
				}
			}
		}
	}
	return bValid;
}
function bool IsFirestormTraitActive(optional bool bCloseDistance)
{
	return (GetShip() != none && GetShip().IsFirestorm() && IsTraitActive(bCloseDistance, true));
}
function bool GivesTeamBuffs()
{
	local TPilotTrait Trait;
	local bool bCareerBuff, bFirestormBuff;

	Trait = GetCareerTrait();
	bCareerBuff = class'SU_Utils'.static.GetRankTeamAimBonus(GetRank(), GetCareerType()) != 0 || class'SU_Utils'.static.GetRankTeamDefBonus(GetRank(), GetCareerType()) != 0 || IsTraitActive() && (Trait.iBonusTeamAim != 0 || Trait.iBonusTeamDef != 0);
	Trait = GetFirestormTrait();
	bFirestormBuff = IsFirestormTraitActive() && (Trait.iBonusTeamAim != 0 || Trait.iBonusTeamDef != 0);
	return bCareerBuff || bFirestormBuff;
}
function bool GivesBetterTeamBuffThan(SU_Pilot kOtherPilot)
{
	local int iOthersAimBuff, iOthersDefBuff, iAimBuff, iDefBuff;
	local bool bBetter;
	local TPilotTrait Trait;

	if(!GivesTeamBuffs())
	{
		bBetter = false;
	}
	else
	{
		iAimBuff = class'SU_Utils'.static.GetRankTeamAimBonus(GetRank(), GetCareerType());
		iDefBuff = class'SU_Utils'.static.GetRankTeamDefBonus(GetRank(), GetCareerType());
		if(IsTraitActive())
		{
			Trait = GetCareerTrait();
			iAimBuff += Trait.iBonusTeamAim;
			iDefBuff += Trait.iBonusTeamDef;
		}
		if(IsFirestormTraitActive())
		{
			Trait = GetFirestormTrait();
			iAimBuff += Trait.iBonusTeamAim;
			iDefBuff += Trait.iBonusTeamDef;
		}
		iOthersAimBuff = class'SU_Utils'.static.GetRankTeamAimBonus(kOtherPilot.GetRank(), kOtherPilot.GetCareerType());
		iOthersDefBuff = class'SU_Utils'.static.GetRankTeamDefBonus(kOtherPilot.GetRank(), kOtherPilot.GetCareerType());
		if(kOtherPilot.IsTraitActive())
		{
			Trait = kOtherPilot.GetCareerTrait();
			iOthersAimBuff += Trait.iBonusTeamAim;
			iOthersDefBuff += Trait.iBonusTeamDef;
		}
		if(kOtherPilot.IsFirestormTraitActive())
		{
			Trait = kOtherPilot.GetFirestormTrait();
			iOthersAimBuff += Trait.iBonusTeamAim;
			iOthersDefBuff += Trait.iBonusTeamDef;
		}
		bBetter = iDefBuff > iOthersDefBuff || iAimBuff > iOthersAimBuff;
	}
	return bBetter;
}
function SetCareerPath(int iNewCareerPath, optional bool bForceNewCareer)
{
	local int iLvl;

	`Log(GetFuncName() @ iNewCareerPath @ bForceNewCareer @ GetCallsign());
	if(m_bCareerChoicePending || bForceNewCareer)
	{
		m_iCareerPath = iNewCareerPath;
	}
	m_bCareerChoicePending = m_iCareerPath == -1 && class'SU_Utils'.static.GetRankMgr().m_arrCareers.Length > 1;
	m_kTCareerPath = class'SU_Utils'.static.GetRankMgr().GetCareerPathByType(m_iCareerPath);
	if(class'SU_Utils'.static.GetGameCore().IsOptionEnabled(9))
	{
		for(iLvl=0; iLvl < m_kTCareerPath.arrTRanks.Length; ++iLvl)
		{
			m_kTCareerPath.arrTRanks[iLvl].iKills *= class'XGTacticalGameCore'.default.SW_MARATHON;
			m_kTCareerPath.arrTRanks[iLvl].iReqXP *= class'XGTacticalGameCore'.default.SW_MARATHON;
		}
	}
	UpdateTraits();
}
/** Ensures that ship.m_iConfirmedKills is always set to pilot.m_iKills*/
function UpdateShipConfirmedKills(optional int iOverrideKills = -1)
{
	if(m_kGameActor != none)
	{
		GetShip().m_iConfirmedKills = iOverrideKills >= 0 ? iOverrideKills : m_iKills;
	}
}
function SetShip(XGShip_Interceptor kShip)
{
	if(GetShip() == kShip)
	{
		return;
	}
	else if(GetShip() != none)
	{
		UpdateShipConfirmedKills(0);
		GetShip().m_strCallsign = class'SquadronUnleashed'.default.m_strNoPilotAssigned;
	}
	AssignGameActor(kShip);
	UpdateShipConfirmedKills();
	if(GetShip() != none)
	{
		GetShip().m_strCallsign = GetCallsignWithRank();
	}
}
function XGShip_Interceptor GetShip()
{
	return XGShip_Interceptor(m_kGameActor);
}
function int GetStatus()
{
	return m_iStatus;
}
function int GetContinent()
{
	return m_iContinent;
}
function int GetXP()
{
	return m_iXP;
}
function int GetKills()
{
	return m_iKills;
}
function int GetTeamKills()
{
	return int(m_fTeamKills);
}
function TPilotCareerPath GetCareerPath()
{
	return m_kTCareerPath;
}
function int GetCareerType()
{
	return m_iCareerPath;
}
function int GetRank()
{
	return m_iPilotRank;
}
function string GetCallsign()
{
	return m_strCallSign;
}
function string GetCallsignWithRank(optional bool bUpdateRankFirst, optional bool bSkipCareerName)
{
	local string strRank, strType;

	if(bUpdateRankFirst)
	{
		UpdateRank();
	}
	bSkipCareerName = bSkipCareerName || class'SU_Utils'.static.GetRankMgr().m_arrCareers.Length < 2;
	strRank = class'SU_Utils'.static.GetRankMgr().GetShortRankName(m_iPilotRank);
	strType = class'SU_Utils'.static.GetRankMgr().GetCareerPathName(m_iCareerPath);
	return strRank $ (bSkipCareerName ? "" : " ("$CAPS(strType)$")") @ GetCallsign();
}
/** Returns raw aim bonus from rank and kills (ignores traits or stance).*/
function int CalcTotalAimBonus(optional int iRank=-1)
{
	return class'SU_Utils'.static.GetRankAimBonus(iRank != -1 ? iRank : GetRank(), GetCareerType()) + class'SquadronUnleashed'.default.AIM_BONUS_PER_KILL * (iRank != -1 ? class'SU_Utils'.static.GetKillsForRank(iRank, GetCareerType()) : GetKills());
}
/** Returns raw dmg modifier (0.0-1.0) from rank and kills (ignores traits or stance)*/
function float CalcTotalDamageModifier(optional int iRank=-1)
{
	return class'SU_Utils'.static.GetRankDmgBonus(iRank != -1 ? iRank : GetRank(), GetCareerType()) + class'SquadronUnleashed'.default.EXTRA_DMG_PCT_PER_KILL * (iRank != -1 ? Max(GetKills(), class'SU_Utils'.static.GetKillsForRank(iRank, GetCareerType())) : GetKills());
}
function string StatsToString(optional int iRank=-1)
{
	local string strStats;
	local int iMod;

	iMod = CalcTotalAimBonus(iRank);
	strStats $= class'SU_UIPilotRoster'.default.m_strAim @ "+" $ iMod $ (iMod < 10 ? " " : "");
	iMod = class'SU_Utils'.static.GetRankDefBonus(iRank != -1 ? iRank : GetRank(), GetCareerType());
	strStats @= " " $class'SU_UIPilotRoster'.default.m_strDef @ "+" $ iMod $ (iMod < 10 ? " " : "");
	iMod = CalcTotalDamageModifier(iRank) * 100 - 100;
	strStats @= " " $class'SU_UIPilotRoster'.default.m_strDamage @ (iMod >= 0 ? "+" : "") $ iMod $ "%";
	
	return strStats;
}
/** Returns the list of team buffs from a rank (ignores traits).*/
function string TeamBuffsToString(optional int iRank=-1)
{
	local string strBuffs;
	local int iMod;

	iMod = class'SU_Utils'.static.GetSquadronSizeAtRank(iRank != -1 ? iRank : GetRank(), GetCareerType());
	strBuffs $= class'SU_UIPilotRoster'.default.m_strSize @ iMod $" ";
	iMod = class'SU_Utils'.static.GetRankTeamAimBonus(iRank != -1 ? iRank : GetRank(), GetCareerType());
	strBuffs @= class'SU_UIPilotRoster'.default.m_strAim @ "+" $ iMod $ (iMod < 10 ? "  " : " ");
	iMod = class'SU_Utils'.static.GetRankTeamDefBonus(iRank != -1 ? iRank : GetRank(), GetCareerType());
	strBuffs @= " " $class'SU_UIPilotRoster'.default.m_strDef @ "+" $ iMod;
	
	return strBuffs;
}
/** Returns the list of buffs for specified trait (by default the career trait).*/
function string TraitBuffsToString(optional int iTrait=m_iCareerTrait)
{
	local XGParamTag kTag;
	local string strTraitBuffs;
	local SU_PilotRankMgr kRankMgr;
	local TPilotTrait Trait;

	kRankMgr = class'SU_Utils'.static.GetRankMgr();
	Trait = kRankMgr.GetTrait(iTrait);

	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
	//aim
	kTag.IntValue0 = Trait.iBonusAim;
	kTag.StrValue0 = kTag.IntValue0 > 0 ? "+"$kTag.IntValue0 : string(kTag.IntValue0);
	strTraitBuffs $= (kTag.IntValue0 != 0 ? "\n"$class'XComLocalizer'.static.ExpandString(kRankMgr.m_strTraitModAim) : "");
	//def
	kTag.IntValue0 = Trait.iBonusDef;
	kTag.StrValue0 = kTag.IntValue0 > 0 ? "+"$kTag.IntValue0 : string(kTag.IntValue0);
	strTraitBuffs $= (kTag.IntValue0 != 0 ? "\n"$class'XComLocalizer'.static.ExpandString(kRankMgr.m_strTraitModDef) : "");
	//team aim
	kTag.IntValue0 = Trait.iBonusTeamAim;
	kTag.StrValue0 = kTag.IntValue0 > 0 ? "+"$kTag.IntValue0 : string(kTag.IntValue0);
	strTraitBuffs $= (kTag.IntValue0 != 0 ? "\n"$class'XComLocalizer'.static.ExpandString(kRankMgr.m_strTraitModTeamAim) : "");
	//team def
	kTag.IntValue0 = Trait.iBonusTeamDef;
	kTag.StrValue0 = kTag.IntValue0 > 0 ? "+"$kTag.IntValue0 : string(kTag.IntValue0);
	strTraitBuffs $= (kTag.IntValue0 != 0 ? "\n"$class'XComLocalizer'.static.ExpandString(kRankMgr.m_strTraitModTeamDef) : "");
	//dodge
	kTag.IntValue0 = Trait.iBonusDodge;
	kTag.StrValue0 = kTag.IntValue0 > 0 ? "+"$kTag.IntValue0 : string(kTag.IntValue0);
	strTraitBuffs $= (kTag.IntValue0 != 0 ? "\n"$class'XComLocalizer'.static.ExpandString(kRankMgr.m_strTraitModDodge) : "");
	//dmgPct
	kTag.IntValue0 = Trait.iBonusDmgPct;
	kTag.StrValue0 = kTag.IntValue0 > 0 ? "+"$kTag.IntValue0 : string(kTag.IntValue0);
	strTraitBuffs $= (kTag.IntValue0 != 0 ? "\n"$class'XComLocalizer'.static.ExpandString(kRankMgr.m_strTraitModDmgPct) : "");
	//crit chance
	kTag.IntValue0 = Trait.iBonusCritChance;
	kTag.StrValue0 = kTag.IntValue0 > 0 ? "+"$kTag.IntValue0 : string(kTag.IntValue0);
	strTraitBuffs $= (kTag.IntValue0 != 0 ? "\n"$class'XComLocalizer'.static.ExpandString(kRankMgr.m_strTraitModCrit) : "");
	//crit dmgPct
	kTag.IntValue0 = Trait.iBonusCritDmgPct;
	kTag.StrValue0 = kTag.IntValue0 > 0 ? "+"$kTag.IntValue0 : string(kTag.IntValue0);
	strTraitBuffs $= (kTag.IntValue0 != 0 ? "\n"$class'XComLocalizer'.static.ExpandString(kRankMgr.m_strTraitModCritDmgPCt) : "");
	//time
	kTag.IntValue0 = Trait.iBonusTime;
	kTag.StrValue0 = kTag.IntValue0 > 0 ? "+"$kTag.IntValue0 : string(kTag.IntValue0);
	strTraitBuffs $= (kTag.IntValue0 != 0 ? "\n"$class'XComLocalizer'.static.ExpandString(kRankMgr.m_strTraitModTime) : "");

	if(strTraitBuffs != "")
	{
		strTraitBuffs = Right(strTraitBuffs, Len(strTraitBuffs)-1);
	}
	return strTraitBuffs;

}
/** Returns the list of trait restrictions/requirements for the specified trait (by default the career trait)*/
function string TraitReqsToString(optional int iTrait=m_iCareerTrait)
{
	local string strTraitReqs ;
	local SU_PilotRankMgr kRankMgr;
	local TPilotTraitReqs tRestrictions;

	kRankMgr = class'SU_Utils'.static.GetRankMgr();
	tRestrictions = kRankMgr.GetTraitRestrictions(iTrait);
	strTraitReqs $= tRestrictions.iSquadronSize > 0 ? "\n"$kRankMgr.m_strTraitReqSquadronSize @ tRestrictions.iSquadronSize : "";
	strTraitReqs $= tRestrictions.bCloseDistance ? "\n"$kRankMgr.m_strTraitReqClose : "";
	strTraitReqs $= tRestrictions.iTactic != -1 ? "\n"$class'SU_UIAirforceCommand'.default.m_strTacticsTabLabel $": <font color='#ffffff'>" $ class'SU_Utils'.static.StanceToString(none, tRestrictions.iTactic) $ "</font>" : "";
	strTraitReqs $= tRestrictions.bFireStorm ? "\n"$kRankMgr.m_strTraitReqFirestorm : "";
	if(strTraitReqs != "")
	{
		strTraitReqs = Right(strTraitReqs, Len(strTraitReqs)-1);
	}
	return strTraitReqs;
}
function string CareerProgressToString(optional bool bIncludeNextRankXP, optional bool bIncludeTeamKills)
{
	local string strProgress;
	
	strProgress = class'SU_UIPilotRoster'.default.m_strKills @ GetKills();
	if(bIncludeTeamKills)
	{
		strProgress @= "("$GetTeamKills()$")" $ (GetTeamKills() < 10 ? " " : "");
	}
	strProgress @= (GetKills() < 10 ? " " : "");
	if(!class'SU_Utils'.static.GetSquadronMod().m_bDisablePilotXP)
	{ 
		strProgress @= class'SU_UIPilotRoster'.default.m_strXP @ GetXP();
		if(bIncludeNextRankXP)
		{
			strProgress @="/";
			strProgress @= class'SU_Utils'.static.GetRankMgr().GetXPForRank(GetRank()+1, GetCareerType());
		}
	}
	return strProgress;
}
function string RankUpReqsToString(optional int iRank=GetRank()+1, optional bool bHighlightWhenFullfilled)
{
	local int iKillsReq, iXPReq;
	local string strKills, strXP;

	iKillsReq = class'SU_Utils'.static.GetKillsForRank(iRank, GetCareerType());
	iXPReq = class'SU_Utils'.static.GetXPForRank(iRank, GetCareerType());

	strKills = class'SU_UIPilotRoster'.default.m_strKills @" "@ iKillsReq @ (iKillsReq < 10 ? "  " : " ");
	if(bHighlightWhenFullfilled && (GetKills() >= iKillsReq || GetTeamKills() >= iKillsReq))
	{
		if(GetKills() < iKillsReq)//implies pass from TeamKills
		{
			strKills = Repl(strKills, iKillsReq, "("$iKillsReq$")");
		}
		strKills = class'UIUtilities'.static.GetHTMLColoredText(strKills, eUIState_Good);
	}
	if(iXPReq > 0)
	{
		strXP = class'SU_UIPilotRoster'.default.m_strXP @ iXPReq;
		if(bHighlightWhenFullfilled && GetXP() > iXPReq)
		{
			strXP = class'UIUtilities'.static.GetHTMLColoredText(strXP, eUIState_Good);
		}
	}
	return	strKills @ strXP;
}
function string GetStatusString(optional bool bShort)
{
	local string strStatus;

	if(GetStatus() < ePilotStatus_MAX)
	{
		strStatus = m_arrPilotStatus[GetStatus()];
		if(m_iHoursUnavailable > 0 && !bShort)
		{
			strStatus @= class'SU_Utils'.static.GetHoursOrDaysString(m_iHoursUnavailable);
		}
	}
	else
	{
		strStatus = "???";
	}
	if(GetShip() == none && !bShort)
	{
		strStatus $= "\n";
		strStatus $= class'UIUtilities'.static.GetHTMLColoredText(class'SquadronUnleashed'.default.m_strNoShipAssigned, eUIState_Bad);
	}
	if(bShort)
	{
		strStatus -=" -";
	}
	return strStatus;
}
function float GetSurvivalChancePct()
{
	if(IsAtMaxRank() && class'SquadronUnleashed'.default.PILOT_CMDR_NEVER_DIES)
	{
		return 1.0;
	}
	return float(class'SquadronUnleashed'.default.PILOT_SURVIVAL_CHANCE_FLAT + class'SquadronUnleashed'.default.PILOT_SURVIVAL_CHANCE_PER_RANK * GetRank() ) / 100.0;
}
function int GetServiceDurationInDays()
{
	return class'SU_Utils'.static.GetGameCore().GEOSCAPE().m_kDateTime.DifferenceInDays(m_kJoinServiceDate);
}
function int GetTotalDogfightSecondsRemainder()
{
	return int(m_fTotalDogfightTime) % 60;
}
function int GetTotalDogfightMinutes()
{
	return int(m_fTotalDogfightTime) / 60;
}
function int GetTotalDogfightHours()
{
	return int(m_fTotalDogfightTime) / 3600;
}
function string DogfightTimeToString()
{
	local string sHours, sMins, sSec;

	sHours = string(GetTotalDogfightHours());
	sMins = string(GetTotalDogfightMinutes() % 60);
	if(Len(sMins) < 2)
	{
		sMins = "0" $ sMins;
	}
	sSec = string(GetTotalDogfightSecondsRemainder());
	if(Len(sSec) < 2)
	{
		sSec = "0" $ sSec;
	}
	return sHours $ ":" $ sMins $ ":"  $ sSec;
}
function UIChangeCareer()
{
	class'SU_Utils'.static.GetSquadronMod().UIShowPilotCard(self, 1);
}
function InitVoice()
{
	local SoundCue TestCue;

	TestCue = SoundCue(DynamicLoadObject(VoiceSetPath $".Engage", class'SoundCue', true));
	if(VoiceSetPath != "" && VoiceSetPath != "Default" && TestCue == none)
	{
		XComContentManager(Class'Engine'.static.GetEngine().GetContentManager()).RequestObjectAsync(VoiceSetPath $".Engage", self, OnSoundLoaded);
	}
	else 
	{
		OnSoundLoaded(TestCue);
	}
}
function OnSoundLoaded(Object LoadedSound)
{
	if(VoiceSetPath != "")
	{
		m_tVoice.SFX_EnemySighted =     SoundCue(DynamicLoadObject(VoiceSetPath $".Engage", class'SoundCue', true));
		m_tVoice.SFX_ClosingOnTarget =  SoundCue(DynamicLoadObject(VoiceSetPath $".CloseRange", class'SoundCue', true));
		m_tVoice.SFX_Aborting =         SoundCue(DynamicLoadObject(VoiceSetPath $".Disengage", class'SoundCue', true));
		m_tVoice.SFX_JetBelow50HP=      SoundCue(DynamicLoadObject(VoiceSetPath $".PilotLowHP", class'SoundCue', true));
		m_tVoice.SFX_JetDown=           SoundCue(DynamicLoadObject(VoiceSetPath $".PilotDown", class'SoundCue', true));
		m_tVoice.SFX_UFODown=           SoundCue(DynamicLoadObject(VoiceSetPath $".UFODown", class'SoundCue', true));
		m_tVoice.SFX_UFOEscaped=        SoundCue(DynamicLoadObject(VoiceSetPath $".UFOEscaped", class'SoundCue', true));
	}
}
function SetNextPossibleVoice()
{
	local int iVoice;

	if(class'SU_Utils'.static.GetSquadronMod().PilotVoiceSet.Length > 0)
	{
		iVoice = class'SU_Utils'.static.GetSquadronMod().PilotVoiceSet.Find(VoiceSetPath);
		iVoice++;
		if(iVoice == class'SU_Utils'.static.GetSquadronMod().PilotVoiceSet.Length)
		{
			iVoice = 0;
		}
		VoiceSetPath = class'SU_Utils'.static.GetSquadronMod().PilotVoiceSet[iVoice];
		InitVoice();
	}
}
function SetPreviousPossibleVoice()
{
	local int iVoice;

	if(class'SU_Utils'.static.GetSquadronMod().PilotVoiceSet.Length > 0)
	{
		iVoice = class'SU_Utils'.static.GetSquadronMod().PilotVoiceSet.Find(VoiceSetPath);
		iVoice--;
		if(iVoice < 0)
		{
			iVoice = class'SU_Utils'.static.GetSquadronMod().PilotVoiceSet.Length - 1;
		}
		VoiceSetPath = class'SU_Utils'.static.GetSquadronMod().PilotVoiceSet[iVoice];
		InitVoice();
	}
}
function Speak(EPilotVoiceCue eCue)
{
	local SoundCue kCue;
	local bool bPriority;

	if(VoiceSetPath != "") //has custom voice
	{
		switch(eCue)
		{
		case 0:
			kCue = m_tVoice.SFX_EnemySighted;
			break;
		case 1:
			kCue = m_tVoice.SFX_ClosingOnTarget;
			break;
		case 2:
			kCue = m_tVoice.SFX_Aborting;
			bPriority=true;
			break;
		case 3:
			kCue = m_tVoice.SFX_JetBelow50HP;
			break;
		case 4:
			kCue = m_tVoice.SFX_JetDown;
			break;
		case 5:
			kCue = m_tVoice.SFX_UFODown;
			bPriority=true;
			break;
		case 6:
			kCue = m_tVoice.SFX_UFOEscaped;
			bPriority=true;
		}
	}
	if(kCue != none)
	{
		//kCue.VolumeMultiplier = Max(2.5, kCue.VolumeMultiplier);
		class'SU_Utils'.static.GetSquadronMod().m_kSoundMgr.QueueSound(kCue, bPriority);
	}
	else //has no custom voice
	{
		switch(eCue)
		{
		case 0:
			class'SU_Utils'.static.PRES().UINarrative(XComNarrativeMoment(DynamicLoadObject(class'XGNarrative'.default.NarrativeMoments[160], class'XComNarrativeMoment')));
			break;
		case 1:
			class'SU_Utils'.static.PRES().UINarrative(XComNarrativeMoment(DynamicLoadObject(class'XGNarrative'.default.NarrativeMoments[158], class'XComNarrativeMoment')));
			break;
		case 2:
			class'SU_Utils'.static.PRES().UINarrative(XComNarrativeMoment(DynamicLoadObject(class'XGNarrative'.default.NarrativeMoments[156], class'XComNarrativeMoment')));
			break;
		case 3:
			class'SU_Utils'.static.PRES().UINarrative(XComNarrativeMoment(DynamicLoadObject(class'XGNarrative'.default.NarrativeMoments[157], class'XComNarrativeMoment')));
			break;
		case 4:
			class'SU_Utils'.static.PRES().UINarrative(XComNarrativeMoment(DynamicLoadObject(class'XGNarrative'.default.NarrativeMoments[421], class'XComNarrativeMoment')));
			break;
		case 5:
			break;
		case 6:
			class'SU_Utils'.static.PRES().UINarrative(XComNarrativeMoment(DynamicLoadObject(class'XGNarrative'.default.NarrativeMoments[429], class'XComNarrativeMoment')));
		}
	}
}
function PlayRandomCue()
{
	Speak(EPilotVoiceCue(Rand(7)));
}

DefaultProperties
{
	m_iCareerPath=-1
	m_bCareerChoicePending=true
	bCollideActors=false
	VoiceSetPath="Default"
}