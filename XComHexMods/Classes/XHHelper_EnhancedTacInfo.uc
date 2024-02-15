class XHHelper_EnhancedTacInfo extends Actor
	config(HexMods);

var XHGfxSoldierStats m_gfxStats;
var XGUnit m_kUnit;
var config bool m_bAlienStatsRequireAutopsy;
var array<int> m_arrCharToIdxMap;

function Init(XGUnit kUnit)
{
	m_kUnit = kUnit;
}
function AttachStatIcons()
{
	LoadGfxComponents();
	SetTimer(0.05, true, 'PollForMovieLoaded'); //loading a movie takes time dependent on PC performance
}
/** Load SoldierSummary.swf into F1 panel*/
function LoadGfxComponents()
{
	local GFxObject gfxPanel, gfxSoldierSummary;
	local array<ASValue> arrParams;
	local ASValue myParam;

	gfxPanel = PRES().m_kGermanMode.manager.GetVariableObject(string(PRES().m_kGermanMode.GetMCPath()));
	gfxSoldierSummary = gfxPanel.CreateEmptyMovieClip("SoldierSummary"); //create a placeholder for .swf file
		myParam.Type = AS_String;
		myParam.s = "/ package/gfxSoldierSummary/SoldierSummary"; //provide path to .swf movie
		arrParams.AddItem(myParam); //put the path into params array
	gfxSoldierSummary.Invoke("loadMovie", arrParams);	//call loadMovie method with provided path as param
}
/** Checks if the movie has finished loading*/
function PollForMovieLoaded()
{
	if(PRES().m_kGermanMode.manager.GetVariableObject(string(PRES().m_kGermanMode.GetMCPath()) $ ".SoldierSummary.theScreen.soldierStatsMC") != none)
	{
		ClearTimer(GetFuncName());
		SetupGfx();
	}
}
function SetupGfx()
{
	local GFxObject gfxSummary, gfxPanel;

	gfxPanel = PRES().m_kGermanMode.manager.GetVariableObject(string(PRES().m_kGermanMode.GetMCPath()));
	gfxSummary = gfxPanel.GetObject("SoldierSummary").GetObject("theScreen");
	gfxSummary.SetFloat("_x", gfxPanel.GetObject("bg").GetFloat("_x"));
	gfxPanel.CreateEmptyMovieClip("UnitStats");
	gfxPanel.SetObject("UnitStats", gfxSummary.GetObject("soldierStatsMC"));
	m_gfxStats = XHGfxSoldierStats(gfxPanel.GetObject("UnitStats", class'XHGfxSoldierStats'));

	//hide unnecessary pieces of clips
	gfxSummary.GetObject("bg").SetVisible(false); 
	gfxPanel.GetObject("header").GetObject("statHealth").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("statWill").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("statOffense").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("statDefense").SetVisible(false);
	//in case of original Enhanced Tactical Info existing
	if(gfxPanel.GetObject("header").GetObject("statMobility") != none)
	{
		`Log(GetFuncName() @ "original EnhTacInfo detected");
		SetTimer(0.05, false, 'HideOrigInfoGfx');
	}
	m_gfxStats.GetObject("bg").SetVisible(false);
	m_gfxStats.GetObject("fuelIcon").SetVisible(false);
	m_gfxStats.GetObject("fuelText").SetVisible(false);	

	m_gfxStats.SetPosition(50.0, -310.0);
	m_gfxStats.LineUpIcons();
	m_gfxStats.AttachTextBoxes();
}
function HideOrigInfoGfx()
{
	local GFxObject gfxPanel;

	gfxPanel = PRES().m_kGermanMode.manager.GetVariableObject(string(PRES().m_kGermanMode.GetMCPath()));
	gfxPanel.GetObject("header").GetObject("statMobility").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("statXP").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("statPsiXP").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("statDR").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("iconHealth").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("iconDR").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("iconDefense").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("iconOffense").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("iconWill").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("iconMobility").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("iconPsiXP").SetVisible(false);
	gfxPanel.GetObject("header").GetObject("iconXP").SetVisible(false);
	if(XGCharacter_Soldier(m_kUnit.GetCharacter()) != none)
	{
		gfxPanel.GetObject("header").GetObject("soldierInfo").GetObject("unitNickname").SetString("htmlText", XGCharacter_Soldier(m_kUnit.GetCharacter()).m_kSoldier.strNickName != "" ? "'"$XGCharacter_Soldier(m_kUnit.GetCharacter()).m_kSoldier.strNickName$"'" : "");
	}
}
function SetUnitStats()
{
	local string sXP, sPsiXP, sHP, sAim, sDef, sMob, sWill, sDR;
	local XGCharacter_Soldier kChar;
    local int aModifiers[ECharacterStat], iPctDR, iMinStaticDR, iMaxStaticDR;
    local array<int> arrBackPackItems;
	
	sHP     = string(Max(m_kUnit.GetUnitMaxHP(), m_kUnit.m_aCurrentStats[0]));
	sAim    = string(m_kUnit.GetOffense());
	sDef    = string(PRES().m_kGermanMode.GetDefenseBonus(m_kUnit));
	sWill   = string(PRES().m_kGermanMode.GetWillBonus(m_kUnit));
	sMob    = string(m_kUnit.GetMaxPathLength());
	//xcom
	if(XGCharacter_Soldier(m_kUnit.GetCharacter()) != none)
	{
		kChar = XGCharacter_Soldier(m_kUnit.GetCharacter());
		sXP     = kChar.GetXP() $ "/" $ TACTICAL().GetXPRequired(kChar.m_kSoldier.iRank + 1);
		if(kChar.m_kSoldier.iPsiRank >= 1)
		{
			sPsiXP  = kChar.m_kSoldier.iPsiXP $ "/" $ TACTICAL().GetPsiXPRequired(kChar.m_kSoldier.iPsiRank + 1);
		}

		TACTICAL().GetBackpackItemArray(kChar.m_kChar.kInventory, arrBackPackItems);
		TACTICAL().GetInventoryStatModifiers(aModifiers, kChar.m_kChar, TACTICAL().GetEquipWeapon(kChar.m_kChar.kInventory), arrBackPackItems);
		
		if(aModifiers[eStat_HP] != 0)
		{
			sHP = string(int(sHP) - aModifiers[eStat_HP]) $ "|" $ (aModifiers[eStat_HP] > 0 ? "+" : "") $ string(aModifiers[eStat_HP]);
		}
		if(aModifiers[eStat_Offense] != 0)
		{
			sAim = string(int(sAim) - aModifiers[eStat_Offense]) $ "|" $ (aModifiers[eStat_Offense] > 0 ? "+" : "") $ string(aModifiers[eStat_Offense]);
		}
		if(aModifiers[eStat_Defense] != 0)
		{
			sDef = string(int(sDef) - aModifiers[eStat_Defense]) $ "|" $ (aModifiers[eStat_Defense] > 0 ? "+" : "") $ string(aModifiers[eStat_Defense]);
		}
		if(aModifiers[eStat_Mobility] != 0)
		{
			sMob = string(int(sMob) - aModifiers[eStat_Mobility]) $ "|" $ (aModifiers[eStat_Mobility] > 0 ? "+" : "") $ string(aModifiers[eStat_Mobility]);
		}
		sMob = sMob @ "<font color='#67E8ED' size='20'>(" $ int(m_kUnit.GetMaxPathDistance()/96.0) @ "tiles)</font>";
		if(aModifiers[eStat_Will] != 0)
		{
			sWill = string(int(sWill) - aModifiers[eStat_Will]) $ "|" $ (aModifiers[eStat_Will] > 0 ? "+" : "") $ string(aModifiers[eStat_Will]);
		}
		//sDR = string((aModifiers[4] % 100) / 10) $ "." $ string((aModifiers[4] % 100) % 10);
	}
	else
	{
		//alien
	}
	EstimateDR(iPctDR, iMinStaticDR, iMaxStaticDR);
	sDR = (iPctDR > 0 ? iPctDR $"% + " : "") $ (iMinStaticDR != iMaxStaticDR ? iMinStaticDR $"-"$iMaxStaticDR : string(iMaxStaticDR));
	if(m_kUnit.GetTeam() == eTeam_XCom)
	{
		m_gfxStats.SetSoldierStats(sXP, sPsiXP, sHP, sAim, sDef, sMob, sWill, sDR);
		m_gfxStats.SetVisible(true);
	}
	else if(!m_bAlienStatsRequireAutopsy || XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore.m_kAbilities.HasAutopsyTechForChar(m_kUnit.GetCharType()))
	{
		m_gfxStats.SetAlienStats(sHP, sAim, sDef, sMob, sWill, sDR);
		m_gfxStats.SetVisible(true);
	}
	else
	{
		m_gfxStats.SetVisible(false);
	}
}
function EstimateDR(out int iPctDR, out int iMinDR, out int iMaxDR)
{
	local int i, iStaticDR, iDmgOutput;
	local XGBattle_SP kBattle;
	local XGUnit kActiveUnit;
	local XGWeapon kWeapon;

	kBattle = XGBattle_SP(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle);
	kActiveUnit = kBattle.m_kActivePlayer.GetActiveUnit();
	kWeapon = kActiveUnit.GetInventory().GetActiveWeapon();
	if(m_kUnit == kActiveUnit)
	{
		kActiveUnit = none;
		kWeapon = none;
	}
	iMinDR = 9999;
	iMaxDR = -1;
	for(i=0; i<10; ++i)
	{
		iDmgOutput = m_kUnit.AbsorbDamage(10000, kActiveUnit, kWeapon);
		iPctDR = 100 - FCeil(float(iDmgOutput) / 100.0);
		iStaticDR = m_kUnit.m_bCantBeHurt - iPctDR * 100;
		iMinDR = Min(iMinDR, iStaticDR);
		iMaxDR = Max(iMaxDR, iStaticDR);
		if(iMaxDR != iMinDR)
		{
			return;
		}
	}
}
function SetAlienCounts(optional bool bForAlien)
{
	local array<int> arrActiveEnemyTypes;
	local int i, idx, iBox, iNeutralized;
	local XGSquad kEnemySquad;
	local XGUnit kEnemy;

	arrActiveEnemyTypes.Add(m_arrCharToIdxMap.Length);
	kEnemySquad = XGBattle_SP(GRI().GetBattle()).GetAIPlayer().GetSquad();
	for(i=0; i < kEnemySquad.GetNumMembers(); ++i)
	{
		kEnemy = kEnemySquad.GetMemberAt(i);
		if(kEnemy.IsAliveAndWell() && !kEnemy.IsDormant())
		{
			idx = GetArrayIdxFromType(kEnemy.GetCharType());
			++arrActiveEnemyTypes[idx];
		}
		else if(kEnemy.IsDead() || kEnemy.IsCriticallyWounded())
		{
			++iNeutralized;
		}
	}
	iBox = 0;
	for(i=0; i < arrActiveEnemyTypes.Length; ++i)
	{
		if(arrActiveEnemyTypes[i] > 0 && iBox < 11)
		{
			if(iBox==0)
			{
				m_gfxStats.SetInfoText(iBox++, bForAlien ? class'UIUtilities'.static.GetHTMLColoredText(class'XGMissionControlUI'.default.m_strLabelAlienSpecies, eUIState_Bad) : class'XGMissionControlUI'.default.m_strLabelAlienSpecies);
			}
			idx = ArrayIdxToChar(i);
			m_gfxStats.SetInfoText(iBox, bForAlien ? class'UIUtilities'.static.GetHTMLColoredText(class'XLocalizedData'.default.m_aCharacterName[idx], eUIState_Bad) : class'XLocalizedData'.default.m_aCharacterName[idx]);
			m_gfxStats.SetInfoExtText(iBox++, bForAlien ? class'UIUtilities'.static.GetHTMLColoredText(string(arrActiveEnemyTypes[i]), eUIState_Bad) : string(arrActiveEnemyTypes[i]));
		}
	}
	if(iNeutralized > 0)
	{
		m_gfxStats.SetInfoText(iBox, bForAlien ? class'UIUtilities'.static.GetHTMLColoredText(class'XGSummaryUI'.default.m_strLabelAliensKilled, eUIState_Bad) : class'XGSummaryUI'.default.m_strLabelAliensKilled);
		m_gfxStats.SetInfoExtText(iBox++, bForAlien ? class'UIUtilities'.static.GetHTMLColoredText(string(iNeutralized), eUIState_Bad) : string(iNeutralized));
	}
}
function int GetArrayIdxFromType(int iType)
{
	return m_arrCharToIdxMap.Find(iType);
}
function int ArrayIdxToChar(int idx)
{
	return m_arrCharToIdxMap[idx];
}
function XComPresentationLayer PRES()
{
	return XComPresentationLayer(XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).m_Pres);
}
function XComTacticalGRI GRI()
{
	return XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI);
}
function XGTacticalGameCore TACTICAL()
{
	return GRI().m_kGameCore;
}
DefaultProperties
{
	m_arrCharToIdxMap(0)=4
	m_arrCharToIdxMap(1)=17
	m_arrCharToIdxMap(2)=6
	m_arrCharToIdxMap(3)=23
	m_arrCharToIdxMap(4)=18
	m_arrCharToIdxMap(5)=5
	m_arrCharToIdxMap(6)=13
	m_arrCharToIdxMap(7)=14
	m_arrCharToIdxMap(8)=7
	m_arrCharToIdxMap(9)=8
	m_arrCharToIdxMap(10)=21
	m_arrCharToIdxMap(11)=15
	m_arrCharToIdxMap(12)=9
	m_arrCharToIdxMap(13)=10
	m_arrCharToIdxMap(14)=11
	m_arrCharToIdxMap(15)=16
	m_arrCharToIdxMap(16)=12
	m_arrCharToIdxMap(17)=19
	m_arrCharToIdxMap(18)=24
	m_arrCharToIdxMap(19)=25
	m_arrCharToIdxMap(20)=26
	m_arrCharToIdxMap(21)=27
	m_arrCharToIdxMap(22)=28
	m_arrCharToIdxMap(23)=29
	m_arrCharToIdxMap(24)=30
	m_arrCharToIdxMap(25)=31
}
