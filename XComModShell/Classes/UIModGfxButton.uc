class UIModGfxButton extends GfxObject
	dependson(UIModUtils);

/** @param iNewStyle 0-None, 1-Hotlink, 2-Selected_Shows_Hotlink, 3-Hotlink_When_No_Mouse, 4-Button_When_Mouse
 */
function AS_SetStyle(int iNewStyle, optional float fFontSize=20.0, optional bool bResizeToText=true)
{
	ActionScriptVoid("setStyle");
}
function AS_SetText(string strNewText)
{
	ActionScriptVoid("setText");
}
function AS_SetHTMLText(string strNewText)
{
	ActionScriptVoid("setHTMLText");
}
function AS_Select()
{
	ActionScriptVoid("select");
}
function AS_Deselect()
{
	ActionScriptVoid("deselect");
}
function AS_OnReceiveFocus()
{
	ActionScriptVoid("onReceiveFocus");
}
function AS_OnLoseFocus()
{
	ActionScriptVoid("onLoseFocus");
}
/** @param strIconLabel Check definition of class'UI_FxsInput' for acceptable entries.
 */
function AS_SetIcon(string strIconLabel)
{
	ActionScriptVoid("setIcon");
}
function AS_SetRealizeReadOnlyDelegate(delegate<UIModUtils.del_OnReleaseCallback> fnReadOnlyCallback)
{
	ActionScriptSetFunction("realizeReadOnlyVisuals");
}
/** Purely for Mods Menu - makes the check-button invisible when ReadOnly is true
 */
function del_RealizeReadOnlyVisuals()
{
	if(GetObject("buttonMC") != none)
	{
		GetObject("buttonMC").SetVisible(false);
		GetObject("buttonHelpMC").SetVisible(false);
		SetObject("buttonMC", none);
		SetObject("buttonHelpMC", none);
	}
	ActionScriptVoid("realize");
}
//icon labels:
//blank
//Icon_A_X
//Icon_B_CIRCLE
//Icon_X_SQUARE
//Icon_Y_TRIANGLE
//Icon_RT_R2
//Icon_RB_R1
//Icon_LT_L2
//Icon_LB_L1
//Icon_RSTICK
//Icon_LSTICK
//Icon_DPAD_UP
//Icon_DPAD_DOWN
//Icon_DPAD_LEFT
//Icon_DPAD_RIGHT
//Icon_START
//Icon_BACK_SELECT
//Icon_DPAD
//Icon_DPAD_HORIZONTAL
//Icon_DPAD_VERTICAL
//Icon_LSCLICK_L3
//Icon_RSCLICK_R3
//Icon_MOUSE_LEFT
//Icon_MOUSE_RIGHT
//Icon_MOUSE_WHEEL
//Icon_MOUSE_SCROLL
//Icon_ARROW_LEFT
//Icon_ARROW_UP
//Icon_ARROW_RIGHT
//Icon_ARROW_DOWN
//Icon_KEY_TAB
//Icon_MOUSE_LEFT4
//Icon_MOUSE_LEFT5
DefaultProperties
{
}
