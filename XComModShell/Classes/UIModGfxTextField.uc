/** This is a helper class for easy manipulation of any TextField created from Unrealscript side.
 *  The main problem of such not-through-ActionScript-created text field is setting text format.
 *  The issue is that any use of GfxObject.SetText function or SetString("text", ...) removes any text formatting from text field.
 *  This makes the text format be reverted to black, 12, left-aligned text (rarely visible at all due to black background)
 *  */

class UIModGfxTextField extends GfxObject;

var float m_FontSize;
var float m_fRightMargin;
var float m_fLeftMargin;
var bool m_bHTML;
var bool m_bAutoSize;
var bool m_bMultiline;
var bool m_bWordwrap;
var bool m_bNoSelect;
var string m_sAutoSize;
/** Acceptable entries: "right", "left", "center"*/
var string m_sTextAlign;
/** Color hex string, defaults to "0x67E8ED" (xcom cyan)*/
var string m_sFontColor;
/** Acceptable entries: "$NormalFont", "$TitleFont"*/
var string m_sFontFace;
/** Defaults to FALSE. Automatically decreases font size of too long text to match the text field's width. Cannot bring the font size below 10.0*/
var bool m_bAutoFontResize;

/** Sets new text - both HTML and normal. Ensures correct formatting.*/
function SetHTMLText(string strText)
{
	AS_SetHTML(true);
	if(IsHTMLText(strText))
	{
		FormatTextForHTML(strText);
		SetString("htmlText", strText);
	}
	else
	{
		SetString("htmlText", strText);
		RealizeFormat();
	}
	if(m_bAutoFontResize)
	{
		AutoResizeFont();
	}
}
/** Adds compulsory "size", "color" and "face" attributes in the leading "<font ...>" block.*/
function FormatTextForHTML(out string strTxt)
{
	strTxt = "<FONT COLOR='#"$ Split(m_sFontColor,"0x",true) $"' SIZE='"$ int(m_FontSize) $"' FACE='"$ m_sFontFace $"'>"$ strTxt $"</FONT>";
	if(InStr(strTxt, "align",,true) < 0)
	{
		strTxt = "<p align='"$ m_sTextAlign $"'>"$ strTxt $"</p>";
	}
}

/** Applies all set properties related to text field, but not font properties or margins*/
function RealizeProperties()
{
	AS_SetHTML(m_bHTML);
	SetBool("multiline", m_bMultiline);
	SetBool("wordWrap", m_bWordwrap);
	if(m_sAutoSize != "")
	{
		SetString("autosize", m_sAutoSize);
	}
	else
	{
		SetBool("autosize", m_bAutoSize);
	}
	SetBool("noselect", m_bNoSelect);
}
/** Applies all font properties and right/left margin, but not field's properties
 *  @param bForNewText false - format existing text (reliable), true - format any new text afterwards (not reliable)
 *  */
function RealizeFormat(optional bool bForNewText=false)
{
	local GFxObject kTextFormat;

	kTextFormat = CreateObject("TextFormat");
	kTextFormat.SetString("font", m_sFontFace);
	kTextFormat.SetFloat("size", m_FontSize);
	kTextFormat.SetString("color", m_sFontColor);
	kTextFormat.SetString("align", m_sTextAlign);
	kTextFormat.SetFloat("leftMargin", m_fLeftMargin);
	kTextFormat.SetFloat("rightMargin", m_fRightMargin);
	if(bForNewText)
	{
		AS_SetNewTextFormat(kTextFormat);
	}
	else
	{
		AS_SetTextFormat(kTextFormat);
	}
}
/** Applies class-default font properties and right/left margin, but not the field's properties.
 *  @param bForNewText false - format existing text (reliable), true - format any new text afterwards (not reliable)
 *  */
function RealizeDefaultFormat(optional bool bForNewText=false)
{
	local GFxObject kTextFormat;

	kTextFormat = CreateObject("TextFormat");
	kTextFormat.SetString("font", default.m_sFontFace);
	kTextFormat.SetFloat("size", default.m_FontSize);
	kTextFormat.SetString("color", default.m_sFontColor);
	kTextFormat.SetString("align", default.m_sTextAlign);
	kTextFormat.SetFloat("leftMargin", default.m_fLeftMargin);
	kTextFormat.SetFloat("rightMargin", default.m_fRightMargin);
	if(bForNewText)
	{
		AS_SetNewTextFormat(kTextFormat);
	}
	else
	{
		AS_SetTextFormat(kTextFormat);
	}
}
/** Applies default class properties related to text field, but not font properties or margins*/
function RealizeDefaultProperties()
{
	AS_SetHTML(default.m_bHTML);
	SetBool("multiline", default.m_bMultiline);
	SetBool("wordWrap", default.m_bWordwrap);
	SetBool("autosize", default.m_bAutoSize);
	SetBool("noselect", default.m_bNoSelect);
}
function AutoResizeFont()
{
	local float fTextW, fW, fSize;
	local string  strText;

	strText = GetRawText();
	fTextW = AS_GetTextExtent(strText).GetFloat("width");
	fW = GetFloat("_width");
	fSize = AS_GetTextFormat().GetFloat("size");
	if(fTextW > fW - 10.0)
	{
		//the 10.0 offset is to ensure resizing of "perfect fits" which tend to be not that perfect actually
		fSize = FFloor(fSize * (fW - 10.0) / fTextW);
	}
	SetFontSize(fSize);

}
/** Sets font size inside TextFormat property. It will be respected by native Action Script.
 *  However, when using SetHTMLText helper function it will be overriden by m_FontSize property. 
 */
function SetFontSize(float fSize)
{
	local GfxObject kTextFormat;
	
	kTextFormat = AS_GetTextFormat();
	kTextFormat.SetFloat("size", fSize);
	AS_SetTextFormat(kTextFormat);
	AS_SetNewTextFormat(kTextFormat);
}
/**Returns "text" property after removing leading <font ...> and closing </font> blocks.*/
function string GetRawText()
{
	local string strFullText, strRawText;

	strFullText = GetText();
	if(IsHTMLText(strFullText))
	{
		FormatTextForHTML(strFullText);
		strRawText = Left(strFullText, InStr(strFullText, "</"));
		strRawText = Right(strRawText, Len(strRawText) - InStr(strRawText, ">", true) - 1);
	}
	else
	{
		strRawText = strFullText;
	}
	return strRawText;
}
static function bool IsHTMLText(string strTestText)
{
	return InStr(strTestText, "</") != -1;
}
function AS_SetHTML(bool bEnableHTML)
{
	SetBool("html", bEnableHTML);
}
function AS_SetNewTextFormat(GfxObject NewTextFormat)
{
	ActionScriptVoid("setNewTextFormat");
}
function AS_SetTextFormat(GfxObject NewTextFormat)
{
	ActionScriptVoid("setTextFormat");
}
function GfxObject AS_GetTextFormat()
{
	return ActionScriptObject("getTextFormat");
}
/** Returns width (in pixels) of provided strText respecting current TextFormat of the text field. 
 *  Useful to determine how much space the text will occupy or whether it fits the text field's width.
 */
function GfxObject AS_GetTextExtent(string strText)
{
	return AS_GetTextFormat().ActionScriptObject("getTextExtent");
}

DefaultProperties
{
	m_FontSize=20.0
	m_bHTML=true
	m_bAutoSize=true
	m_sAutoSize=""
	m_bWordwrap=true
	m_bMultiline=true
	m_bNoSelect=true;
	m_sFontColor="0x67E8ED"
	m_sTextAlign="left"
	m_sFontFace="$NormalFont"
}
