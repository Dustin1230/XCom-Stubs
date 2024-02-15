class MMXComEngine extends XComEngine;

function Object GetProfileSettings()
{
	local XComMod kNewMod;

	if(InStr(GetScriptTrace(), "InitBattle") != -1)
	{
		if(XComGameInfo(GetCurrentWorldInfo().Game).BaseMutator == none)
		{
			kNewMod = new (GetCurrentWorldInfo().Game) class<XComMod>(DynamicLoadObject("XComMutator.BaseMutatorLoader", class'Class'));
			XComGameInfo(GetCurrentWorldInfo().Game).Mods.AddItem(kNewMod);
		}
		XComGameInfo(GetCurrentWorldInfo().Game).ModStartMatch();
	}
    return XComProfileSettings;
}
function Object GetContentManager()
{
	local XComMod kNewMod;

	if(InStr(GetScriptTrace(), "XComHQPresentationLayer.Init") != -1)
	{
		if(XComGameInfo(GetCurrentWorldInfo().Game).BaseMutator == none)
		{
			kNewMod = new (GetCurrentWorldInfo().Game) class<XComMod>(DynamicLoadObject("XComMutator.BaseMutatorLoader", class'Class'));
			XComGameInfo(GetCurrentWorldInfo().Game).Mods.AddItem(kNewMod);
		}
		XComGameInfo(GetCurrentWorldInfo().Game).ModStartMatch();
	}

	return ContentManager;
}
DefaultProperties
{
}
