class UIModCredits extends UICredits;

var array<string> m_arrModCredits;

simulated function OnInit()
{
	super(UI_FxsScreen).OnInit();
	DEBUG_AS_SetPixelsPerSec(30);
	UpdateData();
	if(m_iNumCreditsEntries != -1)
	{
		SetHelp(0, m_strDefaultHelp_Cancel, class'UI_FxsGamepadIcons'.static.GetBackButtonIcon());
	}
	else
	{
		manager.GetVariableObject(GetMCPath() $ ".theBackButton").SetVisible(false);
		SetTimer(3.0, false, 'EnableCancel');
	}
	if(UI_FxsScreen(Owner) != none)
	{
		UI_FxsScreen(Owner).Hide();
	}
}
simulated function UpdateData()
{
	local ASValue myValue;
	local array<ASValue> myArray;
	local int I;

	myValue.Type = AS_String;
	for(I = 0; I < m_arrModCredits.Length; ++ I)
	{
		myValue.S $= ((ApplyStyle(m_arrModCredits[I])) $ "\n");
		if((Len(myValue.S) > 500) || I == (m_arrModCredits.Length - 1))
		{
			myArray.AddItem(myValue);
			myValue.S = "";
		}
	}
	Invoke("SetCredits", myArray);
}
simulated function bool OnCancel(optional string Str)
{
	if(IsTimerActive('EnableCancel'))
	{
		return false;
	}
	Hide();
	if(UI_FxsScreen(Owner) != none)
	{
		UI_FxsScreen(Owner).Show();
	}
	if(controllerRef.m_Pres.m_kCredits != none)
	{
		controllerRef.m_Pres.m_kCredits = none;
	}
	controllerRef.m_Pres.GetHUD().RemoveScreen(self);
	return true;
}
function EnableCancel()
{
	SetHelp(0, m_strDefaultHelp_Cancel, class'UI_FxsGamepadIcons'.static.GetBackButtonIcon());
}
DefaultProperties
{
}
