/** This class is a holder for static functions written as helpers for modding UI.*/
class UIModUtils extends Object;

static function XComPresentationLayerBase GetPresBase()
{
	return XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).m_Pres;
}
static function UIFxsMovie GetHUD()
{
	if(XComHQPresentationLayer(GetPresBase()) != none && XComHQPresentationLayer(GetPresBase()).GetStateName() == 'State_InterceptionEngagement')
	{
		return XComHQPresentationLayer(GetPresBase()).Get3DMovie();
	}
	else
	{
		return XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).m_Pres.GetHUD();
	}
}

delegate del_OnReleaseCallback();

/** Similar to AS_BindMovie. Creates a clip of specified class and attaches it to the specified parent clip (owner). 
 *  In addition it can make the return object be of a specified class (extending GfxObject). 
 *  The result is not coerced though. You must do it yourself.
 */
static function GfxObject BindMovie(GFxObject kOwner, coerce string strFlashClass, coerce string strClipName, optional class<GfxObject> kClass=none, optional UIFxsMovie manager=GetHUD())
{
	local GFxObject O;
	local array<ASValue> myArray;

	O = AS_BindMovie(kOwner, strFlashClass, strClipName, manager);
	
	myArray.Add(1); //dummy, to pass as param
	O.Invoke("onLoad", myArray); //objects created from Unreal side do not have it auto-called

	if(kClass != none)
	{
		O = kOwner.GetObject(strClipName, kClass);
	}
	return O;
}

/** A wrapper for AttachMovieClip. Creates a clip of specified flash class and attaches it to the specified parent clip (owner).
 *  This tends to work only with classes embedded in the owner-clip or with some globally accessible components.
 *  */
static function GfxObject AS_BindMovie(GFxObject kOwner, coerce string strTemplateFlashClass, coerce string strNewClipID, optional UIFxsMovie manager=GetHUD())
{
	return manager.ActionScriptObject(manager.GetMCPath() $ "._global.Bind.movie");
}
/** Loads image from specified path and attaches it to the specified parent clip (owner)*/
static function AS_BindImage(GFxObject kOwner, coerce string strImagePath)
{
	GetHUD().ActionScriptVoid(GetHUD().GetMCPath() $ "._global.Bind.image");
}
/** Makes a movie clip mouse-sensitive*/
static function AS_BindMouse(GfxObject kBindToObject)
{
	GetHUD().ActionScriptVoid(GetHUD().GetMCPath() $ "._global.Bind.mouse");
}
/** Registers a movie clip as a receiver of mouse event calls*/
static function AS_AddMouseListener(GfxObject kListener)
{
	GetHUD().ActionScriptVoid(GetHUD().GetMCPath() $ "._global.Mouse.addListener");
}
/** Unregisters a movie clip as a receiver of mouse event calls*/
static function AS_RemoveMouseListener(GfxObject kListener)
{
	GetHUD().ActionScriptVoid(GetHUD().GetMCPath() $ "._global.Mouse.removeListener");
}
/** Removes currently scrolled textField or movie clip*/
static function AS_RemoveTweens(GfxObject gfxInObj)
{
	GetHUD().ActionScriptVoid(GetHUD().GetMCPath() $ "._global.caurina.transitions.Tweener.removeTweens");
}
/** Removes ALL currently scrolled textFields or movie clips*/
static function AS_RemoveAllTweens()
{
	GetHUD().ActionScriptVoid(GetHUD().GetMCPath() $ "._global.caurina.transitions.Tweener.removeAllTweens");
}
/** Duplicates a clip specified by a path (must be full ActionScript path - consider using AS_GetPath function). The duplicate is attached to the same parent as the original.
 *  @param strClipToDuplicatePath Must be a full path starting from "_level0..."
 *  @param strNewClipName A name for the duplicate (assigned to the duplicate's .Name property on Flash side)
 *  @param gfxOutClass Optional return class type for the new object. Note that the result is not coerced (like with Spawn function) so you must cast it manually
 *  */
