/** This is manager class for secondary weapon panel in UIShipLoadout screen and for SU_UIPilotRoster*/
class SU_XGHangarUI extends XGHangarUI;

var EItemType m_eWeaponEquipped;
var int m_iWatchShipWeapons;
var int m_iWatchDialogData;
var bool m_bPrimaryLoadoutChanged;
var bool m_bSecondaryLoadoutChanged;
var int m_iRearmHours;
var array<TContinentInfoWithPilots> m_arrContinentsInfo;
var localized string m_strLabelChoosePilot;
var localized string m_strLabelChangePilot;

function Init(int iView)
{
	if(SU_UIPilotRoster(m_kInterface) == none)//not pilot roster
	{
		m_iWatchDialogData = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES().GetHUD().DialogBox, 'm_arrData', self, OnDialogDataChange);
	}
	super.Init(iView);
}
function GoToView(int iView)
{
	`Log(GetFuncName() @ iView @ self);
	if(m_kShip == none && (PRES().IsInState('State_HangarShipSummary') || PRES().IsInState('State_HangarShipLoadout')) )
	{
		m_kShip = XGHangarUI(PRES().GetMgr(class'XGHangarUI')).m_kShip;
		UpdateWatchVariables();
	}
	super.GoToView(iView);
}
function UpdateWatchVariables()
{
	if(m_iWatchShipWeapons != -1)
	{
		StopWatchingWeapons();
	}
	if(m_iCurrentView == 2 && m_kShip != none)//ship loadout
	{
		StartWatchingWeapons();
	}
}
function UIShipLoadout MainWeaponPanel()
{
	return class'SU_Utils'.static.GetSquadronMod().m_kShipLoadoutPrimary;
}
function SU_UIShipLoadout SecondaryWeaponPanel()
{
	return class'SU_Utils'.static.GetSquadronMod().m_kShipLoadoutSecondary;
}
/** Callback to override dialog box data in order to display correct rearm hours in ship loadout screen or when transfering ship*/
function OnDialogDataChange()
{
	local UIDialogueBox kDialog;
    local XGParamTag kTag;
	local UIShipLoadout kPanel;
	local string strDialogTxt;

	if(!PRES().IsInState('State_HangarShipLoadout') && !PRES().IsInState('State_HangarShipList') || class'SU_Utils'.static.GetHelpMgr().IsInState('ProcessingQueue'))
	{
		return;
	}
	kDialog = PRES().GetHUD().DialogBox;
	if(kDialog != none && kDialog.m_arrData.Length > 0)
	{
		strDialogTxt = kDialog.m_arrData[0].strText;
		if(PRES().IsInState('State_HangarShipLoadout'))
		{
			kPanel = SecondaryWeaponPanel().m_bHasControllerFocus ? SecondaryWeaponPanel() : MainWeaponPanel();
			kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
			kTag.StrValue0 = kPanel.GetMgr().m_kTable.mnuOptions.arrOptions[kPanel.m_iCurrentSelection].arrStrings[0];
			kTag.IntValue0 = class'SU_Utils'.static.GetWeaponRearmHours(class'SU_Utils'.static.ItemTypeToShipWeapon(kPanel.GetMgr().m_arrItems[kPanel.m_iCurrentSelection].iItem));
			if(kTag.IntValue0 < m_iRearmHours)
			{
				kTag.IntValue0 = m_iRearmHours;
			}
			strDialogTxt = class'XComLocalizer'.static.ExpandString(kPanel.m_strConfirmEquipDialogText);
		}
		else if(PRES().IsInState('State_HangarShipList') && PRES().m_kShipList.m_bTransferingShip)
		{
			kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
			if(InStr(kTag.StrValue0, class'SquadronUnleashed'.default.m_strNoPilotAssigned) != -1)
			{
				kTag.StrValue0 = Repl(kTag.StrValue0, class'SquadronUnleashed'.default.m_strNoPilotAssigned, class'XGItemTree'.default.ShipTypeNames[PRES().m_kShipList.m_kSelectedShip.GetType()], false);
			}
			strDialogTxt = class'XComLocalizer'.static.ExpandString(class'UIShipList'.default.m_strConfirmTransferDialogText);
		}
		kDialog.UpdateDialogText(strDialogTxt);
		if(PRES().m_kShipLoadout != none && kDialog.m_arrData[kDialog.m_arrData.Length -1].fnCallback == PRES().m_kShipLoadout.OnConfirmDialogComplete)
		{
			kDialog.m_arrData[kDialog.m_arrData.Length -1].fnCallback = OnConfirmPrimaryLoadoutChange;//override main callback function
		}	
	}
}
function OnConfirmPrimaryLoadoutChange(EUIAction eAction)
{
	local int iOption;
	
	`Log(GetFuncName() @ self, class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	iOption = PRES().m_kShipLoadout.m_iCurrentSelection; 
    if(eAction == eUIAction_Accept)
    {
	    if(PRES().m_kShipLoadout.GetMgr().m_kTable.mnuOptions.arrOptions[iOption].iState == 1)
		{
			PlayBadSound();
		}
		else
		{
			PRES().m_kShipSummary.m_bUpdateDataOnReceiveFocus = true;
			HANGAR().EquipWeapon(EItemType(PRES().m_kShipLoadout.GetMgr().m_arrItems[iOption].iItem), XGShip_Interceptor(m_kShip));
			//GoToView(1); stay in ship loadout view
		}
    }
    else
    {
        PlayCloseSound();
    }
}
/** Updates secondary weapon's 3D mesh on hangar ship model*/
function UpdateShipWeaponView(XGShip_Interceptor kShip, EShipWeapon eWeapon)
{
	local XGHangarShip kCinShip;
	
	kCinShip = HANGAR().m_kViewWeaponsShip;
	if(kCinShip.kLeftWeaponMesh == none)
	{
		kCinShip.kLeftWeaponMesh = new (self) class'StaticMeshComponent';
	}
	kCinShip.SkeletalMeshComponent.DetachComponent(kCinShip.kLeftWeaponMesh);
	kCinShip.kLeftWeaponMesh.SetLightingChannels(kCinShip.SkeletalMeshComponent.LightingChannels);
	kCinShip.kLeftWeaponMesh.SetShadowParent(kCinShip.SkeletalMeshComponent);
	if(eWeapon < 0)
	{
		kCinShip.kLeftWeaponMesh = none;
	}
	else
	{
		if(eWeapon == eShipWeapon_None)
		{
			eWeapon = eShipWeapon_Cannon;
		}
		else if(eWeapon == eShipWeapon_Stingray)
		{
			eWeapon = eShipWeapon_Avalanche;
		}
		kCinShip.kLeftWeaponMesh.SetStaticMesh(XComGameInfo(WorldInfo.Game).JetWeaponMeshes[eWeapon]);
		kCinShip.SkeletalMeshComponent.AttachComponentToSocket(kCinShip.kLeftWeaponMesh, 'Hardpoint_L1');
		kCinShip.kLeftWeaponMesh.SetLightEnvironment(kCinShip.SkeletalMeshComponent.LightEnvironment);
	}
}
/** Callback after option's selection in ship loadout screen*/
function OnChooseTableOption(int iOption)
{
	LogInternal(Name $ "." $ GetFuncName(), 'SquadronUnleashed');
	if(m_kTable.mnuOptions.arrOptions[iOption].iState == 1)
	{
		PlayBadSound();
	}
	else
	{
		XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).m_kShipSummary.m_bUpdateDataOnReceiveFocus = true;
		EquipWeapon(EItemType(m_arrItems[iOption].iItem), XGShip_Interceptor(m_kShip), true);
		//GoToView(1);//no, no - we wanna stay in view 2 :)
	}
}
/** Update list of ship weapons for ship loadout screen*/
function UpdateTableMenu()
{
	local THangarTable kTable;
	local TTableMenu kTableMenu;
	local int iMenuItem;

	kTableMenu.arrCategories.AddItem(2);//item category
	kTableMenu.arrCategories.AddItem(4);//quantity category
	m_arrItems = HANGAR().GetUpgrades(XGShip_Interceptor(m_kShip));
	class'SU_Utils'.static.FilterWeaponsForSlot(2, m_arrItems);
	m_arrItems.Insert(0,1);//empty slot for Vulcan Cannon
	for(iMenuItem=0; iMenuItem < m_arrItems.Length; ++ iMenuItem)
	{
		kTableMenu.arrOptions.AddItem(BuildTableItem(m_arrItems[iMenuItem]));
		kTable.arrSummaries.AddItem(BuildItemSummary(m_arrItems[iMenuItem]));
	}
	kTableMenu.kHeader.arrStrings = GetHeaderStrings(kTableMenu.arrCategories);
	kTableMenu.kHeader.arrStates = GetHeaderStates(kTableMenu.arrCategories);
	kTableMenu.bTakesNoInput = false;
	kTable.mnuOptions = kTableMenu;
	m_kTable = kTable;
	UpdatePrimaryWeaponPanel();
}
/** Ensures update of data for main weapon panel after secondary weapon changed*/
function UpdatePrimaryWeaponPanel()
{
	local THangarTable kTable;
	local array<TItem> arrItems;
	local int iMenuItem, iShipWeapon;

	PRES().m_kShipLoadout.GetMgr().UpdateTableMenu();//cache data from original function
	arrItems = PRES().m_kShipLoadout.GetMgr().m_arrItems;//grab the cached item data
	kTable = PRES().m_kShipLoadout.GetMgr().m_kTable;//grab the cached table menu
	for(iMenuItem=arrItems.Length-1; iMenuItem >= 0; --iMenuItem)
	{
		//filter out non-fitting weapons
		iShipWeapon = class'SU_Utils'.static.ItemTypeToShipWeapon(arrItems[iMenuItem].iItem);
		kTable.mnuOptions.arrOptions[iMenuItem].arrStrings[0] = class'SU_Utils'.static.GetShipWeaponName(iShipWeapon);
		if(!class'SU_Utils'.static.WeaponFitsPrimarySlot(iShipWeapon))
		{
			kTable.mnuOptions.arrOptions.Remove(iMenuItem, 1);
			kTable.arrSummaries.Remove(iMenuItem, 1);
			arrItems.Remove(iMenuItem, 1);//this is probably redundant but better to keep it clean
		}
		else if(m_bPrimaryLoadoutChanged)
		{
			kTable.mnuOptions.arrOptions[iMenuItem].iState = 1;
		}
	}
	PRES().m_kShipLoadout.GetMgr().m_kTable = kTable;//put back the filtered menu data
	PRES().m_kShipLoadout.GetMgr().m_arrItems = arrItems;//...and items data
	PRES().m_kShipLoadout.m_iCurrentSelection = Clamp(PRES().m_kShipLoadout.m_iCurrentSelection, 0, arrItems.Length -1);
	PRES().m_kShipLoadout.UpdateData();//push data to primary screen
	UpdatePanelHeaders();
}
/** Build single weapon option for ship loadout screen*/
function TTableMenuOption BuildTableItem(TItem kItem)
{
	local TTableMenuOption kOption;

	if(kItem.iItem == 0) //Vulcan Cannon
	{
		kOption.arrStrings[0] = class'SU_UIShipLoadout'.default.m_strVulcanCannonName;
		kOption.arrStates[0] = 0;
		kOption.arrStrings[1] = "";
		kOption.arrStates[1] = 0;
	}
	else
	{
		kOption = super.BuildTableItem(kItem);
		kOption.arrStrings[0] = class'SU_Utils'.static.GetShipWeaponName(class'SU_Utils'.static.ItemTypeToShipWeapon(kItem.iItem));
	}
	if(m_bSecondaryLoadoutChanged || m_kShip.m_kTShip.arrWeapons[1] == class'SU_Utils'.static.ItemTypeToShipWeapon(kItem.iItem) || (kItem.iItem == 122 && !XGShip_Interceptor(m_kShip).IsFirestorm()) )
	{
		kOption.iState = 1;//disable option if already changed loadout or item=currentWeapon, or item=Fusion and ship!=Firestorm
	}
	else
	{
		kOption.iState = 0;
	}
	return kOption;
}
/** Build single weapon summary txt for ship loadout screen*/
function XGHangarUI.TTableItemSummary BuildItemSummary(TItem kItem)
{
    local XGHangarUI.TTableItemSummary kSummary;

	if(kItem.iItem == 0) //Vulcan Cannon
	{
	    kSummary.txtTitle.StrValue = class'SU_UIShipLoadout'.default.m_strVulcanCannonName;
		kSummary.txtSummary.StrValue =class'SU_UIShipLoadout'.default.m_strVulcanCannonDesc;
		kSummary.imgOption.iImage = 118;//phoenix (this is overriden anyway)
	}
	else
	{
		kSummary = super.BuildItemSummary(kItem);
	}
    return kSummary;
}
/** Equip secondary weapon*/
function EquipWeapon(EItemType eItem, XGShip_Interceptor kShip, optional bool bStorageUpdate=true)
{
	`Log(GetFuncName() @ eItem @ kShip @ bStorageUpdate);
	kShip.m_kTShip.arrWeapons.Length = 2;
	if((eItem > 0 && kShip.m_kTShip.arrWeapons[1] == int(HANGAR().ItemTypeToShipWeapon(eItem))) || (eItem == 0 && kShip.m_kTShip.arrWeapons[1] == 0))
	{
		`Log("eItem matches currently equipped weapon");
		m_eWeaponEquipped = eItem;
		return;
	}
	else if(bStorageUpdate)//if this is not when main panel erased arrWeapons
	{
		if(eItem > 0)
		{
			STORAGE().RemoveItem(eItem, 1);
		}
		if(kShip.m_kTShip.arrWeapons[1] != 0)
		{
			STORAGE().AddItem(HANGAR().ShipWeaponToItemType(EShipWeapon(kShip.m_kTShip.arrWeapons[1])));
		}
		Sound().PlaySFX(SNDLIB().SFX_Facility_ConstructItem);
		kShip.m_iStatus = 7;
	}
	if(!m_bSecondaryLoadoutChanged)
	{
		m_bSecondaryLoadoutChanged = (eItem != m_eWeaponEquipped);
	}
	m_eWeaponEquipped = eItem;
	class'SU_Utils'.static.SaveValue(m_kShip, "SecondaryWeapon", class'SU_Utils'.static.ItemTypeToShipWeapon(m_eWeaponEquipped));
	StopWatchingWeapons();//to avoid OnMainWeaponChanged() call
	kShip.m_kTShip.arrWeapons[1] = (eItem > 0 ? int(HANGAR().ItemTypeToShipWeapon(eItem)) : 0);
	StartWatchingWeapons();
	if(eItem > HANGAR().m_eBestWeaponEquipped)
	{
		HANGAR().m_eBestWeaponEquipped = eItem;
	}
	UpdateTableMenu();
	SecondaryWeaponPanel().UpdateData();
	UpdatePanelHeaders();
	CalculateInterceptorHoursDown();
}
/** Calculates resulting rearm hours considering both weapon slot changes*/
function CalculateInterceptorHoursDown(optional bool bCalcOnly, optional out int iHoursOut)
{
	local int iHours1, iHours2;
	local string strDebug;

	if(m_bPrimaryLoadoutChanged)
		iHours1 = class'SU_Utils'.static.GetWeaponRearmHours(m_kShip.m_kTShip.arrWeapons[0]);
	if(m_bSecondaryLoadoutChanged)
		iHours2 = class'SU_Utils'.static.GetWeaponRearmHours(m_kShip.m_kTShip.arrWeapons[1]);
	iHoursOut = Max(iHours1, iHours2);
	if(!bCalcOnly)
	{
		m_iRearmHours = iHoursOut;
		XGShip_Interceptor(m_kShip).m_iHoursDown = m_iRearmHours;
	}
	strDebug = string(GetFuncName());
	strDebug @= ("iHours1="$iHours1);
	strDebug @= ("iHours2="$iHours2);
	strDebug @= ("m_iHoursDown="$Max(iHours1, iHours2));
	`log(strDebug, class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
}
function StopWatchingWeapons()
{
	WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchShipWeapons);
	m_iWatchShipWeapons = -1;
}
function StartWatchingWeapons()
{
	m_iWatchShipWeapons = WorldInfo.MyWatchVariableMgr.RegisterWatchVariableStructMember(m_kShip, 'm_kTShip', 'arrWeapons', self, OnMainWeaponChanged);
}
/** Callback when weapons changed via main weapon panel - which clears arrWeapons*/
function OnMainWeaponChanged()
{
	`Log(GetFuncName() @ self, class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	m_bPrimaryLoadoutChanged = true;
	EquipWeapon(m_eWeaponEquipped, XGShip_Interceptor(m_kShip), false);//only update weapon arrays, no StorageUpdate or other stuff
	UpdateTableMenu();
	SecondaryWeaponPanel().UpdateData();
	CalculateInterceptorHoursDown();
}
/** Update weapon names of main/secondary panel based on current loadout*/
function UpdatePanelHeaders()
{
	local UIShipLoadout kUI1, kUI2;
	local UIModGfxTextField gfxTitle1, gfxTitle2;

	kUI1 = MainWeaponPanel();
	gfxTitle1 =  UIModGfxTextField(kUI1.manager.GetVariableObject(kUI1.GetMCPath() $".title", class'UIModGfxTextField'));
	gfxTitle1.m_sFontFace="$TitleFont";
	gfxTitle1.RealizeFormat();
	gfxTitle1.SetHTMLText(class'UIUtilities'.static.GetHTMLColoredText( CAPS(class'SU_UIShipLoadout'.default.m_strWeaponColumnPrimary$SHIPWEAPON(m_kShip.m_kTShip.arrWeapons[0]).strName), 2, 28) );
	
	kUI2 = SecondaryWeaponPanel();
	gfxTitle2 =  UIModGfxTextField(kUI2.manager.GetVariableObject(kUI2.GetMCPath() $".title", class'UIModGfxTextField'));
	gfxTitle2.m_sFontFace="$TitleFont";
	gfxTitle2.RealizeFormat();
	gfxTitle2.SetHTMLText(class'UIUtilities'.static.GetHTMLColoredText( CAPS(class'SU_UIShipLoadout'.default.m_strWeaponColumnSecondary$SHIPWEAPON(m_kShip.m_kTShip.arrWeapons[1]).strName), 2, 28) );
}
/** Updates header of various hangar screens (determined by m_iCurrentView)*/
function UpdateHeader()
{
	if(m_iCurrentView < 6)
	{
		super.UpdateHeader();
	}
}
/** */
function ExtendShipSummaryGfx()
{
	local UIShipSummary kUI;
	local GFxObject gfxPanel, gfxBg, gfxObj1, gfxObj2;
	local UIModGfxTextField gfxTextField;
	local ASDisplayInfo tDisplay;

	`Log(GetFuncName());
	kUI = PRES().m_kShipSummary;
	if(kUI != none)
	{
		gfxPanel = kUI.manager.GetVariableObject(string(kUI.GetMCPath()));
		gfxBg = class'UIModUtils'.static.AS_GetInstanceAtDepth(1-16384, gfxPanel);
		tDisplay = gfxBg.GetDisplayInfo();
		tDisplay.X += 272.0;
		tDisplay.XScale = 164;
		gfxBg.SetDisplayInfo(tDisplay);

		gfxObj1 = gfxPanel.GetObject("imageContainerMC");
		gfxObj2 = class'UIModUtils'.static.AS_DuplicateMovieClip(class'UIModUtils'.static.AS_GetPath(gfxObj1), "imageContainerMC2", kUI.manager);
		tDisplay = gfxObj2.GetDisplayInfo();
		tDisplay.X = 20.0;
		tDisplay.Y = gfxObj1.GetFloat("_y")+15;
		tDisplay.XScale = 85;
		tDisplay.YScale = 85;
		gfxObj2.SetDisplayInfo(tDisplay);

		gfxObj1 = gfxPanel.GetObject("imageBracket");
		gfxObj2 = class'UIModUtils'.static.AS_DuplicateMovieClip(class'UIModUtils'.static.AS_GetPath(gfxObj1), "imageBracket2", kUI.manager);
		tDisplay = gfxObj2.GetDisplayInfo();
		tDisplay.X += 312;
		tDisplay.Y = gfxObj1.GetFloat("_y");
		tDisplay.XScale = 131;
		tDisplay.YScale = 131;
		gfxObj2.SetDisplayInfo(tDisplay);

		gfxTextField = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(gfxPanel, "weapon2Label",20,218,250,30,, class'UIModGfxTextField'));
		gfxTextField.m_sFontFace = "$TitleFont";
		gfxTextField.m_FontSize = 24;
		gfxTextField.RealizeFormat();
		gfxTextField.m_sTextAlign = "right";
		gfxTextField.RealizeProperties();
	}
}
static function TItemCard BuildShipWeaponCard(EItemType eWeapon)
{
    local TItemCard kItemCard;
    local TShipWeapon kWeapon;

	kWeapon = class'SU_Utils'.static.GetGameCore().SHIPWEAPON(class'SU_Utils'.static.ItemTypeToShipWeapon(eWeapon));
	kItemCard.m_type = 3;
	kItemCard.m_strName = kWeapon.strName;
	if(class'SU_Utils'.static.GetAmmoForWeaponType(kWeapon.eType) > 0)
	{
		kItemCard.m_strName @= "("$ class'SU_Utils'.static.GetAmmoForWeaponType(kWeapon.eType) $")";
	}
	kItemCard.m_iBaseDamage = class'SU_Utils'.static.GetShipWeaponDamageBin(kWeapon.iDamage);
	kItemCard.m_shipWpnRange = class'SU_Utils'.static.GetShipWeaponRangeBin(kWeapon.eType);
	kItemCard.m_shipWpnHitChance = kWeapon.iToHit;
	kItemCard.m_shipWpnArmorPen = class'SU_Utils'.static.GetShipWeaponArmorPenetrationBin(kWeapon.iAP);
	kItemCard.m_shipWpnFireRate = class'SU_Utils'.static.GetShipWeaponFiringRateBin(kWeapon.fFiringTime);
	if(eWeapon == 0)
	{
		kItemCard.m_strFlavorText = class'SU_UIShipLoadout'.default.m_strVulcanCannonDesc;
	}
	else
	{
		kItemCard.m_strFlavorText = class'XComLocalizer'.static.ExpandString(class'XGLocalizedData'.default.ShipWeaponFlavorTxt[kWeapon.eType]);
	}
	kItemCard.m_item = eWeapon;
	return kItemCard;
}
function AS_ShipSummarySetSecondaryWeaponData()
{
	local string strImagePath, strWeaponName;
	local TShipWeapon tW;
	local UIModGfxTextField gfxTextField;
	local GFxObject gfxObj;

	m_kShip = PRES().m_kShipSummary.m_kShip;//get the ship from original screen
	tW = SHIPWEAPON(m_kShip.m_kTShip.arrWeapons[1]);
	if(tW.eType == 0)
	{
		strImagePath = "img:///"$class'SquadronUnleashed'.default.m_strVulcanCanonImgPath;
	}
	else
	{
		strImagePath = class'UIUtilities'.static.GetInventoryImagePath(class'SU_Utils'.static.ShipWeaponToItemType(m_kShip.m_kTShip.arrWeapons[1]));
	}
	gfxObj = PRES().m_kShipSummary.manager.GetVariableObject(PRES().m_kShipSummary.GetMCPath() $ ".imageContainerMC2");
	class'UIModUtils'.static.AS_BindImage(gfxObj, strImagePath);
	strWeaponName = class'SU_Utils'.static.GetShipWeaponName(tW.eType);
	gfxTextField = UIModGfxTextField(PRES().m_kShipSummary.manager.GetVariableObject(PRES().m_kShipSummary.GetMCPath() $ ".weapon2Label", class'UIModGfxTextField'));
	gfxTextField.SetHTMLText(strWeaponName);
}
function OverrideRenameButton()
{
	local UIShipSummary kUI;

	kUI = PRES().m_kShipSummary;
	kUI.AS_SetWeaponHelp(2, class'SU_Utils'.static.GetPilot(kUI.m_kShip) == none ? m_strLabelChoosePilot : m_strLabelChangePilot, class'UI_FxsGamepadIcons'.static.GetAdvanceButtonIcon(), false);
}
function AS_AddSecondaryWeaponInfoButton()
{
	local UIShipSummary kScreen;
	local GFxObject gfxNavBar;
	
	kScreen = PRES().m_kShipSummary;
	gfxNavBar = kScreen.manager.GetVariableObject(kScreen.GetMCPath()$".helpBarMC");
	gfxNavBar.GetObject("rightContainerStartPos").SetFloat("x", 285);
	gfxNavBar.GetObject("rightContainer").SetFloat("padding", 170);
	//kScreen.UpdateButtonHelp();
	if(kScreen.m_kNavBar.m_arrButtonClickDelegates.Find(OnSecondWeaponInfo) < 0)
	{
		kScreen.m_kNavBar.AddRightHelp(class'SquadronUnleashed'.static.IsLWR() ? "WEAPON INFO" : class'UIShipSummary'.default.m_strWeaponInfoBtnHelp, XComPlayerController(GetALocalPlayerController()).IsMouseActive() ? "" : class'UI_FxsGamepadIcons'.const.ICON_RT_R2, OnSecondWeaponInfo);
	}
}
function UpdateShipSummaryHeader()
{
	local UIShipSummary kScreen;
	local SU_Pilot kPilot;
	local UIModGfxTextField gfxHeader;

	kScreen = PRES().m_kShipSummary;
	kPilot = class'SU_Utils'.static.GetPilot(XGShip_Interceptor(m_kShip));
	if(kPilot != none)
	{
		kScreen.AS_SetKills(kPilot.StatsToString());
		gfxHeader = UIModGfxTextField(kScreen.manager.GetVariableObject(kScreen.GetMCPath() $ ".shipName", class'UIModGfxTextField'));
		gfxHeader.m_sFontFace="$TitleFont";
		gfxHeader.m_FontSize=32.0;
		gfxHeader.m_sTextAlign="center";
		gfxHeader.SetHTMLText(kPilot.GetCallsignWithRank());
	}
	kScreen.manager.GetVariableObject(kScreen.GetMCPath() $ ".shipName").SetFloat("_x", -350);
	kScreen.manager.GetVariableObject(kScreen.GetMCPath() $ ".kills").SetFloat("_x", -270);
}
function OnSecondWeaponInfo()
{
	local TItemCard cardData;
	local TShipWeapon kWeapon;

	if(!PRES().IsInState('State_ItemCard'))
	{
		kWeapon = SHIPWEAPON(m_kShip.m_kTShip.arrWeapons[1]);
		cardData = BuildShipWeaponCard(EItemType(class'SU_Utils'.static.ShipWeaponToItemType(kWeapon.eType)));
		PRES().UIItemCard(cardData);
	}
}
function OnAssignPilotClick()
{
	class'SU_Utils'.static.GetSquadronMod().UIAssignPilot(PRES().m_kShipSummary.m_kShip);
}
function OnCloseShipSummary()
{
	class'SU_Utils'.static.GetSquadronMod().GetMyInputGate().PopFromScreenStack();
	PRES().m_kShipSummary.OnCancel();
}
event Destroyed()
{
	if(m_iWatchShipWeapons != -1) WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchShipWeapons);
	if(m_iWatchDialogData != -1) WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchDialogData);
}
simulated function OnLeaveFacility()
{
	super(XGHangarUI).OnLeaveFacility();
}
/** Update hangar's main menu data*/
function UpdateMain()
{
	local TMenu kMainMenu;
	local TMenuOption kOption;

	super.UpdateMain();
	kMainMenu = m_kMainMenu.mnuOptions;

	//add "View Pilot Roster" button
	kOption.strText = class'SU_UIStrategyHUD_FSM_Hangar'.default.m_strViewPilotsLabel;
	if(class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.RequiresAttention())
	{
		kOption.strText = "<font color='#"$class'UIUtilities'.const.WARNING_HTML_COLOR$"'>!</font>" @ kOption.strText;
	}
	kOption.strHelp = class'SU_UIStrategyHUD_FSM_Hangar'.default.m_strViewPilotsHelp;
	kOption.iState=0;
	kMainMenu.arrOptions.AddItem(kOption);
	class'SU_Utils'.static.GetSquadronMod().m_kHangarMenu.m_iOptionPilotRoster = kMainMenu.arrOptions.Length - 1;

	//add "Air Force HQ" button
	kOption.strText = class'SU_UIStrategyHUD_FSM_Hangar'.default.m_strAirforceCommandLabel;
	kOption.strHelp = class'SU_UIStrategyHUD_FSM_Hangar'.default.m_strAirforceCommandHelp;
	kOption.iState=0;
	kMainMenu.arrOptions.AddItem(kOption);
	class'SU_Utils'.static.GetSquadronMod().m_kHangarMenu.m_iOptionAirforceCommand = kMainMenu.arrOptions.Length - 1;

	//add "Training Center" button
	if( !class'SU_Utils'.static.GetSquadronMod().m_bDisablePilotXP)
	{
		kOption.strText = class'SU_UIStrategyHUD_FSM_Hangar'.default.m_strTrainingCenterLabel;
		kOption.strHelp = class'SU_UIStrategyHUD_FSM_Hangar'.default.m_strTrainingCenterHelp;
		kOption.iState=0;
		kMainMenu.arrOptions.AddItem(kOption);
		class'SU_Utils'.static.GetSquadronMod().m_kHangarMenu.m_iOptionTrainingCenter = kMainMenu.arrOptions.Length - 1;
	}
	m_kMainMenu.mnuOptions = kMainMenu;
}
/** Cache data for pilot roster screen.*/
function UpdatePilotList()
{
	local array<TContinentInfoWithPilots> kContinentList;
	local int iContinent;

	if(m_iCurrentView == 6 || (m_iCurrentView == 7 && m_kShip == none))//view pilot roster or sign-up a pilot for training
	{
		for(iContinent=0; iContinent < 5; ++iContinent)
		{
			if(iContinent == HQ().m_iContinent)
			{
				kContinentList.InsertItem(0, class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.GetContinentInfo(EContinent(iContinent)));
			}
			else
			{
				kContinentList.AddItem(class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.GetContinentInfo(EContinent(iContinent)));
			}
		}
	}
	else if(m_iCurrentView == 7 && m_kShip != none)//assign pilot
	{
		kContinentList.AddItem(class'SU_Utils'.static.GetSquadronMod().m_kPilotQuarters.GetContinentInfo(EContinent(XGShip_Interceptor(m_kShip).m_iHomeContinent)));
	}
	m_arrContinentsInfo = kContinentList;
}

DefaultProperties
{
	m_iWatchShipWeapons=-1
}