class GMMutator extends XComMutator config (ModGenderMgr);

var string m_strBuildVersion;
var XGCharacterGenerator m_kOrigCharGen;
var GMCharGenerator m_kGMCharGen;

function string GetDebugName()
{
	return GetItemName(string(Class)) @ m_strBuildVersion;
}
event PostBeginPlay()
{
	SetTimer(2.0, true, 'StrategyLoadedCheck');
	`Log(GetFuncName() @ GetDebugName());
}

static function GMMutator GetSelf()
{
	local Mutator kM;

	kM = class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator;
	while(!kM.IsA('GMMutator') && kM.NextMutator != none)
	{
		kM = kM.NextMutator;
	}
	return GMMutator(kM);
}
function XGStrategy STRATEGY()
{
	return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore();
}
function RegisterWatchVars()
{
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(STRATEGY().GEOSCAPE(), 'm_fGameTimer', self, GameTickUpdate);
}
function StrategyLoadedCheck()
{
	if(XComHeadquartersController(GetALocalPlayerController()).m_Pres != none && XComHeadquartersController(GetALocalPlayerController()).m_Pres.m_bPresLayerReady)
	{
		`log("Strategy loaded",,GetFuncName());
		ClearTimer(GetFuncName());
		RegisterWatchVars();
		CacheCharGenerators();
	}
}
function CacheCharGenerators()
{
	if(m_kGMCharGen == none)
	{
		m_kGMCharGen = Spawn(class'GMCharGenerator');
	}
	if(m_kOrigCharGen == none)
	{
		if(STRATEGY().GetHQ() != none && STRATEGY().GetHQ().m_kBarracks != none)
		{
			m_kOrigCharGen = STRATEGY().GetHQ().m_kBarracks.m_kCharGen;
		}
		else
		{
			m_kOrigCharGen = Spawn(class'XGCharacterGenerator');
		}
	}
}
function HeadQuartersInitNewGame(PlayerController Sender)
{
	`log(GetFuncName(),,Name);
	ApplyInitialGenderRatio();
}
function ApplyInitialGenderRatio()
{
	local XGFacility_Barracks kB;
	local XGStrategySoldier kS;

	kB = STRATEGY().BARRACKS();
	foreach kB.m_arrSoldiers(kS)
	{
		kS.Destroy();
	}
	kB.m_arrSoldiers.Length = 0;
	kB.m_arrOTSUpgrades.Length = 0;
	kB.m_iSoldierCounter = 0;
	ShuffleCharGenerator(true);
	kB.InitNewGame();
	ShuffleCharGenerator(false);
}
function ShuffleCharGenerator(bool bMy)
{
	CacheCharGenerators();
	STRATEGY().GetHQ().m_kBarracks.m_kCharGen = bMy ? m_kGMCharGen : m_kOrigCharGen;
	if(!bMy && m_kGMCharGen != none && m_kGMCharGen.GetDummy() != none)
	{
		STRATEGY().GetHQ().m_kBarracks.m_arrFallen.RemoveItem(m_kGMCharGen.GetDummy());
	}
}
function GameTickUpdate()
{
	if(STRATEGY().GEOSCAPE().m_fGameTimer <= 1800.0)
	{
		UpdateSoldierHirings();
	}
}
function UpdateSoldierHirings()
{
	local XGHeadQuarters HQ;
	local TStaffOrder tOrder;
	local int i;

	HQ = STRATEGY().HQ();
	for(i=HQ.m_arrHiringOrders.Length-1; i >=0; --i)
	{
		tOrder = HQ.m_arrHiringOrders[i];
		if(tOrder.iStaffType == eStaff_Soldier && tOrder.iHours <= 1)
		{
			ShuffleCharGenerator(true);
			HQ.GEOSCAPE().RestoreNormalTimeFrame();
			HQ.m_kBarracks.AddNewSoldiers(tOrder.iNumStaff);
			HQ.PRES().Notify(eGA_NewSoldiers, tOrder.iNumStaff);
			HQ.m_arrHiringOrders.Remove(i, 1);
			ShuffleCharGenerator(false);
		}
	}
}
function BuildDataForModMgr()
{
	local GMModOptions kContainer;

	class'UIModManager'.static.RegisterUpdateCallback(UpdateOptions);
	class'UIModManager'.static.RegisterInitWidgetCallback(InitModsMenuWidget);
	foreach DynamicActors(class'GMModOptions', kContainer)
	{
		if(kContainer != none)
		{
			break;
		}
	}
	if(kContainer == none)
	{
		kContainer = Spawn(class'GMModOptions');
		kContainer.Init(self);
	}
}
function UpdateOptions()
{
}
function InitModsMenuWidget(out UIWidget kWidget, out TModOption tOption)
{
}
state UpdatingOptions
{
	event PushedState()
	{
		BuildDataForModMgr();
	}

}
DefaultProperties
{
	m_strBuildVersion="1.0"
}
