class MMXGAbility_ScoutSense extends XGAbility_Targeted;

var string m_strHUDColor;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	if(XGUnit(Owner) != none)
	{
		m_kUnit = XGUnit(Owner);
	}
}
function Init(int iAbility)
{
	super(XGAbility).Init(iAbility);
	if(m_kUnit != none)
	{
		m_aTargets[0].m_kTarget = m_kUnit;
		UpdateHelp();
	}
}
function UpdateHelp()
{
	local MMUnitTracker kTracker;

	kTracker = class'MMUnitTracker'.static.GetUnitTrackerFor(m_kUnit);
	if(kTracker.m_kScoutSense != none && !kTracker.m_kScoutSense.bHidden)
	{
		strHelp = class'MiniModsTactical'.default.m_strScoutSenseRest;
	}
	else
	{
		strHelp = class'MiniModsTactical'.default.m_strScoutSenseHelp;
	}
	
}
simulated function string GetHelpText()
{
	return strHelp;
}
simulated function ApplyEffect()
{
	TogglePerception();
	UpdateHelp();
	//lines below should ensure that no cost is applied by XGAbility.ApplyCost
	m_bDelayApplyCost = true;
	m_bReactionFire = true;
}
simulated function bool IsFreeAiming()
{
	PRES().GetTacticalHUD().m_kInfoBox.AS_SetGermanModeButtonVisibility(false);
    return m_bFreeAiming;
}

function TogglePerception()
{
	local MMUnitTracker kTracker;

	kTracker = class'MMUnitTracker'.static.GetUnitTrackerFor(m_kUnit);
	kTracker.UpdateScoutSense();
	kTracker.m_kScoutSense.ToggleVisibility();
}
function string GetHUDColorString()
{
	strPerformerMessage=string(Class.Name)$"."$GetFuncName();
    if(class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator != none)
    {
        class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator.ModifyLogin(strPerformerMessage, m_strHUDColor);
    }
	return m_strHUDColor;
}
simulated function bool ShowAbility()
{
	return m_kUnit == XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_kActivePlayer.GetActiveUnit();
}
DefaultProperties
{
	m_iMaxExecutions=10
	m_strHUDColor="cyan"
}
