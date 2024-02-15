class MMGfx_WidgetHelper extends GfxObject;

function AS_InitWidgetHelper(GFxObject parent, int iNumWidgets, optional GFxObject mouseTargetCallback)
{
	local int iWidget;
	local GFxObject arrWidgets;

	SetObject("_parent", parent);
	SetFloat("MAX_widgets", iNumWidgets);
	SetObject("targetMouseCallback", mouseTargetCallback != none ? mouseTargetCallback : parent);
	arrWidgets = CreateArray();
	iWidget=0;
	for(iWidget=0; iWidget < iNumWidgets; ++iWidget)
	{
		arrWidgets.SetElementObject(iWidget, GetObject("_parent").GetObject("option"$iWidget));
		`log("ERROR: WidgetHelper"@self@"could not find 'option"$iWidget$"' in _parent" @ GetObject("_parent"), arrWidgets.GetElementObject(iWidget) == none);
//		arrWidgets.GetElementObject(iWidget).SetVisible(true);
	}
	SetObject("widgets", arrWidgets);
	AS_SetSelected(0);	
}
function AS_SetSelected(int iSelected)
{
	ActionScriptVoid("SetSelected");
}
DefaultProperties
{
}
