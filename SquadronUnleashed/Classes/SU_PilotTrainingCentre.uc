class SU_PilotTrainingCentre extends XGFacility
	config(SquadronUnleashed);

struct TTrainingLvl
{
	var int iCostPerMonth;
	var int iCostToUnlock;
	var int iImpactFactor1;
	var int iImpactFactor2;		
};
struct TPilotTrainee
{
	var SU_Pilot kPilot;
	var int iRemainingHours;
	var int iBonusXP;
};
struct CheckpointRecord_SU_PilotTrainingCentre extends CheckpointRecord
{
	var array<TPilotTrainee> m_arrTrainedPilots;
	var int m_iStaffLevel;
	var int m_iFacilitiesLvl;
	var int m_iTrainingProgramsLvl;
	var int m_iPendingStaffLevel;
	var int m_iPendingFacilitiesLvl;
	var int m_iPendingProgramsLvl;
	var int m_iTotalTrainingInvestment;
	var int m_iTotalStaffInvestment;
	var int m_iTotalFacilitieslInvestment;
};
var config array<TTrainingLvl> m_arrTrainingProgramsLvl;
var config array<TTrainingLvl> m_arrTrainingStaffLvl;
var config array<TTrainingLvl> m_arrTrainingFacilitiesLvl;
var array<TPilotTrainee> m_arrTrainedPilots;
var int m_iStaffLevel;
var int m_iFacilitiesLvl;
var int m_iTrainingProgramsLvl;
var int m_iPendingStaffLevel;
var int m_iPendingFacilitiesLvl;
var int m_iPendingProgramsLvl;
var int m_iTotalTrainingInvestment;
var int m_iTotalStaffInvestment;
var int m_iTotalFacilitieslInvestment;
var localized string m_strLabelTrainingFinished;

