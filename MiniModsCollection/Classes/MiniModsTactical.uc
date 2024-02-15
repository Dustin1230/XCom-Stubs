class MiniModsTactical extends XComMutator
	dependson(MMCustomItemCharges)
	config(MiniMods);

struct TExaltAmmo
{
	var XGUnit kUnit;
	var int iAmmo;
	var int iTurnFired;
};
struct TScoutSenseInfo
{
    var int iDistance;
    var int iMessageID;
};

var config array<TScoutSenseInfo> ScoutSenseRange;
var localized string m_strScoutSenseMessage[7];
var XGRecapSaveData m_kSaveData;
var XGUnit m_kHelperUnit;
var int m_idx;
var string m_strCallback;
var int m_iWatchInfoPanel;
var int m_iWatchPlayerHandle;
var int m_iWatchUnitHandle;
var int m_iWatchGameSpeedHandle;
var int m_iWatchCovertHacker;
var int m_iWatchMovesHandle;
var int m_iWatchCurrAction;
var int m_iWatchTargetedActor;
var int m_iNumPermanentHumans;
var int m_iNumPermanentAliens;
var int m_iWatchMultishotTargets;
var int m_iWatchDropIns;
var int m_iWatchAbilitiesHUD;
var int m_iScoutAbilityIdx;
var int m_iWatchPathingPawnLoc;
var XComPathingPawn m_kTracedPathingPawn;
var MMCustomItemCharges m_kCustomCharges;
var config bool bDebugLog;
var config bool m_bFlashBombOnHackingArray;
var config bool m_bUnlimitedArrayHacks;
var config bool m_bRevealAll;
var config bool m_bPerksGiveItemCharges;
var config int FLASH_BOMB_AIM_PENALTY;
var config int FLASH_BOMB_TURNS_AFFECTING;
var config int FLASH_BOMB_CHANCE_AFFECTING;
var config bool m_bOfficerIronWill;
var config bool m_bFuelConsumption;
var config bool m_bFuelAnnounceBeginTurn;
var config float ADJUST_FUEL_MULTIPLIER;
var config int OTS_LEADER_RANGE;
var config bool m_bTilesCounterPopUp;
var config bool m_bAmmoCounter;
var config bool m_bAmmoCounterTextStyle;
var config bool m_bShowAmmoSpentByEnemies;
var config bool m_bSalvageMod;
var config bool m_bTurnCounter;
var config bool bRandomizeExtraSalvage;
var config bool m_bRangeAimModifiers;
var config bool m_bSequentialOverwatch;
var config bool m_bTakeOWShotsByDist;
var config bool m_bSplitSentinelOWShots;
var config bool m_bFasterRapidReaction;
var config bool m_bFasterCCS;
var config bool m_bAlwaysCoveringFire;
var config bool m_bSentinelCoveringFire;
var config bool m_bItchyTrigger;
var config bool m_bSmokeBlocksReactionFire;
var config bool m_bSmokeBlocksReactionFire_DenseOnly;
var config float m_fReactionDistanceThroughSmoke;
var config bool m_bShadowStep;
var config bool m_bShadowStepRequiresDash;
var config bool m_bDashGivesShadowStep;
var config bool m_bShadowStepOnlyOnMove;
var config array<int> m_arrShadowStepPerks;
var config array<int> m_arrShadowBusterPerks;
var config bool m_bScoutSense;
var config bool m_bScoutSenseScalesWithRank;
var config bool m_bScoutSensePersistentCues;
var config int m_iScoutSensePerk;
var config int m_iScoutSenseLvl1Rank;
var config int m_iScoutSenseLvl2Rank;
var config int m_iScoutSenseLvl3Rank;
var config int m_iScoutSenseMaxRange;
var config bool m_bFlashBangBlinds;
var config int m_iDisorientedSightRadius;
var config bool m_bNoCostCombatStims;
var config bool m_bNoCostGrapple;
var config bool m_bNoCostCommand;
var config int m_iGrappleCharges;
var config int m_iGrappleCooldown;
var config int ELERIUM_SALVAGE_COST;
var config int ALLOYS_SALVAGE_COST;
var config float ELERIUM_SALVAGE_MOD;
var config float ALLOYS_SALVAGE_MOD;
var config array<int> MissionTypeAllowed;
var config bool m_bAlienIconsMod;
var config bool m_bOWIcons;
var config float m_fLeaderIconMultiplier;
var config float m_fSquadSizeIconTransparency; //lol, should be SquadSight
var config bool m_bAllHitChanceOverIcons;
var config int m_iHUDColorCode_Aim;
var config int m_iHUDColorCode_Crit;
var config bool m_bKillsCounter;
var config bool m_bKillsAndXPDisplay;
var config bool m_bNoDeathMod;
var config float GAME_SPEED_TACTICAL;
var config float GAME_SPEED_MOD_STEP;
var config bool GAME_SPEED_SKIP_ACTION_CAM;
var config string weapon_test_path;
var config int weapon_test_itemtype;
var float MIN_GAME_SPEED;
var float MAX_GAME_SPEED;
var bool m_bForceGameSpeedPopup;
var config bool m_bLimitChainPanic;
var config array<int> IgnoredMoraleEvent;
var config bool m_bAltSightlineIndicator;
var config bool m_bAlienSightRings;
var config bool m_bAlienSightRingsPermanent;
var config bool m_bAlienSightRingsOnlyXcomTurn;
var config Color m_tSightRingColor;
var config bool m_bCompactHPDisplay;
var config bool m_bMoreGlamCam;
var config bool m_bGlamCam_Grapple;
var config bool m_bGlamCam_Rocket;
var localized string m_strSalvageTitle;
var localized string m_strSalvageBody;
var localized string m_strSalvageAccept;
var localized string m_strSalvageCancel;
var localized string m_strShadowStepping;
var localized string m_strShadowStepBuster;
var localized string m_strShadowStepBuffDesc;
var localized string m_strShadowStepDashSuffix;
var localized string m_strShadowStepMoveSuffix;
var localized string m_strReactionBlockedBySmoke;
var localized string m_strScoutSenseName;
var localized string m_strScoutSenseHelp;
var localized string m_strScoutSensePerkDesc;
var localized string m_strDistanceInTiles;
var localized string m_strScoutSenseRest;
var localized string m_strScoutSenseBeyondRange;
var localized string m_strGameSpeed;
var array<TExaltAmmo> m_arrExaltAmmo;
var array<MMUnitTracker> m_arrUnitTrackers;
var XGAbility_Targeted m_kHelperShot;
var bool m_bOverrideLWR;

