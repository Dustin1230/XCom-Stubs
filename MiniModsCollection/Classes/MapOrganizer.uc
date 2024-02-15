class MapOrganizer extends XComMutator
	config(MiniMods);

struct MapRules
{
	var int iMaxDifficulty;
	var string Map;
};

var config array<MapRules> AbductionMapRules;
var bool TestDone;


event PostBeginPlay()
{
	TestDone = !class'MiniModsStrategy'.default.bDebugLog;
	if(class'Engine'.static.GetCurrentWorldInfo().Game.IsA('XComHeadquartersGame'))
	{
		//start launching RegisterWatchVars in loop until success
		SetTimer(1.0, true, 'RegisterWatchVars');
	}
}
function RegisterWatchVars()
{
	if(!XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().IsInState('Headquarters'))
	{
		//if the game is not yet ready exit the function
		return;
	}
	//stop the loop, game is ready, let's rock
	ClearTimer(GetFuncName());

	//start watching m_arrMissions array on Geoscape
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GEOSCAPE(), 'm_arrMissions', self, UpdateMissions);
	UpdateMissions();
}
function int GetMaxMapDifficulty(string strMapDisplayName)
{
	local MapRules tMapRule;
	local int iDiff;

	iDiff = eMissionDiff_VeryHard;
	foreach AbductionMapRules(tMapRule)
	{
		if(InStr(strMapDisplayName, tMapRule.Map,,true) != -1 && tMapRule.iMaxDifficulty < iDiff)
		{
			iDiff = tMapRule.iMaxDifficulty;
		}
	}
	return iDiff;
}
function UpdateMissions()
{
	local XGMission kMission;
	local XGGeoscape kGeo;
	//local int i;

	if(!class'MiniModsStrategy'.default.bAbductionMapManager)
	{
		return;
	}
	`Log("Checking whether maps match difficulty...", class'MiniModsStrategy'.default.bDebugLog, name);
	kGeo = XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GEOSCAPE();
	foreach kGeo.m_arrMissions(kMission)
	{
		if(kMission.m_bScripted || kMission.m_bCheated || kMission.m_iMissionType != eMission_Abduction)
		{
			`Log(kMission @ "is abduction?" @ kMission.m_iMissionType == eMission_Abduction @ ". Scripted?" @ kMission.m_bScripted @ ". Cheated?" @ kMission.m_bCheated @ "Skipping.", class'MiniModsStrategy'.default.bDebugLog, name);
			//skip non-abduction, cheated and scripted
			continue;
		}
		`Log(kMission @ "map name:" @ kMission.m_kDesc.m_strMapName @ "diff:" @ kMission.m_eDifficulty, class'MiniModsStrategy'.default.bDebugLog, name);
		if( kMission.m_eDifficulty > GetMaxMapDifficulty(kMission.m_kDesc.m_strMapName))
		{
			ReplaceMapFor(kMission);
		}
		else
			`Log("Map matches difficulty", class'MiniModsStrategy'.default.bDebugLog, name);
	}
	/*if(!TestDone)
	{
		for(i=0; i<20; ++i)
		{
			kMission = GetRandomTestAbduction();
			LogInternal(kMission @ "map name:" @ kMission.m_kDesc.m_strMapName @ "diff:" @ kMission.m_eDifficulty);
			if( kMission.m_eDifficulty > GetMaxMapDifficulty(kMission.m_kDesc.m_strMapName))
				ReplaceMapFor(kMission);
			else
				LogInternal("Map matches difficulty");
			kMission.Destroy();
		}
		TestDone=true;
	}*/
}
function XGMission GetRandomTestAbduction()
{
	local XGMission_Abduction kMission;
	local int iPlayCount;
	local XGStrategy kCore;

	kCore = XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore();

	kMission = Spawn(class'XGMission_Abduction');
	kMission.m_iMissionType = eMission_Abduction;
	kMission.m_eDifficulty = EMissionDifficulty(Rand(4));
	kMission.m_iCity = kCore.Continent(kCore.HQ().GetContinent()).GetRandomCity();
	kMission.m_iCountry = kCore.CITY(kMission.m_iCity).GetCountry();
	kMission.m_iContinent = kCore.HQ().GetContinent();
	kMission.m_iDuration = class'XGTacticalGameCore'.default.ABDUCTION_TIMER;
	kMission.m_v2Coords = kCore.CITY(kMission.m_iCity).m_v2Coords;
	kMission.m_eTimeOfDay = 0;
	kMission.m_kDesc = Spawn(class'XGBattleDesc');
	kMission.m_kDesc.m_strMapName = class'XComMapManager'.static.GetRandomMapDisplayName(EMissionType(kMission.m_iMissionType), (Rand(2)==0 ? eMissionTime_Day : eMissionTime_Night), eShip_None, kMission.GetRegion(), kMission.GetCountry(), XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_arrMapHistory, iPlayCount); 
	kMission.m_kDesc.m_strMapCommand = class'XComMapManager'.static.GetMapCommandLine(kMission.m_kDesc.m_strMapName, true, true, kMission.m_kDesc);
	return kMission;
}
function ReplaceMapFor(XGMission kM)
{
	local int iPlayCount;

	class'XComMapManager'.static.DecrementMapPlayHistory(kM.m_kDesc.m_strMapName, XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_arrMapHistory, iPlayCount);
	do{
		kM.m_kDesc.m_strMapName = class'XComMapManager'.static.GetRandomMapDisplayName(eMission_Abduction, eMissionTime_None, eShip_None, kM.GetRegion(), kM.GetCountry(), XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_arrMapHistory, iPlayCount); 
	}
	until(kM.m_eDifficulty <= GetMaxMapDifficulty(kM.m_kDesc.m_strMapName));
	kM.m_kDesc.m_strMapCommand = class'XComMapManager'.static.GetMapCommandLine(kM.m_kDesc.m_strMapName, true, true, kM.m_kDesc);
	class'XComMapManager'.static.IncrementMapPlayHistory(kM.m_kDesc.m_strMapName, XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_arrMapHistory, iPlayCount);
	XComOnlineEventMgr(GameEngine(class'Engine'.static.GetEngine()).OnlineEventManager).SaveProfileSettings();
}
static function int GetDefaultDifficultyForMap(string strMapName)
{
	switch(CAPS(strMapName))
	{
		CASE "URB_BAR":
		CASE "URB_BOULEVARD":
		CASE "URB_BOULEVARD_EURO":
		CASE "URB_COMMERCIALSTREET":
		CASE "URB_FASTFOOD":
		CASE "URB_FASTFOOD_EWI":
		CASE "URB_HIGHWAY1":
		CASE "URB_INDUSTRIALOFFICE":
		CASE "DLC1_1_LOWFRIENDS":
		CASE "EWI_MELDTUTORIAL":
		CASE "URB_ROOFTOPSCONST":
		CASE "URB_ROOFTOPSCONST_ASIAN":
		CASE "URB_SMALLCEMETERY":
		CASE "URB_STREETHURRICANE":
			return 1; 
		case "URB_COMMERCIALRESTAURANT":
		case "URB_GASSTATION_EWI":
		case "URB_HIGHWAYBRIDGE":
		case "URB_LIQUORSTORE":
		case "DLC2_1_PORTENT":
		case "URB_STREETOVERPASS":
		case "URB_DEMOLITION_EWI":
		case "URB_TRUCKSTOP_EWI":
			return 2;
		case "URB_CONVIENIENCESTORE_EWI":
		case "URB_HIGHWAYFALLEN":
		case "URB_OFFICEPAPER":
		case "URB_OFFICEPAPER_EWI":
		case "URB_PIERA":
		case "URB_PIERA_ASIAN":
		case "URB_PIERA_TERROR":
		case "URB_POLICESTATION":
		case "URB_RESEARCHOUTPOST_EWI":
		case "URB_SLAUGHTERHOUSEA":
		case "URB_STREETOVERPASS_EWI":
		case "URB_TRAINYARD":
		case "URB_CEMETERYGRAND":
		case "URB_COMMERCIALALLEY_EWI":
		case "DLC1_2_CNFNDLIGHT":
		case "DLC2_2_DELUGE":
		case "URB_HIGHWAYCONSTRUCTION":
		case "URB_HIGHWAYCONSTRUCTION_EWI":
		case "URB_MILITARYAMMO":
		case "URB_TRAINSTATION":
			return 4;
		default:
			return 4;
	}
}
DefaultProperties
{
}
