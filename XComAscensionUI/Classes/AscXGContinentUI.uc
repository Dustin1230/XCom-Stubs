class AscXGContinentUI extends XGContinentUI;

var UIContinentSelect m_kUI;
var float m_fLeftAnchor;
var float m_fRightAnchor;

//this function will load m_arrContients with either continents OR countries
function PopulateContinentsArray()
{
	local int i;

	`log(GetFuncName(),,Name);
	m_arrContinents.Length = 0;
	if(m_iChosenContinent < 0)
	{
		for(i = 0; i < class'XGTacticalGameCore'.default.ItemBalance_Classic.Length; ++ i)
		{
			//only cache continent options
			if(class'XGTacticalGameCore'.default.ItemBalance_Classic[i].eItem == 2)
			{
				if(m_arrContinents.Find(class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iAlloys) == -1)
					m_arrContinents.AddItem(class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iAlloys);
			}
		}
	}
	else
	{
		for(i = 0; i < class'XGTacticalGameCore'.default.ItemBalance_Classic.Length; ++ i)
		{
			//only cache country options for chosen continent
			if(class'XGTacticalGameCore'.default.ItemBalance_Classic[i].eItem == 0 && class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iAlloys == m_iChosenContinent)
			{
				if(m_arrContinents.Find((class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iCash << 16) | class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iElerium) == -1)
					m_arrContinents.AddItem((class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iCash << 16) | class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iElerium);
			}
		}
	}
}
function Init(int iView)
{
	`log(GetFuncName(),,Name);
    if(!Game().m_bDebugStart && !ISCONTROLLED())
    {
        PRES().PlayCinematic(0,, false);
    }
	m_kUI = XComHQPresentationLayer(XComPlayerController(WorldInfo.GetALocalPlayerController()).m_Pres).m_kContinentSelect;
	PopulateContinentsArray();
    super(XGScreenMgr).Init(0);
    XComEngine(class'Engine'.static.GetEngine()).MapManager.PreloadTransitionLevels(true);
    class'XComEngine'.static.AddStreamingTextureSlaveLocation(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).m_kEarth.Location, rot(0, 0, 0), 155.0, true);
    if(class'XComEngine'.static.IsMoviePlaying(""))
    {
        class'XComEngine'.static.WaitForMovie();
        class'XComEngine'.static.StopCurrentMovie();
    }
    Sound().PlayMusic(eMusic_HQ_ActI);  
}
function bool OnChooseCont(int iOption)
{
		`log(GetFuncName(),,Name);

	if(m_iChosenContinent < 0)
	{
		//if not yet chosen continent do this:
		m_iChosenContinent = m_arrContinents[iOption];  //assign idx of selected continent to m_iChosenContinent
		PopulateContinentsArray();                      //populate arrays with countries for the selected continent
		AS_ClearItemList();                             //must be added to manually clear the list before building new one
		m_kUI.maxContinents = m_arrContinents.Length;   //this is relevant for gamepad/keyboard controls
		UpdateView();
		DumpScreenInfo();
		return false;
	}
	return super.OnChooseCont(iOption);
}
function UpdateMainMenu()
{

	local TMenuOption kOption;
	local TMenu kMainMenu;
	local int iMenuOption;
	`log(GetFuncName(),,Name);

	m_kMainMenu.arrContOptions.Remove(0, m_kMainMenu.arrContOptions.Length);
	for(iMenuOption = 0; iMenuOption < m_arrContinents.Length; ++iMenuOption)
	{
		//things to keep in mind: 
		//when m_iChosenContinent < 0 the array m_arrContinents holds continents' IDs
		//otherwise the array holds composites of iCash (country bonus Id) and iElerium (country ID)
		//when dealing with the composite iContinent&255 is iElerium and iContinent>>16 is iCash
		if(m_iChosenContinent < 0)
			kOption.strText = class'XGWorld'.default.m_aContinentNames[m_arrContinents[iMenuOption]];
		else
			kOption.strText = class'XGLocalizedData'.default.CountryNames[m_arrContinents[iMenuOption] & 255];
		kOption.iState = 0;
		kMainMenu.arrOptions.AddItem(kOption);
		m_kMainMenu.arrContOptions.AddItem(BuildContinentOption(m_arrContinents[iMenuOption]));                
	}
	m_kMainMenu.mnuOptions = kMainMenu;
}
function TContOption BuildContinentOption(int iContinent)
{
	local TContOption kOption;
	local XGParamTag kBonus;
	local int i, j;
	`log(GetFuncName(),,Name);
	
	//things to keep in mind: 
	//when m_iChosenContinent == -1 it means iContinent is a continent's ID
	//when m_iChosenContinent != -1 it means iContinent is a composite of iCash (country bonus Id) and iElerium (country ID)
	//when dealing with the composite iContinent&255 states for iElerium and iContinent>>16 for iCash

	kOption.txtBonusDesc.StrValue = "";
	for(i = 0; i  < class'XGTacticalGameCore'.default.ItemBalance_Classic.Length; ++i)
	{
		if(class'XGTacticalGameCore'.default.ItemBalance_Classic[i].eItem == 0 && m_iChosenContinent != -1)
		{
			if(class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iElerium == (iContinent & 255))
			{
				if(class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iCash == (iContinent >> 16))
				{
					kBonus = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
					kBonus.IntValue0 = World().GetContinentByBonus(EContinentBonus(i));
					j = class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iTime;
					kOption.txtBonusDesc.StrValue $= class'UIUtilities'.static.GetHTMLColoredText(class'XGLocalizedData'.default.ContinentBonusNames[j], 4, 22);
					kOption.txtBonusDesc.StrValue $= "";
					kOption.txtBonusDesc.StrValue $= class'UIUtilities'.static.GetHTMLColoredText(class'XComLocalizer'.static.ExpandString(class'XGLocalizedData'.default.ContinentBonusDesc[j]), 5, 16);
					kOption.txtBonusDesc.StrValue $= "\n";
				}
			}
		}
	}
	if(m_iChosenContinent != -1)
		kOption.txtBonusDesc.StrValue $= "\n";
	kOption.txtBonusDesc.StrValue $= class'UIUtilities'.static.GetHTMLColoredText(m_strLabelBonus, 0, 22);
	kOption.txtBonusDesc.StrValue $= "\n";
	for(i = 0; i < class'XGTacticalGameCore'.default.ItemBalance_Classic.Length; ++i)
	{
		if(class'XGTacticalGameCore'.default.ItemBalance_Classic[i].eItem == 2)
		{
			if(class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iAlloys == (m_iChosenContinent != -1 ? m_iChosenContinent : iContinent) )
			{
				kBonus = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
				kBonus.IntValue0 = World().GetContinentByBonus(EContinentBonus(i));
				j = class'XGTacticalGameCore'.default.ItemBalance_Classic[i].iTime;
				kOption.txtBonusDesc.StrValue $= class'UIUtilities'.static.GetHTMLColoredText(CAPS(class'XGLocalizedData'.default.ContinentBonusNames[j]), 4, 26);
				kOption.txtBonusDesc.StrValue $= "\n"; 
				kOption.txtBonusDesc.StrValue $= class'UIUtilities'.static.GetHTMLColoredText(class'XComLocalizer'.static.ExpandString(class'XGLocalizedData'.default.ContinentBonusDesc[j]), 0, 18);
				kOption.txtBonusDesc.StrValue $= "\n";
			}
		}
	}
	kOption.txtName.StrValue = (m_iChosenContinent != -1 ? Country(iContinent & 255).GetName() : Continent(iContinent).GetName());
	kOption.txtName.iState = 4;
	kOption.txtBonusLabel.StrValue = class'UIUtilities'.static.GetHTMLColoredText(Caps(kOption.txtName.StrValue), 5, 26);
	if(m_iChosenContinent != -1)
		kOption.txtBonusTitle.StrValue = m_strLabelReturnToContinent $ (ConvertCashToString(int(float(class'XGTacticalGameCore'.default.FundingAmounts[(iContinent & 255) + 36]) * class'XGTacticalGameCore'.default.FundingBalance[Game().GetDifficulty() + 4])));
	return kOption;
}

function DumpScreenInfo()
{
	local string strOut;
	`log(GetFuncName(),,Name);

	strOut $= ("\nDesc._x=" $ string(AS_GetDescField().GetFloat("_x")));
	strOut $=("\nDesc._y=" $ string(AS_GetDescField().GetFloat("_y")));
	strOut $=("\nDesc._width=" $ string(AS_GetDescField().GetFloat("_width")));
	strOut $=("\nDesc._height=" $ string(AS_GetDescField().GetFloat("_height")));
	strOut $=("\nList._x=" $ string(AS_GetItemList().GetFloat("_x")));
	strOut $=("\nList._y=" $ string(AS_GetItemList().GetFloat("_y")));
	strOut $=("\nList._width=" $ string(AS_GetItemList().GetFloat("_width")));
	strOut $=("\nList._height=" $ string(AS_GetItemList().GetFloat("_height")));
	strOut $=("\nScreen._x=" $ string(AS_GetScreen().GetFloat("_x")));
	strOut $=("\nScreen._y=" $ string(AS_GetScreen().GetFloat("_y")));
	strOut $=("\nScreen._width=" $ string(AS_GetScreen().GetFloat("_width")));
	strOut $=("\nScreen._height=" $ string(AS_GetScreen().GetFloat("_height")));
	LogInternal(strOut, name);
}
function GfxObject AS_GetDescField()
{
	return m_kUI.manager.GetVariableObject(string(m_kUI.GetMCPath())$ ".descField");;
}
function GfxObject AS_GetItemList()
{
	return m_kUI.manager.GetVariableObject(string(m_kUI.GetMCPath())$ ".listMC");;
}
function GfxObject AS_GetScreen()
{
	return m_kUI.manager.GetVariableObject(string(m_kUI.GetMCPath()));
}
function AS_ClearItemList()
{
	m_kUI.Invoke("clear");
	m_kUI.Invoke("listMC.clear");
}

DefaultProperties
{
	m_iChosenContinent=-1
}
