class LoadoutManagerMutator extends XComMutator;

var LoadoutManager m_kLoadoutManager;

function EnsureLoadoutManager(PlayerController Sender)
{
    local LoadoutManager lm;
    if (m_kLoadoutManager == None) {
        foreach AllActors(class 'LoadoutManager', lm)
        {
            m_kLoadoutManager = lm;
            break;
        }

        if (m_kLoadoutManager == None) {
            m_kLoadoutManager = Spawn(class'LoadoutManager', Sender);
        }
    }
}

function AdjustDescription()
{
    local UISoldierSummary kUI;
    local float height;

    foreach AllActors(class 'UISoldierSummary', kUI) {
        break;
    }
    if (kUI == none)
    {
        LogInternal("Failed to locate the UISoldierSummary instance");
        return;
    }

    // Move the description box (separator + text area) down 40 pixels to give more space to the
    // menu itself.
    height = kUI.manager.GetVariableNumber(string(kUI.GetMCPath()) $ ".description._y");
    kUI.manager.SetVariableNumber(string(kUI.GetMCPath()) $ ".description._y", height + 40);

    // Increase the total height of the "bg" clip to allow more room before the text overflows
    height = kUI.manager.GetVariableNumber(string(kUI.GetMCPath()) $ ".bg.height");
    kUI.manager.SetVariableNumber(string(kUI.GetMCPath()) $ ".bg.height", height + 80);
}

function Mutate(String MutateString, PlayerController Sender)
{
    if (MutateString == "XGSoldierUI.SaveRestoreLoadoutMenu") {
        //LogInternal("Mutate: SaveRestoreLoadoutMenu");
        EnsureLoadoutManager(Sender);
        m_kLoadoutManager.UpdateMainMenu();            
    }
    else if (InStr(MutateString, "XGSoldierUI.SaveLoadout_") > -1) {
        //LogInternal("Mutate: SaveLoadout");
        EnsureLoadoutManager(Sender);
        m_kLoadoutManager.SaveLoadout(Split(MutateString, "XGSoldierUI.SaveLoadout_", true));
    }
    else if (InStr(MutateString, "XGSoldierUI.RestoreLoadout_") > -1) {
        //LogInternal("Mutate: RestoreLoadout");
        EnsureLoadoutManager(Sender);
        m_kLoadoutManager.RestoreLoadout(Split(MutateString, "XGSoldierUI.RestoreLoadout_", true));
    }
    else if (MutateString == "UISoldierSummary.AdjustDescription") {
        AdjustDescription();
    }
    else if (MutateString == "SquadLoadout_0") {
        //LogInternal("Mutate: SquadLoadout 0");
        EnsureLoadoutManager(Sender);
        m_kLoadoutManager.SquadLoadout(0);
    }
    else if (MutateString == "SquadLoadout_1") {
        //LogInternal("Mutate: SquadLoadout 1");
        EnsureLoadoutManager(Sender);
        m_kLoadoutManager.SquadLoadout(1);
    }
    else if (MutateString == "LoadoutManager.UpdateMainMenuForSaveRestore") {
        EnsureLoadoutManager(Sender);
        m_kLoadoutManager.UpdateMainMenuForSaveRestore();
    }
    else if (MutateString == "LoadoutManager.UpdateSquadButtons") {
        EnsureLoadoutManager(Sender);
        m_kLoadoutManager.UpdateSquadButtons();
    }

    super.Mutate(MutateString, Sender);
}
