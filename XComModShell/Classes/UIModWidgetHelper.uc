class UIModWidgetHelper extends UIWidgetHelper;

var bool m_bFocusOnConfigButton;
var int m_iInitialSelection;

simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
	local bool bHandled;

	if(m_arrWidgets.Length == 0 || m_iCurrentWidget > m_arrWidgets.Length - 1)
	{
		//this is only possible while refreshing widgets and the call cannot be handled
		return false;
	}
	if(m_arrWidgets[m_iCurrentWidget].eType == eWidget_Checkbox && AS_GetWidgetGfx(m_iCurrentWidget).GetObject("configButton") != none)
	{
		//this section handles the widget which was "current" prior to pressing a controller's button
		switch(Cmd)
		{
			case 300:
			case 511:
			case 513:
				break;
			case 352:
			case 373:
			case 501:
			case 518:
				m_bFocusOnConfigButton = true;
				bHandled = true;
				break;
			case 356:
			case 372:
			case 503:
			case 515:
				m_bFocusOnConfigButton = m_arrWidgets[m_iCurrentWidget].bReadOnly;
				bHandled = true;
				break;
			case 370:
			case 371:
			case 500:
			case 502:
			case 350:
			case 354:
			case 533:
			case 537:
				m_bFocusOnConfigButton = false;
			default:
				bHandled = false;
		}
		SetConfigButtonFocus(m_bFocusOnConfigButton);
	}
	if(!bHandled)
	{
		switch(Cmd)
		{
		case 300:
		case 511:
		case 513:
			if(m_bFocusOnConfigButton)
			{
				//this case will be handled in UIModShell therefore bHandled remains 'false'
				break;
			}
		default:
			if(super.OnUnrealCommand(Cmd, Arg))
			{
				//this section handles the widget which is "current" AFTER pressing the controller's button
				bHandled = true;
				m_bFocusOnConfigButton = m_arrWidgets[m_iCurrentWidget].eType == eWidget_Checkbox && AS_GetWidgetGfx(m_iCurrentWidget).GetObject("configButton") != none && m_arrWidgets[m_iCurrentWidget].bReadOnly;
				if(m_bFocusOnConfigButton)
				{
					SetConfigButtonFocus(true);
				}
			}
		}   
	}
	return bHandled;
}
/** Controls highlight/selection FX of the config button for an option in Mods Menu*/
function SetConfigButtonFocus(bool bFocus)
{
	local UIModGfxButton gfxCheckbox, gfxConfigButton;

	//the clumsy way of getting gfxCheckbox through _parent results from the fact that I want it to be of class'UIModGfxButton'
	gfxConfigButton = UIModGfxButton(AS_GetWidgetGfx(m_iCurrentWidget).GetObject("configButton", class'UIModGfxButton'));
	gfxCheckbox = UIModGfxButton(gfxConfigButton.GetObject("_parent", class'UIModGfxButton'));
	if(gfxConfigButton != none)
	{
		if(bFocus)
		{
			gfxConfigButton.AS_OnReceiveFocus();
			gfxCheckbox.AS_OnLoseFocus();
		}
		else
		{
			gfxCheckbox.AS_OnReceiveFocus();
			gfxConfigButton.AS_OnLoseFocus();
		}
	}
}
function UIModGfxOptionsList GetModList()
{
	return UIModShell(Owner).GetModList();
}
function GfxObject AS_GetWidgetGfx(int iWidget)
{
	return GetModList().AS_GetItemAt(iWidget);
}
DefaultProperties
{
	s_name="widgetHelper2."
}
