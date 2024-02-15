class AscUIMutator extends XComMutator;

var AscUILabs m_kLabsUI;
var AscHelper_ScienceLabs m_kLabsHelper;
var string m_strBuildVersion;

function string GetDebugName()
{
	return GetItemName(string(Class)) @ m_strBuildVersion;
}

event PostBeginPlay()
{
	//the stuff below is done as soon as the mutator comes to life
	//class'MyXCom'.static.GetClassOverrider().RegisterClassOverride("XComStrategyGame.XGContinentUI", "XComAscensionUI.AscXGContinentUI");
	//class'MyXCom'.static.RegisterModCallback("UIContinentSelect.UpdateInfoPanelData", OnContinentUpdateInfoPanelData);
	//class'MyXCom'.static.RegisterModCallback("UIContinentSelect.OnCancel", OnCancelContinentSelect);
	`Log(GetFuncName() @ GetDebugName());
	SetTimer(1.0, false, 'WaitForInit');
}
function WaitForInit()
{
	PushState('WaitingForInit');
}
function XComHQPresentationLayer PRES()
{
	return XComHQPresentationLayer(XComHeadquartersController(GetALocalPlayerController()).m_Pres);
}
function ModifyLogin(out string strParameters, out string strMessage)
{
	if(InStr(strParameters, "UIContinentSelect.UpdateInfoPanelData:", true) != -1)
	{
		//OnContinentUpdateInfoPanelData(strParameters, strMessage);    //replaced with RegisterModCallback
	}
	if(InStr(strParameters, "UIContinentSelect.OnCancel:", true) != -1)
	{
		//OnCancelContinentSelect(strParameters, strMessage);           //replaced with RegisterModCallback
	}
	super.ModifyLogin(strParameters, strMessage);
}
function XComHQPresentationLayer HQPRES()
{
	return XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres);
}
function OnContinentUpdateInfoPanelData(Object InObject, out string strParameters, out string strMessage)
{
	local int iContinent;
	local UIContinentSelect kUI;
	local TContOption kOption;
	
	//grab the panel
	kUI = UIContinentSelect(InObject);
	
	//convert strParameters from string to value:
	iContinent = class'MyXCom'.static.GetIntParam(1, strParameters);

	if(kUI.GetMgr().m_iChosenContinent < 0)
	{
		kOption = kUI.GetMgr().m_kMainMenu.arrContOptions[iContinent];
		kUI.AS_UpdateInfo(kOption.txtBonusLabel.StrValue, kOption.txtBonusTitle.StrValue, kOption.txtBonusDesc.StrValue);            
		XComHQPresentationLayer(kUI.Owner).CAMLookAtEarth(kUI.GetMgr().Continent(kUI.GetMgr().m_arrContinents[iContinent]).GetHQLocation(), 1.0, 0.50);                                                                                                                                                                                                                                                
		strMessage = "Return"; //forces the original function to stop execution at this point
	}	
}
function OnCancelContinentSelect(Object InObject, out string strParameters, out string strMessage)
{
	local UIContinentSelect kUI;

	kUI = UIContinentSelect(InObject);
	if(kUI.GetMgr().IsA('AscXGContinentUI') && kUI.GetMgr().m_iChosenContinent != -1)
	{
		AscXGContinentUI(kUI.GetMgr()).AS_ClearItemList();
		kUI.m_iContinent = kUI.GetMgr().m_iChosenContinent;
		kUI.GetMgr().m_iChosenContinent = -1;
		AscXGContinentUI(kUI.GetMgr()).PopulateContinentsArray();	
		kUI.maxContinents = kUI.GetMgr().m_arrContinents.Length;
		kUI.GetMgr().UpdateView();
		//AscXGContinentUI(kUI.GetMgr()).DumpScreenInfo();
		strMessage = "Return:true";
	}
}
event Tick(float fDeltaTime)
{
	//local UIStrategyHUD kHUD;

	if(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game) == none 
		|| HQPRES() == none
		|| HQPRES().m_kStrategyHUD == none)
	{
		return;
	}
	if(HQPRES().GetStateName() == 'State_StrategyHUD' && IsInState('WaitingForInit'))
	{
		PopState();
		OnHQLoaded();
	}
	//kHUD = HQPRES().m_kStrategyHUD;
	if(HQPRES().GetStateName() == 'State_LabsMenu' && m_kLabsUI == none)
	{
		m_kLabsUI = Spawn(class'AscUILabs');
		m_kLabsUI.PanelInit(XComPlayerController(HQPRES().Owner), HQPRES().GetHUD(), HQPRES().m_kStrategyHUD);
	}
	else if(HQPRES().GetStateName() != 'State_LabsMenu' && m_kLabsUI != none)
	{
		m_kLabsUI.GetListGfx().ClearGfxContainer(HQPRES().GetStateName() == 'State_ChooseTech');
		HQPRES().GetUIMgr().PopFirstInstanceOfScreen(m_kLabsUI);
		m_kLabsUI.Destroy();
		m_kLabsUI=none;
	}
}
function ReplaceUIContinentSelect()
{
	local UIContinentSelect kOldUI, kMyUI;

	`log(GetFuncName(),,Name);
	//risk of flickering but...
	if(PRES().m_kContinentSelect != none && !PRES().m_kContinentSelect.IsA('AscUIContinentSelect'))
	{
		kOldUI = PRES().m_kContinentSelect;
		PRES().GetHUD().RemoveScreen(kOldUI);
		PRES().RemoveMgr(class'XGContinentUI');
		kMyUI = PRES().Spawn(class'AscUIContinentSelect', PRES());
		PRES().m_kContinentSelect = kMyUI;
		kMyUI.Init(XComPlayerController(PRES().Owner), PRES().GetHUD(), 0);
	}
	if(IsInState('WaitingForInit'))
	{
		PopState();
	}
}
function OnHQLoaded()
{
	GetLabsHelper();
}
function AscHelper_ScienceLabs GetLabsHelper()
{
	if(m_kLabsHelper == none)
	{
		foreach DynamicActors(class'AscHelper_ScienceLabs', m_kLabsHelper)
		{
			break;
		}
	}
	if(m_kLabsHelper == none)
	{
		m_kLabsHelper = Spawn(class'AscHelper_ScienceLabs');
		m_kLabsHelper.Init(eEntityGraphic_HQ);//the param is irrelevant (ignored), any would do
	}
	return m_kLabsHelper;
}
state WaitingForInit
{
Begin:
	while(PRES() == none || PRES().m_kContinentSelect == none)
	{
		Sleep(0.10);
	}
	ReplaceUIContinentSelect();
}
DefaultProperties
{
	m_strBuildVersion="1.2"
}