function Init(bool bLoadingFromSave)
{
	HQ().m_arrBaseFacilities[eFacility_Hangar] = 1;//this will auto-charge hangar costs at end-of-month
	UpdateHangarMaintenanceCost();
}
function UpdateHangarMaintenanceCost()
{
	ITEMTREE().BuildFacilities();
	ITEMTREE().m_arrFacilities[eFacility_Hangar].iMaintenance += GetTotalMonthlyCost();
}
function int GetStaffImpact(optional int iFactor=1, optional int iLvl=m_iStaffLevel)
{
	return (iFactor == 1 ? m_arrTrainingStaffLvl[iLvl].iImpactFactor1 : m_arrTrainingStaffLvl[iLvl].iImpactFactor2);
}
function int GetFacilitiesImpact(optional int iFactor=1, optional int iLvl=m_iFacilitiesLvl)
{
	return (iFactor == 1 ? m_arrTrainingFacilitiesLvl[iLvl].iImpactFactor1 : m_arrTrainingFacilitiesLvl[iLvl].iImpactFactor2);
}
function int GetTrainingProgramsImpact(int iFactor, optional int iLvl=m_iTrainingProgramsLvl)
{
	return (iFactor == 1 ? m_arrTrainingProgramsLvl[iLvl].iImpactFactor1 : m_arrTrainingProgramsLvl[iLvl].iImpactFactor2);
}
/** Returns monthly cost for specified level (default to NEXT month's pending level)*/
function int GetStaffCost(optional int iLvl=m_iPendingStaffLevel)
{
	return m_arrTrainingStaffLvl[iLvl].iCostPerMonth;
}
/** Returns monthly cost for specified level (default to NEXT month's pending level)*/
function int GetFacilitiesCost(optional int iLvl=m_iPendingFacilitiesLvl)
{
	return m_arrTrainingFacilitiesLvl[iLvl].iCostPerMonth;
}
/** Returns monthly cost for specified level (default to NEXT month's pending level)*/
function int GetTrainingProgramsCost(optional int iLvl=m_iPendingProgramsLvl)
{
	return m_arrTrainingProgramsLvl[iLvl].iCostPerMonth;
}
/** Returns total monthly cost for specified levels (default to NEXT month's pending levels)*/
function int GetTotalMonthlyCost(optional int iProgramsLvl=m_iPendingProgramsLvl, optional int iFacilitiesLvl=m_iPendingFacilitiesLvl, optional int iStaffLvl=m_iPendingStaffLevel)
{
	return GetStaffCost(iStaffLvl) + GetFacilitiesCost(iFacilitiesLvl) + GetTrainingProgramsCost(iProgramsLvl);
}
function int GetTrainingProgramsUnlockCost(int iLvlToUnlock)
{
	return m_arrTrainingProgramsLvl[iLvlToUnlock].iCostToUnlock;
}
function int GetFacilitiesUnlockCost(int iLvlToUnlock)
{
	return m_arrTrainingFacilitiesLvl[iLvlToUnlock].iCostToUnlock;
}
function int GetStaffUnlockCost(int iLvlToUnlock)
{
	return m_arrTrainingStaffLvl[iLvlToUnlock].iCostToUnlock;
}
/** Returns training cycle's XP bonus for specified lvl (by default current month's level).*/
function int GetTrainingCycleXPBonus(optional int iLvl=m_iTrainingProgramsLvl)
{
	return GetTrainingProgramsImpact(1, iLvl);
}
/** Returns training cycle's duration for specified lvl (by default current month's level).*/
function int GetTrainingCycleDurationDays(optional int iLvl=m_iTrainingProgramsLvl)
{
	return GetTrainingProgramsImpact(2, iLvl);
}
/** Returns max XP to be achieved through training for specified lvl (by default current month's level).*/
function int GetXPLimit(optional int iLvl=m_iStaffLevel)
{
	return GetStaffImpact(1, iLvl);
}
/** Returns training center's capacity for specified lvl (by default current month's level).*/
function int GetCapacity(optional int iLvl=m_iFacilitiesLvl)
{
	return GetFacilitiesImpact(1, iLvl);
}
/** Returns the maximum level that can be set considering unlock conditions.*/
function int GetMaxTrainingProgramsLvl()
{
	local int iLvl, iMaxLvl;

	for(iLvl=0; iLvl < m_arrTrainingProgramsLvl.Length; ++iLvl)
	{
		if(m_arrTrainingProgramsLvl[iLvl].iCostToUnlock >=0 && m_iTotalTrainingInvestment < m_arrTrainingProgramsLvl[iLvl].iCostToUnlock)
		{
			break;
		}
		else if((m_arrTrainingProgramsLvl[iLvl].iCostToUnlock >=0 && m_iTotalTrainingInvestment >= m_arrTrainingProgramsLvl[iLvl].iCostToUnlock) )
		{
			iMaxLvl = iLvl;
		}
	}
	class'UIUtilities'.static.ClampIndexToArrayRange(m_arrTrainingProgramsLvl.Length, iMaxLvl);
	return iMaxLvl;
}
/** Returns the minimum level guaranteed by total investment so far.*/
function int GetMinTrainingProgramsLvl()
{
	local int iLvl, iMinLvl;

	iMinLvl=0;
	for(iLvl=0; iLvl < m_arrTrainingProgramsLvl.Length; ++iLvl)
	{
		if(m_arrTrainingProgramsLvl[iLvl].iCostToUnlock <= m_arrTrainingProgramsLvl[iMinLvl].iCostToUnlock)
		{
			continue;
		}
		else if(m_arrTrainingProgramsLvl[iLvl].iCostToUnlock > 0 && m_iTotalTrainingInvestment >= m_arrTrainingProgramsLvl[iLvl].iCostToUnlock)
		{
			iMinLvl = iLvl;
		}
	}
	class'UIUtilities'.static.ClampIndexToArrayRange(m_arrTrainingProgramsLvl.Length, iMinLvl);
	return iMinLvl;
}
/** Returns the maximum level that can be set considering unlock conditions.*/
function int GetMaxStaffLvl()
{
	local int iLvl, iMaxLvl;

	for(iLvl=0; iLvl < m_arrTrainingStaffLvl.Length; ++iLvl)
	{
		if(m_arrTrainingStaffLvl[iLvl].iCostToUnlock >=0 && m_iTotalStaffInvestment < m_arrTrainingStaffLvl[iLvl].iCostToUnlock)
		{
			break;
		}
		else if((m_arrTrainingStaffLvl[iLvl].iCostToUnlock >=0 && m_iTotalStaffInvestment >= m_arrTrainingStaffLvl[iLvl].iCostToUnlock) )
		{
			iMaxLvl = iLvl;
		}
	}
	class'UIUtilities'.static.ClampIndexToArrayRange(m_arrTrainingStaffLvl.Length, iMaxLvl);
	return iMaxLvl;
}
/** Returns the minimum level guaranteed by total investment so far.*/
function int GetMinStaffLvl()
{
	local int iLvl, iMinLvl;

	iMinLvl=0;
	for(iLvl=0; iLvl < m_arrTrainingStaffLvl.Length; ++iLvl)
	{
		if(m_arrTrainingStaffLvl[iLvl].iCostToUnlock <= m_arrTrainingStaffLvl[iMinLvl].iCostToUnlock)
		{
			continue;
		}
		else if(m_arrTrainingStaffLvl[iLvl].iCostToUnlock > 0 && m_iTotalStaffInvestment >= m_arrTrainingStaffLvl[iLvl].iCostToUnlock)
		{
			iMinLvl = iLvl;
		}
	}
	class'UIUtilities'.static.ClampIndexToArrayRange(m_arrTrainingStaffLvl.Length, iMinLvl);
	return iMinLvl;
}
/** Returns the maximum level that can be set considering unlock conditions.*/
function int GetMaxFacilitiesLvl()
{
	local int iLvl, iMaxLvl;

	for(iLvl=0; iLvl < m_arrTrainingFacilitiesLvl.Length; ++iLvl)
	{
		if(m_arrTrainingFacilitiesLvl[iLvl].iCostToUnlock >=0 && m_iTotalFacilitieslInvestment < m_arrTrainingFacilitiesLvl[iLvl].iCostToUnlock)
		{
			break;
		}
		else if((m_arrTrainingFacilitiesLvl[iLvl].iCostToUnlock >=0 && m_iTotalFacilitieslInvestment >= m_arrTrainingFacilitiesLvl[iLvl].iCostToUnlock) )
		{
			iMaxLvl = iLvl;
		}
	}
	class'UIUtilities'.static.ClampIndexToArrayRange(m_arrTrainingFacilitiesLvl.Length, iMaxLvl);
	return iMaxLvl;
}
/** Returns the minimum level guaranteed by total investment so far.*/
function int GetMinFacilitiesLvl()
{
	local int iLvl, iMinLvl;

	iMinLvl=0;
	for(iLvl=0; iLvl < m_arrTrainingFacilitiesLvl.Length; ++iLvl)
	{
		if(m_arrTrainingFacilitiesLvl[iLvl].iCostToUnlock <= m_arrTrainingFacilitiesLvl[iMinLvl].iCostToUnlock)
		{
			continue;
		}
		else if(m_arrTrainingFacilitiesLvl[iLvl].iCostToUnlock > 0 && m_iTotalFacilitieslInvestment >= m_arrTrainingFacilitiesLvl[iLvl].iCostToUnlock)
		{
			iMinLvl = iLvl;
		}
	}
	class'UIUtilities'.static.ClampIndexToArrayRange(m_arrTrainingFacilitiesLvl.Length, iMinLvl);
	return iMinLvl;
}
function SetTrainingProgramsLvl(int iNewLvl)
{
	m_iTrainingProgramsLvl = Clamp(iNewLvl, GetMinTrainingProgramsLvl(), GetMaxTrainingProgramsLvl());
}
function SetStaffLvl(int iNewLvl)
{
	m_iStaffLevel = Clamp(iNewLvl, GetMinStaffLvl(), GetMaxStaffLvl());
}
function SetFacilitiesLvl(int iNewLvl)
{
	m_iFacilitiesLvl = Clamp(iNewLvl, GetMinFacilitiesLvl(), GetMaxFacilitiesLvl());
}
function ApplyPendingLevels()
{
	SetTrainingProgramsLvl(m_iPendingProgramsLvl);
	SetFacilitiesLvl(m_iPendingFacilitiesLvl);
	SetStaffLvl(m_iPendingStaffLevel);
}
function Update()
{
	local int i, iPilotStatus;
	local TMCNotice kNotice;
	local XGParamTag kTag;

	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));

	for(i = m_arrTrainedPilots.Length-1; i >=0; --i)
	{
		if(class'SU_Utils'.static.GetSquadronMod().m_bDisablePilotXP)
		{
			m_arrTrainedPilots.Remove(i, 1);
		}
		else
		{
			iPilotStatus = m_arrTrainedPilots[i].kPilot.GetStatus();
			if(iPilotStatus == ePilotStatus_Ready)
			{
				m_arrTrainedPilots[i].iRemainingHours = Max(--m_arrTrainedPilots[i].iRemainingHours, 0);
			}
			if(m_arrTrainedPilots[i].iRemainingHours == 0 && !GEOSCAPE().IsBusy())
			{
				m_arrTrainedPilots[i].kPilot.m_iXP += m_arrTrainedPilots[i].iBonusXP;
				//pres notify
				kNotice.fTimer = 6.0;
				kNotice.txtNotice.iState = eUIState_Highlight;
				kTag.StrValue0 = m_arrTrainedPilots[i].kPilot.GetCallsignWithRank(true, true);
				kTag.IntValue0 = m_arrTrainedPilots[i].iBonusXP;
				kNotice.txtNotice.StrValue = class'UIUtilities'.static.GetHTMLColoredText(class'XComLocalizer'.static.ExpandString(m_strLabelTrainingFinished), eUIState_Highlight);
				m_arrTrainedPilots.Remove(i, 1);
				if(PRES().m_kUIMissionControl != none)
				{
					PRES().m_kUIMissionControl.GetMgr().m_arrNotices.AddItem(kNotice);
					PRES().m_kUIMissionControl.UpdateNotices();
					GEOSCAPE().Pause();
				}
			}
		}
	}
}
function int FindTrainee(SU_Pilot kSearchedPilot, optional out TPilotTrainee tFoundTrainee)
{
	local int i, iFound;

	iFound = -1;
	for(i=0; i <  m_arrTrainedPilots.Length; ++i)
	{
		if(m_arrTrainedPilots[i].kPilot == kSearchedPilot)
		{
			tFoundTrainee = m_arrTrainedPilots[i];
			iFound = i;
			break;
		}
	}
	return iFound;
}
function AddTrainee(SU_Pilot kPilot)
{
	local TPilotTrainee tTrainee;
	local int iFound;

	//if(kPilot.GetShip() != none)
	//{
	//	kPilot.SetShip(none);
	//}
	iFound = FindTrainee(kPilot, tTrainee);
	tTrainee.kPilot = kPilot;
	tTrainee.iBonusXP =  Min(GetTrainingCycleXPBonus(), Max(0, GetXPLimit() - kPilot.m_iXP));
	tTrainee.iRemainingHours = 24 * GetTrainingCycleDurationDays();
	if(iFound != -1)
	{
		m_arrTrainedPilots[iFound] = tTrainee;
	}
	else
	{
		m_arrTrainedPilots.AddItem(tTrainee);
	}
}
function RemoveTrainee(SU_Pilot kPilot)
{
	local int iFound;

	iFound = FindTrainee(kPilot);
	if(iFound != -1)
	{
		m_arrTrainedPilots.Remove(iFound, 1);
	}
}
function OnEndOfMonth()
{
	ApplyPendingLevels();
}
function TTableMenu GetUITable()
{
	local TTableMenu kMenu;
	local TTableMenuOption tOption;
	local TPilotTrainee kTrainee;
	local int i;

	for(i=0; i < m_arrTrainedPilots.Length; ++i)
	{
		kTrainee = m_arrTrainedPilots[i];
		tOption.arrStrings[0] = kTrainee.kPilot.GetCallsignWithRank();
		tOption.arrStates[0] = 0;
		tOption.arrStrings[1] = class'SU_Utils'.static.TimeToString(kTrainee.iRemainingHours + kTrainee.kPilot.m_iHoursUnavailable); 
		tOption.arrStrings[1] @= "[ +" $ kTrainee.iBonusXP @ class'XGSoldierUI'.default.m_strLabelStrength $"]";
		tOption.arrStates[1] = 0;
		if(kTrainee.kPilot.GetStatus() != ePilotStatus_Ready)
		{
			tOption.arrStrings[0] @= class'UIUtilities'.static.GetHTMLColoredText("("$kTrainee.kPilot.GetStatusString(true)$")", eUIState_Bad);
			tOption.arrStrings[1] = class'UIUtilities'.static.GetHTMLColoredText(tOption.arrStrings[1], eUIState_Bad);
		}
		else
		{
			tOption.arrStrings[1] = class'UIUtilities'.static.GetHTMLColoredText(tOption.arrStrings[1], eUIState_Normal);
		}
		tOption.arrStrings[2] = class'SU_UIPilotTraining'.default.m_strRemovePilot;
		kMenu.arrOptions.AddItem(tOption);
	}
	return kMenu;
}
function bool PilotCanBenefitFromTraining(SU_Pilot kTestPilot)
{
	return kTestPilot.m_iXP < GetXPLimit();
}
function bool PilotCanSignUpForTraining(SU_Pilot kTestPilot)
{
	local bool bStatusOK;

	switch(kTestPilot.GetStatus())
	{
	case ePilotStatus_Incoming:
	case ePilotStatus_Wounded:
	case ePilotStatus_Dead:
		bStatusOK = false;
		break;
	default:
		bStatusOK = class'SU_Utils'.static.GetSquadronMod().m_kPilotTrainingCenter.m_arrTrainedPilots.Find('kPilot', kTestPilot) < 0;
	}
	return bStatusOK && PilotCanBenefitFromTraining(kTestPilot);
}
DefaultProperties
{
}
