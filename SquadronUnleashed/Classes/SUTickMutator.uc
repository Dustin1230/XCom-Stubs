class SUTickMutator extends XComMutator
	config(SquadronUnleashed);

var float m_fShipListScale;
var float m_fShipListX;
var float m_fShipListY;
var float m_iNumShipCards;
var float m_fStanceButtonsAnchorX;
var float m_fStanceButtonsY;
var float m_fLogTime;
var config float DODGE_EFFECT_SECONDS;

function string GetDebugName()
{
	return GetItemName(string(Class)) @ class'SquadronUnleashed'.default.m_strBuildVersion;
}
event PostBeginPlay()
{
	`Log(self @ "online",, 'SUTickMutator');
}
function PlayerController PC()
{
	return class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController();
}
function XComHQPresentationLayer HQPRES()
{
	return XComHQPresentationLayer(XComHeadquartersController(PC()).m_Pres);
}
function XGStrategy GetStrategy()
{
    return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore();
}
function XGGeoscape GEOSCAPE()
{
    return GetStrategy().GetGeoscape();  
}

function XGFacility_Hangar HANGAR()
{
    return GetStrategy().GetHQ().m_kHangar;  
}

function XGItemTree ITEMTREE()
{
	return GetStrategy().ITEMTREE();
}

function XGStrategyAI AI()
{
	return GetStrategy().GetAI();
}
function Mutate(string MutateString, PlayerController Sender)
{
	//this mutator is not intended to base on Mutate calls - just passing code execution to the others:
	super(Mutator).Mutate(MutateString, Sender);
}
function UpdateCurrentShipListGfxData()
{
	local float fCurrWidth, fCurrScale, fMiddleAnchorY, fSelectedY;
	local string strMCPath;
	local int iSelected;

	strMCPath = string(UIMissionControl_UFORadarContactAlert(HQPRES().m_kUIMissionControl.m_kActiveAlert).GetMCPath());
	fCurrScale = HQPRES().GetHUD().GetVariableNumber(strMCPath $ ".shipListMC._xscale");
	m_iNumShipCards = int(HQPRES().GetHUD().GetVariableNumber(strMCPath $ ".numInterceptors"));
	if(m_iNumShipCards > 6)
	{
		m_fShipListScale = 100.0 * 6 / m_iNumShipCards;
		m_fShipListY = 0.0;
	}
	else
	{
		m_fShipListScale = 100.0;
	}
	fCurrWidth = HQPRES().GetHUD().GetVariableNumber(strMCPath $ ".shipListMC._width");
	m_fShipListX = 900.0 + (fCurrWidth / fCurrScale) * (100.0 - m_fShipListScale);
	if(fCurrScale != m_fShipListScale)
	{
		fMiddleAnchorY = HQPRES().GetHUD().GetVariableNumber(strMCPath $ ".shipListMC._y") + (m_iNumShipCards * 56.875 + 25.0) / fCurrScale * 100.0;
		m_fShipListY = fMiddleAnchorY - (m_iNumShipCards * 56.875 + 25.0) * m_fShipListScale / 100.0;
	}
	m_fStanceButtonsAnchorX = m_fShipListX + 77.15 * m_fShipListScale / 100.0;
	iSelected = UIMissionControl_UFORadarContactAlert(HQPRES().m_kUIMissionControl.m_kActiveAlert).m_iSelectedShip & 31;
	fSelectedY = HQPRES().GetHUD().GetVariableNumber(strMCPath $ ".shipListMC.ship" $ iSelected $"._y");
	m_fStanceButtonsY = m_fShipListY + (fSelectedY + 134.3) * m_fShipListScale / 100.0;
}
event Tick(float fDeltaTime)
{
	local GFxObject gfxObj;

	if(GetStrategy() == none)
	{
		return;
	}
	if(HQPRES().m_kPauseMenu != none && !IsInState('State_PauseMenu'))
	{
		PushState('State_PauseMenu');
	}
	if(DODGE_EFFECT_SECONDS > 0.0 && HQPRES().m_kInterceptionEngagement != none && HQPRES().m_kInterceptionEngagement.GetMgr().m_kInterceptionEngagement != none && HQPRES().m_kInterceptionEngagement.GetMgr().m_kInterceptionEngagement.IsConsumableInEffect(125))
	{
		HQPRES().m_kInterceptionEngagement.GetMgr().m_kInterceptionEngagement.m_aiConsumableQuantitiesInEffect[0] = 2; //force dodge active
		if(!IsTimerActive('DisableDodgeEffect'))
		{
			`Log("Setting timer on dodge button... (current battle time left=" $ HQPRES().m_kInterceptionEngagement.m_fEnemyEscapeTimer$")");
			SetTimer(default.DODGE_EFFECT_SECONDS, false, 'DisableDodgeEffect');
		}
	}
	if(HQPRES().m_kInterceptionEngagement != none && class'SU_Utils'.static.GetHelpMgr().TutorialDone())
	{
		XComPlayerController(GetALocalPlayerController()).SetPause(false);
	}
	if(HQPRES().m_kUIMissionControl != none && UIMissionControl_UFORadarContactAlert(HQPRES().m_kUIMissionControl.m_kActiveAlert) != none)
	{
		if(UIMissionControl_UFORadarContactAlert(HQPRES().m_kUIMissionControl.m_kActiveAlert).IsInState('ShipSelection'))
		{
			if(UIMissionControl_UFORadarContactAlert(HQPRES().m_kUIMissionControl.m_kActiveAlert).m_kInterceptMgr.m_kSquadron.arrJets.Length > 6)
			{
				UpdateCurrentShipListGfxData();
				gfxObj = HQPRES().GetHUD().GetVariableObject(UIMissionControl_UFORadarContactAlert(HQPRES().m_kUIMissionControl.m_kActiveAlert).GetMCPath() $ ".shipListMC");
				if(gfxObj != none)
				{
					gfxObj.SetFloat("_xscale", m_fShipListScale);
					gfxObj.SetFloat("_yscale", m_fShipListScale);
					gfxObj.SetFloat("_y", m_fShipListY);
					gfxObj.SetFloat("_x", m_fShipListX);
					gfxObj = HQPRES().GetHUD().GetVariableObject(UIMissionControl_UFORadarContactAlert(HQPRES().m_kUIMissionControl.m_kActiveAlert).GetMCPath() $ ".def");
					if(gfxObj != none)
					{
						gfxObj.SetPosition(m_fStanceButtonsAnchorX, m_fStanceButtonsY);
						gfxObj.SetFloat("_xscale", m_fShipListScale);
						gfxObj.SetFloat("_yscale", m_fShipListScale);
						gfxObj.GetObject("textField").SetFloat("_xscale", 100.0);
						gfxObj.GetObject("textField").SetFloat("_yscale", 100.0);

						gfxObj = HQPRES().GetHUD().GetVariableObject(UIMissionControl_UFORadarContactAlert(HQPRES().m_kUIMissionControl.m_kActiveAlert).GetMCPath() $ ".bal");
						gfxObj.SetPosition(m_fStanceButtonsAnchorX + 0.80 * m_fShipListScale, m_fStanceButtonsY);
						gfxObj.SetFloat("_xscale", m_fShipListScale);
						gfxObj.SetFloat("_yscale", m_fShipListScale);
						gfxObj.GetObject("textField").SetFloat("_xscale", 100.0);
						gfxObj.GetObject("textField").SetFloat("_yscale", 100.0);
						
						gfxObj = HQPRES().GetHUD().GetVariableObject(UIMissionControl_UFORadarContactAlert(HQPRES().m_kUIMissionControl.m_kActiveAlert).GetMCPath() $ ".agg");
						gfxObj.SetPosition(m_fStanceButtonsAnchorX + 1.60 * m_fShipListScale, m_fStanceButtonsY);
						gfxObj.SetFloat("_xscale", m_fShipListScale);
						gfxObj.SetFloat("_yscale", m_fShipListScale);
						gfxObj.GetObject("textField").SetFloat("_xscale", 100.0);
						gfxObj.GetObject("textField").SetFloat("_yscale", 100.0);
					}
				}
				else
				{
					`Log(GetFuncName() @ "not found shipListMC gfxObject!!!",, 'SUTickMutator');
				}
			}
		}
	}
}
function DisableDodgeEffect()
{
	`Log(GetFuncName() @ "(current battle time left=" $ HQPRES().m_kInterceptionEngagement.m_fEnemyEscapeTimer$")");
	if(IsTimerActive(GetFuncName())) 
		ClearTimer(GetFuncName());//just in case - disable other timers to call this

	if(HQPRES().m_kInterceptionEngagement != none && HQPRES().m_kInterceptionEngagement.GetMgr().m_kInterceptionEngagement.IsConsumableInEffect(125))
	{
		HQPRES().m_kInterceptionEngagement.GetMgr().m_kInterceptionEngagement.m_aiConsumableQuantitiesInEffect[0] = 0;
		HQPRES().m_kInterceptionEngagement.AS_DisplayEffectEvent(1, HQPRES().m_kInterceptionEngagement.GetAbilityDescription(1), false);
		HQPRES().m_kInterceptionEngagement.AS_SetDodgeButton(HQPRES().m_kInterceptionEngagement.m_strDodgeAbility, 2);
	}
}
function SU_UIInputGate GetMyInputGate(optional UI_FxsScreen kParentScreen)
{
	return class'SU_Utils'.static.GetSquadronMod().GetMyInputGate(kParentScreen);
}
state ModdedState
{
	event PushedState()
	{
		`Log(GetFuncName() @ GetStateName(), class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	}
	event PausedState()
	{
		`Log(GetFuncName() @ GetStateName(), class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	}
	event ContinuedState()
	{
		`Log(GetFuncName() @ GetStateName(), class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	}
	event PoppedState()
	{
		`Log(GetFuncName() @ GetStateName(), class'SquadronUnleashed'.default.bVerboseLog, 'SquadronUnleashed');
	}
}
state State_PauseMenu extends ModdedState
{
	event PoppedState()
	{
		super.PoppedState();
		GetMyInputGate().PopFromScreenStack();
	}
Begin:
	while(!HQPRES().m_kPauseMenu.IsInited())
	{
		Sleep(0.10);
	}
 	class'SU_Utils'.static.GetSquadronMod().m_optTutorialButtonID = HQPRES().m_kPauseMenu.MAX_OPTIONS;
	class'SU_Utils'.static.GetSquadronMod().BuildDataForModManager();
	HQPRES().m_kPauseMenu.AS_AddOption(HQPRES().m_kPauseMenu.MAX_OPTIONS++, Caps(class'SU_Utils'.static.GetSquadronMod().m_kOptionsContainer.GetUINameForVar("SquadronUnleashed")) @ "-" @ ParseLocalizedPropertyPath("XComGame.UIShellDifficulty.m_strTutorialLabel"), 0);
	GetMyInputGate(HQPRES().m_kPauseMenu).BringToTopOfScreenStack();
	while(HQPRES().m_kPauseMenu != none)
	{
		Sleep(0.30);
	}
	PopState();
}

DefaultProperties
{
	bAlwaysTick=true
}
