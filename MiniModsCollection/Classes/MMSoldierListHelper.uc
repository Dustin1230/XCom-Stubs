class MMSoldierListHelper extends XGStrategyActor;

const WIDGET_ID_SELECT_ORDER=0;
const WIDGET_ID_SORT_LIST=1;
var UISoldierListBase m_kSoldierList;
var XGStrategySoldier m_kSoldier;
var GFxObject m_gfxList;
var GFxObject m_gfxAbilities;
var MMGfx_WidgetHelper m_gfxWidgetHelper;
var UIWidgetHelper m_kWidgetHelper;
var UIModInputGate m_kInputGate;
var TTableMenu m_tSoldierListData;
var int m_iWatchPresState;
var int m_iWatchSelection;
var int m_iSelectedItem;
var bool m_bCustomFilterApplied;
var bool m_bCustomOrderApplied;
var bool m_bReverseOrderPending;
var bool m_bReverseOrderApplied;
var bool m_bSortingModEnabled;
var bool m_bShowingPerksEnabled;
var int m_iCurrentSortingCategory;
var localized string m_strSortListLabel;
var localized string m_strReverseOrderLabel;
var localized string m_strSelectOrderLabel;

function Init(optional int iInitalSortingOrder = -1, optional bool bReverseOrder, optional UISoldierListBase kList=PRES().m_kSoldierList)
{
	m_kSoldierList = kList;
	m_gfxList = m_kSoldierList.manager.GetVariableObject(string(m_kSoldierList.GetMCPath()));
	m_iWatchPresState = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_aStateStack', self, OnPresStateChanged);
	m_iWatchSelection = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kSoldierList, 'm_iCurrentSelection', self, OnNewSelection);
	m_iCurrentSortingCategory = iInitalSortingOrder;
	if(m_bShowingPerksEnabled)
	{
		if(m_gfxAbilities == none)
		{
			AttachAbilitiesPanel();
		}
		else
		{
			SetTimer(0.20, false, 'AS_SetupGfx');
		}
	}
	if(m_bSortingModEnabled)
	{
		AttachSortFilterButtons();
		InitWidgetHelper();
		ApplyInitialSortingOrder(bReverseOrder);
	}
	m_kInputGate = Spawn(class'UIModInputGate');
	m_kInputGate.GateInit(m_kSoldierList, OnMouseEvent, OnUnrealCommand);
	SetTimer(0.30, false, 'OnNewSelection');
}
function Uninit(optional bool bDestroy=true)
{
	WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchPresState);
	WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchSelection);
	m_kInputGate.PopFromScreenStack();
	if(bDestroy)
	{
		Destroy();
	}
	else
	{
		ClearAllTimers();
	}
}
event Destroyed()
{
	local array<ASValue> arrParams;

	ClearAllTimers();
	if(m_gfxAbilities != none)
	{
		arrParams.Length=0;
		m_gfxAbilities.Invoke("removeMovieClip", arrParams);
	}
	if(m_kWidgetHelper != none)
	{
		m_kWidgetHelper.Destroy();
		m_gfxWidgetHelper = none;
	}
}
function OnPresStateChanged()
{
	if(PRES().IsInState('State_SoldierList'))
	{
		OnReceiveFocus();
	}
	else
	{
		OnLoseFocus();
	}
}
function OnReceiveFocus()
{
	SetTickIsDisabled(false);
	SetTimer(0.30, false, 'PushInputGate');
	if(m_bSortingModEnabled)
	{
		UpdateSortListButton();
	}
}
function OnLoseFocus()
{
	SetTickIsDisabled(true);
	PopInputGate();
}
function PushInputGate()
{
	if(PRES().IsInState('State_SoldierList'))
	{
		m_kInputGate.GateInit(m_kSoldierList, OnMouseEvent, OnUnrealCommand);
		m_kInputGate.BringToTopOfScreenStack();
	}
}
function PopInputGate()
{
	m_kInputGate.PopFromScreenStack();
}
function OnNewSelection()
{
	local array<ASValue> arrParams;

	if(m_gfxAbilities != none && m_bShowingPerksEnabled && PRES().IsInState('State_SoldierList'))
	{
		arrParams.Length=0;
		m_gfxAbilities.Invoke("clear", arrParams);
		UpdateAbilities();
		SetTimer(0.05, true, 'PollForAbilitiesLoaded'); //loading a movie takes time dependent on PC performance
	}
}
function UpdateAbilities()
{
	local int iPerk;

	UpdateSelectedSoldier();
	AS_SetTitle(class'UIUtilities'.static.GetHTMLColoredText(m_kSoldier.GetName(9) @ m_kSoldier.GetName(eNameType_First) @ m_kSoldier.GetName(eNameType_Last), eUIState_Highlight, 20));
	for(iPerk=0; iPerk < 172; ++iPerk)
	{
		if(m_kSoldier.m_kChar.aUpgrades[iPerk] != 0 && perkMgr().GetPerk(iPerk).bShowPerk)
		{
			AS_AddAbility(perkMgr().GetPerkName(iPerk), class'UIUtilities'.static.GetPerkIconLabel(iPerk, perkMgr()), class'MiniModsStrategy'.static.IsPsiPerk(iPerk));
		}
	}
}
function UpdateSelectedSoldier()
{
	local int iSoldier, iSoldierIdx;
	local array<XGStrategySoldier> arrSoldiersActors;
	local TTableMenu tMenuData;

	iSoldier = Max(0, m_kSoldierList.m_iCurrentSelection);
	GetTableMenu(tMenuData);
	if(m_kSoldierList.IsA('UISoldierList_SquadSelect') || m_kSoldierList.IsA('UISoldierList_Gollop'))
	{
		iSoldierIdx = iSoldier;
	}
	else
	{
		iSoldierIdx = int(tMenuData.arrOptions[iSoldier].arrStrings[14]);
	}
	GetXGStrategySoldiersList(arrSoldiersActors);
	m_kSoldier = arrSoldiersActors[iSoldierIdx];
}
/**Acquires the TTableMenu struct which had been used by UpdateDataFromTable*/
function GetTableMenu(out TTableMenu out_tMenu)
{
	switch(m_kSoldierList.Class)
	{
	case class'UISoldierList_AssignMedal':
		out_tMenu = UISoldierList_AssignMedal(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers;
		break;
	case class'UISoldierList_Barracks':
		out_tMenu = UISoldierList_Barracks(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers;
		break;
	case class'UISoldierList_CyberneticsLab':
		out_tMenu = UISoldierList_CyberneticsLab(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers;
		break;
	case class'UISoldierList_GeneLab':
		out_tMenu = UISoldierList_GeneLab(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers;
		break;
	case class'UISoldierList_PsiLabs':
		out_tMenu = UISoldierList_PsiLabs(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers;
		break;
	case class'UISoldierList_SelectCovertOperative':
		out_tMenu = UISoldierList_SelectCovertOperative(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers;
		break;
	case class'UISoldierList_Gollop':
		out_tMenu = UISoldierList_Gollop(m_kSoldierList).GetMgr().m_kList.tmnuSoldiers;
		break;
	case class'UISoldierList_SquadSelect':
		out_tMenu = UISoldierList_SquadSelect(m_kSoldierList).GetMgr().m_kBarracksTable.mnuBarracks;
		break;
	default:
		out_tMenu.arrOptions.Length = 0;
	}
}
/**Acquires the array which holds the list of soldier actors for the curren UI list.*/
function GetXGStrategySoldiersList(out array<XGStrategySoldier> arrSoldiers)
{
	switch(m_kSoldierList.Class)
	{
	case class'UISoldierList_Gollop':
		arrSoldiers = UISoldierList_Gollop(m_kSoldierList).GetMgr().m_kList.arrVolunteers;
		break;
	default:
		arrSoldiers = BARRACKS().m_arrSoldiers;
	}
}
function AttachAbilitiesPanel()
{
	AS_LoadGfxComponents();
	SetTimer(0.05, true, 'PollForMovieLoaded'); //loading a movie takes time dependent on PC performance
}
function AttachSortFilterButtons()
{
	local UIModGfxButton gfxNewButton;
	local GfxObject gfxSpinner;
	local array<ASValue> arrParams;
	local ASValue myParam;
	local ASDisplayInfo tD;

   	tD = m_gfxList.GetObject("theSoldierList").GetDisplayInfo();
		tD.Y += 10;
	m_gfxList.GetObject("theSoldierList").SetDisplayInfo(tD);
	gfxSpinner = class'UIModUtils'.static.BindMovie(m_gfxList, "XComSpinner", "option"$WIDGET_ID_SELECT_ORDER,, m_kSoldierList.manager);
	gfxSpinner.SetBool("bCanSpin", true);
		myParam.Type = AS_Number;
		myParam.n = 220;//forceOptionWidth
		arrParams.AddItem(myParam);
		myParam.Type = AS_Boolean;
		myParam.b = true;//bCenter
		arrParams.AddItem(myParam);
		gfxSpinner.Invoke("forceValueWidth", arrParams);
	gfxSpinner.SetPosition(560, 24);
	gfxSpinner.SetVisible(true);
	gfxNewButton = UIModGfxButton(class'UIModUtils'.static.BindMovie(m_gfxList, "XComButton", "option"$WIDGET_ID_SORT_LIST, class'UIModGfxButton', m_kSoldierList.manager));
	gfxNewButton.AS_SetIcon(class'UI_FxsGamepadIcons'.const.ICON_X_SQUARE);
	gfxNewButton.AS_SetStyle(1,,true);
		tD = gfxNewButton.GetDisplayInfo();
		tD.X = 870;
		tD.Y = 24;
	gfxNewButton.SetDisplayInfo(tD);
	gfxNewButton.SetVisible(true);
	//gfxNewButton = UIModGfxButton(class'UIModUtils'.static.BindMovie(m_gfxList, "XComButton", "clearFilterBtn", class'UIModGfxButton', m_kSoldierList.manager));
	//gfxNewButton.AS_SetHTMLText("CLEAR FILTERS");
	//	tD = gfxNewButton.GetDisplayInfo();
	//	tD.X = 1000;
	//	tD.Y = 90;
	//gfxNewButton.SetDisplayInfo(tD);
	//gfxNewButton.SetVisible(true);
	//gfxNewButton = UIModGfxButton(class'UIModUtils'.static.BindMovie(m_gfxList, "XComButton", "sortListBtn", class'UIModGfxButton', m_kSoldierList.manager));
	//gfxNewButton.AS_SetHTMLText("SORT LIST");
	//	tD = gfxNewButton.GetDisplayInfo();
	//	tD.X = 1000;
	//	tD.Y = 120;
	//gfxNewButton.SetDisplayInfo(tD);
	//gfxNewButton.SetVisible(true);
}
function InitWidgetHelper()
{
	if(m_kSoldierList != none)
	{
		m_gfxList.SetObject("widgetHelper", m_gfxList.Outer.CreateObject("WidgetHelper", class'MMGfx_WidgetHelper'));
		m_gfxWidgetHelper = MMGfx_WidgetHelper(m_gfxList.GetObject("widgetHelper", class'MMGfx_WidgetHelper'));
		m_gfxWidgetHelper.AS_InitWidgetHelper(m_gfxList, 2, m_gfxList);//init 2 widgets

		m_kWidgetHelper = Spawn(class'UIWidgetHelper', m_kSoldierList);

		m_kWidgetHelper.NewSpinner();   //1st widget ("option0")
		SetupCategorySpinner();
		
		m_kWidgetHelper.NewButton();    //2nd widget ("option1")
		m_kWidgetHelper.GetWidget(WIDGET_ID_SORT_LIST).strTitle = m_strSortListLabel;
		m_kWidgetHelper.GetWidget(WIDGET_ID_SORT_LIST).del_OnValueChanged = SortList;
		
		m_kWidgetHelper.RefreshAllWidgets();
	}
	UpdateSortListButton();
}
function ApplyInitialSortingOrder(bool bReverseOrder)
{
	m_bReverseOrderPending = bReverseOrder;
	if(m_iCurrentSortingCategory == -1)
	{
		RestoreDefaultSorting();
	}
	else
	{
		SortByCategory(m_iCurrentSortingCategory);
	}
	UpdateSortListButton();
}
function SetupCategorySpinner()
{
	local UIWidget_Spinner kSpinner;

	kSpinner = UIWidget_Spinner(m_kWidgetHelper.GetWidget(WIDGET_ID_SELECT_ORDER));
	if(kSpinner != none)
	{
		kSpinner.strTitle = m_strSelectOrderLabel;
		kSpinner.bCanSpin = true;
		kSpinner.del_OnDecrease = UpdateSortListButton;
		kSpinner.del_OnIncrease = UpdateSortListButton;
		//clear - for safety reasons
		kSpinner.arrLabels.Length=0;
		kSpinner.arrValues.Length=0;
		//-1, default
		kSpinner.arrValues.AddItem(-1);
		kSpinner.arrLabels.AddItem(CAPS(Localize("UIControllerMap", "m_sDefaults", "XComGame")));
		//2, class
		kSpinner.arrValues.AddItem(eSLCat_Class);
		kSpinner.arrLabels.AddItem(m_kSoldierList.m_strSoldierListBaseClassLabel);
		//7, status
		kSpinner.arrValues.AddItem(eSLCat_Status);
		kSpinner.arrLabels.AddItem(m_kSoldierList.m_strSoldierListBaseStatusLabel);
		//15, healing time
		kSpinner.arrValues.AddItem(eSLCat_MAX);
		kSpinner.arrLabels.AddItem(m_kSoldierList.m_strSoldierListBaseStatusLabel @ "("$CAPS(class'UIDebrief'.default.m_strDays)$")");
		//11, gene mod
		kSpinner.arrValues.AddItem(eSLCat_HasGeneMod);
		kSpinner.arrLabels.AddItem(CAPS(class'XGMissionControlUI'.default.m_strLabelGeneModification));
		//12, medals
		kSpinner.arrValues.AddItem(eSLCat_Medals);
		kSpinner.arrLabels.AddItem(CAPS(class'XGBarracksUI'.default.m_strBaseViewNames[eBarracksView_Medals]));
		//0, country
		kSpinner.arrValues.AddItem(eSLCat_Country);
		kSpinner.arrLabels.AddItem(CAPS(class'XGCustomizeUI'.default.m_strCountrySpinner));
		//9, psi promotable
		kSpinner.arrValues.AddItem(eSLCat_PsiPromotable);
		kSpinner.arrLabels.AddItem(CAPS(class'UIDebrief'.default.m_strPromote @ class'XGLocalizedData'.default.SoldierClassNames[eSC_Psi]));
		//8, promotable
		kSpinner.arrValues.AddItem(eSLCat_Promotable);
		kSpinner.arrLabels.AddItem(CAPS(class'UIDebrief'.default.m_strPromote));
		
		kSpinner.iCurrentSelection = kSpinner.arrValues.Find(m_iCurrentSortingCategory);
	}
}
function UpdateSortListButton()
{
	if(m_kWidgetHelper.GetCurrentValue(WIDGET_ID_SELECT_ORDER) == m_iCurrentSortingCategory)
	{
		m_kWidgetHelper.SetButtonLabel(WIDGET_ID_SORT_LIST, m_strReverseOrderLabel);
	}
	else
	{
		m_kWidgetHelper.SetButtonLabel(WIDGET_ID_SORT_LIST, m_strSortListLabel);
	}
}
function SortList()
{
	local int iCategory;

	iCategory = m_kWidgetHelper.GetCurrentValue(WIDGET_ID_SELECT_ORDER);
	if(iCategory == m_iCurrentSortingCategory)
	{
		ReverseOrder();
		return;
	}
	m_iCurrentSortingCategory = iCategory;
	m_bCustomOrderApplied = m_iCurrentSortingCategory != -1;
	if(m_bCustomOrderApplied)
	{
		SortByCategory(iCategory);
	}
	else
	{
		RestoreDefaultSorting();
	}
	if(m_kInputGate != none && MiniModsStrategy(m_kInputGate.m_kMutator) != none)
	{
		MiniModsStrategy(m_kInputGate.m_kMutator).m_iSoldierListSortingCategory = m_iCurrentSortingCategory;
	}
	UpdateSortListButton();
}
function ReverseOrder()
{
	local TTableMenu tMenuData;
	local array<TTableMenuOption> arrOptionsCurrent, arrOptionsSorted;
	local array<XGStrategySoldier> arrSoldiersCurrent, arrSoldiersSorted, arrSoldiersToSort;
	local int iOption, iSoldier, iSortedIdx;

	GetTableMenu(tMenuData);
	arrOptionsCurrent = tMenuData.arrOptions;
	GetXGStrategySoldiersList(arrSoldiersCurrent);
	arrSoldiersToSort = arrSoldiersCurrent;
	//only squad select and main barracks list hold ALL soldiers;
	//other lists have SHIVs filtered out - these must be added at end of sorted list
	//gollop uses its own arrVolunteers instead of barracks list;
	iSortedIdx = -1;
	for(iOption=arrOptionsCurrent.Length-1; iOption >=0; --iOption)
	{
		iSortedIdx++;
		iSoldier = iOption;//good for gollop and squad select where numSoldiers==numOptions
		if(arrOptionsCurrent[iOption].arrStrings.Length >= 15)
		{
			//this is neither squad select nor gollop so arrStrings[14] holds the idx from arrSoldiersCurrent
			iSoldier = int(arrOptionsCurrent[iOption].arrStrings[14]);
		}
		arrOptionsSorted.AddItem(arrOptionsCurrent[iOption]);
		arrSoldiersSorted.AddItem(arrSoldiersCurrent[iSoldier]);
		arrSoldiersToSort.RemoveItem(arrSoldiersCurrent[iSoldier]);
		arrOptionsSorted[iSortedIdx].arrStrings[14] = string(iSortedIdx);
	}
	//add any soldiers (SHIVS actually) from outside the ui list
	for(iSoldier=0; iSoldier < arrSoldiersToSort.Length; ++iSoldier)
	{
		arrSoldiersSorted.AddItem(arrSoldiersToSort[iSoldier]);
	}
	ApplyCustomSorting(arrOptionsSorted, arrSoldiersSorted, false);
	m_bReverseOrderApplied = !m_bReverseOrderApplied;
}
function SortByCategory(int iCategory)
{
	local TTableMenu tMenuData;
	local array<TTableMenuOption> arrOptionsCurrent, arrOptionsSorted;
	local array<XGStrategySoldier> arrSoldiersCurrent, arrSoldiersSorted, arrSoldiersToSort;
	local int iOption, iSoldier, iSortedIdx;
	local bool bInsert, bSortByState;

	if(iCategory >= 8 && iCategory <= 11 || iCategory == 13)
	{
		bSortByState = true;
	}
	GetTableMenu(tMenuData);
	arrOptionsCurrent = tMenuData.arrOptions;
	GetXGStrategySoldiersList(arrSoldiersCurrent);
	arrSoldiersToSort = arrSoldiersCurrent;
	//sort options first, not soldiers
	for(iOption=0; iOption < arrOptionsCurrent.Length; iOption++)
	{
		iSoldier = iOption;
		if(arrOptionsCurrent[iOption].arrStrings.Length >= 15){
			iSoldier = int(arrOptionsCurrent[iOption].arrStrings[14]);
		}
		else{//ensure that arrString[14] holds iSoldier mapping to arrSoldiersCurrent
			arrOptionsCurrent[iOption].arrStrings[14] = string(iSoldier);
		}
		if(arrOptionsSorted.Length == 0)
		{
			arrOptionsSorted.AddItem(arrOptionsCurrent[iOption]);
			continue;
		}
		bInsert = false;
		for(iSortedIdx=0; iSortedIdx < arrOptionsSorted.Length; iSortedIdx++)
		{
			if(bSortByState)
			{
				bInsert = arrOptionsCurrent[iOption].arrStates[iCategory] >= arrOptionsSorted[iSortedIdx].arrStates[iCategory];
			}
			else
			{
				if(iCategory == eSLCat_Status)//ensure OnMission is on top
				{
					if(arrSoldiersCurrent[int(arrOptionsSorted[iSortedIdx].arrStrings[14])].GetStatus() == eStatus_OnMission)
						continue;//don't insert before OnMission, check next iSortedIdx instead
					else if(arrSoldiersCurrent[iSoldier].GetStatus() == eStatus_OnMission)
						bInsert = true;
					else
						bInsert=arrOptionsCurrent[iOption].arrStrings[eSLCat_Status] <= arrOptionsSorted[iSortedIdx].arrStrings[eSLCat_Status];			
				}
				else if(iCategory == 15)//by days-to-availability
				{
					bInsert = arrSoldiersCurrent[iSoldier].m_iTurnsOut <= arrSoldiersCurrent[int(arrOptionsSorted[iSortedIdx].arrStrings[14])].m_iTurnsOut;
				}
				else //all other cases
					bInsert=arrOptionsCurrent[iOption].arrStrings[iCategory] <= arrOptionsSorted[iSortedIdx].arrStrings[iCategory];			
			}
			if(bInsert) 
			{
				arrOptionsSorted.InsertItem(iSortedIdx, arrOptionsCurrent[iOption]);
				break;
			}
		}
		if(!bInsert)
		{
			arrOptionsSorted.AddItem(arrOptionsCurrent[iOption]);
		}
	}
	//sort soldiers based on sorted options
	for(iSortedIdx=0; iSortedIdx < arrOptionsSorted.Length; iSortedIdx++)
	{
		iSoldier = int(arrOptionsSorted[iSortedIdx].arrStrings[14]);
		arrSoldiersSorted.AddItem(arrSoldiersCurrent[iSoldier]);
		arrSoldiersToSort.RemoveItem(arrSoldiersCurrent[iSoldier]);
		arrOptionsSorted[iSortedIdx].arrStrings[14] = string(iSortedIdx);
	}
	//add any soldiers (SHIVS actually) from outside the ui list
	for(iSoldier=0; iSoldier < arrSoldiersToSort.Length; ++iSoldier)
	{
		arrSoldiersSorted.AddItem(arrSoldiersToSort[iSoldier]);
	}
	ApplyCustomSorting(arrOptionsSorted, arrSoldiersSorted);	
}
function ApplyCustomSorting(array<TTableMenuOption> arrSortedOptions, array<XGStrategySoldier> arrSortedSoldiers, optional bool bDeferred=true)
{
	local TTableMenu tMenuData;

	switch(m_kSoldierList.Class)
	{
	case class'UISoldierList_AssignMedal':
		UISoldierList_AssignMedal(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers.arrOptions = arrSortedOptions;
		BARRACKS().m_arrSoldiers = arrSortedSoldiers;
		break;
	case class'UISoldierList_Barracks':
		UISoldierList_Barracks(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers.arrOptions = arrSortedOptions;
		BARRACKS().m_arrSoldiers = arrSortedSoldiers;
		break;
	case class'UISoldierList_CyberneticsLab':
		UISoldierList_CyberneticsLab(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers.arrOptions = arrSortedOptions;
		BARRACKS().m_arrSoldiers = arrSortedSoldiers;
		break;
	case class'UISoldierList_GeneLab':
		UISoldierList_GeneLab(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers.arrOptions = arrSortedOptions;
		BARRACKS().m_arrSoldiers = arrSortedSoldiers;
		break;
	case class'UISoldierList_PsiLabs':
		UISoldierList_PsiLabs(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers.arrOptions = arrSortedOptions;
		BARRACKS().m_arrSoldiers = arrSortedSoldiers;
		break;
	case class'UISoldierList_SelectCovertOperative':
		UISoldierList_SelectCovertOperative(m_kSoldierList).GetMgr().m_kSoldierTable.mnuSoldiers.arrOptions = arrSortedOptions;
		BARRACKS().m_arrSoldiers = arrSortedSoldiers;
		break;
	case class'UISoldierList_Gollop':
		UISoldierList_Gollop(m_kSoldierList).GetMgr().m_kList.tmnuSoldiers.arrOptions = arrSortedOptions;
		UISoldierList_Gollop(m_kSoldierList).GetMgr().m_kList.arrVolunteers = arrSortedSoldiers;
		break;
	case class'UISoldierList_SquadSelect':
		UISoldierList_SquadSelect(m_kSoldierList).GetMgr().m_kBarracksTable.mnuBarracks.arrOptions = arrSortedOptions;
		BARRACKS().m_arrSoldiers = arrSortedSoldiers;
		break;
	}
	GetTableMenu(tMenuData);
	m_kSoldierList.m_arrUIOptions.Length = 0;
	if(bDeferred)
	{
		m_tSoldierListData = tMenuData;
		PushState('ApplyingCustomSorting');//optimization to avoid Runaway loop
	}
	else
	{
		m_kSoldierList.UpdateDataFromTable(tMenuData);
	}
}
function RestoreDefaultSorting()
{
	if(!IsInState('RestoringDefaultSorting'))
	{
		PushState('RestoringDefaultSorting');
		return;
	}
	BARRACKS().ReorderRanks();
	switch(m_kSoldierList.Class)
	{
	case class'UISoldierList_AssignMedal':
		UISoldierList_AssignMedal(m_kSoldierList).GetMgr().UpdateSoldierList();
		break;
	case class'UISoldierList_Barracks':
		UISoldierList_Barracks(m_kSoldierList).GetMgr().UpdateSoldierList(false);
		break;
	case class'UISoldierList_CyberneticsLab':
		UISoldierList_CyberneticsLab(m_kSoldierList).GetMgr().UpdateSoldierList();
		break;
	case class'UISoldierList_GeneLab':
		UISoldierList_GeneLab(m_kSoldierList).GetMgr().UpdateSoldierList();
		break;
	case class'UISoldierList_PsiLabs':
		UISoldierList_PsiLabs(m_kSoldierList).GetMgr().UpdateSoldierList();
		break;
	case class'UISoldierList_SelectCovertOperative':
		UISoldierList_SelectCovertOperative(m_kSoldierList).GetMgr().UpdateSoldierList(true);
		break;
	case class'UISoldierList_Gollop':
		UISoldierList_Gollop(m_kSoldierList).GetMgr().UpdateVolunteerList();
		break;
	case class'UISoldierList_SquadSelect':
		UISoldierList_SquadSelect(m_kSoldierList).GetMgr().UpdateBarracksTable();
		break;
	}
	m_kSoldierList.m_arrUIOptions.Length = 0;
	//m_kSoldierList.UpdateData();
	//if(InStr(GetScriptTrace(), "ApplyInitialSortingOrder") != -1)
	//{
		SetTimer(0.10, false, 'UpdateData', m_kSoldierList);//optimization to avoid runaway loop
	//}
	//else
	//{
	//}
}
/** Checks if the SoldierSummary movieClip has finished loading*/
function PollForMovieLoaded()
{
	m_gfxAbilities = m_kSoldierList.manager.GetVariableObject(string(m_kSoldierList.GetMCPath()) $ ".theSoldierList.SoldierSummary.theScreen.soldierAbilityListMC");
	if(m_gfxAbilities != none)
	{
		ClearTimer(GetFuncName());
		AS_SetupGfx();
	}
}
/** Checks if the 'soldierAbilityListMC' has finished loading all the items*/
function PollForAbilitiesLoaded()
{
	if(m_gfxAbilities.GetFloat("leftToLoadCount") == 0)
	{
		ClearTimer(GetFuncName());
		AS_AdjustHeight();
	}
}
event Tick(float fDeltaTime)
{
	if(m_gfxAbilities != none && PRES().IsInState('State_SoldierList'))
	{
		if(V2DSizeSq(PRES().m_kUIMouseCursor.m_v2MouseFrameDelta) > 2.5)
		{
			UpdateSelectionFromMouseCursor();
		}
	}
}
function bool OnMouseEvent(int Cmd, array<string> args)
{
	local int iWidget, iOption;

	if(Cmd == 391 && InStr(args[4], "option") != -1)
	{
		iWidget = int(Split(args[4], "option", true));
		iOption = args.Length > 5 ? int(args[args.Length-1]) : -1;
		m_kWidgetHelper.ProcessMouseEvent(iWidget, iOption);
		return true;
	}
	return m_kSoldierList.OnMouseEvent(Cmd, args);
}
function bool OnUnrealCommand(int Cmd, int ActionMask)
{
	local bool bHandled;

	switch(Cmd)
	{
	case 571:
	case class'UI_FxsInput'.const.FXS_BUTTON_X:
			SortList();
			bHandled = true;
			break;
	case class'UI_FxsInput'.const.FXS_ARROW_LEFT:
	case class'UI_FxsInput'.const.FXS_DPAD_LEFT:
	case class'UI_FxsInput'.const.FXS_VIRTUAL_LSTICK_LEFT:
		m_kWidgetHelper.ProcessMouseEvent(WIDGET_ID_SELECT_ORDER, class'UIWidgetHelper'.const.DECREASE_VALUE);
		bHandled = true;
		break;
	case class'UI_FxsInput'.const.FXS_ARROW_RIGHT:
	case class'UI_FxsInput'.const.FXS_DPAD_RIGHT:
	case class'UI_FxsInput'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		m_kWidgetHelper.ProcessMouseEvent(WIDGET_ID_SELECT_ORDER, class'UIWidgetHelper'.const.INCREASE_VALUE);
		bHandled = true;
		break;
	default:
		bHandled = false;
	};
	return bHandled;	
}
function UpdateSelectionFromMouseCursor()
{
	local int i, iNumItems;
	local bool bFound;

	iNumItems = m_kSoldierList.m_arrUIOptions.Length;
	for(i=0; i<iNumItems; ++i)
	{
		if(m_kSoldierList.manager.GetVariableBool(m_kSoldierList.GetMCPath() $".soldierList.theItems."$ i $".bMouseIsHovering"))
		{
			bFound=true;
			break;
		}
	}
	if(bFound && m_kSoldierList.m_iCurrentSelection != i)
	{
		m_kSoldierList.m_iCurrentSelection = i;
	}
}
/** Load SoldierSummary.swf into SoldierList screen*/
function AS_LoadGfxComponents()
{
	local GFxObject gfxSoldierSummary;
	local array<ASValue> arrParams;
	local ASValue myParam;

	gfxSoldierSummary = m_gfxList.GetObject("theSoldierList").CreateEmptyMovieClip("SoldierSummary"); //create a placeholder for .swf file
		myParam.Type = AS_String;
		myParam.s = "/ package/gfxSoldierSummary/SoldierSummary"; //provide path to .swf movie
		arrParams.AddItem(myParam); //put the path into params array
	gfxSoldierSummary.Invoke("loadMovie", arrParams);	//call loadMovie method with provided path as param
}

function AS_SetupGfx()
{
	local ASDisplayInfo tDisplay;
	local array<ASValue> arrParams;
	local bool bFixObscuring;
	local float fScaleAdj;

	//scale down the abilities list and adjust its position
	tDisplay = m_gfxAbilities.GetDisplayInfo();
		tDisplay.XScale *= 0.7;
		tDisplay.YScale *= 0.7;
		tDisplay.Y -= 112;
		tDisplay.X = -508 + m_gfxList.GetObject("theSoldierList").GetObject("backgroundMC").GetFloat("_width");
		if(tDisplay.X > 500)
		{
			bFixObscuring = true;
		}
	m_gfxAbilities.SetDisplayInfo(tDisplay);
	//make the bg frame narrower, adjust bottom line
	tDisplay = m_gfxAbilities.GetObject("bg").GetDisplayInfo();
		tDisplay.XScale *= 0.80;
	m_gfxAbilities.GetObject("bg").SetDisplayInfo(tDisplay);
	arrParams.Add(1);
	arrParams[0].Type = AS_Number;
	arrParams[0].n = 3 - 16384;
	m_gfxAbilities.GetObject("bg").Invoke("swapDepths", arrParams);
	tDisplay = m_gfxAbilities.GetObject("bottomBracket").GetDisplayInfo();
		tDisplay.XScale *= 0.80;
		tDisplay.X += 80;
	m_gfxAbilities.GetObject("bottomBracket").SetDisplayInfo(tDisplay);
	//move the title to the right due to narrowed bg
	tDisplay = m_gfxAbilities.GetObject("title").GetDisplayInfo();
		tDisplay.X += 82;
	m_gfxAbilities.GetObject("title").SetDisplayInfo(tDisplay);
	//move main list 45 pixels to the left and 10 pixels down + scale if needed
	tDisplay = m_gfxList.GetDisplayInfo();
		tDisplay.X -= 45;
		if(bFixObscuring)
		{
			fScaleAdj = 1006.0 / m_gfxList.GetObject("theSoldierList").GetObject("backgroundMC").GetFloat("_width");
			tDisplay.XScale = (tDisplay.hasXScale ? tDisplay.XScale : 100.0) * fScaleAdj;
			tDisplay.YScale = tDisplay.XScale;
			m_gfxList.GetObject("theSoldierList").GetObject("listbox").SetFloat("_height", m_gfxList.GetObject("theSoldierList").GetObject("listbox").GetFloat("_height") / fScaleAdj);
			m_gfxList.GetObject("theSoldierList").GetObject("backgroundMC").SetFloat("_height", m_gfxList.GetObject("theSoldierList").GetObject("backgroundMC").GetFloat("_height") / fScaleAdj);
		}
	m_gfxList.SetDisplayInfo(tDisplay);
	if(bFixObscuring)
	{
		arrParams.Length = 0;
		m_gfxList.GetObject("theSoldierList").Invoke("setMaskAndRootSize", arrParams);
	}
	//hide the redundant bg and stats
	m_gfxAbilities.GetObject("_parent").GetObject("bg").SetVisible(false);
	m_gfxAbilities.GetObject("_parent").GetObject("soldierStatsMC").SetVisible(false);
	//show the list (cause it's hidden by default)
	m_gfxAbilities.SetVisible(true);
}
function AS_AdjustHeight()
{
	local float fH;
	local array<ASValue> arrParams;
	
	arrParams.Length = 0;
	fH = AS_GetTotalHeight();
	m_gfxAbilities.GetObject("bg").SetFloat("_height", fH + 105);
	m_gfxAbilities.GetObject("theMask").SetFloat("_height", fH);
	m_gfxAbilities.SetFloat("maskHeight", fH);
	m_gfxAbilities.GetObject("bottomBracket").SetFloat("_y", fH -10 + m_gfxAbilities.GetObject("itemRoot").GetFloat("_y"));
	m_gfxAbilities.Invoke("ClearScroll", arrParams);
}
function AS_SetTitle(string Title)
{
    m_gfxAbilities.ActionScriptVoid("SetTitle");
}
function AS_AddAbility(string _label, string _perkIconLabel, bool _psionic)
{
    m_gfxAbilities.ActionScriptVoid("AddAbility");
}
function float AS_GetTotalHeight()
{
	return m_gfxAbilities.ActionScriptFloat("getTotalHeight");
}
state ApplyingCustomSorting
{
Begin:
	Sleep(0.30);
	m_kSoldierList.UpdateDataFromTable(m_tSoldierListData);
	if(m_bReverseOrderPending)
	{
		m_bReverseOrderPending = false;
		ReverseOrder();
	}
	PopState();
}
state RestoringDefaultSorting
{
Begin:
	Sleep(0.30);
	RestoreDefaultSorting();
	if(m_bReverseOrderPending)
	{
		m_bReverseOrderPending = false;
		ReverseOrder();
	}
	PopState();
}
DefaultProperties
{
	m_iCurrentSortingCategory=-1
}
