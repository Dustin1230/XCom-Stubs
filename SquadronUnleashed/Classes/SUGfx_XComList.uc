class SUGfx_XComList extends GfxObject;

var float START_PADDING;

delegate delRealizePostions();

function AS_SetRealizePositionsDelegate(delegate<delRealizePostions> fnCallback)
{
	ActionScriptSetFunction("realizePositions");
}
/**Override for VerticalContainer.realizePositions()*/
function RealizePositions()
{
	local GFxObject gfxItem;
	local int iStartIdx, iEndIdx, iDir, iItem; 
	local float fPadding, fCurrentY;
	local ASDisplayInfo tDisplay;
	local array<ASValue> arrParams;

	arrParams.Add(1);
	fPadding = GetFloat("padding");
	START_PADDING = GetFloat("startPadding");
	switch(int(GetFloat("align")))
	{
	case 1:
		//align bottom
		iStartIdx = int(GetObject("items").Invoke("getLength", arrParams).n) - 1;
		iEndIdx = -1;
		iDir = -1;
		fCurrentY = -START_PADDING;
		break;
	case 0:
		//align top
		iStartIdx = 0;
		iEndIdx = int(GetObject("items").Invoke("getLength", arrParams).n);
		iDir = 1;
		fCurrentY = START_PADDING;
		break;
	default:
		LogInternal("ERROR: VerticalContainer \'" $ GetString("_name") $ "\' has an unknown alignment: " $ int(GetFloat("align")));
		return;
	}
	iItem = iStartIdx;
	while(iItem != iEndIdx)
	{
        gfxItem = AS_GetItemAt(iItem);
		if(gfxItem != none)
		{
			if(iDir < 0)
			{
				fCurrentY -= (gfxItem.Invoke("getHeight", arrParams).n + fPadding);
			}
			tDisplay = gfxItem.GetDisplayInfo();
			tDisplay.Y = fCurrentY;
			gfxItem.SetDisplayInfo(tDisplay);
			if(iDir > 0)
			{
				fCurrentY += (gfxItem.Invoke("getHeight", arrParams).n + fPadding);
			}
		}
		iItem += iDir;
	}
	SetFloat("maxY", fCurrentY);
}
function GfxObject AS_GetItemAt(int i)
{
	local GfxObject gfxObj;

	gfxObj = GetObject("items").ActionScriptObject("getItemAt");
	if(gfxObj == none)
	{
		gfxObj = GetObject("itemRoot").GetObject(string(i));
	}
	return gfxObj;
}
function float AS_GetHeight()
{
	return ActionScriptFloat("getHeight");
}
function float AS_GetTotalHeight()
{
	return ActionScriptFloat("getTotalHeight");
}
function AS_AddListItem(int id, optional string sItemText="", optional bool bSelectFirstElement=false, optional bool bIsDisabled=false, optional string InitParams="undefined")
{
	ActionScriptVoid("AddListItem");
}
function AS_Clear()
{
	ActionScriptVoid("clear");
}
DefaultProperties
{
}
