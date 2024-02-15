class MMGfxAmmoBar extends GfxObject;

function AS_UpdateLocation(float X, float Y)
{
	ActionScriptVoid("UpdateLocation");
}
function AS_SetHealth(int iMax, int iRemaining)
{
	ActionScriptVoid("SetHealth");
	if(iRemaining == 0)
	{
		GetObject("remainingHealthFill").SetFloat("_width", 1.0);
	}
}
function AS_SetKillShot(bool bFullBorder)
{
	ActionScriptVoid("SetKillShot");
}
DefaultProperties
{
}