function string GetDebugName()
{
	return GetItemName(string(Class)) @ class'MiniModsStrategy'.default.m_strBuildVersion;
}
event PostBeginPlay()
{
	`Log(GetFuncName() @ GetDebugName());
	if(OTS_LEADER_RANGE == 0)   //skip if already set from config file
	{
		OTS_LEADER_RANGE = 8; //otherwise ensure default value
	}
	ELERIUM_SALVAGE_MOD = FMax(1.0, default.ELERIUM_SALVAGE_MOD);
	ALLOYS_SALVAGE_MOD = FMax(1.0, default.ALLOYS_SALVAGE_MOD);
	if(default.ELERIUM_SALVAGE_COST <= 0 )
	{
		ELERIUM_SALVAGE_COST = class'MiniModsStrategy'.static.GetItemBalanceNormalFor(eItem_Elerium115).iCash * 2;
	}
	if(default.ALLOYS_SALVAGE_COST <= 0 )
	{
		ALLOYS_SALVAGE_COST = class'MiniModsStrategy'.static.GetItemBalanceNormalFor(eItem_AlienAlloys).iCash * 2;
	}
	class'MMCustomItemCharges'.static.CleanUpDefaultSettings();
	m_kCustomCharges = Spawn(class'MMCustomItemCharges');
	m_kCustomCharges.Init(self, false);
}
event Destroyed()
{
	m_kCustomCharges.Destroy();
}
event Tick(float fDelta)
{
	if(m_bKillsCounter && PRES() != none && PRES().GetTacticalHUD() != none && PRES().GetTacticalHUD().m_kMouseControls != none)
	{
		if(PRES().GetTacticalHUD().m_kMouseControls.manager.GetVariableString(PRES().GetTacticalHUD().m_kMouseControls.GetMCPath() $".hoverHelpDesc") != "")
		{
			GetKillsInfoBox().SetVisible(false);
		}
		else
		{
			GetKillsInfoBox().SetVisible(true);
		}
	}
}
simulated event OnCleanupWorld()
{
}
function CreateNewSaveData()
{
	if(m_kSaveData == none)
	{
		m_kSaveData = Spawn(class'XGRecapSaveData');
		m_kSaveData.m_aJournalEvents.AddItem("MiniModsCollection");
	}
}
function XGRecapSaveData GetSavedData()
{
	local bool bFound;
	local XGRecapSaveData kData;

	if(m_kSaveData == none)
	{
		foreach DynamicActors(class'XGRecapSaveData', kData)
		{
			if(kData.m_aJournalEvents.Find("MiniModsCollection") != -1)
			{
				bFound = true;
				m_kSaveData = kData;
				break;
			}
		}
		if(!bFound)
		{
			CreateNewSaveData();
		}
	}
	return m_kSaveData;
}
function RegisterWatchVariables()
{
	ConsoleCommand("set XGAction_Fire m_iTracerBeamShots -1");
	m_iWatchInfoPanel = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kGermanMode', self, OnInfoPanel);
    m_iWatchPlayerHandle = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(BATTLE(), 'm_kActivePlayer', self, OnActivePlayerChanged);
    m_iWatchUnitHandle = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(BATTLE().m_kActivePlayer, 'm_kActiveUnit', self, OnActiveUnitChanged);
	if((!IsLWR() || m_bOverrideLWR) && (class'XComModsProfile'.static.HasSetting("bModEnabled", "GameSpeedMod") || class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "GameSpeedMod")) )
	{
	    m_iWatchGameSpeedHandle = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(WorldInfo.Game, 'GameSpeed', self, ForceGameSpeed);
		GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(BATTLE().m_kGlamMgr, 'm_eGlamWaitStatus', self, ForceGameSpeed);
	    ForceGameSpeed();
	}
	GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kMissionSummary', self, OnBattleDone);
	GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(XGBattle_SP(GRI().GetBattle()).GetHumanPlayer().GetSquad(), 'm_iNumPermanentUnits', self, OnNewHumanUnit);
	GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(XGBattle_SP(GRI().GetBattle()).GetAIPlayer().GetSquad(), 'm_iNumPermanentUnits', self, OnNewAlienUnit);
	GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(GRI().m_kCameraManager, 'm_aLookAts', self, UpdateSightlineHUD);
	m_iNumPermanentHumans = XGBattle_SP(GRI().GetBattle()).GetHumanPlayer().GetSquad().GetNumPermanentMembers();
	m_iNumPermanentAliens = XGBattle_SP(GRI().GetBattle()).GetAIPlayer().GetSquad().GetNumPermanentMembers();
}
function PostLoadSaveGame(PlayerController Sender)
{
	local bool bFromPostLevelLoaded;

	if(!IsBattleReady())
	{
		SetTimer(1.00, false, GetFuncName());
		return;
	}
	bFromPostLevelLoaded = InStr(GetScriptTrace(), "PostLevelLoaded") != -1;
	RegisterWatchVariables();
	if(XGBattle_SPCovertOpsExtraction(BATTLE()) != none)
	{
		FixCovertOperative();
	}
	if(m_bPerksGiveItemCharges && !bFromPostLevelLoaded && GetSavedData().m_aJournalEvents.Find("UpdatedItemCharges") < 0)
	{
		//this is not during PostLevelLoaded and UpdatedItemCharges not yet ever called
		//so this is a load from initial AutoSave which was created before UpdateItemCharges had got fired
		m_kCustomCharges.UpdateItemCharges();
	}
	BuildCustomAbilities();
	AddCustomBindings();
	OnActivePlayerChanged();
	PollForBattleReady();
	TestStuff();
	XComContentManager(class'Engine'.static.GetEngine().GetContentManager()).RequestContentArchetype(1, 81);
}

function PostLevelLoaded(PlayerController Sender)
{
	local int i;
	local array<string> arrSaveRecords;

	CheckAdjustInitialFuel();
	//clear UpdatedItemCharges saved setting
	if(m_bPerksGiveItemCharges)
	{
		GetSavedData().m_aJournalEvents.RemoveItem("UpdatedItemCharges");
		m_kCustomCharges.UpdateItemCharges();
	}
	//clear all saved settings of XGUnit actors
	arrSaveRecords = GetSavedData().m_aJournalEvents;
	for(i=arrSaveRecords.Length-1; i >=0; --i)
	{
		if(InStr(arrSaveRecords[i], "XGUnit",,true) != -1)
		{
			arrSaveRecords.Remove(i, 1);
		}
	}
	PostLoadSaveGame(Sender);
}
function TestStuff(optional XGUnit kUnit)
{
	local MaterialInstanceConstant otherMIC/*, MIC*/;
	local XGUnit kSourceUnit;
	local bool bFound;
	local TextureParameterValue TPV;
	local VectorParameterValue VPV;
	local ScalarParameterValue SPV;
	local int i;
	local array<name> arrBones;
	//local LinearColor kColor;
	local MeshComponent MeshComp;
	local XComWeapon kWeapon;
	local skeletalmesh kSkelMesh;
	local Rotator rotAlt;
	//local XComGlamManager kGlamMgr;

	return;
	if(kUnit.GetInventory().GetActiveWeapon().m_eType == weapon_test_itemtype)
	{
		kWeapon = kUnit.GetInventory().GetActiveWeapon().GetEntity();
		if(kWeapon == none)
		{
			`log("error: no xcomweapon",,GetFuncName());
		}
		else
		{
			kSkelMesh = SkeletalMesh(DynamicLoadObject(weapon_test_path, class'SkeletalMesh'));
			`log("loaded new mesh successfully", kSkelMesh != none, GetFuncName());
			PRES().GetMessenger().Message("weapon package name" @ SkeletalMeshComponent(kWeapon.Mesh).SkeletalMesh.GetPackageName());
			PRES().GetMessenger().Message("model replacement pending");
			if(kSkelMesh != none)
			{
				SkeletalMeshComponent(kWeapon.Mesh).SetSkeletalMesh(kSkelMesh);
				rotAlt=kWeapon.RelativeRotation;
				rotAlt.Yaw +=50.0;
				kweapon.SetRelativeRotation(rotAlt);
				PRES().GetMessenger().Message("new weapon package name" @ SkeletalMeshComponent(kWeapon.Mesh).SkeletalMesh.GetPackageName());
			}
		}
	}
	return;
	MeshComp = kUnit.GetPawn().Mesh;
	SkeletalMeshComponent(MeshComp).GetBoneNames(arrBones);
	for(i=0; i<arrBones.Length; ++i)
	{
		`log(arrBones[i],,'PawnBoneName');
	}
	foreach DynamicActors(class'XGUnit', kSourceUnit)
	{
		if(kSourceUnit.IsAlien() && kSourceUnit.GetPawn().IsA('XComMuton'))
		{
			bFound=true;
			break;
		}
	}
	if(bFound)
	{
		LogInternal(GetFuncName() @ kSourceUnit);
		for(i=0; i< kSourceUnit.GetPawn().Mesh.SkeletalMesh.Materials.Length; ++i)
		{
			if(kSourceUnit.GetPawn().Mesh.SkeletalMesh.Materials[i].IsA('MaterialInstanceConstant'))
			{
				otherMIC = MaterialInstanceConstant(kSourceUnit.GetPawn().Mesh.SkeletalMesh.Materials[i]);
				LogInternal("Found" @ kSourceUnit.GetPawn() @ "mesh material" @ i @ otherMIC.Parent.Name);
				foreach otherMIC.TextureParameterValues(TPV)
				{
					LogInternal("Found TextureParameterValue" @ TPV.ParameterName @ Texture2D(TPV.ParameterValue).TextureFileCacheName);
				}
				foreach otherMIC.VectorParameterValues(VPV)
				{
					LogInternal("Found VectorParameterValue" @ VPV.ParameterName @ VPV.ParameterValue.R @ VPV.ParameterValue.G @ VPV.ParameterValue.B);
				}
				foreach otherMIC.ScalarParameterValues(SPV)
				{
					LogInternal("Found Scalar ParameterValue" @ SPV.ParameterName @ SPV.ParameterValue);
				}
			}
		}
		LogInternal(kSourceUnit @ "weapon UITextures.length" @ kSourceUnit.GetInventory().GetActiveWeapon().GetEntity().UITextures.Length);
		LogInternal(kSourceUnit @ "Weapon.SkeletalMesh.Materials.length" @ SkeletalMeshComponent(kSourceUnit.GetInventory().GetActiveWeapon().GetEntity().Mesh).SkeletalMesh.Materials.Length);
		if(SkeletalMeshComponent(kSourceUnit.GetInventory().GetActiveWeapon().GetEntity().Mesh).Attachments.Length > 0)
		{
			LogInternal(kSourceUnit @ "Weapon.Attachment[0]" @ SkeletalMeshComponent(kSourceUnit.GetInventory().GetActiveWeapon().GetEntity().Mesh).SkeletalMesh.Materials.Length);
		}
		foreach kSourceUnit.GetPawn().AllOwnedComponents(class'MeshComponent', MeshComp)
		{
			for(i=0; i< MeshComp.GetNumElements(); ++i)
			{					
				if(MeshComp.GetMaterial(i).IsA('MaterialInstanceConstant'))
				{
					otherMIC = MaterialInstanceConstant(MeshComp.GetMaterial(i));
					LogInternal("Found" @ kSourceUnit.GetPawn() @ MeshComp @ "material" @ i @ otherMIC.Parent.Name);
					foreach otherMIC.TextureParameterValues(TPV)
					{
						LogInternal("Found TextureParameterValue" @ TPV.ParameterName @ Texture2D(TPV.ParameterValue).TextureFileCacheName);
					}
					foreach otherMIC.VectorParameterValues(VPV)
					{
						LogInternal("Found VectorParameterValue" @ VPV.ParameterName @ VPV.ParameterValue.R @ VPV.ParameterValue.G @ VPV.ParameterValue.B);
					}
					foreach otherMIC.ScalarParameterValues(SPV)
					{
						LogInternal("Found Scalar ParameterValue" @ SPV.ParameterName @ SPV.ParameterValue);
					}
				}

			}
		}
		LogInternal(GetFuncName() @ kUnit);
		for(i=0; i< kUnit.GetPawn().Mesh.SkeletalMesh.Materials.Length; ++i)
		{
			if(kUnit.GetPawn().Mesh.SkeletalMesh.Materials[i].IsA('MaterialInstanceConstant'))
			{
				otherMIC = MaterialInstanceConstant(kUnit.GetPawn().Mesh.SkeletalMesh.Materials[i]);
				LogInternal("Found" @ kUnit.GetPawn() @ "mesh material" @ i @ otherMIC.Parent.Name);
				foreach otherMIC.TextureParameterValues(TPV)
				{
					LogInternal("Found TextureParameterValue" @ TPV.ParameterName);
				}
				foreach otherMIC.VectorParameterValues(VPV)
				{
					LogInternal("Found VectorParameterValue" @ VPV.ParameterName @ VPV.ParameterValue.R @ VPV.ParameterValue.G @ VPV.ParameterValue.B);
				}
				foreach otherMIC.ScalarParameterValues(SPV)
				{
					LogInternal("Found Scalar ParameterValue" @ SPV.ParameterName @ SPV.ParameterValue);
				}
			}
		}
		foreach kUnit.GetPawn().AllOwnedComponents(class'MeshComponent', MeshComp)
		{
			for(i=0; i<MeshComp.Materials.Length;++i)
			{
				if(MeshComp.GetMaterial(i).IsA('MaterialInstanceConstant'))
				{
					otherMIC = MaterialInstanceConstant(MeshComp.GetMaterial(i));
					LogInternal("Found" @ kUnit.GetPawn() @ MeshComp @ "material" @ i @ otherMIC.Parent.Name);
					foreach otherMIC.TextureParameterValues(TPV)
					{
						LogInternal("Found TextureParameterValue" @ TPV.ParameterName);
					}
					foreach otherMIC.VectorParameterValues(VPV)
					{
						LogInternal("Found VectorParameterValue" @ VPV.ParameterName @ VPV.ParameterValue.R @ VPV.ParameterValue.G @ VPV.ParameterValue.B);
					}
					foreach otherMIC.ScalarParameterValues(SPV)
					{
						LogInternal("Found Scalar ParameterValue" @ SPV.ParameterName @ SPV.ParameterValue);
					}
				}

			}
		}
		otherMIC = MaterialInstanceConstant(kSourceUnit.GetPawn().Mesh.GetMaterial(0));
//		otherMIC.SetTextureParameterValue('Diffuse', Texture2D(DynamicLoadObject("MiniMods.CharacterSkins.ThinMan_White_DIF", class'Texture2D')));
		//MIC = new (kUnit.GetPawn()) class'MaterialInstanceConstant';
		//MIC.SetParent(otherMIC);
//		MIC.SetTextureParameterValue('Diffuse', Texture2D(DynamicLoadObject("MiniMods.CharacterSkins.MutonSoldier_Blue_DIF", class'Texture2D')));
		otherMIC.SetTextureParameterValue('Diffuse', Texture2D(DynamicLoadObject("MiniMods.CharacterSkins.MutonSoldier_Blue_DIF", class'Texture2D')));
		//class'UIModUtils'.static.CopyTextureParameterValue('Diffuse', MIC, otherMIC);
		//class'UIModUtils'.static.CopyTextureParameterValue('Normal', MIC, otherMIC);
		//class'UIModUtils'.static.CopyTextureParameterValue('Detail_Normal', MIC, otherMIC);
		//class'UIModUtils'.static.CopyTextureParameterValue('Reflect', MIC, otherMIC);
		//class'UIModUtils'.static.CopyTextureParameterValue('Spc_Ems_Ref_Skn', MIC, otherMIC);
		//class'UIModUtils'.static.CopyVectorParameterValue('EmsColor_EmsValue', MIC, otherMIC);
		//class'UIModUtils'.static.CopyVectorParameterValue('RefColor_RefValue', MIC, otherMIC);
		//class'UIModUtils'.static.CopyVectorParameterValue('SpcColor_SpcGloss', MIC, otherMIC);
		//class'UIModUtils'.static.CopyScalarParameterValue('DtlNrm_Tile', MIC, otherMIC);
		//kUnit.GetPawn().Mesh.SetMaterial(0, otherMIC);

		//kColor.R=1.00;
		//kColor.G=3.00;
		//kColor.B=20.0;
		//MaterialInstanceConstant(kSourceUnit.GetPawn().Mesh.GetMaterial(0)).SetVectorParameterValue('EmsColor_EmsValue', kColor);  
		//kColor.R=10.0;
		//kColor.G=15.0;
		//kColor.B=20.0;
		//MaterialInstanceConstant(kSourceUnit.GetInventory().GetActiveWeapon().GetEntity().Mesh.GetMaterial(0)).SetVectorParameterValue('SpcColor_SpcGloss', kColor);  

		//kColor.R=0.02;
		//kColor.G=0.02;
		//kColor.B=0.95;
		//MaterialInstanceConstant(kUnit.GetInventory().GetActiveWeapon().GetEntity().Mesh.GetMaterial(0)).SetVectorParameterValue('Noise_Color', kColor);
		//MaterialInstanceConstant(kUnit.GetInventory().GetActiveWeapon().GetEntity().Mesh.GetMaterial(0)).SetScalarParameterValue('EmsValue', 8.0);  
		//MaterialInstanceConstant(kSourceUnit.GetPawn().Mesh.GetMaterial(0)).SetVectorParameterValue('RefColor_RefValue', kColor);
		//MaterialInstanceConstant(kSourceUnit.GetPawn().Mesh.GetMaterial(0)).SetVectorParameterValue('SpcColor_SpcGloss', kColor);

	}	
}
function DoFireworks(Vector vTargetLoc)
{
	local XComProjectile_FragGrenade kBomb;

	`Log(vTargetLoc.X @ vTargetLoc.Y @ vTargetLoc.Z,,GetFuncName());
	kBomb = Spawn(class'XComProjectile_FragGrenade', none,,vTargetLoc,,XComContentManager(class'Engine'.static.GetEngine().GetContentManager()).GetWeaponTemplate(81).ProjectileTemplate, false);
	kBomb.InitProjectile(vTargetLoc, false, false);//assume fired from the corner of the map
	kBomb.bWillDoDamage = false;
	kBomb.m_fLifeTime = 1.0;
	kBomb.SetLocation(vTargetLoc);
	kBomb.Explode(vTargetLoc, Normal(vTargetLoc));
}
static function AddCustomBindings()
{
	local KeyBind NewBinding;

	NewBinding.Name='Equals';
	NewBinding.Control=true;
	NewBinding.Command="Mutate GameSpeedIncrease";
	AddBinding(NewBinding);

	NewBinding.Name='Add';
	NewBinding.Control=true;
	NewBinding.Command="Mutate GameSpeedIncrease";
	AddBinding(NewBinding);

	NewBinding.Name='UnderScore';
	NewBinding.Control=true;
	NewBinding.Command="Mutate GameSpeedDecrease";
	AddBinding(NewBinding);

	NewBinding.Name='Subtract';
	NewBinding.Control=true;
	NewBinding.Command="Mutate GameSpeedDecrease";
	AddBinding(NewBinding);

	NewBinding.Name='R';
	NewBinding.Control=true;
	NewBinding.Command="Mutate ToggleAlienSightRings";
	AddBinding(NewBinding);

	NewBinding.Name='H';
	NewBinding.Control=true;
	NewBinding.Command="Mutate ToggleCompactHPDisplay";
	AddBinding(NewBinding);
}
static function AddBinding(KeyBind tBind)
{
	local PlayerInput kInput;

	kInput = class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().PlayerInput;
	kInput.Bindings[kInput.Bindings.Length] = tBind;
}
function PollForBattleReady()
{
	if(IsBattleReady())
	{
		PushState('Initing');
	}
	else
	{
		SetTimer(0.50, false, GetFuncName());
	}
}
function OnBattleReady()
{
	local UIUnitFlag kFlag;

	AttachTxtIconsToAlienHeads();
	AttachAmmoBars();
	UpdateSightlineHUD();
	UpdateWeaponHUD();
	UpdateKillsDisplay();

	foreach PRES().m_kUnitFlagManager.m_arrFlags(kFlag)
	{
		kFlag.RealizeHitPoints();
	}
}
//--------------------------------------------------------------------------
// UTILITY FUNCTIONS BLOCK
//--------------------------------------------------------------------------
static function WorldInfo GetWorldInfo()
{
	return class'Engine'.static.GetCurrentWorldInfo();
}

static function XComTacticalController PC()
{
	return XComTacticalController(TACTICAL().GetALocalPlayerController());
}

static function XComPresentationLayer PRES()
{
	return XComPresentationLayer(PC().m_Pres);
}

static function XComTacticalGame TACTICAL()
{
    return XComTacticalGame(GetWorldInfo().Game);
}

static function XComTacticalGRI GRI()
{
    return XComTacticalGRI(GetWorldInfo().GRI);
}

static function XGBattle BATTLE()
{
	return GRI().m_kBattle;
}
function bool IsBattleReady()
{
	local bool bXComLoaded, bAliensLoaded, bNeutralLoaded;
	local XGPlayer kPlayer;

	kPlayer = BATTLE().m_arrPlayers[0];
	if(kPlayer != none && kPlayer.GetSquad() != none)
	{
		bXComLoaded = true;
	}
	kPlayer = BATTLE().m_arrPlayers[1];
	if(kPlayer != none && kPlayer.GetSquad() != none)
	{
		bAliensLoaded = true;
	}
	kPlayer = BATTLE().m_arrPlayers[2];
	if(kPlayer != none && kPlayer.GetSquad() != none)
	{
		bNeutralLoaded = true;
	}
	return (BATTLE().AtBottomOfRunningStateBeginBlock() && BATTLE().m_bTacticalIntroDone &&  bAliensLoaded && bXComLoaded && bNeutralLoaded);
}
static function string GetParameterString(int iParameterID, string strParams, optional string strSeparator=",")
{
	local array<string> arrFunctParas;
	
	if(strParams != "")
	{
		ParseStringIntoArray(Split(strParams, ":", true), arrFunctParas, strSeparator, true);
		return arrFunctParas[iParameterID];
	}
}

static function actor GetActor(class<actor> ActorClass, string strName)
{
	local actor kActorToGet;

	foreach GetWorldInfo().DynamicActors(ActorClass, kActorToGet)
	{
		if(string(kActorToGet.Name) == strName)
		{
			break;
		}
	}
	return kActorToGet;
}
static function bool IsLWR()
{
	return class'UIModManager'.static.GetMutator("LWRebalance.RebalanceMutator") != none;
}
//--------------------------------------------------------------------------
// END OF UTILS
//--------------------------------------------------------------------------

function Mutate(String MutateString, PlayerController Sender)
{
	//`Log("Received call:" @ MutateString, bDebugLog, name);
	if(InStr(MutateString, "XGUnit.UpdateInteractClaim:") != -1)
	{
		OnUpdateInteractClaim(XGUnit(GetActor(class'XGUnit', GetParameterString(0, MutateString))) );
	}
	else if (MutateString == "XGPlayer.EndingTurn")
    {
		GetWorldInfo().MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchInfoPanel, false);
    }
	else if(MutateString == "TacticalDebugger.UpdateCurrAction")
	{
		//OnActiveUnitAction();
	}
	else if(InStr(MutateString, "XGAbility_Targeted.GetHitChance:") != -1)
	{
		//MutateGetHitChance(MutateString);
	}
	else if(InStr(MutateString, "GameSpeedIncrease") != -1)
	{
		GameSpeedUp();
	}
	else if(InStr(MutateString, "GameSpeedDecrease") != -1)
	{
		GameSpeedDown();
	}
	else if(InStr(MutateString, "ToggleAlienSightRings") != -1)
	{
		ToggleAlienSightRings();
	}
	else if(InStr(MutateString, "ToggleCompactHPDisplay") != -1)
	{
		ToggleCompactHPDisplay();
	}
	super.Mutate(MutateString, Sender);
}
function OnUpdateInteractClaim(XGUnit kUnit)
{
	local bool bHumanTurnBegin, bAlienTurnBegin, bTurnBegin;
	local string strTrace;

	if(!IsBattleReady() )
	{
		return;
	}
	strTrace = GetScriptTrace();
	bHumanTurnBegin = (InStr(strTrace, "XGPlayer:BeginningTurn") != -1);
	bAlienTurnBegin = (InStr(strTrace, "XGAIPlayer:BeginningTurn") != -1 && kUnit.IsAlien());
	bTurnBegin = bHumanTurnBegin || bAlienTurnBegin;
	
	`Log(kUnit @ "beginning" @ (BATTLE().IsAlienTurn() ? "alien" : "human" ) @ "turn" @ BATTLE().m_iTurn, bTurnBegin, 'MiniModsTactical');
	if(!BATTLE().IsAlienTurn())
	{
		UpdateWeaponHUD();
		UpdateKillsDisplay();
		SetTimer(0.20, false, 'UpdateSightlineHUD');
	}
	if(bHumanTurnBegin)
	{
		//start tracking interface; hunting F1 preview
		GetWorldInfo().MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchInfoPanel, true);
		OnActiveUnitChanged();
		if(m_bTurnCounter)
		{
			ShowTurnCount();
		}
	}
	if(bAlienTurnBegin)
	{
		GetUnitTrackerFor(kUnit).m_bStartedTurnUnseenToPlayer = kUnit.IsVisibleToTeam(eTeam_XCom);
	}
	if(bDebugLog)
	{
		LogDebugFlashBomb(kUnit);
	}
	GetUnitTrackerFor(kUnit).FixOWIconPosition();

	//GetUnitTrackerFor(kUnit).PopUpObjectsHP();
} 
function OnNewHumanUnit()
{
	local XGUnit kNewUnit;
	local XGSquad kSquad;
	local int iNewSquadSize;

	kSquad = XGBattle_SP(GRI().GetBattle()).GetHumanPlayer().GetSquad();
	iNewSquadSize = kSquad.GetNumPermanentMembers();
	while(m_iNumPermanentHumans < iNewSquadSize)
	{
		kNewUnit = kSquad.m_arrPermanentMembers[m_iNumPermanentHumans];
		if(m_bPerksGiveItemCharges)
		{
			m_kCustomCharges.UpdateItemCharges(false, kNewUnit);
		}
		if(kNewUnit.GetUnitFlightFuel() > 0)
		{
			AdjustInitialFuelFor(kNewUnit);
		}
		InitTrackerFor(kNewUnit);
		++ m_iNumPermanentHumans;
	}
}
function OnNewAlienUnit()
{
	local XGUnit kNewUnit;
	local XGSquad kSquad;
	local int iNewSquadSize;


	kSquad = XGBattle_SP(GRI().GetBattle()).GetAIPlayer().GetSquad();
	iNewSquadSize = kSquad.GetNumPermanentMembers();
	while(m_iNumPermanentAliens < iNewSquadSize)
	{
		kNewUnit = kSquad.m_arrPermanentMembers[m_iNumPermanentAliens];
		InitTrackerFor(kNewUnit);
		++ m_iNumPermanentAliens;
	}
}
function InitTrackerFor(XGUnit kUnit)
{
	local MMUnitTracker kNewTracker;

	kNewTracker = Spawn(class'MMUnitTracker');
	kNewTracker.Init(kUnit);
	m_arrUnitTrackers.AddItem(kNewTracker);
}
function MMUnitTracker GetUnitTrackerFor(XGUnit kUnit)
{
	local MMUnitTracker kTracker;

	foreach m_arrUnitTrackers(kTracker)
	{
		if(kTracker.m_kUnit == kUnit)
			break;
	}
	return kTracker;
}
function InitUnitTrackers()
{
	local XGUnit kUnit;

	foreach DynamicActors(class'XGUnit', kUnit)
	{
		if(kUnit.IsAlien_CheckByCharType() && (kUnit.GetTeam() == eTeam_Neutral || kUnit.m_eTeam == eTeam_Neutral) || kUnit.IsCivilian())
		{
			//this is a civilian or tracktwo's chryssalid/sectoid helper for Line Of Sight Indicator
			continue;
		}
		else
		{
			InitTrackerFor(kUnit);
		}
	}
}
/** DEPRECATED*/
function FlashBombOnHackingArray(string strParameters)
{
	local XComUIBroadcastWorldMessage kBroadcastWorldMessage;
	local XGUnit kCovertOp, kEnemy;
	local XComRadarArrayActor kArray;
	local array<XGUnit> arrExalt, arrDebuffed;
    local XComAlienPod kPod;
    local XGSquad kSquad;
	local XGAbility_FlashBang kFlashBang;
	local XGAbilityTree kAbilityTree;
	local XGAbility_Targeted kAbility;
    local int I;

	kCovertOp = XGUnit(GetActor(class'XGUnit', GetParameterString(1, strParameters)));
	kArray = XComRadarArrayActor(GetActor(class'XComRadarArrayActor', GetParameterString(0, strParameters)));
	kAbilityTree = GRI().m_kGameCore.m_kAbilities;

	kArray.SetActive(false);
	if(!m_bUnlimitedArrayHacks)
	{
		kCovertOp.m_bCovertHackerThisTurn = true;
	}
	GetWorldInfo().PlaySound(kArray.m_kHackingCue);
	foreach GRI().m_kBattle.m_kPodMgr.m_arrPod(kPod)
	{
		kPod.bNoMoveNextTurn = true;
	}    
	kSquad = GRI().m_kBattle.GetAIPlayer().GetSquad();
	for(I = 0; I < kSquad.GetNumMembers(); ++ I)
	{
		kEnemy = kSquad.GetMemberAt(I);
		if(kEnemy.IsExalt())
		{
			arrExalt.AddItem(kEnemy);
		}
	}
	foreach arrExalt(kEnemy)
	{
		if(Rand(100) >= FLASH_BOMB_CHANCE_AFFECTING)
		{
			continue;
		}
		//spawn FlashBang ability actor (individually for each victim)
		kFlashBang = XGAbility_FlashBang(kAbilityTree.SpawnAbility(15, kEnemy, arrExalt, none));
		kFlashBang.ClearMultiShotTargets();     //we want each flashbang apply only to one target
		kFlashBang.AddMultiShotTarget(kEnemy);  //set the sole target of flashbang to the enemy being processed
		kFlashBang.aTargetStats[1] = FLASH_BOMB_AIM_PENALTY;    //set aim-stat modifier - this one is used by native code
		kFlashBang.iDuration = FLASH_BOMB_TURNS_AFFECTING * 2 + 1;  //set duration (the counter is decreased at start and end of each player's turn)
		if(kEnemy.IsAffectedByAbility(15))
		{
			//remove current flash bang before applying a new one
			kAbility = kEnemy.FindAbilityAffecting(15);
			kAbilityTree.RemoveAbility(kAbility);
		}
		kEnemy.m_aCurrentStats[18] = 0;     //clear reaction stat (overwatch) of the enemy
		kEnemy.DebugVisibilityForSelf();    //this is relevant for suppressing enemy being interrupted
		kEnemy.m_bExaltHacked = true;       //this will make 'hacked' entry appear on the F1 preview
		kAbilityTree.ApplyAbilityToTarget(kFlashBang, kEnemy);  //this applies 'disoriented' effect to the enemy
		kAbilityTree.ApplyAbilityToSelf(kFlashBang);        //this sets the counter on the enemy
		arrDebuffed.AddItem(kEnemy);        //mark the target for further stuff performed below
	}
	kCovertOp.Unhide();
	foreach arrDebuffed(kEnemy)
	{
		kEnemy.UpdateUnitBuffs();   //put red arrow over the enemy pawn
		kBroadcastWorldMessage = PRES().GetWorldMessenger().Message(GRI().m_kGameCore.GetUnexpandedLocalizedMessageString(29), kEnemy.GetLocation(), 4,,, kEnemy.m_eTeamVisibilityFlags,,,, class'XComUIBroadcastWorldMessage_UnexpandedLocalizedString');
		if(kBroadcastWorldMessage != none)
		{
			XComUIBroadcastWorldMessage_UnexpandedLocalizedString(kBroadcastWorldMessage).Init_UnexpandedLocalizedString(29, kEnemy.GetLocation(), 4, kEnemy.m_eTeamVisibilityFlags);
		}
		if(kEnemy.IsDormant() && m_bRevealAll)
		{
			GRI().m_kBattle.m_kPodMgr.QueuePodReveal(kEnemy.m_kBehavior.m_kPod, kCovertOp, true);
		}
	}
	if(bDebugLog) //provide debug info
	{
		LogInternal("Count of exalt affected by flash bomb:" @ string(arrDebuffed.Length), 'MiniModsTactical');
		foreach arrExalt(kEnemy)
		{
			if(kEnemy.IsAffectedByAbility(15))
			{
				LogInternal(kEnemy.SafeGetCharacterFullName() $ "_" $ GetRightMost(kEnemy) @ "is affected by flash bang:" @ kEnemy.FindAbilityAffecting(15) $ ". Current Aim:" @ string(kEnemy.m_aCurrentStats[1]), 'MiniModsTactical');
				LogInternal(kEnemy.SafeGetCharacterFullName() @ "flash bang duration:" @ string(kEnemy.FindAbilityAffecting(15).iDuration));
			}
			else
			{
				LogInternal(kEnemy.SafeGetCharacterFullName() $ "_" $ GetRightMost(kEnemy) @ "is NOT affected by flash bang. Current Aim:" @ string(kEnemy.m_aCurrentStats[1]), 'MiniModsTactical');
			}
		}
	}
	m_strCallback = "Return"; //set callback message to skip original code
}
function OnActivePlayerChanged()
{
	if(!BATTLE().IsInState('Running') || !IsBattleReady())
	{
		SetTimer(0.30, false, GetFuncName());
		return;
	}
	if(m_iWatchUnitHandle > 0)
	{
		GetWorldInfo().MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchUnitHandle);
		m_iWatchUnitHandle = 0;
	}
	m_iWatchUnitHandle = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(BATTLE().m_kActivePlayer, 'm_kActiveUnit', self, OnActiveUnitChanged);
	OnActiveUnitChanged();
	if(!BATTLE().IsAlienTurn())
	{
		GetWorldInfo().MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchInfoPanel, true);
		UpdateFuel();
		UpdateExaltAmmo();
	}
	else
	{
		GetWorldInfo().MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchInfoPanel, false);
	}
}

function OnActiveUnitChanged()
{
	local XGUnit kUnit;
	
	if(!BATTLE().IsInState('Running') || !IsBattleReady() || BATTLE().IsInState('TransitioningPlayers'))
	{	
		SetTimer(0.10, false, GetFuncName());
		return;
	}
	kUnit = BATTLE().m_kActivePlayer.GetActiveUnit();
	if(kUnit != none)
	{
		if(m_iWatchMovesHandle > 0)
		{
			GetWorldInfo().MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchMovesHandle);
			m_iWatchMovesHandle = 0;
		}
		if(m_iWatchCurrAction > 0)
		{
			GetWorldInfo().MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchCurrAction);
			m_iWatchCurrAction = 0;
		}
		m_iWatchMovesHandle = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(kUnit, 'm_iMovesActionsPerformed', self, OnUnitMoved);
		m_iWatchCurrAction = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(kUnit, 'm_kCurrAction', self, UpdateCurrAction);
		UpdateCurrAction();
		if(!BATTLE().IsAlienTurn())
		{
			CheckForceLand(kUnit);
			AnnounceFuelFor(kUnit);
			//SetTimer(0.20, false, 'UpdateWeaponHUD');
			SetTimer(0.20, false, 'UpdateSightlineHUD');
			UpdateWeaponHUD();
			UpdateKillsDisplay();
			if(XGBattle_SPCovertOpsExtraction(BATTLE()) != none)
			{
				if(m_iWatchCovertHacker == 0 && kUnit.GetCharacter().m_kChar.aUpgrades[151] == 1)
				{
					m_iWatchCovertHacker = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(kUnit, 'm_bCovertHackerThisTurn', self, CheckRadarHack);
				}
				if(kUnit == XGBattle_SPCovertOpsExtraction(BATTLE()).GetCovertOperative())
				{
					UpdateExaltAmmo();
					GetWorldInfo().MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchCovertHacker, true);
				}
				else
				{
					GetWorldInfo().MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchCovertHacker, false);
				}
			}
		}
	}
}
function OnUnitMoved()
{
	local XGUnit kUnit;

	kUnit = BATTLE().m_kActivePlayer.GetActiveUnit();
	if(kUnit != none)
	{
		if(kUnit.IsMoving())
		{
			if(!IsTimerActive(GetFuncName()))
			{
				SetTimer(0.30, false, GetFuncName());
			}
			return;
		}
		if(!BATTLE().IsAlienTurn())
		{
			UpdateSquadLeaderProximity(kUnit);
			CheckForceLand(kUnit);
			if(BATTLE().IsA('XGBattle_SPCovertOpsExtraction') && kUnit == XGBattle_SPCovertOpsExtraction(BATTLE()).GetCovertOperative())
			{
				UpdateExaltAmmo();
			}
		}
	}
	UpdateSightlineHUD();
	TestStuff(kUnit);
}
function UpdateCurrAction()
{
	local XGUnit kUnit;
	local XGAction kAction;

	if(BATTLE().m_kActivePlayer.GetActiveUnit() != none)
	{
		kUnit = BATTLE().m_kActivePlayer.GetActiveUnit();
		kAction = kUnit.GetAction();
		if(!BATTLE().IsAlienTurn() && kAction != none && kAction.IsA('XGAction_Targeting'))
		{
			GetWorldInfo().MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchTargetedActor);
			m_iWatchTargetedActor = GetWorldInfo().MyWatchVariableMgr.RegisterWatchVariable(kAction, 'm_kTargetedEnemy', self, DistancePopUp);
			DistancePopUp();
		}
		else
		{
			PRES().GetWorldMessenger().RemoveMessage("DistancePopUp");
		}
		if(!BATTLE().IsAlienTurn())
		{
			if( kAction.IsA('XGAction_Equip') || kAction.IsA('XGAction_Reload') )
			{
				//SetTimer(0.50, false, 'UpdateWeaponHUD');
				UpdateWeaponHUD();
				UpdateSightlineHUD();
			}
			else if(kAction.IsA('XGAction_Path'))
			{
				TracePathingPawn(m_bAltSightlineIndicator);
			}
			else
			{
				TracePathingPawn(false);
			}
		}
		UpdateKillsDisplay();
	}
}
function DistancePopUp()
{
	local XGUnit kUnit, kTarget;
	
	UpdateSightlineHUD();
	if(!m_bTilesCounterPopUp)
	{
		return;
	}
	kUnit = BATTLE().m_kActivePlayer.GetActiveUnit();
	kTarget = XGAction_Targeting(kUnit.GetAction()).m_kTargetedEnemy;
	if(kTarget != none && kTarget != kUnit)
	{
		PRES().GetWorldMessenger().RemoveMessage("DistancePopUp");
		PRES().GetWorldMessenger().Message(string(int(VSize(kTarget.GetLocation() - kUnit.GetLocation())/96.0)) @ "Tiles", kTarget.GetPawn().GetHeadshotLocation(), eColor_Cyan, 1 , "DistancePopUp",kUnit.m_eTeamVisibilityFlags,,, 60.0);
	}
}
function TracePathingPawn(bool bEnable)
{
	if(bEnable && BATTLE().m_kActivePlayer.GetActiveUnit().GetPathingPawn() == m_kTracedPathingPawn)
	{
		return;
	}
	if(m_iWatchPathingPawnLoc != -1)
	{
		Worldinfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iWatchPathingPawnLoc);
		m_iWatchPathingPawnLoc = -1;
	}
	if(bEnable)
	{
		m_kTracedPathingPawn = BATTLE().m_kActivePlayer.GetActiveUnit().GetPathingPawn();
		m_iWatchPathingPawnLoc = Worldinfo.MyWatchVariableMgr.RegisterWatchVariable(m_kTracedPathingPawn.Path, 'AdjustedDestination', self, OnPathDestinationChanged);
		//class'XComWorldData'.static.GetWorldData().RegisterActor(m_kTracedPathingPawn, 6, vect(0.0, 0.0, 64.0));
		OnPathDestinationChanged();
	}
}
function OnPathDestinationChanged()
{
	local int i;

	if(m_kTracedPathingPawn.HasValidNonZeroPath())
	{
		ClearTimer(GetFuncName());
		for(i=0; i < m_arrUnitTrackers.Length; ++i)
		{
			m_arrUnitTrackers[i].UpdateVisibilityIndicator();
		}
	}
	else
	{
		SetTimer(0.10, false, GetFuncName());
	}
}
function PopUpCoverInfo()
{
	local XComCoverPoint kCover;
	local string sMsg;
	local int i, x, y, z;
	local vector vLoc;

	ClearTimer(GetFuncName());
	if(m_kTracedPathingPawn.HasValidNonZeroPath())
	{
		vLoc = m_kTracedPathingPawn.GetPathDestinationLimitedByCost();
		class'XComWorldData'.static.GetWorldData().GetFloorTileForPosition(vLoc, x, y, z);
		vLoc = class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(x, y, z);
		class'XComWorldData'.static.GetWorldData().GetCoverPoint(vLoc, kCover);
		sMsg = "("$x$","$y$","$z$")";
		for(i=15; i>=0; --i)
		{
			if(i % 4 == 3)
			{
				sMsg @= kCover.Flags >> i & 1;
			}
			else
			{
				sMsg $= kCover.Flags >> i & 1;
			}
		}
		PRES().GetMessenger().Message(sMsg);
	}
}
function CheckAdjustInitialFuel()
{
	local int iMember;
	local XGUnit kUnit;
    local XComUIBroadcastWorldMessage kBroadcastWorldMessage;

	if(!m_bFuelConsumption || !(ADJUST_FUEL_MULTIPLIER > 0.0))
	{
		return;
	}
	if(!IsBattleReady())
	{
		SetTimer(1.0, false, GetFuncName());
		return;
	}
	else
	{
		ClearTimer(GetFuncName());
		kUnit = BATTLE().m_kActivePlayer.GetActiveUnit();
		for(iMember = 0; iMember < kUnit.GetPlayer().GetSquad().GetNumMembers(); ++iMember)
		{
			kUnit = kUnit.GetPlayer().GetSquad().GetMemberAt(iMember);
			if(kUnit.GetUnitFlightFuel() > 0)
			{
				AdjustInitialFuelFor(kUnit);
				if(kUnit.IsActiveUnit() && m_bFuelAnnounceBeginTurn)
				{
					kBroadcastWorldMessage = PRES().GetWorldMessenger().Message(class'XComUIBroadcastWorldMessage_HoverFuel'.static.GetHoverFuelText(1, kUnit.GetUnitFlightFuel(), kUnit.GetUnitMaxFlightFuel()), kUnit.GetLocation(), 3,,, kUnit.m_eTeamVisibilityFlags,,,, class'XComUIBroadcastWorldMessage_HoverFuel');
					if(kBroadcastWorldMessage != none)
					{
						XComUIBroadcastWorldMessage_HoverFuel(kBroadcastWorldMessage).Init_HoverFuel(1, kUnit.GetUnitFlightFuel(), kUnit.GetUnitMaxFlightFuel(), kUnit.GetLocation(), 3, kUnit.m_eTeamVisibilityFlags);
					}
				}
			}
		}
		AdjustCoreArmorFuel();
	}
}
function AdjustInitialFuelFor(XGUnit kUnit)
{
	kUnit.m_aInventoryStats[17] *= ADJUST_FUEL_MULTIPLIER;
	kUnit.GetCharacter().m_kChar.aStats[17] *= ADJUST_FUEL_MULTIPLIER;
	kUnit.SetUnitFlightFuel(kUnit.GetUnitMaxFlightFuel());
}
static function AdjustCoreArmorFuel()
{
	local int iSeraphFuel, iArchangelFuel, iShivFuel, idx;

	idx = class'XGTacticalGameCore'.default.Armors.Find('iType', 67);
	iSeraphFuel = class'XGTacticalGameCore'.default.Armors[idx].iFlightFuel;

	idx = class'XGTacticalGameCore'.default.Armors.Find('iType', eItem_ArmorArchangel);
	iArchangelFuel = class'XGTacticalGameCore'.default.Armors[idx].iFlightFuel;

	idx = class'XGTacticalGameCore'.default.Armors.Find('iType', eItem_SHIVDeck_III);
	iShivFuel = class'XGTacticalGameCore'.default.Armors[idx].iFlightFuel;

	if(XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore != none)
	{
		XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_arrArmors[67].iFlightFuel = int(float(iSeraphFuel) * default.ADJUST_FUEL_MULTIPLIER);
		XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_arrArmors[eItem_ArmorArchangel].iFlightFuel = int(float(iArchangelFuel) * default.ADJUST_FUEL_MULTIPLIER);
		XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_arrArmors[eItem_SHIVDeck_III].iFlightFuel = int(float(iShivFuel) * default.ADJUST_FUEL_MULTIPLIER);
	}
}
function UpdateFuel()
{
    local XComUIBroadcastWorldMessage kBroadcastWorldMessage;
    local array<XGUnit> arrFliers;
	local int iMember;
	local XGUnit kUnit;
	
	if(!m_bFuelConsumption)
	{
		return;
	}
	if( BATTLE().IsInState('TransitioningPlayers') || !(BATTLE().IsInState('Running') && BATTLE().AtBottomOfRunningStateBeginBlock()) || IsTimerActive('CheckAdjustInitialFuel'))
	{
		SetTimer(1.0, false, GetFuncName());
		return;
	}
	else
	{
		kUnit = BATTLE().m_kActivePlayer.GetActiveUnit();
		if(kUnit != none)
		{
			for(iMember = 0; iMember < kUnit.GetPlayer().GetSquad().GetNumMembers(); ++iMember)
			{
				kUnit = kUnit.GetPlayer().GetSquad().GetMemberAt(iMember);
				if(kUnit.IsFlying())
				{
					arrFliers.AddItem(kUnit);
				}
			}
			foreach arrFliers(kUnit)
			{
				kUnit.SetUnitFlightFuel(kUnit.GetUnitFlightFuel() + kUnit.GetFlightFuelCost());
				CheckForceLand(kUnit);
				kBroadcastWorldMessage = PRES().GetWorldMessenger().Message(class'XComUIBroadcastWorldMessage_HoverFuel'.static.GetHoverFuelText(1, kUnit.GetUnitFlightFuel(), kUnit.GetUnitMaxFlightFuel()), kUnit.GetLocation(), 3,,, kUnit.m_eTeamVisibilityFlags,,,, class'XComUIBroadcastWorldMessage_HoverFuel');
				if(kBroadcastWorldMessage != none)
				{
					XComUIBroadcastWorldMessage_HoverFuel(kBroadcastWorldMessage).Init_HoverFuel(1, kUnit.GetUnitFlightFuel(), kUnit.GetUnitMaxFlightFuel(), kUnit.GetLocation(), 3, kUnit.m_eTeamVisibilityFlags);
				}
			}
		}
	}
}
function CheckForceLand(XGUnit kUnit)
{
    local Vector vHitLoc, vHitNormal;

	if(kUnit.IsFlying() && kUnit.GetUnitFlightFuel() < -kUnit.GetFlightFuelCost())
	{
		if(!m_bFuelConsumption)
		{
			return;
		}
		kUnit.SetUnitFlightFuel(0);
		if(!kUnit.m_kPawn.NavTraceBelowSelf(-1024.0, vHitLoc, vHitNormal))
		{
			vHitLoc = GRI().GetClosestValidLocation(vHitLoc, kUnit, false);
		}
		kUnit.AddFlightToggleAction(false, vHitLoc);
		SetTimer(0.30, false, 'OnUnitMoved');
	}
	else if(InStr(GetScriptTrace(), "Active.Activate") != -1 && !GRI().GetBattle().IsAlienTurn() && GRI().GetBattle().IsInState('Running'))
	{
		//AnnounceFuelFor(kUnit);
	}
}
function AnnounceFuelFor(XGUnit kUnit)
{
    local XComUIBroadcastWorldMessage kBroadcastWorldMessage;
	
    if(!m_bFuelAnnounceBeginTurn || IsTimerActive('CheckAdjustInitialFuel') || kUnit.GetUnitMaxFlightFuel() == 0)
    {
		return;
    }
	kBroadcastWorldMessage = PRES().GetWorldMessenger().Message(class'XComUIBroadcastWorldMessage_HoverFuel'.static.GetHoverFuelText(1, kUnit.GetUnitFlightFuel(), kUnit.GetUnitMaxFlightFuel()), kUnit.GetLocation(), 3,,, kUnit.m_eTeamVisibilityFlags,,,, class'XComUIBroadcastWorldMessage_HoverFuel');
	if(kBroadcastWorldMessage != none)
	{
		XComUIBroadcastWorldMessage_HoverFuel(kBroadcastWorldMessage).Init_HoverFuel(1, kUnit.GetUnitFlightFuel(), kUnit.GetUnitMaxFlightFuel(), kUnit.GetLocation(), 3, kUnit.m_eTeamVisibilityFlags);
	}
}
function FixCovertOperative()
{
	local int i;
	local XGSquad kXcomSquad;

	if(XGBattle_SPCovertOpsExtraction(BATTLE()).GetCovertOperative() == none && IsBattleReady())
	{
		kXcomSquad=BATTLE().GetEnemySquad(BATTLE().GetAIPlayer());
		for(i=0; i < kXcomSquad.GetNumMembers(); ++i)
		{
			if(kXcomSquad.GetMemberAt(i).GetCharacter().m_kChar.aUpgrades[151] > 0)
			{
				XGBattle_SPCovertOpsExtraction(BATTLE()).m_kCovertOperative = kXcomSquad.GetMemberAt(i);
				break;
			}
		}
	}
}
function UpdateExaltAmmo()
{
	local XGUnit kEnemy;
	local array<XGUnit> arrExalt;
	local TExaltAmmo kAmmoData;
	
	if(!m_bFlashBombOnHackingArray || !BATTLE().IsA('XGBattle_SPCovertOpsExtraction') )
	{
		return;
	}
	m_arrExaltAmmo.Length = 0;
	arrExalt = GetExaltSquad();
	foreach arrExalt(kEnemy)
	{
		kAmmoData.kUnit = kEnemy;
		kAmmoData.iAmmo = kEnemy.GetInventory().GetPrimaryWeapon().iAmmo;
		kAmmoData.iTurnFired = kEnemy.GetInventory().GetPrimaryWeapon().m_iTurnFired;
		m_arrExaltAmmo.AddItem(kAmmoData);
	}
}
function array<XGUnit> GetExaltSquad()
{
	local XGUnit kEnemy;
	local XGSquad kEnemySquad;
	local array<XGUnit> arrExalt;
	local int i;

	kEnemySquad = BATTLE().GetAIPlayer().GetSquad();
	for(i=0; i < kEnemySquad.GetNumMembers(); ++i)
	{
		kEnemy = kEnemySquad.GetMemberAt(i);
		if(kEnemy.IsExalt() && !kEnemy.IsDead())
		{
			arrExalt.AddItem(kEnemy);
		}
	}
	return arrExalt;
}
function CheckRadarHack()
{
	local XGUnit kCovertOp, kEnemy;
	local array<XGUnit> arrExalt;
	local XGAbility_FlashBang kFlashBang;
	local XGAbilityTree kAbilityTree;
	local XGAbility_Targeted kAbility;
	local XComUIBroadcastWorldMessage kBroadcastWorldMessage;
	local int i;

	if(!m_bFlashBombOnHackingArray)
	{
		return;
	}
	kCovertOp = XGBattle_SPCovertOpsExtraction(BATTLE()).GetCovertOperative();
	if(kCovertOp.m_bCovertHackerThisTurn)
	{
		kAbilityTree = GRI().m_kGameCore.m_kAbilities;
		arrExalt = GetExaltSquad();
		foreach arrExalt(kEnemy)
		{
			//restore all Exalts' ammo to previously stored values 
			for(i=0; i<m_arrExaltAmmo.Length; ++i)
			{
				if(kEnemy == m_arrExaltAmmo[i].kUnit)
				{
					kEnemy.GetInventory().GetPrimaryWeapon().iAmmo = m_arrExaltAmmo[i].iAmmo;
					kEnemy.GetInventory().GetPrimaryWeapon().m_iTurnFired = m_arrExaltAmmo[i].iTurnFired;
					kEnemy.EndWeaponDisabled();
				}
			}
			if(Rand(100) >= FLASH_BOMB_CHANCE_AFFECTING)
			{
				continue;
			}
			//spawn FlashBang ability actor (individually for each victim)
			kFlashBang = XGAbility_FlashBang(kAbilityTree.SpawnAbility(15, kEnemy, arrExalt, none));
			kFlashBang.ClearMultiShotTargets();     //we want each flashbang apply only to one target
			kFlashBang.AddMultiShotTarget(kEnemy);  //set the sole target of flashbang to the enemy being processed
			kFlashBang.aTargetStats[1] = FLASH_BOMB_AIM_PENALTY;    //set aim-stat modifier - this one is applied later by native code
			kFlashBang.iDuration = FLASH_BOMB_TURNS_AFFECTING * 2 + 1;  //set duration (the counter is decreased at start and end of each player's turn)
			if(kEnemy.IsAffectedByAbility(15))
			{
				//remove current flash bang before applying a new one
				kAbility = kEnemy.FindAbilityAffecting(15);
				kAbilityTree.RemoveAbility(kAbility);
			}
			kAbilityTree.ApplyAbilityToTarget(kFlashBang, kEnemy);  //this applies 'disoriented' effect to the enemy
			kAbilityTree.ApplyAbilityToSelf(kFlashBang);        //this sets the counter on the enemy
			kEnemy.UpdateUnitBuffs();   //put red arrow over the enemy pawn
	
			kBroadcastWorldMessage = PRES().GetWorldMessenger().Message(GRI().m_kGameCore.GetUnexpandedLocalizedMessageString(29), kEnemy.GetLocation(), 4,,, kEnemy.m_eTeamVisibilityFlags,,,, class'XComUIBroadcastWorldMessage_UnexpandedLocalizedString');
			if(kBroadcastWorldMessage != none)
			{
				XComUIBroadcastWorldMessage_UnexpandedLocalizedString(kBroadcastWorldMessage).Init_UnexpandedLocalizedString(29, kEnemy.GetLocation(), 4, kEnemy.m_eTeamVisibilityFlags);
			}
			if(kEnemy.IsDormant() && m_bRevealAll)
			{
				GRI().m_kBattle.m_kPodMgr.QueuePodReveal(kEnemy.m_kBehavior.m_kPod, kCovertOp, true);
			}
		}
		if(m_bUnlimitedArrayHacks)
		{
			kCovertOp.m_bCovertHackerThisTurn = false;
		}
	}
	if(bDebugLog) //provide debug info
	{
		`Log("Count of exalt affected by flash bomb:" @ string(arrExalt.Length),, 'MiniModsTactical');
		foreach arrExalt(kEnemy)
		{
			`Log(kEnemy.SafeGetCharacterFullName() $ "_" $ GetRightMost(kEnemy) @ "is affected by flash bang:" @ kEnemy.FindAbilityAffecting(15) $ ". Current Aim:" @ string(kEnemy.m_aCurrentStats[1]), kEnemy.IsAffectedByAbility(15), 'MiniModsTactical');
			`Log(kEnemy.SafeGetCharacterFullName() @ "flash bang duration:" @ string(kEnemy.FindAbilityAffecting(15).iDuration), kEnemy.IsAffectedByAbility(15), 'MiniModsTactical');
			`Log(kEnemy.SafeGetCharacterFullName() $ "_" $ GetRightMost(kEnemy) @ "is NOT affected by flash bang. Current Aim:" @ string(kEnemy.m_aCurrentStats[1]), !kEnemy.IsAffectedByAbility(15), 'MiniModsTactical');
		}
	}		
}
function LogDebugFlashBomb(XGUnit kUnit)
{
	if(XGBattle_SPCovertOpsExtraction(GRI().m_kBattle) != none)
	{
		`Log("Found EXALT unit" @ kUnit.SafeGetCharacterFullName() $ "_" $ GetRightMost(kUnit), kUnit.IsExalt());
		`Log("Unit is affected by flash bomb?" @ string(kUnit.IsAffectedByAbility(15)), kUnit.IsExalt());
		`Log("Flash bomb duration:" @ string(kUnit.FindAbilityAffecting(15).iDuration), kUnit.IsExalt());
	}
}
function UpdateSquadLeaderProximity(XGUnit kUnit)
{
	local XGUnit kSquadLeader, kOther;
	local XGSquad kSquad;
	local int I;
	local float fDistTiles;
	
	if(!m_bOfficerIronWill)
	{
		return;
	}
	//skip if not XCom Soldier or this is not on 'ProcessNewPosition' - or leader is dead/down
	if(kUnit.GetCharType() != 2 || InStr(GetScriptTrace(), "NewPosition",,true) < 0 || !kUnit.IsAliveAndWell())
	{
		return;
	}
	kSquad = kUnit.GetPlayer().GetSquad();
	kSquadLeader = kSquad.GetSquadLeader();
	if(kUnit != kSquadLeader)
	{
		fDistTiles = VSize2D(kUnit.GetLocation() - kSquadLeader.GetLocation()) / 96.0;
		//`Log(kUnit.SafeGetCharacterFullName() @ " tiles to leader:" @ int(fDistTiles), bDebugLog, name);
		if( fDistTiles <= OTS_LEADER_RANGE )
		{
			if(!kUnit.HasSquadLeaderOTSBonus() && kSquadLeader.IsAliveAndWell())
			{
				if(kSquadLeader.m_aCurrentStats[eStat_Will] > kUnit.m_aCurrentStats[eStat_Will])
				{
					kUnit.m_aCurrentStats[eStat_Will] = kSquadLeader.m_aCurrentStats[eStat_Will];
				}
			}
		}
		else
		{
			kUnit.m_aCurrentStats[eStat_Will] = kUnit.GetCharacter().GetCharMaxStat(eStat_Will) + kUnit.m_aInventoryStats[eStat_Will];
		}
	}
	else
	{
		for(I = 0; I < kSquad.GetNumMembers(); ++ I)
		{
			kOther = kSquad.GetMemberAt(I);
			if(kOther == kUnit || !kOther.IsAliveAndWell())
			{
				continue;
			}
			fDistTiles = VSize2D(kOther.GetLocation() - kSquadLeader.GetLocation()) / 96.0;
			//`Log(kOther.SafeGetCharacterFullName() @ " tiles to leader:" @ int(fDistTiles), bDebugLog, name);
			if( fDistTiles <= OTS_LEADER_RANGE )
			{
				if(!kOther.HasSquadLeaderOTSBonus())
				{
					if(kSquadLeader.m_aCurrentStats[eStat_Will] > kOther.m_aCurrentStats[eStat_Will])
					{
						kOther.m_aCurrentStats[eStat_Will] = kSquadLeader.m_aCurrentStats[eStat_Will];
					}
				}
			}
			else
			{
				kOther.m_aCurrentStats[eStat_Will] = kOther.GetCharacter().GetCharMaxStat(eStat_Will) + kOther.m_aInventoryStats[eStat_Will];
			}
		}
	}
}