static function GfxObject AS_DuplicateMovieClip(string strClipToDuplicatePath, string strNewClipName, optional UIFxsMovie manager=GetHUD(), optional class<GfxObject> gfxOutClass)
{
	local ASValue myValue;
	local array<ASValue> myArray;
	local string strParent;
	local int iCount;

	iCount = InStr(strClipToDuplicatePath, ".", true);
	strParent = Left(strClipToDuplicatePath, iCount);
	
	myValue.Type = AS_String;
	myValue.s = strNewClipName;
	myArray.AddItem(myValue);	
	myValue.Type = AS_Number;
	myValue.n = AS_GetNextHighestDepth(manager.GetVariableObject(strParent));
	myArray.AddItem(myValue);
	manager.GetVariableObject(strClipToDuplicatePath).Invoke("duplicateMovieClip", myArray);
	return manager.GetVariableObject(strParent $ "." $ strNewClipName, gfxOutClass);
}
/** Creates and returns a duplicate of UI_FxsPanel instance. Check for sourcePanel.b_IsInitialized before duplicating it.
 *  The new panel is INSERTED into panels' stack of the owner-screen - so that the new panel becomes "first to receive input callbacks". 
 *  @param kSourcePanel Instance of UI_FxsPanel to duplicate.
 *  @param kNewPanelClass New panel class - must be child of UI_FxsPanel.
 *  @param bDuplicateMC If true the gfx layer of source panel will be duplicated as parallel movie clip.
 *  @param sNewGfxName ActionScript name for the gfx layer of the panel. Defaults to kNewPanelClass.s_name.
 *  @param gfxClass Optional return class type for the duplicated gfx movie clip.
 */
static function UI_FxsPanel DuplicateFxsPanel(UI_FxsPanel kSourcePanel, class<UI_FxsPanel> kNewPanelClass, optional bool bDuplicateMC, optional string sNewGfxName, optional class<GfxObject> gfxClass)
{
	local UI_FxsPanel kNewPanel;
	local GFxObject gfxNewPanel;
	local ASDisplayInfo tDisplay;

	//create UI_FxsPanel and perform standard PanelInit stuff, BUT skipping LoadPanel
	kNewPanel = kSourcePanel.controllerRef.m_Pres.Spawn(kNewPanelClass, kSourcePanel.screen);//create UI_FxsPanel actor
	if(sNewGfxName != "")
		kNewPanel.s_name = name(sNewGfxName);//bind gfx layer to UI_FxsPanel actor
	kNewPanel.controllerRef = kSourcePanel.controllerRef;
	kNewPanel.manager = kSourcePanel.manager;
	kNewPanel.screen = kSourcePanel.screen;
	kNewPanel.uicache = new (kNewPanel) class'UICacheMgr';
	kNewPanel.m_fnOnCommand = kNewPanel.screen.OnCommand;
	kSourcePanel.screen.panels.InsertItem(0, kNewPanel); //put new panel on top of panels' stack (be the first in OnMouseEvent but NOT OnUnrealCommand)
	
	if(bDuplicateMC)
	{
		//create gfx layer for the duplicated panel and offset it a little to make the effect noticable
		gfxNewPanel = AS_DuplicateMovieClip(string(kSourcePanel.GetMCPath()), string(kNewPanel.s_name), kSourcePanel.manager, gfxClass);
		tDisplay = gfxNewPanel.GetDisplayInfo();
		tDisplay.X += 30.0;
		tDisplay.Y += 30.0;
		gfxNewPanel.SetDisplayInfo(tDisplay);
		if(!kNewPanel.DependantVariablesAreInitialized())
			kNewPanel.PushState('PanelInit_WaitForDependantVariablesToInit');
		else
			kNewPanel.BaseOnDependantVariablesInitialized();
	}
	
	return kNewPanel;
}
/** Returns an available "depth" (layer) of the specified movie clip on which another GfxObject can be placed.
 * */
static function float AS_GetNextHighestDepth(GFxObject kInObj)
{
	local array<ASValue> arrVal;
	local ASValue myVal;

	arrVal.Add(1);
	myVal = kInObj.Invoke("getNextHighestDepth", arrVal);
	return myVal.n;
}
static function float AS_GetDepth(GFxObject kInObj)
{
	local array<ASValue> arrVal;
	local ASValue myVal;

	arrVal.Add(1);
	myVal = kInObj.Invoke("getDepth", arrVal);
	return myVal.n;
}

/** Modifies all colors in the specified gfxObject by multiplying respective R, G, B values by the specified multipliers. Optionally modifies alpha same way*/
static function ObjectMultiplyColor(GfxObject kInObj, float fR, float fG, float fB, optional float fA=-1.0)
{
	local ASColorTransform tColorTransform;

	tColorTransform = kInObj.GetColorTransform();
	tColorTransform.multiply.R = fR;
	tColorTransform.multiply.G = fG;
	tColorTransform.multiply.B = fB;
	if(fA != -1.0)
	{
		tColorTransform.multiply.A = fA;
	}
	kInObj.SetColorTransform(tColorTransform);
}

