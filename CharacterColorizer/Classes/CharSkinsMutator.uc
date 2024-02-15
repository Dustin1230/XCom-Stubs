class CharSkinsMutator extends XComMutator
	config(CharacterSkins);

struct TConfigSkinData
{
	var int iChar;
	var int iLeaderLvl;
	var string Skin;
};

var string m_strBuildVersion;
var config array<TConfigSkinData> AlienSkins;
var config bool RANDOM_ZOMBIE_COLORS;
var int m_iNumPermanentHumans;
var int m_iNumPermanentAliens;

function string GetDebugName()
{
	return Class.Name @ m_strBuildVersion;
}
function XGBattle_SP BATTLE()
{
	return (WorldInfo.GRI != none ? XGBattle_SP(XComTacticalGRI(WorldInfo.GRI).m_kBattle) : none);
}
static function bool IsLongWarBuild()
{
	return class'XComPerkManager'.default.SoldierPerkTrees.Length > 15;
}

function Mutate(string MutString, PlayerController Sender)
{
	if(InStr(MutString, "AliensLevelUp",,true) != -1)
	{
		IncreaseAlienLevels();
	}
	else if(InStr(MutString, "CharSkinsMutator.ApplySkins",,true) != -1)
	{
		ApplySkins();
	}
	super.Mutate(MutString, Sender);
}
event PostBeginPlay()
{
	super.PostBeginPlay();
	`Log(GetFuncName() @ GetDebugName());
	if(XComTacticalGame(WorldInfo.Game) != none)
	{
		PollForBattleReady();
	}
}
function PollForBattleReady()
{
	if(IsBattleReady())
	{
		RegisterWatchVars();
		ApplyArchetypeSkins();
		ApplySkins();
		TestStuff();
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
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(BATTLE().GetHumanPlayer().GetSquad(), 'm_iNumPermanentUnits', self, OnNewHumanUnit);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(BATTLE().GetAIPlayer().GetSquad(), 'm_iNumPermanentUnits', self, OnNewAlienUnit);
}
function OnNewHumanUnit()
{
}
function OnNewAlienUnit()
{
	local XGUnit kNewUnit;
	local XGSquad kSquad;
	local int iNewSquadSize;


	kSquad = BATTLE().GetAIPlayer().GetSquad();
	iNewSquadSize = kSquad.GetNumPermanentMembers();
	while(m_iNumPermanentAliens < iNewSquadSize)
	{
		kNewUnit = kSquad.m_arrPermanentMembers[m_iNumPermanentAliens];
		ApplySkin(kNewUnit, GetAlienSkin(kNewUnit));
		++ m_iNumPermanentAliens;
	}
}
function ApplyArchetypeSkins()
{
	local TConfigSkinData tSkin;
	local XGUnit kUnit;
	local int I;
	local XComUnitPawn kArchetype;

	foreach AlienSkins(tSkin)
	{
		if(tSkin.iLeaderLvl == 0 && DynamicLoadObject(tSkin.Skin, class'Texture2D', true) != none)
		{
			foreach DynamicActors(class'XGUnit', kUnit)
			{
				if(kUnit.GetCharType() == tSkin.iChar)
				{
					kArchetype = kUnit.GetCharacter().GetPawnArchetype();
					`log(kUnit.GetPawnType() @ "has" @ kArchetype.Mesh.GetNumElements() @ "materials",,GetFuncName());
					for(I=0; I < kArchetype.Mesh.GetNumElements(); ++I)
					{
						MaterialInstance(kArchetype.Mesh.GetMaterial(I)).SetTextureParameterValue('Diffuse', Texture2D(DynamicLoadObject(tSkin.Skin, class'Texture2D')));
						if(kArchetype.IsA('XComExalt') || kArchetype.IsA('XComZombie'))
						{
							break;
						}
					}
					break;
				}
			}
		}
	}
}
function ApplySkins()
{
	local XGUnit kUnit;

	foreach DynamicActors(class'XGUnit', kUnit)
	{
		if(RANDOM_ZOMBIE_COLORS && kUnit.m_kZombieVictim == none && kUnit.GetPawn() != none && kUnit.GetPawn().IsA('XComZombie') && kUnit.m_iProximityMines == 0)
		{
			kUnit.m_iProximityMines = 1+Rand(9);
		}
		if(kUnit.IsAlien_CheckByCharType())
		{
			ApplySkin(kUnit, GetAlienSkin(kUnit));
		}
	}
}
static function CSM_WatchActor GetWatchActorFor(XGUnit kUnit)
{
	local CSM_WatchActor kWatcher;
	local WorldInfo kInfo;

	kInfo = class'Engine'.static.GetCurrentWorldInfo();

	foreach kInfo.DynamicActors(class'CSM_WatchActor', kWatcher)
	{
		if(kWatcher.m_kUnit == kUnit)
			return kWatcher;
	}
	return none;
}
static function ApplySkin(XGUnit kUnit, Texture kNewSkin, optional bool bSpawnWatchActor=true)
{
	local int iElement;
	local LinearColor tCMOD;

	`log(kUnit.GetPawnType() @ GetSkinPath(kUnit),,GetFuncName());
	if(kNewSkin != none && kUnit.GetPawn() != none)
	{
		if(kUnit.GetPawn().IsA('XComOutsider') && kUnit.IsDead())
		for(iElement=0; iElement < kUnit.GetPawn().Mesh.GetNumElements(); ++iElement)
		{
			kUnit.GetPawn().Mesh.CreateAndSetMaterialInstanceConstant(iElement).SetTextureParameterValue('Diffuse', kNewSkin);
			if(kUnit.GetPawn().IsA('XComElder') && kUnit.GetPawn().Mesh.GetMaterial(iElement).GetVectorParameterValue('CMOD', tCMOD))
			{
				if(GetSkinPath(kUnit) ~= "CHA_Elder_MOD.Textures.Elder_DIF")
				{
					tCMOD.R=0.0828699;
					tCMOD.G=0.00127869;
				}
				else
				{
					tCMOD.R=0;
					tCMOD.G=0;
				}
				MaterialInstance(kUnit.GetPawn().Mesh.GetMaterial(iElement)).SetVectorParameterValue('CMOD', tCMOD);
			}
			if(kUnit.GetPawn().IsA('XComExalt') || kUnit.GetPawn().IsA('XComZombie'))
			{
				break;
			}		
		}
		if(bSpawnWatchActor && GetWatchActorFor(kUnit) == none)
		{
			kUnit.Spawn(class'CSM_WatchActor').WatchMaterialsForUnit(kUnit);
		}
		GetWatchActorFor(kUnit).m_kCharSkin = kNewSkin;
	}
}
static function string GetSkinPath(XGUnit kUnit)
{
	local TConfigSkinData tSkin;
	local int iLvl;
	local string strPath;

	foreach default.AlienSkins(tSkin)
	{
		if(kUnit.GetCharType() == tSkin.iChar)
		{
			if(tSkin.iLeaderLvl >= iLvl && GetAlienLeaderLvl(kUnit) >= tSkin.iLeaderLvl)
			{
				iLvl = tSkin.iLeaderLvl;
				strPath = tSkin.Skin;
			}
		}
	}
	return strPath;
}
static function Texture2D GetAlienSkin(XGUnit kUnit)
{
	return Texture2D(DynamicLoadObject(GetSkinPath(kUnit), class'Texture2D', true));
}
static function int GetAlienLeaderLvl(XGUnit kUnit)
{
	if(IsLongWarBuild())
	{
		return int(kUnit.IsAlien_CheckByCharType()) * kUnit.m_iProximityMines;
	}
	else
	{
		return int(kUnit.IsAlien_CheckByCharType()) * kUnit.GetUnitMaxHP();
	}
}
static function bool IsAlienLeader(XGUnit kUnit)
{
	return GetAlienLeaderLvl(kUnit) > 0;
}
function IncreaseAlienLevels()
{
	local XGUnit kUnit;

	foreach DynamicActors(class'XGUnit', kUnit)
	{
		if(kUnit.IsAlien_CheckByCharType())
		{
			kUnit.m_iProximityMines++;
			if(kUnit.m_iProximityMines > 9)
			{
				kUnit.m_iProximityMines = 0;
			}
		}
	}
	ApplySkins();
}
function TestStuff()
{
	local KeyBind NewBinding;
	local array<OnlineContent> arrDLCs;
	local OnlineContent DLCBundle;
	local string sLog, sPackage;
	local PlayerInput kInput;


	NewBinding.Name='L';
	NewBinding.Control=true;
	NewBinding.Command="Mutate AliensLevelUp";
	kInput = class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().PlayerInput;
	kInput.Bindings[kInput.Bindings.Length] = NewBinding;

	NewBinding.Name='S';
	NewBinding.Control=true;
	NewBinding.Alt=true;
	NewBinding.Command="Mutate CharSkinsMutator.ApplySkins";
	kInput = class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().PlayerInput;
	kInput.Bindings[kInput.Bindings.Length] = NewBinding;

	if(XComEngine(class'Engine'.static.GetEngine()).DLCEnumerator != none && XComEngine(class'Engine'.static.GetEngine()).DLCEnumerator.DLCBundles.Length > 0)
	{
		arrDLCs = XComEngine(class'Engine'.static.GetEngine()).DLCEnumerator.DLCBundles;
		sLog = "Found" @ arrDLCs.Length @ "DLC bundles";
		foreach arrDLCs(DLCBundle)
		{
			sLog $="\n"$Chr(9);
			sLog $= DLCBundle.FriendlyName;
			sLog $="\n"$Chr(9);
			sLog $= string(DLCBundle.UserIndex);
			sLog $="\n"$Chr(9);
			sLog $= string(DLCBundle.bIsCorrupt);
			sLog $="\n"$Chr(9);
			sLog $= string(DLCBundle.DeviceId);
			sLog $="\n"$Chr(9);
			sLog $= string(DLCBundle.LicenseMask);
			sLog $="\n"$Chr(9);
			sLog $= DLCBundle.Filename;
			sLog $="\n"$Chr(9);
			sLog $= DLCBundle.ContentPath;
			foreach DLCBundle.ContentPackages(sPackage)
			{
				sLog $="\n"$Chr(9);
				sLog $= sPackage;
			}
			sLog $="\n"$Chr(9);
			sLog $= "NumFiles:" @ DLCBundle.ContentFiles.Length;
		}
		`log(sLog,,GetFuncName());
	}
}
//[0030.78] ScriptLog: ePawnType_Sectoid has 1 materials
//[0030.78] ScriptLog: ePawnType_Sectoid_Commander has 2 materials
//[0030.78] ScriptLog: ePawnType_ThinMan has 1 materials
//[0030.78] ScriptLog: ePawnType_Floater has 1 materials
//[0030.78] ScriptLog: ePawnType_Floater_Heavy has 1 materials
//[0030.78] ScriptLog: ePawnType_Muton has 1 materials
//[0030.78] ScriptLog: ePawnType_Muton_Elite has 1 materials
//[0030.78] ScriptLog: ePawnType_Muton_Berserker has 1 materials
//[0030.78] ScriptLog: ePawnType_CyberDisc has 2 materials
//[0030.78] ScriptLog: ePawnType_Elder has 2 materials
//[0030.78] ScriptLog: ePawnType_Chryssalid has 1 materials
//[0030.78] ScriptLog: ePawnType_Sectopod has 1 materials
//[0030.78] ScriptLog: ePawnType_SectopodDrone has 1 materials
//[0030.78] ScriptLog: ePawnType_Seeker has 1 materials
//[0030.78] ScriptLog: ePawnType_Mechtoid has 3 materials
//[0030.78] ScriptLog: ePawnType_Outsider has 1 materials
//[0030.78] ScriptLog: ePawnType_Zombie has 5 materials
//[0030.78] ScriptLog: ePawnType_ExaltOperative has 2 materials
//[0030.78] ScriptLog: ePawnType_ExaltSniper has 2 materials
//[0030.78] ScriptLog: ePawnType_ExaltEliteOperative has 2 materials
//[0030.78] ScriptLog: ePawnType_ExaltEliteSniper has 2 materials
//[0030.78] ScriptLog: ePawnType_ExaltEliteHeavy has 3 materials

DefaultProperties
{
	m_strBuildVersion="1.0"
}
