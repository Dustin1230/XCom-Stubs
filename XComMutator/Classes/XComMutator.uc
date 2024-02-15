class XComMutator extends Mutator;

var bool m_bDisableLog;
var bool m_bLocalMutate;

// Mutators loaded from checkpoint might have the NextMutator property set to a conflicting value (risk of recursive calls).
// Therefore during ApplyCheckpointRecord the existing chain of mutators must be rebuilt on thy fly.
// Attribute Mutator.bUserAdded serves as the flag for validated mutators.
function ApplyCheckpointRecord()
{
	local Mutator kMutator;
	local string strLog;
	local array<Mutator> arrValidMutators;
	local int i;

	strLog="Rebuilt mutators' chain:";
	
	//ensure BaseMutator is kept (though any mutator can serve as BaseMutator actually)
	arrValidMutators.AddItem(class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator);
	//cache all mutators
	foreach DynamicActors(class'Mutator', kMutator)
	{
		if(kMutator.bUserAdded && arrValidMutators.Find(kMutator) < 0)
		{
			arrValidMutators.AddItem(kMutator);
		}
	}
	if(NextMutator != none)
	{
		i = arrValidMutators.Find(NextMutator);
	}
	arrValidMutators.RemoveItem(self); 
	if(i >= 0)
	{
		arrValidMutators.InsertItem(i, self);
	}
	else
	{
		arrValidMutators.AddItem(self);
	}
	bUserAdded = true;
	m_bDisableLog = class'XComMutatorLoader'.default.bDisableLog;
	
	//rebuild chain of mutators
	for(i=0; i < arrValidMutators.Length; i++)
	{
		if(i+1 < arrValidMutators.Length)
		{
			arrValidMutators[i].NextMutator = arrValidMutators[i+1];
		}
		else
		{
			arrValidMutators[i].NextMutator = none;
		}
		strLog @= string(arrValidMutators[i].Name);
		strLog @= "->";
	}
	strLog @= "None";
	`Log(strLog, !m_bDisableLog);
}
function ModifyLogin(out string strOptions, out string strMessage)
{
	//szmind: this section is only to make Mutate function respond to ModifyLogin calls
	//it is mainly for backward compatibility of older mods
	//a check for GameCore is to avoid premature call of Mutate in HQ game
	if(XComTacticalGame(class'Engine'.static.GetCurrentWorldInfo().Game) != none || (XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game) != none && XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore() != none) )
	{
		m_bLocalMutate = true;
		Mutate(strOptions, none);
	}

	// never forget to call for super(Mutator).ModifyLogin from inside subclass of XComMutator class
	// if you do, you'll stop ModifyLogin propagation along the chain of mutators
	super(Mutator).ModifyLogin(strOptions, strMessage);
}
function Mutate(string MutateString, PlayerController Sender)
{
	local array<string> SplitStr;
	local string ParamsStr;
	local bool bLocal;
	
	bLocal = m_bLocalMutate;    //szmind: check if Mutate was called from ModifyLogin
	m_bLocalMutate = false;     //reset m_bLocalMutate for any further call from ModifyLogin
	
	if (MutateString == "XComGameInfo.InitGame")
	{
		GameInfoInitGame(Sender);
	}
	else if (MutateString == "XGHeadQuarters.InitNewGame")
	{
		HeadQuartersInitNewGame(Sender);
	}
	else if (MutateString == "XGBattle_SP.PostLevelLoaded")
	{
		PostLevelLoaded(Sender);
	}
	else if (MutateString == "XGBattle_SP.PostLoadSaveGame")
	{
		PostLoadSaveGame(Sender);
	}
	else if (MutateString == "XGBattle.DoWorldDataRebuild")
	{
		DoWorldDataRebuild(Sender);
	}
	else if (MutateString == "XGBattle.Loading.NotifyKismetOfLoad")
	{
		MutateNotifyKismetOfLoad(Sender);
	}
	else if (MutateString == "XGStrategy.NewGame")
	{
		MutateStrategyAI(Sender);
	}
	else if (InStr(MutateString, "SeqAct_SpawnAlien.Activated") > -1)
	{
		MutateSpawnAlien(Split(MutateString, "SeqAct_SpawnAlien.Activated:", true), Sender);
	}
	else if (InStr(MutateString, "XGPlayer.InitBehavior") > -1)
	{
		MutateTacticalAI(Split(MutateString, "XGPlayer.InitBehavior:", true), Sender);
	}
	else if (InStr(MutateString, "XGUnit.UpdateInteractClaim") > -1)
	{
		MutateUpdateInteractClaim(Split(MutateString, "XGUnit.UpdateInteractClaim:", true), Sender);
	}
	else if (InStr(MutateString, "XGUnit.RecordKill") > -1)
	{
		ParamsStr = Split(MutateString, "XGUnit.RecordKill:", true);
		SplitStr = SplitString(ParamsStr, ",", false);
		if (SplitStr.Length == 2)
		{
			MutateRecordKill(SplitStr[0], SplitStr[1], Sender);
		}
	}
	`Log("XComMutator: Current = " $ string(Name), !m_bDisableLog);
	if (NextMutator != none)
	{
		`Log("XComMutator: Next = " $ string(NextMutator.Name), !m_bDisableLog);
	}
	else
	{
		`Log("XComMutator: Next = None", !m_bDisableLog);
	}
	// never forget to call for super.Mutate from inside subclass of XComMutator class
	// if you do, you'll stop Mutate propagation along the chain of mutators
	// szmind: no need for propagation when this was called from ModifyLogin (cause ModifyLogin handles propagation)
	if(!bLocal)
		super.Mutate(MutateString, Sender);
}

