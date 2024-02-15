class MiniModsOptionsContainer extends UIModOptionsContainer
	config(MiniMods);

var localized array<string> m_arrCreditsMiniMods;
var localized array<string> m_arrCreditsMapOrganizer;

function Init(Object kMasterMod)
{
	super.Init(kMasterMod);
	BuildDataForModMgrTactical();
	BuildDataForModMgrStrategy();
	class'UIModManager'.static.RegisterInitWidgetCallback(InitWidgetDataCallback);
}

function AddModDataRecord(TModUIData tNewModData)
{
	if(tNewModData.ModName ~= "AbductionMapOrganizer")
	{
		tNewModData.arrCredtis = m_arrCreditsMapOrganizer;
	}
	else
	{
		tNewModData.arrCredtis = m_arrCreditsMiniMods;
	}
	if(tNewModData.arrRequiredClassPaths.Find("MiniModsCollection.MiniModsTactical") < 0)
	{
		tNewModData.arrRequiredClassPaths.AddItem("MiniModsCollection.MiniModsTactical");
	}
	if(tNewModData.arrRequiredClassPaths.Find("MiniModsCollection.MiniModsStrategy") < 0)
	{
		tNewModData.arrRequiredClassPaths.AddItem("MiniModsCollection.MiniModsStrategy");
	}
	super.AddModDataRecord(tNewModData);
}
function BuildDataForModMgrTactical()
{
	local TModUIData tMod;
	local TModOption tOption;
	local string strSetting;
	local int idx, iBlankOptions, iMod, iOption;
	local array<int> arrValues;
	local array<string> arrLabels;
	local XGParamTag kTag;
	local MMCustomItemCharges kCustomCharges;

	kCustomCharges = MiniModsTactical(class'UIModManager'.static.GetMutator("MiniModsCollection.MiniModsTactical")).m_kCustomCharges;

	if(FindOption("OfficerIronWill", "", iMod))
	{
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsTactical'.default.m_bOfficerIronWill;
	}
	if(FindOption("FuelConsumption", "", iMod))
	{
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsTactical'.default.m_bFuelConsumption;
	}
	if(FindOption("DisorientExalt", "", iMod))
	{
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsTactical'.default.m_bFlashBombOnHackingArray;
	}
	if(FindOption("SequentialOverwatch", "", iMod))
	{
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsTactical'.default.m_bSequentialOverwatch;
	}
	if(FindOption("SalvageMod", "", iMod))
	{
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsTactical'.default.m_bSalvageMod;
	}

	tMod.ModName="SalvageMod";
	AddConfigVarBool(tMod.ModName, class'UIMultiplayerPostMatchSummary'.default.m_strMap,,,,,,true,,"Maps");
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.UFOCrash", class'MiniModsTactical'.default.MissionTypeAllowed.Find(3) != -1, true, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.UFOCrash"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.UFOCrash"),,true,,"Maps.");
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.UFOLanded", class'MiniModsTactical'.default.MissionTypeAllowed.Find(4) != -1, true, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.UFOLanded"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.UFOLanded"),,,,"Maps.");
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.AlienBase", class'MiniModsTactical'.default.MissionTypeAllowed.Find(8) != -1, true, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.AlienBase"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.AlienBase"),,,,"Maps.");
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.ExaltRaid", class'MiniModsTactical'.default.MissionTypeAllowed.Find(13) != -1, true, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.ExaltRaid"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.ExaltRaid"),,,,"Maps.");
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.DataRecovery", class'MiniModsTactical'.default.MissionTypeAllowed.Find(6) != -1, true, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.DataRecovery"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.DataRecovery"),,,,"Maps.");
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.ExtractAgent", class'MiniModsTactical'.default.MissionTypeAllowed.Find(5) != -1, false, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.ExtractAgent"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.ExtractAgent"),,,,"Maps.");
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.TerrorSite", class'MiniModsTactical'.default.MissionTypeAllowed.Find(9) != -1, false, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.TerrorSite"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.TerrorSite"),,,,"Maps.");
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.CouncilMission", class'MiniModsTactical'.default.MissionTypeAllowed.Find(11) != -1, false, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.CouncilMission"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.CouncilMission"),,,,"Maps.");
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.Abduction", class'MiniModsTactical'.default.MissionTypeAllowed.Find(2) != -1, false, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.Abduction"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.Abduction"),,,,"Maps.");		
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.LowFriends", class'MiniModsTactical'.default.MissionTypeAllowed.Find(20) != -1, false, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.LowFriends"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.LowFriends"),,,,"Maps.");		
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.ConfoundingLight", class'MiniModsTactical'.default.MissionTypeAllowed.Find(21) != -1, false, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.ConfoundingLight"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.ConfoundingLight"),,,,"Maps.");		
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.Gangplank", class'MiniModsTactical'.default.MissionTypeAllowed.Find(22) != -1, false, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.Gangplank"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.Gangplank"),,,,"Maps.");		
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.Portent", class'MiniModsTactical'.default.MissionTypeAllowed.Find(25) != -1, false, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.Portent"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.Portent"),,,,"Maps.");		
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.Deluge", class'MiniModsTactical'.default.MissionTypeAllowed.Find(26) != -1, false, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.Deluge"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.Deluge"),,,,"Maps.");		
	AddConfigVarBool(tMod.ModName, tMod.ModName$".MissionTypeAllowed.Furies", class'MiniModsTactical'.default.MissionTypeAllowed.Find(27) != -1, false, GetUINameForVar(tMod.ModName$".MissionTypeAllowed.Furies"), GetDescForVar(tMod.ModName$".MissionTypeAllowed.Furies"),,,,"Maps.");		

	if(FindOption("ShadowStep", "", iMod))
	{
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsTactical'.default.m_bShadowStep;
		for(iOption = 0; iOption < m_arrModsData[iMod].arrModOptions.Length; ++iOption)
		{
			tOption = m_arrModsData[iMod].arrModOptions[iOption];
			if(InStr(tOption.VarName, "m_arrShadowStepPerks") != -1)
			{
				tOption.VarDescription = GetDescForVar("ShadowStep.m_arrShadowStepPerks");
				m_arrModsData[iMod].arrModOptions[iOption] = tOption;
			}
			else if(InStr(tOption.VarName, "m_arrShadowBusterPerks") != -1)
			{
				tOption.VarDescription = GetDescForVar("ShadowStep.m_arrShadowBusterPerks");
				m_arrModsData[iMod].arrModOptions[iOption] = tOption;
			} 
		}
	}

	if(FindOption("PerkGivesItems", "", iMod))
	{
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsTactical'.default.m_bPerksGiveItemCharges;
		tMod = m_arrModsData[iMod];
		iBlankOptions = class'XComModsProfile'.static.HasSetting("iBlankOptions", "PerkGivesItems", strSetting) ? int(strSetting) : 2;
		kCustomCharges.PerkGivesItems.Add(iBlankOptions);
		kCustomCharges.SaveConfig();
		idx=0;
		for(iOption = 0; iOption < tMod.arrModOptions.Length; ++iOption)
		{
			tOption = tMod.arrModOptions[iOption];
			strSetting = Split(tOption.VarPath, "[", true);
			strSetting = Left(strSetting, InStr(strSetting, "]"));
			if(InStr(tOption.VarName, "iPerk") != -1)
			{
				idx++;
				tOption.VarDescription = GetDescForVar("PerkGivesItems.iPerk");
				tOption.VarDisplayLabel = GetUINameForVar("PerkGivesItems.iPerk");
				tOption.Index = strSetting $".0";
				m_arrModsData[iMod].arrModOptions[iOption] = tOption;
			}
			else if(InStr(tOption.VarName, "iCharges") != -1)
			{
				tOption.VarDescription = GetDescForVar("PerkGivesItems.iCharges");
				tOption.VarDisplayLabel = GetUINameForVar("PerkGivesItems.iCharges");
				tOption.Index = strSetting $".1";
				m_arrModsData[iMod].arrModOptions[iOption] = tOption;
			} 
			else if(InStr(tOption.VarName, "iItem") != -1)
			{
				tOption.VarDescription = GetDescForVar("PerkGivesItems.iItem");
				tOption.VarDisplayLabel = GetUINameForVar("PerkGivesItems.iItem");
				tOption.Index = strSetting $".2";
				m_arrModsData[iMod].arrModOptions[iOption] = tOption;
			}
			else if(InStr(tOption.VarName, "bEnabled") != -1)
			{
				tOption.VarDescription = GetDescForVar("PerkGivesItems.bEnabled");
				tOption.Index = strSetting;
				m_arrModsData[iMod].arrModOptions[iOption] = tOption;
			}
		}
		if(kCustomCharges.PerkGivesItems.Length > idx)
		{
			iOption = idx; //cache idx in iOption
			//build values/labels templates for PerkGivesItems
			arrValues.Length = 0;
			arrLabels.Length = 0;
			arrValues.AddItem(0);
			arrValues.AddItem(69);
			arrValues.AddItem(73);
			arrValues.AddItem(77);
			arrValues.AddItem(81);
			arrValues.AddItem(82);
			arrValues.AddItem(83);
			arrValues.AddItem(84);
			arrValues.AddItem(85);
			arrValues.AddItem(86);
			arrValues.AddItem(87);
			arrValues.AddItem(88);
			arrValues.AddItem(89);
			arrValues.AddItem(97);
			arrLabels.AddItem(class'UIFxsLocalizationHelper'.default.m_strAlienDisplayName_None);
			for(idx=1; idx < 14; ++idx)
			{
				arrLabels.AddItem(class'XLocalizedData'.default.m_aItemNames[arrValues[idx]]);
			}
			//end of template building
			for(idx=iOption; idx < kCustomCharges.PerkGivesItems.Length; ++idx)
			{
				//add main checkbox for the blank combination
				AddConfigVarBool(tMod.ModName, tMod.ModName$".bEnabled."$idx,kCustomCharges.PerkGivesItems[idx].bEnabled,false,"? -> ?",GetDescForVar("PerkGivesItems.bEnabled"),,,"MMCustomItemCharges.PerkGivesItems[" $ idx $"].bEnabled",string(idx));
				AddConfigVarPerk(tMod.ModName, tMod.ModName$".iPerk."$idx, idx < kCustomCharges.PerkGivesItems.Length ? kCustomCharges.PerkGivesItems[idx].iPerk : 0,, GetUINameForVar(tMod.ModName$".iPerk"), GetDescForVar(tMod.ModName$".iPerk"),,,"MMCustomItemCharges.PerkGivesItems[" $ idx $"].iPerk", string(idx)$".0");
				AddConfigVarInt(tMod.ModName, tMod.ModName$".iCharges."$idx, idx < kCustomCharges.PerkGivesItems.Length ? kCustomCharges.PerkGivesItems[idx].iCharges : 1,,3,,,GetUINameForVar(tMod.ModName$".iCharges"), GetDescForVar(tMod.ModName$".iCharges"), eWidget_Spinner,,"MMCustomItemCharges.PerkGivesItems[" $ idx $"].iCharges", string(idx)$".1");
					tOption = BuildConfigVarInt(tMod.ModName$".iItem."$idx, idx < kCustomCharges.PerkGivesItems.Length ? kCustomCharges.PerkGivesItems[idx].iItem : 0,,13,,, GetUINameForVar(tMod.ModName$".iItem"), GetDescForVar(tMod.ModName$".iItem"), eWidget_Combobox,,"MMCustomItemCharges.PerkGivesItems[" $ idx $"].iItem",string(idx)$".2");
					tOption.arrListValues = arrValues;
					tOption.arrListLabels = arrLabels;
				AddModOption(tMod.ModName, tOption);
			}
		}
		//add widget for Blank Options
		AddConfigVarInt(tMod.ModName, tMod.ModName$".iBlankOptions", iBlankOptions, 0, 5,,2, GetUINameForVar(tMod.ModName$".iBlankOptions"), GetDescForVar(tMod.ModName$".iBlankOptions"));
	}
	if(FindOption("ScoutSense", "", iMod))
	{
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsTactical'.default.m_bScoutSense;
		tMod = m_arrModsData[iMod];
		//build labels for m_iScoutSenseLvl..Rank (which are rank names)
		arrLabels.Length = 0;
		for(idx=1; idx <= 7; idx++)
		{
			arrLabels.AddItem(class'XGTacticalGameCoreNativeBase'.default.m_aRankNames[idx]);
		}
		for(iOption=0; iOption < tMod.arrModOptions.Length; ++iOption)
		{
			tOption = tMod.arrModOptions[iOption];
			if(InStr(tOption.VarName, "ScoutSensePerk",,true) != -1 && tOption.arrListValues[0] == 0)
			{
				m_arrModsData[iMod].arrModOptions[iOption].arrListLabels[0] = class'XGTacticalGameCore'.default.m_aSoldierClassNames[eSC_Sniper];
			}
			else if(InStr(tOption.VarName, "ScoutSenseLvl",,true) != -1)
			{
				m_arrModsData[iMod].arrModOptions[iOption].arrListLabels = arrLabels;
				m_arrModsData[iMod].arrModOptions[iOption].arrListLabels.Length = tOption.arrListValues.Length; //just in case a modder makes it shorter
			}
			else if(InStr(tOption.VarName, "ScoutSenseRange",,true) != -1)
			{
				idx = int(Split(tOption.VarName, "ScoutSenseRange", true));
				kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
				if(class'MiniModsTactical'.default.m_strScoutSenseMessage[class'MiniModsTactical'.default.ScoutSenseRange[idx].iMessageID] != "")
				{
					kTag.StrValue0 = class'MiniModsTactical'.default.m_strScoutSenseMessage[class'MiniModsTactical'.default.ScoutSenseRange[idx].iMessageID];
					m_arrModsData[iMod].arrModOptions[iOption].VarDisplayLabel = kTag.StrValue0;
					m_arrModsData[iMod].arrModOptions[iOption].VarDescription = class'XComLocalizer'.static.ExpandString(GetDescForVar(tMod.ModName$".ScoutSenseRange"));
				}
			}

		}
	}
}
function BuildDataForModMgrStrategy()
{
	local TModUIData tMod;
	local TModOption tOption;
	local int i, iMod, iOption;
	local string strSetting;
	local XGParamTag kTag;

	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
	if(FindOption("ManufactureExaltLoot", "", iMod))
	{
		tMod = m_arrModsData[iMod];
			kTag.StrValue0 = class'XLocalizedData'.default.m_aItemNames[209];
			kTag.StrValue1 = class'XLocalizedData'.default.m_aItemNames[223];
			kTag.StrValue2 = class'XLocalizedData'.default.m_aItemNames[224];
		m_arrModsData[iMod].strDescription = class'XComLocalizer'.static.ExpandString(GetDescForVar(tMod.ModName));
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsStrategy'.default.bManufactureExaltLoot;
	}
	if(FindOption("ManufactureExaltLoot", "BuildGunsight", iMod, iOption))
	{
		tMod = m_arrModsData[iMod];
		tOption = m_arrModsData[iMod].arrModOptions[iOption];
			kTag.StrValue0 = class'XLocalizedData'.default.m_aItemNames[209];
			tOption.VarDisplayLabel = kTag.StrValue0;
			tOption.VarDescription =  class'XComLocalizer'.static.ExpandString(GetDescForVar(tMod.ModName$".BuildItem"));
			tOption.strInitial = class'XComModsProfile'.static.ReadSettingBool(tOption.VarName, tMod.ModName) ? "True" : "False";
		m_arrModsData[iMod].arrModOptions[iOption] = tOption;
	}
	if(FindOption("ManufactureExaltLoot", "Gunsight.iTime", iMod, iOption))
	{
		tMod = m_arrModsData[iMod];
		tOption = m_arrModsData[iMod].arrModOptions[iOption];
			i = class'MiniModsStrategy'.static.GetItemBalanceNormalFor(209).iTime;
			tOption.strInitial = class'XComModsProfile'.static.HasSetting(tOption.VarName, tMod.ModName, strSetting) ? strSetting : string(i);
			tOption.strDefault = i > 0 ? string(i) : tOption.strDefault;
			tOption.VarDisplayLabel = class'XGManufacturingUI'.default.m_strLabelTimeToBuild;
			kTag.StrValue0 = class'XLocalizedData'.default.m_aItemNames[209];
			tOption.VarDescription = class'XComLocalizer'.static.ExpandString(GetDescForVar(tMod.ModName$".iTime"));
		m_arrModsData[iMod].arrModOptions[iOption] = tOption;
	}
	if(FindOption("ManufactureExaltLoot", "Gunsight.iEng", iMod, iOption))
	{
		tMod = m_arrModsData[iMod];
		tOption = m_arrModsData[iMod].arrModOptions[iOption];
			i = class'MiniModsStrategy'.static.GetItemBalanceNormalFor(209).iEng;
			tOption.strInitial = class'XComModsProfile'.static.HasSetting(tOption.VarName, tMod.ModName, strSetting) ? strSetting : string(i);
			tOption.strDefault = i > 0 ? string(i) : tOption.strDefault;
			tOption.VarDisplayLabel = class'XGManufacturingUI'.default.m_strLabelEngineersAssigned;
			kTag.StrValue0 = class'XLocalizedData'.default.m_aItemNames[209];
			tOption.VarDescription = class'XComLocalizer'.static.ExpandString(GetDescForVar(tMod.ModName$".iEng"));
		m_arrModsData[iMod].arrModOptions[iOption] = tOption;
	}
	if(FindOption("ManufactureExaltLoot", "BuildEnhancer", iMod, iOption))
	{
		tMod = m_arrModsData[iMod];
		tOption = m_arrModsData[iMod].arrModOptions[iOption];
			kTag.StrValue0 = class'XLocalizedData'.default.m_aItemNames[223];
			tOption.VarDisplayLabel = kTag.StrValue0;
			tOption.VarDescription =  class'XComLocalizer'.static.ExpandString(GetDescForVar(tMod.ModName$".BuildItem"));
			tOption.strInitial = class'XComModsProfile'.static.ReadSettingBool(tOption.VarName, tMod.ModName) ? "True" : "False";
		m_arrModsData[iMod].arrModOptions[iOption] = tOption;
	}
	if(FindOption("ManufactureExaltLoot", "Enhancer.iTime", iMod, iOption))
	{
		tMod = m_arrModsData[iMod];
		tOption = m_arrModsData[iMod].arrModOptions[iOption];
			i = class'MiniModsStrategy'.static.GetItemBalanceNormalFor(223).iTime;
			tOption.strInitial = class'XComModsProfile'.static.HasSetting(tOption.VarName, tMod.ModName, strSetting) ? strSetting : string(i);
			tOption.strDefault = i > 0 ? string(i) : tOption.strDefault;
			tOption.VarDisplayLabel = class'XGManufacturingUI'.default.m_strLabelTimeToBuild;
			kTag.StrValue0 = class'XLocalizedData'.default.m_aItemNames[223];
			tOption.VarDescription = class'XComLocalizer'.static.ExpandString(GetDescForVar(tMod.ModName$".iTime"));
		m_arrModsData[iMod].arrModOptions[iOption] = tOption;
	}
	if(FindOption("ManufactureExaltLoot", "Enhancer.iEng", iMod, iOption))
	{
		tMod = m_arrModsData[iMod];
		tOption = m_arrModsData[iMod].arrModOptions[iOption];
			i = class'MiniModsStrategy'.static.GetItemBalanceNormalFor(223).iEng;
			tOption.strInitial = class'XComModsProfile'.static.HasSetting(tOption.VarName, tMod.ModName, strSetting) ? strSetting : string(i);
			tOption.strDefault = i > 0 ? string(i) : tOption.strDefault;
			tOption.VarDisplayLabel = class'XGManufacturingUI'.default.m_strLabelEngineersAssigned;
			kTag.StrValue0 = class'XLocalizedData'.default.m_aItemNames[223];
			tOption.VarDescription = class'XComLocalizer'.static.ExpandString(GetDescForVar(tMod.ModName$".iEng"));
		m_arrModsData[iMod].arrModOptions[iOption] = tOption;
	}
	if(FindOption("ManufactureExaltLoot", "BuildNeuroregulator", iMod, iOption))
	{
		tMod = m_arrModsData[iMod];
		tOption = m_arrModsData[iMod].arrModOptions[iOption];
			kTag.StrValue0 = class'XLocalizedData'.default.m_aItemNames[224];
			tOption.VarDisplayLabel = kTag.StrValue0;
			tOption.VarDescription =  class'XComLocalizer'.static.ExpandString(GetDescForVar(tMod.ModName$".BuildItem"));
			tOption.strInitial = class'XComModsProfile'.static.ReadSettingBool(tOption.VarName, tMod.ModName) ? "True" : "False";
		m_arrModsData[iMod].arrModOptions[iOption] = tOption;
	}
	if(FindOption("ManufactureExaltLoot", "Neuroregulator.iTime", iMod, iOption))
	{
		tMod = m_arrModsData[iMod];
		tOption = m_arrModsData[iMod].arrModOptions[iOption];
			i = class'MiniModsStrategy'.static.GetItemBalanceNormalFor(224).iTime;
			tOption.strInitial = class'XComModsProfile'.static.HasSetting(tOption.VarName, tMod.ModName, strSetting) ? strSetting : string(i);
			tOption.strDefault = i > 0 ? string(i) : tOption.strDefault;
			tOption.VarDisplayLabel = class'XGManufacturingUI'.default.m_strLabelTimeToBuild;
			kTag.StrValue0 = class'XLocalizedData'.default.m_aItemNames[224];
			tOption.VarDescription = class'XComLocalizer'.static.ExpandString(GetDescForVar(tMod.ModName$".iTime"));
		m_arrModsData[iMod].arrModOptions[iOption] = tOption;
	}
	if(FindOption("ManufactureExaltLoot", "Neuroregulator.iEng", iMod, iOption))
	{
		tMod = m_arrModsData[iMod];
		tOption = m_arrModsData[iMod].arrModOptions[iOption];
			i = class'MiniModsStrategy'.static.GetItemBalanceNormalFor(224).iEng;
			tOption.strInitial = class'XComModsProfile'.static.HasSetting(tOption.VarName, tMod.ModName, strSetting) ? strSetting : string(i);
			tOption.strDefault = i > 0 ? string(i) : tOption.strDefault;
			tOption.VarDisplayLabel = class'XGManufacturingUI'.default.m_strLabelEngineersAssigned;
			kTag.StrValue0 = class'XLocalizedData'.default.m_aItemNames[224];
			tOption.VarDescription = class'XComLocalizer'.static.ExpandString(GetDescForVar(tMod.ModName$".iEng"));
		m_arrModsData[iMod].arrModOptions[iOption] = tOption;
	}

	if(FindOption("MapImageOnSquadSelect", "", iMod))
	{
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsStrategy'.default.bMapImageOnSquadSelect;
	}
	if(FindOption("StripGearButton", "", iMod))
	{
		tMod = m_arrModsData[iMod];
			kTag.StrValue0 = class'UISquadSelect'.default.m_strStripGearLabel;
			tMod.strDescription = class'XComLocalizer'.static.ExpandString(GetDescForVar("StripGearButton"));
			tMod.bEnabledByDefault = class'MiniModsStrategy'.default.bStripGearButton;
		m_arrModsData[iMod]=tMod;
	}
	if(FindOption("MeldHealing", "", iMod))
	{
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsStrategy'.default.bMeldHealButton;
	}

	if(FindOption("ClearPerks", "", iMod))
	{
		m_arrModsData[iMod].bEnabledByDefault = class'MiniModsStrategy'.default.bClearPerksButton;
	}
	if(FindOption("ClearPerks", "CLEARPERKS_OTS_REQ", iMod, iOption))
	{
		tMod = m_arrModsData[iMod];
		tOption = m_arrModsData[iMod].arrModOptions[iOption];
			tOption.arrListLabels[0] = class'UIFxsLocalizationHelper'.default.m_strAlienDisplayName_None;
			for(i=1; i<tOption.arrListLabels.Length; ++i)
			{
				tOption.arrListLabels[i] = i @ class'XGLocalizedData'.default.OTSTechNames[i];
			}
		m_arrModsData[iMod].arrModOptions[iOption] = tOption;
	}
}
function InitWidgetDataCallback(out UIWidget kWidget, out TModOption tOption)
{
	local string strTemp;
	local int idx, iPerk, iItem, iCharges;
	local array<TModSetting> arrModSettings;
	
	if(InStr(tOption.VarPath, "MMCustomItemCharges") != -1 && InStr(tOption.VarPath, ".bEnabled") != -1)
	{
		strTemp = Split(tOption.VarPath, "[", true);
		strTemp = Left(strTemp, InStr(strTemp, "]"));
		idx = int(strTemp);
		class'XComModsProfile'.static.GetModSettings("PerkGivesItems", arrModSettings);
		iPerk   = class'XComModsProfile'.static.ReadSettingInt("iPerk."$idx,    "PerkGivesItems", arrModSettings);
		iCharges= class'XComModsProfile'.static.ReadSettingInt("iCharges."$idx, "PerkGivesItems", arrModSettings);
		iItem   = class'XComModsProfile'.static.ReadSettingInt("iItem."$idx,    "PerkGivesItems", arrModSettings);
		if(XComPlayerController(GetALocalPlayerController()).m_Pres != none && XComPlayerController(GetALocalPlayerController()).m_Pres.m_bIsPlayingGame)
		{
			kWidget.strTitle = XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kPerkTree.GetPerkName(iPerk, 0);
		}
		else
		{
			kWidget.strTitle = class'XComPerkManager'.default.m_strPassiveTitle[iPerk];
		}
		if(kWidget.strTitle == "None" || kWidget.strTitle == "")
		{
			kWidget.strTitle = "?";
		}
		kWidget.strTitle @= "->";
		kWidget.strTitle @= string(iCharges);
		strTemp = class'XLocalizedData'.default.m_aItemNames[iItem];
		if(strTemp == "None" || strTemp == "")
		{
			strTemp = "?";
		}
		kWidget.strTitle @= strTemp;
	}
	else if(InStr(tOption.VarPath, "IgnoredMoraleEvent") != -1)
	{
		if(kWidget.IsA('UIWidget_Spinner'))
		{
			UIWidget_Spinner(kWidget).arrLabels[0]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.-1");
			UIWidget_Spinner(kWidget).arrLabels[1]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.0");
			UIWidget_Spinner(kWidget).arrLabels[2]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.1");
			UIWidget_Spinner(kWidget).arrLabels[3]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.2");
			UIWidget_Spinner(kWidget).arrLabels[4]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.4");
			UIWidget_Spinner(kWidget).arrLabels[5]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.6");
		}
		else if(kWidget.IsA('UIWidget_Combobox'))
		{
			UIWidget_Combobox(kWidget).arrLabels[0]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.-1");
			UIWidget_Combobox(kWidget).arrLabels[1]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.0");
			UIWidget_Combobox(kWidget).arrLabels[2]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.1");
			UIWidget_Combobox(kWidget).arrLabels[3]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.2");
			UIWidget_Combobox(kWidget).arrLabels[4]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.4");
			UIWidget_Combobox(kWidget).arrLabels[5]=GetUINameForVar("LimitChainPanic.IgnoredMoraleEvent.N.6");
		}
	}
}
DefaultProperties
{
}
