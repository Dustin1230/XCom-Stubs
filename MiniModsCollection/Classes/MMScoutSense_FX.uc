class MMScoutSense_FX extends DynamicSMActor_Spawnable;

var XGUnit m_kUnit;
var XGUnit m_kNearestEnemy;
var float m_fDistanceToEnemySq;
var string m_strPerceptionInfo;
var string m_strMessageID;
var bool m_bCueIsValid;

event PostBeginPlay()
{
    super.PostBeginPlay();
	StaticMeshComponent.SetStaticMesh(GetVisualizerMesh());
	SetHidden(true);
	SetTickIsDisabled(true);
	m_bCueIsValid = class'MiniModsTactical'.default.m_bScoutSense;
}
function Init(XGUnit kUnit)
{
	m_kUnit = kUnit;
	SetBase(kUnit.GetPawn());
	m_strMessageID = "ScoutSense"$GetRightMost(kUnit);
}
function ToggleVisibility()
{
	if(bHidden)
	{
		if(m_bCueIsValid)
		{
			SetHidden(false);
			m_kNearestEnemy.DelayAlienHiddenMovementSounds();
		}
		ShowPerceptionInfo();
	}
	else
	{
		SetHidden(true);
		HidePerceptionInfo();
	}
}
function UpdateDirection(optional bool bUpdateScale)
{
	local Vector vAimDir, vStart, vEnd;
	local float fTheta;
	local Vector vScale;

	if(m_kNearestEnemy != none)
	{
		vStart = m_kUnit.GetLocation();
		vEnd = m_kNearestEnemy.GetLocation();
		vAimDir = vEnd - vStart;
		vAimDir.Z = 0.0;
		vAimDir = Normal(vAimDir);
		SetLocation(m_kUnit.Location);
		SetRotation(rotator(vAimDir));
	}
	if(bUpdateScale)
	{
		fTheta = 3.1415930 / 30.0;
		vScale.X = 25.0 * float(64);
		vScale.Y = vScale.X * Sin(fTheta);
		vScale.Z = 15.0;
		SetDrawScale3D(vScale);
	}
}
function UpdateNearestEnemy()
{
	local string strMessage, strCallback;

	//LogInternal(GetFuncName() @ GetStateName() @  m_kUnit.SafeGetCharacterFullName());
	m_kNearestEnemy = GetNearestEnemy(m_kUnit.GetLocation(), m_fDistanceToEnemySq);
	m_bCueIsValid = (m_fDistanceToEnemySq > 0.0 && int(Sqrt(m_fDistanceToEnemySq)/96.0) <= class'MiniModsTactical'.default.m_iScoutSenseMaxRange);
	m_bCueIsValid = m_bCueIsValid && m_kUnit.IsAliveAndWell();

    if(class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator != none)
    {
		strMessage = "MMScoutSense_FX.UpdateNearestEnemy(m_bCueIsValid):" $ self;
		strCallback = string(m_bCueIsValid);
        class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator.ModifyLogin(strMessage, strCallback);
		if(InStr(strCallback, "Return:") != -1)
		{
			m_bCueIsValid = bool(Split(strCallback, "Return:",true));
		}
    }

}
function ShowPerceptionInfo()
{
	BuildPerceptionInfo();
	XComPlayerController(GetALocalPlayerController()).m_Pres.GetWorldMessenger().Message(m_strPerceptionInfo, m_kUnit.GetLocation(),,1,m_strMessageID,,,,-1.0);
}
function HidePerceptionInfo()
{
	XComPlayerController(GetALocalPlayerController()).m_Pres.GetWorldMessenger().RemoveMessage(m_strMessageID);
}
function BuildPerceptionInfo()
{
	local int iTiles, iRank;
	local string strEnemyName, strEnemyUnknown;
	
	strEnemyUnknown = Left(class'XGAbility_Targeted'.default.m_strBonusCritEnemyNotInCover, InStr(class'XGAbility_Targeted'.default.m_strBonusCritEnemyNotInCover, " "));
	iTiles = Sqrt(m_fDistanceToEnemySq)/96.0;
	if(iTiles > 0 && iTiles <= class'MiniModsTactical'.default.m_iScoutSenseMaxRange)
	{
		if(m_kNearestEnemy.IsExalt())
		{
			strEnemyName = Left(class'XLocalizedData'.default.m_aCharacterName[eChar_ExaltOperative], InStr(class'XLocalizedData'.default.m_aCharacterName[eChar_ExaltOperative], " "));
		}
		else
		{
			strEnemyName = class'XLocalizedData'.default.m_aCharacterName[m_kNearestEnemy.GetCharType()];
		}
		if(class'MiniModsTactical'.default.m_bScoutSenseScalesWithRank)
		{
			iRank = XGCharacter_Soldier(m_kUnit.GetCharacter()).m_kSoldier.iRank;
		}
		else
		{
			iRank = 7;
		}
		if(iRank >= class'MiniModsTactical'.default.m_iScoutSenseLvl3Rank)
		{
			m_strPerceptionInfo = strEnemyName $ "," @ class'MiniModsTactical'.default.m_strDistanceInTiles @ iTiles;
		}
		else if(iRank >= class'MiniModsTactical'.default.m_iScoutSenseLvl2Rank)
		{
			m_strPerceptionInfo = strEnemyName $ "," @ GetVagueDistanceInfo(iTiles);
		}
		else if(iRank >= class'MiniModsTactical'.default.m_iScoutSenseLvl1Rank)
		{
			m_strPerceptionInfo = strEnemyUnknown $ "," @ GetVagueDistanceInfo(iTiles);
		}
		else 
		{
			m_strPerceptionInfo = strEnemyUnknown;
		}
	}
	else
	{
		m_strPerceptionInfo = class'MiniModsTactical'.default.m_strScoutSenseBeyondRange;
	}
    if(class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator != none)
    {
		strEnemyName = "MMScoutSense_FX.BuildPerceptionInfo:" $ self;
        class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator.ModifyLogin(strEnemyName, m_strPerceptionInfo);
    }

}
function string GetVagueDistanceInfo(int iDistance)
{
	local TScoutSenseInfo tRange;

    foreach class'MiniModsTactical'.default.ScoutSenseRange(tRange)
    {
        if(iDistance < tRange.iDistance)
            break;
    }
	return class'MiniModsTactical'.default.m_strScoutSenseMessage[tRange.iMessageID];
}
function XGUnit GetNearestEnemy(Vector vPoint, optional out float fClosestDist)
{
	local XGSquad kEnemySquad;
	local XGUnit kEnemy, kClosest;
	local float fDist;
	local int i;

	kEnemySquad = XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle.GetEnemySquad(m_kUnit.GetPlayer());
	fClosestDist = -1.0;
	if(kEnemySquad != none)
	{
		for(i=0; i <= kEnemySquad.GetNumMembers(); ++i)
		{
			kEnemy = kEnemySquad.GetMemberAt(i);
			if(kEnemy == none || (kEnemy.GetCharType() == eChar_Seeker && kEnemy.IsHiding()) || kEnemy.IsDead() || kEnemy.IsCriticallyWounded())
			{
				continue;
			}
			fDist = VSizeSq(kEnemy.GetLocation() - vPoint);
			if(kClosest == none || fDist < fClosestDist)
			{
				kClosest = kEnemy;
				fClosestDist = fDist;
			}
		}
	}
	return kClosest;
}
simulated event Tick(float fDeltaTime)
{
	if(m_kNearestEnemy != none)
	{
		UpdateDirection();
	}
}
function StaticMesh GetVisualizerMesh()
{
    return StaticMesh(DynamicLoadObject("UI_Range.Meshes.Overmind_Direction", class'StaticMesh'));
}
DefaultProperties
{
}
