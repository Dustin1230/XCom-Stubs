class SU_PilotQuarters extends XGFacility
	config(SquadronUnleashed);
//extending XGFacility subscribes this class to ActorClassesToRecord

struct TContinentInfoWithPilots extends XGFacility_Hangar.TContinentInfo
{
	var array<SU_Pilot> arrPilots;
};
struct TPilotTactic
{
	var bool bStartClose;
	var float fAutoBackOffHP;
	var float fAutoAbortHP;
};
struct CheckpointRecord_SU_PilotQuarters extends CheckpointRecord
{
	var array<SU_Pilot> m_arrPilots;
	var array<TPilotTactic> m_arrTactics;
};

var array<SU_Pilot> m_arrPilots;
var array<TPilotTactic> m_arrTactics;
var bool m_bInitialized;

function Init(bool bLoadingFromSave)
{
	local SU_Pilot kPilot;

	if(m_bInitialized)
	{
		return;
	}
	`Log(bLoadingFromSave @ self, class'SquadronUnleashed'.default.bVerboseLog, GetFuncName());
	class'SU_Utils'.static.GetSquadronMod().m_kRankMgr.BuildCareerPaths();
	if(!bLoadingFromSave)
	{
		CreateInitialPilots();
	}
	else
	{
		foreach m_arrPilots(kPilot)
		{
			kPilot.PostLoadInit();
		}
		class'SU_Utils'.static.GetGameCore().HQ().m_arrFacilities.RemoveItem(self);
	}
	InitTactics();
	UpdateHangarCosts();
	m_bInitialized=true;
}
function UnInit()
{
	local SU_Pilot kPilot;

	foreach m_arrPilots(kPilot)
	{
		kPilot.UnInit();
		kPilot.Destroy();
	}
	m_arrPilots.Length = 0;
}
function SU_Pilot AddPilot(XGShip_Interceptor kShip, optional string strCallsign, optional int iContinent=HQ().GetContinent())
{
	local SU_Pilot kPilot;
	local string strShipName;

	`Log(GetFuncName() @ "ship="$kShip @ "callsign="$strCallsign @ "continent="$iContinent, class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed'); 
	kPilot = Spawn(class'SU_Pilot');
	if(kShip == none)
	{
		kPilot.Rename();
		kPilot.m_iContinent = iContinent;
		kPilot.m_iStatus = ePilotStatus_Incoming;
		kPilot.m_iHoursUnavailable = class'SquadronUnleashed'.default.PILOT_TRANSFER_HOURS;
	}
	else
	{
		kPilot.AssignGameActor(kShip);
		kPilot.m_iContinent = kShip.m_iHomeContinent;
		kPilot.m_iKills = kShip.m_iConfirmedKills;
		strShipName = kShip.m_strCallsign;
		if(InStr(strShipName, " \"") != -1)
		{
			strShipName = "\"" $ Split(strShipName, " \"", true);
		}
		kPilot.m_strCallSign = strShipName;
	}
	//kPilot.m_iCareerPath = Rand(2)+1;//FIXME - remove after test phase!!!.... or no? hm.... :)

	kPilot.Init(0);//validates callsign, sets careepath and updates rank
	m_arrPilots.AddItem(kPilot);
	UpdateHangarCosts();
	return kPilot;
}
function CreateInitialPilots()
{
	local array<XGShip_Interceptor> arrInts;
	local int i;
	local SU_Pilot kNewPilot;

	arrInts = HANGAR().m_arrInts;
	for(i=0; i < arrInts.Length; ++i)
	{
		kNewPilot = AddPilot(arrInts[i]);
		kNewPilot.FeedDataMidCampaign();
		kNewPilot.UpdateRank();
		if(Left(kNewPilot.m_strCallSign, Len(class'XGFacility_Hangar'.default.m_strCallsignInterceptor)) == class'XGFacility_Hangar'.default.m_strCallsignInterceptor || Left(kNewPilot.m_strCallSign, Len(class'XGFacility_Hangar'.default.m_strCallsignFireStorm)) == class'XGFacility_Hangar'.default.m_strCallsignFireStorm)
		{
			kNewPilot.Rename(,true);
		}
		else
		{
			kNewPilot.Rename(kNewPilot.m_strCallSign);
		}
		kNewPilot.m_bCareerChoicePending = class'SU_Utils'.static.GetRankMgr().m_arrCareers.Length > 1;
	}
	m_bRequiresAttention=true;
	class'SU_Utils'.static.HANGAR().m_bRequiresAttention = true;
	PRES().GetStrategyHUD().m_kMenu.UpdateData();
}
function InitTactics(optional bool bForceDefaultValues)
{
	if(m_arrTactics.Length > 0 && !bForceDefaultValues)
	{
		return;
	}
	m_arrTactics.Length = 3;
	m_arrTactics[0].bStartClose = class'SquadronUnleashed'.default.BAL_TACTIC_START_CLOSE;
	m_arrTactics[0].fAutoBackOffHP = class'SquadronUnleashed'.default.BAL_TACTIC_AUTOBACKOFF_HP_PCT;
	m_arrTactics[0].fAutoAbortHP = class'SquadronUnleashed'.default.BAL_TACTIC_AUTOABORT_HP_PCT;
	m_arrTactics[1].bStartClose = class'SquadronUnleashed'.default.AGG_TACTIC_START_CLOSE;
	m_arrTactics[1].fAutoBackOffHP = class'SquadronUnleashed'.default.AGG_TACTIC_AUTOBACKOFF_HP_PCT;
	m_arrTactics[1].fAutoAbortHP = class'SquadronUnleashed'.default.AGG_TACTIC_AUTOABORT_HP_PCT;
	m_arrTactics[2].bStartClose = class'SquadronUnleashed'.default.DEF_TACTIC_START_CLOSE;
	m_arrTactics[2].fAutoBackOffHP = class'SquadronUnleashed'.default.DEF_TACTIC_AUTOBACKOFF_HP_PCT;
	m_arrTactics[2].fAutoAbortHP = class'SquadronUnleashed'.default.DEF_TACTIC_AUTOABORT_HP_PCT;
}
function Enter(int iView)
{
	m_bRequiresAttention = false;
}
/** This function is called every in-game hour (based on Geoscape time)*/
function Update()
{
	UpdatePilots();
	class'SU_Utils'.static.GetSquadronMod().m_kPilotTrainingCenter.Update();
}
/** Update hours-to-full-availability on pilots.*/
function UpdatePilots()
{
	local int i;
	local bool bIsReady;

	for(i=0; i < m_arrPilots.Length; ++i)
	{
		bIsReady = m_arrPilots[i].m_iStatus == ePilotStatus_Ready;
		if(m_arrPilots[i].GetShip() != none && m_arrPilots[i].GetShip().IsFlying() || m_arrPilots[i].GetStatus() == ePilotStatus_Dead)
		{
			continue;
		}
		else if(--m_arrPilots[i].m_iHoursUnavailable <= 0)
		{
			m_arrPilots[i].m_iHoursUnavailable = 0;
			if(!bIsReady)
			{
				m_arrPilots[i].m_iStatus = ePilotStatus_Ready;
				if(PRES().m_kUIMissionControl != none && m_arrPilots[i].GetShip() != none)
				{
					PRES().Notify(eGA_ShipOnline, HANGAR().m_arrInts.Find(m_arrPilots[i].GetShip()));
					if(!HANGAR().AreShipsFlying() && !GEOSCAPE().IsBusy())
					{
						GEOSCAPE().Pause();
					}
				}
			}
		}
	}
}
function TContinentInfoWithPilots GetContinentInfo(EContinent eCont)
{
	local TContinentInfo kBaseInfo;
	local TContinentInfoWithPilots kInfo;
	local int i;

	kBaseInfo = HANGAR().GetContinentInfo(eCont);
	kInfo.eCont = kBaseInfo.eCont;
	kInfo.strContinentName = kBaseInfo.strContinentName;
	kInfo.arrCraft = kBaseInfo.arrCraft;
	kInfo.iNumShips = kBaseInfo.iNumShips;
	kInfo.m_arrInterceptorOrderIndexes = kBaseInfo.m_arrInterceptorOrderIndexes;
	for(i = 0; i < m_arrPilots.Length; ++i)
	{
		if(m_arrPilots[i].GetContinent() == eCont)
		{
			kInfo.arrPilots.AddItem(m_arrPilots[i]);
		}
	}
	return kInfo;
}
function TransferPilot(SU_Pilot kPilot, int iDestinationContinent)
{
	if(kPilot.GetShip() != none && kPilot.GetShip().m_iHomeContinent != iDestinationContinent)
	{
		kPilot.GetShip().m_strCallsign = class'SquadronUnleashed'.default.m_strNoPilotAssigned;
		kPilot.SetShip(none);
	}
	kPilot.m_iContinent = iDestinationContinent;
	kPilot.m_iStatus = ePilotStatus_InTransfer;
	kPilot.m_iHoursUnavailable = class'SquadronUnleashed'.default.PILOT_TRANSFER_HOURS;
}
function RemovePilot(SU_Pilot kPilot)
{
	if(kPilot.GetShip() != none)
	{
		kPilot.UpdateShipConfirmedKills();
		kPilot.GetShip().m_strCallsign = class'SquadronUnleashed'.default.m_strNoPilotAssigned;
	}
	m_arrPilots.RemoveItem(kPilot);
	kPilot.Destroy();
}
function TPilotTactic GetTactic(int i)
{
	return m_arrTactics[i];
}
function UpdateHangarCosts()
{
	local SquadronUnleashed kMod;

	kMod = class'SU_Utils'.static.GetSquadronMod();
	if(!kMod.m_bDisablePilotXP && kMod.m_kPilotTrainingCenter != none)
	{
		kMod.m_kPilotTrainingCenter.UpdateHangarMaintenanceCost();
	}
	else
	{
		ITEMTREE().BuildFacilities();
	}
	ITEMTREE().m_arrFacilities[eFacility_Hangar].iMaintenance += CalcMonthlyCosts();
}
function int CalcMonthlyCosts()
{
	return m_arrPilots.Length * class'SquadronUnleashed'.default.PILOT_COST_MONTHLY;
}
DefaultProperties
{
	m_nmRoomName=HANGAR
}
