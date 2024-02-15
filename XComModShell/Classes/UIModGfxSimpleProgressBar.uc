class UIModGfxSimpleProgressBar extends GfxObject;

function BuildComponents()
{
	local UIModGfxTextField gfxBackground, gfxProgress, gfxTxt;

	gfxBackground = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self,"bg",0.0, 0.0, 100.0, 20.0, 1, class'UIModGfxTextField'));
	gfxProgress = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self,"progressBar",0.0, 0.0, 100.0, 20.0, 2, class'UIModGfxTextField'));
	gfxTxt = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self,"progressTxt",0.0, 0.0, 100.0, 20.0, 3, class'UIModGfxTextField'));

	gfxBackground.SetBool("background", true);
	gfxBackground.SetString("backgroundColor", "0xFF0000");
	
	gfxProgress.SetBool("background", true);
	gfxProgress.SetString("backgroundColor", "0x" $ class'UIUtilities'.const.NORMAL_HTML_COLOR);

	gfxTxt.m_sFontColor="0xFFFFFF";
	gfxTxt.m_FontSize=16.0;
	gfxTxt.m_sTextAlign="center";
	gfxTxt.RealizeFormat();
}
function SetWidth(float fNewWidth)
{
	GetObject("bg").SetFloat("_width", fNewWidth);
	GetObject("progressBar").SetFloat("_width", fNewWidth);
	GetObject("progressTxt").SetFloat("_width", fNewWidth);
}
function SetHeight(float fNewHeight)
{
	GetObject("bg").SetFloat("_height", fNewHeight);
	GetObject("progressBar").SetFloat("_height", fNewHeight);
	GetObject("progressTxt").SetFloat("_height", fNewHeight);
}
function SetBackgroundVisibility(bool bVisible)
{
	GetObject("bg").SetBool("background", bVisible);
}
function SetBackgroundColor(string strColorHex)
{
	GetObject("bg").SetString("backgroundColor", strColorHex);
}
function SetBorderVisibility(bool bVisible, optional string strColor)
{
	GetObject("bg").SetBool("border", bVisible);
	if(bVisible)
	{
		SetBorderColor(strColor != "" ? strColor : GetObject("progressBar").GetString("backgroundColor"));
	}
}
function SetBorderColor(string strColorHex)
{
	GetObject("bg").SetString("borderColor", strColorHex);
}
function SetProgressColor(string strColorHex)
{
	GetObject("progressBar").SetString("backgroundColor", strColorHex);
}
function SetProgress(float fPct)
{
	fPct = FClamp(fPct, 0.0, 1.0);
	GetObject("progressBar").SetFloat("_width", fPct * GetObject("bg").GetFloat("_width"));
}
function SetProgressTxt(string strInText)
{
	UIModGfxTextField(GetObject("progressTxt", class'UIModGfxTextField')).SetHTMLText(strInText);
}
function SetProgressTxtColor(string strColorHex)
{
	UIModGfxTextField(GetObject("progressTxt", class'UIModGfxTextField')).m_sFontColor=strColorHex;
	UIModGfxTextField(GetObject("progressTxt", class'UIModGfxTextField')).RealizeFormat();
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
DefaultProperties
{
}
