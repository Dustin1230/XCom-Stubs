/**This class serves as a collection of static helpers for Squadron Unleashed*/
class SU_Utils extends Object;

//-------------------------------------------------
//HUD's Helpbar helpers
//-------------------------------------------------

static function AS_AdjustCenterContainerY()
{
	AS_GetContainer("center").SetFloat("_y", AS_GetContainer("left").GetFloat("_y"));
}
static function float AS_GetCenterContainerTotalWidth()
{
	return PRES().GetStrategyHUD().m_kHelpBar.manager.ActionScriptFloat(PRES().m_kUIMissionControl.m_kHelpBar.GetMCPath() $ ".centerContainer.getTotalWidth");
}
static function GfxObject AS_GetContainer(string strPosition)
{
	return PRES().GetStrategyHUD().m_kHelpBar.manager.GetVariableObject(PRES().m_kUIMissionControl.m_kHelpBar.GetMCPath() $ "." $ Locs(strPosition) $ "Container");
}
static function GfxObject AS_GetCenterContainerItem(int iButton)
{
	return PRES().GetStrategyHUD().m_kHelpBar.manager.ActionScriptObject(PRES().m_kUIMissionControl.m_kHelpBar.GetMCPath() $ ".centerContainer.getItemAt");
}
static function GfxObject AS_GetLeftContainerItem(int iButton)
{
	return PRES().GetStrategyHUD().m_kHelpBar.manager.ActionScriptObject(PRES().m_kUIMissionControl.m_kHelpBar.GetMCPath() $ ".leftContainer.getItemAt");
}
//-------------------------------------------------
//GENERAL helpers
//-------------------------------------------------

static function PlayerController PC()
{
	return class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController();
}
static function XComHQPresentationLayer PRES()
{
	return XComHQPresentationLayer(XComHeadquartersController(PC()).m_Pres);
}
static function XGStrategy GetGameCore()
{
    return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore();
}
static function XGGeoscape GEOSCAPE()
{
    return GetGameCore().GetGeoscape();  
}
static function XGFacility_Hangar HANGAR()
{
    return GetGameCore().GetHQ().m_kHangar;  
}
static function XGItemTree ITEMTREE()
{
	return GetGameCore().ITEMTREE();
}
static function XGStrategyAI AI()
{
	return GetGameCore().GetAI();
}
static function PlayBadSound()
{
	PC().PlaySound(SoundCue(DynamicLoadObject("SoundUI.NegativeSelection2Cue", class'SoundCue', true)));
}
static function PlayCancelSound()
{
	PC().PlaySound(SoundCue(DynamicLoadObject("SoundUI.MenuCancelCue", class'SoundCue', true)));
}
static function PlaySelectSound()
{
	PC().PlaySound(SoundCue(DynamicLoadObject("SoundUI.MenuSelectCue", class'SoundCue', true)));
}
static function PlayMenuScrollSound()
{
	PC().PlaySound(SoundCue(DynamicLoadObject("SoundUI.MenuScrollCue", class'SoundCue', true)));
}
/**Converts time in hours into X days if >iDaysThreshold or into Y hours otherwise*/
static function string GetHoursOrDaysString(int iHours, optional int iDaysThreshold=48)
{
	local int iCount;
	local string strSuffix;

	if(iHours <= iDaysThreshold)
	{
		iCount = iHours;
		strSuffix = iCount > 1 ? class'UIUtilities'.default.m_strHours : class'UIUtilities'.default.m_strHour;
	}
	else
	{
		iCount = FCeil(float(iHours)/24.0);
		strSuffix = iCount > 1 ? class'UIUtilities'.default.m_strDays: class'UIUtilities'.default.m_strDay;
	}
	return iCount @ strSuffix;
}
/** Converts time in hours into localized format "XX d YY h" e.g. 316 hours into 13d 4h*/
static function string TimeToString(int iTimeInHours)
{
	local int iDays, iHours;
	local XGParamTag kTag;

	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
	iDays = iTimeInHours / 24;
	iHours = iTimeInHours - iDays * 24;
	kTag.IntValue0 = iDays;
	kTag.StrValue0 = class'XComLocalizer'.static.ExpandString(class'XGFacility_Engineering'.default.m_strETADay);
	kTag.IntValue0 = iHours;
	kTag.StrValue1 = class'XComLocalizer'.static.ExpandString(class'XGFacility_Engineering'.default.m_strETAHour);
	kTag.StrValue2 = kTag.StrValue0 @ kTag.StrValue1;

	return kTag.StrValue2;
}
//-------------------------------------------------
//SAVE DATA helpers
//-------------------------------------------------
static function SaveValue(coerce string sObject, coerce string sKey, coerce string sValue)
{
	class'XGSaveHelper'.static.SaveValueString(GetSquadronMod().m_kSaveData, sObject, sKey, sValue);
}
static function SaveBool(coerce string sObject, coerce string sKey, bool bValue)
{
	SaveValue(sObject, sKey, bValue ? "TRUE" : "FALSE");	
}
static function string GetSavedValue(coerce string sObject, coerce string sKey)
{
	return class'XGSaveHelper'.static.GetSavedValueString(GetSquadronMod().m_kSaveData, sObject, sKey);
}
static function int GetSavedInt(coerce string sObject, coerce string sKey)
{
	return int(GetSavedValue(sObject, sKey));
}
static function float GetSavedFloat(coerce string sObject, coerce string sKey)
{
	return float(GetSavedValue(sObject, sKey));
}
static function bool GetSavedBool(coerce string sObject, coerce string sKey)
{
	return GetSavedValue(sObject, sKey) ~= "TRUE" ? true : false;
}
//-------------------------------------------------
//SQUADRON SPECIFIC helpers
//-------------------------------------------------
static function SquadronUnleashed GetSquadronMod()
{
	local XComMutator kM;

	kM = XComMutator(class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator);
	while(kM.NextMutator != none)
	{
		kM = XComMutator(kM.NextMutator);
		if(kM.IsA('SquadronUnleashed'))
			break;
	}
	return SquadronUnleashed(kM);
}
static function SU_PilotRankMgr GetRankMgr()
{
	return GetSquadronMod().m_kRankMgr;
}
static function SU_HelpManager GetHelpMgr()
{
	return GetSquadronMod().m_kHelpMgr;
}
static function ResetShipStances()
{
	local XGShip_Interceptor kJet;

	foreach class'SU_Utils'.static.HANGAR().m_arrInts(kJet)
		kJet.m_kTShip.iRange = 0;
}

