/** This class serves as a storage for UI data of a single mod package. 
 *  The data are used by UIModManager to build sections of in-game "Mods Menu".
 *  The container is found by Mod Manager using 'foreach DynamicActors' iterator.
 *  A single container is designed as storage for one package (.u file).
 *  However, a single container can hold data of numerous mods inside the package (.u file).
 */
class UIModOptionsContainer extends Actor
	config(ModsProfile);

/** Holds data required to build a single in-game mod option (a single widget)*/
struct TModOption
{
	/** This should be unique within the mod. However, you are not restricted only to names of defined variables.*/
	var string VarName;

	/** This is used as friendly name for the variable - displayed in the menu instead of the VarName*/
	var string VarDisplayLabel;

	/** This must match a Class.Variable path to an existing property. It will be used by "set" / "get" console commands*/
	var string VarPath;

	/** Choose: eVType_Int, eVType_Float, eVType_Bool, eVType_String*/
	var EValueType eVarType;

	/** Provide a default value as a string e.g. "20" or "0.4" or "TRUE"*/
	var string strDefault;

	/** This value is used as initial value of setting when loading Mods Menu.
		Preferably pass here a reference to existing config variable.*/
	var string strInitial;

	/** This description will be displayed whenever a player highlights the variable in UI. It should explain how the variable works.*/
	var string VarDescription;

	/** Choose: eWidget_Checkbox, eWidget_Spinner, eWidget_Combobox, eWidget_Slider. If not provided: defaults to Spinner*/
	var UIWidgetType eWidgetType;

	/** Controls whether the widget is disabled for changes. Default to false.*/
	var bool bReadOnly;
	
	/** "Value" is what is actually saved. Default values are: 0, 1, 2 etc. but any order is valid. 
	    The values are scrolled-through in the order they appear in the array.*/
	var array<int> arrListValues;

	/** "Label" is what a player can see in the UI. arrListLabels[i] is used for arrListValues[i]. Default label is the value itself (as a string). 
		But it can be different, e.g. VarName=ModDiffculty, arrListValues=(0,1,2) and arrListLabels=("Easy", "Medium", "Hard"*/
	var array<string> arrListLabels;
	
	/** Optional filtering string to indicate that this is sub-option of another option. 
	 *  Example: "1.a" informs that this is sub-option "a" of an option "1".*/
	var string Index;

	structdefaultproperties
	{
		eWidgetType=eWidget_Spinner;
		bReadOnly=false;
	}
};

/** Stores data required to build a single record in "Select Mods" menu. Additionally holds all UI-configurable options for the mod.*/
struct TModUIData
{
	/** This is sort of internal ID. Try to make it unique, avoid spaces. Example: LoadoutManager, SquadronUnleashed, EnhancedTacticalInfo.*/
	var string ModName;

	/** This is used as friendly name displayed in the list of mods in the in-game menu. No restrictions - you can even use html syntax  but only 20 chars fit with standard font.*/	
	var string strDisplayName;

	/** This is the path (for instance "MiniModsTactical.m_bScoutSense") to a bool variable which will be toggled by checkbox on the Mod List*/
	var string VarPath;

	/** Make it as detailed as you wish. Tell the players what the mod does.
	 *  This description will be displayed next to the list of mods when the mod is selected
	 */
	var string strDescription;

	/** Each entry should be a path to a class: Package.ClassName. Keep the entries like the ones in DefaultMutatorLoader.ini, so like: "MiniModsCollection.MiniModsTactical" or "RevealMod.RevealModMutator"
	 *  The first entry in the array will be taken as master (main) class for the mod.
	 */
	var array<string> arrRequiredClassPaths;

	/** Each entry in this array will build a row on Credits screen for your mod. 
	 *  Check syntax of m_arrCredits in UICredits class.
	 */
	var array<string> arrCredtis;

	/** Each entry in this array holds data for one variable exposed to the in-game UI*/
	var array<TModOption> arrModOptions;

	/** Controls whether the mod should be enabled in Mods Menu when loaded for the first time or after purging XComModsProfile.ini*/
	var bool bEnabledByDefault;
	
	structdefaultproperties
	{
		bEnabledByDefault=true;
	}
};
/** Holds .ini configurable data for a mod option*/
struct TConfigModOptionInt
{
	/** Expected syntax is e.g. "1" or "1.1.2" or "3.1" etc. describing index of the option on different depth levels.*/
	var string Idx;
	var string ModName;
	var string VarName;
	/** This must match a Class.Variable path to an existing property. It will be used by "set" / "get" console commands*/
	var string VarPath;
	var array<int> arrValues;
	var int iMin;
	var int iMax;
	var int iStep;
	var int iDefault;
	/** Defaults to eWidget_Spinner (arrows left/right). Other options: eWidget_Combobox (dropdown list), eWidget_Slider (horizontal bar with a slider-tick).*/
	var UIWidgetType eWidgetType;
	var bool ReadOnly;
	
	structdefaultproperties
	{
		Idx="";
		iMax=100;
		iStep=1;
		eWidgetType=eWidget_Spinner;
	}
};
struct TConfigModOptionFloat
{
	/** Expected syntax is e.g. "1" or "1.1.2" or "3.1" etc. describing index of the option on different depth levels.*/
	var string Idx;
	var string ModName;
	var string VarName;
	/** This must match a Class.Variable path to an existing property. It will be used by "set" / "get" console commands*/
	var string VarPath;
	var array<float> arrValues;
	var float fMin;
	var float fMax;
	var float fStep;
	var float fDefault;
	/** Defaults to eWidget_Spinner (arrows left/right). Other options: eWidget_Combobox (dropdown list), eWidget_Slider (horizontal bar with a slider-tick).*/
	var UIWidgetType eWidgetType;
	var bool ReadOnly;
	
	structdefaultproperties
	{
		Idx="";
		fMin=0.0f;
		fMax=1.0f;
		fStep=0.1;
		eWidgetType=eWidget_Slider;
	}
};
struct TConfigModOptionBool
{
	/** Expected syntax is e.g. "1" or "1.1.2" or "3.1" etc. describing index of the option on different depth levels.*/
	var string Idx;
	var string ModName;
	var string VarName;
	/** This must match a Class.Variable path to an existing property. It will be used by "set" / "get" console commands*/
	var string VarPath;
	var bool bDefault;
	/** Defaults to eWidget_Checkbox. Other options: eWidget_Combobox (dropdown list), eWidget_Spinner (fieald with left/right arrows).*/
	var UIWidgetType eWidgetType;
	var bool ReadOnly;

	structdefaultproperties
	{
		Idx="";
		eWidgetType=eWidget_Checkbox;
	}
};
struct TConfigModOptionPerk
{
	/** Expected syntax is e.g. "1" or "1.1.2" or "3.1" etc. describing index of the option on different depth levels.*/
	var string Idx;
	var string ModName;
	var string VarName;
	/** This must match a Class.Variable path to an existing property. It will be used by "set" / "get" console commands*/
	var string VarPath;
	var array<int> arrValues;
	var int iDefault;
	/** Defaults to eWidget_Spinner (arrows left/right). Other options: eWidget_Combobox (dropdown list), eWidget_Slider (horizontal bar with a slider-tick).*/
	var UIWidgetType eWidgetType;
	var bool ReadOnly;
	
