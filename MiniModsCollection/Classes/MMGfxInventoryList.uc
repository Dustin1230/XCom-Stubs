class MMGfxInventoryList extends GfxObject;

function Init()
{
	local ASDisplayInfo tDisplayInfo;

	tDisplayInfo = GetDisplayInfo();
	if(class'MiniModsStrategy'.static.IsLongWarBuild())
	{
		tDisplayInfo.X -= 350.0;
		tDisplayInfo.Y += 5.0;
	}
	else
	{
		tDisplayInfo.X -= 320.0;
		tDisplayInfo.Y += 25.0;
	}
	tDisplayInfo.XScale = 50.0;
	tDisplayInfo.YScale = 50.0;
	SetDisplayInfo(tDisplayInfo);
	GetObject("selectionIndicatorMC").SetVisible(false);
	SetFloat("padding", -36.0);
}
function AddInventoryItem(int Type, string Title, string imgLabel, int numEquipableItems, optional GFxObject mecIconsArray=XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).m_Pres.GetHUD().CreateArray(), optional bool bAvailable=true)
{
	local GFxObject gfxNewItem;

	AS_AddInventoryItem(Type, Title, imgLabel, numEquipableItems, mecIconsArray);
	if(!bAvailable)
	{
		gfxNewItem = GetObject("itemRoot").GetObject(string(AS_GetSize()-1));
		class'UIModUtils'.static.ObjectAddColor(gfxNewItem, 20,20,20);
	}
}
function RealizePositions()
{
	AS_RealizePositions();
	if(GetObject("itemRoot").GetObject("0") != none)
	{
		GetObject("itemRoot").GetObject("0").GetObject("removeItemBtnHelp").SetVisible(false);
	}
}
function AS_AddInventoryItem(int Type, string Title, string imgLabel, int numEquipableItems, optional GFxObject mecIconsArray=XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).m_Pres.GetHUD().CreateArray())
{
	local GFxObject gfxNewItem;

	ActionScriptVoid("AddInventoryItem");
	gfxNewItem = GetObject("itemRoot").GetObject(string(AS_GetSize()-1));
	gfxNewItem.SetFloat("_xscale", 50.0);
	gfxNewItem.SetFloat("_yscale", 50.0);
	//make equip/help button fully transparent
	class'UIModUtils'.static.ObjectAddColor(gfxNewItem.GetObject("removeItemBtnHelp"),0,0,0,0);
	//hide the equip/help on 1st slot (still fails with many slots)
	GetObject("itemRoot").GetObject("0").GetObject("removeItemBtnHelp").SetVisible(false);
}
function float GetTotalHeight()
{
	local int i, iMax;
	local float fH;
	local GFxObject gfxItem;

	iMax = AS_GetSize();
	for(i=0; i < iMax; ++i)
	{
		gfxItem = AS_GetItemAt(i);
		if(gfxItem != none)
		{
			fH = fH + AS_GetItemHeight(gfxItem);
			fH += 10.0;
		}
	}
	return fH;
}
function int AS_GetSize()
{
	return ActionScriptInt("getSize");
}
function AS_RealizePositions()
{
	ActionScriptVoid("realizePositions");
}
function AS_Clear()
{
	ActionScriptVoid("clear");
}
function float AS_GetItemHeight(GFxObject kO)
{
	return kO.GetFloat("_height");
}
function GfxObject AS_GetItemAt(int i)
{
	return GetObject("itemRoot").GetObject(string(i));
}
DefaultProperties
{
}
