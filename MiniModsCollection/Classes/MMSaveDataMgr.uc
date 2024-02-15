/**This class is a container of static helper functions to store / extract data saved in string format "?Key=Value".
 * The data container is a XGRecapSaveData actor and its m_aJournalEvents array.
 */
class MMSaveDataMgr extends Object;

static function XGRecapSaveData GetSaveData(optional string strID="MiniModsCollection")
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
DefaultProperties
{
}
