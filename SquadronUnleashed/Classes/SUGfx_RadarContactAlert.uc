class SUGfx_RadarContactAlert extends GfxObject;

var UIModGfxTextField m_gfxOddsInfoText;
var UIModGfxTextField m_gfxTeamBuffsText;
var UIModGfxTextField m_gfxLeaderTitleText;
var UIModGfxTextField m_gfxEscortTitleText;
var UIModGfxTextField m_gfxEscortInfoText;
var UIModGfxSimpleShape m_gfxOddsInfoBox;
var UIModGfxSimpleShape m_gfxLeaderInfoBox;
var UIModGfxSimpleShape m_gfxLeaderFlag;

function SetupGfx()
{
	local float x, y, fArm;

	HideButton2();
	if(m_gfxOddsInfoBox == none)
	{
		m_gfxOddsInfoBox = UIModGfxSimpleShape(CreateEmptyMovieClip("oddsInfoBG",,class'UIModGfxSimpleShape'));
		m_gfxOddsInfoBox.DrawRoundedRectangle(360, 40, 0.25, true,,,true,0x67E8ED,3);
		m_gfxOddsInfoBox.SetPosition(450, 580);

		m_gfxOddsInfoText = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(m_gfxOddsInfoBox, "oddsInfoText",0,0,360,40,,class'UIModGfxTextField'));
		m_gfxOddsInfoText.m_sFontFace="$TitleFont";
		m_gfxOddsInfoText.m_sTextAlign="center";
		m_gfxOddsInfoText.m_FontSize=30.0;
		m_gfxOddsInfoText.RealizeFormat(true);
		m_gfxOddsInfoBox.SetVisible(false);
	}
	if(m_gfxLeaderInfoBox == none)
	{
		m_gfxLeaderInfoBox = UIModGfxSimpleShape(CreateEmptyMovieClip("leaderInfoBG",,class'UIModGfxSimpleShape'));
		m_gfxLeaderInfoBox.DrawRoundedRectangle(360, 60, 0.25, true,,,true,0x67E8ED,3);
		m_gfxOddsInfoBox.GetPosition(x, y);
		y -= 70.0;
		m_gfxLeaderInfoBox.SetPosition(x, y);

		m_gfxLeaderTitleText= UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(m_gfxLeaderInfoBox, "leaderTitleTF",0,0,360,30,,class'UIModGfxTextField'));
		m_gfxLeaderTitleText.m_sFontFace="$TitleFont";
		m_gfxLeaderTitleText.m_sTextAlign="center";
		m_gfxLeaderTitleText.m_FontSize=25.0;
		m_gfxLeaderTitleText.RealizeFormat(true);

		m_gfxTeamBuffsText = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(m_gfxLeaderInfoBox, "teamBuffsTF",0,30,360,30,,class'UIModGfxTextField'));
		m_gfxTeamBuffsText.m_sTextAlign="center";
		m_gfxTeamBuffsText.m_FontSize=21.0;
		m_gfxTeamBuffsText.m_sFontColor="0x" $ class'UIUtilities'.const.GOOD_HTML_COLOR;
		m_gfxTeamBuffsText.RealizeFormat(true);
		m_gfxTeamBuffsText.SetVisible(false);
	}
	if(m_gfxLeaderFlag == none)
	{
		m_gfxLeaderFlag = UIModGfxSimpleShape(CreateEmptyMovieClip("leaderFlagMC",,class'UIModGfxSimpleShape'));
		//drawing a pentagram star manually, lol :))
		fArm = 30;
		m_gfxLeaderFlag.AS_MoveTo(0,0);
		m_gfxLeaderFlag.AS_BeginFill(0xFFFF00);
		m_gfxLeaderFlag.AS_LineStyle(2, 0xFFFF00, 100);
		m_gfxLeaderFlag.AS_LineTo(fArm, 0);
		m_gfxLeaderFlag.AS_LineTo(fArm - fArm * Cos(Pi/5), fArm * Sin(Pi/5));
		m_gfxLeaderFlag.AS_LineTo(fArm / 2, -fArm / 2 * Tan(Pi/5));
		m_gfxLeaderFlag.AS_LineTo(fArm * Cos(Pi/5), fArm * Sin(Pi/5));
		m_gfxLeaderFlag.AS_LineTo(0,0);
		m_gfxLeaderFlag.AS_EndFill();
		x = fArm/2/Cos(Pi/5);
		m_gfxLeaderFlag.AS_MoveTo(x, 0);
		m_gfxLeaderFlag.AS_BeginFill(0xFFFF00);
		m_gfxLeaderFlag.AS_LineTo(fArm - (fArm-x)*Cos(Pi/5), -fArm / 2 * Tan(Pi/5) + x * Cos(Pi/10));
		m_gfxLeaderFlag.AS_LineTo(fArm / 2, fArm / 2 * Tan(Pi/5));
		m_gfxLeaderFlag.AS_LineTo((fArm-x)*Cos(Pi/5), -fArm / 2 * Tan(Pi/5) + x * Cos(Pi/10));
		m_gfxLeaderFlag.AS_LineTo(fArm-x, 0);
		m_gfxLeaderFlag.AS_LineTo(x, 0);
		m_gfxLeaderFlag.AS_EndFill();
		m_gfxLeaderFlag.SetVisible(false);
	}
	if(m_gfxEscortTitleText == none || m_gfxEscortInfoText == none)
	{
		m_gfxEscortTitleText = UIModGfxTextField( class'UIModUtils'.static.AttachTextFieldTo(self, "escortTitle", 104, 520, 275, 31,,class'UIModGfxTextField') );
			m_gfxEscortTitleText.m_sFontColor = "0xEE1C25";
			m_gfxEscortTitleText.m_sFontFace = "$TitleFont";
			m_gfxEscortTitleText.m_FontSize = 20;
			m_gfxEscortTitleText.m_bWordwrap = true;
			m_gfxEscortTitleText.m_bMultiline = true;
		m_gfxEscortInfoText = UIModGfxTextField( class'UIModUtils'.static.AttachTextFieldTo(self, "escortInfo", 116, 544, 275, 82,,class'UIModGfxTextField') );
			m_gfxEscortInfoText.m_sFontColor = "0x" $ class'UIUtilities'.const.WARNING_HTML_COLOR;
			m_gfxEscortInfoText.m_FontSize = 17;
			m_gfxEscortInfoText.m_bWordwrap = true;
			m_gfxEscortInfoText.m_bMultiline = true;
		GetObject("bgLeft").GetPosition(x, y);
		y -= 75;
		GetObject("bgLeft").SetPosition(x, y);
		GetObject("bgLeft").SetFloat("_yscale", 131.25);
	}
}
function SetOddsInfoText(string sNewText)
{
	if(m_gfxOddsInfoText == none)
	{
		SetupGfx();
	}
	m_gfxOddsInfoText.SetHTMLText(sNewText);
	m_gfxOddsInfoBox.SetVisible(sNewText != "");
}
function SetLeaderTitle(string sNewText)
{
	if(m_gfxLeaderTitleText == none)
	{
		SetupGfx();
	}
	m_gfxLeaderTitleText.SetHTMLText(sNewText);
	m_gfxLeaderTitleText.SetVisible(sNewText != "");
}
function SetTeamBuffsText(string sNewText)
{
	if(m_gfxTeamBuffsText == none)
	{
		SetupGfx();
	}
	m_gfxTeamBuffsText.SetHTMLText(sNewText);
	m_gfxTeamBuffsText.SetVisible(sNewText != "");
}
function SetEscortTitle(string sNewTitle)
{
	if(m_gfxEscortTitleText == none)
	{
		SetupGfx();
	}
	m_gfxEscortTitleText.SetHTMLText(sNewTitle);
	m_gfxEscortTitleText.SetVisible(sNewTitle != "");
}
function SetEscortInfo(string sNewText)
{
	if(m_gfxEscortInfoText == none)
	{
		SetupGfx();
	}
	m_gfxEscortInfoText.SetHTMLText(sNewText);
	m_gfxEscortInfoText.SetVisible(sNewText != "");
}
function HideButton2()
{
	if(GetObject("button_2") != none)
	{
		GetObject("button_2").SetVisible(false);
	}
}
function ShowToggleShipHelpIcon(int iShipCard, string strIcon)
{
	local GFxObject gfxIcon;

	gfxIcon = GetObject("shipListMC").GetObject("ship"$iShipCard).GetObject("btnHelpIcon");
	if(strIcon != "")
	{
		gfxIcon.SetPosition(-340, 20);
		gfxIcon.GetObject("theIcon").GotoAndPlay(strIcon);
		gfxIcon.SetVisible(true);
	}
	else
	{
		gfxIcon.SetVisible(false);
	}
}
function GfxObject CreateAmmoIndicatorFor(GFxObject gfxShipCardMC)
{
	local float x, y;
	local GFxObject gfxIndicator;
	local UIModGfxSimpleShape gfxSymbol;
	local UIModGfxTextField gfxTF;

	gfxIndicator = gfxShipCardMC.CreateEmptyMovieClip("ammoMC");
	gfxTF = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(gfxIndicator, "weapon1", 0, 0,,,,class'UIModGfxTextField'));
		gfxTF.m_FontSize=15.0;
		gfxTF.RealizeFormat();
		gfxTF.GetPosition(x, y);
	gfxSymbol = UIModGfxSimpleShape(gfxIndicator.CreateEmptyMovieClip("infinity1",,class'UIModGfxSimpleShape'));
		gfxSymbol.SetPosition(x, y+8);
		gfxSymbol.AS_LineStyle(1, 0x67e8ed);
		gfxSymbol.AS_MoveTo(0, 0);
		gfxSymbol.AS_LineTo(2, 0);
		gfxSymbol.AS_LineTo(10, 6);
		gfxSymbol.AS_LineTo(12, 6);
		gfxSymbol.AS_LineTo(14, 3);
		gfxSymbol.AS_LineTo(12, 0);
		gfxSymbol.AS_LineTo(10, 0);
		gfxSymbol.AS_LineTo(2, 6);
		gfxSymbol.AS_LineTo(0, 6);
		gfxSymbol.AS_LineTo(-2, 3);
		gfxSymbol.AS_LineTo(0, 0);
		
	gfxTF = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(gfxIndicator, "weapon2", 40, 0,,,,class'UIModGfxTextField'));
		gfxTF.m_FontSize=15.0;
		gfxTF.RealizeFormat();
		gfxTF.GetPosition(x, y);
	gfxSymbol = UIModGfxSimpleShape(gfxIndicator.CreateEmptyMovieClip("infinity2",,class'UIModGfxSimpleShape'));
		gfxSymbol.SetPosition(x, y+8);
		gfxSymbol.AS_LineStyle(1, 0x67e8ed);
		gfxSymbol.AS_MoveTo(0, 0);
		gfxSymbol.AS_LineTo(2, 0);
		gfxSymbol.AS_LineTo(10, 6);
		gfxSymbol.AS_LineTo(12, 6);
		gfxSymbol.AS_LineTo(14, 3);
		gfxSymbol.AS_LineTo(12, 0);
		gfxSymbol.AS_LineTo(10, 0);
		gfxSymbol.AS_LineTo(2, 6);
		gfxSymbol.AS_LineTo(0, 6);
		gfxSymbol.AS_LineTo(-2, 3);
		gfxSymbol.AS_LineTo(0, 0);
	
	return gfxIndicator;
}
function GfxObject CreateDistanceIndicatorFor(GFxObject gfxShipCardMC, bool bFirestorm)
{
	local GFxObject gfxIndicator;
	local UIModGfxTextField gfxTF;

	gfxIndicator = gfxShipCardMC.CreateEmptyMovieClip("distanceMC");
	gfxIndicator.SetPosition(-334, 119);

	gfxTF = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(gfxIndicator, "startCloseMC", -20, 0, 80, 20,,class'UIModGfxTextField'));
	gfxTF.m_FontSize = 15;
	gfxTF.m_sTextAlign="right";
	gfxTF.m_bWordwrap=false;
	gfxTF.RealizeProperties();
	gfxTF.SetHTMLText(class'SU_Utils'.static.GetDistanceToUFOstring(bFirestorm, true));
	gfxTF.SetVisible(false);

	gfxTF = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(gfxIndicator, "startBackMC", -20, 0, 80, 20,,class'UIModGfxTextField'));
	gfxTF.m_FontSize = 15;
	gfxTF.m_sTextAlign="right";
	gfxTF.m_bWordwrap=false;
	gfxTF.RealizeProperties();
	gfxTF.SetHTMLText(class'SU_Utils'.static.GetDistanceToUFOstring(bFirestorm, false));
	gfxTF.SetVisible(false);

	return gfxIndicator;
}
function SetShipAmmo(int iShip, int iWeapon, int iAmmo)
{
	local GFxObject gfxShipCard, gfxAmmoMC, gfxInfinity;
	local UIModGfxTextField gfxTF;

	gfxShipCard = GetObject("shipListMC").GetObject("ship"$iShip);
	gfxAmmoMC = gfxShipCard.GetObject("ammoMC");
	if(gfxAmmoMC == none)
	{
		gfxAmmoMC = CreateAmmoIndicatorFor(gfxShipCard);
	}
	gfxAmmoMC.SetPosition(-334, 102);
	gfxInfinity = gfxAmmoMC.GetObject("infinity"$iWeapon);
	gfxTF = UIModGfxTextField(gfxAmmoMC.GetObject("weapon"$iWeapon, class'UIModGfxTextField'));
	gfxTF.SetHTMLText(string(iAmmo));
	gfxTF.SetVisible(iAmmo > 0);
	gfxInfinity.SetVisible(iAmmo == -1);
}
function SetLeaderFlag(int iShip)
{
	local float fListX, fListY, fShipX, fShipY;

	if(m_gfxLeaderFlag == none)
	{
		SetupGfx();
	}
	GetObject("shipListMC").GetPosition(fListX, fListY); 
	GetObject("shipListMC").GetObject("ship"$iShip).GetPosition(fShipX, fShipY);
	m_gfxLeaderFlag.SetPosition(fListX + fShipX - 33, fListY + fShipY + 0.5 * GetObject("shipListMC").GetObject("ship"$iShip).GetFloat("_height"));
	m_gfxLeaderFlag.SetVisible(true);
}
function SetStartingDistance(int iShip, bool bClose, bool bFirestorm)
{
	local GFxObject gfxIndicator;

	gfxIndicator = GetObject("shipListMC").GetObject("ship"$iShip).GetObject("distanceMC");
	if(gfxIndicator == none)
	{
		gfxIndicator = CreateDistanceIndicatorFor(GetObject("shipListMC").GetObject("ship"$iShip), bFirestorm);
	}
	gfxIndicator.GetObject("startCloseMC").SetVisible(bClose);
	gfxIndicator.GetObject("startBackMC").SetVisible(!bClose);
	gfxIndicator.SetVisible(true);
}
function HideDistanceIndicator(int iShip)
{
	GetObject("shipListMC").GetObject("ship"$iShip).GetObject("distanceMC").SetVisible(false);
}
DefaultProperties
{
}