static function SetStance(XGShip kShip, int iStance)
{
	kShip.m_kTShip.iRange = iStance;
	if(kShip.IsA('XGShip_UFO'))
	{
		XGShip_UFO(kShip).m_iStatus = 1;//flag for "UFO has the stance set"
	}
}
static function DetermineUFOStance(XGShip_UFO kUFO)
{
	//local TObjective kObjective;

	if(kUFO.m_iStatus == 0)
	{
		switch(class'SquadronUnleashed'.default.eUFOStanceAIsetting)
		{
		case 0:
			SetStance(kUFO, class'SquadronUnleashed'.default.eFixedUFOStance);
			break;
		case 1:
			SetStance(kUFO, Rand(3));
			break;
		default:
		//kObjective = kUFO.m_kObjective.m_kTObjective;
		}
	}
}
static function string StanceToString(XGShip kShip, optional int iStance=GetStance(kShip))
{
	local string strStance;

	switch(iStance)
	{
	case 1:
		strStance = class'SquadronUnleashed'.default.m_strStanceAGG;
		break;
	case 2:
		strStance = class'SquadronUnleashed'.default.m_strStanceDEF;
		break;
	default:
		strStance = class'SquadronUnleashed'.default.m_strStanceBAL;
	}
	return strStance;
}
/** @param iWeapon EShipWeapon weapon type (0-10)*/
static function bool IsShortDistanceWeapon(int iWeapon)
{
	return class'SquadronUnleashed'.default.ShipWeapons[class'SquadronUnleashed'.default.ShipWeapons.Find('iWeaponType', iWeapon)].bClose;
}
static function int GetStance(XGShip kShip)
{
	return kShip.m_kTShip.iRange;
}
static function int GetAggroForShip(XGShip_Interceptor kShip, optional XGShip_UFO kUFO)
{
	local int iAggro, iWeaponIndex, iWeaponLvl, iToHit;
	local array<TShipWeapon> akShipWeapons;
	
	class'SquadronUnleashed'.default.bVerboseLog = false;
	if(kUFO != none)
	{
		iToHit = GetHitChance(kUFO, kShip,,,true);
		if(GetStance(kShip) == 1)
		{
			iToHit += Max(0, float(class'SquadronUnleashed'.default.AGG_JET_FORCE_HIT_CHANCE) / 100.0 * (100 - iToHit));
		}
		else if(GetStance(kShip) == 2)
		{
			iToHit *= (1.0 - (float(class'SquadronUnleashed'.default.DEF_JET_DODGE_CHANCE) / 100.0));
		}
		iAggro = iToHit;
		if(kUFO.m_kTShip.arrWeapons.Length > 1)
		{
			iAggro = Max(iAggro, GetHitChance(kUFO, kShip, 1,,true));
		}
	}
	akShipWeapons = kShip.GetWeapons();
	if(akShipWeapons.Length < 2)
	{
		//vulcan must have been skipped, so...
		akShipWeapons.AddItem(GetGameCore().SHIPWEAPON(0));
	}
	for(iWeaponIndex = 0; iWeaponIndex < akShipWeapons.Length; ++ iWeaponIndex)
    {
		if(kShip.m_afWeaponCooldown[iWeaponIndex] > 100.0 || GetAmmo(kShip, iWeaponIndex) == 0)
		{	
			continue;
		}
    	iWeaponLvl = akShipWeapons[iWeaponIndex].eType;
		switch(iWeaponLvl)
		{
		case 1:
			iAggro += class'SquadronUnleashed'.default.AGGRO_FOR_WEAPON[3];
			break;
		case 2:
			iAggro += class'SquadronUnleashed'.default.AGGRO_FOR_WEAPON[1];
			break;
		case 3:
			iAggro += class'SquadronUnleashed'.default.AGGRO_FOR_WEAPON[2];
			break;
		default:
			iAggro += class'SquadronUnleashed'.default.AGGRO_FOR_WEAPON[iWeaponLvl];
		}
    }
	switch(GetStance(kShip))
	{
		case 0:
			iAggro += class'SquadronUnleashed'.default.AGGRO_FOR_BAL;
			break;
		case 1:
			iAggro += class'SquadronUnleashed'.default.AGGRO_FOR_AGG;
			break;
		case 2:
			iAggro += class'SquadronUnleashed'.default.AGGRO_FOR_DEF;
			break;
		default:
			iAggro += class'SquadronUnleashed'.default.AGGRO_FOR_BAL;
	}
	if(kShip.IsFirestorm())
	{
		iAggro += class'SquadronUnleashed'.default.AGGRO_FOR_FIRESTORM;
	}
	class'SquadronUnleashed'.default.bVerboseLog = true;
	return iAggro;
}
static function int GetHitChance(XGShip kShip, optional XGShip kTarget, optional int iWeaponIndex=0, optional bool bSkipDamagedPenalty, optional bool bForCloseDistance)
{
	local array<TShipWeapon> akShipWeapons;
	local TShipWeapon kWeapon;
	local SU_Pilot kPilot;
	local int iToHit, iMaxToHit;

	`Log(GetFuncName(), class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	akShipWeapons = kShip.GetWeapons();
	if(akShipWeapons.Length < 2)
	{
		//vulcan must have been skipped, so...
		akShipWeapons.AddItem(GetGameCore().SHIPWEAPON(0));
	}
	kWeapon = akShipWeapons[iWeaponIndex];
	iToHit = kWeapon.iToHit;
	iMaxToHit = class'SquadronUnleashed'.default.BAL_MAX_HIT_CHANCE > 0 ? class'SquadronUnleashed'.default.BAL_MAX_HIT_CHANCE : 95;
	if(kShip.IsHumanShip())
	{
		kPilot = GetPilot(XGShip_Interceptor(kShip));
		if(kPilot != none)
		{
			iToHit += Clamp(kPilot.m_iKills * class'SquadronUnleashed'.default.AIM_BONUS_PER_KILL, 0, class'SquadronUnleashed'.default.MAX_AIM_BONUS_FOR_KILLS);
			iToHit += GetRankAimBonus(kPilot.GetRank(), kPilot.GetCareerType());
		}
		if(SU_XGInterception(XGShip_Interceptor(kShip).m_kEngagement) != none)
		{
			iToHit += SU_XGInterception(XGShip_Interceptor(kShip).m_kEngagement).m_iSquadronAimBonus;
		}
		else if(PRES().m_kUIMissionControl != none && SU_UFORadarContactAlert(PRES().m_kUIMissionControl.m_kActiveAlert) != none)
		{
			iToHit += SU_XGInterception(SU_XGInterceptionUI(SU_UFORadarContactAlert(PRES().m_kUIMissionControl.m_kActiveAlert).m_kInterceptMgr).m_kInterception).m_iSquadronAimBonus;
		}
		if(GetStance(kShip) == 1)
		{
			iToHit += class'SquadronUnleashed'.default.AGG_JET_AIM_BONUS;
			iMaxToHit = (class'SquadronUnleashed'.default.AGG_MAX_HIT_CHANCE > 0 ? class'SquadronUnleashed'.default.AGG_MAX_HIT_CHANCE : 95);
		}
		if(GetStance(kShip) == 2)
		{
			iToHit -= class'SquadronUnleashed'.default.DEF_JET_AIM_PENALTY;
			iMaxToHit = (class'SquadronUnleashed'.default.DEF_MAX_HIT_CHANCE > 0 ? class'SquadronUnleashed'.default.DEF_MAX_HIT_CHANCE : 95);
		}
		if(XGShip_UFO(kTarget) != none)
		{
			switch(kTarget.GetType())
            {
                case 4:
                case 10:
                    iToHit -= class'SquadronUnleashed'.default.AIM_PENALTY_VS_SMALL_UFO;
                    break;
                case 7:
                case 8:
                case 13:
                case 14:
                    iToHit += class'SquadronUnleashed'.default.AIM_BONUS_VS_LARGE_UFO;
                    break;
                default:
                    break;
            }
		}
		if(kShip.IsDamaged() && !bSkipDamagedPenalty)
		{
			iToHit -= class'SquadronUnleashed'.default.DAMAGED_JET_AIM_PENALTY;
		}
		if(kPilot.IsTraitActive(bForCloseDistance))
		{
			iToHit += kPilot.GetCareerTrait().iBonusAim;
		}
		if(kPilot.IsFirestormTraitActive(bForCloseDistance))
		{
			iToHit += kPilot.GetFirestormTrait().iBonusAim;
		}
	}
	else if(kTarget.IsHumanShip())
	{
		kPilot = GetPilot(XGShip_Interceptor(kTarget));
		iToHit -= GetRankDefBonus(kPilot.GetRank(), kPilot.GetCareerType());
		if(SU_XGInterception(XGShip_Interceptor(kTarget).m_kEngagement) != none)
		{
			iToHit -= SU_XGInterception(XGShip_Interceptor(kTarget).m_kEngagement).m_iSquadronDefBonus;
		}
		else if(PRES().m_kUIMissionControl != none && SU_UFORadarContactAlert(PRES().m_kUIMissionControl.m_kActiveAlert) != none)
		{
			iToHit -= SU_XGInterception(SU_XGInterceptionUI(SU_UFORadarContactAlert(PRES().m_kUIMissionControl.m_kActiveAlert).m_kInterceptMgr).m_kInterception).m_iSquadronDefBonus;
		}
		if(GetStance(kShip) == 1)
		{
			iToHit += class'SquadronUnleashed'.default.AGG_UFO_AIM_BONUS;
			iMaxToHit = (class'SquadronUnleashed'.default.AGG_MAX_HIT_CHANCE > 0 ? class'SquadronUnleashed'.default.AGG_MAX_HIT_CHANCE : 95);
		}
		if(GetStance(kShip) == 2)
		{
			iToHit -= class'SquadronUnleashed'.default.DEF_UFO_AIM_PENALTY;
			iMaxToHit = (class'SquadronUnleashed'.default.DEF_MAX_HIT_CHANCE > 0 ? class'SquadronUnleashed'.default.DEF_MAX_HIT_CHANCE : 95);
		}
		if(kPilot.IsTraitActive(bForCloseDistance))
		{
			iToHit -= kPilot.GetCareerTrait().iBonusDef;
		}
		if(kPilot.IsFirestormTraitActive(bForCloseDistance))
		{
			iToHit -= kPilot.GetFirestormTrait().iBonusDef;
		}
	}
	if(bForCloseDistance)
	{
		iToHit += GetWeaponAimModClose(kWeapon.eType);
		if(!IsShortDistanceWeapon(kWeapon.eType))
			iToHit += class'SquadronUnleashed'.default.AIM_BONUS_CLOSE_DISTANCE_GLOBAL;
	}
	`Log("returned HitChance = " $ string(Clamp(iToHit, 5, iMaxToHit)), class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	return Clamp(iToHit, 5, iMaxToHit);
}
static function int GetCritChance(XGShip kShip, XGShip kTarget, int iWeaponIdx, optional int iShipWeaponType=-1)
{
	local array<TShipWeapon> arrAllWeapons;
	local int iCritChance;
	local SU_Pilot kPilot;

	if(iShipWeaponType == -1)
	{
		arrAllWeapons = kShip.GetWeapons();
		if(arrAllWeapons.Length < 2)
		{
			//vulcan must have been skipped, so...
			arrAllWeapons.AddItem(GetGameCore().SHIPWEAPON(0));
		}
		iShipWeaponType = arrAllWeapons[iWeaponIdx].eType;
	}
	iCritChance = (kShip.SHIPWEAPON(iShipWeaponType).iAP + kShip.m_kTShip.iAP - kTarget.m_kTShip.iArmor) / 2;
	iCritChance += GetWeaponCritMod(iShipWeaponType);
	if(kShip.IsHumanShip())
	{
		kPilot = class'SU_Utils'.static.GetPilot(XGShip_Interceptor(kShip));
		if(kPilot.IsTraitActive(ShipCloseOn(XGShip_Interceptor(kShip))))
		{
			iCritChance += kPilot.GetCareerTrait().iBonusCritChance;
		}
		if(kPilot.IsFirestormTraitActive(ShipCloseOn(XGShip_Interceptor(kShip))))
		{
			iCritChance += kPilot.GetFirestormTrait().iBonusCritChance;
		}
	}
	iCritChance = Clamp(iCritChance, class'SquadronUnleashed'.default.CRIT_MIN_CHANCE, class'SquadronUnleashed'.default.CRIT_MAX_CHANCE);
	return iCritChance;
}
static function bool ShipCloseOn(XGShip_Interceptor kShip, optional bool bDuringBattle)
{
	local bool bCloseDistance;

	if(!bDuringBattle && PRES().m_kUIMissionControl != none && SU_UFORadarContactAlert(PRES().m_kUIMissionControl.m_kActiveAlert) != none)
	{
		bCloseDistance = GetPilot(kShip).m_iForcedStartingDistance > 0 || GetPilot(kShip).m_bStartBattleClose;//during ship selection check forced distances only
	}
	else if(SU_UIInterceptionEngagement(PRES().m_kInterceptionEngagement) != none)
	{
		bCloseDistance = SU_UIInterceptionEngagement(PRES().m_kInterceptionEngagement).SelfGfx().GetShip(kShip).m_bClosedIn;
	}
	return bCloseDistance;
}
/** Returns 0 for short range weapon or 2 for long range weapon.
 *  @param iShipWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum
 */
static function int GetShipWeaponRangeBin(int iShipWeaponType)
{
	return IsShortDistanceWeapon(iShipWeaponType) ? 0 : 2;
}
/** Returns weapon's name adding ammo count in parenthesis.
 *  @param iShipWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum
 *  @param bWithAmmo Defaults to true - adds ammo count in parenthesis. Set to 'false' to get the name only.
 */
static function string GetShipWeaponName(int iShipWeaponType, optional bool bWithAmmo=true)
{
	local TShipWeapon tW;
	local string strWeaponName;

	tW = HANGAR().SHIPWEAPON(iShipWeaponType);
	strWeaponName = tW.strName;
	if(bWithAmmo && GetAmmoForWeaponType(iShipWeaponType) > 0)
	{
		strWeaponName @= "("$ GetAmmoForWeaponType(iShipWeaponType) $ ")";
	}
	return strWeaponName;
}
static function eGenericTriScale GetShipWeaponDamageBin(int iDamage)
{
	local int iWeapon;
	local array<int> arrAllValues;
	local float fAvg, fStdDev;

	for(iWeapon=0; iWeapon < 7; ++iWeapon)
	{
		arrAllValues.AddItem(GetGameCore().SHIPWEAPON(iWeapon).iDamage);
	}
	fAvg = MathGetAvg_IntToFloat(arrAllValues);	
	fStdDev = MathGetStdDev_IntToFloat(arrAllValues);
	if(iDamage <= int(fAvg - 0.7 * fStdDev))
	{
		return eGTS_Low;
	}
	else if(iDamage > int(fAvg + 0.44 * fStdDev))
	{
		return eGTS_High;
	}
	else
	{
		return eGTS_Medium;
	}
}
static function eGenericTriScale GetShipWeaponArmorPenetrationBin(int iAP)
{
	local int iWeapon;
	local array<int> arrAllValues;
	local float fAvg, fStdDev;

	for(iWeapon=0; iWeapon < 8; ++iWeapon)
	{
		arrAllValues.AddItem(GetGameCore().SHIPWEAPON(iWeapon).iAP);
	}
	fAvg = MathGetAvg_IntToFloat(arrAllValues);	
	fStdDev = MathGetStdDev_IntToFloat(arrAllValues);
	if(iAP <= int(fAvg - 0.7 * fStdDev))
	{
		return eGTS_Low;
	}
	else if(iAP > int(fAvg + 0.44 * fStdDev))
	{
		return eGTS_High;
	}
	else
	{
		return eGTS_Medium;
	}
}
static function eShipFireRate GetShipWeaponFiringRateBin(float fCooldown)
{
	local int iWeapon;
	local array<int> arrAllValues;
	local float fAvg, fStdDev;

	for(iWeapon=0; iWeapon < 8; ++iWeapon)
	{
		arrAllValues.AddItem(int(GetGameCore().SHIPWEAPON(iWeapon).fFiringTime * 100.0));
	}
	fAvg = MathGetAvg_IntToFloat(arrAllValues);	
	fStdDev = MathGetStdDev_IntToFloat(arrAllValues);
	if(fCooldown * 100 <= fAvg - 0.7 * fStdDev)
	{
		return eSFR_Rapid;
	}
	else if(fCooldown * 100 > fAvg + 0.44 * fStdDev)
	{
		return eSFR_Slow;
	}
	else
	{
		return eSFR_Medium;
	}
}

/** Returns iAmmo defined in ShipWeapons array in .ini file.
 *  @param iShipWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum
 */
static function int GetAmmoForWeaponType(int iShipWeaponType)
{
	return class'SquadronUnleashed'.default.ShipWeapons[iShipWeaponType].iAmmo;
}
/** @param iWeaponIdx Index in the arrWeapons array of kShip.m_kTShip.arrWeapons*/
static function bool IsSecondaryWeapon(int iWeaponIdx, XGShip kShip)
{
	return iWeaponIdx > 0;
}
/** Converts EShipWeapon enum (0-7) to ItemType (116-122 or 0)
@param iShipWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum*/
static function int ShipWeaponToItemType(int iShipWeaponType)
{
	switch(iShipWeaponType)
	{
		case 1:
			return 117;
		case 2:
			return 116;
		case 3:
			return 118;
		case 4:
			return 119;
		case 5:
			return 120;
		case 6:
			return 121;
		case 7:
			return 122;
		case 9:
			return 123;
		case 10:
			return 179;
		default:
			return 0;
	}
}
/** Converts ItemType (116-122 or 0) to index of EShipWeapon enum
 *  @param iItemType An ItemType in range 116-122 (or 0 for Vulcan Cannon).
 */
static function int ItemTypeToShipWeapon(int iItemType)
{
	switch(iItemType)
	{
        case 117:
            return 1;
        case 116:
            return 2;
        default:
			return Clamp(iItemType - 115, 0, 7);
	}
}
/** @param iWeaponIdx Index in the arrWeapons array of kShip.m_kTShip.arrWeapons*/
static function int GetAmmo(XGShip kShip, int iWeaponIdx)
{
	local array<TShipWeapon> arrAllWeapons;
	local int iWeaponItemType;

	arrAllWeapons = kShip.GetWeapons();
	if(arrAllWeapons.Length < 2 && !kShip.IsA('XGShip_UFO'))
	{
		//vulcan must have been skipped, so...
		arrAllWeapons.AddItem(GetGameCore().SHIPWEAPON(0));
	}
	iWeaponItemType = ShipWeaponToItemType(arrAllWeapons[iWeaponIdx].eType);
	return (arrAllWeapons[iWeaponIdx].eType > 7 ? -1 : kShip.m_kTShip.arrSalvage[iWeaponItemType]);
}
/** @param iWeaponIdx Index in the arrWeapons array of kShip.m_kTShip.arrWeapons*/
static function int GetMaxAmmo(XGShip kShip, int iWeaponIdx)
{
	local array<TShipWeapon> arrAllWeapons;	

	arrAllWeapons = kShip.GetWeapons();
	if(arrAllWeapons.Length < 2)
	{
		//vulcan must have been skipped, so...
		arrAllWeapons.AddItem(GetGameCore().SHIPWEAPON(0));
	}
	return GetAmmoForWeaponType(arrAllWeapons[iWeaponIdx].eType);
}
/** Replenishes ammo of all weapons for the specified ship. This is always called at battle start as debug procedure.*/
static function RearmShip(XGShip kShip)
{
	local array<TShipWeapon> arrAllWeapons;	
	local int i, iMaxAmmo, iWeaponItemType;
	local bool bUnlimited;
	local array<int> arrMaxAmmo;
	local string strDebug;

	arrAllWeapons = kShip.GetWeapons();
	if(arrAllWeapons.Length < 2 && !kShip.IsA('XGShip_UFO'))
	{
		//vulcan must have been skipped, so...
		arrAllWeapons.AddItem(GetGameCore().SHIPWEAPON(0));
	}
	arrMaxAmmo.Add(kShip.ITEMTREE().m_arrItems.Length);
	arrMaxAmmo.Add(255);
	for(i=0; i < arrAllWeapons.Length; i++)
	{
		iMaxAmmo = GetMaxAmmo(kShip, i);
		bUnlimited = (iMaxAmmo == -1);
		iWeaponItemType = ShipWeaponToItemType(arrAllWeapons[i].eType);
		strDebug $= ("\n"$Chr(9)$"iWeaponItemType set to" @ iWeaponItemType$"\n"$Chr(9)$"Setting arrMaxAmmo...");
		if(bUnlimited)
		{
			arrMaxAmmo[iWeaponItemType] = -1;
		}
		else
		{
			arrMaxAmmo[iWeaponItemType] += iMaxAmmo;
		}
		strDebug $= ("\n"$Chr(9)$arrAllWeapons[i].eType @ "ammo is being set to" @ arrMaxAmmo[iWeaponItemType]);
		kShip.m_kTShip.arrSalvage[iWeaponItemType] = arrMaxAmmo[iWeaponItemType];
	}
	`Log(strDebug, class'SquadronUnleashed'.default.bVerboseLog, GetFuncName());
}
/** Ensures correct lenght of weapon and cooldown arrays. This is always called at battle start as debug procedure.*/
static function DebugWeaponsForShip(XGShip kShip)
{
	//debug part for country interceptors from LWR
	if(!kShip.IsA('XGShip_UFO') && kShip.m_kTShip.arrWeapons.Length < 2)
	{
		kShip.m_kTShip.arrWeapons.Length = 2;
	}
	kShip.m_afWeaponCooldown.Length = kShip.m_kTShip.arrWeapons.Length;
}
/** @param iWeaponIdx Index in the arrWeapons array of kShip.m_kTShip.arrWeapons*/
static function ConsumeAmmo(XGShip kShip, int iWeaponIdx)
{
	local array<TShipWeapon> arrAllWeapons;	
	local int iWeaponItemType;

	arrAllWeapons = kShip.GetWeapons();
	if(arrAllWeapons.Length < 2)
	{
		//vulcan must have been skipped, so...
		arrAllWeapons.AddItem(GetGameCore().SHIPWEAPON(0));
	}
	iWeaponItemType = ShipWeaponToItemType(arrAllWeapons[iWeaponIdx].eType);
	if(kShip.m_kTShip.arrSalvage[iWeaponItemType] > 0)
	{
		--kShip.m_kTShip.arrSalvage[iWeaponItemType];
	}
}
/** Returns average DPS of a ship assuming it's not in battle yet 
 - therefore the distance is drawn either from the tactic or from the pilot's forced starting distance.
 In order to get DPS for certain distance consider temporary override of the pilot's forced distance.*/
static function int CalculateShipDPS(XGShip kShip, optional XGShip kTarget, optional bool bSkipDamaged, optional bool bForCloseDistance)
{
	local int I, iToHit, iBaseDmg, iCritChance, iDPS, iTotalDPS;
	local float fDmgMitigation;
	local TShipWeapon kWeapon;
	local array<TShipWeapon> akShipWeapons;
	local string strDebugTxt;
	local SU_Pilot kPilot;

	strDebugTxt = string(GetFuncName());
	
	akShipWeapons = kShip.GetWeapons();
	if(akShipWeapons.Length < 2)
	{
		//vulcan must have been skipped, so...
		akShipWeapons.AddItem(GetGameCore().SHIPWEAPON(0));
	}
	if(XGShip_Interceptor(kShip) != none)
	{
		kPilot = GetPilot(XGShip_Interceptor(kShip));
	}
	else if(XGShip_Interceptor(kTarget) != none)
	{
		kPilot = GetPilot(XGShip_Interceptor(kTarget));
	}
	iTotalDPS = 0;
	for(I = 0; I < kShip.m_kTShip.arrWeapons.Length; ++ I)
	{
		strDebugTxt $= ("\n"$Chr(9)$"Weapon " $ I);
		kWeapon = akShipWeapons[I];
		if(XGShip_Interceptor(kShip) != none)
		{
			if(I > kShip.m_afWeaponCooldown.Length-1)
			{
					strDebugTxt $= ("\n"$Chr(9)$"...not found cooldown value. Skipping" $ I);
					continue;
			}
			if(kShip.m_afWeaponCooldown[I] > 0.0)
			{
				strDebugTxt $= "\n" $ "...disabled due to cooldown. Skipping.";
				continue;
			}
			if(IsShortDistanceWeapon(kWeapon.eType) && !ShipCloseOn(XGShip_Interceptor(kShip)) )
			{
				strDebugTxt $= "\n" $ "...short distance weapons don't fire from long range. Skipping.";
				continue;
			}
		}
		iBaseDmg = kWeapon.iDamage;
		strDebugTxt $= ("\n"$Chr(9)$"BaseDamage = " $ string(iBaseDmg));
		
		iBaseDmg *= 1.25;
		strDebugTxt $= ("\n"$Chr(9)$"BaseDamage averaged = " $ string(iBaseDmg));
			
		if(XGShip_Interceptor(kShip) != none)
		{
			iBaseDmg *= (1.0 + (kPilot.m_iKills * class'SquadronUnleashed'.default.EXTRA_DMG_PCT_PER_KILL));
			strDebugTxt $= ("\n"$Chr(9)$"BaseDamage after kills = " $ string(iBaseDmg));

			iBaseDmg *= GetRankMgr().GetRankDmgBonus(kPilot.GetRank(), kPilot.GetCareerType());
			strDebugTxt $= ("\n"$Chr(9)$"BaseDamage after rank dmg bonus = " $ string(iBaseDmg));

			if(kPilot.IsTraitActive(ShipCloseOn(XGShip_Interceptor(kShip))))
			{
				iBaseDmg *= (1.0 + float(kPilot.GetCareerTrait().iBonusDmgPct) / 100.0);
				strDebugTxt $= ("\n"$Chr(9)$"BaseDamage after CareerTraitAdj = " $ string(iBaseDmg));
			}
			if(kPilot.IsFirestormTraitActive(ShipCloseOn(XGShip_Interceptor(kShip))))
			{
				iBaseDmg *= (1.0 + float(kPilot.GetFirestormTrait().iBonusDmgPct) / 100.0);
				strDebugTxt $= ("\n"$Chr(9)$"BaseDamage after FirestormTraitAdj = " $ string(iBaseDmg));
			}
			if(GetStance(kShip) == 1)
			{
				iBaseDmg *= (1.0 + class'SquadronUnleashed'.default.AGG_JET_DMG_BONUS);
				strDebugTxt $= ("\n"$Chr(9)$"BaseDamage AGG adjusted = " $ string(iBaseDmg));
			}
		}
		//FIXME: close distance checks require tests
		iToHit = GetHitChance(kShip, kTarget, I, bSkipDamaged, bForCloseDistance || XGShip_Interceptor(kShip) != none && ShipCloseOn(XGShip_Interceptor(kShip)) );
		if(kTarget.IsHumanShip())
		{
			if(GetStance(kTarget) == 1)
			{
				iToHit += Max(0, float(class'SquadronUnleashed'.default.AGG_JET_FORCE_HIT_CHANCE) / 100.0 * (100 - iToHit));
			}
			else if(GetStance(kTarget) == 2)
			{
				iToHit *= (1.0 - (float(class'SquadronUnleashed'.default.DEF_JET_DODGE_CHANCE) / 100.0));
			}
		}
		iDPS = iBaseDmg * iToHit / int(kWeapon.fFiringTime * 100.0);
		strDebugTxt $= ("\n"$Chr(9)$"Base DPS = " $ string(iDPS));
		if(XGShip_UFO(kTarget) != none)
		{
			if(kShip.LABS().IsResearched(XGShip_UFO(kTarget).GetType() + 57))
			{
				iDPS *= (1.0 + class'SquadronUnleashed'.default.EXTRA_DMG_FOR_RESEARCH);
				strDebugTxt $= ("\n"$Chr(9)$"DPS scaled with research bonus = " $ string(iDPS));
			}
		}
		if(kTarget != none)
		{
			fDmgMitigation = float(Clamp(5 * (kTarget.m_kTShip.iArmor - (kWeapon.iAP + kShip.m_kTShip.iAP)), 0, 95));
			strDebugTxt $= ("\n"$Chr(9)$"DmgMitigation = " $ Left(string(fDmgMitigation), 4));
			
			iDPS *= (1.0 - (fDmgMitigation / 100.0));
			strDebugTxt $= ("\n"$Chr(9)$"DPS after Mitigation = " $ string(iDPS));
			
			iCritChance = GetCritChance(kShip, kTarget, I, kWeapon.eType);
			strDebugTxt $= ("\n"$Chr(9)$"CritChance = " $ string(iCritChance));
			
			if(iCritChance > 0)
			{
				iDPS += int((float(iCritChance) / 100.0) * (float(iDPS) * (class'SquadronUnleashed'.default.CRIT_DMG_MULTIPLIER - 1.0) * GetWeaponCritDmgModPct(kWeapon.eType)));
				strDebugTxt $= ("\n"$Chr(9)$"DPS after PctCritAdj = " $ string(iDPS));  

				iDPS += int(float(iCritChance) / 100.0 * float(GetWeaponCritDmgModFlat(kWeapon.eType)));
				strDebugTxt $= ("\n"$Chr(9)$"DPS after FlatCritAdj = " $ string(iDPS));

				if(XGShip_Interceptor(kShip) != none)
				{
					if(kPilot.IsTraitActive(ShipCloseOn(XGShip_Interceptor(kShip))))
					{
						iDPS *= (float(iCritChance) / 100.0 * float(kPilot.GetCareerTrait().iBonusCritDmgPct) + 100.0) / 100.0;
						strDebugTxt $= ("\n"$Chr(9)$"DPS after CareerTraitCritAdj = " $ string(iDPS));
					}
					if(kPilot.IsFirestormTraitActive(ShipCloseOn(XGShip_Interceptor(kShip))))
					{
						iDPS *= (float(iCritChance) / 100.0 * float(kPilot.GetFirestormTrait().iBonusCritDmgPct) + 100.0) / 100.0;
						strDebugTxt $= ("\n"$Chr(9)$"DPS after FirestormTraitCritAdj = " $ string(iDPS));
					}
				}
			}
		}
		if(XGShip_Interceptor(kShip) != none && IsSecondaryWeapon(I, kShip))		
		{
			iDPS *= class'SquadronUnleashed'.default.SECONDARY_WPN_DMG_MOD;
			strDebugTxt $= ("\n"$Chr(9)$"DPS after SecondaryWpnAdj = " $ string(iDPS));
		}
		iTotalDPS += iDPS;
	}
	strDebugTxt $= ("\n"$Chr(9)$"returned DPS = " $ string(iTotalDPS));
	`Log(strDebugTxt, class'SquadronUnleashed'.default.bVerboseLog, GetFuncName());
	return iTotalDPS;
}
static function float GetAutoDisengageHPTreshold(XGShip_Interceptor kJet)
{
	switch(GetStance(kJet))
	{
	case 0:
	case 1:
	case 2:
		return GetSquadronMod().m_kPilotQuarters.m_arrTactics[GetStance(kJet)].fAutoAbortHP;
	default:
		return 1.0;
	}
}
static function float GetAutoBackOffHPTreshold(XGShip_Interceptor kJet)
{
	switch(GetStance(kJet))
	{
	case 0:
	case 1:
	case 2:
		return GetSquadronMod().m_kPilotQuarters.m_arrTactics[GetStance(kJet)].fAutoBackOffHP;
	default:
		return 1.0;
	}
}
static function bool ShouldStartClose(XGShip_Interceptor kInterceptor, optional XGInterception kInterception)
{
	local bool bStartClose;
	local SU_Pilot kPilot;
	local int iStance, iLongDPS, iCloseDPS;

	kPilot = GetPilot(kInterceptor);
	if(kPilot.m_iForcedStartingDistance < 0)
	{
		bStartClose = false;//forced back start
	}
	else if(kPilot.m_iForcedStartingDistance > 0)
	{
		bStartClose = true;//forced front start
	}
	else
	{
		iStance = GetStance(kInterceptor);
		bStartClose = GetSquadronMod().m_kPilotQuarters.m_arrTactics[iStance].bStartClose;//front start forced by tactic
		//FIXME: maybe calc auto-distance through total DPS over first 3/4/5 seconds??
		if(!bStartClose && kInterception != none)
		{
			kPilot.m_iForcedStartingDistance = -1;//temporary override
			iLongDPS = CalculateShipDPS(kInterceptor, kInterception.m_kUFOTarget);
			kPilot.m_iForcedStartingDistance = 1;//temporary override
			iCloseDPS = CalculateShipDPS(kInterceptor, kInterception.m_kUFOTarget);
			kPilot.m_iForcedStartingDistance=0;//restoring 0
			`Log(kInterceptor.GetCallsign() @ "iLongDPS="$iLongDPS @ "iCloseDPS="$iCloseDPS,,GetFuncName());
			if(iCloseDPS > iLongDPS)
			{
				bStartClose = true;
			}
		}
	}
	return bStartClose;
}
static function SU_Pilot GetPilot(XGShip_Interceptor kInterceptor)
{
	local SU_Pilot kPilot;

	foreach GetSquadronMod().m_kPilotQuarters.m_arrPilots(kPilot)
	{
		if(kPilot.GetShip() == kInterceptor)
		{
			return kPilot;
		}
	}
	return none;
}
static function int GetPilotRank(XGShip_Interceptor kInterceptor)
{
	return GetPilot(kInterceptor).GetRank();
}
static function string GetFullRankName(int iRank)
{
	return class'SU_PilotRankMgr'.default.m_arrPilotRankNames[iRank];
}

static function string GetShortRankName(int iRank)
{
	return class'SU_PilotRankMgr'.default.m_arrPilotRankShort[iRank];
}

static function int GetSquadronSizeAtRank(int iRank, int iType, optional bool bNoClamp)
{
	return (bNoClamp ? GetRankMgr().GetSquadronSizeAtRank(iRank, iType) : Clamp(GetRankMgr().GetSquadronSizeAtRank(iRank, iType), GetSquadronMod().MIN_SQUADRON_SIZE, GetSquadronMod().MAX_SQUADRON_SIZE));
}

static function int GetKillsForRank(int iRank, int iType)
{
	return GetRankMgr().GetKillsForRank(iRank, iType);
}
static function int GetXPForRank(int iRank, int iType)
{
	return GetRankMgr().GetXPForRank(iRank, iType);
}
static function int GetRankAimBonus(int iRank, int iType)
{
	return GetRankMgr().GetRankAimBonus(iRank, iType);
}
static function int GetRankDefBonus(int iRank, int iType)
{
	return GetRankMgr().GetRankDefBonus(iRank, iType);
}
static function float GetRankDmgBonus(int iRank, int iType)
{
	local float fMod;
	fMod = GetRankMgr().GetRankDmgBonus(iRank, iType);
	if(fMod == 0.0)
	{
		fMod = 1.0;
	}
	return fMod;
}
/** Returns squadron aim bonus for a pilot of a given rank in the given career. Debugs invalid rank or career.*/
static function int GetRankTeamAimBonus(int iRank, int iCareerPath)
{	
	return GetRankMgr().GetRankTeamAimBonus(iRank, iCareerPath);
}
/** Returns squadron defense (evasion) bonus for a pilot of a given rank in the given career. Debugs invalid rank or career.*/
static function int GetRankTeamDefBonus(int iRank, int iCareerPath)
{
	return GetRankMgr().GetRankTeamDefBonus(iRank, iCareerPath);
}
/** @param iWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum*/
static function int GetWeaponAimMod(int iWeaponType)
{
	return class'SquadronUnleashed'.default.ShipWeapons[class'SquadronUnleashed'.default.ShipWeapons.Find('iWeaponType', iWeaponType)].iAimMod;
}
/** @param iWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum*/
static function int GetWeaponAimModClose(int iWeaponType)
{
	return class'SquadronUnleashed'.default.ShipWeapons[class'SquadronUnleashed'.default.ShipWeapons.Find('iWeaponType', iWeaponType)].iAimModClose;
}
/** @param iWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum*/
static function int GetWeaponCritMod(int iWeaponType)
{
	return class'SquadronUnleashed'.default.ShipWeapons[class'SquadronUnleashed'.default.ShipWeapons.Find('iWeaponType', iWeaponType)].iCritChanceMod;
}
/** @param iWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum*/
static function int GetWeaponDmgModFlat(int iWeaponType)
{
	return class'SquadronUnleashed'.default.ShipWeapons[class'SquadronUnleashed'.default.ShipWeapons.Find('iWeaponType', iWeaponType)].iDmgMod;
}
/** @param iWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum*/
static function float GetWeaponDmgModPct(int iWeaponType)
{
	local float fMod;
	fMod =class'SquadronUnleashed'.default.ShipWeapons[class'SquadronUnleashed'.default.ShipWeapons.Find('iWeaponType', iWeaponType)].fDmgMod;
	if(fMod == 0.0)
	{
		fMod = 1.0;
	}
	return fMod;
}
/** @param iWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum*/
static function float GetWeaponCritDmgModPct(int iWeaponType)
{
	local float fMod;
	fMod =class'SquadronUnleashed'.default.ShipWeapons[class'SquadronUnleashed'.default.ShipWeapons.Find('iWeaponType', iWeaponType)].fCritDmgMod;
	if(fMod == 0.0)
	{
		fMod = 1.0;
	}
	return fMod;
}
/** @param iWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum*/
static function int GetWeaponCritDmgModFlat(int iWeaponType)
{
	return class'SquadronUnleashed'.default.ShipWeapons[class'SquadronUnleashed'.default.ShipWeapons.Find('iWeaponType', iWeaponType)].iCritDmgMod;
}
/** @param iWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum*/
static function bool WeaponFitsSecondarySlot(int iWeaponType)
{
	return class'SquadronUnleashed'.default.ShipWeapons[class'SquadronUnleashed'.default.ShipWeapons.Find('iWeaponType', iWeaponType)].bSecondary;
}
/** @param iWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum*/
static function bool WeaponFitsPrimarySlot(int iWeaponType)
{
	return (iWeaponType == 118 || iWeaponType > 0 && class'SquadronUnleashed'.default.ShipWeapons[class'SquadronUnleashed'.default.ShipWeapons.Find('iWeaponType', iWeaponType)].bPrimary);
}
/** @param iWeaponType A number in range 0-7 specifiying the weapon as in EShipWeapon enum*/
static function int GetWeaponRearmHours(int iWeaponType)
{
	local int iHours, iItemType;

	iHours = class'SquadronUnleashed'.default.ShipWeapons[class'SquadronUnleashed'.default.ShipWeapons.Find('iWeaponType', iWeaponType)].RearmHours;
	if(iHours <= 0)
	{
		iItemType = ShipWeaponToItemType(iWeaponType);
		//apply default LW settings
		if(iItemType == 0)
		{
			iHours = 6;
		}
		else if(iItemType == 116 || iItemType == 118)
		{
			iHours = 12;
		}
		else
		{
			iHours += class'XGTacticalGameCore'.default.INTERCEPTOR_REARM_HOURS;
		}
	}
	return iHours;
}
/** @param iSlotType 1 - primary, 2 - secondary*/
static function FilterWeaponsForSlot(int iSlotType, out array<TItem> arrItems)
{
	local TItem tItemW;
	local TShipWeapon tShipW;
	local int iItem;
	local bool bRemove;
	local string sLog;

	sLog = GetFuncName() @ iSlotType @ "num items" @ arrItems.Length;
	//for removing array elements loop from the end is appropriate
	for(iItem = arrItems.Length-1; iItem >= 0; --iItem)
	{
		sLog $="\n"$Chr(9)$"Checking item" @ arrItems[iItem].iItem;
		tItemW = arrItems[iItem];
		tShipW = HANGAR().SHIPWEAPON(tItemW.iItem == 0 ? 0 : int(class'XGFacility_Hangar'.static.ItemTypeToShipWeapon(EItemType(tItemW.iItem))));
		sLog $="\n"$Chr(9)$"ShipWeapon=" @ tShipW.eType;
		bRemove = false;
		if(iSlotType == 1)
		{
			bRemove = !WeaponFitsPrimarySlot(tShipW.eType);
			sLog $= (bRemove ? "\n"$Chr(9)$"Weapon does not fit primary slot." : "");
		}
		else
		{
			bRemove = !WeaponFitsSecondarySlot(tShipW.eType);
			sLog $= (bRemove ? "\n"$Chr(9)$"Weapon does not fit secondary slot." : "");
		}
		if(bRemove)
		{
			sLog $="\n"$Chr(9)$"Removing...";
			arrItems.Remove(iItem, 1);
		}
	}
	`Log(sLog, class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
}
static function float MathGetStdDev_IntToFloat(array<int> arrValues)
{
	local int iAvg;
	local int i, iCount, iSqrSum;

	iAvg = int(MathGetAvg_IntToFloat(arrValues));
	foreach arrValues(i, iCount)
	{
		iSqrSum += (i - iAvg) ** 2;
	}
	return Sqrt(float(iSqrSum) / float(iCount+1));
}
static function float MathGetAvg_IntToFloat(array<int> arrValues)
{
	local int i, iSum, iCount;

	foreach arrValues(i, iCount)
	{
		iSum += i;
	}
	return float(iSum) / float(iCount + 1);
}
static function string GetDistanceToUFOstring(bool bFirestorm, bool bShort)
{
	return "<img src='img://" $ (bFirestorm ? "LongWar.Icons.IC_Firestorm" : "LongWar.Icons.IC_Raven") $ "' height='14' width='14'>"$ (bShort ? "--" : "-----") @ "<img src='img:///gfxMissionControl.ML_ufo' height='14' width='14'>";
}
static function SU_UFOSquadron GetUFOSquadron(XGShip_UFO kUFO)
{
	local XGGeoscape kGeo;
	local SU_UFOSquadron kUFOs;

	kGeo = GEOSCAPE();
	foreach kGeo.DynamicActors(class'SU_UFOSquadron', kUFOs)
	{
		if(kUFOs.GetMotherShip() == kUFO || kUFO.m_kEntity.m_iData == kUFOs.m_iData)
		{
			return kUFOs;
		}
	}
	return none;
}
static function int XComThreat()
{
	if(!GetGameCore().IsOptionEnabled(eGO_DynamicWar))
	{
		return Clamp(GetGameCore().STAT_GetStat(21) / 2, 0, 4);
	}
	else
	{
		return Clamp(GetGameCore().STAT_GetStat(21), 0, 8);
	}
}
static function int AlienResources()
{
	return GetGameCore().STAT_GetStat(19);
}
static function int AlienResourceLvl()
{
	return Clamp(GetGameCore().STAT_GetStat(19) / 50, 0 , 4);
}
static function int AlienResearch()
{
	return GetGameCore().STAT_GetStat(1);
}
static function int GetUFOHullSize(int iUFOType)
{
	local int iSize;

	switch(iUFOType)
	{
	case 4:
	case 10:
		iSize=1;
		break;
	case 5:
	case 11:
		iSize=2;
		break;
	case 6:
	case 12:
		iSize=3;
		break;
	case 7:
	case 13:
		iSize=4;
		break;
	case 8:
	case 14:
		iSize=5;
		break;
	default:
		iSize=0;
	}
	return iSize;
}
DefaultProperties
{
}