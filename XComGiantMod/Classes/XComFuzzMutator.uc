class XComFuzzMutator extends XComMutator
	config(GiantMod);

var XGRecapSaveData m_kSaveData;
var config bool bKeepOriginalWtS;
var config bool bDeepCover;
var config bool bXComHPRegen;

function PostLevelLoaded(PlayerController PC)
{
	PostLoadSaveGame(PC);
}
function PostLoadSaveGame(PlayerController PC)
{
	m_kSaveData=class'XGSaveHelper'.static.GetSaveData("FuzzMutator");
	RegisterWatchVars();
	ConvertPerksFlags();
}
function RegisterWatchVars()
{
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle(), 'm_iResult', self, OnBattleDone); 
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_arrPlayers[0], 'm_bMyTurn', self, OnHumanPlayerTurnChange, 0); 
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_arrPlayers[1], 'm_bMyTurn', self, OnAIPlayerTurnChange, 0); 
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XGBattle_SP(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle()).GetHumanPlayer().GetSquad(), 'm_iNumPermanentUnits', self, OnHumanReinforcements);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XGBattle_SP(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle()).GetAIPlayer().GetSquad(), 'm_iNumPermanentUnits', self, OnAlienReinforcements);
}
function OnHumanPlayerTurnChange()
{
	if(!XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_arrPlayers[0].m_bMyTurn)
	{
		OnHumanPlayerEndTurn();
	}
	else if(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_arrPlayers[0].m_bMyTurn)
	{
		OnHumanPlayerBeginTurn();
	}
}
function OnAIPlayerTurnChange()
{
	if(!XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_arrPlayers[1].m_bMyTurn)
	{
		OnAIPlayerEndTurn();
	}
	else if(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_arrPlayers[1].m_bMyTurn)
	{
		OnAIPlayerBeginTurn();
	}

}
/** At this stage the m_kActivePlayer is still the player whose turn is ending*/
function OnPlayerEndTurn()
{
	local XGUnit kUnit;
	local XGSquad kSquad;
	local int iSquadMate;

	kSquad = XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_kActivePlayer.GetSquad();
	for(iSquadMate=0; iSquadMate < kSquad.GetNumMembers(); ++ iSquadMate)
	{
		kUnit = kSquad.GetMemberAt(iSquadMate);
		if(kUnit.IsAliveAndWell())
		{
			EndTurnHunkerDownCheck(kUnit);
		}
	}
}
function EndTurnHunkerDownCheck(XGUnit kUnit)
{
	if( bDeepCover && kUnit.GetNumberOfSuppressionTargets() == 0 
		&& kUnit.m_aCurrentStats[eStat_Reaction] == 0 
		&& class'XGSaveHelper'.static.GetSavedValueString(m_kSaveData, kUnit, "DeepCover") == "1"
		&& !kUnit.IsStrangled() && !kUnit.IsFlying() && !kUnit.IsHunkeredDown())
	{
		if(kUnit.GetMoves() == 0)
		{
			kUnit.GiveOneMoveAndOneAction();
		}
		kUnit.PerformAbility(eAbility_TakeCover);
	}
}
function OnHumanPlayerEndTurn()
{
	OnPlayerEndTurn();
}
function OnAIPlayerEndTurn()
{
	OnPlayerEndTurn();
}
function OnHumanPlayerBeginTurn()
{
	local XGUnit kUnit;
	local XGSquad kSquad;
	local int iSquadMate;

	kSquad = XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_kActivePlayer.GetSquad();
	for(iSquadMate=0; iSquadMate < kSquad.GetNumMembers(); ++ iSquadMate)
	{
		kUnit = kSquad.GetMemberAt(iSquadMate);
		if(kUnit.IsAliveAndWell())
		{
			HealXComUnitCheck(kUnit);
		}
	}
}
function OnAIPlayerBeginTurn()
{
}
function HealXComUnitCheck(XGUnit kUnit)
{
	if(bXComHPRegen && kUnit.GetUnitHP() < kUnit.GetUnitMaxHP())
	{
		kUnit.SetUnitHP(kUnit.GetUnitHP() + 1);
		XComTacticalController(GetALocalPlayerController()).m_Pres.GetWorldMessenger().Message("Healed 1", kUnit.GetLocation());
	}
}
function OnHumanReinforcements()
{
	ConvertPerksFlags();
}
function OnAlienReinforcements()
{
	ConvertPerksFlags();
}
function ConvertPerksFlags(optional bool bEndOfBattle)
{
	local XGUnit kUnit;

	foreach DynamicActors(class'XGUnit', kUnit)
	{
		if(!bEndOfBattle)
		{
			ConvertPerksToCustomFlags(kUnit);
		}
		else
		{
			ConvertFlagsToPerks(kUnit);
		}
	}
}
function ConvertPerksToCustomFlags(XGUnit kUnit)
{
	if(kUnit.GetCharacter().HasUpgrade(ePerk_WillToSurvive))
	{
		class'XGSaveHelper'.static.SaveValueString(m_kSaveData, kUnit, "DeepCover", 1);
		class'XGSaveHelper'.static.SaveValueString(m_kSaveData, kUnit, "WtS", kUnit.GetCharacter().m_kChar.aUpgrades[ePerk_WillToSurvive]);
		if(!bKeepOriginalWtS)
		{
			kUnit.GetCharacter().m_kChar.aUpgrades[ePerk_WillToSurvive]=0;
		}
	}
}
function ConvertFlagsToPerks(XGUnit kUnit)
{
	if(class'XGSaveHelper'.static.GetSavedValueString(m_kSaveData, kUnit, "DeepCover") != "")
	{
		kUnit.GetCharacter().m_kChar.aUpgrades[ePerk_WillToSurvive] = int(class'XGSaveHelper'.static.GetSavedValueString(m_kSaveData, kUnit, "WtS"));
	}
}
function OnBattleDone()
{
	if(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetBattle().m_iResult != 0)
	{
		ConvertPerksFlags(true);
		m_kSaveData.Destroy();
	}
}

function MutateUpdateInteractClaim(string strUnitName, PlayerController PC)
{
	local XGUnit kUnit;

	return;
	foreach DynamicActors(class'XGUnit', kUnit)
	{
		if(string(kUnit) == strUnitName)
		{
			break;
		}
	}
}
DefaultProperties
{
}
