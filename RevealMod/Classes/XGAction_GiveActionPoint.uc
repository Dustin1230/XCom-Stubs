class XGAction_GiveActionPoint extends XGAction
    hidecategories(Navigation);

function bool Init(XGUnit kUnit)
{
    BaseInit(kUnit);
    return true;
}

function bool HasRunAndGun()
{
    local array<XGAbility_Targeted> arrAbilities;

    m_kUnit.GetAbilitiesOfType(arrAbilities, eAbility_RunAndGun);
    return arrAbilities.Length > 0;
}

simulated function InternalCompleteAction()
{
    if(class'RevealModMutator'.default.bDebugLog)
    {
		LogInternal(">>> Completing action point action on unit " $ m_kUnit.SafeGetCharacterName());
	    // Re-check to ensure the unit is eligible for a free action: only if they have no
	    // actions remaining.
		LogInternal("Fire actions performed: " $ string(m_kUnit.m_iFireActionsPerformed));
		LogInternal("Move actions performed: " $ string(m_kUnit.m_iMovesActionsPerformed));
		LogInternal("RNG active: " $ string(m_kUnit.m_bRunAndGunActivated));
		LogInternal("RNG used move: " $ string(m_kUnit.m_bRunAndGunUsedMove));
		LogInternal(("Soldier class: " $ string(m_kUnit.GetSoldierClass())) @ m_kUnit.GetSoldierClassName());
		LogInternal("GetMoves: " $ string(m_kUnit.GetMoves()));
		LogInternal("Has RunAndGun: " $ string(HasRunAndGun()));
	}
    if(m_kUnit.GetMoves() == 0)
    {
		`Log("Granted point", class'RevealModMutator'.default.bDebugLog);
        m_kUnit.m_iMovesActionsPerformed = 1;
        m_kUnit.SetMoves(1);
        m_kUnit.m_iUseAbilities = 0;
        m_kUnit.m_iFireActionsPerformed = 0;
        m_kUnit.SetTakenTurnEndingAction(false);
        m_kUnit.m_bRunAndGunActivated = false;
        m_kUnit.m_bRunAndGunUsedMove = false;
        if(HasRunAndGun())
        {
        	// Need to turn off RnGActivated or any units that have used RnG and all
            // their actions will consistently show 1 move remaining in their unit flag
            // even after taking their free move as if this flag is active it will not consume
            // another move action when they use the free move, it'll set the "move used"
            // flag instead. But we cannot set the "move used" flag here or they won't be
            // able to move.
            `Log("Unit has RnG available.", class'RevealModMutator'.default.bDebugLog);
        }
        m_kUnit.BuildAbilities(true);
    }
    else
    {
        if((m_kUnit.RunAndGunPerkActive() && m_kUnit.m_bRunAndGunUsedMove) && m_kUnit.m_iFireActionsPerformed == 0)
        {
            if(m_kUnit.m_iMovesActionsPerformed == 1)
            {
	            // Unit has RnG activated, used 2 moves but not fired. They get 1 move OR a
	            // shot -- give them 1 movement point, disable RnG.

                `Log("Granted point w/ RnG active -- abilities enabled.", class'RevealModMutator'.default.bDebugLog);
                m_kUnit.m_iMovesActionsPerformed = 1;
                m_kUnit.SetMoves(1);
                m_kUnit.m_bRunAndGunActivated = false;
                m_kUnit.m_bRunAndGunUsedMove = false;
            }
            else
            {
	            // Unit used RnG, used 1 move and has not fired. No change (can still move and fire)
                `Log("RnG 1 move and no fire: no effect.", class'RevealModMutator'.default.bDebugLog);
            }
        }
        else
        {
            `Log("Unit has remaining actions: not granting point.", class'RevealModMutator'.default.bDebugLog);
        }
    }
    m_kUnit.BuildAbilities(true);
    super(XGAction).InternalCompleteAction();
}

simulated state Executing
{
Begin:
    CompleteAction();
	stop;
                   
}