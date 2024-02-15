class SightlinesMenu extends XComMutator;

function UpdateSightlinesSettings()
{
	local Mutator kM;

	//update or remove the running mutator
	if(XComTacticalGame(class'Engine'.static.GetCurrentWorldInfo().Game) != none)
	{
		kM = GetMutator("Sightlines.SightlineMutator");
		if(kM != none && kM.bUserAdded)
		{
			if(!class'UIModManager'.static.GetModMgr().IsModEnabled("Sightlines"))
			{
				XComTacticalGame(class'Engine'.static.GetCurrentWorldInfo().Game).RemoveMutator(kM);
				kM.Destroy();
			}
			else
			{
				SightlineMutator(kM).SightIndicator = class'SightlineMutator'.default.SightIndicator;
				SightlineMutator(kM).OVERWATCH_TOGGLE_DELAY = class'SightlineMutator'.default.OVERWATCH_TOGGLE_DELAY;
				SightlineMutator(kM).SIGHTLINE_TICK_DELAY = class'SightlineMutator'.default.SIGHTLINE_TICK_DELAY;
				SightlineMutator(kM).SHOW_FRIENDLY_INDICATORS = class'SightlineMutator'.default.SHOW_FRIENDLY_INDICATORS;
				SightlineMutator(kM).USE_TOGGLE_HOTKEY = class'SightlineMutator'.default.USE_TOGGLE_HOTKEY;
			}
		}
		else if(class'UIModManager'.static.GetModMgr().IsModEnabled("Sightlines") && kM != none)
		{
			kM.bUserAdded = true; //this will prevent destruction by the manager on cleanUp
			kM.SetTickIsDisabled(false); //this will re-enable Tick (disabled by the manager)
			kM.SetTimer(0.50, true, 'InitSightlines', self);
		}
	}
}
function InitSightlines()
{
	local SightlineMutator kSightlines;
	
	if(XComPlayerController(GetALocalPlayerController()).m_Pres.m_kPauseMenu == none)
	{
		kSightlines = SightlineMutator(GetMutator("Sightlines.SightlineMutator"));
		kSightlines.ClearTimer(GetFuncName(), self);
		kSightlines.PostLoadSaveGame(none);
	}
}
static function Mutator GetMutator(string sMutatorClass)
{
	local Mutator kM;
	local class<Mutator> kMutClass;

	kMutClass = class<Mutator>(DynamicLoadObject(sMutatorClass, class'Class', true));
	if(kMutClass != none)
	{
		kM = class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator;
		while(kM != none)
		{
			if(kM.Class == kMutClass)
			{
				return kM;
			}
			kM = kM.NextMutator;
		}
	}
	return none;
}
state UpdatingOptions
{
	event PushedState()
	{
		class'UIModManager'.static.RegisterUpdateCallback(UpdateSightlinesSettings);
	}
}
DefaultProperties
{
}