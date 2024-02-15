class XComLocPatcher extends IniLocPatcher;

function Init()
{
	if(class'XComGameInfo'.default.ModNames.Find("XComMutator.BaseMutatorLoader") < 0)
	{
		class'XComGameInfo'.default.ModNames.AddItem("XComMutator.BaseMutatorLoader");
		class'XComGameInfo'.static.StaticSaveConfig();
	}
	//restore original settings and re-init
	class'GameEngine'.static.GetOnlineSubsystem().IniLocPatcherClassName = "Engine.IniLocPatcher";
	class'GameEngine'.static.GetOnlineSubsystem().PostInit();
}
DefaultProperties
{
}