	structdefaultproperties
	{
		Idx="";
		eWidgetType=eWidget_Combobox;
	}
};
struct TConfigModOptionTech
{
	/** Expected syntax is e.g. "1" or "1.1.2" or "3.1" etc. describing index of the option on different depth levels.*/
	var string Idx;
	var string ModName;
	var string VarName;
	/** This must match a Class.Variable path to an existing property. It will be used by "set" / "get" console commands*/
	var string VarPath;
	var array<int> arrValues;
	var int iDefault;
	/** Defaults to eWidget_Spinner (arrows left/right). Other options: eWidget_Combobox (dropdown list), eWidget_Slider (horizontal bar with a slider-tick).*/
	var UIWidgetType eWidgetType;
	var bool ReadOnly;

	structdefaultproperties
	{
		Idx="";
		eWidgetType=eWidget_Combobox;
	}
};
struct TConfigModOptionFoundryTech
{
	/** Expected syntax is e.g. "1" or "1.1.2" or "3.1" etc. describing index of the option on different depth levels.*/
	var string Idx;
	var string ModName;
	var string VarName;
	/** This must match a Class.Variable path to an existing property. It will be used by "set" / "get" console commands*/
	var string VarPath;
	var array<int> arrValues;
	var int iDefault;
	/** Defaults to eWidget_Spinner (arrows left/right). Other options: eWidget_Combobox (dropdown list), eWidget_Slider (horizontal bar with a slider-tick).*/
	var UIWidgetType eWidgetType;
	var bool ReadOnly;

	structdefaultproperties
	{
		Idx="";
		eWidgetType=eWidget_Combobox;
	}
};
struct TConfigModOptionItem
{
	/** Expected syntax is e.g. "1" or "1.1.2" or "3.1" etc. describing index of the option on different depth levels.*/
	var string Idx;
	var string ModName;
	var string VarName;
	/** This must match a Class.Variable path to an existing property. It will be used by "set" / "get" console commands*/
	var string VarPath;
	var array<int> arrValues;
	var int iDefault;
	/** Defaults to eWidget_Spinner (arrows left/right). Other options: eWidget_Combobox (dropdown list), eWidget_Slider (horizontal bar with a slider-tick).*/
	var UIWidgetType eWidgetType;
	var bool ReadOnly;

	structdefaultproperties
	{
		Idx="";
		eWidgetType=eWidget_Combobox;
	}
};
struct TConfigModUIData
{
	var string ModName;
	var array<string> ModClassList;
	var bool bEnabledByDefault;
	var string VarPath;

	structdefaultproperties
	{
		bEnabledByDefault=true;
	}
};
/** Holds UI data for mods inside a package.*/
var array<TModUIData> m_arrModsData;

/** This string will be passed as an argument for DynamicLoadObject function to check if the required package exists.*/
var string m_strMasterClass;

var localized array<string> m_arrVarName;
var localized array<string> m_arrVarFriendlyName;
var localized array<string> m_arrVarDescription;
var localized array<string> m_arrCreditsModMgr;
var config array<TConfigModOptionInt> ModOptionInt;
var config array<TConfigModOptionFloat> ModOptionFloat;
var config array<TConfigModOptionBool> ModOptionBool;
var config array<TConfigModOptionPerk> ModOptionPerk;
var config array<TConfigModOptionItem> ModOptionItem;
var config array<TConfigModOptionTech> ModOptionTech;
var config array<TConfigModOptionFoundryTech> ModOptionFoundryTech;
var config array<TConfigModUIData> ModRecord;

event PostBeginPlay()
{
	BuildDataFromConfig();
}

/** @param kMasterMod The package and class of this object will be assigned to m_strMasterClass property.*/
function Init(Object kMasterMod)
{
	m_strMasterClass = string(kMasterMod.Class.GetPackageName()) $ "." $ string(kMasterMod.Class);
}

/** Adds a new record holding UI data of a single mod. Please make sure that tNewModData holds at least one entry in arrRequiredClassPaths.*/
function AddModDataRecord(TModUIData tNewModData)
{
	//ensure m_strMasterClass (Init call might have been skipped).
	if(m_strMasterClass == "" && m_arrModsData.Length == 0)
	{
		if(tNewModData.arrRequiredClassPaths.Length > 0)
		{
			m_strMasterClass = tNewModData.arrRequiredClassPaths[0];
		}
		else
		{
			Init(Owner);
		}
	}
	m_arrModsData.AddItem(tNewModData);
}

/** Builds a new in-game menu option (of type "int") for specified mod. */
function TModOption BuildConfigVarInt(string VarName, int iInitial=0, optional int iMin=0, optional int iMax=100, optional int iStep=1, optional int iDefault=0, optional string strDisplayLabel="", optional string strDescription="", optional UIWidgetType eWidgetType=eWidget_Spinner, optional bool bReadOnly=FALSE, optional string VarPath, optional string strIndex)
{
	local TModOption tNewOption;
	local int i;

	if(iStep == 0)
	{
		iStep = 1;
	}
	tNewOption.VarName = VarName;
	tNewOption.VarDisplayLabel = (strDisplayLabel != "" ? strDisplayLabel : VarName);
	tNewOption.eVarType = eVType_Int;
	tNewOption.strInitial = string(iInitial);
	tNewOption.strDefault = string(iDefault);
	tNewOption.VarDescription = strDescription;
	if(eWidgetType == eWidget_Slider && ((iMax - iMin)/iStep) > 100)
	{
		//a slider can only handle 101 different values, otherwise force-change to spinner
		eWidgetType = eWidget_Spinner;
	}
	tNewOption.eWidgetType = eWidgetType;
	tNewOption.bReadOnly = bReadOnly;
	tNewOption.VarPath = VarPath;
	for(i = iMin; i <= iMax; i += iStep)
	{
		if(i > iMax)
		{
			i = iMax;
		}
		tNewOption.arrListLabels.AddItem(string(i));
		if(eWidgetType != eWidget_Slider)
		{
			//arrListValues for a slider is built by UIModShell.InitWidgetDataFromTOption
			tNewOption.arrListValues.AddItem(i);
		}
	}
	tNewOption.Index = strIndex;
	return tNewOption;
}
/** Adds a new in-game menu option (of type "int") for specified mod.
 *  @param ModName It should match ModName property of some existing TModUIData record. If no match found - a new TModUIData record will be created when using AddModOption.
 *  @param VarName Recommended name is the actual name of the exposed variable. A "friendly" name to be displayed in menu is held by optional strDisplayLabel parameter.
 *  @param iInitial Initial value for the widget when entering Mods Menu. Defaults to 0.
 *  @param iMin Minimum value that can be set in-game. Defaults to 0.
 *  @param iMax Maximum value that can be set in-game. Defaults to 100.
 *  @param iStep Increase/decrease step when scrolling through possible values. Defaults to 1.
 *  @param iDefault Default value for the variable. Defaults to 0.
 *  @param strDisplayLabel If provided this will be displayed in the menu instead of VarName.
 *  @param strDescription Use this to explain what the variable controls and how its values work.
 *  @param eWidgetType UI widget type. Defaults to eWidget_Spinner (arrows left/right); other options: eWidget_Combobox (dropdown list), eWidget_Slider (horizontal bar with a slider-tick).
 *  @param bReadOnly Defaults to FALSE. Otherwise it is a read-only option.
 *  @param VarPath This must match Class.Variable reference to an existing, defined variable. It will serve as argument for "set" / "get" console commands.
 */
