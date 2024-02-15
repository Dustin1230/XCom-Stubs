/** A helper class to handle manipulation of soldierStats panel for Enhanced Tactical Info*/
class XHGfxSoldierStats extends GFxObject;

var bool m_bGfxReady;
var array<UIModGfxTextField> m_arrInfoBoxes;
var array<UIModGfxTextField> m_arrBoxExtensions;

function LineUpIcons(optional float fX)
{
	GetObject("xpIcon").SetFloat("_x", fX);
	GetObject("pxpIcon").SetFloat("_x", fX);
	GetObject("hpIcon").SetFloat("_x", fX + 150.0);
	GetObject("offIcon").SetFloat("_x", fX + 150.0);
	GetObject("mobIcon").SetFloat("_x", fX + 300.0);
	GetObject("defIcon").SetFloat("_x", fX + 300.0);
	GetObject("willIcon").SetFloat("_x", fX + 450);
	GetObject("drIcon").SetFloat("_x", fX + 450);

	fX = fX + 30.0;
	GetObject("xpText").SetFloat("_x", fX);
	GetObject("xpText").SetFloat("_y", GetObject("xpText").GetFloat("_y") + 2.0);
	GetObject("pxpText").SetFloat("_x", fX);
	GetObject("pxpText").SetFloat("_y", GetObject("pxpText").GetFloat("_y") + 2.0);
	GetObject("hpText").SetFloat("_x", fX + 150.0);
	GetObject("offText").SetFloat("_x", fX + 150.0);
	GetObject("mobText").SetFloat("_x", fX + 300.0);
	GetObject("defText").SetFloat("_x", fX + 300.0);
	GetObject("willText").SetFloat("_x", fX + 450.0);
	GetObject("drText").SetFloat("_x", fX + 450.0);
	
	m_bGfxReady=true;
}
function SetSoldierStats(string sXP, string sPsiXP, string sHP, string sAim, string sDef, string sMob, string sWill, string sDR)
{
	local string sMod;
	local int iChar;

	iChar = InStr(sHP, "|");
	if(iChar > 0)
	{
		sMod  = Split(sHP, "|", true);
		sHP   = Left(sHP, iChar);
	}
	GetObject("hpText").SetString("htmlText", sMod == "" ? sHP : sHP $ "<font color='#FFD038' size='16'> "$ sMod $ "</font>");

	sMod="";
	iChar = InStr(sAim, "|");
	if(iChar > 0)
	{	
		sMod  = Split(sAim, "|", true);
		sAim  = Left(sAim, iChar);
	}
	GetObject("offText").SetString("htmlText", sMod == "" ? sAim : sAim $ "<font color='#FFD038' size='16'> "$ sMod $ "</font>");

	sMod="";
	iChar = InStr(sDef, "|");
	if(iChar > 0)
	{	
		sMod  = Split(sDef, "|", true);
		sDef  = Left(sDef, iChar);
	}
	GetObject("defText").SetString("htmlText", sMod == "" ? sDef : sDef $ "<font color='#FFD038' size='16'> "$ sMod $ "</font>");

	sMod="";
	iChar = InStr(sMob, "|");
	if(iChar > 0)
	{	
		sMod  = Split(sMob, "|", true);
		sMob  = Left(sMob, iChar);
	}
	GetObject("mobText").SetString("htmlText", sMod == "" ? sMob : sMob $ "<font color='#FFD038' size='16'> "$ sMod $ "</font>");

	sMod="";
	iChar = InStr(sWill, "|");
	if(iChar > 0)
	{	
		sMod  = Split(sWill, "|", true);
		sWill = Left(sWill, iChar);
	}
	GetObject("willText").SetString("htmlText", sMod == "" ? sWill : sWill $ "<font color='#FFD038' size='16'> "$ sMod $ "</font>");

	if(sPsiXP == "")
	{
		GetObject("pxpIcon").SetVisible(false);
	}
	else
	{
		GetObject("pxpText").SetString("htmlText","<font color='#A09CD6' size='20'>"$ sPsiXP $ "</font>");
	}
	GetObject("xpText").SetString("htmlText", "<font color='#FFD038' size='20'>"$ sXP $ "</font>");
	GetObject("drText").SetString("htmlText", sDR);
}
function SetAlienStats(string sHP, string sAim, string sDef, string sMob, string sWill, string sDR)
{
	GetObject("xpIcon").SetVisible(false);
	GetObject("pxpIcon").SetVisible(false);
	class'UIModUtils'.static.ObjectMultiplyColor(GetObject("hpIcon"), 0.0, 0.0, 0.0);
	class'UIModUtils'.static.ObjectMultiplyColor(GetObject("offIcon"), 0.0, 0.0, 0.0);
	class'UIModUtils'.static.ObjectMultiplyColor(GetObject("defIcon"), 0.0, 0.0, 0.0);
	class'UIModUtils'.static.ObjectMultiplyColor(GetObject("mobIcon"), 0.0, 0.0, 0.0);
	class'UIModUtils'.static.ObjectMultiplyColor(GetObject("willIcon"), 0.0, 0.0, 0.0);
	class'UIModUtils'.static.ObjectMultiplyColor(GetObject("drIcon"), 0.0, 0.0, 0.0);
	class'UIModUtils'.static.ObjectAddColor(GetObject("hpIcon"), 238, 28, 37);
	class'UIModUtils'.static.ObjectAddColor(GetObject("offIcon"), 238, 28, 37);
	class'UIModUtils'.static.ObjectAddColor(GetObject("defIcon"), 238, 28, 37);
	class'UIModUtils'.static.ObjectAddColor(GetObject("willIcon"), 238, 28, 37);
	class'UIModUtils'.static.ObjectAddColor(GetObject("drIcon"), 238, 28, 37);
	class'UIModUtils'.static.ObjectAddColor(GetObject("mobIcon"), 238, 28, 37);
	GetObject("hpText").SetString("htmlText", "<font color='#EE1C25'>"$ sHP $ "</font>");
	GetObject("offText").SetString("htmlText", "<font color='#EE1C25'>"$ sAim $ "</font>");
	GetObject("defText").SetString("htmlText", "<font color='#EE1C25'>"$ sDef $ "</font>");
	GetObject("mobText").SetString("htmlText", "<font color='#EE1C25'>"$ sMob $ "</font>");
	GetObject("willText").SetString("htmlText", "<font color='#EE1C25'>"$ sWill $ "</font>");
	GetObject("drText").SetString("htmlText", "<font color='#EE1C25'>"$ sDR $ "</font>");
}
function AttachTextBoxes()
{
	local UIModGfxTextField gfxBox;
	local int i;
	local float x, y;

	x = GetObject("drText").GetFloat("_x") + GetObject("drText").GetFloat("_width") + 70.0;
	y = -30.0;
	for(i=0; i < 12; ++i)
	{
		if(i == 6)
		{
			x = x + 130.0;
			y = -30.0;
		}
		y = y + 18.0;
		gfxBox = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self, "InfoTextBox" $ m_arrInfoBoxes.Length, x, y, 100.0, 18.0,,class'UIModGfxTextField'));
