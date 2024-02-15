class XComGiantMutator extends XComMutator
	config(GiantMod);

struct TGiantComboPerk
{
	var int iPerkReq;
	var int iPerkGranted;
};
var config int m_iCombatDrugsBonusInSmoke;
var config int m_iSquadSizeAbduction;
var config int m_iSquadSizeTerror;
var config int m_iSquadSizeCouncil;
var config int m_iSquadSizeDLC;
var config int m_iDoubleTapCooldown;
var config int m_iPrecShotCooldown;
var config int m_iFireRocketCooldown;
var config int m_iRunAndGunCooldown;
var config int m_iSuppressionCooldown;
var config int m_iJetOrderHours;
var config int m_iSoldiersArrivalHours;
var config bool m_bAlienSightRings;
var config bool m_bIronFocus;
var config Color m_tSightRingColor;
var array<StaticMeshComponent> m_arrAlienSightRings;
var config bool m_bSoftExplosives;
var config array<TPerk> m_arrForceRemovePerks;
var config array<TItem> m_arrForceItemCategory;
var config array<TGiantComboPerk> m_arrComboPerks;
var int m_iWatchSoldierPerks;
var XGStrategySoldier m_kCurrentSoldier;
var TPerk m_kTPerk;
var TGiantComboPerk m_kTPerkCombo;
var int m_Iterator;

var array<XGUnit> m_arrAllUnits;

function PostLevelLoaded(PlayerController Sender)
{
	local XGUnit kUnit;

	foreach DynamicActors(class'XGUnit', kUnit)
	{
		RegisterWatchVarsForUnit(kUnit);
		m_arrAllUnits.AddItem(kUnit);
	}
	RegisterWatchVarsTactical();
	UpdateAlienSightRings(m_bAlienSightRings);
	//set cooldown on Precision Shot, Rocket, ShredderRocket, Run And Gun
	XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_kAbilities.m_arrAbilities[eAbility_PrecisionShot].iCooldown = (default.m_iPrecShotCooldown > 0 ? default.m_iPrecShotCooldown : -1);
	XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_kAbilities.m_arrAbilities[eAbility_ShotSuppress].iCooldown = (default.m_iSuppressionCooldown> 0 ? default.m_iSuppressionCooldown : -1);
	XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_kAbilities.m_arrAbilities[eAbility_RocketLauncher].iCooldown = (default.m_iFireRocketCooldown > 0 ? default.m_iFireRocketCooldown : -1);
	XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_kAbilities.m_arrAbilities[eAbility_ShredderRocket].iCooldown = (default.m_iFireRocketCooldown > 0 ? default.m_iFireRocketCooldown : -1);
	XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_kAbilities.m_arrAbilities[eAbility_RunAndGun].iCooldown = (default.m_iRunAndGunCooldown> 0 ? default.m_iRunAndGunCooldown: -1);
	if(m_bIronFocus)
	{
		XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_kAbilities.m_arrAbilities[eAbility_Aim].aProperties[eProp_AbortWithShot] = 0;
		XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_kAbilities.m_arrAbilities[eAbility_Aim].aProperties[eProp_AbortWithWound] = 0;
	}
}
function PostLoadSaveGame(PlayerController Sender)
{
	local XGUnit kUnit;
	
	foreach DynamicActors(class'XGUnit', kUnit)
	{
		kUnit.GetCharacter().m_kUnit = kUnit;
	}
	PostLevelLoaded(Sender);
}
function RegisterWatchVarsForUnit(XGUnit kUnit)
{
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(kUnit, 'm_bDoubleTapActivated', self, OnDoubleTapActivated);
}
function RegisterWatchVarsHQ()
{
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().HQ(), 'm_akInterceptorOrders', self, OnNewInterceptorOrder);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XComHQPresentationLayer(XComPlayerController(GetALocalPlayerController()).m_Pres), 'm_kSoldierPromote', self, OnSoldierPromotionScreen);
}
function RegisterWatchVarsTactical()
{
	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle, 'm_iTurn', self, OnNewHumanTurn);
}
function UpdateWatchVarsForUnit(XGUnit kUnit)
{
	if(m_arrAllUnits.Find(kUnit) < 0)
	{
		m_arrAllUnits.AddItem(kUnit);
		RegisterWatchVarsForUnit(kUnit);
	}
}
function MutateUpdateInteractClaim(string sUnitName, PlayerController PC)
{
	local XGUnit kTheUnit, kUnit;
	local TPerk tRemovePerk;

	if(!XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().AtBottomOfRunningStateBeginBlock())
	{
		return;
	}
	foreach DynamicActors(class'XGUnit', kUnit)
	{
		UpdateWatchVarsForUnit(kUnit);
		if(string(kUnit.Name) == sUnitName)
		{
			kTheUnit = kUnit;
		}
		if(kUnit.m_bWasKilledByExplosion)
		{
			kUnit.m_bWasKilledByExplosion = !m_bSoftExplosives;
		}
		foreach default.m_arrForceRemovePerks(tRemovePerk)
		{
			if(kUnit.GetCharType() == tRemovePerk.iCategory)
			{
				kUnit.GetCharacter().m_kChar.aUpgrades[tRemovePerk.iPerk] = 0;
			}
		}
	}
	if(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle.IsAlienTurn())
	{
		if(kTheUnit.GetTeam() == eTeam_Alien)
		{
			UpdateAlienSightRings(false, kTheUnit);
		}
	}
	else if(kTheUnit.GetTeam() == eTeam_XCom)
	{
		UpdateAlienSightRings(true);
	}
}
function Mutate(string strCall, PlayerController P)
{
	if(InStr(strCall, "XGAbility_Targeted.GetHitChance:") != -1)
	{
		ModifyHitChanceStats(strCall);
	}
	else if(InStr(strCall, "XGShip_Dropship.GetCapacity") != -1)
	{
		ModifyDropshipCapacity();
	}
	else if(InStr(strCall, "XGStrategy.PostLoadSaveGame") != -1)
	{
		ApplyForceItemCategories();
		FixSoldiersArrivalTime();
		UpdateComboPerksForAll();
		RegisterWatchVarsHQ();
	}
	super.Mutate(strCall, P);
}

