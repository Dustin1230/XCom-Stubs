class LWD_UnitTracker extends Actor;

var XGUnit m_kUnit;
var TacticalDebugger DEBUGGER;
var int m_iWatchGhettoTimout;
var Vector m_vGrappleTargetLoc;
var bool m_bUnitGrappling;
var array<XGUnit> m_arrSuppressors;
var array<XGUnit> m_arrSuppressionExecutors;

function Init(XGUnit kUnit)
{
	m_kUnit = kUnit;
	DEBUGGER = TacticalDebugger(Owner);
	if(DEBUGGER != none)
	{
		RegisterWatchVars();
	}
	else `Log("Warning: attempted to init" @ self @ "for" @ m_kUnit @ "("$m_kUnit.SafeGetCharacterFullName()$") without valid TacticalDebugger as owner.",,'LWDebugger');
}
function RegisterWatchVars()
{
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kUnit, 'm_kCurrAction', self, OnUnitAction); 
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kUnit, 'm_arrSuppressionTargets', self, OnSuppresionTargetsChanged); 
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kUnit, 'm_arrSuppressingEnemies', self, UpdateSuppresingEnemies); 
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kUnit, 'm_arrSuppressionExecutingEnemies', self, OnSuppressionExecutorsChanged); 
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kUnit, 'StoredEnterCoverAction', self, OnStoredEnterCoverAction); 
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kUnit, 'bSteppingOutOfCover', self, OnStepOut); 	
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kUnit, 'm_bInPodReveal', self, OnPodReveal);
}
function OnUnitAction()
{
	local XGAction kAction;

	kAction = m_kUnit.GetAction();

	if(kAction != none)
	{
		if(XGAction_BeginMove(kAction) != none)
		{
			UpdateSuppresingEnemies();
		}
		else if(XGAction_Fire(kAction) != none)
		{
			if(XGAction_Fire(kAction).IsCurrentAbilityGrapple())
			{
				m_bUnitGrappling = true;
				m_vGrappleTargetLoc = m_kUnit.GetPathingPawn().Path.GetPoint(m_kUnit.GetPathingPawn().Path.PathSize() -1);
			}
		}
		else if(XGAction_Idle(kAction) != none)
		{
			UpdateSuppresingEnemies();
			if(m_bUnitGrappling)
			{
				m_bUnitGrappling = false;
				if(VSize(m_kUnit.GetLocation() - m_vGrappleTargetLoc) > 96.0)
				{
					if(m_kUnit.GetPawn().SetLocation(m_vGrappleTargetLoc))
					{
						PRES().GetMessenger().Message("Debugging grapple location for" @ m_kUnit.SafeGetCharacterFullName());
						m_kUnit.ProcessNewPosition(true);
					}
				}
			}
		}
	}
}
function OnSuppresionTargetsChanged()
{
}
function UpdateSuppresingEnemies()
{
	m_kUnit.GetSuppressingEnemies(m_arrSuppressors);
}
function OnSuppressionExecutorsChanged()
{
	local int idx;
	local XGUnit kSuppressor;
	local XGAction kAction;
	local bool bFound;

	for(idx=0; idx < 16; idx++)
	{
		kSuppressor = XGUnit(m_kUnit.m_arrSuppressionExecutingEnemies[idx]);
		if(kSuppressor != none)
		{
			if(kSuppressor.m_kActionQueue.Contains('XGAction_FireOverwatchExecuting', kAction))
			{
				bFound = true;
			}
		}
	}
	if(bFound)
	{
		SetTimer(3.0, false, 'DebugSuppressionCheck');
	}
}
function DebugSuppressionCheck()
{
	DEBUGGER.DebugSuppression(m_kUnit);
}
function OnStoredEnterCoverAction()
{
}
function OnStepOut()
{
}
function OnPodReveal()
{
	if(DEBUGGER.bDebugDoubleMove && BATTLE().GetHumanPlayer().m_ePlayerEndTurnType > 0)
	{
		DEBUGGER.DebugDoubleMove(m_kUnit);
	}
}
function XGBattle_SP BATTLE()
{
	return XGBattle_SP(XGRI().m_kBattle);
}
function XComTacticalGRI XGRI()
{
	return XComTacticalGRI(XComGameReplicationInfo(Class'Engine'.static.GetCurrentWorldInfo().GRI));
}
function XComPresentationLayer PRES()
{
	return XComPresentationLayer(XComTacticalController(GetALocalPlayerController()).m_Pres);
}
DefaultProperties
{
}
