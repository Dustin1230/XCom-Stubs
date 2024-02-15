/**This class works just like an Action Script class - but from the Unreal side.
 * It handles all the gfx part of the mod manager just as Action Script does for other UI screens.
 */
class UIModGfxOptionsList extends GfxObject
	dependson(UIModUtils);

var UIFxsMovie manager;
var GfxObject m_gfxScrollbar;
var GfxObject m_gfxScrollTextUpArrow;
var GfxObject m_gfxScrollTextDownArrow;
var int m_iNumOptions;

/** Set by code. Helps bringing a combobox on top of other widgets*/
var int m_iHighestDepth;

/** Controls horizontal offset of the scrollbar vs the list box*/
var float SCROLLBAR_X_PADDING;

/** Controls vertical offset of the scrollbar*/
var float SCROLLBAR_Y_PADDING;

/** Controls height of the scrollbar (so it can be made shorter than the list)*/
var float SCROLLBAR_HEIGHT_PADDING;

/** Mask determines the visible area of the list*/
var float MASK_X_PADDING;
var float MASK_Y_PADDING;
var float MASK_HEIGHT_PADDING;

/** Controls the space between a widget and the right edge of the list's*/
var float ITEM_RIGHT_MARGIN_PADDING;

/** Anchor of the whole list*/
var float ANCHOR_X;
var float ANCHOR_Y;

/** Height adjustment (in pixels) of the list in relation the height of the whole menu window*/
var float HEIGHT_ADJUSTMENT_TO_PARENT;

/** Controls the width of the list as a fraction of the width of the menu (0 - 1.0)*/
var float WIDTH_SCALE_TO_PARENT;

/** Controls vertical space between the items on the list*/
var float ITEM_PADDING;

/** Controls the width of all widgets*/
var float SPINNER_FORCEWIDTH;

/** Fontsize of the items on the list*/
var float LABEL_FONTSIZE;

/** Controls the height of comboboxes (their original size is like twice too large)*/
var float COMBO_FORCEHEIGHT;

/** Controls the space between text and the widget*/
var float LABEL_TO_WIDGET_PADDING;

delegate OnScrollerCallback(GfxObject gfxScrolledField);