//		gfxBox.SetBool("border", true);
//		gfxBox.SetString("borderColor", gfxBox.m_sFontColor);
		gfxBox.m_FontSize = 13.0;
		gfxBox.RealizeFormat();
		gfxBox.SetVisible(true);
		m_arrInfoBoxes.AddItem(gfxBox);
		gfxBox = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self, "InfoTextExt" $ (m_arrInfoBoxes.Length-1), x+100.0, y, 20.0, 18.0,,class'UIModGfxTextField'));
//		gfxBox.SetBool("border", true);
//		gfxBox.SetString("borderColor", gfxBox.m_sFontColor);
		gfxBox.m_FontSize = 13.0;
		gfxBox.m_sTextAlign="right";
		gfxBox.RealizeFormat();
		gfxBox.SetVisible(true);
		m_arrBoxExtensions.AddItem(gfxBox);
	}
}
function SetInfoText(int iBox, coerce string strInText)
{
	if(m_arrInfoBoxes.Length == 0)
	{
		AttachTextBoxes();
	}
	if(iBox < m_arrInfoBoxes.Length)
	{
		m_arrInfoBoxes[iBox].SetHTMLText(strInText);
	}
}
function SetInfoExtText(int iBox, coerce string strInText)
{
	if(m_arrBoxExtensions.Length == 0)
	{
		AttachTextBoxes();
	}
	if(iBox < m_arrBoxExtensions.Length)
	{
		m_arrBoxExtensions[iBox].SetHTMLText(strInText);
	}
}
function XComTacticalGRI GRI()
{
	return XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI);
}
function XGTacticalGameCore TACTICAL()
{
	return GRI().m_kGameCore;
}
function XComPresentationLayer PRES()
{
	return XComPresentationLayer(XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).m_Pres);
}
DefaultProperties
{
}
