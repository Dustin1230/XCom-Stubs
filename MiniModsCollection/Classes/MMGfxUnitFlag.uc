/**This clas is an interface to manipulate unit's flag visuals*/
class MMGfxUnitFlag extends GfxObject;

var UIModGfxTextField m_gfxAmmoTxtBox;
var MMGfxUnitHPBar m_gfxHPBar;
var float m_fHPBarWidth;

delegate del_SetHP(int iCurrent, int iMax, optional int iBase);
delegate del_SetHPPreview(optional int iPossibleDmg);
delegate del_SetCover(string State, bool bIsFlanked);

function UIModGfxTextField GetAmmoTxtBox()
{
	if(m_gfxAmmoTxtBox == none)
	{
		AttachAmmoTxtBox();
	}
	return m_gfxAmmoTxtBox;
}
function AttachAmmoTxtBox()
{
	m_gfxAmmoTxtBox = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self, "ammoTxtBox", 0, 0, 200, 24,,class'UIModGfxTextField'));
	m_gfxAmmoTxtBox.m_FontSize = 18;
	m_gfxAmmoTxtBox.SetVisible(false);
}
function MMGfxUnitHPBar GetHPBar()
{
	if(m_gfxHPBar == none)
	{
		AttachHPBar();
	}
	return m_gfxHPBar;
}
function AttachHPBar()
{
	m_gfxHPBar = MMGfxUnitHPBar(CreateEmptyMovieClip("HPBar",,class'MMGfxUnitHPBar'));
	if(GetBool("_isHuman"))
	{
		m_gfxHPBar.BORDER_COLOR_HEX = m_gfxHPBar.BORDER_COLOR_HEX_XCOM;
		m_gfxHPBar.DIVIDOR_COLOR_HEX = m_gfxHPBar.DIVIDOR_COLOR_HEX_XCOM;
		m_gfxHPBar.TXT_COLOR_STRING = m_gfxHPBar.TXT_COLOR_STRING_XCOM;
		m_gfxHPBar.BG_COLOR_STRING = m_gfxHPBar.BG_COLOR_STRING_XCOM;
		m_gfxHPBar.BASE_COLOR_STRING = m_gfxHPBar.BASE_COLOR_STRING_XCOM;
		m_gfxHPBar.ARMOR_COLOR_STRING= m_gfxHPBar.ARMOR_COLOR_STRING_XCOM;
		m_gfxHPBar.HP_ICON_COLOR_HEX = m_gfxHPBar.HP_ICON_COLOR_HEX_XCOM;
	}
	m_gfxHPBar.BuildComponents();
	m_gfxHPBar.SetVisible(true);
	m_gfxHPBar.SetPosition(22.35, -40.0 - m_gfxHPBar.BAR_HEIGHT);
	CoverIconMC().SetFloat("_y", m_gfxHPBar.GetFloat("_y") + 25.0 + GetHeightOf(m_gfxHPBar));
	AdjustBuffIndicatorsPositions();
}
function AdjustHitPointsBlockPosition()
{
	local ASDisplayInfo tD;

	if(m_gfxHPBar != none && m_gfxHPBar.GetBool("_visible"))
	{
		tD = HitPointsBlockMC().GetDisplayInfo();
		tD.Y = -65.0 + m_gfxHPBar.GetFloat("_y") + GetHeightOf(HitPointsBlockMC().GetObject("hitPoints"));
		HitPointsBlockMC().SetDisplayInfo(tD);
	}
}
function AdjustOverwatchIconPosition()
{
	local ASDisplayInfo tD;
	local GFxObject gfxOWicon;
	local float barX, barY;

	if(m_gfxHPBar != none && m_gfxHPBar.GetBool("_visible"))
	{
		m_gfxHPBar.GetPosition(barX, barY);
		gfxOWicon = OverwatchMC();
		tD = gfxOWicon.GetDisplayInfo();
		tD.Y = barY - GetHeightOf(gfxOWicon) / 2.0 - 16.0;
		gfxOWicon.SetDisplayInfo(tD);
	}
}
function AdjustBuffIndicatorsPositions()
{
	local GFxObject gfxBuff, gfxDebuff, gfxMoves;
	
	if(class'MiniModsTactical'.static.IsLWR())
	{
		return;//FIXME: check if LWX sneaks through
	}
	gfxBuff = BuffMC();
	gfxDebuff = DebuffMC();
	gfxMoves = RemainingMovesMC();
	//gfxCoverIcon = CoverIconMC();
	gfxBuff.SetFloat("_y", gfxMoves.GetFloat("_y") + gfxMoves.GetBool("_visible") ? (GetHeightOf(gfxMoves) + 10.0) : 5.0);
	gfxBuff.SetFloat("_x", gfxMoves.GetFloat("_x") + GetBool("_isHuman") ? 20.0 : 30.0);
	if(LWRBuffCountTxt() != none)
	{
		LWRBuffCountTxt().SetFloat("_y", gfxBuff.GetFloat("_y"));
		LWRBuffCountTxt().SetFloat("_x", gfxBuff.GetFloat("_x") + 2.0 + gfxBuff.GetFloat("_width"));
		gfxDeBuff.SetFloat("_x", LWRBuffCountTxt().GetFloat("_x") + 2.0 + LWRBuffCountTxt().GetFloat("_width"));
	}
	else
	{
		gfxDebuff.SetFloat("_x", gfxBuff.GetFloat("_x") + 20.0 + gfxBuff.GetFloat("_width"));
	}
	gfxDebuff.SetFloat("_y", gfxBuff.GetFloat("_y"));
	if(LWRDeBuffCountTxt() != none)
	{
		LWRDeBuffCountTxt().SetFloat("_y", gfxDebuff.GetFloat("_y"));
		LWRDeBuffCountTxt().SetFloat("_x", gfxDebuff.GetFloat("_x") + 2.0 + gfxDebuff.GetFloat("_width"));
	}
}
/** Redirects all flash "SetHitPoints" calls to del_SetHP*/
function SetHitPointsDelegate(delegate<del_SetHP> fnSetHP)
{
	ActionScriptSetFunction("SetHitPoints");
}
/** Redirects all flash "SetHitPointsPreview" calls to del_SetHPPreview*/
function SetHitPointsPreviewDelegate(delegate<del_SetHPPreview> fnSetHPPreview)
{
	ActionScriptSetFunction("SetHitPointsPreview");
}
function SetCoverDelegate(delegate<del_SetCover> fnSetCover)
{
	ActionScriptSetFunction("SetCover");
}

function float GetHeightOf(GfxObject gfxInObj)
{
	return gfxInObj.GetFloat("_height");
}
function float GetWidthOf(GFxObject gfxInObj)
{
	return gfxInObj.GetFloat("_width");
}
function GfxObject RemainingMovesMC()
{
	return GetObject("remainingMoves");
}
function GfxObject HitPointsBlockMC()
{
	return GetObject("hitPointsBlock");
}
function GfxObject CoverIconMC()
{
	return GetObject("coverStatusObj");
}
function GfxObject OverwatchMC()
{
	return GetObject("overwatchMC");
}
function GfxObject BuffMC()
{
	return GetObject("buffMC");
}
function GfxObject DebuffMC()
{
	return GetObject("debuffMC");
}
function UIModGfxTextField LWRBuffCountTxt()
{
    return UIModGfxTextField(GetObject("BuffBox", class'UIModGfxTextField'));
}
function UIModGfxTextField LWRDebuffCountTxt()
{
    return UIModGfxTextField(GetObject("DebuffBox", class'UIModGfxTextField'));
}

DefaultProperties
{
}