function Init(optional bool bWithScrollbar=true)
{
	manager = class'UIModUtils'.static.GetHUD();
	GetObject("itemRoot").SetObject("mask", GetObject("mask"));
	UpdateAnchorAndPadding();
	AttachDescriptionTextField();
	AttachVersionInfoDisplay();
	AttachScrollArrowHelpers();
	if(!manager.IsMouseActive())
	{
		AttachHelpIconTo(self, "helpIconMC").GotoAndPlay("Icon_RT_R2");
	}
	AS_BindMouse(GetObject("theListbox"));
	RegisterSetFocusDelegate(del_SetFocus);
	RegisterRealizePositionsDelegate(del_RealizePositions);
	RegisterGetTotalHeightDelegate(del_GetTotalHeight);
	RegisterOnScrollerDelegate(UpdateScrollArrowsState);
	UpdateScrollArrowsState();
	SetBool("hasScrollbar", bWithScrollbar);
	SetListBoxScale();
	SetMaskAndRootSize();
}
function UpdateAnchorAndPadding()
{
	SetFloat("padding", ITEM_PADDING);
	SetFloat("SCROLLBAR_X_PADDING", SCROLLBAR_X_PADDING); 	
	SetFloat("SCROLLBAR_Y_PADDING", SCROLLBAR_Y_PADDING); 	
	SetFloat("SCROLLBAR_HEIGHT_PADDING", SCROLLBAR_HEIGHT_PADDING); 	
	SetFloat("MASK_X_PADDING", MASK_X_PADDING); 	
	SetFloat("MASK_Y_PADDING", MASK_Y_PADDING); 	
	SetFloat("MASK_HEIGHT_PADDING", MASK_HEIGHT_PADDING); 	
	SetFloat("ITEM_RIGHT_MARGIN_PADDING", ITEM_RIGHT_MARGIN_PADDING); 	
	SetPosition(ANCHOR_X, ANCHOR_Y);
	SetFloat("_height", GetObject("_parent").GetFloat("_height") + HEIGHT_ADJUSTMENT_TO_PARENT);
	SetFloat("_width", GetObject("_parent").GetFloat("_width") * WIDTH_SCALE_TO_PARENT);
}
function SetListBoxScale()
{
	GetObject("listbox").SetFloat("_xscale", GetFloat("_xscale"));
	GetObject("listbox").SetFloat("_yscale", GetFloat("_yscale"));
	if(GetBool("hasScrollbar"))
	{
		AS_EnableScrollbar("XComScrollbar");
		m_gfxScrollbar = GetObject("scrollbar");
	}
}
function SetMaskAndRootSize()
{
	AS_SetMaskAndRootSize();
	//ensure correct _x anchor for the widgets'
	GetObject("itemRoot").SetFloat("_x", GetObject("listbox").GetFloat("_x"));
}
function UIModGfxButton AttachConfigOptionButton(GFxObject gfxWidget, delegate<UIModUtils.del_OnReleaseCallback> fnCallback)
{
	local UIModGfxButton kButton;

	kButton = UIModGfxButton(class'UIModUtils'.static.BindMovie(gfxWidget, "XComButton", "configButton", class'UIModGfxButton'));
	if(kButton != none)
	{
		kButton.SetVisible(true);
		kButton.SetFloat("_x",kButton.GetFloat("_x") + 100.0);
		kButton.AS_SetStyle(2);
		kButton.AS_SetIcon("Icon_A_X");
		class'UIModUtils'.static.AS_OverrideClickButtonDelegate(kButton, fnCallback);
	}
	return kButton;
}
function AttachDescriptionTextField()
{
	local GFxObject kDescField;
	local UIModGfxTextField kTextBox;
	local string strGfxPath;
	local float fX, fFreeSpace;

	//calc the space of main window not occupied by the list (accounting for initial x offset)
	fFreeSpace = GetObject("_parent").GetFloat("_width") - GetFloat("_width");
	fX = GetFloat("_width") +  5.0;
	
	//draw new border by duplicating the border of existing list (.theListbox) and give it the name "descBG"
	strGfxPath = class'UIModUtils'.static.AS_GetPath(self);
	strGfxPath $= ".theListbox";
	kDescField = class'UIModUtils'.static.AS_DuplicateMovieClip(strGfxPath, "descBG");
	
	//tune the size of new border
	kDescField.SetFloat("_height", GetFloat("_height"));
	kDescField.SetFloat("_width", fFreeSpace);
	
	//flip the border horizontally for better visual fitting (by reverting _xcale to negative)
	kDescField.SetFloat("_xscale", -kDescField.GetFloat("_xscale"));
	
	//adjust _x offset of the flipped border  
	kDescField.SetFloat("_x", fX + kDescField.GetFloat("_width"));

	//add a text field
	kTextBox = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(self, "descText", fX + 15.0, 18.0, fFreeSpace - 25.0, kDescField.GetFloat("_height") - 35.0,, class'UIModGfxTextField'));
	kTextBox.m_fRightMargin=40.0;
	kTextBox.RealizeFormat(true);
	
	//kTextBox.SetText("A description of a mod or of an option will appear here as set by mod author. Currently this line is just long enough to test width limits, word wrapping and margins.\nBackground \nChance \nDone \nEventually \nFor \nGenuine \nHumble \nImmediately \nJust \nKnown \nMusic \nNew \nOverwatch \nPossible \nQueue \nReaction \nSuppression \nTurn \nUltimate \nVisible \nWorld");
}
function GfxObject AttachHelpIconTo(GfxObject kAttachToObject, string strNewName)
{
	local GfxObject gfxReturnMC, kTextFormat; 
	local UIModGfxTextField	gfxText;

	gfxReturnMC = class'UIModUtils'.static.AS_BindMovie(kAttachToObject, "GamepadIcons", strNewName);
	gfxText = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(gfxReturnMC, "helpIcon_txt", 25.0, -2.0, 60.0, 20.0,,class'UIModGfxTextField'));
	gfxText.SetBool("wordWrap", false);
	kTextFormat = CreateObject("TextFormat");
	kTextFormat.SetString("align", "center");
	kTextFormat.SetString("color", "0x" $ class'UIUtilities'.const.NORMAL_HTML_COLOR);
	kTextFormat.SetFloat("size", 13.0);
	kTextFormat.SetString("font", "$NormalFont");
	gfxText.AS_SetNewTextFormat(kTextFormat);
	gfxText.SetBool("border",true);
	gfxText.SetString("borderColor", "0x" $ class'UIUtilities'.const.NORMAL_HTML_COLOR);
	gfxText.SetText(class'UIModShell'.default.m_strGamepadScrollHelp);
	return gfxReturnMC;
}
function UIModGfxTextField AttachVersionInfoDisplay()
{
	local UIModGfxTextField gfxTextField;
	local string strParentPath;
	
	strParentPath = class'UIModUtils'.static.AS_GetPath(GetObject("_parent").GetObject("_parent"));
	gfxTextField = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(manager.GetVariableObject(strParentPath), "versionTxt",0.0,0.0,300.0,20.0,,class'UIModGfxTextField'));
	class'UIModUtils'.static.ObjectMultiplyColor(gfxTextField,1.0,1.0,1.0,0.50);
	gfxTextField.SetFloat("_x", 970.0);
	gfxTextField.m_FontSize=12.0;
	gfxTextField.m_sTextAlign="right";
	gfxTextField.m_bAutoSize=true;
	gfxTextField.RealizeProperties();
	return gfxTextField;
}
function AttachScrollArrowHelpers()
{
	local GFxObject gfxArrow;
	local ASDisplayInfo tDisplay;
	local float fX, fY;


	GetObject("descBG").GetPosition(fX, fY);
	gfxArrow = class'UIModUtils'.static.AS_BindMovie(self, "spinner button vertical", "textUpArrow");
	tDisplay = gfxArrow.GetDisplayInfo();
	tDisplay.XScale = 50.0;
	tDisplay.Rotation = 270.0;
	tDisplay.X = fX - GetObject("descBG").GetFloat("_width") / 2.0 - 10.0;
	tDisplay.Y = fY + gfxArrow.GetFloat("_width") - 8.0;
	gfxArrow.SetDisplayInfo(tDisplay);
	gfxArrow.SetVisible(true);
	m_gfxScrollTextUpArrow = gfxArrow;

	gfxArrow = class'UIModUtils'.static.AS_BindMovie(self, "spinner button vertical", "textDownArrow");
	tDisplay = gfxArrow.GetDisplayInfo();
	tDisplay.XScale = 50.0;
	tDisplay.Rotation = 90.0;
	tDisplay.X = fX - GetObject("descBG").GetFloat("_width") / 2.0 + gfxArrow.GetFloat("_height") - 12.0;
	tDisplay.Y = fY + GetObject("descText").GetFloat("_height") + 7.0;
	gfxArrow.SetDisplayInfo(tDisplay);
	gfxArrow.SetVisible(true);
	m_gfxScrollTextDownArrow = gfxArrow;
}
function UpdateScrollArrowsState(optional GfxObject gfxTextField)
{
	local int iScroll, iMaxScroll;

	if(gfxTextField == none)
	{
		gfxTextField = GetObject("descText");
	}
	iScroll = int(gfxTextField.GetString("scroll"));
	iMaxScroll = int(gfxTextField.GetString("maxscroll"));
	m_gfxScrollTextDownArrow.SetVisible(iMaxScroll > 1 && iScroll < iMaxScroll);
	m_gfxScrollTextUpArrow.SetVisible(iMaxScroll > 1 && iScroll > 1);
}
function UpdatePanelFocusHelp(bool bFocusOnDescription)
{
	local float X, Y;
	local string strHelp;

	Y = -10.0;
	if(bFocusOnDescription)
	{
		X = -2.0;
		strHelp = class'UIModShell'.default.m_strGamepadBackToListHelp;
	}
	else
	{
		X = 928.0;
		strHelp = class'UIModShell'.default.m_strGamepadScrollHelp;
	}
	GetObject("helpIconMC").SetPosition(X, Y);
	GetObject("helpIconMC").GetObject("helpIcon_txt").SetText(strHelp);
}
function GfxObject AS_AddOption(optional string strWidgetClass="XComCheckBox")
{
	local ASValue myValue;
	local array<ASValue> myArray;
	local GFxObject gfxNewWidget;

	gfxNewWidget = class'UIModUtils'.static.BindMovie(GetObject("itemRoot"), strWidgetClass, string(m_iNumOptions));
		myArray.Length=0;
		myValue.Type=AS_Number;
		myValue.n=float(GetObject("items").GetObject("keys").GetString("length"));
		myArray.AddItem(myValue);
	gfxNewWidget.Invoke("setIndex", myArray);
	gfxNewWidget.SetObject("_container", self);
		myArray.Length = 0;
		myValue.Type=AS_String;
		myValue.s=string(m_iNumOptions);
		myArray.AddItem(myValue);
	if(IsSpinner(gfxNewWidget))
	{
		FormatSpinner(gfxNewWidget);
	}
	else if(IsSlider(gfxNewWidget))
	{
		FormatSlider(gfxNewWidget);
	}
	else if(IsCombobox(gfxNewWidget))
	{
		FormatDropdown(gfxNewWidget);
	}
	else if(IsCheckbox(gfxNewWidget))
	{
		FormatCheckBox(gfxNewWidget);
	}
	AS_ItemsAdd(string(m_iNumOptions), gfxNewWidget);
	GetObject("navigator").Invoke("addOption", myArray);
	if(m_gfxScrollbar != none)
	{
		AS_ScrollboxNotifyItemsChanged();
	}
	myArray.Length=0;
	m_iHighestDepth = int(gfxNewWidget.Invoke("getDepth",myArray).n);
	m_iNumOptions++;
	return gfxNewWidget;
}

