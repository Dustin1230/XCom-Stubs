/** This class is actually never instantiated. It serves as a helper to store/manipulate/get data from ModsProfile ini.
   All the functions here are 'static' for easy access frome anywhere.*/
class XComModsProfile extends Object
	config(ModsProfile);

enum EValueType
{
	eVType_Undefined,
	eVType_Int,
	eVType_Float,
	eVType_String,
	eVType_Bool
};
/** A storage unit for most basic profile/mod setting.*/
struct TModSetting
{
	/** Name identifier of the mod holding the variable. It is advised to use the mod's class name but suit yourself. Avoid language-specific characters (this causes issues).*/
	var string ModName;
	/** Name for the property/variable/setting. It should be unique within the mod. Does not need to match existing variable. Spaces allowed.*/
	var string PropertyName;
	/** This must match a Class.Variable path to an existing property. It will be used by "set" / "get" console commands*/
	var string PropertyPath;
	/** A string representaion of the value e.g. "0.20" for float or "3" for int, or "true" / "false".*/
	var string Value;
	/** Generic type of the value: eVType_Int, or eVType_Float, or eVType_String, or eVType_Bool. */
	var EValueType ValueType;
	
	structdefaultproperties
	{
		ValueType=eVType_Undefined
	}
};
/** ModSettings array holds records of data. Each record holds the following information: ModName, PropertyName, Value, ValueType*/
var config array<TModSetting> ModSettings;

/** Builds and adds entry to ModSettings array. The array is saved in XComModsProfile.ini. 
 *  Settings with the same ModName are grouped in one block inside the .ini. 
 *  
 *  @param strModName Provide unique name identifier. It is advised to use the mod's class name but it's not compulsory. You can use spaces but avoid language-special characters (this causes issues).
 *  @param strProperty Provide name of the property/variable. It should be unique to your mod cause ReadSetting returns the first matching entry. In case of duplication PropertyName to be saved will be expanded with ModName as a prefix.
 *  @param strValue Provide a string representaion of the value to be saved e.g. "0.20" for float or "3" for int, or "true" / "false" for bool.
 *  @param eType Provide generic type of the value: eVType_Int, or eVType_Float, or eVType_String, or eVType_Bool. When strValue is "true" or "false" the default type is eVType_Bool (unless specified differently).
 *  @param strVarPath Provide an address to an existing variable, for instance "XGTacticalGameCore.SW_MARATHON".
 */
static function SaveSetting(string strModName, string strProperty, string strValue, optional EValueType eType=(strValue ~= "true" || strValue ~= "false") ? eVType_Bool : eVType_Undefined, optional string strVarPath="")
{
	local TModSetting tSetting, tNewEntry;
	local int Idx;
	local bool bMatchFound;

	if(strModName == "" || strProperty == "")
	{
		return;
	}
	tNewEntry.ModName       = strModName;
	tNewEntry.PropertyName  = strProperty;
	tNewEntry.ValueType     = eType;
	tNewEntry.PropertyPath  = strVarPath;
	tNewEntry.Value         = strValue;

	//search the line of the property and replace if found
	foreach default.ModSettings(tSetting, Idx)
	{
		if(tNewEntry.ModName ~= tSetting.ModName && (tNewEntry.PropertyName ~= tSetting.PropertyName || (tNewEntry.ModName $"."$ tNewEntry.PropertyName) ~= tSetting.PropertyName))
		{
			if(tSetting.PropertyName ~= (tNewEntry.ModName $"."$ tNewEntry.PropertyName))
			{
				tNewEntry.PropertyName = tNewEntry.ModName $"."$ tNewEntry.PropertyName;
			}
			if(tNewEntry.ValueType == eVType_Undefined)
			{
				tNewEntry.ValueType = tSetting.ValueType;
			}
			default.ModSettings[Idx] = tNewEntry;
			StaticSaveConfig();
			return;
		}
		else if(tNewEntry.PropertyName ~= tSetting.PropertyName)
		{
			bMatchFound=true; //found setting with matching PropertyName but for a different mod
		}
	}
	if(bMatchFound)
	{
		tNewEntry.PropertyName = strModName $ "." $ strProperty; //add prefix to PropertyName to make it unique.
		bMatchFound = false;
	}
	//add the line, preferably next to other lines with the same ModName
	foreach default.ModSettings(tSetting, Idx)
	{
		if(CAPS(tNewEntry.ModName) == CAPS(tSetting.ModName))
		{
			bMatchFound = true;
			break;
		}
	}
	if(!bMatchFound)
	{
		default.ModSettings.AddItem(tNewEntry);
	}
	else
	{
		default.ModSettings.InsertItem(Idx, tNewEntry);
	}
	StaticSaveConfig();
}
/** Finds and returns value of a property stored in provided array of settings. If no array is provided (bad for performance) the whole ModSettings from XComModsProfile.ini is used. The first found entry matching will be returned. 
 *  Returned value is a string so you must type-cast it to the correct type - or use a specialized version e.g. ReadSettingInt
 *  @param strProperty Name of the variable to retrieve. The first entry matching PropertyName will be returned if you do not provide ModName.
 *  @param strModName Provide name of the mod that holds the variable - optional, if PropertyName is unique no need for ModName.
 *  @param iIndex This out param will receive an idx in ModSettings array under which the setting has been found. Useful e.g. if you want to make a check for the settings 'ValueType'.
 */
