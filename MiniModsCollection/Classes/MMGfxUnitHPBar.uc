class MMGfxUnitHPBar extends GFxObject
	config(ModCompactHP);

var config float BAR_WIDTH;
var config float BAR_HEIGHT;
var config float BORDER_THICKNESS;
var config int BORDER_COLOR_HEX;
var config int DIVIDOR_COLOR_HEX;
var config string BG_COLOR_STRING;
var config float BG_TRANSPARENCY;
var config string ARMOR_COLOR_STRING;
var config string BASE_COLOR_STRING;
var config string DMG_COLOR_STRING;
var config string HEAL_COLOR_STRING;
var config string TXT_COLOR_STRING;
var config int HP_ICON_COLOR_HEX;
var config string BG_COLOR_STRING_XCOM;
var config int BORDER_COLOR_HEX_XCOM;
var config int DIVIDOR_COLOR_HEX_XCOM;
var config string ARMOR_COLOR_STRING_XCOM;
var config string BASE_COLOR_STRING_XCOM;
var config string TXT_COLOR_STRING_XCOM;
var config int HP_ICON_COLOR_HEX_XCOM;
var config string ARMOR_COLOR_STRING_INACTIVE;
var config string BASE_COLOR_STRING_INACTIVE;
var config string TXT_COLOR_STRING_INACTIVE;
var config int HP_ICON_COLOR_HEX_INACTIVE;
var config bool SHOW_MAX_HP;
var UIModGfxTextField m_gfxBG;
var UIModGfxTextField m_gfxBaseHP;
var UIModGfxTextField m_gfxArmorHP;
var UIModGfxTextField m_txtHP;
var UIModGfxTextField m_gfxDmg;
var UIModGfxSimpleShape m_gfxBorder;
var UIModGfxSimpleShape m_gfxHPIcon;
var GFxObject m_gfxKillShotIcon;
var UIModGfxSimpleShape m_gfxCircleMask;