function OnInfoPanel()
{
	if(PRES().IsInState('State_GermanMode'))
	{
		PushState('ModdingInfoPanel');
	}
	else if(IsInState('ModdingInfoPanel'))
	{
		PopState();
	}
}
function AttachTxtIconsToAlienHeads()
{
	local GfxObject gfxIcon, gfxText;
	local int i;

	for(i=0; i<20; ++i)
	{
		gfxIcon = PRES().GetHUD().GetVariableObject("_level0.theInterfaceMgr.gfxSightlineHUD.theSightlineHUD.theSightlineContainer.icon" $ i);
		if(gfxIcon != none && gfxIcon.GetObject("ExtraTextBox") == none)
		{
			gfxText = class'UIModUtils'.static.AttachTextFieldTo(gfxIcon, "ExtraTextBox",-1.0,-1.0,18.0,18.0);
			gfxText.SetFloat("_xscale", 50.0);
			gfxText.SetFloat("_yscale", 50.0);
			gfxText.SetVisible(false);
		}
	}
}
function SetEnemyIconTxt(GFxObject gfxIcon, string strTxt)
{
	local UIModGfxTextField gfxBox;

	gfxBox = UIModGfxTextField(gfxIcon.GetObject("ExtraTextBox", class'UIModGfxTextField'));
	if(gfxBox != none)
	{
		if(strTxt != "")
		{
			gfxBox.SetHTMLText(strTxt);
			gfxBox.SetVisible(true);
		}
		else
		{
			gfxBox.SetVisible(false);
		}
	}
}
function UpdateSightlineHUD()
{
	local GfxObject gfxIcon;
	local UISightlineHUD_SightlineContainer kHUD;
	local int iEnemy, iHit, iCritHit;
	local XGUnit kUnit, kEnemy;
	local XGAbility_Targeted kHelperShot;

	kUnit= GRI().GetBattle().m_kActivePlayer.GetActiveUnit();
	kHUD = PRES().m_kSightlineHUD.m_kSightlineContainer;
	if(kUnit == none || kHUD.m_arrEnemies.Length == 0 || BATTLE().IsAlienTurn())
	{
		return;
	}
	for(iEnemy=0; iEnemy < kHUD.m_arrEnemies.Length; ++iEnemy)
	{
		gfxIcon = PRES().GetHUD().GetVariableObject("_level0.theInterfaceMgr.gfxSightlineHUD.theSightlineHUD.theSightlineContainer.icon" $ iEnemy);
		kEnemy = XGUnit(kHUD.m_arrEnemies[iEnemy]);
		SetHeadIconTransparency(gfxIcon, (!m_bAlienIconsMod || kUnit.m_arrVisibleEnemies.Find(kEnemy) >= 0 ) ? 1.0 : (1.0 - m_fSquadSizeIconTransparency));
		//squad sight icon scaling:
		if(m_bAlienIconsMod && kEnemy.IsAlien_CheckByCharType() && kEnemy.m_iProximityMines != 0)
		{
			//positive m_iProximityMines (for an alien) marks a leader/navigator and will scale the alien's pawn
			ScaleHeadIcon(gfxIcon, m_fLeaderIconMultiplier);
		}
		else
		{
			ScaleHeadIcon(gfxIcon, 1.0);
		}
		//OW helper indicators
		if(m_bAlienIconsMod && m_bOWIcons && kEnemy.m_aCurrentStats[eStat_Reaction] > 0)
		{
			SetEnemyIconTxt(gfxIcon, "<img src='Icon_OVERWATCH_HTML' width='14' height='14'>");
		}
		else if(m_bAlienIconsMod && m_bOWIcons && kUnit.IsSuppressedBy(kEnemy))
		{
			SetEnemyIconTxt(gfxIcon, "<img src='img:///gfxWorldMessageMgr.Icon_SUPRESSION_HTML' width='14' height='14'>");
		}
		else
		{
			SetEnemyIconTxt(gfxIcon, "");
		}
		//all hit/crit chance helpers
		if(m_bAlienIconsMod && m_bAllHitChanceOverIcons)
		{
			if(XGAction_Targeting(kUnit.GetAction()) != none && XGAction_Targeting(kUnit.GetAction()).m_kShot != none && XGAction_Targeting(kUnit.GetAction()).m_kShot.ShouldShowPercentage())
			{
				kHelperShot = XGAbility_Targeted(kUnit.FindAbility(XGAction_Targeting(kUnit.GetAction()).m_kShot.iType, kEnemy));
			}
			else
			{
				kHelperShot = XGAbility_Targeted(kUnit.FindAbility(7, kEnemy));
			}
			if(kHelperShot != none)
			{
				kHelperShot.GetUIHitChance(iHit, iCritHit);
				gfxIcon.getObject("tf").SetBool("multiline", true);
				gfxIcon.getObject("tf").SetBool("html", true);
				gfxIcon.GetObject("tf").SetString("htmlText", class'UIUtilities'.static.GetHTMLColoredText(string(iCritHit)$"%", m_iHUDColorCode_Crit) $ "\n\n" $ class'UIUtilities'.static.GetHTMLColoredText(string(iHit)$"%", m_iHUDColorCode_Aim));
				gfxIcon.GetObject("tf").SetVisible(true);
			}
		}
	}
}
function ScaleHeadIcon(GfxObject gfxIcon, float fScaleMultiplier)
{
	local float fScale;

	if(class'MiniModsStrategy'.static.IsLongWarBuild())
	{
		fScale = 233.0; //this is the default scale of head icons
		gfxIcon.SetFloat("_xscale", fScale * fScaleMultiplier);
		gfxIcon.SetFloat("_yscale", fScale * fScaleMultiplier);
	}
}
function SetHeadIconTransparency(GfxObject gfxIcon, float fAlpha)
{
	class'UIModUtils'.static.ObjectMultiplyColor(gfxIcon, gfxIcon.GetColorTransform().multiply.R,gfxIcon.GetColorTransform().multiply.G,gfxIcon.GetColorTransform().multiply.B, fAlpha);
}
function AttachAmmoBars()
{
	local GFxObject gfxWeaponPanel, gfxAmmoBar;
	local MMGfxAmmoBar gfxMyAmmoBar;
	if(PRES().GetHUD().GetVariableObject("_level0.theInterfaceMgr.gfxTacticalHUD.theTacticalHUD.theWeaponContainer.weapon0.AmmoBar") == none)
	{
		gfxWeaponPanel = PRES().GetHUD().GetVariableObject("_level0.theInterfaceMgr.gfxTacticalHUD.theTacticalHUD.theWeaponContainer.weapon0");
		gfxAmmoBar = class'UIModUtils'.static.AS_BindMovie(gfxWeaponPanel, "TargetHealthBar", "AmmoBar");
		gfxAmmoBar.SetVisible(true);
		gfxMyAmmoBar = MMGfxAmmoBar(gfxWeaponPanel.GetObject("AmmoBar", class'MMGfxAmmoBar'));
		gfxMyAmmoBar.AS_UpdateLocation(gfxWeaponPanel.GetFloat("_width")/2, 0.0);
		gfxMyAmmoBar.AS_SetKillShot(true);
		
		gfxWeaponPanel = PRES().GetHUD().GetVariableObject("_level0.theInterfaceMgr.gfxTacticalHUD.theTacticalHUD.theWeaponContainer.weapon1");
		gfxAmmoBar = class'UIModUtils'.static.AS_BindMovie(gfxWeaponPanel, "TargetHealthBar", "AmmoBar");
		gfxAmmoBar.SetVisible(true);
		gfxMyAmmoBar = MMGfxAmmoBar(gfxWeaponPanel.GetObject("AmmoBar", class'MMGfxAmmoBar'));
		gfxMyAmmoBar.AS_UpdateLocation(gfxWeaponPanel.GetFloat("_width")/2, 0.0);
		gfxMyAmmoBar.AS_SetKillShot(true);
	}
}
function SetAmmoGfx(int iPanel, int iMax, int iRemaining)
{
	local MMGfxAmmoBar gfxAmmoBar;

	iPanel = Clamp(iPanel, 0, 1);
	gfxAmmoBar = MMGfxAmmoBar(PRES().GetHUD().GetVariableObject("_level0.theInterfaceMgr.gfxTacticalHUD.theTacticalHUD.theWeaponContainer.weapon" $ string(iPanel) $ ".AmmoBar", class'MMGfxAmmoBar'));
	if(gfxAmmoBar != none)
	{
		gfxAmmoBar.AS_SetHealth(iMax, iRemaining);
		gfxAmmoBar.SetVisible(true);
	}
}
function UpdateWeaponHUD()
{
	local XGUnit kUnit;
	local UITacticalHUD_WeaponContainer kPanel;
	local XGWeapon kWeapon;
	local int iAmmo, iAmmoChunk, iMaxAmmo;

	if(BATTLE().IsAlienTurn())
	{
		return;
	}
	kUnit = BATTLE().m_kActivePlayer.GetActiveUnit();
	if(kUnit == none || !kUnit.IsIdle()) 
	{
		SetTimer(0.10, false, GetFuncName());
		return;
	}
	if(!m_bAmmoCounter)
	{
		PRES().GetHUD().GetVariableObject("_level0.theInterfaceMgr.gfxTacticalHUD.theTacticalHUD.theWeaponContainer.weapon0.AmmoBar").SetVisible(false);
		PRES().GetHUD().GetVariableObject("_level0.theInterfaceMgr.gfxTacticalHUD.theTacticalHUD.theWeaponContainer.weapon1.AmmoBar").SetVisible(false);
	}
	kWeapon = kUnit.GetInventory().GetPrimaryWeaponForUI();
	if( (m_bAmmoCounter || m_bAmmoCounterTextStyle) && kWeapon != none && !kWeapon.HasProperty(eWP_UnlimitedAmmo) && !kWeapon.HasProperty(eWP_NoReload))
	{
		if(class'MiniModsStrategy'.static.IsLongWarBuild())
		{
			iAmmoChunk = GRI().m_kGameCore.GetOverheatIncrement(none, kWeapon.ItemType(), eAbility_ShotStandard, kUnit.GetCharacter().m_kChar, false);
		}
		else
		{
			iAmmoChunk = GRI().m_kGameCore.GetAmmoCost(kWeapon.GamePlayType(), 7, kUnit.GetCharacter().m_kChar.aUpgrades[113] > 0, kUnit.GetCharacter().m_kChar, false);
		}
		iAmmo = kWeapon.GetRemainingAmmo() / iAmmoChunk;
		iMaxAmmo = 100 / iAmmoChunk;

		if(kWeapon == kUnit.GetInventory().GetActiveWeapon())
		{
			kWeapon.m_kTWeapon.strName = GRI().m_kGameCore.GetTWeapon(kWeapon.ItemType()).strName;
			if(m_bAmmoCounterTextStyle)
			{
				kWeapon.m_kTWeapon.strName @= ("(" $ string(iAmmo) $ "/" $ string(iMaxAmmo) $ ")");
			}
			kPanel = PRES().GetTacticalHUD().m_kWeaponContainer;
			kPanel.AS_SetWeaponName(kWeapon.m_kTWeapon.strName);
		}
		if(m_bAmmoCounter)
		{
			SetAmmoGfx(0, iMaxAmmo, iAmmo);
		}
	}
	else if(!m_bAmmoCounterTextStyle && kWeapon != none && kWeapon == kUnit.GetInventory().GetActiveWeapon() && InStr(kWeapon.m_kTWeapon.strName, "(") != -1)
	{
		kWeapon.m_kTWeapon.strName = Left(kWeapon.m_kTWeapon.strName, InStr(kWeapon.m_kTWeapon.strName, "("));
		kPanel = PRES().GetTacticalHUD().m_kWeaponContainer;
		kPanel.AS_SetWeaponName(kWeapon.m_kTWeapon.strName);
	}
	kWeapon = kUnit.GetInventory().GetSecondaryWeaponForUI();
	if( (m_bAmmoCounter || m_bAmmoCounterTextStyle) && kWeapon != none && !kWeapon.HasProperty(eWP_UnlimitedAmmo) && !kWeapon.HasProperty(eWP_NoReload))
	{
		if(class'MiniModsStrategy'.static.IsLongWarBuild())
		{
			iAmmo = kWeapon.GetRemainingAmmo() / GRI().m_kGameCore.GetOverheatIncrement(none, kWeapon.ItemType(), eAbility_ShotStandard, kUnit.GetCharacter().m_kChar, false);
			iMaxAmmo = 100 / GRI().m_kGameCore.GetOverheatIncrement(none, kWeapon.ItemType(), eAbility_ShotStandard, kUnit.GetCharacter().m_kChar, false);
		}
		else
		{
			iAmmo = kWeapon.GetRemainingAmmo() / GRI().m_kGameCore.GetAmmoCost(kWeapon.GamePlayType(), 7, kUnit.GetCharacter().m_kChar.aUpgrades[113] > 0, kUnit.GetCharacter().m_kChar, false);
			iMaxAmmo = 100 / GRI().m_kGameCore.GetAmmoCost(kWeapon.GamePlayType(), 7, kUnit.GetCharacter().m_kChar.aUpgrades[113] > 0, kUnit.GetCharacter().m_kChar, false);
		}
		if(kWeapon == kUnit.GetInventory().GetActiveWeapon())
		{
			kWeapon.m_kTWeapon.strName = GRI().m_kGameCore.GetTWeapon(kWeapon.ItemType()).strName;// @ "(" $ string(iAmmo) $ "/" $ string(iMaxAmmo) $ ")";
			if(m_bAmmoCounterTextStyle)
			{
				kWeapon.m_kTWeapon.strName @= ( "(" $ string(iAmmo) $ "/" $ string(iMaxAmmo) $ ")" );
			}
			kPanel = PRES().GetTacticalHUD().m_kWeaponContainer;
			kPanel.AS_SetWeaponName(kWeapon.m_kTWeapon.strName);
		}
		if(m_bAmmoCounter)
		{
			SetAmmoGfx(1, iMaxAmmo, iAmmo);
		}
	}
	else if(!m_bAmmoCounterTextStyle && kWeapon != none &&  kWeapon == kUnit.GetInventory().GetActiveWeapon() && InStr(kWeapon.m_kTWeapon.strName, "(") != -1)
	{
		kWeapon.m_kTWeapon.strName = Left(kWeapon.m_kTWeapon.strName, InStr(kWeapon.m_kTWeapon.strName, "("));
		kPanel = PRES().GetTacticalHUD().m_kWeaponContainer;
		kPanel.AS_SetWeaponName(kWeapon.m_kTWeapon.strName);
	}
}
function OnBattleDone()
{
	local TDialogueBoxData kDialogData;
	local XGParamTag kTag;
	local float fRandom;

	if(m_kSaveData != none)
	{
		m_kSaveData.Destroy();
	}
	m_kCustomCharges.UpdateItemCharges(true);
	if(m_bNoDeathMod)
	{
		ReviveReturningDeadSoldiers();
	}
	if(!IsExtraSalvageValid())
	{
		return;
	}
	if(bRandomizeExtraSalvage)
	{
		fRandom = FRand();
		ELERIUM_SALVAGE_MOD = 1.0 + fRandom * (ELERIUM_SALVAGE_MOD - 1.0);
		ALLOYS_SALVAGE_MOD = 1.0 + fRandom * (ALLOYS_SALVAGE_MOD - 1.0);
	}
	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
	kTag.StrValue0 = class'XGScreenMgr'.static.ConvertCashToString(CalcSalvageCost());
	kTag.StrValue1 = GetCashBalanceString();
	kTag.IntValue0 = int((ELERIUM_SALVAGE_MOD - 1.0) * float(BATTLE().m_kDesc.m_kDropShipCargoInfo.m_arrArtifacts[161]));
	kTag.IntValue1 = int((ALLOYS_SALVAGE_MOD - 1.0) * float(BATTLE().m_kDesc.m_kDropShipCargoInfo.m_arrArtifacts[162]));
	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strSalvageTitle;
	kDialogData.strText = class'XComLocalizer'.static.ExpandString(m_strSalvageBody);
	kDialogData.strAccept = m_strSalvageAccept;
	kDialogData.strCancel = m_strSalvageCancel;
	kDialogData.fnCallback = OnBetterSalvageAccept;
	if(kTag.IntValue0 > 0 || kTag.IntValue1 > 0)
	{
		XComPresentationLayer(XComPlayerController(GetWorldInfo().GetALocalPlayerController()).m_Pres).UIRaiseDialog(kDialogData);
	}
}
function OnBetterSalvageAccept(EUIAction eAction)
{
	local XGDropshipCargoInfo kCargo;

	if(eAction == eUIAction_Accept)
	{
		kCargo = XGBattle_SP(GRI().m_kBattle).m_kDesc.m_kDropShipCargoInfo;
		StoreCashCost(string(-CalcSalvageCost()));                                      //store money cost
		kCargo.m_arrArtifacts[161] = kCargo.m_arrArtifacts[161] * ELERIUM_SALVAGE_MOD;	//add elerium
		kCargo.m_arrArtifacts[162] = kCargo.m_arrArtifacts[162] * ALLOYS_SALVAGE_MOD;	//add alloys
	}
}
function int CalcSalvageCost()
{
	local XGDropshipCargoInfo kCargo;
	local int iCost, iMod;

	kCargo = BATTLE().m_kDesc.m_kDropShipCargoInfo;
	iMod = kCargo.m_arrArtifacts[161] * (ELERIUM_SALVAGE_MOD - 1.0);
	iCost += iMod * ELERIUM_SALVAGE_COST;
	iMod = kCargo.m_arrArtifacts[162] * (ALLOYS_SALVAGE_MOD - 1.0);
	iCost += iMod * ALLOYS_SALVAGE_COST;
	return iCost;
}
function string GetCashBalanceString()
{
	local string strCash;

	strCash = class'XGSaveHelper'.static.GetSavedValueString(GetSavedData(), "HQ", "CashBalance");
	if(strCash != "")
	{
		return class'XGScreenMgr'.static.ConvertCashToString(int(strCash));
	}
	return "???";
}
function StoreCashCost(string strCostToStore)
{
	local int i;
	local array<string> aJournal;

	aJournal = BATTLE().GetStats().m_aJournalEvents;
	for(i=aJournal.Length; i >= 0; --i)
	{
		//replace CashBalance record with a CashMod record
		if(InStr(aJournal[i], "CashBalance:") != -1)
		{
			 BATTLE().GetStats().m_aJournalEvents[i]="CashMod:" $ strCostToStore;
			 return;
		}
	}
	
	//if CashBalance not found just store CashMod
	BATTLE().GetStats().RecordEvent("CashMod:" $ strCostToStore);
}
function bool IsExtraSalvageValid()
{
	local int iType;
	
	if(!m_bSalvageMod || GRI().m_kBattle.m_iResult != 1)
		return false;

	foreach MissionTypeAllowed(iType)
	{
		if(BATTLE().m_kDesc.m_iMissionType == iType)
			return true;
	}
	return false;
}
function ShowTurnCount()
{
	local UITurnOverlay kUI;

	kUI = PRES().m_kTurnOverlay;
	if(!kUI.IsShowingXComTurn())
	{
		kUI.SetDisplayText(kUI.m_sAlienTurn, (kUI.m_sXComTurn @ BATTLE().m_iTurn), kUI.m_sExaltTurn);
		kUI.PulseXComTurn();
	}
}
function ReviveReturningDeadSoldiers()
{
	local XGSquad kXCom;
	local XGUnit kSoldier;
	local int iMember;

	kXCom = XGBattle_SP(BATTLE()).GetHumanPlayer().GetSquad();
	for(iMember=0; iMember < kXCom.GetNumPermanentMembers(); ++iMember)
	{
		kSoldier = kXCom.GetPermanentMemberAt(iMember);
		if(kSoldier.IsDead())
		{
			if(XGBattle_SPCovertOpsExtraction(BATTLE()) == none || (kSoldier != XGBattle_SPCovertOpsExtraction(BATTLE()).GetCovertOperative()) )
			{
				kSoldier.m_aCurrentStats[eStat_HP]=1;
				kSoldier.m_iLowestHP=1;
				kSoldier.m_strCauseOfDeath="";
			}
		}
	}
}