static function string ReadSetting(string strProperty, optional string strModName="", optional array<TModSetting> arrModSettings=default.ModSettings, optional out int iIndex)
{
	local string strRetValue;
	local int idx;

	if(strModName == "")
	{
		idx = arrModSettings.Find('PropertyName', strProperty);
	}
	else
	{
		idx = arrModSettings.Find('PropertyName', strModName $"."$ strProperty);
		if(idx < 0)
		{
			idx = arrModSettings.Find('PropertyName', strProperty);
		}
	}
	if(idx != -1 && (strModName == "" || strModName ~= arrModSettings[idx].ModName) )
	{
		strRetValue = arrModSettings[idx].Value;
	}
	iIndex = idx;
	return strRetValue;
}
static function bool HasSetting(string strProperty, optional string strModName="", optional out string strValue, optional array<TModSetting> arrSettings=default.ModSettings, optional out int iIndex)
{
	strValue = ReadSetting(strProperty, strModName, arrSettings, iIndex);
	return (strValue != "" ? true : false);
}
/** Reads setting's value and converts it to bool type.*/
static function bool ReadSettingBool(string strProperty, optional string strModName="", optional array<TModSetting> arrSettings=default.ModSettings, optional out int iIndex)
{
	return bool(ReadSetting(strProperty, strModName, arrSettings, iIndex));
}
/** Reads setting's value and converts it to int type.*/
static function int ReadSettingInt(string strProperty, optional string strModName="", optional array<TModSetting> arrSettings=default.ModSettings, optional out int iIndex)
{
	return int(ReadSetting(strProperty, strModName, arrSettings, iIndex));
}
/** Reads setting's value and converts it to float type.*/
static function float ReadSettingFloat(string strProperty, optional string strModName="", optional array<TModSetting> arrSettings=default.ModSettings, optional out int iIndex)
{
	return float(ReadSetting(strProperty, strModName, arrSettings, iIndex));
}
/** Adds entry to ModSettings array. The array is saved in XComModsProfile.ini. You could also add the entry manually in DefaultModsProfile.ini.
 *  @param tNewSetting The struct holds 3 strings (ModName, PropertyName, Value) and int/enum code for property type (eType): EVType_Int, or EVType_Float, or EVType_String, or EVType_Bool.
 */
static function SaveModSetting(TModSetting tNewSetting)
{
	local TModSetting tSetting;
	local int Idx;
	local bool bMatchFound;

	//search the line of the property and replace
	foreach default.ModSettings(tSetting, Idx)
	{
		if(tNewSetting.ModName ~= tSetting.ModName && tNewSetting.PropertyName ~= tSetting.PropertyName)
		{
			default.ModSettings[Idx] = tNewSetting;
			StaticSaveConfig();
			return;
		}
	}
	//otherwise add the line, preferably next to other lines with the same ModName
	foreach default.ModSettings(tSetting, Idx)
	{
		if(tNewSetting.ModName ~= tSetting.ModName)
		{
			bMatchFound = true;
			break;
		}
	}
	if(!bMatchFound)
	{
		default.ModSettings.AddItem(tNewSetting);
	}
	else
	{
		default.ModSettings.InsertItem(Idx, tNewSetting);
	}
	StaticSaveConfig();
}

/** Returns array of ModSettings with a specified ModName. Useful to get all settings for a mod.
 *  @param strModName Name of mod to get settings for.
 */
static function array<TModSetting> ReadModSettings(string strModName)
{
	local TModSetting tSetting;
	local array<TModSetting> arrSettings;

	foreach default.ModSettings(tSetting)
	{
		if(tSetting.ModName ~= strModName)
		{
			arrSettings.AddItem(tSetting);
		}
	}
	return arrSettings;
}

/** Fills provided array with ModSettings for a specified ModName. 
 *  Similar to ReadModSettings but using <out> param allows building array of settings for multiple mods (cause the param is not being cleared).
 *  @param strModName Name of mod to get settings for.
 *  @param arrSettings Note: provided array is not cleared - the function only adds to the end of it.
 */
