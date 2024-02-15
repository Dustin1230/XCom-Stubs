/** This is a template for helper-screen to be put on top of screens' stack to hijack input events.*/
class SU_UIInputGate extends UIModInputGate;

simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
	local bool bHandled;

	if(SquadronUnleashed(m_kMutator).IsInState('State_HangarMenu') && SquadronUnleashed(m_kMutator).m_kHangarMenu != none)
	{
		bHandled = OnUnrealCommand_HangarMenu(Cmd, Arg);
	}
	else if(SquadronUnleashed(m_kMutator).IsInState('State_HangarShipSummary'))
	{
		bHandled = OnUnrealCommand_ShipSummary(Cmd, Arg);
	}
	else if(SquadronUnleashed(m_kMutator).IsInState('State_HangarShipLoadout') )
	{
		bHandled = OnUnrealCommand_ShipLoadout(Cmd, Arg);
	}
	else if(SquadronUnleashed(m_kMutator).IsInState('State_HangarAirforceCommand') )
	{
		bHandled = OnUnrealCommand_AirforceCommand(Cmd, Arg);
	}
	else if(SquadronUnleashed(m_kMutator).IsInState('State_HangarPilotTraining') )
	{
		bHandled = OnUnrealCommand_TrainingCentre(Cmd, Arg);
	}
	else if(UIPauseMenu(screen) != none) //this one is instigated by SU_TickMutator, state check on SquadonUnleashed will fail
	{
		bHandled = OnUnrealCommand_PauseMenu(Cmd, Arg);
	}
	return bHandled;
}
simulated function bool OnMouseEvent(int Cmd, array<string> args)
{
	local string targetCallback;

	JoinArray(args, targetCallback, ".", false);
//	LogInternal(GetFuncName() @ Cmd @ targetCallback);
	if(screen != none)
	{
		if(screen.IsA('UIShipSummary'))
		{
			return OnMouseEvent_ShipSummary(Cmd, args);
		}
		else if(screen.IsA('UIShipLoadout'))
		{
			return OnMouseEvent_ShipLoadout(Cmd, args);
		}
		else if(screen.IsA('SU_UIAirforceCommand'))
		{
			return OnMouseEvent_AirforceCommand(Cmd, args);
		}
		else if(screen.IsA('SU_UIPilotTraining'))
		{
			return OnMouseEvent_TrainingCentre(Cmd, args);
		}
		else if(screen.IsA('UIPauseMenu'))
		{
			return OnMouseEvent_PauseMenu(Cmd, args);
		}
		else
		{
			return screen.OnMouseEvent(Cmd, args);
		}
	}
	`Log("WARNING!" @ self @ "returns false due to 'screen' property being 'none'.");
	return false;
}
function bool OnUnrealCommand_HangarMenu(int Cmd, int Arg)
{
	if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg))// && !(Cmd == 571 && Arg == 32)) //let Tab sneak through, for tests
	{
		return false;
	}
	return SquadronUnleashed(m_kMutator).m_kHangarMenu.OnUnrealCommand(Cmd, Arg);
}
function bool OnUnrealCommand_ShipSummary(int Cmd, int Arg)
{
	local bool bHandled;

	if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg))// && !(Cmd == 571 && Arg == 32)) //let Tab sneak through, for tests
	{
		return false;
	}
	switch(Cmd)
	{
		case class'UI_FxsInput'.const.FXS_BUTTON_A:
        case class'UI_FxsInput'.const.FXS_KEY_SPACEBAR:
        case class'UI_FxsInput'.const.FXS_KEY_ENTER:
			if(class'SU_Utils'.static.PRES().m_kShipSummary.m_iSelectedOption == 2)
			{
				SquadronUnleashed(m_kMutator).UIAssignPilot(class'SU_Utils'.static.PRES().m_kShipSummary.m_kShip);
				bHandled = true;
			}
			else if(class'SU_Utils'.static.PRES().m_kShipSummary.m_iSelectedOption == 0)
			{
				if(class'SU_Utils'.static.PRES().m_kShipSummary.m_kShip.GetStatus() == eShipStatus_Rearming)
					class'SU_Utils'.static.GetHelpMgr().ShowErrorMsg(eSUError_JetAlreadyRearming);
				else if(class'SU_Utils'.static.PRES().m_kShipSummary.m_kShip.GetStatus() == eShipStatus_Transfer)
					class'SU_Utils'.static.GetHelpMgr().ShowErrorMsg(eSUError_JetInTransfer);
			}
			break;
		case class'UI_FxsInput'.const.FXS_BUTTON_B:
		case class'UI_FxsInput'.const.FXS_KEY_ESCAPE:
		case class'UI_FxsInput'.const.FXS_R_MOUSE_DOWN:
			SU_XGHangarUI(class'SU_Utils'.static.PRES().GetMgr(class'SU_XGHangarUI')).OnCloseShipSummary();
			bHandled = true;
            break;
		case class'UI_FxsInput'.const.FXS_BUTTON_X:
			class'SU_Utils'.static.PRES().m_kShipSummary.OnMouseShipInfo();
			bHandled = true;
			break;
		case class'UI_FxsInput'.const.FXS_BUTTON_LTRIGGER:
			class'SU_Utils'.static.PRES().m_kShipSummary.OnMouseWeaponInfo();
			bHandled = true;
			break;
		case class'UI_FxsInput'.const.FXS_BUTTON_RTRIGGER:
			SU_XGHangarUI(class'SU_Utils'.static.PRES().GetMgr(class'SU_XGHangarUI')).OnSecondWeaponInfo();
			bHandled = true;
			break;
		default:
			bHandled = false;
	}
	return bHandled;
}
function bool OnMouseEvent_ShipSummary(int Cmd, array<string> args)
{
	local bool bHandled;
	local string targetCallback;

	if(Cmd == 391)
	{
		targetCallback = args[args.Length - 1];
		if(targetCallback == "weaponButton_2")
		{
			SquadronUnleashed(m_kMutator).UIAssignPilot(class'SU_Utils'.static.PRES().m_kShipSummary.m_kShip);
			bHandled = true;
		}
		else if(targetCallback == "weaponButton_0")
		{
			if(class'SU_Utils'.static.PRES().m_kShipSummary.m_kShip.GetStatus() == eShipStatus_Rearming)
				class'SU_Utils'.static.GetHelpMgr().ShowErrorMsg(eSUError_JetAlreadyRearming);
			else if(class'SU_Utils'.static.PRES().m_kShipSummary.m_kShip.GetStatus() == eShipStatus_Transfer)
				class'SU_Utils'.static.GetHelpMgr().ShowErrorMsg(eSUError_JetInTransfer);
		}
	}
	if(!bHandled)
	{
		bHandled = class'SU_Utils'.static.PRES().m_kShipSummary.OnMouseEvent(Cmd, args);
	}
	return bHandled;
}
function bool OnUnrealCommand_ShipLoadout(int Cmd, int Arg)
{
	local bool bHandled;

	if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg))
	{
		bHandled = false;
	}
	switch(Cmd)
	{
	case class'UI_FxsInput'.const.FXS_ARROW_RIGHT:
	case class'UI_FxsInput'.const.FXS_DPAD_RIGHT:
	case class'UI_FxsInput'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		if(!manager.IsMouseActive())
		{
			SquadronUnleashed(m_kMutator).m_kShipLoadoutSecondary.SetPanelFocus(true);
			bHandled = true;
			break;
		}
	case class'UI_FxsInput'.const.FXS_ARROW_LEFT:
	case class'UI_FxsInput'.const.FXS_DPAD_LEFT:
	case class'UI_FxsInput'.const.FXS_VIRTUAL_LSTICK_LEFT:
		if(!manager.IsMouseActive())
		{
			SquadronUnleashed(m_kMutator).m_kShipLoadoutSecondary.SetPanelFocus(false);
			bHandled = true;
			break;
		}
	default:
		if(SquadronUnleashed(m_kMutator).m_kShipLoadoutSecondary.m_bHasControllerFocus)
		{
			bHandled = SquadronUnleashed(m_kMutator).m_kShipLoadoutSecondary.OnUnrealCommand(Cmd, Arg);
		}
		else
		{
			bHandled = SquadronUnleashed(m_kMutator).m_kShipLoadoutPrimary.OnUnrealCommand(Cmd, Arg);
		}
	}
	return bHandled;
}
function bool OnMouseEvent_ShipLoadout(int Cmd, array<string> args)
{
	local TShipWeapon kWeapon;
	local XGHangarUI kMgr;
	local UIShipLoadout kUIScreen;
	local bool bHandled;

	if(SquadronUnleashed(m_kMutator).m_kShipLoadoutSecondary.m_bHasControllerFocus)
	{
		bHandled = SquadronUnleashed(m_kMutator).m_kShipLoadoutSecondary.OnMouseEvent(Cmd, args);
	}
	else
	{
		if(Cmd == 392 && args.Length > 2 && args[args.Length - 2] == "theItems")//mouse hover
		{
			kUIScreen = SquadronUnleashed(m_kMutator).m_kShipLoadoutPrimary;
			//manual RealizeSelected procedure applied to the main weapon panel:
			kUIScreen.m_iCurrentSelection = int(args[args.Length - 1]);
			kMgr = kUIScreen.GetMgr();
			kWeapon = kMgr.SHIPWEAPON(kMgr.HANGAR().ItemTypeToShipWeapon(EItemType(kMgr.m_arrItems[kUIScreen.m_iCurrentSelection].iItem)));
			kMgr.UpdateShipWeaponView(XGShip_Interceptor(kMgr.m_kShip), kWeapon.eType);
			kUIScreen.AS_SetSelected(kUIScreen.m_iCurrentSelection);
			kUIScreen.AS_SetWeaponName(kWeapon.strName);
			kUIScreen.AS_SetWeaponImage(class'UIUtilities'.static.GetInventoryImagePath(kMgr.m_kTable.arrSummaries[kUIScreen.m_iCurrentSelection].imgOption.iImage), 0.90);
			kUIScreen.AS_SetWeaponDescription(kMgr.m_kTable.arrSummaries[kUIScreen.m_iCurrentSelection].txtSummary.StrValue);
			SquadronUnleashed(m_kMutator).m_kShipLoadoutSecondary.OnPrimaryPanelSelectionChange();
			bHandled = true;
		}
		else
		{
			bHandled = SquadronUnleashed(m_kMutator).m_kShipLoadoutPrimary.OnMouseEvent(Cmd, args);
			if(Cmd == 391 && !SU_XGHangarUI(SquadronUnleashed(m_kMutator).m_kShipLoadoutPrimary.GetMgr()).m_bPrimaryLoadoutChanged)
			{
				SquadronUnleashed(m_kMutator).m_kShipLoadoutSecondary.OnPrimaryPanelSelectionChange();//this is to update weapon info card
			}
		}
	}
	return bHandled;
}
function bool OnUnrealCommand_AirforceCommand(int Cmd, int Arg)
{
	return	SquadronUnleashed(m_kMutator).m_kAirforceCommand.OnUnrealCommand(Cmd, Arg);
}
function bool OnMouseEvent_AirforceCommand(int Cmd, array<string> args)
{
	return	SquadronUnleashed(m_kMutator).m_kAirforceCommand.OnMouseEvent(Cmd, args);
}
function bool OnUnrealCommand_TrainingCentre(int Cmd, int Arg)
{
	return	SquadronUnleashed(m_kMutator).m_kPilotTrainingUI.OnUnrealCommand(Cmd, Arg);
}
function bool OnMouseEvent_TrainingCentre(int Cmd, array<string> args)
{
	return	SquadronUnleashed(m_kMutator).m_kPilotTrainingUI.OnMouseEvent(Cmd, args);
}
function bool OnMouseEvent_PauseMenu(int Cmd, array<string> args)
{
    local bool bHandled;

    switch(Cmd)
    {
        case 391:
            if(int(args[args.Length - 1]) == SquadronUnleashed(m_kMutator).m_optTutorialButtonID)
            {
				SquadronUnleashed(m_kMutator).TutorialDialog();
				bHandled = true;
            }
            break;
        default:
            bHandled = false;
    }
	if(!bHandled)
	{
		bHandled = screen.OnMouseEvent(Cmd, args);
	}
    return bHandled;
}
function bool OnUnrealCommand_PauseMenu(int Cmd, int Arg)
{
	local bool bHandled;

	if(!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg))
    {
        bHandled = false;
    }
	else
	{
		switch(Cmd)
		{
			case 300:
			case 511:
			case 513:
				if(UIPauseMenu(screen).m_iCurrentSelection == SquadronUnleashed(m_kMutator).m_optTutorialButtonID)
				{
					SquadronUnleashed(m_kMutator).TutorialDialog();
					bHandled=true;
				}
				break;
			default:
				bHandled = false;
		}
	}
	return bHandled;
}
function BringToTopOfScreenStack()
{
//	LogInternal(GetFuncName() @ self);//FIXME
	super.BringToTopOfScreenStack();
}
function PopFromScreenStack()
{
//	LogInternal(GetFuncName() @ self);//FIXME
	super.PopFromScreenStack();
}
DefaultProperties
{
	bAlwaysTick=true
}
