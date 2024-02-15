/** This class was created over time, trying to help different players fix sth in their on-going games.
 *  It does not serve as a permanent mod - rather a one shot tool.
 */
class XComSaveFixer extends XComMod
	config(SaveFixer);

struct TOTSPerkFix
{
	var string Name;
	var int iListIdx;
	var int iNewPerk;
};

var config int GIVE_MONEY;
var config bool DISABLE_NEWBIE_MOMENTS;
var config bool RESET_RANDOM_PERKS;
var config bool bPurgeExaltReminders;
var config array<TOTSPerkFix> OfficerPerkOverride;
var config bool bPurgeSoldierHirings;
var bool m_bMoneyAdded;
var bool m_bNarrativeFixed;
var bool m_bSoldiersFixed;
var bool m_bOfficersFixed;
var bool m_bExaltRemindersRemoved;
var bool m_bSoldierHiringsRemoved;

simulated function StartMatch()
{
    super.StartMatch();
    if(class'Engine'.static.GetCurrentWorldInfo().Game.IsA('XComHeadquartersGame'))
    {
        FixStrategy();
    }
    else if(class'Engine'.static.GetCurrentWorldInfo().Game.IsA('XComTacticalGame'))
    {
        FixTactical();
    }
	LogInternal("Hello world");
}
function FixStrategy()
{
	local XGNarrative kNarrative;
	local XGStrategySoldier kSoldier;

	if(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore() != none)
	{
		if(GIVE_MONEY > 0 && !m_bMoneyAdded)
		{
			XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().HQ().AddResource(eResource_Money, GIVE_MONEY);
			m_bMoneyAdded = true;
		}
		if(DISABLE_NEWBIE_MOMENTS && !m_bNarrativeFixed)
		{
			kNarrative = XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres.m_kNarrative;
			kNarrative.m_arrNarrativeCountersAtStartOfMap.Length=0;
			kNarrative.m_arrNarrativeMoments.Length=0;
			kNarrative.m_arrTipCounters.Length=0;
			kNarrative.PreBeginPlay();
			kNarrative.InitNarrative(DISABLE_NEWBIE_MOMENTS);
			m_bNarrativeFixed = true;
		}
		if(RESET_RANDOM_PERKS && !m_bSoldiersFixed)
		{
			foreach XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().GetBarracks().m_arrSoldiers(kSoldier)
			{
				if(kSoldier.GetRank() > 0)
				{
					LogInternal("Assigning new random perk tree for" @ kSoldier.GetName(eNameType_Full), name);
					kSoldier.ClearPerks();
				}
			}
			m_bSoldiersFixed = true;
		}
		if(!m_bOfficersFixed)
		{
			XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().SetTimer(3.0, false, 'FixOfficers',self);
			m_bOfficersFixed = true;
		}
		if(bPurgeExaltReminders && !m_bExaltRemindersRemoved)
		{
			RemoveExaltReminders();
			m_bExaltRemindersRemoved = true;
		}
		if(bPurgeSoldierHirings && !m_bSoldierHiringsRemoved)
		{
			ClearSoldierHirings();
			m_bSoldierHiringsRemoved = true;
		}
	}
	else
	{
		class'Engine'.static.GetCurrentWorldInfo().SetTimer(1.0, false, GetFuncName(), self);
	}
}
function FixOfficers()
{
	local XGStrategySoldier kSoldier;
	local bool bFound;
	local TOTSPerkFix kTOfficer;
	local int iPerk, iCount;

	foreach OfficerPerkOverride(kTOfficer)
	{
		bFound = false;
		foreach XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().GetBarracks().m_arrSoldiers(kSoldier, iCount)
		{
			if(Caps(kSoldier.GetName(3)) == Caps(kTOfficer.Name) || iCount == (kTOfficer.iListIdx - 1 ))
			{
				bFound = true;
				iPerk = kTOfficer.iNewPerk;
				break;
			}
		}
		if(bFound)
		{
			if(!class'XGTacticalGameCoreNativeBase'.static.IsMedalPerk(ePerkType(iPerk)))
			{
				LogInternal("Perk" @ iPerk @ "is not OTS perk", Class.Name);
				continue;
			}
			LogInternal("GiveOTSPerk" @ iPerk @ "to" @ kSoldier.GetName(3), class.Name);
			kSoldier.m_kChar.aUpgrades[iPerk] = kSoldier.m_kChar.aUpgrades[iPerk] | 2;
			iPerk = GetOppositeOTSPerk(iPerk);
			kSoldier.m_kChar.aUpgrades[iPerk] = kSoldier.m_kChar.aUpgrades[iPerk] & 1;
		}
		else
		{
			LogInternal("Soldier" @ kTOfficer.Name @ "not found", Class.Name);
		}
	}
}
function int GetOppositeOTSPerk(int iTestPerk)
{
	switch(iTestPerk)
	{
	case 122: 
		return 156;
	case 156: 
		return 122;
	case 140: 
		return 152;
	case 152: 
		return 140;
	case 1:
		return 161;
	case 161:
		return 1;
	case 157:
		return 160;
	case 160:
		return 157;
	case 138:
		return 158;
	case 158:
		return 138;
	}
}
function RemoveExaltReminders()
{
	local XGHeadQuarters kHQ;
	local int i;

	LogInternal("Attempting" @ GetFuncName(), name);
	kHQ = XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().HQ();
	i = kHQ.m_arrHiringOrders.Length - 1;
	while(i >= 0)
	{
		if(kHQ.m_arrHiringOrders[i].iNumStaff == 0 && kHQ.m_arrHiringOrders[i].iStaffType != 1)
		{
			LogInternal("Found buggy exalt-reminder order, ETA within" @ kHQ.m_arrHiringOrders[i].iHours @ "hours. Removing...", name);
			kHQ.m_arrHiringOrders.Remove(i, 1);
		}
		--i;
	}
}
function ClearSoldierHirings()
{
	local XGHeadQuarters kHQ;
	local int i;

	LogInternal("Attempting" @ GetFuncName(), name);
	kHQ = XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().HQ();
	i = kHQ.m_arrHiringOrders.Length - 1;
	LogInternal("Found" @ i+1 @ "pending orders for staff.", name);
	while(i >= 0)
	{
		LogInternal("Found pending order for staff type" @ kHQ.m_arrHiringOrders[i].iStaffType, name);
		if(kHQ.m_arrHiringOrders[i].iNumStaff > 0)
		{
			LogInternal("The order is for" @ kHQ.m_arrHiringOrders[i].iNumStaff@ "recruits. Removing...", name);
			kHQ.m_arrHiringOrders.Remove(i, 1);
		}
		--i;
	}
}
function FixTactical()
{

}