static function GetModSettings(string strModName, out array<TModSetting> arrSettings)
{
	local TModSetting tSetting;

	foreach default.ModSettings(tSetting)
	{
		if(tSetting.ModName ~= strModName)
		{
			arrSettings.AddItem(tSetting);
		}
	}
}
/** Helper to list all mods for which settings are present in XComModsProfile.ini. Might be useful for large .ini with multiple mods and settings.
 */
static function array<string> GetAllSavedModNames()
{
	local array<string> arrModNames;
	local TModSetting tSetting;

	foreach default.ModSettings(tSetting)
	{
		if(arrModNames.Find(tSetting.ModName) == -1)
		{
			arrModNames.AddItem(tSetting.ModName);
		}
	}
	return arrModNames;
}
/** Removes all lines with ModName matching strModName from ModSettings array except the line for bModEnabled (unless this one is requested with param). 
 *  Recommended when all ModSettings for the mod rely on PropertyPath and leaving them in XComModsProfile is garbage creation.
 *  @param strModName ModName for which the lines will be removed. The check is not case sensitive.
 *  @param bClearModEnabledProperty TRUE - makes also bModEnabled line removed (the mod will be always "OFF" when entering Mods Menu).
 */
static function ClearAllSettingsForMod(string strModName, optional bool bClearModEnabledProperty)
{
	local int i;

	for(i = default.ModSettings.Length - 1; i >=0; --i)
	{
		if(default.ModSettings[i].ModName ~= strModName && default.ModSettings[i].PropertyPath != "" && (bClearModEnabledProperty || default.ModSettings[i].PropertyName != "bModEnabled"))
		{
			default.ModSettings.Remove(i, 1);
		}
	}
}
/** Removes from ModSettings all lines that match specified ModName and PropertyName
 *  @param strModName The comparison check on this string is case insensitive.
 *  @param strPropertyName The comparison check on this string is case insensitive.
 */
static function ClearPropertySetting(string strModName, string strPropertyName)
{
	local int i;

	for(i = default.ModSettings.Length - 1; i >=0; --i)
	{
		if(default.ModSettings[i].ModName ~= strModName && (default.ModSettings[i].PropertyName ~= strPropertyName || default.ModSettings[i].PropertyName ~= (strModName $"."$ strPropertyName)))
		{
			default.ModSettings.Remove(i, 1);
		}
	}
}
/** Same as XComOnlineProfileSettingsDataBlob.FindProfileStatIndex but with lower risk of runaway loop.*/
static function int FindProfileStatIndex(string strStat, optional out int out_crc)
{
	out_crc = XComEngine(Class'Engine'.static.GetEngine()).GetStringCRC(strStat);
	return XComOnlineProfileSettings(Class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_aProfileStats.Find('iCrc', out_crc);
}
/** Saves iValue under strStatName in user's profile data (not in the XComModsProfile.ini)*/
static function SetProfileSetting(string strStatName, int iValue)
{
    local int I;
    local ProfileStatValue kStat;
    local int crc;

    I = FindProfileStatIndex(strStatName, crc);
    if(I != -1)
    {
        XComOnlineProfileSettings(Class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_aProfileStats[I].iValue = iValue;        
    }
    else
    {
        kStat.iCrc = crc;
        kStat.iValue = iValue;
        XComOnlineProfileSettings(Class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_aProfileStats.AddItem(kStat);
    }
}
/** Retrieves iValue saved under strStatName in user's profile data. Should only be used if there is certainity that strStatName had been saved.
 Otherwise the returned 0 might not be the actual value saved but a default int.*/
static function int GetProfileSetting(string strStatName)
{
    local int I;

    I = FindProfileStatIndex(strStatName);
    if(I != -1)
    {
        return XComOnlineProfileSettings(Class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_aProfileStats[I].iValue;
    }
    return 0;
}
/** Checks if there is any value saved under strStatName in the user's profile data. Optionally returns the value as <out> iValue. 
 Similar to GetProfileSetting, but allows for verification if iValue is an actual value saved.*/
static function bool HasProfileSetting(string strStatName, optional out int iValue)
{
	local int I;

	I = FindProfileStatIndex(strStatName);
	if(I != -1)
	{
		iValue = XComOnlineProfileSettings(Class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_aProfileStats[I].iValue;
	}
	return I != -1;
}
/** Clears (removes) a setting of strStatName from profile settings.*/
static function ClearProfileSetting(string strStatName)
{
	local int I;

	I = FindProfileStatIndex(strStatName);
	if(I != -1)
	{
		XComOnlineProfileSettings(Class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_aProfileStats.Remove(I, 1);
	}
}
DefaultProperties
{
}