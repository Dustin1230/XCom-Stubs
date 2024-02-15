class XComFCMutator extends XComMutator;

function XGWorld World()
{
    return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetWorld();
}

function HeadQuartersInitNewGame(PlayerController Sender)
{
	LogInternal("XComFCMutator: spawn XGFundingCouncil_Mod class.");
    World().m_kFundingCouncil = Spawn(class'XGFundingCouncil_Mod');
    World().m_kFundingCouncil.InitNewGame();
}

// Decompiled with UE Explorer.
defaultproperties
{}