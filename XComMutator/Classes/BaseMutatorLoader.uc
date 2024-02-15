class BaseMutatorLoader extends XComMod;

simulated function StartMatch()
{
	if(class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator == none)
	{
		`log("Initializing BaseMutator...",, Class.Name);
		class'Engine'.static.GetCurrentWorldInfo().Game.AddMutator("XComMutator.XComMutatorLoader");
		XComMutatorLoader(class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator).GameInfoInitGame(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController());
	}
	else
	{
		`log("Found BaseMutator" @ class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator,,Class.Name);
	}
}

DefaultProperties
{
}
