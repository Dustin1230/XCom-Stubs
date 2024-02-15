/** The purpose of this class is to have all UIShipLoadout code for gfx maninpulation but with custom MCPath.
 *  It also makes tuning OnMouseEvent and OnUnrealCommand easier.*/
class SU_UIShipLoadout extends UIShipLoadout;

var localized string m_strWeaponColumnPrimary;
var localized string m_strWeaponColumnSecondary;
var localized string m_strVulcanCannonName;
var localized string m_strVulcanCannonDesc;
var bool m_bHasControllerFocus;
var int m_iWatchPrimaryCurrentSelection;

function GfxObject SelfGfx()
{
	return manager.GetVariableObject(string(GetMCPath()));
}
simulated function PanelInit(XComPlayerController _controller, UIFxsMovie _manager, UI_FxsScreen _screen, optional delegate<OnCommandCallback> CommandFunction)
{
	LogInternal(self @ GetFuncName() @ _screen);
	//original code but without AddPanel call
	if(_controller == none || _manager == none || _screen == none)
	{
		LogInternal(Name $"."$ GetFuncName() @ "error, missing parameters:" @ (_controller == none ? "_controller" : "") @ (_manager == none ? "_manager" : "")@ (_screen == none ? "_screen" : "")$". Debugging...", 'SquadronUnleashed');
		if(_controller == none)
			_controller = XComPlayerController(GetALocalPlayerController());
		if(_manager == none)
			_manager = class'SU_Utils'.static.PRES().GetHUD();
		if(_screen == none)
			_screen = class'SU_Utils'.static.PRES().m_kShipLoadout;
	}
	controllerRef = _controller;
	manager = _manager;
	screen = _screen;
	uicache = new (self) class'UICacheMgr';
	m_fnOnCommand = CommandFunction != none ? CommandFunction : _screen.OnCommand;
	screen.panels.InsertItem(0, self); //original code has screen.AddPanel here (but it would look for embedded gfx which is missing)
	UIShipLoadout(screen).AS_SetListLabels(m_strWeaponColumnPrimary, m_strQuantityColumnLabel);
	if(!DependantVariablesAreInitialized())
		PushState('PanelInit_WaitForDependantVariablesToInit');
	else
		BaseOnDependantVariablesInitialized();
}
simulated function bool CalcDependantVariablesAreInitialized()
{
    return (screen != none && screen.b_IsInitialized && UIShipLoadout(screen).m_kShip != none);
}
simulated function OnDependantVariablesInitialized()
{
	local GFxObject gfxNewPanel;

	//load gfx layer for the new panel
	if(manager.GetVariableObject(string(screen.GetMCPath()) $ "." $ string(s_name)) == none)
	{
		gfxNewPanel = class'UIModUtils'.static.AS_DuplicateMovieClip(string(screen.GetMCPath()), string(s_name), manager);
		//assign MCPath property
		MCPath = name(class'UIModUtils'.static.AS_GetPath(gfxNewPanel));
		manager.GetVariableObject(string(MCPath));
	}
}
simulated function OnInit()
{
	Hide();
	m_kShip = UIShipLoadout(screen).m_kShip;
	GetMgr().m_kShip = m_kShip;
	SU_XGHangarUI(GetMgr()).m_iRearmHours=0;
	SU_XGHangarUI(GetMgr()).m_bPrimaryLoadoutChanged=false;
	SU_XGHangarUI(GetMgr()).m_bSecondaryLoadoutChanged=false;
	SU_XGHangarUI(GetMgr()).m_eWeaponEquipped = EItemType(class'SU_Utils'.static.ShipWeaponToItemType(class'SU_Utils'.static.GetSavedInt(m_kShip, "SecondaryWeapon")));
	AS_SetTitle(m_strWeaponColumnSecondary$":  "@ m_kShip.SHIPWEAPON(m_kShip.m_kTShip.arrWeapons[1]).strName);
    AS_SetListLabels(m_strScreenTitle, m_strQuantityColumnLabel);
	GetMgr().PRES().m_kShipLoadout.AS_SetListLabels(m_strScreenTitle, m_strQuantityColumnLabel);
	GetMgr().PRES().m_kShipLoadout.AS_SetTitle(m_strWeaponColumnPrimary$":  "@ m_kShip.SHIPWEAPON(m_kShip.m_kTShip.arrWeapons[0]).strName);
    SetScreenPosition();
	GetMgr().UpdateTableMenu();//
    UpdateData();
	if(manager.IsMouseActive())
	{
		UpdateFocusFromMouseCursor();
	}
	else
	{
		SetPanelFocus(false);
	}
	m_iWatchPrimaryCurrentSelection = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(class'SU_Utils'.static.GetSquadronMod().m_kShipLoadoutPrimary, 'm_iCurrentSelection', self, OnPrimaryPanelSelectionChange);
	OnPrimaryPanelSelectionChange();
	XComHQPresentationLayer(controllerRef.m_Pres).GetStrategyHUD().SetBackButtonMouseClickDelegate(OnCloseShipLoadout);
	super(UI_FxsPanel).OnInit();//native (subscribes the panel as receiver of FlashRaiseCommand)
	Show();
	class'SU_Utils'.static.GetHelpMgr().QueueHelpMsg(eSUHelp_ShipLoadout);
}
simulated function Show()
{
	SU_XGHangarUI(GetMgr()).UpdateWatchVariables();
	super.Show();
}
function SetScreenPosition()
{
	local GFxObject gfxObj;
	local ASDisplayInfo tDisplay;
	local float x, y;

	gfxObj = manager.GetVariableObject(string(screen.GetMCPath()));
	gfxObj.GetPosition(x, y);
	SelfGfx().SetPosition(x + gfxObj.GetFloat("_width"), y);

	gfxObj = class'UIModUtils'.static.AS_GetInstanceAtDepth(1-16384, SelfGfx());
	tDisplay = gfxObj.GetDisplayInfo();
	tDisplay.XScale = -100;
	tDisplay.X = tDisplay.X - gfxObj.GetFloat("_width") + 30.0;
	gfxObj.SetDisplayInfo(tDisplay);
}
simulated function XGHangarUI GetMgr()
{
    if(m_kLocalMgr == none)
    {
		//make it return SU_XGHangarUI screen manager instead of XGHangarUI
        m_kLocalMgr = SU_XGHangarUI(XComHQPresentationLayer(controllerRef.m_Pres).GetMgr(class'SU_XGHangarUI', (self), 2));
    }
    return m_kLocalMgr;
}
function RealizeSelected()
{	
    local int shipWpnRange, shipWpnFireRate, shipWpnBaseDamage, shipWpnArmorPen;
    local string tmpStr;
	local TShipWeapon kWeapon;

	m_iCurrentSelection = Clamp(m_iCurrentSelection, 0, GetMgr().m_arrItems.Length-1);
	if(GetMgr().m_arrItems[m_iCurrentSelection].iItem == 0)
		kWeapon = GetMgr().SHIPWEAPON(0);
	else
		kWeapon = GetMgr().SHIPWEAPON(GetMgr().HANGAR().ItemTypeToShipWeapon(EItemType(GetMgr().m_arrItems[m_iCurrentSelection].iItem)));
	GetMgr().UpdateShipWeaponView(m_kShip, kWeapon.eType);
    shipWpnRange = class'SU_Utils'.static.GetShipWeaponRangeBin(kWeapon.eType);
    shipWpnFireRate =  class'SU_Utils'.static.GetShipWeaponFiringRateBin(kWeapon.fFiringTime);
    shipWpnBaseDamage = class'SU_Utils'.static.GetShipWeaponDamageBin(kWeapon.iDamage);
    shipWpnArmorPen = class'SU_Utils'.static.GetShipWeaponArmorPenetrationBin(kWeapon.iAP);
	if(class'SU_Utils'.static.IsShortDistanceWeapon(kWeapon.eType))
	{
		tmpStr = "--";
	}
	else
	{
		tmpStr = string(kWeapon.iToHit);
	}
	tmpStr @= "/";
	tmpStr @= string(kWeapon.iToHit + class'SU_Utils'.static.GetWeaponAimModClose(kWeapon.eType) + (class'SU_Utils'.static.IsShortDistanceWeapon(kWeapon.eType) ? 0 : class'SquadronUnleashed'.default.AIM_BONUS_CLOSE_DISTANCE_GLOBAL));
    AS_SetStatData(0, "("$class'UIItemCards'.default.m_strRangeLong @ "/" @ class'UIItemCards'.default.m_strRangeShort$")" @ class'UIUtilities'.static.InjectHTMLImage("img:///gfxMessageMgr.Attack",22,22,-2) $":", tmpStr);
    switch(shipWpnRange)
    {
        case 0:
            tmpStr = class'UIItemCards'.default.m_strRangeShort;
            break;
        case 1:
            tmpStr = class'UIItemCards'.default.m_strRangeMedium;
            break;
        case 2:
            tmpStr = class'UIItemCards'.default.m_strRangeLong;
            break;
    }
    AS_SetStatData(1, class'UIItemCards'.default.m_strRangeLabel, tmpStr);
    switch(shipWpnFireRate)
    {
		case 0:
			tmpStr = class'UIItemCards'.default.m_strRateSlow;
            break;
		case 1:
			tmpStr = class'UIItemCards'.default.m_strRateMedium;
            break;
        case 2:
			tmpStr = class'UIItemCards'.default.m_strRateRapid;
			break;
    }
    AS_SetStatData(2, class'UIItemCards'.default.m_strFireRateLabel, tmpStr);
    switch(shipWpnBaseDamage)
    {
		case 0:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleLow;
			break;
		case 1:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleMedium;
            break;
        case 2:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleHigh;
            break;
    }
    AS_SetStatData(3, class'UIItemCards'.default.m_strDamageLabel, tmpStr);
    switch(shipWpnArmorPen)
    {
		case 0:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleLow;
            break;
        case 1:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleMedium;
            break;
        case 2:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleHigh;
            break;
    }
    AS_SetStatData(4, class'UIItemCards'.default.m_strArmorPenetrationLabel, tmpStr);
    AS_SetSelected(m_iCurrentSelection);
    AS_SetWeaponName(class'SU_Utils'.static.GetShipWeaponName(kWeapon.eType));
	if(GetMgr().m_arrItems[m_iCurrentSelection].iItem == 0)
	{
		AS_SetWeaponImage("img:///"$class'SquadronUnleashed'.default.m_strVulcanCanonImgPath, 0.80);
	}
	else
	{
		AS_SetWeaponImage(class'UIUtilities'.static.GetInventoryImagePath(GetMgr().m_kTable.arrSummaries[m_iCurrentSelection].imgOption.iImage), 0.90);
	}
	AS_SetWeaponDescription(GetMgr().m_kTable.arrSummaries[m_iCurrentSelection].txtSummary.StrValue);
}
/** Updates stat's range-description on main weapon panel for current selection*/
function OnPrimaryPanelSelectionChange()
{
	local UIShipLoadout kMainPanel;
    local int shipWpnRange, shipWpnFireRate, shipWpnBaseDamage, shipWpnArmorPen;
    local string tmpStr;
	local TShipWeapon kWeapon;

	kMainPanel = class'SU_Utils'.static.GetSquadronMod().m_kShipLoadoutPrimary;
	kWeapon = kMainPanel.GetMgr().SHIPWEAPON( class'SU_Utils'.static.ItemTypeToShipWeapon(kMainPanel.GetMgr().m_arrItems[kMainPanel.m_iCurrentSelection].iItem) );
	shipWpnRange = class'SU_Utils'.static.GetShipWeaponRangeBin(kWeapon.eType);
    shipWpnFireRate =  class'SU_Utils'.static.GetShipWeaponFiringRateBin(kWeapon.fFiringTime);
    shipWpnBaseDamage = class'SU_Utils'.static.GetShipWeaponDamageBin(kWeapon.iDamage);
    shipWpnArmorPen = class'SU_Utils'.static.GetShipWeaponArmorPenetrationBin(kWeapon.iAP);
	if(class'SU_Utils'.static.IsShortDistanceWeapon(kWeapon.eType))
	{
		tmpStr = "--";
	}
	else
	{
		tmpStr = string(kWeapon.iToHit);
	}
	tmpStr @= "/";
	tmpStr @= string(kWeapon.iToHit + class'SU_Utils'.static.GetWeaponAimModClose(kWeapon.eType) + (class'SU_Utils'.static.IsShortDistanceWeapon(kWeapon.eType) ? 0 : class'SquadronUnleashed'.default.AIM_BONUS_CLOSE_DISTANCE_GLOBAL));
    kMainPanel.AS_SetStatData(0, "("$class'UIItemCards'.default.m_strRangeLong @ "/" @ class'UIItemCards'.default.m_strRangeShort$")" @ class'UIUtilities'.static.InjectHTMLImage("img:///gfxMessageMgr.Attack",22,22,-2) $":", tmpStr);
	switch(shipWpnRange)
    {
        case 0:
            tmpStr = class'UIItemCards'.default.m_strRangeShort;
            break;
        case 1:
            tmpStr = class'UIItemCards'.default.m_strRangeMedium;
            break;
        case 2:
            tmpStr = class'UIItemCards'.default.m_strRangeLong;
            break;
    }
    kMainPanel.AS_SetStatData(1, class'UIItemCards'.default.m_strRangeLabel, tmpStr);
    switch(shipWpnFireRate)
    {
		case 0:
			tmpStr = class'UIItemCards'.default.m_strRateSlow;
            break;
		case 1:
			tmpStr = class'UIItemCards'.default.m_strRateMedium;
            break;
        case 2:
			tmpStr = class'UIItemCards'.default.m_strRateRapid;
			break;
    }
    kMainPanel.AS_SetStatData(2, class'UIItemCards'.default.m_strFireRateLabel, tmpStr);
    switch(shipWpnBaseDamage)
    {
		case 0:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleLow;
			break;
		case 1:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleMedium;
            break;
        case 2:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleHigh;
            break;
    }
    kMainPanel.AS_SetStatData(3, class'UIItemCards'.default.m_strDamageLabel, tmpStr);
    switch(shipWpnArmorPen)
    {
		case 0:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleLow;
            break;
        case 1:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleMedium;
            break;
        case 2:
			tmpStr = class'UIItemCards'.default.m_strGenericScaleHigh;
            break;
    }
    kMainPanel.AS_SetStatData(4, class'UIItemCards'.default.m_strArmorPenetrationLabel, tmpStr);
    kMainPanel.AS_SetWeaponName(class'SU_Utils'.static.GetShipWeaponName(kWeapon.eType));
	tmpStr = kMainPanel.GetMgr().m_kTable.arrSummaries[kMainPanel.m_iCurrentSelection].txtSummary.StrValue;
	UIModGfxTextField(manager.GetVariableObject(kMainPanel.GetMCPath() $ ".description", class'UIModGfxTextField')).SetHTMLText(tmpStr);
}
function SetPanelFocus(bool bNewHasFocus)
{
	local GFxObject gfxPanel;
	local UIShipLoadout kPanelToReceiveFocus, kPanelToLoseFocus;
	local ASDisplayInfo tDisplay;

	if(m_bHasControllerFocus != bNewHasFocus)
	{
		m_bHasControllerFocus = bNewHasFocus;
		if(!manager.IsMouseActive())
		{
			kPanelToReceiveFocus = bNewHasFocus ? self : class'SU_Utils'.static.GetSquadronMod().m_kShipLoadoutPrimary;
			kPanelToLoseFocus = bNewHasFocus ? class'SU_Utils'.static.GetSquadronMod().m_kShipLoadoutPrimary : self;
	
			gfxPanel = kPanelToReceiveFocus.manager.GetVariableObject(string(kPanelToReceiveFocus.GetMCPath()));
			tDisplay = gfxPanel.GetDisplayInfo();
			tDisplay.Alpha = 100;
			gfxPanel.SetDisplayInfo(tDisplay);

			gfxPanel = kPanelToLoseFocus.manager.GetVariableObject(string(kPanelToLoseFocus.GetMCPath()));
			tDisplay = gfxPanel.GetDisplayInfo();
			tDisplay.Alpha = 50;
			gfxPanel.SetDisplayInfo(tDisplay);
		}
	}
}
function UpdateFocusFromMouseCursor()
{
	if(manager.IsMouseActive() && !controllerRef.m_Pres.GetHUD().DialogBox.ShowingDialog())
	{
		SetPanelFocus(controllerRef.m_Pres.m_kUIMouseCursor.m_v2MouseLoc.X > 615);
	}
	SetTimer(0.10, false, GetFuncName());
}
function OnCloseShipLoadout()
{
	LogInternal(GetFuncName());
	class'SU_Utils'.static.GetSquadronMod().GetMyInputGate().PopFromScreenStack();
	screen.panels.RemoveItem(self);
	UIShipLoadout(screen).OnMouseCancel();
}
event Destroyed()
{
	WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchPrimaryCurrentSelection);
	SU_XGHangarUI(GetMgr()).CalculateInterceptorHoursDown();
	super(UI_FxsPanel).Destroyed();//NOT super.Destroyed - it would attempt to remove a non-registered screen and CTD
}
simulated function AS_SetWeaponDescription(string txt)
{
	UIModGfxTextField(manager.GetVariableObject(GetMCPath() $ ".description", class'UIModGfxTextField')).SetHTMLText(txt);
	UIModGfxTextField(manager.GetVariableObject(GetMCPath() $ ".description", class'UIModGfxTextField')).SetVisible(true);
}
DefaultProperties
{
	m_bHasControllerFocus=true
	s_name="theScreen2"
}