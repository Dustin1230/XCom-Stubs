/**This class is a container of static helper functions to store / extract data saved in string format "?Key=Value".
 * The data container is an instance of XGRecapSaveData class and specifically its m_aJournalEvents array.
 */
class XGSaveHelper extends Object;

static function XGRecapSaveData GetSaveData(string strID)
{
	local Actor kA;
	local XGRecapSaveData kData;
	local bool bFound;

	kA = class'Engine'.static.GetCurrentWorldInfo();

	foreach kA.DynamicActors(class'XGRecapSaveData', kData)
	{
		if(kData.m_aJournalEvents.Find(strID) != -1)
		{
			bFound = true;
			break;
		}
	}
	if(!bFound)
	{
		kData = kA.Spawn(class'XGRecapSaveData');
		kData.m_aJournalEvents.AddItem(strID);
	}
	return kData;
}
static function SaveValueString(XGRecapSaveData kContainer, coerce string sObject, coerce string sKey, coerce string sValue)
{
	local string strTemp, strCurrVal;
	local bool bFound;
	local int i;

	for(i=0; i < kContainer.m_aJournalEvents.Length; ++i)
	{
		strTemp = kContainer.m_aJournalEvents[i];
		if(class'GameInfo'.static.ParseOption(strTemp, "Object") ~= sObject)
		{
			bFound = true;
			strCurrVal = class'GameInfo'.static.ParseOption(strTemp, sKey);
			if(strCurrVal != "")
			{
				kContainer.m_aJournalEvents[i] = Repl(strTemp, "?" $ sKey $ "=" $ strCurrVal, "?" $ sKey $ "=" $ sValue, false);
			}
			else
			{
				kContainer.m_aJournalEvents[i] = strTemp $ "?" $ sKey $ "=" $ sValue;
			}
			break;
		}
	}
	if(!bFound)
	{
		kContainer.m_aJournalEvents.AddItem("?Object=" $ sObject $ "?" $ sKey $ "=" $ sValue);
	}
}
static function string GetSavedValueString(XGRecapSaveData kContainer, coerce string sObject, coerce string sKey)
{
	local string strTemp, strVal;

	foreach kContainer.m_aJournalEvents(strTemp)
	{
		if(class'GameInfo'.static.ParseOption(strTemp, "Object") ~= sObject)
		{
			strVal = class'GameInfo'.static.ParseOption(strTemp, sKey);
			break;
		}
	}
	return strVal;
}
static function ClearSaveDataForObject(XGRecapSaveData kContainer, coerce string sObject)
{
	local int i;

	for(i=kContainer.m_aJournalEvents.Length-1; i >=0; --i)
	{
		if(InStr(kContainer.m_aJournalEvents[i], "?Object=" $ sObject,,true) != -1)
		{
			kContainer.m_aJournalEvents.Remove(i, 1);
		}
	}
}
static function ClearAllSaveData(XGRecapSaveData kContainer)
{
	kContainer.m_aJournalEvents.Length = 1;
}
static function XGSH_QueueHelper GetQueueProcessor()
{
	local XGSH_QueueHelper kProcessor;
	local Actor kA;
	local bool bFound;

	kA = class'Engine'.static.GetCurrentWorldInfo();

	foreach kA.DynamicActors(class'XGSH_QueueHelper', kProcessor)
	{
		bFound = true;
		break;
	}
	if(!bFound)
	{
		kProcessor = kA.Spawn(class'XGSH_QueueHelper');
	}
	return kProcessor;
}
static function QueueSaveValueString(XGRecapSaveData kContainer, coerce string sObject, coerce string sKey, coerce string sValue)
{
	GetQueueProcessor().QueueSaveValue(kContainer, sObject, sKey, sValue);
}
static function SetProfileStat(string strStatName, int iValue)
{
    local int I;
    local ProfileStatValue kStat;
    local int crc;

    I = XComOnlineProfileSettings(Class'Engine'.static.GetEngine().GetProfileSettings()).Data.FindProfileStatIndex(strStatName, crc);
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
static function int GetProfileStatValue(string strStatName)
{
    local int I;

    I = XComOnlineProfileSettings(Class'Engine'.static.GetEngine().GetProfileSettings()).Data.FindProfileStatIndex(strStatName);
    if(I != -1)
    {
        return XComOnlineProfileSettings(Class'Engine'.static.GetEngine().GetProfileSettings()).Data.m_aProfileStats[I].iValue;
    }
    return 0;
}

DefaultProperties
{
}