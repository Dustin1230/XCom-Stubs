class SUGfx_Ship extends GfxObject;

/**Flag for XCom ship being currently in short range to UFO*/
var bool m_bClosedIn;

/**Flag for ship performing a move - grants invulnerability*/
var bool m_bMoving;

var int m_iUFOCurrentMove;

/**Holds "x" and "y" coordinates of "short" distance point in reference to the main stage coordinate system.*/
var GFxObject m_gfxGlobalCloseDistanceLocation;

/**Holds "x" and "y" coordinates of starting point in reference to the main stage coordinate system.*/
var GFxObject m_gfxGlobalStartingLocation;

/**Holds "x" and "y" coordinates of starting point - used for UFOs, local scope.*/
var GFxObject m_gfxStartLoc;

/**Holds "x" and "y" coordinates of starting point - used for UFOs, local scope*/
var GFxObject m_gfxDestLoc;

var float m_fPreMoveScale;
var float m_fPostMoveScale;

/**Reference to the "selection box" for the ship.*/
var UIModGfxSimpleShape m_gfxFocusBorder;

/**Reference to the "hp bar" for the ship.*/
var UIModGfxSimpleProgressBar m_gfxDamageBar;

/**Reference to the reticle marking current target for the UFO.*/
var UIModGfxSimpleShape m_gfxUFOTargetMarker;

/**Reference to the star marking current squadron leader.*/
var UIModGfxSimpleShape m_gfxLeaderFlag;

var UIModGfxTextField m_gfxAmmoTextField;
/**Flag for XCom ship being currently targeted by UFO*/
var bool m_bUFOTarget;

/**Flag for XCom ship being currently under the player's control*/
var bool m_bHasFocus;

delegate DelegateWithoutParams();

function bool IsUFO()
{
	return GetBool("isEnemy");
}
/**
 Sets HP of the ship in the Action Script. 
 If "initialHP" (hull's strength) of the ship is < 0 (flag) this will also set the hull's total strength to the value of iNewHP.
 */
