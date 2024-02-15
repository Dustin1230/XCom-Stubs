class SUGfx_HangarsList extends SUGfx_XComList;

var array<SUGfx_ContinentList> m_aGfxContinents;

function RealizePositions()
{
	super.RealizePositions();
}
delegate delSetContinentSelection(int iSelectedContinent)
{
	local GFxObject gfxSelectedItem;
	local SUGfx_ContinentList gfxSelectedContinent;
	local float fThumbPercent, fItemY, fTopY, fBottomY, fOffset, fDiffToTop, fMaskHeight, fItemHeight;
	local int iSelectedItem;
	local array<ASValue> arrParams;

	iSelectedItem = GetObject("_parent").GetFloat("selectedShipIndex");
	gfxSelectedContinent = m_aGfxContinents[iSelectedContinent];
	gfxSelectedItem = gfxSelectedContinent.AS_GetItemAt(iSelectedItem);
	fItemY = gfxSelectedItem.GetFloat("_y");
	arrParams.Add(1);
	fItemHeight = gfxSelectedItem.Invoke("getHeight", arrParams).n;
	fTopY = gfxSelectedContinent.GetFloat("_y") + 40.0 + fItemY;
	fBottomY = fTopY + fItemHeight;
	fDiffToTop = fTopY - m_aGfxContinents[0].GetFloat("_y") + 0.01;
	fMaskHeight = GetObject("maskMC").GetFloat("_height");
	if(fBottomY > fMaskHeight)
	{
		fOffset = fBottomY - fMaskHeight;
		fThumbPercent = (fDiffToTop + fItemHeight) / AS_GetTotalHeight();
		AS_SetThumbAtPercent(fThumbPercent);
	}
	else if(fTopY < 0)
	{
		fOffset = fTopY - 50;
		fThumbPercent = (fDiffToTop - 40) / AS_GetTotalHeight();
		AS_SetThumbAtPercent(fThumbPercent);
	}
	SetFloat("startPadding", GetFloat("startPadding") - fOffset);
	RealizePositions();
}
function AS_SetContinentSelectionDelegate(delegate<delSetContinentSelection> fnCallback)
{
	ActionScriptSetFunction("SetContinentSelection");
}
function AS_SetThumbAtPercent(float fPercent)
{
	GetObject("scrollbar").ActionScriptVoid("SetThumbAtPercent");
}
DefaultProperties
{
}