function ModifyHitChanceStats(string strParams)
{
	local XGAbility_Targeted kShot;
	local TShotResult kResult; 
	local TShotInfo kInfo;
	local TShotHUDStat tStat;
	local XGParamTag kTag;
	local string strBackUp;
	local bool bFound;
	local int i;

	kShot = XGAbility_Targeted(class'MiniModsTactical'.static.GetActor(class'XGAbility_Targeted', class'MiniModsTactical'.static.GetParameterString(0, strParams)));
	if(kShot != none && kShot.GetType() != 9 && !kShot.HasProperty(33) && kShot.m_kWeapon != none && kShot.GetPrimaryTarget() != none)
	{

		//backup string saved in kTag
		kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
		strBackUp = kTag.StrValue0;

		//get F1 shot summary:
		kShot.GetShotSummary(kResult, kInfo);
		
		//restore kTag string which has just 
		kTag.StrValue0 = strBackUp;
		
		if(kShot.m_kUnit.m_bInCombatDrugs)
		{
			//loop over F1 entries, find combat drugs, modify:
			for(i=0; i < 16; ++i)
			{
				//find row for combat drugs
				if(kShot.m_shotHUDHitChanceStats[i].m_iPerk == 51)
				{
					bFound = true;
					kShot.m_shotHUDHitChanceStats[i].m_iAmount = default.m_iCombatDrugsBonusInSmoke;
				}
			}
			if(!bFound)
			{
				tStat.m_iPerk = 51;
				tStat.m_iAmount= default.m_iCombatDrugsBonusInSmoke;
				tStat.m_strTitle = kShot.PERKS().GetBonusTitle(51);
				kShot.AddShotHUDStat(eType_HitChance, tStat);
			}
		}
	}
}
function ModifyDropshipCapacity()
{
	local XGShip_Dropship kSkyranger;
	
	kSkyranger = XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().HANGAR().GetDropship();
	switch(EMissionType(kSkyranger.m_kMission.m_iMissionType))
	{
	case eMission_Abduction:
		kSkyranger.m_iCapacity = default.m_iSquadSizeAbduction;
		break;
	case eMission_TerrorSite:
		kSkyranger.m_iCapacity = default.m_iSquadSizeTerror;
		break;
	case eMission_Special:
		kSkyranger.m_iCapacity = default.m_iSquadSizeCouncil;
		break;
	case 20:
	case 21:
	case 22:
	case 25:
	case 26:
	case 27:
		kSkyranger.m_iCapacity = default.m_iSquadSizeDLC;
		break;
	default:
		break;
	}
	kSkyranger.m_iCapacity = Clamp(kSkyranger.m_iCapacity, 2, 8);
}
function OnDoubleTapActivated()
{
	local XGUnit kUnit;
	local int idx;

	kUnit = XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_kActivePlayer.GetActiveUnit();
	if(kUnit.m_bDoubleTapActivated)
	{
		for(idx=0; idx < 64; ++idx)
		{
			if(kUnit.m_aAbilitiesOnCooldown[idx].iType == 47)
			{
				//XComPlayerController(GetALocalPlayerController()).m_Pres.GetMessenger().Message("DoubleTap cooldown was" @ kUnit.m_aAbilitiesOnCooldown[idx].iCooldown);
				kUnit.m_aAbilitiesOnCooldown[idx].iCooldown = default.m_iDoubleTapCooldown;
				//XComPlayerController(GetALocalPlayerController()).m_Pres.GetMessenger().Message("DoubleTap cooldown is" @ kUnit.m_aAbilitiesOnCooldown[idx].iCooldown);
				break;
			}
		}
	}
}
function ApplyForceItemCategories()
{
	local TItem tOption;
	
	foreach default.m_arrForceItemCategory(tOption)
	{
		if(tOption.iItem > 0)
		{
			XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().ITEMTREE().m_arrItems[tOption.iItem].iCategory = tOption.iCategory;
		}
	}
}
function OnNewInterceptorOrder()
{
	local XGHeadQuarters kHQ;
	
	kHQ = XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().HQ();
	if(kHQ.m_akInterceptorOrders[kHQ.m_akInterceptorOrders.Length-1].iHours > default.m_iJetOrderHours)
	{
		kHQ.m_akInterceptorOrders[kHQ.m_akInterceptorOrders.Length-1].iHours = default.m_iJetOrderHours;
	}
}
function FixSoldiersArrivalTime()
{
	XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().ITEMTREE().m_arrStaff[1].iHours = default.m_iSoldiersArrivalHours;
}
function OnSoldierPromotionScreen()
{
	local UISoldierPromotion kUI;

	kUI = XComHQPresentationLayer(XComPlayerController(GetALocalPlayerController()).m_Pres).m_kSoldierPromote;
	if(kUI != none)
	{
		if(kUI.m_kSoldier != none)
		{
			m_iWatchSoldierPerks = WorldInfo.MyWatchVariableMgr.RegisterWatchVariableStructMember(kUI.m_kSoldier, 'm_kChar', 'aUpgrades', self, UpdateComboPerksForSoldier);
			SetTimer(0.50, false, 'UpdateComboPerkDescriptions');
		}
		else
		{
			SetTimer(0.50, false, GetFuncName());
		}
	}
	else
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchSoldierPerks);
		m_iWatchSoldierPerks = -1;
	}
}
function UpdateComboPerksForSoldier()
{
	local TGiantComboPerk tCombo;

	if(XComHQPresentationLayer(XComPlayerController(GetALocalPlayerController()).m_Pres).m_kSoldierPromote != none)
	{
		m_kCurrentSoldier = XComHQPresentationLayer(XComPlayerController(GetALocalPlayerController()).m_Pres).m_kSoldierPromote.m_kSoldier;
	}
	if(m_kCurrentSoldier != none)
	{
		foreach default.m_arrComboPerks(tCombo)
		{
			if((m_kCurrentSoldier.m_kChar.aUpgrades[tCombo.iPerkReq] & 1) > 0)
			{
				m_kCurrentSoldier.m_kChar.aUpgrades[tCombo.iPerkGranted] = m_kCurrentSoldier.m_kChar.aUpgrades[tCombo.iPerkGranted] | 1;
			}
		}
		if(XComHQPresentationLayer(XComPlayerController(GetALocalPlayerController()).m_Pres).m_kSoldierPromote != none)
		{
			XComHQPresentationLayer(XComPlayerController(GetALocalPlayerController()).m_Pres).m_kSoldierPromote.UpdateAbilityData();
			XComHQPresentationLayer(XComPlayerController(GetALocalPlayerController()).m_Pres).m_kSoldierPromote.m_kSoldierStats.UpdateData();
		}
	}
}
function UpdateComboPerksForAll()
{
	local XGStrategySoldier kSoldier;

	foreach DynamicActors(class'XGStrategySoldier', kSoldier)
	{
		m_kCurrentSoldier = kSoldier;
		UpdateComboPerksForSoldier();
	}
}
function UpdateComboPerkDescriptions()
{
	local XComPerkManager kPerkMgr;
	local TGiantComboPerk tCombo;
	local TPerk kTPerk;
	local string strDescExpansion;

	if(GetStateName() == 'UpdatingPerkDescriptions' && !XComHQPresentationLayer(XComPlayerController(GetALocalPlayerController()).m_Pres).IsInState('State_SoldierPromotion'))
	{
		PopState();
	}
	else
	{
		PushState('UpdatingPerkDescriptions');
	}
	return;
	kPerkMgr = XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().perkMgr();
	foreach default.m_arrComboPerks(tCombo)
	{
		kTPerk = kPerkMgr.GetPerk(tCombo.iPerkReq);
		strDescExpansion = ". Grants" @ kPerkMgr.GetPerk(tCombo.iPerkGranted).strName[0] $ ".";
		if(InStr(kTPerk.strDescription[0], strDescExpansion, true, true) < 0)
		{
			kTPerk.strDescription[0] = kTPerk.strDescription[0] $ strDescExpansion;
		}
		kPerkMgr.m_arrPerks[tCombo.iPerkReq] = kTPerk;
	}
}
function OnNewHumanTurn()
{
	//ShowAlienSightRangeIndicators(true);
}
function UpdateAlienSightRings(bool bShow, optional XGUnit kOnlyThisUnit)
{
	local XGUnit kUnit;
	local float fDiameter;
    local Vector tmpVect;
	local StaticMeshComponent kRing;

	foreach DynamicActors(class'XGUnit', kUnit)
	{
		if(kUnit.GetTeam() == eTeam_Alien)
		{
			if(kOnlyThisUnit == none || kOnlyThisUnit == kUnit)
			{
				kRing = GetAlienSightRing(kUnit);
				fDiameter = float((kUnit.GetSightRadius()) * 128);
				kRing.SetScale(fDiameter / 512.0);
				tmpVect = kUnit.GetPawn().Location - (kUnit.GetFootLocation());
				tmpVect.Z *= -0.90;
				kRing.SetTranslation(tmpVect);
				SetRingColor(kRing);
				kRing.SetHidden(!bShow || !m_bAlienSightRings  || !kUnit.IsVisibleToTeam(eTeam_XCom) || !kUnit.IsAlive() || kUnit.IsCriticallyWounded());
			}
		}
	}
}
function StaticMeshComponent GetAlienSightRing(XGUnit kUnit)
{
	local StaticMeshComponent kRing;
	local bool bFound;

	foreach m_arrAlienSightRings(kRing)
	{
		if(kRing.Outer == kUnit)
		{
			bFound = true;
			break;
		}
	}
	if(!bFound)
	{
		kRing = new (kUnit) class'StaticMeshComponent';
		kRing.SetStaticMesh(kUnit.GetPawn().CivilianRescueRing);
		kRing.SetHidden(true);
		SetRingColor(kRing);
		kUnit.AttachComponent(kRing);
		m_arrAlienSightRings.AddItem(kRing);
	}
	return kRing;
}
function SetRingColor(StaticMeshComponent kRing)
{
	local LinearColor tColor;
	local MaterialInstanceConstant MIC;

	MIC = MaterialInstanceConstant(kRing.GetMaterial(0));
	if(MIC == none)
	{
		MIC = new (kRing.Outer) class'MaterialInstanceConstant';
		MIC.SetParent(kRing.GetMaterial(0));
		kRing.SetMaterial(0, MIC);
	}
	tColor.R= float(m_tSightRingColor.R) / 255.0;
	tColor.G= float(m_tSightRingColor.G) / 255.0;
	tColor.B= float(m_tSightRingColor.B) / 255.0;
	tColor.A= float(m_tSightRingColor.A) / 100.0;
	MIC.SetVectorParameterValue('Color', tColor);
}
function BuildModMenu()
{
	local UIModOptionsContainer kContainer;

	kContainer = Spawn(class'GiantModOptionsContainer', self);
	kContainer.Init(self);
}
state UpdatingOptions
{
	event PushedState()
	{
		BuildModMenu();
	}
	event PoppedState()
	{
		class'XComModsProfile'.static.ClearAllSettingsForMod("GiantMod");
	}
}
state UpdatingPerkDescriptions
{
	function XComPerkManager PERKS()
	{
		return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().perkMgr();
	}
Begin:
	m_Iterator = default.m_arrComboPerks.Length - 1;
	while(m_Iterator >= 0)
	{
		m_kTPerkCombo = default.m_arrComboPerks[m_Iterator];
		if(m_kTPerkCombo.iPerkReq > 0)
		{
			m_kTPerk = PERKS().GetPerk(m_kTPerkCombo.iPerkReq);
			if(InStr(m_kTPerk.strDescription[0], ". Grants" @ PERKS().GetPerk(m_kTPerkCombo.iPerkGranted).strName[0] $ ".", true, true) < 0)
			{
				m_kTPerk.strDescription[0] = m_kTPerk.strDescription[0] $ ". Grants" @ PERKS().GetPerk(m_kTPerkCombo.iPerkGranted).strName[0] $ ".";
			}
			PERKS().m_arrPerks[m_kTPerkCombo.iPerkReq] = m_kTPerk;
			Sleep(0.0);
		}
		--m_Iterator;
	}
	PopState();
}
DefaultProperties
{
	m_iWatchSoldierPerks=-1
}