function AddConfigVarInt(string ModName, string VarName, optional int iInitial=0, optional int iMin=0, optional int iMax=100, optional int iStep=1, optional int iDefault=0, optional string strDisplayLabel="", optional string strDescription="", optional UIWidgetType eWidgetType=eWidget_Spinner, optional bool bReadOnly=FALSE, optional string VarPath, optional string strIndex)
{
	AddModOption(ModName, BuildConfigVarInt(VarName, iInitial, iMin, iMax, iStep, iDefault, strDisplayLabel, strDescription, eWidgetType, bReadOnly, VarPath, strIndex));
}

/** Builds a new in-game menu option (of type "float") for specified mod.*/
function TModOption BuildConfigVarFloat(string VarName, optional float fInitial=0.0, optional float fMinimum=0.0, optional float fMaximum=1.0, optional float fStep=0.1, optional float fDefault=0.0, optional string strDisplayLabel="", optional string strDescription="", optional UIWidgetType eWidgetType=eWidget_Slider, optional bool bReadOnly=FALSE, optional string VarPath, optional string strIndex)
{
	local TModOption tNewOption;
	local float fCurrent;

	if(fStep == 0.0)
	{
		fStep = 0.10;
	}
	tNewOption.VarName = VarName;
	tNewOption.VarDisplayLabel = (strDisplayLabel != "" ? strDisplayLabel : VarName);
	tNewOption.eVarType = eVType_Float;
	tNewOption.strInitial = Left(fInitial, InStr(fInitial, ".") + 3);
	tNewOption.strDefault = Left(fDefault, InStr(fDefault, ".") + 3);
	tNewOption.VarDescription = strDescription;
	if(eWidgetType == eWidget_Slider && ( int(fMaximum - fMinimum)/fStep) > 100)
	{
		//a slider can only handle 101 different values, otherwise force-change to spinner
		eWidgetType = eWidget_Spinner;
	}
	tNewOption.eWidgetType = eWidgetType;
	tNewOption.bReadOnly = bReadOnly;
	tNewOption.VarPath = VarPath;
	fCurrent = fMinimum;
	while(fCurrent <= fMaximum)
	{
		tNewOption.arrListLabels.AddItem(Left(fCurrent, InStr(fCurrent, ".") + 3));
		//arrListValues for a slider will be built from arrListLabels by UIModShell.InitWidgetDataFromTOption
		//other widget type are handled below
		if(eWidgetType != eWidget_Slider)
		{
			tNewOption.arrListValues.AddItem(int(fCurrent * 100.0));
		}
		if(fCurrent == fMaximum)
		{
			break;
		}
		else
		{
			fCurrent = FMin(fCurrent + fStep, fMaximum);
		}
	}
	tNewOption.Index = strIndex;
	return tNewOption;
}
/** Adds a new in-game menu option (of type "float") for specified mod.
 *  @param ModName It should match ModName property of some existing TModUIData record. If no match found - a new TModUIData record will be created when using AddModOption.
 *  @param VarName Recommended name is the actual name of the exposed variable. A "friendly" name to be displayed in menu is held by optional strDisplayLabel parameter.
 *  @param fInitial Initial value for the widget when entering Mods Menu. Defaults to 0.0.
 *  @param fMinimum Minimum value that can be set in-game. Defaults to 0.0. Negative values will be clamped to 0.0.
 *  @param fMaximum Maximum value that can be set in-game. Defaults to 1.0.
 *  @param fStep Increase/decrease step when scrolling through possible values. Defaults to 0.1.
 *  @param fDefault Default value for the variable. Defaults to 0.0.
 *  @param strDisplayLabel If provided this will be displayed in the menu instead of VarName.
 *  @param strDescription Use this to explain what the variable controls and how its values work.
 *  @param eWidgetType UI widget type. Defaults to eWidget_Slider (horizontal bar with a slider-tick/thumb). If number of different values resulting from Min/Max/Step exceed 101 eWidget_Spinner will be force-changed to eWidget_Spinner; other options: eWidget_Combobox (dropdown list), eWidget_Spinner (arrows left/right).
 *  @param bReadOnly Defaults to FALSE. Otherwise it is a read-only option.
 *  @param VarPath This must match Class.Variable reference to an existing, defined variable. It will serve as argument for "set" / "get" console commands.
 */
function AddConfigVarFloat(string ModName, string VarName, optional float fInitial=0.0, optional float fMinimum=0.0, optional float fMaximum=1.0, optional float fStep=0.1, optional float fDefault=0.0, optional string strDisplayLabel="", optional string strDescription="", optional UIWidgetType eWidgetType=eWidget_Slider, optional bool bReadOnly=FALSE, optional string VarPath, optional string strIndex)
{
	AddModOption(ModName, BuildConfigVarFloat(VarName, fInitial, fMinimum, fMaximum, fStep, fDefault, strDisplayLabel, strDescription, eWidgetType, bReadOnly, VarPath, strIndex)); 
}
/** Builds a new in-game menu option (of type "bool") for the specified mod.*/
function TModOption BuildConfigVarBool(string VarName, optional bool bInitial=FALSE, optional bool bDefault=FALSE, optional string strDisplayLabel="", optional string strDescription="", optional UIWidgetType eWidgetType=eWidget_Checkbox, optional bool bReadOnly=FALSE, optional string VarPath, optional string strIndex)
{
	local TModOption tNewOption;

	if(eWidgetType == eWidget_Slider)
	{
		eWidgetType = eWidget_Spinner;
	}
	tNewOption.VarName = VarName;
	tNewOption.VarDisplayLabel = (strDisplayLabel != "" ? strDisplayLabel : VarName);
	tNewOption.eVarType = eVType_Bool;
	tNewOption.strInitial = (bInitial ? "true" : "false");
	tNewOption.strDefault = (bDefault ? "true" : "false");
	tNewOption.VarDescription = strDescription;
	tNewOption.eWidgetType = eWidgetType;
	tNewOption.bReadOnly = bReadOnly;
	tNewOption.VarPath = VarPath;
	tNewOption.arrListValues.AddItem(0);
	tNewOption.arrListLabels.AddItem("FALSE");
	tNewOption.arrListValues.AddItem(1);
	tNewOption.arrListLabels.AddItem("TRUE");
	tNewOption.Index = strIndex;
	return tNewOption;
}
/** Adds a new in-game menu option (of type "bool") for the specified mod.
 *  @param ModName It should match ModName property of some existing TModUIData record. If no match found - a new TModUIData record will be created when using AddModOption.
 *  @param VarName Recommended name is the actual name of the exposed variable. A "friendly" name to be displayed in menu is held by optional strDisplayLabel parameter.
 *  @param bInitial Initial value for the widget when entering Mods Menu. Defaults to FALSE.
 *  @param bDefault Default value for the variable. Defaults to FALSE.
 *  @param strDisplayLabel If provided this will be displayed in the menu instead of VarName.
 *  @param strDescription Use this to explain what the variable controls and how its values work.
 *  @param eWidgetType UI widget type. Defaults to eWidget_Checkbox; other options: eWidget_Combobox (dropdown list), eWidget_Spinner (arrows left/right).
 *  @param bReadOnly Defaults to FALSE. Otherwise it is a read-only option.
 *  @param VarPath This must match Class.Variable reference to an existing, defined variable. It will serve as argument for "set" / "get" console commands.
 */
