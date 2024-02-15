class AltWeaponsMutator extends XComMutator
	config(ModWeaponModels);

struct TConfigWeaponModelData
{
	var int ItemType;
	var string MeshPath;
	var float fPitch;
	var float fYaw;
};

var string m_strBuildVersion;
var config array<TConfigWeaponModelData> WeaponModel;
var config bool bModEnabled;
var int m_iNumPermanentHumans;
var int m_iNumPermanentAliens;
var AltWeaponModelConstructor CONSTRUCTOR;

function string GetDebugName()
{
	return Class.Name @ m_strBuildVersion;
}
function XGBattle_SP BATTLE()
{
	return (WorldInfo.GRI != none ? XGBattle_SP(XComTacticalGRI(WorldInfo.GRI).m_kBattle) : none);
}
function XComContentManager CONTENT()
{
	return XComContentManager(Class'Engine'.static.GetEngine().GetContentManager());
}
static function bool IsLongWarBuild()
{
	return class'XComPerkManager'.default.SoldierPerkTrees.Length > 15;
}

function Mutate(string MutString, PlayerController Sender)
{
	if(InStr(MutString, "AWM_PitchUp",,true) != -1)
	{
		//AdjustRotation(1.0, 0.0);
		CONSTRUCTOR.ApplyTextures(XComWeapon(BATTLE().GetHumanPlayer().GetActiveUnit().GetInventory().GetPrimaryWeapon().m_kEntity), GetDataForItemType(BATTLE().GetHumanPlayer().GetActiveUnit().GetInventory().GetPrimaryWeapon().m_eType));
	}
	else if(InStr(MutString, "AWM_PitchDown",,true) != -1)
	{
		AdjustRotation(-1.0, 0.0);
	}
	else if(InStr(MutString, "AWM_YawLeft",,true) != -1)
	{
		AdjustRotation(0.0, -1.0);
	}
	else if(InStr(MutString, "AWM_YawRight",,true) != -1)
	{
		AdjustRotation(0.0, 1.0);
	}
	super.Mutate(MutString, Sender);
}
event PostBeginPlay()
{
	super.PostBeginPlay();
	if(XComTacticalGame(WorldInfo.Game) != none)
	{
		PollForBattleReady();
	}
	else if(XComHeadquartersGame(WorldInfo.Game) != none)
	{
		PollForStrategyReady();
	}
	`Log(GetFuncName() @ GetDebugName());
}
function InitConstructor()
{
	if(CONSTRUCTOR == none)
	{
		CONSTRUCTOR = new (self) class'AltWeaponModelConstructor';
		CONSTRUCTOR.Init();
	}
}
function PollForBattleReady()
{
	if(IsBattleReady())
	{
		RegisterWatchVars();
		ApplyArchetypeMeshes();
		ApplyAllUnitWeaponMeshes();
		AddBindings();
	}
	else
	{
		SetTimer(1.0, false, GetFuncName());
	}
}
function PollForStrategyReady()
{
	if(XComHeadquartersController(GetALocalPlayerController()) != none && XComHeadquartersController(GetALocalPlayerController()).m_Pres != none && XComHeadquartersController(GetALocalPlayerController()).m_Pres.m_bPresLayerReady)
	{
		AddBindings();
	}
	else
	{
		SetTimer(1.0, false, GetFuncName());
	}
}
function bool IsBattleReady()
{
	local bool bXComLoaded, bAliensLoaded, bNeutralLoaded;
	local XGPlayer kPlayer;

	if(BATTLE() == none)
	{
		return false;
	}
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
function RegisterWatchVars()
{
	m_iNumPermanentHumans = BATTLE().GetHumanPlayer().GetSquad().GetNumPermanentMembers();
	m_iNumPermanentAliens = BATTLE().GetAIPlayer().GetSquad().GetNumPermanentMembers();
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(BATTLE().GetHumanPlayer().GetSquad(), 'm_iNumPermanentUnits', self, OnNewXComUnit);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(BATTLE().GetAIPlayer().GetSquad(), 'm_iNumPermanentUnits', self, OnNewEnemyUnit);
}
function OnNewXComUnit()
{
}
function OnNewEnemyUnit()
{
	local XGUnit kNewUnit;
	local XGSquad kSquad;
	local int iNewSquadSize;

	kSquad = BATTLE().GetAIPlayer().GetSquad();
	iNewSquadSize = kSquad.GetNumPermanentMembers();
	while(m_iNumPermanentAliens < iNewSquadSize)
	{
		kNewUnit = kSquad.m_arrPermanentMembers[m_iNumPermanentAliens];
		ApplyWeaponMeshesForUnit(kNewUnit);
		++ m_iNumPermanentAliens;
	}
}
function ApplyArchetypeMeshes()
{
	local TConfigWeaponModelData tData;
	local XComWeapon kArchetype;
	local rotator rot;

	InitConstructor();
	foreach WeaponModel(tData)
	{
		kArchetype = XComContentManager(Class'Engine'.static.GetEngine().GetContentManager()).GetWeaponTemplate(EItemType(tData.ItemType));
		if(kArchetype != none)
		{
			CONSTRUCTOR.ApplyTextures(kArchetype, tData);
			rot = kArchetype.Mesh.Rotation;
			rot.Pitch = tData.fPitch*65535/360;
			rot.Yaw = tData.fYaw*65535/360;
			kArchetype.Mesh.SetRotation(rot);
		}
		else
		{
			`log("Failed to load content object from path" @ tData.MeshPath);
		}
	}
}
function ApplyWeaponMeshesForUnit(XGUnit kUnit)
{
	local int i;
	local TConfigWeaponModelData tData;
	local XComWeapon kWeapon;
	local SkeletalMesh NewMesh;
	local rotator rot;

	InitConstructor();
	for(i=0; i<2; ++i)
	{
		if(i == 0)
		{
			kWeapon = XComWeapon(kUnit.GetInventory().GetPrimaryWeapon().m_kEntity);
		}
		else if(kUnit.GetInventory().GetSecondaryWeapon() != none)
		{
			kWeapon = XComWeapon(kUnit.GetInventory().GetSecondaryWeapon().m_kEntity);
		}
		if(kWeapon != none && kWeapon.m_kGameWeapon != none)
		{
			tData = GetDataForItemType(kWeapon.m_kGameWeapon.m_eType);
			CONSTRUCTOR.ApplyTextures(kWeapon, tData);
			NewMesh = SkeletalMesh(DynamicLoadObject(tData.MeshPath, class'SkeletalMesh', true));
			if(NewMesh != none)
			{
				rot = kWeapon.Mesh.Rotation;
				rot.Pitch = tData.fPitch*65535/360;
				rot.Yaw = tData.fYaw*65535/360;
				kWeapon.Mesh.SetRotation(rot);
			}
			else
			{
				`log("Failed to load content object from path" @ tData.MeshPath,,Class.GetPackageName());
			}
		}
	}
	//kUnit.GetPawn().UpdateMeshMaterials(kWeapon.Mesh);
}
//static function CSM_WatchActor GetWatchActorFor(XGUnit kUnit)
//{
//	local CSM_WatchActor kWatcher;
//	local WorldInfo kInfo;

//	kInfo = class'Engine'.static.GetCurrentWorldInfo();

//	foreach kInfo.DynamicActors(class'CSM_WatchActor', kWatcher)
//	{
//		if(kWatcher.m_kUnit == kUnit)
//			return kWatcher;
//	}
//	return none;
//}
function ApplyAllUnitWeaponMeshes()
{
	local XGUnit kUnit;

	foreach DynamicActors(class'XGUnit', kUnit)
	{
		ApplyWeaponMeshesForUnit(kUnit);
	}
}
static function TConfigWeaponModelData GetDataForItemType(int iType, optional out int idx)
{
	local TConfigWeaponModelData tData;
	local int i;

	for(i=default.WeaponModel.Length-1; i>=0; --i)
	{
		if(default.WeaponModel[i].ItemType == iType)
		{
			idx = i;
			return default.WeaponModel[i];
		}
	}
	idx = -1;
	return tData;
}
static function string GetMeshPathForItemType(int iType)
{
	return GetDataForItemType(iType).MeshPath;
}
//static function string GetSkinPathForItemType(int iType)
//{
//	return GetDataForItemType(iType).SkinPath;
//}
function AdjustRotation(float fAdjP, float fAdjY)
{
	local int idx;
	local TConfigWeaponModelData tD;
	local SkeletalMeshComponent kMesh;
	local XComWeapon kWeapon;
	local rotator rot;

	if(XComTacticalGame(WorldInfo.Game) != none && IsBattleReady() && !BATTLE().IsAlienTurn())
	{
		kWeapon = XComWeapon(BATTLE().GetHumanPlayer().GetActiveUnit().GetInventory().GetActiveWeapon().m_kEntity);
		if(kWeapon != none && kWeapon.Mesh != none)
		{
			kMesh = SkeletalMeshComponent(kWeapon.Mesh);
			tD = GetDataForItemType(kWeapon.m_kGameWeapon.m_eType, idx);
		}
	}
	else if(XComHeadquartersGame(Worldinfo.Game) != none && XComHQPresentationLayer(XComHeadquartersController(GetALocalPlayerController()).m_Pres).m_kSoldierLoadout != none)
	{
		kMesh = SkeletalMeshComponent(XComHQPresentationLayer(XComHeadquartersController(GetALocalPlayerController()).m_Pres).m_kSoldierLoadout.m_kSoldier.m_kPawn.Weapon.Mesh);
		tD = GetDataForItemType(XComHumanPawn(XComHQPresentationLayer(XComHeadquartersController(GetALocalPlayerController()).m_Pres).m_kSoldierLoadout.m_kSoldier.m_kPawn).PrimaryWeapon, idx);
	}
	if(kMesh != none)
	{
		rot = kMesh.Rotation;
		`log("before rot.pitch" @ rot.Pitch @ "yaw" @ rot.Yaw);
		rot.Pitch += fAdjP*65535/360;
		rot.Yaw += fAdjY*65535/360;
		`log("after rot.pitch" @ rot.Pitch @ "yaw" @ rot.Yaw);
		kMesh.SetRotation(rot);
		if(idx != -1)
		{
			WeaponModel[idx].fPitch = tD.fPitch + fAdjP;
			WeaponModel[idx].fYaw = tD.fYaw + fAdjY;
			SaveConfig();
		}
	}
}
function AddBindings()
{
	local KeyBind NewBinding;
	local PlayerInput kInput;

	NewBinding.Name='Up';
	NewBinding.Control=true;
	NewBinding.Command="Mutate AWM_PitchUp";
	kInput = class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().PlayerInput;
	kInput.Bindings[kInput.Bindings.Length] = NewBinding;

	NewBinding.Name='Down';
	NewBinding.Control=true;
	NewBinding.Command="Mutate AWM_PitchDown";
	kInput = class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().PlayerInput;
	kInput.Bindings[kInput.Bindings.Length] = NewBinding;

	NewBinding.Name='Left';
	NewBinding.Control=true;
	NewBinding.Command="Mutate AWM_YawLeft";
	kInput = class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().PlayerInput;
	kInput.Bindings[kInput.Bindings.Length] = NewBinding;

	NewBinding.Name='Right';
	NewBinding.Control=true;
	NewBinding.Command="Mutate AWM_YawRight";
	kInput = class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().PlayerInput;
	kInput.Bindings[kInput.Bindings.Length] = NewBinding;
}
DefaultProperties
{
	m_strBuildVersion="0.5.20240106"
}