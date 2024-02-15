class SU_WatchShipMgr extends XGStrategyActor;

var XGShip_Interceptor m_kShip;
var SU_Pilot m_kCurrentPilot;
var int m_iWatchWeaponsHandle;
var int m_iWatchStatusHandle;
var int m_iWatchCallsignHandle;
var int m_iWatchKillsHandle;
var bool m_bRearmPending;

function Init(XGShip_Interceptor kShip)
{
	`Log(self @ kship @ GetFuncName(),class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	if(kShip != none)
	{
		m_kShip = kShip;
		class'SU_Utils'.static.GetSquadronMod().UpdateShipLoadout(m_kShip);
		ValidateWeaponSlots();
		if(m_kShip.m_iStatus == 0)
		{
			class'SU_Utils'.static.RearmShip(kShip);
		}
		OnStatusChangedCallback();//this also calls StartWatchingStatus()
		StartWatchingWeapons();
		StartWatchingCallsign();
		UpdatePilot();
	}
	else
	{
		`Log("ERROR: Cannot init"@ self @ "without XGShip_Interceptor instance. Destroying" @ self,class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
		Destroy();
	}
}
function bool IsValid()
{
	if(m_kShip == none)
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchWeaponsHandle);
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchStatusHandle);
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchCallsignHandle);
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchKillsHandle);
		Destroy();
		return false;
	}
	return true;
}
/** Callback after arrWeapons changed to restore possibly erased/overwritten arrWeapons[1] entry*/
function OnWeaponsChangedCallback()
{
	`Log(self @ GetFuncName(), class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	StopWatchingWeapons();
	class'SU_Utils'.static.GetSquadronMod().UpdateShipLoadout(m_kShip);
	SetTimer(0.05, false, 'StartWatchingWeapons');
}
/** Checks if weapons meet slots' restrictions (primary/secondary) and apply fix if required.*/
function ValidateWeaponSlots()
{
	local array<TShipWeapon> arrShipWeapons;
	local bool bSecondaryValid, bSecondaryInfinite, bPrimaryValid, bPrimaryInfinite;
	local string strDebug;
	
	//IMPORTANT: m_kTShip.arrWeapons stores EShipWeapon, whereas m_eWeapon is EItemType

	strDebug = self @ m_kShip @ m_kShip.m_strCallsign @ GetFuncName();
	StopWatchingWeapons();
	m_kShip.m_kTShip.arrWeapons.Length = 2;
	arrShipWeapons = m_kShip.GetWeapons();
	if(arrShipWeapons.Length < 2)
	{
		//vulcan must have been skipped, so...
		arrShipWeapons.AddItem(SHIPWEAPON(0));
		strDebug $= ("\n"$Chr(9)$"Adding missing Vulcan cannon to arrShipWeapons (debug procedure).");
	}
	bPrimaryValid = class'SU_Utils'.static.WeaponFitsPrimarySlot(arrShipWeapons[0].eType);
	bSecondaryValid = class'SU_Utils'.static.WeaponFitsSecondarySlot(arrShipWeapons[1].eType);
	bPrimaryInfinite = STORAGE().IsInfinite(EItemType(class'SU_Utils'.static.ShipWeaponToItemType(m_kShip.m_kTShip.arrWeapons[0])));
	bSecondaryInfinite = m_kShip.m_kTShip.arrWeapons[1] == 0 || STORAGE().IsInfinite(EItemType(class'SU_Utils'.static.ShipWeaponToItemType(m_kShip.m_kTShip.arrWeapons[1])));
	if(!bPrimaryValid)
	{
		strDebug $= ("\n"$Chr(9)$"Primary weapon"@ m_kShip.m_kTShip.arrWeapons[0] @"does not fit primary slot.");
		//if secondary fits primary just swap weapons
		if(class'SU_Utils'.static.WeaponFitsPrimarySlot(arrShipWeapons[1].eType))
		{
			m_kShip.m_kTShip.arrWeapons[0] = arrShipWeapons[1].eType;
			m_kShip.m_kTShip.arrWeapons[1] = arrShipWeapons[0].eType;
			strDebug $= ("\n"$Chr(9)$"Swapped primary" @ arrShipWeapons[0].eType @ "with secondary" @ arrShipWeapons[1].eType);
		}//else if secondary is valid (but not Vulcan) and does not fit primary, replace primary with Avalanche
		else if(bSecondaryValid && arrShipWeapons[1].eType > 0)
		{
			strDebug $= ("\n"$Chr(9)$"Secondary" @ arrShipWeapons[1].eType @ "is valid and does not fit primary slot.");
			if(!bPrimaryInfinite)
			{
				strDebug $= ("\n"$Chr(9)$"Primary" @ arrShipWeapons[0].eType @"returned to storage.");
				STORAGE().AddItem(class'SU_Utils'.static.ShipWeaponToItemType(m_kShip.m_kTShip.arrWeapons[0]));
			}
			m_kShip.m_kTShip.arrWeapons[0] = eShipWeapon_Avalanche;
			strDebug $= ("\n"$Chr(9)$"Avalanche equipped as primary.");
		}//else (secondary is Vulcan) - replace vulcan with primary and primary with avalanche
		else
		{
			m_kShip.m_kTShip.arrWeapons[1] = m_kShip.m_kTShip.arrWeapons[0];
			m_kShip.m_kTShip.arrWeapons[0] = eShipWeapon_Avalanche;
			strDebug $= ("\n"$Chr(9)$"Secondary weapon is Vulcan Cannon("$arrShipWeapons[1].eType$"). Primary" @ arrShipWeapons[0].eType @ "moved to secondary slot.");
			strDebug $= ("\n"$Chr(9)$"Avalanche equipped as primary.");
		}
		m_kShip.m_eWeapon = EItemType(class'SU_Utils'.static.ShipWeaponToItemType(m_kShip.m_kTShip.arrWeapons[0]));
		strDebug $= ("\n"$Chr(9)$"Ship's m_eWeapon set to" @ m_kShip.GetWeapon());
	}//primary is valid but secondary is not - equip Vulcan Cannon
	else if(!bSecondaryValid)
	{
		strDebug $= ("\n"$Chr(9)$"Secondary" @ arrShipWeapons[1].eType @ "does not fit secondary slot.");
		if(!bSecondaryInfinite)
		{
			strDebug $= ("\n"$Chr(9)$"Secondary" @ arrShipWeapons[1].eType @ "returned to storage.");
			STORAGE().AddItem(class'SU_Utils'.static.ShipWeaponToItemType(m_kShip.m_kTShip.arrWeapons[1]));
		}
		strDebug $= ("\n"$Chr(9)$"Vulcan Cannon equipped as secondary weapon.");
		m_kShip.m_kTShip.arrWeapons[1] = 0;
	}
	class'SU_Utils'.static.SaveValue(m_kShip, "SecondaryWeapon", m_kShip.m_kTShip.arrWeapons[1]);
	SetTimer(0.05, false, 'StartWatchingWeapons');
	`Log(strDebug, class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
}
/** Callback after m_iStatus changed.*/
function OnStatusChangedCallback()
{
	local TMCNotice kNotice;
	local XGParamTag kTag;

	`Log(self @ GetFuncName() @ m_kShip @ string(EShipStatus(m_kShip.m_iStatus)),class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	StopWatchingStatus();
	if(m_kShip.m_iStatus == eShipStatus_Rearming)
	{
		m_bRearmPending = true;
	}
	else if(m_kShip.m_iStatus == eShipStatus_Refuelling)
	{
		m_kShip.m_iHoursDown = class'SU_Utils'.static.GetSquadronMod().m_iRefuellingHours;
	}
	else if(m_kShip.m_iStatus == eShipStatus_Repairing && m_kShip.GetHPPct() > class'SquadronUnleashed'.default.DAMAGED_JET_HP_PCT_CAN_FIGHT && m_kShip.GetFuelPct() < 1.0)
	{
		m_kShip.m_iStatus = eShipStatus_Refuelling;
		m_kShip.m_iHoursDown = class'SU_Utils'.static.GetSquadronMod().m_iRefuellingHours;
	}
	else if(m_kShip.m_iStatus == eShipStatus_Transfer)
	{
		UpdatePilot();
		if(m_kCurrentPilot != none)
		{
			class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.TransferPilot(m_kCurrentPilot, m_kShip.m_iHomeContinent);
		}
	}
	else if(m_bRearmPending)
	{
		class'SU_Utils'.static.RearmShip(m_kShip);
		UpdatePilot();
		kNotice.fTimer = 6.0;
		kNotice.txtNotice.iState = 4;
		kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
		kTag.StrValue0 = m_kCurrentPilot.GetCallsignWithRank();
		kTag.StrValue1 = class'SU_Utils'.static.GetShipWeaponName(m_kShip.m_kTShip.arrWeapons[1]);
		kNotice.txtNotice.StrValue = class'XComLocalizer'.static.ExpandString(class'XGMissionControlUI'.default.m_strLabelShipRearmed);
		if(PRES().m_kUIMissionControl != none)
		{
			PRES().m_kUIMissionControl.GetMgr().m_arrNotices.AddItem(kNotice);
			PRES().m_kUIMissionControl.UpdateNotices();
		}
	}
	SetTimer(0.05, false, 'StartWatchingStatus');
	`Log("Current ship status" @ string(EShipStatus(m_kShip.m_iStatus)),class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
}
/** Callback after m_strCallsign changed*/
function OnCallsignChangedCallback()
{
	`Log(self @ (m_kShip != none ? string(m_kShip) : "no ship") @ GetFuncName(), class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	StopWatchingCallsign();
	UpdatePilot();
	if(m_kCurrentPilot != none)
	{
		m_kShip.m_strCallsign = m_kCurrentPilot.GetCallsignWithRank();
	}
	else
	{
		m_kShip.m_strCallsign = class'SquadronUnleashed'.default.m_strNoPilotAssigned;
	}
	SetTimer(0.05, false, 'StartWatchingCallsign');
}
/** Ensures that kills of the ship are always set to pilot's kills.*/
function OnKillsChangedCallback()
{
	`Log(self @ m_kShip @ GetFuncName(), class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	PauseWatchingKills();
	UpdatePilot();
	if(m_kCurrentPilot != none)
	{
		m_kCurrentPilot.UpdateShipConfirmedKills();
	}
	else
	{
		m_kShip.m_iConfirmedKills = 0;
	}
	SetTimer(0.05, false, 'ContinueWatchingKills');
}
function UpdatePilot(optional SU_Pilot kPilot)
{
	if(kPilot == none)
	{
		kPilot = class'SU_Utils'.static.GetPilot(m_kShip);
	}
	m_kCurrentPilot = kPilot;
	if(m_kCurrentPilot == none)
	{
		m_kShip.m_strCallsign = class'SquadronUnleashed'.default.m_strNoPilotAssigned;
		m_kShip.m_iConfirmedKills = 0;
	}
}
/** Returns SU_WatchShipMgr instance with the specified m_kShip property.*/
static function SU_WatchShipMgr GetWatchShipMgr(XGShip_Interceptor kShip)
{
	local SU_WatchShipMgr kMgr;
	local WorldInfo kWorld;

	kWorld = class'Engine'.static.GetCurrentWorldInfo();//helper due to static function
	foreach kWorld.DynamicActors(class'SU_WatchShipMgr', kMgr)
	{
		if(kMgr.IsValid() && kMgr.m_kShip == kShip)
		{
			return kMgr;
		}
	}
	return none;
}
function StartWatchingWeapons()
{
	m_iWatchWeaponsHandle = WorldInfo.MyWatchVariableMgr.RegisterWatchVariableStructMember(m_kShip, 'm_kTShip', 'arrWeapons', self, OnWeaponsChangedCallback);
}
function StartWatchingStatus()
{
	m_iWatchStatusHandle = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kShip, 'm_iStatus', self, OnStatusChangedCallback);
}
function StartWatchingCallsign()
{
	m_iWatchCallsignHandle = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kShip, 'm_strCallsign', self, OnCallsignChangedCallback);
}
function StopWatchingWeapons()
{
	if(m_iWatchWeaponsHandle != -1)
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchWeaponsHandle);
	}
	m_iWatchWeaponsHandle = -1;
}
function StopWatchingStatus()
{
	if(m_iWatchStatusHandle!= -1)
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchStatusHandle);
	}
	m_iWatchStatusHandle = -1;
}
function StopWatchingCallsign()
{
	if(m_iWatchCallsignHandle != -1)
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchCallsignHandle);
	}
	m_iWatchCallsignHandle = -1;
}
function PauseWatchingKills()
{
	if(m_iWatchKillsHandle != -1)
		DisableWatchHandle(m_iWatchKillsHandle);
}
function ContinueWatchingKills()
{
	if(m_iWatchKillsHandle != -1)
		EnableWatchHandle(m_iWatchKillsHandle);
}
function EnableWatchHandle(int iHandle)
{
	WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(iHandle, true);
}
function DisableWatchHandle(int iHandle)
{
	WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(iHandle, false);
}
function EnableAllHandles()
{
	EnableWatchHandle(m_iWatchCallsignHandle);
	EnableWatchHandle(m_iWatchKillsHandle);
	EnableWatchHandle(m_iWatchStatusHandle);
	EnableWatchHandle(m_iWatchWeaponsHandle);
}
function DisableAllHandles()
{
	DisableWatchHandle(m_iWatchCallsignHandle);
	DisableWatchHandle(m_iWatchKillsHandle);
	DisableWatchHandle(m_iWatchStatusHandle);
	DisableWatchHandle(m_iWatchWeaponsHandle);
}
DefaultProperties
{
}