delegate del_SetFocus(string id)
{
	local GFxObject gfxItem;
	local array<ASValue> myArray;
	local float fHeight;
	local bool bNearEndOfListItem;

	bNearEndOfListItem = int(id) >= m_iNumOptions - 3;
	myArray.Add(1); //this is just a dummy for Invoke calls

//	this.focusCacheId = id
	SetString("focusCacheId", id);
//	var _loc2_ = this.items.getItem(id)
	gfxItem = AS_GetItem(id);
//	if(_loc2_ == undefined)
	if(gfxItem == none)
	{
//	    return undefined;
		return;
	}
//	 if(this.focus != _loc2_)
	if(GetObject("focus") != gfxItem)
	{
//      this.navigator.setSelected(this.navigator.getIndex(id));
		AS_navigatorSetSelected( AS_navigatorGetIndex(id) );
//      if(this.focus != undefined)
		if(GetObject("focus") != none)
		{
//      this.focus.onLoseFocus();
			GetObject("focus").Invoke("onLoseFocus",  myArray);
			SetFocusFX(GetObject("focus"), false);
		}
//      this.focus = _loc2_;
		SetObject("focus", gfxItem);
//      this.focus.onReceiveFocus();
		GetObject("focus").Invoke("onReceiveFocus", myArray);
//      if(this.scrollbar != undefined)
		if(m_gfxScrollbar != none)
		{
//          var _loc3_ = this.displayHeight - this.getTotalHeight();
			fHeight = GetFloat("displayHeight") - AS_GetTotalHeight();
//          if(_loc2_._y < 0)
			if(gfxItem.GetFloat("_y") < 0.0)
			{
//              this.SetWindow((this.startPadding - _loc2_._y) / _loc3_);
				AS_SetWindow((GetFloat("startPadding") - gfxItem.GetFloat("_y")) / fHeight);
			}
//          else if(_loc2_._y + _loc2_.getHeight() > this.displayHeight)
			else if((gfxItem.GetFloat("_y") + GetItemDisplayHeight(gfxItem, bNearEndOfListItem)) > GetFloat("displayHeight"))
			{
				AS_SetWindow(FMin(1.0, (GetFloat("startPadding") - (gfxItem.GetFloat("_y") + GetItemDisplayHeight(gfxItem, bNearEndOfListItem) + GetFloat("padding") - GetFloat("displayHeight"))) / fHeight));
			}
//          this.scrollbar.NotifySelectedIndexChanged();
			AS_ScrollboxNotifySelectedIndexChanged();
		}
	}
	else
	{
//      caurina.transitions.Tweener.removeTweens(this.focus);
		AS_RemoveTweens(GetObject("focus"));
	}
//  caurina.transitions.Tweener.removeTweens(this);
	AS_RemoveTweens(self);
//  if(this.leftToLoadCount == 0)
	if(int(GetFloat("leftToLoadCount")) == 0)
	{
		del_RealizePositions();
	}
	SetFocusFX(gfxItem, true);

	FixWidgetLabelFontSize(gfxItem);
}
function SetFocusFX(GfxObject kO, bool bHasFocus)
{
	local GfxObject gfxTextField;

	if(IsCheckbox(kO))
	{
		gfxTextField = kO.GetObject("displayLabelField");
	}
	else if(IsCombobox(kO))
	{
		gfxTextField = kO.GetObject("theButton").GetObject("labelText");
	}
	else
	{
		gfxTextField = kO.GetObject("displayLabel");
	}
	if(bHasFocus)
	{
		gfxTextField.SetString("backgroundColor", "0x" $ class'UIUtilities'.const.NORMAL_HTML_COLOR);
		gfxTextField.SetString("textColor", "0x000000");
		gfxTextField.SetBool("background", true);
	}
	else
	{
		gfxTextField.SetString("backgroundColor", "0x000000");
		gfxTextField.SetString("textColor", "0x" $ class'UIUtilities'.const.NORMAL_HTML_COLOR);
		gfxTextField.SetBool("background", false);
	}
	if(!manager.IsMouseActive())
	{
		UpdatePanelFocusHelp(false);
	}
}
delegate del_RealizePositions()
{
	local float fX, fCurrentY;
	local int i, iLength;
	local GFxObject gfxItem;
	
	i = 0;
	iLength = AS_GetSize();
	fX = GetObject("itemRoot").GetFloat("_x") + 5.0;
	fCurrentY = GetFloat("startPadding");
	while(i < iLength)
	{
		gfxItem = AS_GetItemAt(i);
		if(gfxItem != none)
		{
			if(IsCombobox(gfxItem))
			{
				gfxItem.SetFloat("_y", fCurrentY + 11.0 + ITEM_PADDING);
			}
			else
			{
				gfxItem.SetFloat("_y", fCurrentY);
			}
			if(IsCheckbox(gfxItem))
			{
				FormatCheckBox(gfxItem);
				if(gfxItem.GetFloat("textStyle") == 0)
				{
					gfxItem.SetFloat("_x", GetFloat("displayWidth") - 108.0 - SPINNER_FORCEWIDTH - GetFloat("ITEM_RIGHT_MARGIN_PADDING"));
				}
				else
				{
					gfxItem.SetFloat("_x", fX);
				}
			}
			else if(IsSpinner(gfxItem))
			{
				FormatSpinner(gfxItem);
				gfxItem.SetFloat("_x", GetFloat("displayWidth") - (CalcSpinnerWidth(gfxItem) + 40.0) - GetFloat("ITEM_RIGHT_MARGIN_PADDING"));
			}
			else if(IsSlider(gfxItem))
			{
				FormatSlider(gfxItem);
				gfxItem.SetFloat("_x", GetFloat("displayWidth") - (CalcSliderWidth(gfxItem) + 30.0) - GetFloat("ITEM_RIGHT_MARGIN_PADDING"));
			}
			else if(IsCombobox(gfxItem))
			{
				FormatDropdown(gfxItem);
				gfxItem.SetFloat("_x", GetFloat("displayWidth") - CalcComboWidth(gfxItem) - GetFloat("ITEM_RIGHT_MARGIN_PADDING"));
			}
			else
			{
				gfxItem.SetFloat("_x", fX);
			}
			fCurrentY = fCurrentY + GetItemDisplayHeight(gfxItem)  + GetFloat("padding");

			//if(IsCombobox(gfxItem))
			//{
			//	//fCurrentY = fCurrentY + gfxItem.GetObject("theButton").GetObject("theButton").GetFloat("_height") + GetFloat("padding");
			//}
			//else
			//{
			//	fCurrentY = fCurrentY + (gfxItem.GetFloat("_height") + GetFloat("padding"));
			//}	
		}
		if(m_gfxScrollbar != none)
		{
			//AS_ScrollboxResize();
		}
		i++;
	}
	SetFloat("maxY", fCurrentY); //probably irrelevant (no references found to maxY)
	if(m_gfxScrollbar != none)
	{
		AS_ScrollboxNotifySelectedIndexChanged();
	}
}
delegate float del_GetTotalHeight(optional int iStartIdx=0, optional int iEndIdx=m_iNumOptions)
{
	local int i;
	local float fH;
	local GFxObject gfxItem;
	local bool bOffsetForCombo;

	//iCurrentSelection = int(AS_GetWidgetHelper().GetFloat("iSelected"));
	//fH = GetFloat("startPadding");
	for(i=0; i < m_iNumOptions; ++i)
	{
		gfxItem = AS_GetItemAt(i);
		if(gfxItem != none)
		{
			if(IsCombobox(gfxItem))
			{
				fH += 37.90;
				bOffsetForCombo = true;
			}
			else
			{
				fH = fH + AS_GetItemHeight(gfxItem);
			}
			fH += GetFloat("padding");
		}
	}
	if(bOffsetForCombo)
	{
		fH += 123.0;
	}
	return fH;
}
function bool IsCheckbox(GfxObject kObj)
{
	return (kObj.GetObject("theButton") != none && kObj.GetObject("theButton").GetObject("theCheck") != none);
}
function bool IsCombobox(GfxObject kObj)
{
	return kObj.GetObject("theListAnimator") != none;
}
function bool IsSpinner(GFxObject kObj)
{
	return kObj.GetObject("displayValue") != none;
}
function bool IsSlider(GfxObject kObj)
{
	return kObj.GetObject("tickMC") != none;

}
function FixWidgetLabelFontSize(GfxObject kWidget)
{
	local UIModGfxTextField kTextField;

	if(IsCheckbox(kWidget))
	{
		kTextField = UIModGfxTextField(kWidget.GetObject("displayLabelField", class'UIModGfxTextField'));
	}
	else if(IsCombobox(kWidget))
	{
		kTextField = UIModGfxTextField(kWidget.GetObject("theButton").GetObject("labelText", class'UIModGfxTextField'));
	}
	else
	{
		kTextField = UIModGfxTextField(kWidget.GetObject("displayLabel", class'UIModGfxTextField'));
	}
	kTextField.AutoResizeFont();
}
function FormatCheckBox(GFxObject kBox)
{
	if(int(kBox.GetFloat("textStyle")) == 0)
	{
		//textStyle 0 is used for the list of mods, when box is to the left, hence longer text can be allowed
		kBox.GetObject("displayLabelField").SetFloat("_x", CalcTextFieldX(kBox));
		kBox.GetObject("displayLabelField").SetFloat("_width", CalcTextFieldWidth(kBox));
	}
	FixWidgetLabelFontSize(kBox);
}
function FormatDropdown(GfxObject kCombobox)
{
	local ASValue myVal;
	local array<ASValue> arrParams;
	local float fScale, fH;
	local GFxObject gfxButton, gfxParentButton;

	gfxParentButton = kCombobox.GetObject("theButton");
	gfxButton = gfxParentButton.GetObject("theButton");
	fH = gfxButton.GetFloat("_height");
	fScale = 100.0 * COMBO_FORCEHEIGHT / fH;
	if(kCombobox.GetFloat("_yscale") != fScale)
	{   
		kCombobox.SetFloat("_yscale",fScale);
		kCombobox.SetFloat("_xscale",fScale);
	}
	fScale = 100.0 / fScale;
	fH = FFloor(LABEL_FONTSIZE * fScale);
	gfxParentButton.GetObject("labelText").SetFloat("_width", CalcTextFieldWidth(kCombobox));
	gfxParentButton.SetFloat("labelY", 17.0);
	gfxParentButton.SetFloat("labelX", CalcTextFieldX(kCombobox));
	gfxParentButton.SetFloat("textHeightPadding", 30.0);
		myVal.Type=AS_Number;
		myVal.n = fH;
	arrParams.AddItem(myVal);
		myVal.Type=AS_String;
		myVal.s = "$TitleFont";
	arrParams.AddItem(myVal);
	gfxParentButton.Invoke("setLabelFontSize", arrParams);
	arrParams.Length=0;
		myVal.s = "right";
	arrParams.AddItem(myVal);
	gfxParentButton.Invoke("setLabelAlignment", arrParams);
	SetFocusFX(kCombobox, kCombobox == GetObject("focus"));

	FixWidgetLabelFontSize(kCombobox);
}
function FormatSpinner(GFxObject kSpinner)
{
	local GFxObject gfxLabel;
	
	class'UIModUtils'.static.SpinnerForceValueWidth(kSpinner, SPINNER_FORCEWIDTH, true);
	gfxLabel = kSpinner.GetObject("displayLabel");
	gfxLabel.SetBool("multiline", false);
	gfxLabel.SetBool("wordWrap", false);
	gfxLabel.SetFloat("size", LABEL_FONTSIZE); 
	gfxLabel.SetFloat("_x", CalcTextFieldX(kSpinner));
	gfxLabel.SetString("align", "right");
	gfxLabel.SetFloat("_width", CalcTextFieldWidth(kSpinner));

	FixSpinnerValueFontSize(kSpinner);//this is crucial to gamepad somehow
	FixWidgetLabelFontSize(kSpinner);
}
function FixSpinnerValueFontSize(GFxObject kSpinner)
{
	local GfxObject kTextFormat;
	local UIModGfxTextField kTextField;
	local string strDisplayText;
	local float fW, fTextW, fSize;

	kTextField = UIModGfxTextField(kSpinner.GetObject("displayValue", class'UIModGfxTextField'));
	strDisplayText = kSpinner.GetString("displayStringValue");
	if(InStr(strDisplayText, "</") != -1)
	{
		strDisplayText = Left(strDisplayText, InStr(strDisplayText, "</"));
		strDisplayText = Right(strDisplayText, Len(strDisplayText) - InStr(strDisplayText, ">", true) - 1);
	}
	fTextW = kTextField.AS_GetTextExtent(strDisplayText).GetFloat("width");
	fW = kTextField.GetFloat("_width");
	if(fTextW > fW)
	{
		kTextFormat = kTextField.AS_GetTextFormat();
		fSize = kTextFormat.GetFloat("size");
		fSize = float(int(fSize * fW / fTextW)) - 1.0;
		kTextFormat.SetFloat("size", fSize);
		kTextField.AS_SetTextFormat(kTextFormat);
	}
}
function FormatSlider(GFxObject kSlider)
{
	local array<ASValue> arrParams;
	local GFxObject gfxLabel;

	if(kSlider.GetBool("bDraggingThumb"))
	{
		return;
	}
	arrParams.Length = 0;
	kSlider.SetFloat("sliderWidth", SPINNER_FORCEWIDTH + 10.0);
	gfxLabel = kSlider.GetObject("displayLabel");
	//gfxLabel.SetFloat("size", LABEL_FONTSIZE); 
	gfxLabel.SetFloat("_x", CalcTextFieldX(kSlider));
	gfxLabel.SetString("align", "right");
	gfxLabel.SetFloat("_width", CalcTextFieldWidth(kSlider));
	kSlider.Invoke("realize", arrParams);
	if(kSlider.GetObject("tickMC").GetObject("Value_txt") == none)
	{
		class'UIModUtils'.static.AttachTextFieldTo(kSlider.GetObject("tickMC"), "Value_txt", -10.0, 20.0, 40.0, 37.0, 2);
		kSlider.GetObject("tickMC").GetObject("Value_txt").SetBool("multiline", false);
	}
	FixWidgetLabelFontSize(kSlider);
}
function float CalcSpinnerWidth(GfxObject kSpinner)
{
	local float fW;

	fW = SPINNER_FORCEWIDTH;
	fW += kSpinner.GetObject("rightArrow").GetFloat("_width");
	fW += kSpinner.GetObject("leftArrow").GetFloat("_width");
	return fW;
}
function float CalcSliderWidth(GFxObject kSlider)
{
	local float fW;

	fW = kSlider.GetFloat("sliderWidth");
	fW += kSlider.GetObject("rightArrow").GetFloat("_width");
	fW += kSlider.GetObject("leftArrow").GetFloat("_width");
	return fW;
}
function float CalcComboWidth(GFxObject kCombo)
{
	return kCombo.GetFloat("_xscale") * kCombo.GetObject("theButton").GetObject("theButton").GetFloat("_width") / 100.0;
}
function float CalcTextFieldX(optional GfxObject kWidget)
{
	local float fW;	

	fW = GetFloat("displayWidth") - ITEM_RIGHT_MARGIN_PADDING - SPINNER_FORCEWIDTH - 90.0 - LABEL_TO_WIDGET_PADDING;
	if (IsSpinner(kWidget))
	{
		fW += 1.0;
	}
	else if (IsSlider(kWidget))
	{
		fW += 1.0;
	}
	else if (IsCombobox(kWidget))
	{
		fW += 142.0;
	}
	else
	{
		fW -= 14.0;
	}
	return -fW;
}
function float CalcTextFieldWidth(optional GfxObject kWidget)
{
	local float fW;	

	fW = GetFloat("displayWidth") - ITEM_RIGHT_MARGIN_PADDING - SPINNER_FORCEWIDTH - 90.0 - LABEL_TO_WIDGET_PADDING;
	if (IsSpinner(kWidget))
	{
		fW -= 28.0;
	}
	else if (IsSlider(kWidget))
	{
		fW -= 28.0;
	}
	else if (IsCombobox(kWidget))
	{
		fW += 98.0;
	}
	else
	{
		fW -= 22.0;
	}
	return fW;
}
function int GetItemIDFromMouse(optional out GFxObject gfxClosest)
{
	local int i, iReturn;
	local float fCurrent, fClosest;
	local GfxObject gfxItem, gfxClosestToMouse;

	//skip if mouse cursor is outside the listbox (which is recognized by _xmouse < 0 || _xmouse > displayWidth)
	if(GetObject("listbox").GetFloat("_xmouse") > GetFloat("displayWidth") || GetObject("listbox").GetFloat("_xmouse") < 0 )
	{
		gfxClosest = none;
		iReturn = -1;
	}
	else
	{
		gfxClosestToMouse = none;
		//loop over all items and get the one with the lowest positive _ymouse
		for(i=0; i < m_iNumOptions; i++)
		{
			gfxItem = AS_GetItemAt(i);
			fCurrent = gfxItem.GetFloat("_ymouse");
			if(IsCombobox(gfxItem))
			{
				fCurrent += 15.0;
			}
			if(fCurrent < 0.0)
			{
				continue;
			}
			//if item is closer to mouse than currently set as the closest one -> update
			if(gfxClosestToMouse == none || fCurrent < fClosest)
			{
				gfxClosestToMouse = gfxItem;
				fClosest = fCurrent;
				iReturn = i;
			}
		}
		gfxClosest = gfxClosestToMouse;
	}
	return iReturn;
}
function float GetItemDisplayHeight(GFxObject gfxItem, optional bool bOffsetForComboList)
{
	local float fHeight;

	if(IsCombobox(gfxItem))
	{
		fHeight = (bOffsetForComboList ? 160.0 : 37.90);
	}
	else
	{
		fHeight = gfxItem.GetFloat("_height");
	}
	return fHeight;
}
function RegisterSetFocusDelegate(delegate<del_SetFocus> fnSetFocusFunction)
{
	ActionScriptSetFunction("SetFocus");
}
function RegisterRealizePositionsDelegate(delegate<del_RealizePositions> fnFunction)
{
	ActionScriptSetFunction("realizePositions");
}
function RegisterGetTotalHeightDelegate(delegate<del_GetTotalHeight> fnFunction)
{
	ActionScriptSetFunction("getTotalHeight");
}
function RegisterOnScrollerDelegate(delegate<OnScrollerCallback> fnFunction)
{
	manager.ActionScriptSetFunction(GetObject("descText"), "onScroller");
}
function AS_BindMouse(GfxObject kBindToObject)
{
	manager.ActionScriptVoid(manager.GetMCPath() $ "._global.Bind.mouse");
}
function GfxObject AS_GetWidgetHelper()
{
	return GetObject("parent").GetObject("parent").GetObject("widgetHelper2");
}
function GfxObject AS_GetItemAt(int i)
{
	return GetObject("items").ActionScriptObject("getItemAt");
}
function GfxObject AS_GetItem(string id)
{
	return GetObject("items").ActionScriptObject("getItem");
}
function float AS_GetTotalHeight(optional int iStartIdx=0, optional int iEndIdx=m_iNumOptions)
{
	return ActionScriptFloat("getTotalHeight");
}
function int AS_GetSize()
{
	return ActionScriptInt("getSize");
}
function float AS_GetWindowPercent()
{
	return ActionScriptFloat("GetWindowPercent");
}
function AS_SetWindow(float fPercent)
{
	ActionScriptVoid("SetWindow");
}
function AS_SetFocus(string strFocusItem)
{
	ActionScriptVoid("SetFocus");
}
function AS_RealizePositions()
{
	ActionScriptVoid("realizePositions");
}
function AS_navigatorSetSelected(int i)
{
	GetObject("navigator").ActionScriptVoid("SetSelected");
}
function int AS_navigatorGetIndex(string id)
{
	return	GetObject("navigator").ActionScriptInt("getIndex");
}
function AS_Clear()
{
	ActionScriptVoid("clear");
}
function AS_EnableScrollbar(string strClass)
{
	ActionScriptVoid("enableScrollbar");
}
function int AS_ItemsAdd(string strKey, GFxObject gfxValue)
{
	return GetObject("items").ActionScriptInt("add");
}
function AS_OnItemLoad(GFxObject gfxItem)
{
	ActionScriptVoid("onItemLoad");
}
function AS_SetListboxScale()
{
	ActionScriptVoid("setListBoxScale");
}
function AS_SetMaskAndRootSize()
{
	ActionScriptVoid("setMaskAndRootSize");
}
function AS_ScrollboxResize()
{
	m_gfxScrollbar.ActionScriptVoid("Resize");
}
function AS_ScrollboxNotifySelectedIndexChanged()
{
	m_gfxScrollbar.ActionScriptVoid("NotifySelectedIndexChanged");
}
function AS_ScrollboxNotifyItemsChanged()
{
	m_gfxScrollbar.ActionScriptVoid("NotifyItemsChanged");
}
function AS_SetScrollbarHeight(float fHeight)
{
	m_gfxScrollbar.ActionScriptVoid("SetScrollbarHeight");
}
function AS_ItemRootSetMask(GfxObject gfxMask)
{
	GetObject("itemRoot").ActionScriptVoid("setMask");
}
function AS_RemoveTweens(GFxObject kObj)
{
	manager.ActionScriptVoid(manager.GetMCPath() $ "._global.caurina.transitions.Tweener.removeTweens");
}
function AS_FormatDropdown(GFxObject kWidgetHelper, int iWidgetIndex)
{
	ActionScriptVoid("formatDropdown");
}
function float AS_GetItemHeight(GFxObject kO)
{
	return kO.ActionScriptFloat("getHeight");
}
function AS_RemoveWidget(GFxObject kO)
{
	kO.ActionScriptVoid("Remove");
}
function AS_SetVersionTxt(string strVersion)
{
	//verstionTxt is attached to theScreen which is "grand parent" of the list
	UIModGfxTextField(GetObject("_parent").GetObject("_parent").GetObject("versionTxt", class'UIModGfxTextField')).SetHTMLText(strVersion);
}
DefaultProperties
{
	ITEM_PADDING=10.0
	LABEL_TO_WIDGET_PADDING=20.0
	ITEM_RIGHT_MARGIN_PADDING=10.0
	SCROLLBAR_X_PADDING=-22.0
	SCROLLBAR_Y_PADDING=-10.0
	SCROLLBAR_HEIGHT_PADDING=30.0
	MASK_X_PADDING=3.0
	MASK_Y_PADDING=6.5
	MASK_HEIGHT_PADDING=11.0
	ANCHOR_X=78.0
	ANCHOR_Y=180.0
	HEIGHT_ADJUSTMENT_TO_PARENT=-20.0
	WIDTH_SCALE_TO_PARENT=0.54
	SPINNER_FORCEWIDTH=150.0
	COMBO_FORCEHEIGHT=27.0
	LABEL_FONTSIZE=24.0
}