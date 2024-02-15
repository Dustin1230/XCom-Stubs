Class WeaponSortCheckpoint extends Actor;

struct CheckpointRecord
{
	var array <int> iFndryComplete;
	var array <int> iRsrchComplete;
};

var array <int> iFndryComplete;
var array <int> iRsrchComplete;

function XGFacility_Engineering ENGINEERING()
{
	return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().m_kEngineering;
	//return ReturnValue;    
}

function XGFacility_Labs LABS()
{
	return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().m_kLabs;
	//return ReturnValue;    
}

function CompletedProject()
{
	iFndryComplete = ENGINEERING().m_arrFoundryHistory;
	iRsrchComplete = LABS().m_arrResearched;
}