function AddConfigVarBool(string ModName, string VarName, optional bool bInitial=FALSE, optional bool bDefault=FALSE, optional string strDisplayLabel="", optional string strDescription="", optional UIWidgetType eWidgetType=eWidget_Checkbox, optional bool bReadOnly=FALSE, optional string VarPath, optional string strIndex)
{
	AddModOption(ModName, BuildConfigVarBool(VarName, bInitial, bDefault, strDisplayLabel, strDescription, eWidgetType, bReadOnly, VarPath, strIndex));
}
function AddModOption(string ModName, TModOption tOption)
{
	local TModUIData tModData;
	local bool bFound;
	local int i;

	foreach m_arrModsData(tModData, i)
	{
		if(CAPS(tModData.ModName) == CAPS(ModName))
		{
			bFound = true;
			m_arrModsData[i].arrModOptions.AddItem(tOption);
		}
	}
	if(!bFound)
	{
		LogInternal("WARNING:" @ GetFuncName() @ "- mod record for \"" @ ModName @ "\"not found, creating a new one", 'UIModManager');
		//ModName not found so a new record will be created:
		tModData.ModName = ModName;
		if(m_strMasterClass == "")
		{
			if(Owner.IsA('XComMutator') || Owner.IsA('XComMod'))
			{
				m_strMasterClass = string(Owner.GetPackageName()) $ "." $ string(Owner.Class);
			}
		}
		if(m_strMasterClass != "" && tModData.arrRequiredClassPaths.Find(m_strMasterClass) < 0)
		{
			tModData.arrRequiredClassPaths.AddItem(m_strMasterClass);
		}
		tModData.arrModOptions.AddItem(tOption);
		AddModDataRecord(tModData);
	}
}
function AddConfigVarTech(string ModName, string VarName, optional int iInitial=0, optional int iDefault=0, optional string strDisplayLabel="", optional string strDescription="", optional UIWidgetType eWidgetType=eWidget_Combobox, optional bool bReadOnly=FALSE, optional string VarPath, optional string strIndex)
{
	local TModOption tOption;
	local int iTech;

	tOption = BuildConfigVarInt(VarName, iInitial,, eTech_MAX - 1,, iDefault, strDisplayLabel, strDescription, eWidgetType, bReadOnly, VarPath, strIndex);
	tOption.arrListLabels[0] = class'UIFxsLocalizationHelper'.default.m_strAlienDisplayName_None;
	for(iTech=1; iTech < tOption.arrListLabels.Length; ++iTech)
	{
		tOption.arrListLabels[iTech] = iTech @ class'XGLocalizedData'.default.TechTypeNames[iTech];
	}
	AddModOption(ModName, tOption);
}
function AddConfigVarFoundryTech(string ModName, string VarName, optional int iInitial=0, optional int iDefault=0, optional string strDisplayLabel="", optional string strDescription="", optional UIWidgetType eWidgetType=eWidget_Combobox, optional bool bReadOnly=FALSE, optional string VarPath, optional string strIndex)
{
	local TModOption tOption;
	local int iTech;

	tOption = BuildConfigVarInt(VarName, iInitial,, eFoundry_MAX - 1,, iDefault, strDisplayLabel, strDescription, eWidgetType, bReadOnly, VarPath, strIndex);
	tOption.arrListLabels[0] = class'UIFxsLocalizationHelper'.default.m_strAlienDisplayName_None;
	for(iTech=1; iTech < tOption.arrListLabels.Length; ++iTech)
	{
		tOption.arrListLabels[iTech] = iTech @ class'XGLocalizedData'.default.FoundryTechNames[iTech];
	}
	AddModOption(ModName, tOption);
}
function AddConfigVarPerk(string ModName, string VarName,optional int iInitial=0, optional int iDefault=0, optional string strDisplayLabel="", optional string strDescription="", optional UIWidgetType eWidgetType=eWidget_Combobox, optional bool bReadOnly=FALSE, optional string VarPath, optional string strIndex)
{
	local TModOption tOption;
	local int iPerk, iNumPerks;

	if(XComPlayerController(GetALocalPlayerController()).m_Pres != none && XComPlayerController(GetALocalPlayerController()).m_Pres.m_bIsPlayingGame)
	{
		iNumPerks = XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kPerkTree.GetNumPerks();
		tOption = BuildConfigVarInt(VarName, iInitial,, iNumPerks-1,, iDefault, strDisplayLabel, strDescription, eWidgetType, bReadOnly, VarPath, strIndex);
		tOption.arrListLabels[0] = class'UIFxsLocalizationHelper'.default.m_strAlienDisplayName_None;
		for(iPerk=1; iPerk < tOption.arrListLabels.Length; ++iPerk)
		{
			tOption.arrListLabels[iPerk] = iPerk @ XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kPerkTree.GetPerkName(iPerk, 0);
		}
	}
	else
	{
		iNumPerks = 172;
		tOption = BuildConfigVarInt(VarName, iInitial,, iNumPerks-1,,iDefault, strDisplayLabel, strDescription, eWidgetType, bReadOnly, VarPath, strIndex);
		tOption.arrListLabels[0] = class'UIFxsLocalizationHelper'.default.m_strAlienDisplayName_None;
		for(iPerk=1; iPerk < tOption.arrListLabels.Length; ++iPerk)
		{
			tOption.arrListLabels[iPerk] = iPerk @ class'XComPerkManager'.default.m_strPassiveTitle[iPerk];
		}
	}
	AddModOption(ModName, tOption);
}
function AddConfigVarItem(string ModName, string VarName,optional int iInitial=0, optional int iDefault=0, optional string strDisplayLabel="", optional string strDescription="", optional UIWidgetType eWidgetType=eWidget_Combobox, optional bool bReadOnly=FALSE, optional string VarPath, optional string strIndex)
{
	local TModOption tOption;
	local int iItem;

	tOption = BuildConfigVarInt(VarName, iInitial,, 254,, iDefault, strDisplayLabel, strDescription, eWidgetType, bReadOnly, VarPath, strIndex);
	tOption.arrListLabels[0] = class'UIFxsLocalizationHelper'.default.m_strAlienDisplayName_None;
	for(iItem=1; iItem < tOption.arrListLabels.Length; ++iItem)
	{
		tOption.arrListLabels[iItem] = iItem @ class'XLocalizedData'.default.m_aItemNames[iItem];
	}
	AddModOption(ModName, tOption);
}
/** Extracts friendly name to be displayed for a given internal VarName*/
function string GetUINameForVar(string strVarName)
{
	local int iFound;
	local string strFoundName;

	iFound = m_arrVarName.Find(strVarName);
	if(iFound != -1)
	{
		strFoundName = m_arrVarFriendlyName[iFound];
	}
	if(strFoundName != "") 
	{
		return strFoundName; 
	}
	else if(InStr(strVarName, ".") != -1) 
	{
		return Split(strVarName, ".", true);
	}
	else
	{
		return strVarName;
	}
}
/** Extracts description to be displayed for a given internal VarName*/
function string GetDescForVar(string strVarName)
{
	local int iFound;

	iFound = m_arrVarName.Find(strVarName);
	if(iFound != -1 && m_arrVarDescription[iFound] != "")
	{
		return m_arrVarDescription[iFound];
	}
	else
	{
		return class'UIModManager'.default.m_strNoDescription;
	}
}
function int FindModDataFor(string ModName, optional out TModUIData tModData)
{
	local int iFound;

	iFound = m_arrModsData.Find('ModName', ModName);
	if(iFound != -1)
	{
		tModData = m_arrModsData[iFound];
	}
	return iFound;
}
function bool FindOption(string sMod, string sVar, optional out int iMod, optional out int iOption)
{
	iOption = -1;
	iMod = FindModDataFor(sMod);
	if(iMod != -1)
	{
		iOption = m_arrModsData[iMod].arrModOptions.Find('VarName', sVar); 
	}
	return (sVar != "" ? iOption != -1 : iMod != -1);
}