function SetHP(int iNewHP)
{
	local array<ASValue> arrParams;

	if(GetFloat("initialHP") < 0)
	{
		`log("Set Hull (initial) on" @ self);
		SetHull(iNewHP);
	}
	SetFloat("currHP", float(iNewHP));
	UpdateDamageVisuals();
	AdjustDamageMasks();
	arrParams.Length=0;
	if(iNewHP <= 0)
	{
		Invoke("NotifyWeaponsOwnerDied", arrParams);
		GetObject("effectsMC").GotoAndPlay("_destroyed");
		GetPC().SetTimer(0.30, false, 'OnDestructionCompleteDelegate', self);
	}
}
/** Updates the ship's damage bar and color of the ship.*/
function UpdateDamageVisuals()
{
	local float fPctHPLeft;
	local array<ASValue> arrParams;

	fPctHPLeft = GetFloat("currHP") / GetFloat("initialHP");
	if(IsUFO() && fPctHPLeft < 0.5 && !GetBool("isExploding"))
	{
		SetBool("isExploding", true);
		arrParams.Length = 0;
		Invoke("spawnExplosion", arrParams);
	}
	if(m_gfxDamageBar != none && class'SU_UIInterceptionEngagement'.default.SHOW_DAMAGE_BARS)
	{
		m_gfxDamageBar.SetProgress(fPctHPLeft);
	}
	if(class'SU_UIInterceptionEngagement'.default.SHOW_DAMAGE_COLORED_JETS)
	{
		if(fPctHPLeft < 0.25)
		{
			class'UIModUtils'.static.ObjectMultiplyColor(GetObject("effectsMC"), 2.50, 0.0, 0.0);
		}
		else if(fPctHPLeft < 0.5)
		{
			class'UIModUtils'.static.ObjectMultiplyColor(GetObject("effectsMC"), 2.50, 0.55, 0.0);
		}
		else if(fPctHPLeft < 0.75)
		{
			class'UIModUtils'.static.ObjectMultiplyColor(GetObject("effectsMC"), 2.50, 1.1, 0.0);
		}
	}
}
/** Applies the ship's HP/Hull data to the main damage diagram.*/
function AdjustDamageMasks()
{
	local GfxObject gfxDiagram, gfxCyanMask, gfxRedMask;
	local float fPctHP, fCyanH;

//	LogInternal(GetFuncName() @ GetString("_name") @ "("$self$")");
	gfxDiagram = GetObject("damageDiagram");
	gfxDiagram.GotoAndPlay(AS_GetShipLabel());
	gfxCyanMask = gfxDiagram.GetObject("cyanMask");
	gfxRedMask = gfxDiagram.GetObject("redMask");
	if(gfxCyanMask == none || gfxRedMask == none)
	{
		LogInternal("Error: Attempted to ajust HP without valid masks: cyanMask=" $ gfxCyanMask $ ", redMask=" $ gfxRedMask);
		return;
	}
	fPctHP = GetFloat("currHP") / GetFloat("initialHP");
	fCyanH = gfxCyanMask.GetFloat("_height") * fPctHP;
	gfxRedMask.SetFloat("_y", fCyanH);
	gfxCyanMask.SetFloat("_y", fCyanH - gfxCyanMask.GetFloat("_height"));
}
/** Sets visibility of "selection box" around the ship.*/
function SetFocus(bool bHasFocus)
{
	m_bHasFocus = bHasFocus;
	if(bHasFocus)
	{
		class'UIModUtils'.static.ObjectMultiplyColor(m_gfxFocusBorder,1.0,1.0,1.0,1.0);
	}
	else
	{
		class'UIModUtils'.static.ObjectMultiplyColor(m_gfxFocusBorder,1.0,1.0,1.0,0.02);//minimal alptha required for mouse response
	}
}
/**Set visibility of "reticile" indicator which marks current UFO's target*/
function SetUFOTarget(bool bUFOTarget)
{
	m_bUFOTarget = bUFOTarget;
	m_gfxUFOTargetMarker.SetVisible(m_bUFOTarget);
	if(m_bUFOTarget)
	{
		AdjustDamageMasks();
	}
}
/**Sets "initialHP" of the ship in the Action Script. Useful when "initalHP" is >=0 and SetHP would not set the hull's strength.*/
function SetHull(int iNewHullStrength)
{
//	LogInternal(GetFuncName() @ iNewHullStrength);
	SetFloat("initialHP", float(iNewHullStrength));
}
function SetGlobalCloseDistanceLoc(GfxObject gfxGlobalLoc)
{
	m_gfxGlobalCloseDistanceLocation = gfxGlobalLoc;
}
function GfxObject GetCloseDistanceLoc()
{
	return m_gfxGlobalCloseDistanceLocation;
}
function SetGlobalStartingLoc(GFxObject gfxStartLoc)
{
	m_gfxGlobalStartingLocation = gfxStartLoc;
}
function GfxObject GetGlobalStartingLoc()
{
	return m_gfxGlobalStartingLocation;
}
function OnDestructionCompleteDelegate()
{
	`Log(self,,GetFuncName());
	SetVisible(false);
	XComPlayerController(GetPC()).m_Pres.UnsubscribeToUIUpdate(UpdateMovingUFO);
	if(m_gfxFocusBorder != none)
	{
		m_gfxFocusBorder.SetVisible(false);
		m_gfxDamageBar.SetVisible(false);
		m_gfxAmmoTextField.SetVisible(false);
		m_gfxLeaderFlag.SetVisible(false);
	}
	if(m_bMoving)
	{
		ToggleMovingStatus();
	}
}
/**Attaches the reticle to the ship's movie clip.*/
function AttachUFOTargetMarker(float fPerspectiveModifier, optional float fCombatScale)
{
	local float fR, fGlobalScaleModifier, fCenterX, fCenterY;
	local ASDisplayInfo tDisplay;
	if(m_gfxUFOTargetMarker == none)
	{
		tDisplay = GetObject("effectsMC").GetDisplayInfo();
		fGlobalScaleModifier= tDisplay.XScale / 100.0 / fPerspectiveModifier;
		fCenterX = tDisplay.X - GetObject("effectsMC").GetFloat("_width")*fGlobalScaleModifier/2.0;
		fCenterY = tDisplay.Y + GetObject("effectsMC").GetFloat("_height")*fGlobalScaleModifier/2.0;
		fR = 24.0 * fGlobalScaleModifier / fCombatScale;// * fPerspectiveModifier;
		m_gfxUFOTargetMarker = UIModGfxSimpleShape(GetObject("theShip").CreateEmptyMovieClip("UFOTargetMarker",,class'UIModGfxSimpleShape'));
		//DRAW THE RETICLE
		m_gfxUFOTargetMarker.DrawCircle(fR, fCenterX, fCenterY, 6, 0xFF0000);
		m_gfxUFOTargetMarker.AS_LineStyle(4, 0xFF0000, 80);
		m_gfxUFOTargetMarker.AS_MoveTo(fCenterX + fR, fCenterY);
		m_gfxUFOTargetMarker.AS_LineTo(fCenterX + fR/2, fCenterY);
		m_gfxUFOTargetMarker.AS_MoveTo(fCenterX - fR, fCenterY);
		m_gfxUFOTargetMarker.AS_LineTo(fCenterX - fR/2, fCenterY);
		m_gfxUFOTargetMarker.AS_MoveTo(fCenterX, fCenterY + fR);
		m_gfxUFOTargetMarker.AS_LineTo(fCenterX, fCenterY + fR/2);
		m_gfxUFOTargetMarker.AS_MoveTo(fCenterX, fCenterY - fR);
		m_gfxUFOTargetMarker.AS_LineTo(fCenterX, fCenterY - fR/2);
		m_gfxUFOTargetMarker.SetVisible(false);
	}
}
/**Attaches golden star to the ship's movie clip.*/
function AttachLeaderFlag(float fPerspectiveModifier, optional float fCombatScale)
{
	local float fArm, fGlobalScaleModifier, fX, fY;
	local ASDisplayInfo tDisplay;

	if(m_gfxLeaderFlag == none)
	{
		tDisplay = GetObject("effectsMC").GetDisplayInfo();
		fGlobalScaleModifier= tDisplay.XScale / 100.0 / fPerspectiveModifier;
		fArm = 20.0 * fGlobalScaleModifier / fCombatScale;//all the scaling is to get normalized size of the star
		fX = tDisplay.X - fArm * 2.0;
		fY = tDisplay.Y + fArm + 30;
		m_gfxLeaderFlag = UIModGfxSimpleShape(GetObject("theShip").CreateEmptyMovieClip("leaderFlag",,class'UIModGfxSimpleShape'));
		//DRAW THE STAR
		m_gfxLeaderFlag.DrawStar(fArm, 1, 0xFFFF00, 0xFFFF00);
		m_gfxLeaderFlag.SetPosition(fX, fY);
		m_gfxLeaderFlag.SetVisible(false);
	}
}
function AttachAmmoTxtField(optional float fPerspectiveModifier)
{
	local float fX, fY;

	if(GetObject("theShip").GetObject("ammoField") == none)
	{
		LogInternal(GetFuncName() @ self @ fPerspectiveModifier);
		m_gfxDamageBar.GetPosition(fX, fY);
		fY -= m_gfxDamageBar.GetFloat("_height");
		fX += m_gfxDamageBar.GetFloat("_width") - 50 / fPerspectiveModifier;

		m_gfxAmmoTextField = UIModGfxTextField(class'UIModUtils'.static.AttachTextFieldTo(GetObject("theShip"), "ammoField", fX, fY, 50 / fPerspectiveModifier, 20 / fPerspectiveModifier,, class'UIModGfxTextField'));
		m_gfxAmmoTextField.m_sTextAlign="right";
		m_gfxAmmoTextField.m_FontSize=13.0 / fPerspectiveModifier;
		m_gfxAmmoTextField.RealizeFormat();
		m_gfxAmmoTextField.SetVisible(true);
	}
}
function SetAmmoText(string sNewText)
{
	m_gfxAmmoTextField.SetHTMLText(sNewText);
}
function ToggleClosedInStatus()
{
	m_bClosedIn = !m_bClosedIn;
}
function ToggleMovingStatus()
{
	m_bMoving= !m_bMoving;
	if(!m_bMoving)
	{
		UpdateStartingLocation();//for new moves to start from
		XComPlayerController(GetPC()).m_Pres.UnsubscribeToUIUpdate(UpdateMovingUFO);

		//AS_UpdateFiringLocation();
		//AS_PopulateHitMissLocations();
	}
}
function bool HasMouseFocus()
{
	local float fW, fH, MouseX, MouseY;

	fW = m_gfxFocusBorder.GetFloat("_width")*1.10;
	fH = m_gfxFocusBorder.GetFloat("_height")*1.10;
	MouseX = m_gfxFocusBorder.GetFloat("_xmouse");
	MouseY = m_gfxFocusBorder.GetFloat("_ymouse");
	return (MouseX >= -10.0 && MouseX <= fW && MouseY >=1.0 && MouseY <= fH);
}
/**Triggers UFO move. 
 @param iMoveType Provide type: -2 go down, -1 escape, 1 move to front line, 0 go back to starting loc
 */
function UFOMoveEvent(int iMoveType, optional bool bForceNewMove=true, optional float fMoveTime=1.0)
{
	local PlayerController PC;

	`log(self @ iMoveType @ bForceNewMove, class'SU_Utils'.static.GetSquadronMod().bVerboseLog, GetFuncName());
	PC = GetPC();
	if(IsUFO() && (!m_bMoving || bForceNewMove) )
	{
		if(m_bMoving && bForceNewMove)
		{
			PC.ClearTimer('OnDestructionCompleteDelegate', self);
			PC.ClearTimer('ToggleMovingStatus', self);
		}
		m_bMoving = true;
		m_iUFOCurrentMove = iMoveType;
		if(iMoveType < 0)
		{
			PC.SetTimer(fMoveTime, false, 'OnDestructionCompleteDelegate', self);
		}
		else
		{
			PC.SetTimer(fMoveTime, false, 'ToggleMovingStatus', self);
		}
		UpdateStartingLocation();
		UpdateDestLoc();
		m_fPreMoveScale = GetFloat("_yscale");
		XComPlayerController(PC).m_Pres.SubscribeToUIUpdate(UpdateMovingUFO);
	}
}
function UpdateMovingUFO()
{
	local float fC, fR, fPct;
	local ASDisplayInfo tD;
	local PlayerController PC;

	if(IsUFO())
	{
		PC = GetPC();
		if(PC.IsTimerActive('OnDestructionCompleteDelegate', self))
		{
			fR = PC.GetTimerRate('OnDestructionCompleteDelegate', self);
			fC = PC.GetTimerCount('OnDestructionCompleteDelegate', self);
		}
		else if(PC.IsTimerActive('ToggleMovingStatus', self))
		{
			fR = PC.GetTimerRate('ToggleMovingStatus', self);
			fC = PC.GetTimerCount('ToggleMovingStatus', self);
		}
		else
		{
			return;
		}
		fPct = fC/fR;
		switch(m_iUFOCurrentMove)
		{
			case -2://go down
				m_fPostMoveScale = 25;
				break;
			case -1://escape
				m_fPostMoveScale = 25;
				break;
			case 0://back to start
				m_fPostMoveScale = 50;
				break;
			case 1:
				m_fPostMoveScale = 100;
		}
		tD = GetDisplayInfo();
			tD.XScale = m_fPreMoveScale + fPct * (m_fPostMoveScale - m_fPreMoveScale);
			tD.YScale = m_fPreMoveScale + fPct * (m_fPostMoveScale - m_fPreMoveScale);
			tD.X = m_gfxStartLoc.GetFloat("x") + fPct * (m_gfxDestLoc.GetFloat("x") - m_gfxStartLoc.GetFloat("x"));
			tD.Y = m_gfxStartLoc.GetFloat("y") + fPct * (m_gfxDestLoc.GetFloat("y") - m_gfxStartLoc.GetFloat("y"));
		SetDisplayInfo(tD);
	}
}
function UpdateStartingLocation()
{
	if(m_gfxStartLoc == none)
	{
		m_gfxStartLoc = CreateEmptyMovieClip("startLoc");
	}
	m_gfxStartLoc.SetFloat("x", GetFloat("_x"));
	m_gfxStartLoc.SetFloat("y", GetFloat("_y"));
}
function UpdateDestLoc()
{
	local float fXDest, fYDest;

	if(m_gfxDestLoc == none)
	{
		m_gfxDestLoc = CreateEmptyMovieClip("destLoc");
	}
	switch(m_iUFOCurrentMove)
	{
		case -2://go down
			fXDest = m_gfxStartLoc.GetFloat("x") - 400;
			fYDest = m_gfxStartLoc.GetFloat("y") + 200;
			break;
		case -1://escape
			fXDest = m_gfxStartLoc.GetFloat("x");
			fYDest = m_gfxStartLoc.GetFloat("y") - 200;
			break;
		case 0://back to start
			fXDest = GetGlobalStartingLoc().GetFloat("x");
			fYDest = GetGlobalStartingLoc().GetFloat("y");
			break;
		case 1://move to front
			fXDest = GetObject("_parent").GetObject("alienTarget").GetFloat("_x");
			fYDest = GetObject("_parent").GetObject("alienTarget").GetFloat("_y");
	}
	m_gfxDestLoc.SetFloat("x", fXDest);
	m_gfxDestLoc.SetFloat("y", fYDest);
	if(m_iUFOCurrentMove == 0)
	{
		class'UIModUtils'.static.GlobalToLocal(m_gfxDestLoc, self);
	}
}
function AS_Initialize(coerce string strShipID, bool bEnemy, GfxObject gfxScreen)
{
	SetBool("bLoaded", true);
	ActionScriptVoid("Initialize");
}
function AS_SetShipType(int iType, optional float fScaleModifier=GetFloat("_xscale") / 100.0)
{
	`Log(iType @ GetString("_name"), class'SU_Utils'.static.GetSquadronMod().bVerboseLog, GetFuncName());
	if(GetBool("isEnemy"))
	{
		SetFloat("shipType", float(iType));
	}
	ActionScriptVoid("SetShipType");
}
function int AS_GetShipType()
{
//	LogInternal(GetFuncName() @ self @ "returns" @ GetString("shipType"));
	return int(GetString("shipType"));
}
function string AS_GetShipLabel(optional int iShipType=AS_GetShipType())
{
//	LogInternal(GetFuncName() @ iShipType @ GetString("_name"));
	return ActionScriptString("GetShipLabel");
}
/**ONLY FOR XCOM SHIPS. Moves the ship to the specified global location.
 @param gfxLocation Global location - must hold "x", "y" coordinates of the destination point in global coordinates.
 */
function AS_ShipMoveToLocation(GFxObject gfxLocation, float fMoveDuration)
{
	m_bMoving = true;
	class'SU_Utils'.static.PRES().SetTimer(fMoveDuration, false, 'AS_UpdateFiringLocation', self);
	class'SU_Utils'.static.PRES().SetTimer(fMoveDuration, false, 'ToggleMovingStatus', self);
	ActionScriptVoid("ShipMoveToLocation");
}
function AS_RemoveWeaponFromID(coerce string iWeaponID, coerce string targetShip)
{
	ActionScriptVoid("RemoveWeaponFromID");
}
function AS_Fire(GfxObject gfxTarget, int iWeaponType, int iWeaponID, int iDamage, float fDuration, bool bHit)
{
	ActionScriptVoid("Fire");
}
function GfxObject AS_GetGlobalFiringLocation()
{
	return ActionScriptObject("GetGlobalFiringLocation");
}
function AS_PopulateHitMissLocations()
{
	ActionScriptVoid("PopulateHitMissLocations");
}
function AS_UpdateFiringLocation()
{
	ActionScriptVoid("UpdateFiringLocation");
}
function AS_GlobalToLocal(out GFxObject gfxLocation)
{
	ActionScriptVoid("globalToLocal");
}
function AS_LocalToGlobal(out GFxObject gfxLocation)
{
	ActionScriptVoid("localToGlobal");
}
function AS_SetOnDestructionCompleteDelegate(delegate<DelegateWithoutParams> fnCallback)
{
	ActionScriptSetFunctionOn(GetObject("effectsMC"), "onDestructionComplete");
}

DefaultProperties
{
}