function BuildDataForModMgr()
{
	local MiniModsOptionsContainer kContainer;

	class'UIModManager'.static.RegisterUpdateCallback(UpdateOptions);
	class'UIModManager'.static.RegisterInitWidgetCallback(InitModsMenuWidget);
	foreach DynamicActors(class'MiniModsOptionsContainer', kContainer)
	{
		if(kContainer != none)
		{
			break;
		}
	}
	if(kContainer == none)
	{
		kContainer = Spawn(class'MiniModsOptionsContainer');
		kContainer.Init(self);
	}
}
function UpdateOptions()
{
	local array<TModSetting> arrUISettings;

	class'XComModsProfile'.static.GetModSettings("SalvageMod",      arrUISettings);
	
	m_bFuelConsumption=         class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "FuelConsumption") && class'XComModsProfile'.static.ReadSettingBool("m_bFuelConsumption", "FuelConsumption");
	m_bFlashBombOnHackingArray= class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "DisorientExalt");
	m_bOfficerIronWill=         class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "OfficerIronWill");
	m_bPerksGiveItemCharges =   class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "PerkGivesItems");
	m_bSalvageMod=              class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "SalvageMod", arrUISettings);
	m_bScoutSense=              class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "ScoutSense");
	m_bSequentialOverwatch =    class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "SequentialOverwatch");
	m_bShadowStep=              class'XComModsProfile'.static.ReadSettingBool("bModEnabled", "ShadowStep");
		
	MissionTypeAllowed.Length=0;
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.UFOCrash", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(3);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.UFOLanded", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(4);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.AlienBase", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(8);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.ExaltRaid", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(13);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.DataRecovery", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(6);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.ExtractAgent", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(5);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.TerrorSite", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(9);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.CouncilMission", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(11);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.Abduction", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(2);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.LowFriends", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(20);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.ConfoundingLight", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(21);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.Gangplank", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(22);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.Portent", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(25);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.Deluge", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(26);
	if(class'XComModsProfile'.static.ReadSettingBool("MissionTypeAllowed.Furies", "SalvageMod", arrUISettings))
		MissionTypeAllowed.AddItem(27);

	if(ELERIUM_SALVAGE_COST <= 0 )
	{
		ELERIUM_SALVAGE_COST = class'MiniModsStrategy'.static.GetItemBalanceNormalFor(eItem_Elerium115).iCash * 2;
	}
	if(ALLOYS_SALVAGE_COST <= 0 )
	{
		ALLOYS_SALVAGE_COST = class'MiniModsStrategy'.static.GetItemBalanceNormalFor(eItem_AlienAlloys).iCash * 2;
	}
	SaveConfig();
	m_kCustomCharges.SaveConfig();
	m_kCustomCharges.CleanUpDefaultSettings();
}
function InitModsMenuWidget(out UIWidget kWidget, out TModOption tOption)
{
	local UIModManager kModsMenu;
	local string sMod;

	kModsMenu = class'UIModManager'.static.GetModMgr();
	sMod = kModsMenu.m_kModShell.m_strSelectedMod;
	if(sMod == "AlienSightRings" && (tOption.VarName == "R" || tOption.VarName == "G" || tOption.VarName == "B"))
	{
		if(UIWidget_Spinner(kWidget) != none)
		{
			UIWidget_Spinner(kWidget).__del_OnDecrease__Delegate = ModsMenu_UpdateSightRingColor;
			UIWidget_Spinner(kWidget).__del_OnIncrease__Delegate = ModsMenu_UpdateSightRingColor;
			kModsMenu.m_kModShell.SetTimer(0.20, false, 'ModsMenu_UpdateSightRingColor', self);
		}
	}
}
function ModsMenu_UpdateSightRingColor()
{
	local int R,G,B;
	local UIModManager kModsMenu;

	kModsMenu = class'UIModManager'.static.GetModMgr();
	if(kModsMenu.m_kModShell.m_bWaitingForUI)
	{
		kModsMenu.m_kModShell.SetTimer(0.20, false, 'ModsMenu_UpdateSightRingColor', self);
		return;
	}
	R = kModsMenu.m_kModShell.m_kWidgetHelper.GetCurrentValue(kModsMenu.m_kModShell.m_arrCurrentModOptions.Find('VarName', "R"));
	G = kModsMenu.m_kModShell.m_kWidgetHelper.GetCurrentValue(kModsMenu.m_kModShell.m_arrCurrentModOptions.Find('VarName', "G"));
	B = kModsMenu.m_kModShell.m_kWidgetHelper.GetCurrentValue(kModsMenu.m_kModShell.m_arrCurrentModOptions.Find('VarName', "B"));
	kModsMenu.m_kModShell.AS_SetDescription( class'UIFxsMovie'.static.ColorString("||||||||||||||||||||||||||||", MakeColor(R, G, B)) );
}
function BuildCustomAbilities()
{
	local XGABilityTree kTree;
	
	kTree = GRI().m_kGameCore.m_kAbilities;
	m_iScoutAbilityIdx = kTree.m_arrAbilities.Length;//check the current count of abilities and set the index for new ability
	BuildCustomAbility(m_iScoutAbilityIdx, 1, m_strScoutSenseName, eTarget_Self, 1, -1, 0,,,,eProp_CostNone, eProp_EnemiesCantReact,,,,,,,eDisplayProp_AlwaysVisible, eDisplayProp_TopDownCamera);
	UpdateCustomAbilities();
}
function UpdateCustomAbilities()
{
	SetAbilityFree(eAbility_CombatStim, m_bNoCostCombatStims);
	SetAbilityFree(eAbility_Grapple, m_bNoCostGrapple);
	SetAbilityCoolDown(eAbility_Grapple, m_bNoCostGrapple ? m_iGrappleCooldown : -1);
	SetAbilityFree(41, m_bNoCostCommand);
	class'MMAbilitiesBuilder'.static.ApplyAbilityMods();
}
function SetAbilityFree(int iAbility, bool bSetFree)
{
	GRI().m_kGameCore.m_kAbilities.m_arrAbilities[iAbility].aProperties[eProp_CostNone] = (bSetFree ? 1 : 0);
}
function SetAbilityCoolDown(int iAbility, int iCooldown)
{
	GRI().m_kGameCore.m_kAbilities.m_arrAbilities[iAbility].aProperties[eProp_Cooldown] = (iCooldown > 0 ? 1 : 0);
	GRI().m_kGameCore.m_kAbilities.m_arrAbilities[iAbility].iCooldown = iCooldown;
}
function SetAbilityCategory(int iAbility, int iCategory)
{
	GRI().m_kGameCore.m_kAbilities.m_arrAbilities[iAbility].iCategory = iCategory;
}
/** This function duplicates XGAbilityTree.BuildAbility while adding iCategory and strAbilityName params - which cannot be auto-set by original BuildAbility*/
function BuildCustomAbility(out int iCustomType, int iCategory, string strAbilityName, EAbilityTarget eTarget, int iRange, int iDuration, int iReactionCost, optional EAbilityEffect eEffect1, optional EAbilityEffect eEffect2, optional EAbilityEffect eEffect3, optional EAbilityProperty eProperty1, optional EAbilityProperty eProperty2, optional EAbilityProperty eProperty3, optional EAbilityProperty eProperty4, optional EAbilityProperty eProperty5, optional EAbilityProperty eProperty6, optional EAbilityProperty eProperty7, optional EAbilityProperty eProperty8, optional EAbilityDisplayProperty eDisplayProperty1, optional EAbilityDisplayProperty eDisplayProperty2, optional EAbilityDisplayProperty eDisplayProperty3, optional EAbilityDisplayProperty eDisplayProperty4, optional int iCooldown=-1, optional int iCharges=-1)
{
	local TAbility kTAbility;

	kTAbility.strName = strAbilityName;
	kTAbility.iType = iCustomType;
	kTAbility.iCategory = iCategory;
	kTAbility.iTargetType = eTarget;
	kTAbility.iRange = iRange;
	kTAbility.iDuration = iDuration;
	kTAbility.iReactionCost = iReactionCost;
	++ kTAbility.aEffects[eEffect1];
	++ kTAbility.aEffects[eEffect2];
	++ kTAbility.aEffects[eEffect3];
	++ kTAbility.aProperties[eProperty1];
	++ kTAbility.aProperties[eProperty2];
	++ kTAbility.aProperties[eProperty3];
	++ kTAbility.aProperties[eProperty4];
	++ kTAbility.aProperties[eProperty5];
	++ kTAbility.aProperties[eProperty6];
	++ kTAbility.aProperties[eProperty7];
	++ kTAbility.aProperties[eProperty8];
	++ kTAbility.aDisplayProperties[eDisplayProperty1];
	++ kTAbility.aDisplayProperties[eDisplayProperty2];
	++ kTAbility.aDisplayProperties[eDisplayProperty3];
	++ kTAbility.aDisplayProperties[eDisplayProperty4];
	kTAbility.iCooldown = iCooldown;
	kTAbility.iCharges = iCharges;
	GRI().m_kGameCore.m_kAbilities.m_arrAbilities[iCustomType] = kTAbility;
}
function ToggleAllReactionStatus(bool bEnable)
{
	local XGUnit kUnit;

	foreach DynamicActors(class'XGUnit', kUnit)
	{
		kUnit.m_bReactionFireStatus = bEnable;
	}
}
function ToggleAlienSightRings()
{
	m_bAlienSightRings = !m_bAlienSightRings;
	default.m_bAlienSightRings = m_bAlienSightRings;
}
function ToggleCompactHPDisplay()
{
	local MMUnitTracker kT;

	m_bCompactHPDisplay = !m_bCompactHPDisplay;
	default.m_bCompactHPDisplay = m_bCompactHPDisplay;
	foreach m_arrUnitTrackers(kT)
	{
		if(m_bCompactHPDisplay)
		{
			kT.UpdateUnitFlag();
		}
		else
		{
			PRES().m_kUnitFlagManager.RemoveFlagForUnit(kT.m_kUnit);
			PRES().m_kUnitFlagManager.AddFlag(kT.m_kUnit);
		}
	}
}
function GameSpeedUp()
{
	GAME_SPEED_TACTICAL = FMin(MAX_GAME_SPEED, GAME_SPEED_TACTICAL + GAME_SPEED_MOD_STEP);
	if(WorldInfo.Game.GameSpeed <= MIN_GAME_SPEED)//if current GameSpeed is at min
		GAME_SPEED_TACTICAL = FFloor(GAME_SPEED_TACTICAL / GAME_SPEED_MOD_STEP) * GAME_SPEED_MOD_STEP; //set gamespeed to lowest valid multiplication of the step
	m_bForceGameSpeedPopup = true;
	ForceGameSpeed();
}
function GameSpeedDown()
{
	GAME_SPEED_TACTICAL = FMax(MIN_GAME_SPEED, GAME_SPEED_TACTICAL - GAME_SPEED_MOD_STEP);
	if(WorldInfo.Game.GameSpeed >= MAX_GAME_SPEED)//if current GameSpeed is at max
		GAME_SPEED_TACTICAL = FCeil(GAME_SPEED_TACTICAL / GAME_SPEED_MOD_STEP) * GAME_SPEED_MOD_STEP;//set gamespeed to highest valid multiplication of the step
	m_bForceGameSpeedPopup = true;
	ForceGameSpeed();
}
function ForceGameSpeed()
{
	if(WorldInfo.Game.GameSpeed == GAME_SPEED_TACTICAL)
	{
		return;
	}
	if(BATTLE().m_kGlamMgr.IsInState('Playing'))
	{
		if(BATTLE().m_kGlamMgr.FocusAction != none && BATTLE().m_kGlamMgr.FocusAction.IsA('XGAction_Fire'))
		{
			BATTLE().m_kGlamMgr.UseFixedTimeStep(GAME_SPEED_SKIP_ACTION_CAM);
		}
		if(!IsTimerActive(GetFuncName()))
		{
			SetTimer(0.50, false, GetFuncName());
		}
		return;
	}
	if(BATTLE().m_kGlamMgr.m_eGlamWaitStatus == eGWS_Completed)
	{
		if(!IsTimerActive(GetFuncName()))
		{
			SetTimer(0.50, false, GetFuncName());
		}
	}
	if(!IsLWR() || m_bOverrideLWR)
	{
		BATTLE().m_kGlamMgr.UseFixedTimeStep(false);
		GetWorldInfo().MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchGameSpeedHandle, false);	
			WorldInfo.Game.SetGameSpeed(GAME_SPEED_TACTICAL);
			if(m_bForceGameSpeedPopup)
			{
				m_bForceGameSpeedPopup = false;
				PRES().GetAnchoredMessenger().Message(m_strGameSpeed @ Left(string(GAME_SPEED_TACTICAL),4), 0.95, 0.90, BOTTOM_RIGHT,1.0,,eIcon_Globe);
				`Log(GetFuncName() @ "GameSpeed set to" @ Left(string(WorldInfo.Game.GameSpeed),4));
			}
		SetTimer(0.10, false, 'EnableWatchGameSpeed');
	}
}
function EnableWatchGameSpeed()
{
	GetWorldInfo().MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchGameSpeedHandle, true);
}
function UpdateKillsDisplay()
{
	local int iTotalKills, iPreBattleKills, iMissionKills, iSoldier, iMissionXP;
	local XGUnit kActiveUnit;
	local string sKills, sOnMission, sTotal, sXP;

	if(!m_bKillsCounter && !m_bKillsAndXPDisplay)
	{
		return;
	}
	if(!BATTLE().IsAlienTurn() && IsBattleReady())
	{
		kActiveUnit = XGBattle_SP(BATTLE()).m_kActivePlayer.GetActiveUnit();
		if(kActiveUnit != none)
		{
			if(kActiveUnit.IsCivilian() || kActiveUnit.m_kCharacter == none)
			{
				GetKillsInfoBox().SetVisible(false);
			}
			else if(XGCharacter_Soldier(kActiveUnit.GetCharacter()) != none)
			{
				iTotalKills = XGCharacter_Soldier(kActiveUnit.GetCharacter()).m_kSoldier.iNumKills;
				iMissionXP = GetCurrentMissionXP(kActiveUnit);
				for(iSoldier = 0; iSoldier < BATTLE().m_kDesc.m_kDropShipCargoInfo.m_arrSoldiers.Length; ++iSoldier)
				{
					if(BATTLE().m_kDesc.m_kDropShipCargoInfo.m_arrSoldiers[iSoldier].kSoldier.iID == XGCharacter_Soldier(kActiveUnit.GetCharacter()).m_kSoldier.iID)
					{
						iPreBattleKills = BATTLE().m_kDesc.m_kDropShipCargoInfo.m_arrSoldiers[iSoldier].kSoldier.iNumKills;
						break;
					}
				}
				iMissionKills = iTotalKills - iPreBattleKills;
				sKills = CAPS(Localize("UIDebrief", "m_strKills", "XComStrategyGame"));
				sOnMission = CAPS(Localize("UISoldierSummary", "m_sOnMissionLabel", "XComStrategyGame"));
				sTotal = CAPS(Localize("UICloseCombat", "m_sTotalDesc", "XComGame"));
				if(m_bKillsAndXPDisplay)
				{
					sXP = CAPS(Localize("XGSoldierUI", "m_strLabelStrength", "XComStrategyGame"));
				}
				if(!m_bKillsAndXPDisplay)
				{
					GetKillsInfoBox().SetHTMLText(sKills @ "-" @ sOnMission $":" @ iMissionKills $ "\n"$sKills @ "-" @ sTotal @ iTotalKills);
				}
				else
				{
					GetKillsInfoBox().SetHTMLText(sKills @ "-" @ sOnMission $":" @ iMissionKills $ "\n"$sXP@ "-" @ sTotal @ iMissionXP @"/"@ GRI().m_kGameCore.GetXPRequired(XGCharacter_Soldier(kActiveUnit.GetCharacter()).m_kSoldier.iRank + 1));
				}
				GetKillsInfoBox().SetVisible(true);
			}
		}
	}
}
function int GetCurrentMissionXP(XGUnit kUnit)
{
	local XGCharacter_Soldier kCharSoldier;
    local int iXPBackup, iReturnXP;

	kCharSoldier = XGCharacter_Soldier(kUnit.GetCharacter());
	if(kCharSoldier != none)
	{
		iXPBackup = kCharSoldier.m_kSoldier.iXP;
		kCharSoldier.AddXP(GRI().m_kGameCore.CalcXP(kUnit, (BATTLE().m_kDesc.m_iMissionType == 9 || BATTLE().m_kDesc.m_iMissionType == 8 || BATTLE().m_kDesc.m_iMissionType == 7 || BATTLE().m_kDesc.m_iMissionType == 4) ? 5 : 4, none));
		kCharSoldier.AddXP(kUnit.GetSquad().GetNumDead() == 0 ? GRI().m_kGameCore.CalcXP(kUnit, 6, none) : 0);
		if(XGBattle_SPCovertOpsExtraction(BATTLE()) != none)
		{
			if(kUnit == XGBattle_SPCovertOpsExtraction(BATTLE()).GetCovertOperative())
			{
				kCharSoldier.AddXP(120);//fixme, some mods can alter this 120
			}
		}
		iReturnXP = kCharSoldier.m_kSoldier.iXP;
		kCharSoldier.m_kSoldier.iXP = iXPBackup;
	}
	return iReturnXP;
}
function UIModGfxTextField GetKillsInfoBox()
{
	local UI_FxsPanel kSoldierStats;
	local GFxObject gfxPanel;
	local UIModGfxTextField gfxKillsInfobox;

	kSoldierStats = PRES().GetTacticalHUD().m_kStatsContainer;
	gfxPanel = kSoldierStats.manager.GetVariableObject(string(kSoldierStats.GetMCPath()));
	gfxKillsInfobox = UIModGfxTextField(gfxPanel.GetObject("killsInfobox", class'UIModGfxTextField'));
	if(gfxKillsInfobox == none)
	{
		gfxKillsInfobox = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(gfxPanel, "killsInfobox", 22, -150, 150, 40,,class'UIModGfxTextField')); 
	}
	gfxKillsInfobox.m_FontSize = 14.0;
	return gfxKillsInfobox;
}

function TestWatchVars()
{
	local WatchVariable kWatchVar;
	local int idx;

	`Log("m_iWatchGameSpeedHandle="$m_iWatchGameSpeedHandle);
	foreach WorldInfo.MyWatchVariableMgr.WatchVariables(kWatchVar, idx)
	{
		if(kWatchVar.WatchName == 'GameSpeed')
		{
			`Log("Found WatchVariable for 'GameSpeed' with WatchGroupHandle" @ kWatchVar.WatchGroupHandle);
		}
	}
	`Log("Scanned total of" @ idx @ "WatchVariables");
}

state ModdingInfoPanel
{
	function AddPerk(int iPerk, optional int iListType=0)
	{
		local UIUnitGermanMode_PerkList kList;
		local TPerk Perk;
		local EPerkBuffCategory eBuffType;
		
		switch(iListType)
		{
		case 1: 
			kList = PRES().m_kGermanMode.m_kBonuses;
			eBuffType = ePerkBuff_Bonus;
			break;
		case 2:
			kList = PRES().m_kGermanMode.m_kPenalties;
			eBuffType = ePerkBuff_Penalty;
			break;
		default:
			kList = PRES().m_kGermanMode.m_kPerks;
			eBuffType = ePerkBuff_Passive;
		}
		Perk = PC().PERKS().GetPerk(iPerk);
		if(!PerkIsListed(kList, iPerk))
			kList.AS_AddPerk(Perk.strName[eBuffType], Perk.strDescription[eBuffType], Perk.strImage);
	}
	function bool PerkIsListed(UIUnitGermanMode_PerkList kPerkList, int iPerk)
	{
		local int I;

		for(I = 0; I < kPerkList.m_arrPerkData.Length; ++ I)
		{
			if(kPerkList.m_arrPerkData[I].strName == PC().PERKS().GetPerkName(iPerk, kPerkList.m_arrPerkData[I].buffCategory))
				return true;
		}
		return false;
	}
	function bool IsLeaderNearby(XGUnit kUnit)
	{
		local XGSquad kSquad;
		local XGUnit kLeader;
		local bool bNearbyLeader;

		if(kUnit.GetPlayer() == XGBattle_SP(BATTLE()).GetHumanPlayer())
		{
			kSquad = XGBattle_SP(BATTLE()).GetHumanPlayer().GetSquad();
			kLeader = kSquad.GetSquadLeader();
			if(kLeader != none)
			{
				bNearbyLeader = (kLeader.IsAliveAndWell() && int(VSize2D(kUnit.GetLocation() - kLeader.GetLocation()) / 96.0) <= OTS_LEADER_RANGE);
			}
		}
		return bNearbyLeader;
	}
	function string GetShadowPerkBuffDescription()
	{
		local string strPrefix;

		strPrefix = m_strShadowStepBuffDesc;
		if(class'MiniModsTactical'.default.m_bShadowStepOnlyOnMove)
		{
			strPrefix @= class'MiniModsTactical'.default.m_strShadowStepMoveSuffix;
		}
		else if(class'MiniModsTactical'.default.m_bShadowStepRequiresDash)
		{
			strPrefix @= class'MiniModsTactical'.default.m_strShadowStepDashSuffix;
		}
		strPrefix $= ".";
		return strPrefix;
	}
Begin:
	while(!PRES().IsInState('State_GermanMode'))
	{
		Sleep(0.10);
	}
	if(m_bOfficerIronWill && IsLeaderNearby(PRES().m_kGermanMode.m_kUnit) && !PRES().m_kGermanMode.m_kUnit.HasSquadLeaderOTSBonus())
	{
		AddPerk(170, 1);
	}
	if(m_bShadowStep && !PRES().m_kGermanMode.m_kUnit.IsShiv() && !PRES().m_kGermanMode.m_kUnit.IsAugmented() 
		&& GetUnitTrackerFor(PRES().m_kGermanMode.m_kUnit).UnitCanShadowStep(PRES().m_kGermanMode.m_kUnit) )
	{
		PRES().m_kGermanMode.m_kPerks.AS_AddPerk(m_strShadowStepping, GetShadowPerkBuffDescription(), "Sprinter");
	}
}
state Initing
{
	event PushedState()
	{
		`Log(GetFuncName() @ GetStateName(),,'MiniModsTactical');
	}
	event PoppedState()
	{
		`Log(GetFuncName() @ GetStateName(),,'MiniModsTactical');
	}
Begin:
	for(m_idx=0; m_idx < XGBattle_SP(GRI().GetBattle()).GetHumanPlayer().GetSquad().GetNumMembers(); m_idx++)
	{
		m_kHelperUnit = XGBattle_SP(GRI().GetBattle()).GetHumanPlayer().GetSquad().GetMemberAt(m_idx);
		InitTrackerFor(m_kHelperUnit);
		if(m_idx % 5 == 0)
		{
			Sleep(0.10);
		}
	}
	for(m_idx=0; m_idx < XGBattle_SP(GRI().GetBattle()).GetAIPlayer().GetSquad().GetNumMembers(); m_idx++)
	{
		m_kHelperUnit = XGBattle_SP(GRI().GetBattle()).GetAIPlayer().GetSquad().GetMemberAt(m_idx);
		InitTrackerFor(m_kHelperUnit);
		if(m_idx % 5 == 0)
		{
			Sleep(0.10);
		}
	}
	m_kHelperUnit=none;
	OnBattleReady();
	PopState();
}
state UpdatingOptions
{
	function CleanUpModsProfile()
	{
		local int iBlankOptions;

		iBlankOptions = class'XComModsProfile'.static.ReadSettingInt("iBlankOptions", "PerkGivesItems");
		class'XComModsProfile'.static.ClearAllSettingsForMod("ScoutSense");
		class'XComModsProfile'.static.ClearAllSettingsForMod("DisorientExalt");
		class'XComModsProfile'.static.ClearAllSettingsForMod("ShadowStep");
		class'XComModsProfile'.static.ClearAllSettingsForMod("SequentialOverwatch");
		class'XComModsProfile'.static.ClearAllSettingsForMod("SalvageMod");
		class'XComModsProfile'.static.ClearAllSettingsForMod("FuelConsumption");
		class'XComModsProfile'.static.ClearAllSettingsForMod("PerkGivesItems");
		class'XComModsProfile'.static.ClearAllSettingsForMod("FlashBangImproved");
		class'XComModsProfile'.static.SaveSetting("PerkGivesItems", "PerkGivesItems.iBlankOptions", string(iBlankOptions), eVType_Int);
	}
	event PushedState()
	{
		BuildDataForModMgr();
	}
	event PoppedState()
	{
		CleanUpModsProfile();
		class'MMCustomItemCharges'.static.CleanUpDefaultSettings();
		if(TACTICAL() != none)
		{
			ToggleAllReactionStatus(!m_bSequentialOverwatch);
			UpdateCustomAbilities();
		}
	}
}
defaultproperties
{
	m_iWatchMultishotTargets=-1
	MIN_GAME_SPEED=0.50
	MAX_GAME_SPEED=2.50
}