function BuildDataFromConfig()
{
	BuildConfigModRecords();
	BuildConfigModOptionsBool();
	BuildConfigModOptionsInt();
	BuildConfigModOptionsFloat();
	BuildConfigModOptionsPerks();
	BuildConfigModOptionsItems();
	BuildConfigModOptionsTechs();
	BuildConfigModOptionsFoundryTechs();
}
function BuildConfigModRecords()
{
	local TConfigModUIData tModRecord;
	local TModUIData tModData;
	local int i;

	foreach default.ModRecord(tModRecord)
	{
		tModData.ModName            = tModRecord.ModName;
		tModData.bEnabledByDefault  = tModRecord.bEnabledByDefault;
		tModData.VarPath            = tModRecord.VarPath;
		tModData.arrRequiredClassPaths.Length = 0;
		for(i=0; i < tModRecord.ModClassList.Length; ++i)
		{
			tModData.arrRequiredClassPaths[i] = tModRecord.ModClassList[i];
		}
		tModData.strDisplayName = GetUINameForVar(tModRecord.ModName);
		tModData.strDescription = GetDescForVar(tModRecord.ModName);
		tModData.arrCredtis = GetCreditsForMod(tModData.ModName);
		AddModDataRecord(tModData);
	}
}
function array<string> GetCreditsForMod(string ModName)
{
	local array<string> arrModCredits;
	local int iStart, iEnd, idx;

	iStart = m_arrCreditsModMgr.Find("BEGIN_" $ ModName);
	iEnd = m_arrCreditsModMgr.Find("END_" $ ModName);
	if(iStart >=0 && iEnd > iStart)
	{
		for(idx = iStart + 1; idx < iEnd; ++idx)
		{
			arrModCredits.AddItem(m_arrCreditsModMgr[idx]);
		}
	}
	return arrModCredits;
}
/** Performs parsing of provided path and tries to extract the value using "get" console command*/
static function string ConsoleGetSetting(string strPath)
{
	local string strObject, strProperty, strArray, strMember, strElement, strSetting;
	local array<string> arrElements;
	local bool bStruct, bArray, bReverseBool;
	local int iElement, iLeftBr, iRightBr, iDot;

	if(Left(strPath, 1) == "!")
	{
		strPath = Split(strPath, "!", true);
		bReverseBool = true;
	}
	//categorize the path
	strObject = Left(strPath, InStr(strPath, "."));
	strProperty = Split(strPath, ".", true);
	iLeftBr = InStr(strProperty,"[");
	iDot = InStr(strProperty, ".");
	bStruct = iDot != -1;
	bArray = (iLeftBr != -1) && (bStruct ? iLeftBr < iDot : true);

	if(!bArray && !bStruct)
	{
		//path points to simple variable
		strSetting = class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("get" @ strObject @ strProperty, false);
	}
	else if(!bStruct)
	{

		//path points to an array of single type elements, like (0,1,2,3)
		strArray = class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("get" @ strObject @ Left(strProperty, iLeftBr), false); //get the array
		strArray = Mid(strArray, 1, Len(strArray) - 2); //trim opening and closing parenthesis
		ParseStringIntoArray(strArray, arrElements, ",", false);
		iElement = int(Mid(strProperty, iLeftBr + 1, Len(strProperty) - iLeftBr - 2));
		if(arrElements.Length - 1 < iElement)
		{
			LogInternal("Warning:" @ GetFuncName() @ strPath @ "accessed" @ Left(strPath, InStr(strPath, "[")) @ "out of bounds("$ iElement $"/"$ arrElements.Length $ "). Expanding the array ...");
			arrElements.Length = iElement + 1;
		}
		strSetting = arrElements[iElement];
	}
	else if(!bArray)
	{
		//path points to a struct variable, like (iMin=5,iMax=8,iType=5)
		strElement = class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("get" @ strObject @ Left(strProperty, iDot), false); //get the struct
		strElement = Mid(strElement, 1, Len(strElement) - 2); //trim opening and closing parenthesis "(" and ")"
		strMember = Mid(strProperty, iDot + 1);
		strSetting = Split(strElement, strMember $ "=", true);
		if(InStr(strSetting, ",") != -1)
		{
			strSetting = Left(strSetting, InStr(strSetting, ","));
		}
	}
	else
	{
		//path points to an array of structs, like ((iMin=0,iMax=2,iType=1),(iMin=5,iMax=8,iType=3))
		strArray = class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("get" @ strObject @ Left(strProperty, iLeftBr), false); //get the array
		strArray = Mid(strArray, 2, Len(strArray) - 4); //trim opening and closing parenthesis (( ))
		ParseStringIntoArray(strArray, arrElements, "),(", false);
		iRightBr = InStr(strProperty, "]");
		iElement = int(Mid(strProperty, iLeftBr + 1, iRightBr - iLeftBr - 1));
		if(arrElements.Length - 1 < iElement)
		{
			LogInternal("Warning:" @ GetFuncName() @ strPath @ "accessed" @ Left(strPath, InStr(strPath, "[")) @ "out of bounds("$ iElement $"/"$ arrElements.Length $ "). Expanding the array ...");
			arrElements.Length = iElement + 1;
		}
		strElement = arrElements[iElement];
		strMember = Mid(strProperty, iDot + 1);
		strSetting = Split(strElement, strMember $ "=", true);
		if(InStr(strSetting, ",") != -1)
		{
			strSetting = Left(strSetting, InStr(strSetting, ","));
		}
	}
	if(strSetting == string(true))
	{
		strSetting = bReverseBool ? "false" : "true";
	}
	else if(strSetting == string(false))
	{
		strSetting = bReverseBool ? "true" : "false";
	}
	return strSetting;
}
static function string ConsoleSetSetting(string strPath, string strValue)
{
	local string strObject, strProperty, strArray, strMember, strElement, strFiller, strSetting, strError;
	local array<string> arrElements;
	local bool bStruct, bArray;
	local int iElement, iLeftBr, iRightBr, iDot;

	//paths to bool variables flagged with "!" are supposed to be handled oppositely
	if(Left(strPath, 1) == "!")
	{
		strPath = Split(strPath, "!", true);
		if(strValue == string(true) || strValue == string(false))
		{
			strError @= strPath @ "handled oppositely, strValue was" @ strValue @ ", will be saved as" @ string(!bool(strValue)) $".";
			strValue = string(!bool(strValue));
		}
	}
	//categorize the path
	strObject = Left(strPath, InStr(strPath, "."));
	strProperty = Split(strPath, ".", true);
	iLeftBr = InStr(strProperty,"[");
	iDot = InStr(strProperty, ".");
	bStruct = iDot != -1;
	bArray = (iLeftBr != -1) && (bStruct ? iLeftBr < iDot : true);

	if(!bArray && !bStruct)
	{
		//path points to simple variable
		class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("set" @ strObject @ strProperty @ strValue, false);
	}
	else if(!bStruct)
	{
		//path points to an array of single type elements
		strArray = class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("get" @ strObject @ Left(strProperty, iLeftBr), false); //get the array
		strArray = Mid(strArray, 1, Len(strArray) - 2); //trim opening and closing parenthesis
		ParseStringIntoArray(strArray, arrElements, ",", false);
		iElement = int(Mid(strProperty, iLeftBr + 1, Len(strProperty) - iLeftBr - 2));
		if(arrElements.Length - 1 < iElement)
		{
			strError = "Warning:" @ GetFuncName() @ strPath @ "accessed" @ Left(strPath, InStr(strPath, "[")) @ "out of bounds ("$ iElement $"/"$ arrElements.Length $ "). Expanding the array.";
			strFiller = arrElements[arrElements.Length - 1]; //make the last element be the filler
			do
			{
				arrElements.AddItem(strFiller);
			}
			until(arrElements.Length -1 == iElement);		
		}
		arrElements[iElement] = strValue;
		JoinArray(arrElements, strArray,, false);
		strArray = "(" $ strArray $ ")";
		class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("set" @ strObject @ Left(strProperty, iLeftBr) @ strArray, false);
	}
	else if(!bArray)
	{
		strElement = class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("get" @ strObject @ Left(strProperty, iDot), false); //get the struct
		strElement = Mid(strElement, 1, Len(strElement) - 2); //trim opening and closing parenthesis "(" and ")"
		strMember = Mid(strProperty, iDot + 1);
		if(InStr(strElement, strMember,,true) < 0)
		{
			strError @=	"Warning:" @ GetFuncName() @ strPath @ "accessed non existing" @ strMember @ "at" @ strObject $"."$ Left(strProperty, iDot) $". Aborting...";
		}
		else
		{
			strSetting = Split(strElement, strMember $ "=", true);
			if(InStr(strSetting, ",") != -1)
			{
				strSetting = Left(strSetting, InStr(strSetting, ","));
			}
			strElement = Repl(strElement, strMember$"="$strSetting, strMember$"="$strValue, false);
		}
		strElement = "(" $ strElement$ ")";
		class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("set" @ strObject @ Left(strProperty, iDot) @ strElement, false);
	}
	else
	{
		//path points to an array of structs (this is a tough task)
		strArray = class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("get" @ strObject @ Left(strProperty, iLeftBr), false); //get the array
		strArray = Mid(strArray, 2, Len(strArray) - 4); //trim opening and closing double parenthesis (( ))
		ParseStringIntoArray(strArray, arrElements, "),(", false);
		iRightBr = InStr(strProperty, "]");
		iElement = int(Mid(strProperty, iLeftBr + 1, iRightBr - iLeftBr - 1));
		if(iElement > arrElements.Length - 1)
		{
			strError = "Warning:" @ GetFuncName() @ strPath @ "accessed" @ Left(strPath, InStr(strPath, "[")) @ "out of bounds("$ iElement $"/"$ arrElements.Length $ "). Expanding the array ...";
			strFiller = arrElements[arrElements.Length - 1]; //make the last element be the filler
			do
			{
				arrElements.AddItem(strFiller);
			}
			until(
			arrElements.Length -1 == iElement);
		}
		strElement = arrElements[iElement];
			strMember = Mid(strProperty, iDot + 1);
			if(InStr(strElement, strMember,,true) < 0)
			{
				strError @=	"Warning:" @ GetFuncName() @ strPath @ "accessed non existing" @ strMember @ "at" @ Left(strPath, InStr(strPath, "]") + 1) $". Aborting...";
			}
			else
			{
				strSetting = Split(strElement, strMember $ "=", true);
				if(InStr(strSetting, ",") != -1)
				{
					strSetting = Left(strSetting, InStr(strSetting, ","));
				}
				strElement = Repl(strElement, strMember$"="$strSetting, strMember$"="$strValue, false);
			}
		arrElements[iElement] = strElement;
		JoinArray(arrElements, strArray, "),("); //turn the array back into a string
		strArray = "((" $ strArray $ "))"; //wrap the string in parenthesis
		class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("set" @ strObject @ Left(strProperty, iLeftBr) @ strArray, false);
	}
	`Log(strError, strError != "", 'UIModManager');
	return strError;
}
function BuildConfigModOptionsInt()
{
	local TConfigModOptionInt tOption;
	local TModOption tO;
	local int i;
	local string strValFromConsole;

	foreach default.ModOptionInt(tOption)
	{
		if(tOption.VarPath != "")
		{
			strValFromConsole = ConsoleGetSetting(tOption.VarPath);
			if(Len(strValFromConsole) > 1 && int(strValFromConsole) == 0)
			{
				//this must be an enum value, cause Len("0") would equal 1)
				//therefore it's of no use
				strValFromConsole = "";
			}
		}
		tO = BuildConfigVarInt(tOption.VarName, strValFromConsole != "" ? int(strValFromConsole) : class'XComModsProfile'.static.ReadSettingInt(tOption.VarName, tOption.ModName), tOption.iMin, tOption.iMax, tOption.iStep, tOption.iDefault, GetUINameForVar(tOption.ModName $"."$ tOption.VarName), GetDescForVar(tOption.ModName $"."$ tOption.VarName), tOption.eWidgetType, tOption.ReadOnly, tOption.VarPath, tOption.Idx);
		if(tOption.arrValues.Length > 0)
		{
			tO.arrListValues = tOption.arrValues;
			tO.arrListLabels.Length = 0;
			for(i=0; i < tO.arrListValues.Length; ++i)
			{
				if(m_arrVarName.Find(tOption.ModName $"."$ tOption.VarName $"."$ tO.arrListValues[i]) != -1)
				{
					tO.arrListLabels.AddItem(GetUINameForVar(tOption.ModName $"."$ tOption.VarName $"."$ tO.arrListValues[i]));
				}
				else
				{
					tO.arrListLabels.AddItem(string(tO.arrListValues[i]));
				}
			}
		}
		AddModOption(tOption.ModName, tO);
		//if Idx is provided remove the option from the end of list and put at the specified Idx
		//if(tOption.Idx != -1)
		//{
		//	i = FindModDataFor(tOption.ModName);
		//	m_arrModsData[i].arrModOptions.Remove(m_arrModsData[i].arrModOptions.Length - 1, 1);
		//	if(tOption.Idx > m_arrModsData[i].arrModOptions.Length - 1)
		//	{
		//		m_arrModsData[i].arrModOptions.Length = tOption.Idx + 1;
		//	}
		//	m_arrModsData[i].arrModOptions[tOption.Idx] = tO;
		//}
	}
}
function BuildConfigModOptionsFloat()
{
	local TConfigModOptionFloat tOption;
	local TModOption tO;
	local int i;
	local string sTrimmedVal;

	foreach default.ModOptionFloat(tOption)
	{
		if(tOption.arrValues.Length > 0)
		{
			tO = BuildConfigVarFloat(tOption.VarName, tOption.VarPath != "" ? float(ConsoleGetSetting(tOption.VarPath)) : class'XComModsProfile'.static.ReadSettingFloat(tOption.VarName, tOption.ModName), 0.0, 0.10, 0.10, tOption.fDefault, GetUINameForVar(tOption.ModName $"."$ tOption.VarName), GetDescForVar(tOption.ModName $"."$ tOption.VarName), tOption.eWidgetType, tOption.ReadOnly, tOption.VarPath, tOption.Idx);
			tO.arrListLabels.Length=0;
			tO.arrListValues.Length=0;
			for(i=0; i < tOption.arrValues.Length; ++i)
			{
				sTrimmedVal = Left(tOption.arrValues[i], InStr(tOption.arrValues[i], ".") + 3);
				if(tO.eWidgetType != eWidget_Slider)
				{
					tO.arrListValues.AddItem(int(tOption.arrValues[i] * 100.0));
					if(m_arrVarName.Find(tOption.ModName $"."$ tOption.VarName $"."$ sTrimmedVal) != -1)
					{
						tO.arrListLabels.AddItem(GetUINameForVar(tOption.ModName $"."$ tOption.VarName $"."$ sTrimmedVal));
					}
					else
					{
						tO.arrListLabels.AddItem(sTrimmedVal);
					}
				}
				else
				{
					tO.arrListLabels.AddItem(sTrimmedVal);
					//arrValues for a slider will be built from arrListLabels by UIModShell
				}
			}			
		}
		else
		{
			tO = BuildConfigVarFloat(tOption.VarName, tOption.VarPath != "" ? float(ConsoleGetSetting(tOption.VarPath)) : class'XComModsProfile'.static.ReadSettingFloat(tOption.VarName, tOption.ModName), tOption.fMin, tOption.fMax, tOption.fStep, tOption.fDefault, GetUINameForVar(tOption.ModName $"."$ tOption.VarName), GetDescForVar(tOption.ModName $"."$ tOption.VarName), tOption.eWidgetType, tOption.ReadOnly, tOption.VarPath, tOption.Idx);
		}
		AddModOption(tOption.ModName, tO);
		//if Idx is provided remove the option from the end of list and put at the specified Idx
		//if(tOption.Idx != -1)
		//{
		//	i = FindModDataFor(tOption.ModName);
		//	m_arrModsData[i].arrModOptions.Remove(m_arrModsData[i].arrModOptions.Length - 1, 1);
		//	if(tOption.Idx > m_arrModsData[i].arrModOptions.Length - 1)
		//	{
		//		m_arrModsData[i].arrModOptions.Length = tOption.Idx + 1;
		//	}
		//	m_arrModsData[i].arrModOptions[tOption.Idx] = tO;
		//}
	}
}
function BuildConfigModOptionsBool()
{
	local TConfigModOptionBool tOption;
	local TModOption tO;
	//local int i;

	foreach default.ModOptionBool(tOption)
	{
		tO = BuildConfigVarBool(tOption.VarName, tOption.VarPath != "" ? bool(ConsoleGetSetting(tOption.VarPath)) : class'XComModsProfile'.static.ReadSettingBool(tOption.VarName, tOption.ModName), tOption.bDefault, GetUINameForVar(tOption.ModName $"."$ tOption.VarName), GetDescForVar(tOption.ModName $"."$ tOption.VarName), tOption.eWidgetType, tOption.ReadOnly, tOption.VarPath, tOption.Idx);
		if(tO.eWidgetType == eWidget_Spinner || tO.eWidgetType == eWidget_Combobox)
		{
			if(m_arrVarName.Find(tOption.ModName $"."$ tOption.VarName $".True") != -1)
			{
				tO.arrListLabels[1] = GetUINameForVar(tOption.ModName $"."$ tOption.VarName $".True");
			}
			if(m_arrVarName.Find(tOption.ModName $"."$ tOption.VarName $".False") != -1)
			{
				tO.arrListLabels[0] = GetUINameForVar(tOption.ModName $"."$ tOption.VarName $".False");
			}
		}
		AddModOption(tOption.ModName, tO);
		//if Idx is provided remove the option from the end of list and put at the specified Idx
		//if(tOption.Idx != -1)
		//{
		//	i = FindModDataFor(tOption.ModName);
		//	m_arrModsData[i].arrModOptions.Remove(m_arrModsData[i].arrModOptions.Length - 1, 1);
		//	if(tOption.Idx > m_arrModsData[i].arrModOptions.Length - 1)
		//	{
		//		m_arrModsData[i].arrModOptions.Length = tOption.Idx + 1;
		//	}
		//	m_arrModsData[i].arrModOptions[tOption.Idx] = tO;
		//}
	}
}
function BuildConfigModOptionsPerks()
{
	local TConfigModOptionPerk tOption;
	local TModOption tO;
	local int i, iMod;

	foreach default.ModOptionPerk(tOption)
	{
		AddConfigVarPerk(tOption.ModName, tOption.VarName, tOption.VarPath != "" ? StringToPerkType(ConsoleGetSetting(tOption.VarPath)) : class'XComModsProfile'.static.ReadSettingInt(tOption.VarName, tOption.ModName), tOption.iDefault, GetUINameForVar(tOption.ModName $"."$ tOption.VarName), GetDescForVar(tOption.ModName $"."$ tOption.VarName), tOption.eWidgetType, tOption.ReadOnly, tOption.VarPath, tOption.Idx);
		iMod = -1;
		if(tOption.arrValues.Length > 0)
		{
			iMod = FindModDataFor(tOption.ModName);
			tO = m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1];
			for(i = tO.arrListValues.Length-1; i >= 0; --i)
			{
				if(tOption.arrValues.Find(tO.arrListValues[i]) < 0)
				{
					tO.arrListValues.Remove(i, 1);
					tO.arrListLabels.Remove(i, 1);
				}
				else if(m_arrVarName.Find(tOption.ModName $"."$ tOption.VarName $"."$ tO.arrListValues[i]) != -1)
				{
					tO.arrListLabels[i] = GetUINameForVar(tOption.ModName $"."$ tOption.VarName $"."$ tO.arrListValues[i]);
				}
			}
			m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1] = tO;
		}
		//if Idx is provided remove the option from the end of list and put at the specifed Idx
		//if(tOption.Idx != -1)
		//{
		//	if(iMod == -1)
		//	{
		//		iMod = FindModDataFor(tOption.ModName);
		//	}
		//	tO = m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1];
		//	m_arrModsData[iMod].arrModOptions.Remove(m_arrModsData[iMod].arrModOptions.Length - 1, 1);
		//	if(tOption.Idx > m_arrModsData[iMod].arrModOptions.Length - 1)
		//	{
		//		m_arrModsData[iMod].arrModOptions.Length = tOption.Idx + 1;
		//	}
		//	m_arrModsData[iMod].arrModOptions[tOption.Idx] = tO;
		//}
	}
}
function BuildConfigModOptionsItems()
{
	local TConfigModOptionItem tOption;
	local TModOption tO;
	local int i, iMod;

	foreach default.ModOptionItem(tOption)
	{
		AddConfigVarItem(tOption.ModName, tOption.VarName, tOption.VarPath != "" ? StringToItemType(ConsoleGetSetting(tOption.VarPath)) : class'XComModsProfile'.static.ReadSettingInt(tOption.VarName, tOption.ModName), tOption.iDefault, GetUINameForVar(tOption.ModName $"."$ tOption.VarName), GetDescForVar(tOption.ModName $"."$ tOption.VarName), tOption.eWidgetType, tOption.ReadOnly, tOption.VarPath, tOption.Idx);
		iMod = -1;
		if(tOption.arrValues.Length > 0)
		{
			iMod = FindModDataFor(tOption.ModName);
			tO = m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1];
			for(i = tO.arrListValues.Length-1; i >= 0; --i)
			{
				if(tOption.arrValues.Find(tO.arrListValues[i]) < 0)
				{
					tO.arrListValues.Remove(i, 1);
					tO.arrListLabels.Remove(i, 1);
				}
				else if(m_arrVarName.Find(tOption.ModName $"."$ tOption.VarName $"."$ tO.arrListValues[i]) != -1)
				{
					tO.arrListLabels[i] = GetUINameForVar(tOption.ModName $"."$ tOption.VarName $"."$ tO.arrListValues[i]);
				}
			}
			m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1] = tO;
		}
		//if Idx is provided remove the option from the end of list and put at the specifed Idx
		//if(tOption.Idx != -1)
		//{
		//	if(iMod == -1)
		//	{
		//		iMod = FindModDataFor(tOption.ModName);
		//	}
		//	tO = m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1];
		//	m_arrModsData[iMod].arrModOptions.Remove(m_arrModsData[iMod].arrModOptions.Length - 1, 1);
		//	if(tOption.Idx > m_arrModsData[iMod].arrModOptions.Length - 1)
		//	{
		//		m_arrModsData[iMod].arrModOptions.Length = tOption.Idx + 1;
		//	}
		//	m_arrModsData[iMod].arrModOptions[tOption.Idx] = tO;
		//}
	}
}
function BuildConfigModOptionsTechs()
{
	local TConfigModOptionTech tOption;
	local TModOption tO;
	local int i, iMod;

	foreach default.ModOptionTech(tOption)
	{
		AddConfigVarTech(tOption.ModName, tOption.VarName, tOption.VarPath != "" ? StringToTechType(ConsoleGetSetting(tOption.VarPath)) : class'XComModsProfile'.static.ReadSettingInt(tOption.VarName, tOption.ModName), tOption.iDefault, GetUINameForVar(tOption.ModName $"."$ tOption.VarName), GetDescForVar(tOption.ModName $"."$ tOption.VarName), tOption.eWidgetType, tOption.ReadOnly, tOption.VarPath, tOption.Idx);
		iMod = -1;
		if(tOption.arrValues.Length > 0)
		{
			iMod = FindModDataFor(tOption.ModName);
			tO = m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1];
			for(i = tO.arrListValues.Length-1; i >= 0; --i)
			{
				if(tOption.arrValues.Find(tO.arrListValues[i]) < 0)
				{
					tO.arrListValues.Remove(i, 1);
					tO.arrListLabels.Remove(i, 1);
				}
				else if(m_arrVarName.Find(tOption.ModName $"."$ tOption.VarName $"."$ tO.arrListValues[i]) != -1)
				{
					tO.arrListLabels[i] = GetUINameForVar(tOption.ModName $"."$ tOption.VarName $"."$ tO.arrListValues[i]);
				}
			}
			m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1] = tO;
		}
		//if Idx is provided remove the option from the end of list and put at the specifed Idx
		//if(tOption.Idx != -1)
		//{
		//	if(iMod == -1)
		//	{
		//		iMod = FindModDataFor(tOption.ModName);
		//	}
		//	tO = m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1];
		//	m_arrModsData[iMod].arrModOptions.Remove(m_arrModsData[iMod].arrModOptions.Length - 1, 1);
		//	if(tOption.Idx > m_arrModsData[iMod].arrModOptions.Length - 1)
		//	{
		//		m_arrModsData[iMod].arrModOptions.Length = tOption.Idx + 1;
		//	}
		//	m_arrModsData[iMod].arrModOptions[tOption.Idx] = tO;
		//}
	}
}
function BuildConfigModOptionsFoundryTechs()
{
	local TConfigModOptionFoundryTech tOption;
	local TModOption tO;
	local int i, iMod;

	foreach default.ModOptionFoundryTech(tOption)
	{
		AddConfigVarFoundryTech(tOption.ModName, tOption.VarName, tOption.VarPath != "" ? StringToFoundryTech(ConsoleGetSetting(tOption.VarPath)) : class'XComModsProfile'.static.ReadSettingInt(tOption.VarName, tOption.ModName), tOption.iDefault, GetUINameForVar(tOption.ModName $"."$ tOption.VarName), GetDescForVar(tOption.ModName $"."$ tOption.VarName), tOption.eWidgetType, tOption.ReadOnly, tOption.VarPath, tOption.Idx);
		iMod = -1;
		if(tOption.arrValues.Length > 0)
		{
			iMod = FindModDataFor(tOption.ModName);
			tO = m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1];
			for(i = tO.arrListValues.Length-1; i >= 0; --i)
			{
				if(tOption.arrValues.Find(tO.arrListValues[i]) < 0)
				{
					tO.arrListValues.Remove(i, 1);
					tO.arrListLabels.Remove(i, 1);
				}
				else if(m_arrVarName.Find(tOption.ModName $"."$ tOption.VarName $"."$ tO.arrListValues[i]) != -1)
				{
					tO.arrListLabels[i] = GetUINameForVar(tOption.ModName $"."$ tOption.VarName $"."$ tO.arrListValues[i]);
				}
			}
			m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1] = tO;
		}
		//if Idx is provided remove the option from the end of list and put at the specifed Idx
		//if(tOption.Idx != -1)
		//{
		//	if(iMod == -1)
		//	{
		//		iMod = FindModDataFor(tOption.ModName);
		//	}
		//	tO = m_arrModsData[iMod].arrModOptions[m_arrModsData[iMod].arrModOptions.Length - 1];
		//	m_arrModsData[iMod].arrModOptions.Remove(m_arrModsData[iMod].arrModOptions.Length - 1, 1);
		//	if(tOption.Idx > m_arrModsData[iMod].arrModOptions.Length - 1)
		//	{
		//		m_arrModsData[iMod].arrModOptions.Length = tOption.Idx + 1;
		//	}
		//	m_arrModsData[iMod].arrModOptions[tOption.Idx] = tO;
		//}
	}
}
function int StringToTechType(string strInValue)
{
	local int i, iReturn;

	iReturn = -1;
	for(i=0; i < eTech_MAX; ++i)
	{
		if(GetEnum(enum'ETechType', i) == name(strInValue))
		{
			iReturn = i;
			break;
		}
	}
	return (iReturn != -1 ? iReturn : int(strInValue));
}
function int StringToItemType(string strInValue)
{
	local int i, iReturn;

	iReturn = -1;
	for(i=0; i < eItem_MAX; ++i)
	{
		if(GetEnum(enum'EItemType', i) == name(strInValue))
		{
			iReturn = i;
			break;
		}
	}
	return (iReturn != -1 ? iReturn : int(strInValue));
}
function int StringToPerkType(string strInValue)
{
	local int i, iReturn;

	iReturn = -1;
	for(i=0; i < ePerk_MAX; ++i)
	{
		if(GetEnum(enum'EPerkType', i) == name(strInValue))
		{
			iReturn = i;
			break;
		}
	}
	return (iReturn != -1 ? iReturn : int(strInValue));
}
function int StringToFoundryTech(string strInValue)
{
	local int i, iReturn;

	iReturn = -1;
	for(i=0; i < eFoundry_MAX; ++i)
	{
		if(GetEnum(enum'EFoundryTech', i) == name(strInValue))
		{
			iReturn = i;
			break;
		}
	}
	return (iReturn != -1 ? iReturn : int(strInValue));
}

DefaultProperties
{
}