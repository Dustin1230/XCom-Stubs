class GMCharGenerator extends XGCharacterGenerator config(ModGender);

struct TGenderModifier
{
	var int iGender;
	var int PctChance;
	var int Aim;
	var int HP;
	var int Will;
	var int Mob;

	structdefaultproperties
	{
		PctChance=100;
	}
};
var config bool bModEnabled;
var config float WOMEN_RATIO;
var config bool bGenderStatModifiers;
var config array<TGenderModifier> GenderStatMod;
var XGStrategySoldier m_kDummy;

function XGStrategySoldier GetDummy()
{
	if(m_kDummy == none)
	{
		m_kDummy = Spawn(class'XGStrategySoldier');
	}
	return m_kDummy;
}
function EnsureGenderRatio(out EGender eForceGender)
{
	if(bModEnabled && eForceGender == eGender_None && WOMEN_RATIO > 0.0)
	{
		eForceGender = FRand() <= WOMEN_RATIO ? eGender_Female : eGender_Male;
	}
}
function EnsureGenderStatModifiers(XGStrategySoldier kSoldier)
{
	local TGenderModifier tMod;

	if(!bGenderStatModifiers || !bModEnabled)
	{
		return;
	}
	if(kSoldier != none && !kSoldier.IsATank() && InStr(GetScriptTrace(), "AddNewSoldier") != -1)
	{
		foreach GenderStatMod(tMod)
		{
			if(kSoldier.m_kSoldier.kAppearance.iGender != tMod.iGender)
			{
				continue;
			}
			else if(tMod.PctChance >= 100 || Rand(100) < tMod.PctChance)
			{
				`log(kSoldier.GetName(eNameType_Full),,GetFuncName());
				kSoldier.m_kChar.aStats[eStat_Offense] += tMod.Aim;
				kSoldier.m_kChar.aStats[eStat_HP] += tMod.HP;
				kSoldier.m_kChar.aStats[eStat_Will] += tMod.Will;
				kSoldier.m_kChar.aStats[eStat_Mobility] += tMod.Mob;
				kSoldier.m_kChar.aStats[eStat_HP] = Max(3, kSoldier.m_kChar.aStats[eStat_HP]);
				kSoldier.m_kChar.aStats[eStat_Offense] = Min(75, kSoldier.m_kChar.aStats[eStat_Offense]);
				kSoldier.m_kChar.aStats[eStat_Mobility] = Min(17, kSoldier.m_kChar.aStats[eStat_Mobility]);
			}
		}
	}
}
function XGStrategySoldier GetLastRecruit()
{
	local XGFacility_Barracks kB;
	local XGStrategySoldier kS;

	if(XComHeadquartersGame(WorldInfo.Game) != none)
	{
		kB = XComHeadquartersGame(WorldInfo.Game).GetGameCore().m_kHQ.m_kBarracks;
		foreach DynamicActors(class'XGStrategySoldier', kS)
		{
			if(kS.m_kSoldier.iID == kB.m_iSoldierCounter-1)
			{
				return kS;
			}
		}
	}
	return none;
}

function TSoldier CreateTSoldier(optional EGender eForceGender, optional int iCountry=-1, optional int iRace=-1, optional ESoldierClass eClass)
{
	local TSoldier tS;
	local XGFacility_Barracks kB;

	EnsureGenderRatio(eForceGender);
	tS = class'GMMutator'.static.GetSelf().m_kOrigCharGen.CreateTSoldier(eForceGender, iCountry, iRace, eClass);

	//the trick is to temporarily put in the barracks or morgue a dummy soldier with the very same name as just created tSoldier
	//this will make NameCheck fail and call GenerateName (within this generator) - thus trigerring EnsureGenderStatModifiers

	GetDummy().m_kSoldier.strFirstName = tS.strFirstName;
	GetDummy().m_kSoldier.strLastName = tS.strLastName;
	kB = GetDummy().BARRACKS();
	if(kB.m_arrFallen.Find(GetDummy()) < 0)
	{
		kB.m_arrFallen.AddItem(GetDummy());
	}
	return tS;
}
function GenerateName(int iGender, int iCountry, out string strFirst, out string strLast, optional int iRace=-1)
{
	EnsureGenderStatModifiers(GetLastRecruit());
	class'GMMutator'.static.GetSelf().m_kOrigCharGen.GenerateName(iGender, iCountry, strFirst, strLast, iRace);
}
function GenerateNickname(int iGen, ESoldierClass eClass, out string strNickName)
{
	class'GMMutator'.static.GetSelf().m_kOrigCharGen.GenerateNickname(iGen, eClass, strNickName);
}
function int PickOriginCountry(optional int iContinent)
{
	return class'GMMutator'.static.GetSelf().m_kOrigCharGen.PickOriginCountry(iContinent);
}
function XGCharacter_Soldier CreateBaseSoldier(optional ELoadoutTypes eLoadout, optional EGender eForceGender, optional ESoldierClass eClass)
{
	EnsureGenderRatio(eForceGender);
	return class'GMMutator'.static.GetSelf().m_kOrigCharGen.CreateBaseSoldier(eLoadout, eForceGender, eClass);
}
static function ECharacterLanguage GetLanguageByString(optional string strLanguage)
{
	return class'GMMutator'.static.GetSelf().m_kOrigCharGen.GetLanguageByString(strLanguage);
}
function ECharacterLanguage GetLanguageByCountry(ECountry Country)
{
	return class'GMMutator'.static.GetSelf().m_kOrigCharGen.GetLanguageByCountry(Country);
}
function int GetNextMaleVoice(ECharacterLanguage eLang, bool IsMec)
{
	return class'GMMutator'.static.GetSelf().m_kOrigCharGen.GetNextMaleVoice(eLang, IsMec);
}
function int GetNextFemaleVoice(ECharacterLanguage eLang, bool IsMec)
{
	return class'GMMutator'.static.GetSelf().m_kOrigCharGen.GetNextFemaleVoice(eLang, IsMec);
}
function int ChooseHairColor(const out TAppearance kAppearance, int iNumBaseOptions)
{
	return class'GMMutator'.static.GetSelf().m_kOrigCharGen.ChooseHairColor(kAppearance, iNumBaseOptions);
}
function int ChooseFacialHair(const out TAppearance kAppearance, int iOrigin, int iNumBaseOptions)
{
	return class'GMMutator'.static.GetSelf().m_kOrigCharGen.ChooseFacialHair(kAppearance, iOrigin, iNumBaseOptions);
}
function int GetRandomRaceByCountry(int iCountry)
{
	return class'GMMutator'.static.GetSelf().m_kOrigCharGen.GetRandomRaceByCountry(iCountry);
}
DefaultProperties
{
}