function GameInfoInitGame(PlayerController Sender)
{
	// never call for NextMutator from inside a function, called by Mutate!
	// if you do, you'll end up calling the same function twice
}

function HeadQuartersInitNewGame(PlayerController Sender)
{
	// never call for NextMutator from inside a function, called by Mutate!
	// if you do, you'll end up calling the same function twice
}

function PostLevelLoaded(PlayerController Sender)
{
	// never call for NextMutator from inside a function, called by Mutate!
	// if you do, you'll end up calling the same function twice
}

function PostLoadSaveGame(PlayerController Sender)
{
	// never call for NextMutator from inside a function, called by Mutate!
	// if you do, you'll end up calling the same function twice
}

function DoWorldDataRebuild(PlayerController Sender)
{
	// never call for NextMutator from inside a function, called by Mutate!
	// if you do, you'll end up calling the same function twice
}

function MutateNotifyKismetOfLoad(PlayerController Sender)
{
	// never call for NextMutator from inside a function, called by Mutate!
	// if you do, you'll end up calling the same function twice
}

function MutateStrategyAI(PlayerController Sender)
{
	// never call for NextMutator from inside a function, called by Mutate!
	// if you do, you'll end up calling the same function twice
}

function MutateSpawnAlien(string SeqActObjName, PlayerController Sender)
{
	// never call for NextMutator from inside a function, called by Mutate!
	// if you do, you'll end up calling the same function twice
}

function MutateTacticalAI(string UnitObjName, PlayerController Sender)
{
	// never call for NextMutator from inside a function, called by Mutate!
	// if you do, you'll end up calling the same function twice
}

function MutateUpdateInteractClaim(string UnitObjName, PlayerController Sender)
{
	// never call for NextMutator from inside a function, called by Mutate!
	// if you do, you'll end up calling the same function twice
}

function MutateRecordKill(string UnitObjName, string VictimObjName, PlayerController Sender)
{
	// never call for NextMutator from inside a function, called by Mutate!
	// if you do, you'll end up calling the same function twice
}

function string TrimMutString(string strMut)
{
	if(InStr(strMut, ":") != -1)
	{
		return Left(strMut, InStr(strMut, ":"));
	}
	return strMut;
}
defaultproperties
{
	m_bDisableLog=true
}
