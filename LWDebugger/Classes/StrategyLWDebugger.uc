class StrategyLWDebugger extends XComMutator
	config(LWDebugger);

var config bool bDebugGeoscapePause;
//-----------------------------------------------
// UTILITY FUNCTIONS
//----------------------------------------------

function XComGameInfo GetGame()
{
	return XComGameInfo(WorldInfo.Game);
}
function PlayerController PC()
{
	return class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController();
}
function XComPresentationLayerBase PRES()
{
	return XComPlayerController(PC()).m_Pres;
}
function actor GetActor(class<actor> ActorClass, string strName)
{
	local actor kActorToGet;

	foreach DynamicActors(ActorClass, kActorToGet)
	{
		if(string(kActorToGet) == strName)
		{
			return kActorToGet;
		}
	}
}
//-----------------------------------
// END OF UTILITY SECTION
//-----------------------------------
event PostBeginPlay()
{
	if(GetGame() != none)
	{
		SetTimer(2.0, true, 'StrategyLoadedCheck');
	}
}
function StrategyLoadedCheck()
{
	if(PRES() != none && PRES().m_bPresLayerReady)
	{
		ClearTimer(GetFuncName());
		CleanUpInterceptions();
		WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XComHeadquartersGame(GetGame()).GetGameCore().GEOSCAPE(), 'm_fTimeScale', self, OnTimeScaleChange);
		//anything to do when HQ game has been loaded comes below
		if(bDebugGeoscapePause && XComHeadquartersGame(GetGame()) != none && XComHeadquartersGame(GetGame()).GetGameCore().GENELABS() != none)
		{
			WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XComHeadquartersGame(GetGame()).GetGameCore().GENELABS(), 'PendingNarrativeMoment', self, OnGeneModFinished);
		}
	}
}
function Mutate(String MutateString, PlayerController Sender)
{	
	if (MutateString == "XGGeoscape.RestoreNormalTimeFrame" && bDebugGeoscapePause)
	{
		LogInternal("Debugging Geoscape Pause");
		MutateGeoscapePause();
	}
	super.Mutate(MutateString, Sender);
}
function MutateGeoscapePause()
{
	local XGGeoscape kGeo;
	local XGMission kMission;
	local int iCount;
	local string strScriptTrace;

	strScriptTrace = GetScriptTrace();
	kGeo = XComHeadquartersGame(GetGame()).GetGameCore().GEOSCAPE();
	if(InStr(strScriptTrace, "OnCancelScan",,true) != -1)
	{
		LogInternal("Cancel scan clicked, skipping");
		return;
	}
	foreach kGeo.m_arrMissions(kMission)
	{
		if(kMission.IsDetected())
		{
			++iCount;
		}
	}
	if(iCount != 1)
	{
		LogInternal("No missions or more than 1 mission pending");
		return;
	}
	foreach kGeo.m_arrMissions(kMission)
	{
		if(kMission.IsDetected() && kMission.m_iMissionType == 8)
		{
			LogInternal("Only alien base alert found, restoring fast forward...");
			kGeo.FastForward();
			break;
		}
	}
}
function OnGeneModFinished()
{
	local XGFacility_GeneLabs kGeneLab;
	
	kGeneLab = XComHeadquartersGame(GetGame()).GetGameCore().GENELABS();
	if(kGeneLab.PendingNarrativeMoment != none && !kGeneLab.IsInState('WaitingToStartGeneModCinematic'))
	{
		if(XComHeadquartersGame(GetGame()).GetGameCore().GEOSCAPE().IsScanning())
		{
			XComHeadquartersGame(GetGame()).GetGameCore().GEOSCAPE().RestoreNormalTimeFrame();
			kGeneLab.PendingNarrativeMoment = none;
		}
	}
}
function OnTimeScaleChange()
{
	local XGGeoscape kGeo;

	kGeo = XComHeadquartersGame(GetGame()).GetGameCore().GEOSCAPE();
	if(kGeo.IsScanning())
	{
		if(kGeo.m_arrInterceptions.Length > 0 && !kGeo.IsBusy())
		{
			CleanUpInterceptions();
		}
	}
}
function CleanUpInterceptions()
{
	local XGInterception kInterception;
	local int iCount;

	foreach DynamicActors(class'XGInterception', kInterception)
	{
		XComHeadquartersGame(GetGame()).GetGameCore().GEOSCAPE().RemoveInterception(kInterception);
		++iCount;
	}
	LogInternal("Destroyed" @ string(iCount) @ "redundant interceptions", name);
}
