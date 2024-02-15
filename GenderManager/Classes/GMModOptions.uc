class GMModOptions extends UIModOptionsContainer config(ModGender);

/** Extracts friendly name to be displayed for a given internal VarName*/
function string GetUINameForVar(string strVarName)
{
	local int iFound;
	local string strFoundName;

	iFound = GetIndexFor(strVarName);
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

	iFound = GetIndexFor(strVarName);
	if(iFound != -1 && m_arrVarDescription[iFound] != "")
	{
		return m_arrVarDescription[iFound];
	}
	else
	{
		return class'UIModManager'.default.m_strNoDescription;
	}
}
function int GetIndexFor(string strVarName)
{
	local int iFound;

	iFound = m_arrVarName.Find(strVarName);
	if(iFound < 0)
	{
		if(InStr(strVarName, "Chance", true, true) != -1)
		{
			iFound = m_arrVarName.Find("GenderManager.StatMod.Chance");
		}
		else if(InStr(strVarName, "Aim", true, true) != -1)
		{
			iFound = m_arrVarName.Find("GenderManager.StatMod.Aim");
		}
		else if(InStr(strVarName, "HP", true, true) != -1)
		{
			iFound = m_arrVarName.Find("GenderManager.StatMod.HP");
		}
		else if(InStr(strVarName, "Will", true, true) != -1)
		{
			iFound = m_arrVarName.Find("GenderManager.StatMod.Will");
		}
		else if(InStr(strVarName, "Mob", true, true) != -1)
		{
			iFound = m_arrVarName.Find("GenderManager.StatMod.Mob");
		}
		else if(InStr(strVarName, "FStatMod", true) != -1)
		{
			iFound = m_arrVarName.Find("GenderManager.FStatMod");
		}
		else if(InStr(strVarName, "MStatMod", true) != -1)
		{
			iFound = m_arrVarName.Find("GenderManager.MStatMod");
		}
	}
	return iFound;
}
DefaultProperties
{
	m_strMasterClass="GenderManager.GMMutator"
}
