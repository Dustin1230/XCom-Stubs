class RevealModMutator extends XComMutator
	config(RevealMod);

var config bool bDebugLog;
var config bool bCallFriendsEndOfTurn;
var config bool	bCallFriendsOnPodReveal;
var config bool	bBailOutOnPodReveal;


function Mutate(String MutateString, PlayerController Sender)
{
	local XGUnit kUnit;
	local XGPlayer kPlayer;
    local string strParameter;


    if (MutateString == "XComAlienPodManager.QueuePodReveal")
    {
        `Log("Got reveal message!", bDebugLog);
        if(bBailOutOnPodReveal)
			ProcessUnits();
    }
	if (MutateString == "XComAlienPodManager.RevealNextPod")
	{
		if(bCallFriendsOnPodReveal)
			QueueOtherVisiblePods();
	}
	if (MutateString == "XComAlienPodManager.UpdateUnactivatedSeenPods")
	{
		if(bCallFriendsEndOfTurn)
			RevealPodsVisibleToActiveFriends();
	}
	if (MutateString == "XGPlayer.EndingTurn")
    {
    	kPlayer = XGBattle_SP(GRI().m_kBattle).GetLocalPlayer();
        `Log("Ending" @ string(kPlayer) @ "turn. Disabling access to full turn for dormant alien pods", bDebugLog, 'RevealMod');
        if(kPlayer != none)
        {
        	DebugDormantPods();
        }
	}
	if(InStr(MutateString, "XGUnit.UpdateInteractClaim:") != -1)
	{
		strParameter = Split(MutateString, "XGUnit.UpdateInteractClaim:", true);
		kUnit = XGUnit(GetActor(class'XGUnit', strParameter));
		if(kUnit.IsAlien())
		{
		`Log("Grabbed alien: " @ kUnit.GetCharacter().SafeGetCharacterName() @ GetRightMost(kUnit) @ "for debugging", bDebugLog, 'RevealMod');
			DebugDoubleMove(kUnit);
		}
	}

    super.Mutate(MutateString, Sender);
}

function ProcessUnits()
{
    local XGUnit kUnit;
    local XGAction kAction;
    local XGAction_GiveActionPoint kActionPoint;
    local bool bAddPoint;

    if (XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle.IsAlienTurn()) {
        // Not XCom's turn; do nothing.
        return;
    }

    // Process all units on the map (possibly better to just iterate squad members, but does this include
    // Mind Controlled units?)
	//szmind: changed to DynamicActors to make it lighter 
    foreach DynamicActors(class 'XGUnit', kUnit) {
        bAddPoint = false;
        `Log("Testing unit " $ kUnit.SafeGetCharacterName(), bDebugLog);
        if (kUnit.GetTeam() != eTeam_XCom) {
            `Log("    Not on XCom Team", bDebugLog);
            continue;
        }

        if (!kUnit.IsAliveAndWell()) {
            `Log("    Not feeling up to it", bDebugLog);
            continue;
        }
		if(bDebugLog)
		{
			LogInternal("Fire actions performed: " $ kUnit.m_iFireActionsPerformed);
			LogInternal("Move actions performed: " $ kUnit.m_iMovesActionsPerformed);
			LogInternal("Free fire used: " $ kUnit.m_bFreeFireActionTaken);
			LogInternal("RNG active: " $ kUnit.m_bRunAndGunActivated);
			LogInternal("RNG used move: " $ kUnit.m_bRunAndGunUsedMove);
			LogInternal("Soldier class: " $ kUnit.GetSoldierClass() @ kUnit.GetSoldierClassName());
			LogInternal("GetMoves: " $ kUnit.GetMoves());
		}
        if (kUnit.IsApplyingAbility(eAbility_ShotSuppress)) {
            `Log("    Unit is suppressing.", bDebugLog);
            continue;
        }
        else if (kUnit.IsInOverwatch()) {
            `Log("    Unit is in overwatch.", bDebugLog);
            continue;
        }
        else if (kUnit.IsHunkeredDown()) {
            `Log("    Unit is hunkered.", bDebugLog);
            continue;
        }
        else if (kUnit.m_kActionQueue.Contains('XGAction_GiveActionPoint')) {
            `Log("    Unit already has a pending action point.", bDebugLog);
            continue;
        }
        else if (!kUnit.IsIdle()) {
            `Log("Unit is performing a non-idle action. Adding point.", bDebugLog);
            kAction = kUnit.GetAction();
            `Log("    Unit is performing action " $ kAction, bDebugLog);
            bAddPoint = true;
        }
        else if (kUnit.GetMoves() == 0) {
            `Log("    Unit has no actions remaining. Adding point.", bDebugLog);
            bAddPoint = true;
        }

        if (bAddPoint) {
            `Log("Granting move pre-emptively", bDebugLog);
            kActionPoint = Spawn(class'XGAction_GiveActionPoint', kUnit.Owner);
            kActionPoint.Init(kUnit);
            kUnit.AddAction(kActionPoint);
			//szmind: this will prevent ending turn if reveal was on last move in turn
            kUnit.SetTakenTurnEndingAction(false);
        }
    }
}//szmind:
//-----------------------------------------------
// UTILITY FUNCTIONS
//----------------------------------------------
static function WorldInfo WORLDINFO()
{
	return class'Engine'.static.GetCurrentWorldInfo();
}

static function PlayerController PC()
{
	return WORLDINFO().GetALocalPlayerController();
}

static function XComTacticalGRI GRI()
{
	return XComTacticalGRI(WORLDINFO().GRI);
}

function actor GetActor(class<actor> ActorClass, string strName)
{
	local actor kActorToGet;

	foreach WORLDINFO().AllActors(ActorClass, kActorToGet)
	{
		if(string(kActorToGet) == strName)
		{
			return kActorToGet;
		}
	}
}
//-----------------------------------
// END OF UTILITY SECTION
//-----------------------------------

function QueueOtherVisiblePods()
{
	local XComAlienPod kPod;
	local XGUnit kUnit;
	local XComAlienPodManager kPodMgr;

	kPodMgr = XGBattle_SP(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle).m_kPodMgr;
    if(kPodMgr.m_bFirstResponse || kPodMgr.GetActivePod().HasVisibleEnemies())
    {
		kPodMgr.m_bFirstResponse = false;
        foreach kPodMgr.GetActivePod().m_arrAlien(kUnit)
        {
			foreach kPodMgr.m_arrPod(kPod)
            {
				if((kUnit.CanSeeActor(kPod) && kPod != kUnit.m_kPod) && kPodMgr.m_arrActivation.Find(kPod) == -1)
                {
                    kPodMgr.m_arrActivation.AddItem(kPod);
                    if(kUnit.m_kPod.m_kEnemy != none)
						kPod.m_kEnemy = kUnit.m_kPod.m_kEnemy;
                }                    
            }                                
        }            
    }
}
//szmind:
//--------------------------------------------------------------
function RevealPodsVisibleToActiveFriends()
{
	local XComAlienPod kPod;
	local XGUnit kAlien, kAlienVisibleFriend;
	local XGSquad kAlienSquad;
	local XComAlienPodManager kPodMgr;
	local int I;

    if(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle.IsAlienTurn())
    {
		kPodMgr = XGBattle_SP(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle).m_kPodMgr;
		kAlienSquad = XGAIPlayer(XGBattle_SP(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle).GetAIPlayer()).GetSquad();
		foreach kPodMgr.m_arrPod(kPod)
		{
			if(kPod.IsInState('Dormant'))
			{
				foreach kPod.m_arrAlien(kAlien)
				{
					for(I = 0; I < kAlienSquad.GetNumMembers(); ++I)
					{
						kAlienVisibleFriend = kAlienSquad.GetMemberAt(I);
						if(!kAlienVisibleFriend.m_kPod.IsInState('Dormant') && kAlienVisibleFriend.CanSee(kAlien, false))
						{
							kPodMgr.m_arrActivation.AddItem(kPod);
							kPod.MarkEnemySeen();
							kPod.MarkSeen();
							if(kAlienVisibleFriend.m_kPod.m_kEnemy != none)
								kPod.m_kEnemy = kAlienVisibleFriend.m_kPod.m_kEnemy;
							break;
						}
					}
					if(kPod.HasBeenSeen())
					{
						break;
					}
				}
			}
		}
    }
	//continue with original code()    
}

function DebugDoubleMove(XGUnit kUnit)
{
	if(!kUnit.IsAlien())
	{
		`Log(kUnit.GetCharacter().SafeGetCharacterName() @ "is not an alien. Skipped.", bDebugLog, 'LWDebugger');
		return;
	}
	if(kUnit.m_bSkipTrackMovement && InStr(GetScriptTrace(), "BeginTurn") != -1)
	{
		`Log(string(kUnit.m_kPod) @ "is marked for no move." @ kUnit.GetCharacter().SafeGetCharacterName() @ "(" $ string(kUnit) $ ") deactivated.", bDebugLog, 'LWDebugger');
		kUnit.m_bSkipTrackMovement = false;
		kUnit.GotoState('Inactive');
	}
}
function DebugDormantPods()
{
	local XComAlienPod kPod;
	local array<XComAlienPod> arrAllPods;
	local XGUnit kUnit;
	local XGPlayer kPlayer;

	kPlayer = XGBattle_SP(GRI().m_kBattle).GetLocalPlayer();
	if(!kPlayer.IsA('XGAIPlayer'))
	{
		arrAllPods = GRI().m_kBattle.m_kPodMgr.m_arrPod;
		foreach arrAllPods(kPod)
		{
			if(kPod.IsInState('Dormant'))
			{
				foreach kPod.m_arrAlien(kUnit)
				{
					kUnit.m_bSkipTrackMovement = true;
					`Log(string(kPod) @ "is Dormant; disabling turn for:" @ kUnit.GetCharacter().SafeGetCharacterName() @ GetRightMost(kUnit) @ ", only whole pod can move/reveal.", bDebugLog, 'LWDebugger');
				}
			}
		}
	}
}
