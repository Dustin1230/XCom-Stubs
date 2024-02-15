class SUGfx_PilotCard extends GfxObject;

var bool m_bGfxReady;
var UIModGfxTextField m_gfxCareerLabel;

function ExtendGfx()
{
	AddButtons();
	AddSpinner();
	AddCareerLabel();
}
function AddButtons()
{
	local UIModGfxButton gfxNewButton;
	local ASDisplayInfo tDisplaySource;

	LogInternal(GetFuncName() @ "to" @ self);
	if(GetButton("button0") != none)
	{
		return;//buttons already added
	}
	class'UIModUtils'.static.AS_BindMovie(GetObject("theItemCard"), "XComButton", "button0");
	gfxNewButton = GetButton("button0");
	tDisplaySource = GetObject("theItemCard").GetObject("stat0").GetDisplayInfo();
	tDisplaySource.X += 30.0;
	gfxNewButton.SetDisplayInfo(tDisplaySource);
	gfxNewButton.SetFloat("MIN_WIDTH", 200.0);
	gfxNewButton.AS_SetStyle(1,,true);
	gfxNewButton.AS_SetIcon("Icon_Y_TRIANGLE");

	class'UIModUtils'.static.AS_BindMovie(GetObject("theItemCard"), "XComButton", "button1");
	gfxNewButton = GetButton("button1");
	tDisplaySource = GetObject("theItemCard").GetObject("stat2").GetDisplayInfo();
	tDisplaySource.X += 30.0;
	gfxNewButton.SetDisplayInfo(tDisplaySource);
	gfxNewButton.SetFloat("MIN_WIDTH", 200.0);
	gfxNewButton.AS_SetStyle(1,,true);
	gfxNewButton.AS_SetIcon("Icon_X_SQUARE");
	
	class'UIModUtils'.static.AS_BindMovie(GetObject("theItemCard"), "XComButton", "button2");
	gfxNewButton = GetButton("button2");
	tDisplaySource = GetObject("theItemCard").GetObject("stat4").GetDisplayInfo();
	tDisplaySource.X += 30.0;
	gfxNewButton.SetDisplayInfo(tDisplaySource);
	gfxNewButton.SetFloat("MIN_WIDTH", 200.0);
	gfxNewButton.AS_SetStyle(1,,true);
	gfxNewButton.AS_SetIcon("Icon_A_X");

}
function AddCareerLabel()
{
	m_gfxCareerLabel = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(GetObject("theItemCard"), "careerLabel", 0, 180, 200, 36,,class'UIModGfxTextField'));
	m_gfxCareerLabel.m_sTextAlign="center";
	m_gfxCareerLabel.m_sFontFace="$TitleFont";
	m_gfxCareerLabel.m_FontSize = 26.0;
	m_gfxCareerLabel.m_bHTML=true;
	m_gfxCareerLabel.RealizeFormat();
	m_gfxCareerLabel.RealizeProperties();
}
function AddSpinner()
{
	local GfxObject gfxComponentsMC;
	local array<ASValue> arrParams;
	local ASValue myParam;
	local float x, y;

	//the XComSpinner flash class is not present in gfxItemCard.swf so Components.swf must be loaded into a dedicated gfxObject
	if(GetObject("componentsMC") != none)
	{
		return;//spinner already added
	}
	gfxComponentsMC = CreateEmptyMovieClip("componentsMC");//create a placeholder for gfxComponents package
	GetButton("button1").GetPosition(x, y);
	gfxComponentsMC.SetPosition(x, y);
		myParam.Type = AS_String;
		myParam.s = "/ package/gfxComponents/Components"; //provide path to Components.swf
		arrParams.AddItem(myParam); //put the path into params array
	gfxComponentsMC.Invoke("loadMovie", arrParams);	//load Components.swf into careerSpinner movie clip
	gfxComponentsMC.SetVisible(false);
	class'SU_Utils'.static.PRES().SetTimer(0.05, true, 'PollForMovieLoaded', self);
}
/** Checks if the movie has finished loading*/
function PollForMovieLoaded()
{
	if(GetObject("componentsMC").GetObject("FxsComponentTestMC") != none)
	{
		class'SU_Utils'.static.PRES().ClearTimer(GetFuncName(), self);
		SetupCareerSpinner();
	}
}
function SetupCareerSpinner()
{
	local GfxObject gfxSpinner, gfxComponents;
	local array<ASValue> arrParams;
	local ASValue myParam;
	local ASDisplayInfo tDisplay;

	//hide unnecessary clips form Components.swf (we had loaded a whole bunch of widgets, lol)
	gfxComponents = GetObject("componentsMC").GetObject("FxsComponentTestMC");
	gfxComponents.GetObject("helpBarMC").SetVisible(false);
	gfxComponents.GetObject("checkBoxMC").SetVisible(false);
	gfxComponents.GetObject("checkBoxMC2").SetVisible(false);
	gfxComponents.GetObject("spinner1MC").SetVisible(false);
	gfxComponents.GetObject("spinner2MC").SetVisible(false);
	gfxComponents.GetObject("sliderMC").SetVisible(false);
	gfxComponents.GetObject("spinnerVerticalMC").SetVisible(false);
	gfxComponents.GetObject("iconButtonMC").SetVisible(false);
	class'UIModUtils'.static.AS_GetInstanceAtDepth(-16384+80, gfxComponents).SetVisible(false);
	class'UIModUtils'.static.AS_GetInstanceAtDepth(-16384+83, gfxComponents).SetVisible(false);
	
	//adjust spinner's position and size
	gfxSpinner = GetCareerSpinner();
	arrParams.Length=0;
	if(!gfxSpinner.GetBool("bIsLoaded"))
	{
		gfxSpinner.Invoke("onLoad", arrParams);
	}
		myParam.Type = AS_Number;
		myParam.n = 120.0;
		arrParams.AddItem(myParam);
		myParam.Type = AS_Boolean;
		myParam.b = true;
		arrParams.AddItem(myParam);
	gfxSpinner.Invoke("forceValueWidth", arrParams);
	
	tDisplay = gfxSpinner.GetDisplayInfo();
		tDisplay.x = 258;
		tDisplay.y = 175;
		tDisplay.XScale = 125;
		tDisplay.YScale = 125;
	gfxSpinner.SetDisplayInfo(tDisplay);
	
	tDisplay = gfxSpinner.GetObject("selectionHighlight").GetDisplayInfo();
		tDisplay.Alpha=0;//make highlight invisible
	gfxSpinner.GetObject("selectionHighlight").SetDisplayInfo(tDisplay);
	
	GetObject("componentsMC").SetVisible(true);
	m_bGfxReady = true;
}
function UIModGfxButton GetButton(string sButtonName)
{
	return UIModGfxButton(GetObject("theItemCard").GetObject(sButtonName, class'UIModGfxButton'));
}
function SetButonLabel(string sButtonName, string sNewLabel)
{
	GetButton(sButtonName).AS_SetHTMLText(sNewLabel);
}
function SetDisabled(string sButtonName)
{
	local array<ASValue> arrParams;

	arrParams.Length=1;
	GetButton(sButtonName).Invoke("disable", arrParams);
}
function SetEnabled(string sButtonName)
{
	local array<ASValue> arrParams;

	arrParams.Length=1;
	GetButton(sButtonName).Invoke("enable", arrParams);
}
function GfxObject GetCareerSpinner()
{
	return GetObject("componentsMC").GetObject("FxsComponentTestMC").GetObject("spinnerMC");
}
function SetCareerSpinnerValue(string sNewValue)
{
	GetCareerSpinner().ActionScriptVoid("setValue");
}
function AS_SetCardTitle(string sNewTitle)
{
	ActionScriptVoid("SetCardTitle");
}
/** @param iCardType 0-none, 1_Armor, 2_SoldierWeapon, 3-ShipWeapon, 4-Item, 5-SHIV, 6-MECSuit, 7-GeneMod, 8-Interceptor, 9-ShipModule, 10-Satellite, 11-MPCharacter*/
function AS_SetCardImage(string sImagePath, optional int iCardType=11)
{
	ActionScriptVoid("SetCardImage");
}
function SetCareerLabel(string sNewLabel)
{
	m_gfxCareerLabel.SetHTMLText(sNewLabel);
}
function ClearFlavorTxt()
{
	GetObject("cardDataContainer").ActionScriptVoid("clear");
}
DefaultProperties
{
}
