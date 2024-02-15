/** Do not extend this class. Instead extend UIModOptionsContainer.
 * This class serves only as a helper for non-programmer modders to build customized entries in Mods Menu through XComModsProfile.ini
 * An instance of this class is always spawned by UIModManager to ensure loading of the above .ini settings.
 * There should be always just ONE instance of this class. Hence PostBeginPlay to ensure this.
 */
class UIModSharedContainer extends UIModOptionsContainer
	config(ModsProfile);

event PostBeginPlay()
{
	local UIModSharedContainer kOther;
	local bool bOtherInstanceFound;

	foreach DynamicActors(class'UIModSharedContainer', kOther)
	{
		if(kOther != self)
		{
			bOtherInstanceFound=true;
		}
	}
	if(bOtherInstanceFound)
	{
		Destroy();
		LogInternal("Instance of UIModSharedContainer already exists. Destroying self...", name);
	}
	else
	{
		super.PostBeginPlay();
	}
}
DefaultProperties
{
}
