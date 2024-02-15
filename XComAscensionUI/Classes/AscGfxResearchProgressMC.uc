class AscGfxResearchProgressMC extends GfxObject;

var float FOCUS_BORDER_HEIGHT;
var float PROJECT_BUTTON_WIDTH;
var float PROJECT_BUTTON_HEIGHT;
var float PROGRESS_BAR_MAXWIDTH;
var int m_iCurrentProgressColorR;
var int m_iCurrentProgressColorG;
var int m_iCurrentProgressColorB;

function AS_SetResearchProgress(string strTitle, optional string strDescription, optional string strETA, optional float fPercentComplete=-1.0f)
{
	if(strTitle == "" && strDescription == "")
	{
		SetVisible(false);
	}
	if(strTitle == "")
	{
		GetObject("title").SetVisible(false);//this hides the horizontal yellow line, not just txt
	}
	else
	{
		GetObject("title").GetObject("txtField").SetString("text", strTitle);
		GetObject("title").GetObject("txtField").SetVisible(true);
	}
	SetVisible(true);
	if(strDescription != "")
	{
		if(strETA != "")
		{
			strDescription $= (" - " $ strETA);
		}
		UIModGfxButton(GetObject("editButton", class'UIModGfxButton')).AS_SetHTMLText("<p align=\'RIGHT\'>" $ strDescription $ "</p>");
	}
	else
	{
		UIModGfxButton(GetObject("editButton", class'UIModGfxButton')).AS_SetHTMLText("");
	}
	if(fPercentComplete > 0.0)
	{
		GetObject("editButton").GetObject("progressBar").SetFloat("_width", PROGRESS_BAR_MAXWIDTH * fPercentComplete);
	}
	else
	{
		GetObject("editButton").GetObject("progressBar").SetFloat("_width", 0.0);
	}
}
function AS_AttachEditButton(delegate<UIModUtils.del_OnReleaseCallback> fnEditButtonCallback, optional string strHelpIcon="Icon_A_X")
{
	local UIModGfxButton gfxButton;
	local GfxObject gfxProgressBar;
	local array<ASValue> arrParam;

	class'UIModUtils'.static.AS_BindMovie(self, "XComButton", "editButton");
	gfxButton = UIModGfxButton(GetObject("editButton", class'UIModGfxButton'));
	class'UIModUtils'.static.AS_OverrideClickButtonDelegate(gfxButton, fnEditButtonCallback);
	gfxButton.AS_SetStyle(2,,false); //no resizing to text
	gfxButton.SetPosition(-PROJECT_BUTTON_WIDTH - 150.0, 17.0);
	gfxButton.SetFloat("_width", PROJECT_BUTTON_WIDTH);
	gfxButton.SetFloat("_height", PROJECT_BUTTON_HEIGHT);
	gfxButton.SetFloat("textX", (PROGRESS_BAR_MAXWIDTH - PROJECT_BUTTON_WIDTH - 10.0));
	gfxButton.SetVisible(true);

	gfxProgressBar = class'UIModUtils'.static.AttachTextFieldTo(gfxButton, "progressBar",-3.0, 2.50, PROGRESS_BAR_MAXWIDTH, PROJECT_BUTTON_HEIGHT-15.0);
	arrParam.Add(1);
	arrParam[0].Type=AS_String;
	arrParam[0].s=class'UIModUtils'.static.AS_GetPath(gfxButton);
	gfxProgressBar.Invoke("setMask", arrParam);
	gfxProgressBar.SetBool("background", true);
	gfxButton.AS_SetIcon(strHelpIcon);
	gfxButton.GetObject("buttonHelpIcon").SetFloat("_x", gfxButton.GetObject("buttonHelpIcon").GetFloat("_x") - gfxButton.GetObject("buttonHelpIcon").GetFloat("_width") * 2);
	AS_SetColor(true);  //initializes default m_iProgressColorR,G,B
}
function DumpDisplayInfo(GfxObject kO)
{	
	LogInternal(kO @ kO.GetFloat("_width") @ kO.GetFloat("_height") @ kO.GetFloat("_xscale") @ kO.GetFloat("_yscale"));
	LogInternal(kO.GetObject("_parent") @ kO.GetObject("_parent").GetFloat("_width") @ kO.GetObject("_parent").GetFloat("_height") @ kO.GetObject("_parent").GetFloat("_xscale") @ kO.GetObject("_parent").GetFloat("_yscale"));
}
/**Provide new color R, G, B to be applied (default values for them can be set using AS_SetProgressColor).
 * @param bSetCustomColor Set to "true" and provide R, G, B or set to "false" to reset to originals (yellow).
 */
function AS_SetColor(bool bSetCustomColor, optional int R=m_iCurrentProgressColorR, optional int G=m_iCurrentProgressColorG, optional int B=m_iCurrentProgressColorB)
{
	local string strColorHex;

	if(bSetCustomColor)
	{
		strColorHex = class'UIModUtils'.static.GetHUD().ToFlashHex(MakeColor(R, G, B));
	}
	else
	{
		strColorHex = class'UIModUtils'.static.GetHUD().ToFlashHex(MakeColor(default.m_iCurrentProgressColorR, default.m_iCurrentProgressColorG, default.m_iCurrentProgressColorB));
	}
	GetObject("editButton").GetObject("progressBar").SetString("backgroundColor", strColorHex);
}
function AS_SetProgressColor(int R, int G, int B)
{
	m_iCurrentProgressColorR=R;
	m_iCurrentProgressColorG=G;
	m_iCurrentProgressColorB=B;
}
function AS_SetFocus(bool bHasFocus)
{
	local array<ASValue> arrVal;

	arrVal.Add(1);
	if(bHasFocus)
	{
		GetObject("editButton").Invoke("onReceiveFocus", arrVal);
	}
	else
	{
		GetObject("editButton").Invoke("onLoseFocus", arrVal);
	}

}
DefaultProperties
{
	FOCUS_BORDER_HEIGHT=40.0
	PROJECT_BUTTON_WIDTH=400.0
	PROJECT_BUTTON_HEIGHT=45.0
	PROGRESS_BAR_MAXWIDTH=386.0
	m_iCurrentProgressColorR=0
	m_iCurrentProgressColorG=128
	m_iCurrentProgressColorB=0
}
