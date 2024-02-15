class SUGfx_AirforceCommand extends GfxObject;

var SUGfx_WidgetHelper m_gfxWidgetHelper;
var SUGfx_XComList m_gfxOptionsList;
var UIModGfxTextField m_gfxInfoField;
var UIModGfxTextField m_gfxTitleField;
var UIModGfxTextField m_gfxItemField;
var UIModGfxTextField m_gfxQuantityField;

var int m_iNumOptions;
var bool m_bAllItemsLoaded;

function OnLoad()
{
	m_gfxInfoField = UIModGfxTextField(GetObject("infoField", class'UIModGfxTextField'));
	m_gfxTitleField = UIModGfxTextField(GetObject("titleField", class'UIModGfxTextField'));
	m_gfxItemField = UIModGfxTextField(GetObject("itemField", class'UIModGfxTextField'));
	m_gfxQuantityField = UIModGfxTextField(GetObject("quantityField", class'UIModGfxTextField'));
	m_gfxOptionsList = SUGfx_XComList(GetObject("listMC", class'SUGfx_XComList'));
	SetObject("widgetHelper", CreateObject("WidgetHelper"));
	m_gfxWidgetHelper = SUGfx_WidgetHelper(GetObject("widgetHelper", class'SUGfx_WidgetHelper'));
	SetupGfx();
}
function ClearWidgets()
{
	local int i;
	local GFxObject gfxObj;
	local array<ASValue> arrParams;

	arrParams.Length=0;
	if(m_gfxOptionsList != none)
	{
		for(i=0; i < m_iNumOptions; ++i)
		{
			gfxObj = m_gfxOptionsList.AS_GetItemAt(i);
			if(gfxObj != none)
			{
				gfxObj.Invoke("removeMovieClip", arrParams);
			}
		}
	}
	m_iNumOptions=0;
	m_gfxOptionsList.ActionScriptVoid("clear");
}
function SetupGfx()
{
	local UIModGfxTextField gfxLabel;

	GetObject("catBg0").SetVisible(false);
	GetObject("catBg1").SetVisible(false);
	GetObject("catBg2").SetVisible(false);
	GetObject("cat0").SetVisible(true);
	GetObject("cat1").SetVisible(true);
	GetObject("cat2").SetVisible(false);
	GetObject("categorySeperator").SetVisible(true);//lol, SepErator :) 
	GetObject("titleField").SetVisible(true);
	GetObject("nameField").SetVisible(true);
	GetObject("infoField").SetVisible(true);
	GetObject("theConfirmButton").SetVisible(false);
	GetObject("itemField").SetVisible(true);
	GetObject("quantityField").SetVisible(true);
	GetObject("descriptionSeparator").SetVisible(true);
	GetObject("descFieldScrolling").SetVisible(true);
	GetObject("subHeaderLineBottom").SetVisible(false);
	GetObject("subHeaderLineTop").SetVisible(false);
	GetObject("bigMessage").SetVisible(false);
	gfxLabel = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(GetObject("cat0").GetObject("theButton"), "catLabel", 15.0, -20.0, 96.0, 20.0,,class'UIModGfxTextField'));
		gfxLabel.m_FontSize = 18.0;
		gfxLabel.m_sTextAlign = "center";
	gfxLabel = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(GetObject("cat1").GetObject("theButton"), "catLabel", 15.0, -20.0, 96.0, 20.0,,class'UIModGfxTextField'));
		gfxLabel.m_FontSize = 18.0;
		gfxLabel.m_sTextAlign = "center";
	gfxLabel = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(GetObject("cat2").GetObject("theButton"), "catLabel", 15.0, -20.0, 96.0, 20.0,,class'UIModGfxTextField'));
		gfxLabel.m_FontSize = 18.0;
		gfxLabel.m_sTextAlign = "center";

	gfxLabel = m_gfxTitleField;
		gfxLabel.m_sFontFace="$TitleFont";		
		gfxLabel.m_FontSize = 28.0;
		gfxLabel.m_sTextAlign = "left";
		gfxLabel.m_sFontColor="0xFF"$class'UIUtilities'.const.NORMAL_HTML_COLOR;
	gfxLabel = m_gfxItemField;
		gfxLabel.m_sFontFace="$TitleFont";		
		gfxLabel.m_FontSize = 22.0;
		gfxLabel.m_sTextAlign = "left";
		gfxLabel.m_sFontColor="0xFF"$class'UIUtilities'.const.GOOD_HTML_COLOR;
	gfxLabel = m_gfxQuantityField;
		gfxLabel.m_sFontFace="$TitleFont";		
		gfxLabel.m_FontSize = 22.0;
		gfxLabel.m_sTextAlign = "right";
		gfxLabel.m_sFontColor="0xFF"$class'UIUtilities'.const.GOOD_HTML_COLOR;
}
function LoadCategoryImg(int iButton, string imgPath)
{
	local GfxObject gfxButton, gfxNewImgMC;
	local array<ASValue> arrParams;
	local ASDisplayInfo tDisplayInfo;

	gfxButton = GetObject("cat" $ iButton).GetObject("theButton");
	if(gfxButton != none)
	{
		gfxNewImgMC = gfxButton.CreateEmptyMovieClip("catImg");
		arrParams.Length = 1;
		arrParams[0].Type = AS_String;
		arrParams[0].s = imgPath;
		gfxNewImgMC.Invoke("loadMovie", arrParams);
		tDisplayInfo = gfxNewImgMC.GetDisplayInfo();
		tDisplayInfo.XScale = 50.0;
		tDisplayInfo.YScale = tDisplayInfo.XScale;
		gfxNewImgMC.SetDisplayInfo(tDisplayInfo);
		class'UIModUtils'.static.AS_BindMouse(gfxNewImgMC);
		class'UIModUtils'.static.AS_AddMouseListener(gfxNewImgMC);
		gfxNewImgMC.SetVisible(true);
	}
}
function SetCategoryLabel(int iButton, string sLabel)
{
	local GfxObject gfxButton;

	gfxButton = GetObject("cat" $ iButton).GetObject("theButton");
	if(gfxButton != none)
	{
		UIModGfxTextField(gfxButton.GetObject("catLabel", class'UIModGfxTextField')).SetHTMLText(sLabel);
	}
}
function UpdateLayout(optional int iCategory)
{
	switch(iCategory)
	{
	case 0:
		SetLayout0();
		break;
	case 1:
		SetLayout1();
		break;
	case 2:
		SetLayout2();
		break;
	default:
		SetLayout0();
	}
}
function SetLayout0()
{
	local array<ASValue> arrParams;
	local GfxObject gfxWidget;

	ClearWidgets();
	gfxWidget =	NewWidget("XComSpinner");
		arrParams.Length=2;
		arrParams[0].Type=AS_Number;
		arrParams[0].n=60;
		arrParams[1].Type=AS_Boolean;
		arrParams[1].b=true;
		gfxWidget.Invoke("forceValueWidth", arrParams);
		gfxWidget.SetFloat("_x", 236);

	gfxWidget = NewWidget("XComCheckbox");
		gfxWidget.SetFloat("_x", 320);
		
	gfxWidget =	NewWidget("XComSpinner");
		arrParams.Length=2;
		arrParams[0].Type=AS_Number;
		arrParams[0].n=60;
		arrParams[1].Type=AS_Boolean;
		arrParams[1].b=true;
		gfxWidget.Invoke("forceValueWidth", arrParams);
		gfxWidget.SetFloat("_x", 236);

	gfxWidget =	NewWidget("XComSpinner");
		gfxWidget.Invoke("forceValueWidth", arrParams);
		gfxWidget.SetFloat("_x", 236);

	m_gfxOptionsList.SetFloat("padding", 10.0);
	m_gfxOptionsList.RealizePositions();
	UpdateWidgetHelper();
}
function SetLayout1()
{
	local int i;
	local GFxObject gfxWidget;
	local array<ASValue> arrParams;

	ClearWidgets();
	for(i=0; i < 3; ++i)
	{
		gfxWidget =	NewWidget("XComSpinner");
			arrParams.Length=2;
			arrParams[0].Type=AS_Number;
			arrParams[0].n=80;
			arrParams[1].Type=AS_Boolean;
			arrParams[1].b=true;
		gfxWidget.Invoke("forceValueWidth", arrParams);
		gfxWidget.SetFloat("_x", 216);
	}
	m_gfxOptionsList.SetFloat("padding", 10.0);
	m_gfxOptionsList.RealizePositions();
	UpdateWidgetHelper();
}
function SetLayout2()
{

}
function GfxObject NewWidget(optional string strWidgetClass="XComSpinner")
{
	local array<ASValue> arrParams;
	local GfxObject gfxObj;

	m_gfxOptionsList.SetString("listItemIdentifier", strWidgetClass);
	m_gfxOptionsList.AS_AddListItem(m_iNumOptions, "", false, false, "undefined");
	gfxObj = m_gfxOptionsList.AS_GetItemAt(m_iNumOptions);
	arrParams.Length=0;//just dummy init
	if(strWidgetClass != "XComCheckbox")
	{
		gfxObj.Invoke("onLoad", arrParams);
	}
	else
	{
		gfxObj.SetObject("defaultButtonMC", gfxObj.GetObject("buttonMC"));
		gfxObj.SetObject("readOnlyMC", gfxObj.GetObject("theButtonReadOnly"));
		gfxObj.SetFloat("textW", 500);
		gfxObj.SetFloat("textFieldStartX", gfxObj.GetObject("displayLabelField").GetFloat("_x"));
	}
	gfxObj.SetVisible(true);
	m_iNumOptions++;
	return gfxObj;
}
function UpdateWidgetHelper()
{
	local int i;

	for(i=0; i<m_iNumOptions; ++i)
	{
		SetObject("option"$i, m_gfxOptionsList.AS_GetItemAt(i));
	}
	m_gfxWidgetHelper.AS_InitWidgetHelper(self, m_iNumOptions, self);
}
function SetCategoryFocus(int iButton, optional bool bFocus=true)
{
	local int i;
	local GFxObject gfxTabButton;
	local ASDisplayInfo tD;

	for(i=0; i < 3; ++i)
	{
		gfxTabButton = GetObject("cat" $ i);
		tD = gfxTabButton.GetDisplayInfo();
		if(i == iButton)
		{
			gfxTabButton.GotoAndStopI(bFocus ? 2 : 1);
			tD.Alpha = bFocus ? 100 : 50;
		}
		else
		{
			gfxTabButton.GotoAndStopI(1);
			tD.Alpha = 50;
		}
		gfxTabButton.SetDisplayInfo(tD);
	}
}
DefaultProperties
{
}