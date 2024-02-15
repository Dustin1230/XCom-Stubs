class XHHelper_LoadoutMgr extends XGStrategyActor;

`define MyStatic class'MyXCom'.static

/** Converts each of specified parameters to a string and joins them all into one string (with "," separator) .
 */
function string BuildParamString(optional coerce string P1, optional coerce string P2, optional coerce string P3, optional coerce string P4, optional coerce string P5, optional coerce string P6, optional coerce string P7, optional coerce string P8, optional coerce string P9, optional coerce string P10)
{
	local string strToReturn;

	strToReturn = P1 $ "," $ P2 $ "," $ P3 $ "," $ P4 $ "," $ P5 $ "," $ P6 $ "," $ P7 $ "," $ P8 $ "," $ P9 $ "," $ P10;
	while(Right(strToReturn, 1) == ",")
	{
		strToReturn = Left(strToReturn, Len(strToReturn) - 1);
	}
	return strToReturn;
}
/** Wrapper for Mutate call.
 *  @param MutateString Defaults to "NameOfClass.FuncName:NameOfCallingActor" which is fine in overriding classes. Otherwise you should specify the string manually.
 */
function Mutate(optional string MutateString=class'MyXCom'.static.GetFunctionName(true, 4) $ ":" $ string(self))
{
	class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator.Mutate(MutateString, GetALocalPlayerController());
}
function UISoldierSummaryGoToView(string strParams, out string strCallback)
{
	local int iView;
	local UISoldierSummary kUI;

	kUI = PRES().m_kSoldierSummary;
	iView = int(`MyStatic.GetParameterString(1, strParams));
	if(iView == 9 || iView == 10 || iView == 0)
	{
		kUI.m_kSoldier = kUI.GetMgr().m_kSoldier;
		if(!kUI.b_IsInitialized)
		{
			return;
		}
		kUI.Show();
		kUI.UpdateData();
	}
}
function OnLeaveSoldierUI(string strParams, out string strCallback)
{
	local XGSoldierUI kMgr;

	kMgr = PRES().m_kSoldierSummary.GetMgr(); 
	if((kMgr.m_iCurrentView == 9) || kMgr.m_iCurrentView == 10)
	{
		kMgr.GoToView(0);
		strCallback = "Return";
 	}
}
function OnMainMenuOption(string strParams, out string strCallback)
{
	local XGSoldierUI kMgr;
	local int iOption, iNewView;

	kMgr = PRES().m_kSoldierSummary.GetMgr(); 
	iOption = int(`MyStatic.GetParameterString(1, strParams));

    if(kMgr.m_kMainMenu.mnuOptions.arrOptions[iOption].iState == 1)
    {
    	return;
    }
	if(kMgr.m_iCurrentView == 9)
	{
		Mutate("XGSoldierUI.SaveLoadout_" $ string(iOption));
		strCallback = "Return";
	}
	if(kMgr.m_iCurrentView == 10)
	{
		Mutate("XGSoldierUI.RestoreLoadout_" $ string(iOption));
		strCallback = "Return";
	}
	iNewView = kMgr.m_kMainMenu.arrOptions[iOption];
	if(iNewView == 9 || iNewView == 10)
	{
		kMgr.GoToView(iNewView);
		strCallback = "Return"; 
	}
}
function UISummaryOnUnrealCommand(string strParams, out string strCallback)
{	
	local UISoldierSummary kUI;

	kUI = PRES().m_kSoldierSummary;

    if(kUI != none && !kUI.IsVisible() || kUI.GetMgr().m_iCurrentView != 0)
    {
        if( kUI.GetMgr().m_iCurrentView != 9 && kUI.GetMgr().m_iCurrentView != 10)
        {
            strCallback="Return:false";
        }
    }
}
function UISummaryUpdateData(string strParams, out string strCallback)
{
	local UISoldierSummary kUI;

	kUI = PRES().m_kSoldierSummary;
	if(kUI == none || (InStr(strParams, "(isPromotable)",,true) == -1 && InStr(strParams, "(isPsiPromotable)",,true) == -1))
	{
		return;
	}
	if(kUI.GetMgr().m_iCurrentView == 9 || kUI.GetMgr().m_iCurrentView == 10)
	{
		strCallback="Return:false";
	}
}
function SoldierUpdateView(string strParams, out string strCallback)
{
	local XGSoldierUI kMgr;

	kMgr = PRES().m_kSoldierSummary.GetMgr(); 
	if(kMgr.m_iCurrentView == 9 || kMgr.m_iCurrentView == 10)
	{
		kMgr.UpdateHeader();
		kMgr.UpdateButtonHelp();
		kMgr.UpdateDoll();
		kMgr.UpdateMainMenu();
		kMgr.GetUIScreen().GoToView(kMgr.m_iCurrentView);
		strCallback="Return";
	}
}
function UISummaryOnInit()
{
	Mutate("UISoldierSummary.AdjustDescription");
}
function UISquadSelectOnCommand(string strParams, out string strCallback)
{
	local UISquadSelect kUI;
	local int Cmd, Arg;

	kUI = PRES().m_kSquadSelect;
	Cmd = int(class'MyXCom'.static.GetParameterString(1, strParams));
	Arg = int(class'MyXCom'.static.GetParameterString(2, strParams));

	if(kUI == none || !kUI.CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg) || kUI.m_bExiting)
	{
        return;
	}
	switch(Cmd)
	{
		case 332:
			if(kUI.m_iCurrentSelection != 0 || kUI.m_iView !=0 || !kUI.m_kSquadList.OnUnrealCommand(Cmd,Arg))
			{
				kUI.OnMouseSimMission();
				strCallback="Return:true";//functions CustomCode and ReturnBool in MyUISquadSelect.OnUnrealCommand will both return true
				break;
			}
		case 333:
			if(kUI.m_iCurrentSelection != 0 || kUI.m_iView !=0 || !kUI.m_kSquadList.OnUnrealCommand(Cmd,Arg))
			{
				kUI.OnSimMission();
				strCallback = "Return:true";//functions CustomCode and ReturnBool in MyUISquadSelect.OnUnrealCommand will both return true
			}
	}
}
function EnsureDescHTML(UISoldierSummary kUI)
{
	if(!kUI.b_IsInitialized)
	{
		return;
	}
	if(!kUI.manager.GetVariableBool(string(kUI.GetMCPath()) $ ".description.textField.html"))
	{
		kUI.manager.SetVariableBool(string(kUI.GetMCPath()) $ ".description.textField.html", true);
	}
}
function LM_SetDescription(string strParams, out string strCallback)
{
	local UISoldierSummary kUI;
	local string strDescText;

	kUI = PRES().m_kSoldierSummary;
	if(InStr(strParams, ",") != -1)
	{
		strDescText = Split(strParams, ",",true);
		while(Right(strDescText,1) == ",")
		{
			strDescText = Left(strDescText, Len(strDescText) - 1);
		}
	}
	else
	{
		strDescText = "";
	}
	EnsureDescHTML(kUI);
	kUI.manager.SetVariableString(string(kUI.GetMCPath()) $ ".description.textField.htmlText", strDescText);
}
DefaultProperties
{
}
