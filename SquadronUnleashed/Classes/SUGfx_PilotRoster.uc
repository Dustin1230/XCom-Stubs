class SUGfx_PilotRoster extends GfxObject;

var SUGfx_HangarsList m_gfxHangarsMC;

function SetupHangarsList()
{
	m_gfxHangarsMC = SUGfx_HangarsList(GetObject("hangarsMC", class'SUGfx_HangarsList'));
	m_gfxHangarsMC.AS_SetRealizePositionsDelegate(m_gfxHangarsMC.RealizePositions);
	m_gfxHangarsMC.AS_SetContinentSelectionDelegate(m_gfxHangarsMC.delSetContinentSelection);
	m_gfxHangarsMC.SetFloat("padding", -20);
	GetObject("shipWeaponLabel").SetFloat("_x", -280.0);
	GetObject("shipStatusLabel").SetFloat("_x", -100.0);
}
function SetupButtonGfx(int iContinent, int iPilot, optional int iOverrideHeight=-1)
{
	local UIModGfxTextField gfxTxtField;
	local SUGfx_ShipListItem gfxButton;

	gfxButton =SUGfx_ShipListItem(m_gfxHangarsMC.m_aGfxContinents[iContinent].GetObject("theItems").GetObject(string(iPilot), class'SUGfx_ShipListItem'));
	if(iOverrideHeight != -1)
	{
		gfxButton.STATIC_HEIGHT = iOverrideHeight;
	}
	gfxButton.GetObject("theButton").SetFloat("_height", gfxButton.STATIC_HEIGHT);
	gfxButton.GetObject("theConsoleButton").SetFloat("_height", gfxButton.STATIC_HEIGHT);
	gfxButton.AS_SetGetHeightDelegate(gfxButton.GetHeightOverride);

	gfxTxtField = UIModGfxTextField(gfxButton.GetObject("shipField", class'UIModGfxTextField'));
	gfxTxtField.m_bMultiline=true;
	gfxTxtField.m_bAutoSize=true;
	gfxTxtField.RealizeProperties();
	gfxTxtField.SetFloat("_height", 67.0);
	gfxTxtField.SetFloat("_width", 360.0);
	gfxTxtField.SetFloat("_x", 20.0);
				
	gfxTxtField = UIModGfxTextField(gfxButton.GetObject("weaponField", class'UIModGfxTextField'));
	gfxTxtField.m_bMultiline=true;
	gfxTxtField.m_bAutoSize=true;
	gfxTxtField.RealizeProperties();
	gfxTxtField.SetFloat("_height", 67.0);
	gfxTxtField.SetFloat("_width", 360.0);
	gfxTxtField.SetFloat("_x", 280.0);

	gfxTxtField = UIModGfxTextField(gfxButton.GetObject("statusField", class'UIModGfxTextField'));
	gfxTxtField.m_bMultiline=true;
	gfxTxtField.m_bAutoSize=true;
	gfxTxtField.RealizeProperties();
	gfxTxtField.SetFloat("_height", 67.0);
	gfxTxtField.SetFloat("_width", 360.0);
	gfxTxtField.SetFloat("_x", 463.0);
}
function CacheContinent(SUGfx_ContinentList gfxContinentList)
{
	local int idx;

	idx = int(Split(gfxContinentList.GetString("_name"), "option", true));
	if(m_gfxHangarsMC.m_aGfxContinents.Length < idx + 1)
	{
		m_gfxHangarsMC.m_aGfxContinents.Length = idx + 1;
	}
	m_gfxHangarsMC.m_aGfxContinents[idx]=gfxContinentList;	
}
function SetSelection(int continentIndex, int shipIndex)
{
	SetFloat("selectedShipIndex", shipIndex);
	SetSelectedContinent(continentIndex);
	SetSelectedShip(shipIndex);
}
function SetSelectedShip(int iShipIndex)
{
	ActionScriptVoid("SetSelectedShip");
}
function SetSelectedContinent(int continentIndex)
{
	ActionScriptVoid("SetSelectedContinent");
}

function WakeScrollBar()
{
	local array<ASValue> params;

	return;
	params.Length=1;
	params[0].Type = AS_Number;
	params[0].n = 0;
	m_gfxHangarsMC.GetObject("scrollbar").Invoke("SetThumbAtPercent",params);
}
DefaultProperties
{
}