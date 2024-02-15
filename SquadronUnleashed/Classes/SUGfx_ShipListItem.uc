class SUGfx_ShipListItem extends GfxObject;

var float STATIC_HEIGHT;

delegate float delGetHeight();

function AS_SetGetHeightDelegate(delegate<delGetHeight> fnCallback)
{
	ActionScriptSetFunction("getHeight");
}
function float GetHeightOverride()
{
	return STATIC_HEIGHT;
}
DefaultProperties
{
	STATIC_HEIGHT=75.0
}