/** Modifies all colors in the specified gfxObject by adding specified values of R, G, B (0-255). Optionally adjusts alpha value (0-100) same way.*/
static function ObjectAddColor(GfxObject kInObj, int R, int G, int B, optional int A=-1)
{
	local ASColorTransform tColorTransform;

	tColorTransform = kInObj.GetColorTransform();
	tColorTransform.add.R = R;
	tColorTransform.add.G = G;
	tColorTransform.add.B = B;
	if(A != -1)
	{
		tColorTransform.multiply.A = 0.01;
		tColorTransform.add.A = A;
	}
	kInObj.SetColorTransform(tColorTransform);
}
/** Created for GfxOptionsList class (originally). Makes a spinner keep forced width*/
static function SpinnerForceValueWidth(GfxObject gfxSpinner, float iForcedWidth, bool bCenter)
{
	local ASValue myVal;
	local array<ASValue> aParams;

	myVal.Type=AS_Number;
	myVal.n=iForcedWidth;
	aParams.AddItem(myVal);
	myVal.Type=AS_Boolean;
	myVal.b=bCenter;
	aParams.AddItem(myVal);
	gfxSpinner.Invoke("forceValueWidth", aParams);
}

/** Retrieves full Flash path to the specified GfxObject. Useful to get the path for AS_DuplicateMovieClip*/
static function string AS_GetPath(GFxObject kO)
{
	local string strReturn;

	strReturn = kO.GetString("_target");
	strReturn = Repl(strReturn,"/",".");
	strReturn = "_level0"$strReturn;
	return strReturn;
}

/** Creates a new text field and binds it to the specified movie clip. Returns reference to the field - for further manipulation. 
 *  Default properties of the field: html=true, noselect=true, wordWrap=true, font=$NormalFont, fontSize=20, fontColor=cyan, align=left.
 *  @param kO A flash object to which the field will be attached.
 *  @param sFlashNameForTextField Name for the text field - to be used later as reference to the object.
 *  @param _x X offset (in pixels) of the field in relation to the parent object.
 *  @param _y Y offset (in pixels) of the field in relation to the parent object.
 *  @param _width Horizontal space (in pixels) for text. Defaults to 30.0
 *  @param _height Vertical space (in pixels)for text. Defaults to 20.0
 *  @param _depth Specify a depth (layer) for the field (objects with higher depth are closer to top)
 *  @param GfxReturnClass The textfield will be of specfied GfxObject child class, recommended is class'UIModGfxTextField' (the result is not coerced though, you must type-cast it on your own)
 */
static function GfxObject AttachTextFieldTo(GfxObject kO, string sFlashNameForTextField, float _x, float _y, optional float _width=30.0, optional float _height = 20.0, optional int _depth = -1, optional class<GfxObject> GfxReturnClass)
{
	local array<ASValue> arrParams;
	local ASValue myParam;
	local UIModGfxTextField kTextField;

	if(_depth < 0)
	{
		arrParams.Add(1);
		myParam = kO.Invoke("getNextHighestDepth", arrParams);
		_depth = int(myParam.n);
		arrParams.Length = 0;
	}
	myParam.Type = AS_String;
	myParam.s = sFlashNameForTextField;
	arrParams.AddItem(myParam);
	myParam.Type = AS_Number;
	myParam.n = float(_depth);      // depth
	arrParams.AddItem(myParam);
	myParam.n = _x;                 // x offset
	arrParams.AddItem(myParam);
	myParam.n = _y;                 // y offxet
	arrParams.AddItem(myParam);
	myParam.n = _width;             // width
	arrParams.AddItem(myParam);
	myParam.n = _height;            // height
	arrParams.AddItem(myParam);
	kO.Invoke("createTextField",arrParams);
	kTextField = UIModGfxTextField(kO.GetObject(sFlashNameForTextField, class'UIModGfxTextField'));
	kTextField.RealizeDefaultProperties();
	kTextField.RealizeDefaultFormat(true);
	if(GfxReturnClass != none)
	{
		return kO.GetObject(sFlashNameForTextField, GfxReturnClass);
	}
	else
	{
		return kO.GetObject(sFlashNameForTextField);
	}
}
static function AttachSimpleProgressBarTo(GFxObject kO, string sInstanceName, optional int iDepth=-1, optional bool bWithBorder, optional string strBgColorHex, optional string strProgressColorHex, optional string strBorderColorHex)
{
	local UIModGfxSimpleProgressBar gfxBarMC;
	
	gfxBarMC = UIModGfxSimpleProgressBar(kO.CreateEmptyMovieClip(sInstanceName, iDepth, class'UIModGfxSimpleProgressBar'));
	gfxBarMC.BuildComponents();
	gfxBarMC.SetBorderVisibility(bWithBorder);
	if(strBgColorHex != "")
	{
		gfxBarMC.SetBackgroundColor(strBgColorHex);
	}
	if(strProgressColorHex != "")
	{
		gfxBarMC.SetProgressColor(strProgressColorHex);
	}
	if(strBorderColorHex != "")
	{
		gfxBarMC.SetBorderColor(strBorderColorHex);
	}
}