function BuildComponents()
{
	m_gfxBG = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self,"bg",0.0, 0.0, BAR_WIDTH, BAR_HEIGHT, 1, class'UIModGfxTextField'));
	class'UIModUtils'.static.ObjectMultiplyColor(m_gfxBG, 1.0, 1.0, 1.0, 0.40);
	m_gfxArmorHP = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self,"armorHP",0.0, 0.0, BAR_WIDTH, BAR_HEIGHT, 2, class'UIModGfxTextField'));
	m_gfxBaseHP = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self,"baseHP",0.0, 0.0, BAR_WIDTH, BAR_HEIGHT, 3, class'UIModGfxTextField'));
	m_gfxDmg = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self,"dmgPreview",0.0, 0.0, BAR_WIDTH, BAR_HEIGHT, 4, class'UIModGfxTextField'));
	m_gfxHPIcon = UIModGfxSimpleShape(CreateEmptyMovieClip("iconHP", 5, class'UIModGfxSimpleShape'));
	m_gfxKillShotIcon = CreateEmptyMovieClip("iconKill", 6);
	m_gfxCircleMask = UIModGfxSimpleShape(CreateEmptyMovieClip("circleMask",7, class'UIModGfxSimpleShape'));
	m_txtHP = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self,"textHP",BAR_HEIGHT * 0.75 + 5.0, 0, BAR_WIDTH - BAR_HEIGHT * 0.75 - 5.0, BAR_HEIGHT, 8, class'UIModGfxTextField'));
	m_gfxBorder = UIModGfxSimpleShape(CreateEmptyMovieClip("borderMC", 9, class'UIModGfxSimpleShape'));
	m_gfxBG.SetBool("background", true);
	m_gfxArmorHP.SetBool("background", true);
	m_gfxBaseHP.SetBool("background", true);
	m_gfxDmg.SetBool("background", true);
	m_gfxDmg.SetVisible(false);
	//	SetBgVisibility(true);

	m_txtHP.m_sFontColor=TXT_COLOR_STRING;
	m_txtHP.m_FontSize=BAR_HEIGHT * 0.75;
	m_txtHP.m_sTextAlign="left";
	m_txtHP.RealizeFormat();
	
	DrawBorder();
	ResetWidth();
	ResetHeight();
	RealizeColors();
}
function DrawBorder()
{
	local float fW;
	
	fW = BAR_WIDTH + BORDER_THICKNESS*2;
	m_gfxBorder.DrawRoundedRectangle(fW, BAR_HEIGHT,, false,,,true, BORDER_COLOR_HEX, BORDER_THICKNESS);
	m_gfxBorder.SetFloat("_x", -BORDER_THICKNESS/2);
	m_gfxBorder.AS_LineStyle(BORDER_THICKNESS, DIVIDOR_COLOR_HEX);
	m_gfxBorder.AS_MoveTo(fW * 0.25, 0);
	m_gfxBorder.AS_LineTo(fW * 0.25, fmax(1.0, BAR_HEIGHT/8));
	m_gfxBorder.AS_MoveTo(fW * 0.25, BAR_HEIGHT);
	m_gfxBorder.AS_LineTo(fW * 0.25, BAR_HEIGHT - fmax(1.0, BAR_HEIGHT/8));

	m_gfxBorder.AS_MoveTo(fW * 0.5, 0);
	m_gfxBorder.AS_LineTo(fW * 0.5, fmax(1.0, BAR_HEIGHT/8));
	m_gfxBorder.AS_MoveTo(fW * 0.5, BAR_HEIGHT);
	m_gfxBorder.AS_LineTo(fW * 0.5, BAR_HEIGHT - fmax(1.0, BAR_HEIGHT/8));

	m_gfxBorder.AS_MoveTo(fW * 0.75, 0);
	m_gfxBorder.AS_LineTo(fW * 0.75, fmax(1.0, BAR_HEIGHT/8));
	m_gfxBorder.AS_MoveTo(fW * 0.75, BAR_HEIGHT);
	m_gfxBorder.AS_LineTo(fW * 0.75, BAR_HEIGHT - fmax(1.0, BAR_HEIGHT/8));
}
function DrawHPIcon(optional int iColor=HP_ICON_COLOR_HEX)
{
	local array<ASValue> arrParams;
	local float fSize;
	
	arrParams.Length = 0;
	m_gfxHPIcon.Invoke("clear", arrParams);

	fSize = m_txtHP.m_FontSize *0.75;
	m_gfxHPIcon.AS_BeginFill(iColor);
	m_gfxHPIcon.AS_MoveTo(0, fSize/4);
	m_gfxHPIcon.AS_LineTo(fSize/4, fSize/4);
	m_gfxHPIcon.AS_LineTo(fSize/4, 0);
	m_gfxHPIcon.AS_LineTo(fSize/4*3, 0);
	m_gfxHPIcon.AS_LineTo(fSize/4*3, fSize/4);
	m_gfxHPIcon.AS_LineTo(fSize, fSize/4);
	m_gfxHPIcon.AS_LineTo(fSize, fSize/4*3);
	m_gfxHPIcon.AS_LineTo(fSize/4*3, fSize/4*3);
	m_gfxHPIcon.AS_LineTo(fSize/4*3, fSize);
	m_gfxHPIcon.AS_LineTo(fSize/4, fSize);
	m_gfxHPIcon.AS_LineTo(fSize/4, fSize/4*3);
	m_gfxHPIcon.AS_LineTo(0, fSize/4*3);
	m_gfxHPIcon.AS_LineTo(0, fSize/4);
	m_gfxHPIcon.AS_EndFill();
	m_gfxHPIcon.SetPosition((m_txtHP.GetFloat("_x") - fSize) / 2, (BAR_HEIGHT - fSize) / 2);
	SetupKillShotIcon(iColor);
}
function SetupKillShotIcon(optional int iColor=HP_ICON_COLOR_HEX)
{
	local array<ASValue> arrParams;
	local ASDisplayInfo tDinfo;

	if(m_gfxKillShotIcon.GetFloat("_width") == 0)
	{
		arrParams.Add(1);
		arrParams[0].Type = AS_String;
		arrParams[0].s = "img:///gfxMissionSummary.aliensKilled";
		m_gfxKillShotIcon.Invoke("loadMovie", arrParams);
		tDinfo = m_gfxKillShotIcon.GetDisplayInfo();
			tDinfo.Visible=false;
			tDinfo.XScale=20;
			tDinfo.YScale=20;
		m_gfxKillShotIcon.SetDisplayInfo(tDinfo);

		class'UIModUtils'.static.GetPresBase().SetTimer(0.20, false, 'InitKillShotIcon', self);
	}
	m_gfxKillShotIcon.SetFloat("_height", BAR_HEIGHT - BORDER_THICKNESS - 1);
	m_gfxKillShotIcon.SetFloat("_width", BAR_HEIGHT - BORDER_THICKNESS - 1);
	m_gfxKillShotIcon.SetFloat("_x", BORDER_THICKNESS + 1);
	m_gfxKillShotIcon.SetFloat("_y", (BAR_HEIGHT - BORDER_THICKNESS - m_gfxKillShotIcon.GetFloat("_height")) / 2);
	
	SetKillShotMaskAndSize();
}
function ResetWidth(optional float fNewWidth=BAR_WIDTH)
{
	m_gfxBG.SetFloat("_width", fNewWidth);
	m_gfxArmorHP.SetFloat("_width", fNewWidth);
	m_gfxBaseHP.SetFloat("_width", fNewWidth);
	m_gfxBorder.SetFloat("_width", fNewWidth);
	m_gfxDmg.SetFloat("_width", fNewWidth);
	//m_gfxBorder.SetFloat("_x", -BORDER_THICKNESS);
}
function ResetHeight(optional float fNewHeight=BAR_HEIGHT)
{
	m_gfxBG.SetFloat("_height", fNewHeight);
	m_gfxArmorHP.SetFloat("_height", fNewHeight);
	m_gfxBaseHP.SetFloat("_height", fNewHeight);
	m_gfxBorder.SetFloat("_height", fNewHeight);
	m_gfxDmg.SetFloat("_height", fNewHeight);
	//m_txtHP.SetFloat("_y", -5.0 - m_txtHP.GetFloat("_height"));
	//m_txtHP.SetFloat("_y", fNewHeight * 0.75 + 6);
}
function RealizeColors()
{
	SetBaseHPColor(BASE_COLOR_STRING);
	SetArmorHPColor(ARMOR_COLOR_STRING);
	SetBgColor(BG_COLOR_STRING);
	SetHPTxtColor(TXT_COLOR_STRING);
	SetDmgPreviewColor(DMG_COLOR_STRING);
	DrawHPIcon(HP_ICON_COLOR_HEX);
}
function SetBorderColor(int ColorHex)
{
	local array<ASValue> arrParams;
	
	arrParams.Length = 0;
	m_gfxBorder.Invoke("clear", arrParams);
	BORDER_COLOR_HEX = ColorHex;
	DrawBorder();
}
function SetBgVisibility(bool bVisible)
{
	m_gfxBG.SetBool("background", bVisible);
}
function SetBgColor(string strColorHex)
{
	m_gfxBG.SetString("backgroundColor", strColorHex);
	class'UIModUtils'.static.ObjectMultiplyColor(m_gfxBG, 1.0, 1.0, 1.0, FClamp(1.0 - BG_TRANSPARENCY, 0.0, 1.0));
}
function SetBaseHPColor(string strColorHex)
{
	m_gfxBaseHP.SetString("backgroundColor", strColorHex);
}
function SetArmorHPColor(string strColorHex)
{
	m_gfxArmorHP.SetString("backgroundColor", strColorHex);
}
function SetHPTxtColor(string strColorHex)
{
	m_txtHP.m_sFontColor = strColorHex;
	m_txtHP.RealizeFormat();
}
function SetDmgPreviewColor(string strColorHex)
{
	m_gfxDmg.SetString("backgroundColor", strColorHex);
}
function SetHPPct(float fPct)
{
	fPct = FClamp(fPct, 0.0, 1.0);
	m_gfxBaseHP.SetFloat("_width", fPct * BAR_WIDTH);
}
function SetArmorPct(float fPct)
{
	fPct = FClamp(fPct, 0.0, 1.0);
	m_gfxArmorHP.SetFloat("_width", fPct * BAR_WIDTH);
}
function SetBgPct(float fPct)
{
	fPct = FClamp(fPct, 0.0, 1.0);
	m_gfxBG.SetFloat("_width", fPct * BAR_WIDTH);
}
function SetDmgPct(float fPct)
{
	fPct = FClamp(fPct, 0.0, 1.0);
	m_gfxDmg.SetFloat("_width", fPct * BAR_WIDTH);
}
function SetHPTxt(string strInText)
{
	m_txtHP.m_bAutoFontResize=true;
	m_txtHP.SetHTMLText(strInText);
}
function AnimateDmgPreview()
{
	local ASDisplayInfo tD;

	tD = m_gfxDmg.GetDisplayInfo();
	if((int(tD.Alpha) % 4) < 2)
	{
		tD.Alpha = int(tD.Alpha) - 4;
		if(tD.Alpha < 0)
			tD.Alpha = 3;
	}
	else
	{
		tD.Alpha = int(tD.Alpha) + 4;
		if(tD.Alpha > 100)
			tD.Alpha = 100;
	}
	m_gfxDmg.SetDisplayInfo(tD);
}
function MakeVertical()
{
	local ASDisplayInfo tDisplay;

	tDisplay=GetDisplayInfo();
	tDisplay.hasRotation=true;
	tDisplay.Rotation=-0.50;
	SetDisplayInfo(tDisplay);
}
function MakeHorizontal()
{
	local ASDisplayInfo tDisplay;

	tDisplay=GetDisplayInfo();
	tDisplay.hasRotation=false;
	tDisplay.Rotation=0.0;
	SetDisplayInfo(tDisplay);
}
function Show()
{
	SetVisible(true);
}
function Hide()
{
	SetVisible(false);
}
function InitKillShotIcon()
{
	m_gfxCircleMask.DrawCircle(20,,,,0xffffff,,true,0xffffff);
	class'UIModUtils'.static.AS_SetMask(m_gfxCircleMask, m_gfxKillShotIcon);
	SetKillShotMaskAndSize();
	m_gfxCircleMask.SetVisible(false);
	m_gfxKillShotIcon.SetVisible(false);
}
function SetKillShotMaskAndSize()
{
	local float x, y, h, w;

	m_gfxKillShotIcon.GetPosition(x, y);
	h = m_gfxKillShotIcon.GetFloat("_height");
	w = m_gfxKillShotIcon.GetFloat("_width");
	m_gfxCircleMask.SetFloat("_height", h*0.82);
	m_gfxCircleMask.SetFloat("_width", w*0.82);
	m_gfxCircleMask.SetPosition(x + w*0.49, y + h*0.49);
}
defaultproperties
{
	//BAR_WIDTH=70
	//BAR_HEIGHT=15
	//BORDER_THICKNESS=2
	//BORDER_COLOR_HEX=0xF67420
	//DIVIDOR_COLOR_HEX=0xF67420
	//BG_COLOR_STRING="0xEE1C25"
	//TXT_COLOR_STRING="0xEE1C25"
	//ARMOR_COLOR_STRING="0xA09CD6"
	//BASE_COLOR_STRING="0xEE1C25"
	//TXT_COLOR_STRING_XCOM="0x67E8ED"
	//ARMOR_COLOR_STRING_XCOM="0xFFD038"
	//BASE_COLOR_STRING_XCOM="0x5CD16C"
	//ARMOR_COLOR_STRING_INACTIVE="0x888888"
	//BASE_COLOR_STRING_INACTIVE="0x444444"
	//TXT_COLOR_STRING_INACTIVE="0xCCCCCC"
}