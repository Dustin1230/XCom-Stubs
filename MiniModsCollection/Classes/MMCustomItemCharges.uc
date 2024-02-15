class MMCustomItemCharges extends Actor
	config(MiniMods);

struct TPerkToItem
{
	var int iPerk;
	var int iItem;
	var int iCharges;
	var bool bEnabled;

	structdefaultproperties
	{
		bEnabled=true
	}
};

var config array<TPerkToItem> PerkGivesItems;
var MiniModsTactical MMTactical;
var MiniModsStrategy MMStrategy;

function Init(XComMutator kOwner, optional bool bCleanUpDefaults=true)
{
	if(kOwner.IsA('MiniModsTactical'))
		MMTactical = MiniModsTactical(kOwner);

	if(kOwner.IsA('MiniModsStrategy'))
		MMStrategy = MiniModsStrategy(kOwner);
	
	if(bCleanUpDefaults)
		CleanUpDefaultSettings();
}
function bool SoldierCanGainChargesFromPerk(XGUnit kSoldier, TPerkToItem tGiveCharge)
{
	local bool bInfiniteItem, bItemInInventory, bSoldierHasPerk;

	if(class'MiniModsStrategy'.static.IsLongWarBuild())
	{
		bInfiniteItem = class'MiniModsStrategy'.static.GetItemBalanceNormalFor(tGiveCharge.iItem).iTime < 0;
	}
	else
	{
		bInfiniteItem = IsInfiniteItemEW(tGiveCharge.iItem);
	}
	bItemInInventory = class'XGTacticalGameCoreNativeBase'.static.TInventoryHasItemType(kSoldier.GetCharacter().m_kChar.kInventory, tGiveCharge.iItem);
	bSoldierHasPerk = kSoldier.GetCharacter().HasUpgrade(tGiveCharge.iPerk);
	return bSoldierHasPerk && !kSoldier.IsAugmented() && !kSoldier.IsShiv() && tGiveCharge.iCharges > 0 && (bInfiniteItem || bItemInInventory);
}
static function bool IsInfiniteItemEW(int eItem)
{
	switch(eItem)
	{
	case 2:
	case 3:
	case 4:
	case 5:
	case 6:
	case 7:
	case 59:
	case 81:
	case 82:
	case 118:
	case 66:
	case 84:
		return true;
	default:
		return false;
	}
}
function UpdateItemCharges(optional bool bCleanUpOnBattleOver=false, optional XGUnit kOnlyThisSoldier=none)
{
	local XGUnit kSoldier;
	local XGSquad kXCom;
	local int i, iLowestHP, iUseAbilites, iMoves, iReaction;
	local TPerkToItem tGiveCharge;
	local bool bUpdate, bRaGActive, bRaGUsedMove, bDTActive;
	local array<int> arrItemsToAdd;

	if(MMTactical != none && (!MMTactical.IsBattleReady() || class'MiniModsTactical'.static.PC().IsInCinematicMode()))
	{
		if(!IsTimerActive(GetFuncName()))
		{
			SetTimer(0.50, false, GetFuncName());
		}
		return;
	}
	kXCom = XGBattle_SP(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle()).GetHumanPlayer().GetSquad();
	for(i=0; i < kXCom.GetNumMembers(); ++i)
	{
		kSoldier = kXCom.GetMemberAt(i);
		if(kOnlyThisSoldier != none && kSoldier != kOnlyThisSoldier)
		{
			continue;
		}
		if(kSoldier.IsAugmented() || kSoldier.IsATank())
		{
			continue;
		}
		bUpdate = false;
		arrItemsToAdd.Length = 0;
		foreach PerkGivesItems(tGiveCharge)
		{
			if( !bCleanUpOnBattleOver && SoldierCanGainChargesFromPerk(kSoldier, tGiveCharge) && tGiveCharge.bEnabled)
			{
				`Log("Updating charges for iPerk=" $ tGiveCharge.iPerk $ ". Soldier:"@kSoldier.SafeGetCharacterFullName(), MMTactical.bDebugLog, name);
				kSoldier.SetFlashBangs(kSoldier.GetFlashBangs() + int(tGiveCharge.iItem == 83) * tGiveCharge.iCharges);				
				kSoldier.SetSmokeGrenadeCharges(kSoldier.GetSmokeGrenadeCharges() + int(tGiveCharge.iItem == 82) * tGiveCharge.iCharges);
				kSoldier.SetMimicBeaconCharges(kSoldier.GetMimicBeaconCharges() + int(tGiveCharge.iItem == 88) * tGiveCharge.iCharges);
				kSoldier.SetFragGrenades(kSoldier.GetFragGrenades() + int(tGiveCharge.iItem == 81) * tGiveCharge.iCharges);
				kSoldier.SetAlienGrenades(kSoldier.GetAlienGrenades() + int(tGiveCharge.iItem == 84) * tGiveCharge.iCharges);
				kSoldier.SetGhostGrenades(kSoldier.GetGhostGrenades() + int(tGiveCharge.iItem == 85) * tGiveCharge.iCharges);
				kSoldier.SetGasGrenades(kSoldier.GetGasGrenades() + int(tGiveCharge.iItem == 86) * tGiveCharge.iCharges);
				kSoldier.SetNeedleGrenades(kSoldier.GetNeedleGrenades() + int(tGiveCharge.iItem == 87) * tGiveCharge.iCharges);
				kSoldier.SetArcThrowerCharges(kSoldier.GetArcThrowerCharges() + int(tGiveCharge.iItem == 73) * tGiveCharge.iCharges);
				kSoldier.SetShredderRockets(kSoldier.GetShredderRockets() + int(tGiveCharge.iItem == 89) * tGiveCharge.iCharges);
				kSoldier.SetRockets(kSoldier.GetRockets() + int(tGiveCharge.iItem == 77) * tGiveCharge.iCharges);
				kSoldier.SetBattleScannerCharges(kSoldier.GetBattleScannerCharges() + int(tGiveCharge.iItem == 97) * tGiveCharge.iCharges);
				kSoldier.m_iMediKitCharges += (int(tGiveCharge.iItem == 69) * tGiveCharge.iCharges);
				if(!class'XGTacticalGameCoreNativeBase'.static.TInventoryHasItemType(kSoldier.GetCharacter().m_kChar.kInventory, tGiveCharge.iItem))
				{
					bUpdate = true;
					arrItemsToAdd.AddItem(tGiveCharge.iItem);
					if(!kSoldier.GetInventory().HasItemOfType(EItemType(tGiveCharge.iItem)))
						XComContentManager(class'Engine'.static.GetEngine().GetContentManager()).RequestContentArchetype(eContent_Weapon, tGiveCharge.iItem);
				}
			}
		}
		if(bUpdate || bCleanUpOnBattleOver)
		{
			`Log("Updating loadout for soldier:" @ kSoldier.SafeGetCharacterFullName(), MMTactical.bDebugLog, name);
			bUpdate = InStr(GetScriptTrace(), "PostLevelLoaded") == -1; //check for call from PostLevelLoaded
			if(bUpdate)
			{
				//calling ApplyInventory a little below will reset some variables so I save them for restoring
				iLowestHP = kSoldier.m_iLowestHP;
				iMoves = kSoldier.m_iMoves;
				iReaction = kSoldier.m_aCurrentStats[18];
				iUseAbilites = kSoldier.m_iUseAbilities;
				bRaGActive = kSoldier.m_bRunAndGunActivated;
				bRaGUsedMove = kSoldier.m_bRunAndGunUsedMove;
				bDTActive = kSoldier.m_bDoubleTapActivated;
			}
			//class'XGLoadoutMgr'.static.ApplyInventory(kSoldier, false);
			UpdateLoadout(kSoldier, arrItemsToAdd, bCleanUpOnBattleOver);
			if(bUpdate)
			{
				//here I am restoring variables which have been reset by ApplyInventory
				kSoldier.m_iLowestHP = iLowestHP;
				kSoldier.m_iMoves = iMoves;
				kSoldier.m_aCurrentStats[18]=iReaction;
				kSoldier.m_iUseAbilities = iUseAbilites;
				kSoldier.m_bRunAndGunActivated = bRaGActive;
				kSoldier.m_bRunAndGunUsedMove = bRaGUsedMove;
				kSoldier.m_bDoubleTapActivated = bDTActive;
			}
			if(!bCleanUpOnBattleOver && (kSoldier == XComTacticalGRI(WorldInfo.GRI).GetBattle().m_kActivePlayer.GetActiveUnit()) )
			{
				kSoldier.UpdateAbilitiesUI(); //rebuilding abilities' HUD for active unit
				`Log("Updated ability HUD for" @ kSoldier.SafeGetCharacterFullName(), MMTactical.bDebugLog, name);
			}
		}
	}
	if(MMTactical.GetSavedData().m_aJournalEvents.Find("UpdatedItemCharges") < 0)
	{
		MMTactical.GetSavedData().m_aJournalEvents.AddItem("UpdatedItemCharges");
	}
}
function UpdateLoadout(XGUnit kSoldier, array<int> arrAddItems, optional bool bOnBattleOver=false)
{
	local TLoadout Loadout;
	local int iSlot;
	
	if(bOnBattleOver)
	{
		//characters who gained SmokeBomb and BattleScanner perks from "free" charges must have the perks removed
		//FieldMedic from medikit is handled by LW code (consider fix for EW!!)
		if(kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_SmokeBomb] > 1 && !class'XGTacticalGameCoreNativeBase'.static.TInventoryHasItemType(kSoldier.GetCharacter().m_kChar.kInventory, eItem_SmokeGrenade) )
		{
			kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_SmokeBomb] = kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_SmokeBomb] & 1; 
		}
		if(kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_BattleScanner] > 1 && !class'XGTacticalGameCoreNativeBase'.static.TInventoryHasItemType(kSoldier.GetCharacter().m_kChar.kInventory, eItem_BattleScanner) )
		{
			kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_BattleScanner] = kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_BattleScanner] & 1;
		}
		if(!class'MiniModsStrategy'.static.IsLongWarBuild())
		{
			if(kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_FieldMedic] > 1 && !class'XGTacticalGameCoreNativeBase'.static.TInventoryHasItemType(kSoldier.GetCharacter().m_kChar.kInventory, eItem_Medikit) )
			{
				kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_FieldMedic] = kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_FieldMedic] & 1;
			}
		}
	}
	else
	{
		class'XGLoadoutMgr'.static.ConvertTInventoryToSoldierLoadout(kSoldier.GetCharacter().m_kChar, kSoldier.GetCharacter().m_kChar.kInventory, Loadout);
		if(kSoldier.GetCharacter().HasUpgrade(48))
		{
			if(!kSoldier.IsAugmented())
			{
				Loadout.Items[eSlot_RightChest] = 69; //Medikit to slot 9 (right chest), this is from LW
				arrAddItems.RemoveItem(69);
			}
		}
		while(arrAddItems.Length > 0)
		{
			if(arrAddItems[0] != 73 
			&& arrAddItems[0] != 77 
			&& arrAddItems[0] != 89 
			&& !kSoldier.GetInventory().HasItemOfType(EItemType(arrAddItems[0])))
			{
				iSlot = GetFirstFreeSlot(Loadout);
				if(iSlot != eSlot_RearBackPack)
				{
					Loadout.Items[iSlot] = arrAddItems[0];
					`Log("Added" @ string(EItemType(arrAddItems[0])) @ "to slot" @ string(ELocation(iSlot)), MMTactical.bDebugLog, name);
				}
				else
				{
					Loadout.Backpack.AddItem(arrAddItems[0]);
					`Log("Added" @ string(EItemType(arrAddItems[0])) @ "to backpack slot" @ Loadout.Backpack.Length, MMTactical.bDebugLog, name);
				}
				if(arrAddItems[0] == eItem_SmokeGrenade && kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_SmokeBomb] == 0)
					kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_SmokeBomb] += 2; //1 would be permanent, 2 is "from item"
				if(arrAddItems[0] == eItem_BattleScanner && kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_BattleScanner] == 0)
					kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_BattleScanner] += 2;//1 would be permanent, 2 is "from item"
				if(!class'MiniModsStrategy'.static.IsLongWarBuild())
				{
					if(arrAddItems[0] == eItem_Medikit && kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_FieldMedic] == 0)
						kSoldier.GetCharacter().m_kChar.aUpgrades[ePerk_FieldMedic] += 2;//1 would be permanent, 2 is "from item"
				}
			}
			arrAddItems.Remove(0,1);
		}
		class'XGLoadoutMgr'.static.ApplyLoadout(kSoldier, Loadout, false);
	}
}
function int GetFirstFreeSlot(TLoadout kLoadout)
{
	local array<ELocation> arrPossibleSlots;
	local ELocation eSlot;

	arrPossibleSlots.AddItem(eSlot_RightChest);
	arrPossibleSlots.AddItem(eSlot_LeftThigh);
	arrPossibleSlots.AddItem(eSlot_LeftChest);
	arrPossibleSlots.AddItem(eSlot_LeftBelt);
	arrPossibleSlots.AddItem(eSlot_RightForearm);
	arrPossibleSlots.AddItem(eSlot_RightSling);
	arrPossibleSlots.AddItem(eSlot_CenterChest);
	arrPossibleSlots.AddItem(eSlot_Claw_R);
	arrPossibleSlots.AddItem(eSlot_Claw_L);
	arrPossibleSlots.AddItem(eSlot_ChestCannon);
	arrPossibleSlots.AddItem(eSlot_KineticStrike);

	foreach arrPossibleSlots(eSlot)
	{
		if(kLoadout.Items[eSlot] < 1)
			return eSlot;
	}
	//emergency slot; this is generally a failure and ability from the item will not appear on HUD
	return eSlot_RearBackPack;
}
static function CleanUpDefaultSettings()
{
	local int iEntry;

	iEntry = default.PerkGivesItems.Length - 1;
	while(iEntry >= 0)
	{
		if(default.PerkGivesItems[iEntry].iPerk <= 0 || !IsValidConsumable(default.PerkGivesItems[iEntry].iItem))
		{
			default.PerkGivesItems.Remove(iEntry, 1);
		}
		--iEntry;
	}
	StaticSaveConfig();
}
static function bool IsValidConsumable(int iItem)
{
	local bool bValid;

	switch(iItem)
	{
	case 69:
	case 73:
	case 77:
	case 81:
	case 82:
	case 83:
	case 84:
	case 85:
	case 86:
	case 87:
	case 88:
	case 89:
	case 97:
		bValid = true;
		break;
	default:
		bValid = false;
	}
	return bValid;
}
static function TPerkToItem GetDemoSetting(int iSetting)
{
	local TPerkToItem tDemo;

	switch(iSetting)
	{
		//Deep Pockets grants 1 frag, smoke and flashbang
	case 1:
		tDemo.iPerk = 53;
		tDemo.iCharges = 1;
		tDemo.iItem = 81;
		break;
	case 2:
		tDemo.iPerk = 53;
		tDemo.iCharges = 1;
		tDemo.iItem = 82;
		break;
	case 3:
		tDemo.iPerk = 53;
		tDemo.iCharges = 1;
		tDemo.iItem = 83;
		break;
		//Smoke and Mirrors gives 1 flashbang
	case 4:
		tDemo.iPerk = 91;
		tDemo.iCharges = 1;
		tDemo.iItem = 83;
		break;
		//Field Medic grants 1 extra free use of Medikit
	case 5:
		tDemo.iPerk = 48;
		tDemo.iCharges = 1;
		tDemo.iItem = 69;
		break;
	default:
		tDemo.iPerk = 0;
		tDemo.iCharges = 0;
		tDemo.iItem = 0;
	}
	return tDemo;
}
DefaultProperties
{
}