/** Sets callback function to answer mouse "release" event for specified GfxObject BUTTON. Usefeul for custom "onClick" events.*/
static function AS_OverrideClickButtonDelegate(GfxObject kButton, delegate<del_OnReleaseCallback> fnCallback)
{
	GetPresBase().GetHUD().ActionScriptSetFunction(kButton, "release");
}
/**Trades the stack position of kInObject and sTarget, provided that kInObject and sTarget share the same parent clip*/
static function AS_SwapDepths(GfxObject kInObject, string sTarget)
{
	local ASValue myVal;
	local array<ASValue> myArray;

	if(int(sTarget) > 0)
	{  
		myVal.Type = AS_Number;
		myVal.n = float(int(sTarget));
	}
	else
	{
		myVal.Type=AS_String;
		myVal.s=sTarget;
	}
	myArray.AddItem(myVal);
	kInObject.Invoke("swapDepths", myArray);
}
static function AS_SetMask(GfxObject gfxMask, GfxObject gfxObj)
{
	gfxObj.ActionScriptVoid("setMask");
}
/** When accesshing objects created at authoring time the depth is -16384 + Depth
 * @param iDepth Objects created at authoring time have deep negative -16384 + Depth
 */
static function GfxObject AS_GetInstanceAtDepth(int iDepth, GfxObject kParentObject)
{
	return kParentObject.ActionScriptObject("getInstanceAtDepth");
}
static function MakeScreenFirstToReceiveIpunt(UI_FxsScreen kScreen)
{
	GetPresBase().GetUIMgr().m_arrScreenInputStack.RemoveItem(kScreen);
	GetPresBase().GetUIMgr().m_arrScreenInputStack.InsertItem(0,kScreen);
}
static function string GetRawText(string strInText)
{
	return StripToRawText(strInText);
}
static function RemoveHTML(out string strOutText)
{
	local string sTxt;

	sTxt = strOutText;
	strOutText = "";
	while(InStr(sTxt, "</") >= 0)
	{
		if(Left(sTxt, 1) == "<")
		{
			sTxt = Split(sTxt, ">", true);
		}
		else
		{
			strOutText $= Left(sTxt, InStr(sTxt, "<"));
			sTxt = Mid(sTxt, InStr(sTxt, "<"));
		}
	}
}
static function CopyTextureParameterValue(name ParameterName, MaterialInstanceConstant newMIC, MaterialInstanceConstant oldMIC)
{
    local Texture oldTexture;

    if(oldMIC.GetTextureParameterValue(ParameterName, oldTexture))
    {
        newMIC.SetTextureParameterValue(ParameterName, oldTexture);
    }
}
static function LocalToGlobal(GfxObject gfxLocalPosition, GFxObject gfxObj)
{
	gfxObj.ActionScriptVoid("localToGlobal");
}
static function GlobalToLocal(GfxObject gfxGlobalPosition, GFxObject gfxObj)
{
	gfxObj.ActionScriptVoid("globalToLocal");
}
static function CopyScalarParameterValue(name ParameterName, MaterialInstanceConstant newMIC, MaterialInstanceConstant oldMIC)
{
    local float oldScalar;

    if(oldMIC.GetScalarParameterValue(ParameterName, oldScalar))
    {
        newMIC.SetScalarParameterValue(ParameterName, oldScalar);
    }
}
static function CopyVectorParameterValue(name ParameterName, MaterialInstanceConstant newMIC, MaterialInstanceConstant oldMIC)
{
    local LinearColor oldVector;

    if(oldMIC.GetVectorParameterValue(ParameterName, oldVector))
    {
        newMIC.SetVectorParameterValue(ParameterName, oldVector);
    }
}
/** Attempts to remove any html formatting from InText e.g. <font ...> and closing </font> blocks. 
	It might not work well when ">" or "<" in the InText are not part of the html syntax.*/
static function string StripToRawText(string InText)
{
	local string strChunk, strRawText;

	while(InStr(InText, "</") != -1)
	{
		if(Left(InText, 1) != "<")
		{
			strChunk = Left(InText, InStr(InText, "<"));
			strRawText $= strChunk;
			InText = Split(InText, strChunk, true);
		}
		InText = Split(InText, ">", true);
	}
	return strRawText;
}

DefaultProperties
{
}
