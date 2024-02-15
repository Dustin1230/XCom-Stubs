class SUGfx_IntercetpionEngagement extends GfxObject;

var int m_iPlayerShips;
var int m_iAlienShips;
var string m_strSelectedShip;
var string m_strCurrentUFOTarget;

delegate ShipTakeDamage(); //just a declaration of "prototype", the prototype can be used for any function which takes no parameters

/** Initializes Unreal delegates that will replace Action Script function.*/
function SetDelegates()
{
//	LogInternal(GetFuncName());
	AS_SetPlayerTakeDamageDelegate(AS_PlayerTakeDamage);
	AS_SetAlienTakeDamageDelegate(AS_AlienTakeDamage);	
}
/** Adds new movie clip of a ship. Make sure "InitializeData" had been already called to initialize the template ships.*/
function AddShip(coerce string strShipID, int iType, optional bool bAlien)
{
	local SUGfx_Ship gfxShip;
	local GFxObject gfxLocation, gfxTempLocation;
	local float fX, fY, fOffsetStepY, fOffsetStepX, fAdjustCloseLocY, fAdjustCloseLocX, fScale, fWidthAdj;
	local string strTemplateShip;
	local int iCurrentNumShips;
	local ASDisplayInfo tDisplay;
	local array<ASValue> arrParams;

	//create basic ship
	strTemplateShip = bAlien ? "alienTarget" : "playerShip";
	GetObject("combatContainer").GetObject(strTemplateShip).SetVisible(false);
	strTemplateShip = class'UIModUtils'.static.AS_GetPath(GetObject("combatContainer").GetObject(strTemplateShip));
	gfxShip = SUGfx_Ship(class'UIModUtils'.static.AS_DuplicateMovieClip(strTemplateShip, strShipID, class'SU_Utils'.static.PRES().m_kInterceptionEngagement.manager, class'SUGfx_Ship'));
	gfxShip.AS_Initialize(strShipID, bAlien, self);
	gfxShip.AS_SetShipType(iType);
	gfxShip.SetFloat("initialHP",-1000);//-1000 will make the first call of SetHP for the ship set hull strength
	//POSITION AND SCALE the ship MC (2nd ship goes below 1st, others go above)
	if(!bAlien)
	{
		GetObject("combatContainer").GetObject("playerShip").GetPosition(fX, fY);
		iCurrentNumShips = ++m_iPlayerShips;
	}
	else
	{
		GetObject("combatContainer").GetObject("alienTarget").GetPosition(fX, fY);
		iCurrentNumShips = ++m_iAlienShips;
	}
	//`Log("Combat scale" @ GetCombatScale());
	if(!bAlien)
	{
		fOffsetStepY = 50.0 / GetCombatScale();
		fOffsetStepX = 36.0 / GetCombatScale();
	}
	else
	{
		fOffsetStepY = 75.0;
	}
	//`Log("Initial position y=" $ fY @ "shipMC.height=" $ gfxShip.GetObject("effectsMC").GetFloat("_height"));
	if(!bAlien && iCurrentNumShips <= 2)
	{
		fScale = (1.0 + iCurrentNumShips / 2 * 0.30) / GetCombatScale()*0.8; //make 2nd ship larger to simulate "closer" to foreground
		fY = fY + iCurrentNumShips / 2 * fOffsetStepY;
		fX = fX + iCurrentNumShips / 2 * fOffsetStepX;
		fAdjustCloseLocY = iCurrentNumShips / 2 * fOffsetStepY * GetCombatScale()/0.8;
		fAdjustCloseLocX = iCurrentNumShips / 2 * fOffsetStepX * GetCombatScale()/0.8;		
	}
	else if(!bAlien)
	{
		fScale = (1-0.12)**(iCurrentNumShips - 2) / GetCombatScale()*0.8;  //scale down 3rd and further ships to simulate perspective
		fY = fY - (iCurrentNumShips - 2) * fOffsetStepY;
		fX = fX - (iCurrentNumShips - 2) * fOffsetStepX;
		fAdjustCloseLocY = -(iCurrentNumShips - 2) * fOffsetStepY * GetCombatScale()/0.8;
		fAdjustCloseLocX = -(iCurrentNumShips - 2) * fOffsetStepX * GetCombatScale()/0.8;
	}
	else if(bAlien && iCurrentNumShips > 1)
	{
		fY += iCurrentNumShips * fOffsetStepY;
		tDisplay = gfxShip.GetDisplayInfo();
			tDisplay.YScale *= 0.50;
			tDisplay.XScale *= 0.50;
		gfxShip.SetDisplayInfo(tDisplay);
	}
	gfxShip.SetPosition(fX, fY);
	gfxShip.AS_PopulateHitMissLocations();//this is crucial to make "missed shots" land close to the targeted ship
	if(bAlien)
	{
		//this is to bring back correct "closeDistanceLoc" for Xcom ships
		arrParams.Length=0;
		GetObject("combatContainer").GetObject("alienTarget").Invoke("PopulateHitMissLocations", arrParams);
	}

	if(!bAlien)
	{
		//APPLY SCALE
		//(this could be done by directly SetFloat("_xscale"...) and SetFloat("_yscale"...) but using ASDisplayInfo is recommended for performance
		tDisplay = gfxShip.GetObject("effectsMC").GetDisplayInfo();//effectsMC is the "xcomShip""
			tDisplay.XScale = tDisplay.XScale * fScale;
			tDisplay.YScale = tDisplay.YScale * fScale;
		gfxShip.GetObject("effectsMC").SetDisplayInfo(tDisplay);
		//	LogInternal(gfxShip.GetString("_name") @ "added at y=" @ fY @ "scaleX" @ tDisplay.XScale @ "scaleY" @ tDisplay.YScale, 'SquadronUnleashed');
	
		//CALC INITIAL AND CLOSE_DISTANCE POSITIONS IN GLOBABL COORDINATES
		gfxLocation = GetObject("closeDistanceLocation");
		gfxTempLocation = gfxShip.CreateEmptyMovieClip("closeDistanceLocation");//creates a new geometric point in gfx layer
		gfxTempLocation.SetFloat("y", gfxLocation.GetFloat("y") + fAdjustCloseLocY);
		gfxTempLocation.SetFloat("x", gfxLocation.GetFloat("x") + fAdjustCloseLocX);
		gfxShip.SetGlobalCloseDistanceLoc(gfxTempLocation);
		
		gfxTempLocation = gfxShip.CreateEmptyMovieClip("startDistanceLocation");
		gfxShip.GetObject("effectsMC").GetPosition(fX, fY);
		gfxTempLocation.SetFloat("x", fX+130.0);//FIXME, fixed 130/30 modifiers must be tested on different UFOs
		gfxTempLocation.SetFloat("y", fY-30.0);
		class'UIModUtils'.static.LocalToGlobal(gfxTempLocation, gfxShip.GetObject("effectsMC"));
		gfxShip.SetGlobalStartingLoc(gfxTempLocation);
	
		//ATTACH damageBar
		class'UIModUtils'.static.AttachSimpleProgressBarTo(gfxShip.GetObject("theShip"), "damageBar",,,,class'SU_Utils'.static.PRES().m_kInterceptionEngagement.manager.ToFlashHex(class'SU_UIInterceptionEngagement'.default.DAMAGE_BAR_HP_COLOR));
		gfxShip.m_gfxDamageBar = UIModGfxSimpleProgressBar(gfxShip.GetObject("theShip").GetObject("damageBar", class'UIModGfxSimpleProgressBar'));
		gfxShip.m_gfxDamageBar.SetProgressTxtColor("0x000000");//black
		gfxShip.m_gfxDamageBar.SetBackgroundColor(class'SU_Utils'.static.PRES().m_kInterceptionEngagement.manager.ToFlashHex(class'SU_UIInterceptionEngagement'.default.DAMAGE_BAR_BG_COLOR));
		gfxShip.m_gfxDamageBar.SetHeight(16.0/GetCombatScale());
		fWidthAdj = 1.0;
		if(iCurrentNumShips >= 3)
		{
			fWidthAdj = 1 + 0.12 / (1-0.12)**(iCurrentNumShips - 2+3);
			`Log(GetFuncName() @ gfxShip @ "fScale" @ fScale @ "fAdj" @ fWidthAdj);
		}
		fX = gfxShip.GetObject("effectsMC").GetFloat("_width")/fScale*fWidthAdj;
		fY = gfxShip.GetObject("effectsMC").GetFloat("_height")/fScale *1.2;
		gfxShip.GetObject("effectsMC").GetPosition(fOffsetStepX, fOffsetStepY);
		gfxShip.m_gfxDamageBar.SetWidth(fX*tDisplay.XScale/100.0);
		gfxShip.m_gfxDamageBar.SetPosition(fOffsetStepX - fX/fWidthAdj * tDisplay.XScale/100.0, fOffsetStepY + fY * tDisplay.YScale/100.0);
		
		//ATTACH targeting reticle
		gfxShip.AttachUFOTargetMarker(fScale, GetCombatScale());
		
		//ATTACH ammo text field
		gfxShip.AttachAmmoTxtField(GetCombatScale() * 0.8);

		//ATTACH leader's flag
		gfxShip.AttachLeaderFlag(fScale, GetCombatScale());

		//ATTACH SELECTION BOX - it cannot be fully transparent in order to respond to mouse events, so alpha is set to 5%
		gfxShip.m_gfxFocusBorder = UIModGfxSimpleShape(gfxShip.GetObject("effectsMC").CreateEmptyMovieClip("selectionBorder",,class'UIModGfxSimpleShape'));
		gfxShip.m_gfxFocusBorder.DrawRoundedRectangle(fX, fY,, true, 0xFFFFFF, 5, true, 0x67E8ED, 1);
		gfxShip.m_gfxFocusBorder.SetPosition(-fX/fWidthAdj, 0.0);
		gfxShip.SetFocus(false);		
		class'UIModUtils'.static.AS_BindMouse(gfxShip.m_gfxFocusBorder);//this binds mouse handlers to the object
		class'UIModUtils'.static.AS_AddMouseListener(gfxShip.m_gfxFocusBorder);//this subscribes the object to OnMouseEvent calls

	}
	else
	{
		gfxTempLocation = gfxShip.CreateEmptyMovieClip("startDistanceLocation");
		gfxShip.GetPosition(fX, fY);
		gfxTempLocation.SetFloat("x", fX);//FIXME, fixed 130/30 modifiers must be tested on different UFOs
		gfxTempLocation.SetFloat("y", fY);
		class'UIModUtils'.static.LocalToGlobal(gfxTempLocation, gfxShip);
		gfxShip.SetGlobalStartingLoc(gfxTempLocation);
	}
	gfxShip.SetVisible(true);
}
function SetShipHP(string ShipName, int iNewHP, bool bAdjustDamageDiagram, optional int iWeaponID=-1)
{
	local SUGfx_Ship gfxShip;

	gfxShip = GetShip(ShipName);
	`Log(GetFuncName() @ ShipName @ gfxShip @ iNewHP @ bAdjustDamageDiagram @ iWeaponID,, 'SquadronUnleashed');
	gfxShip.SetHP(iNewHP);
	if(bAdjustDamageDiagram)
	{
		gfxShip.AdjustDamageMasks();
	}
	if(iWeaponID != -1)
	{
		gfxShip.AS_RemoveWeaponFromID(iWeaponID, ShipName);//removes projectile's movie clip (reduces memory overhead)
	}
}
function SUGfx_Ship GetShip(coerce string ShipName)//using 'coerce' will allow easy passing of XGShip as argument
{
	return SUGfx_Ship(GetObject("combatContainer").GetObject(ShipName, class'SUGfx_Ship'));
}
function SetShipFocus(coerce string ShipName)
{
	if(ShipName != m_strSelectedShip)
	{
		if(m_strSelectedShip != "")
		{
			GetShip(m_strSelectedShip).SetFocus(false);
		}
		m_strSelectedShip = ShipName;
	}
	GetShip(ShipName).SetFocus(true);
}
function SetPlayerShip(coerce string ShipName)
{
	`Log(GetFuncName() @ ShipName,, 'SquadronUnleashed');
	SetObject("playerShip", GetShip(ShipName));
}
function SetAlienShip(coerce string ShipName)
{
	`Log(GetFuncName() @ ShipName,, 'SquadronUnleashed');
	SetObject("alienShip", GetShip(ShipName));
}
function MovementEvent(coerce string ShipName, int iMoveEventType, float fMoveDuration)
{
	local SUGfx_Ship gfxShip;
	local GFxObject gfxDestinationLoc;

	gfxShip = GetShip(ShipName);
	if(gfxShip.GetFloat("currHP") < 0.0 || gfxShip.m_bMoving)
	{
		return;
	}
	if(iMoveEventType != -1)
	{
		if(iMoveEventType == 1 && !gfxShip.m_bClosedIn)
		{
			gfxDestinationLoc = gfxShip.GetCloseDistanceLoc();			
			class'SU_Utils'.static.PRES().SetTimer(fMoveDuration, false, 'ToggleClosedInStatus', gfxShip);
		}
		else if(iMoveEventType == 0 && gfxShip.m_bClosedIn)
		{
			gfxShip.m_bClosedIn = false;
			gfxDestinationLoc = gfxShip.GetGlobalStartingLoc();
		}
	}
	else
	{
		gfxShip.m_bClosedIn=false;
		gfxDestinationLoc = GetObject("playerEscapeLocationInShipSpace");			
	}
	if(gfxDestinationLoc != none)
	{
		gfxShip.AS_ShipMoveToLocation(gfxDestinationLoc, fMoveDuration);
	}
}
function AttackEvent(string sourceShipName, string targetShipName, int iWeaponType, int iWeaponID, int iDamage, float fAttackDuration, bool bHit)
{
	local SUGfx_Ship gfxAttacker, gfxTarget;

	`Log("AttackEvent: sourceShip=" $ sourceShipName $ ", targetShip=" $ targetShipName $ ", weapon=" $ iWeaponType $ ", weaponID=" $ iWeaponID $ ", attackDuration=" $ fAttackDuration $ ", hit=" $ (bHit?"true":"false"),, 'SquadronUnleashed');
	gfxAttacker = GetShip(sourceShipName);
	gfxTarget = GetShip(targetShipName);
	if(gfxAttacker.m_bClosedIn || gfxTarget.m_bClosedIn && bHit)
	{
		gfxTarget.AS_UpdateFiringLocation();
		gfxAttacker.AS_UpdateFiringLocation();
		fAttackDuration = CalculateDurationOffsetBasedOnDistance(fAttackDuration, sourceShipName, targetShipName);
	}
	if(iWeaponType == 2)
    {
        iWeaponType = 3;
    }
	if(gfxAttacker.GetFloat("currHP") > 0.0)
	{
		gfxAttacker.AS_Fire(gfxTarget, iWeaponType, iWeaponID, iDamage, fAttackDuration, bHit);
	}
}
function float CalculateDurationOffsetBasedOnDistance(float fDuration, string sourceShipName, string targetShipName)
{
	local float fAdjustedDuration, fDistance;
	local Vector2D vSourceLoc, vTargetLoc;
	local GfxObject gfxSourceGlobalLoc, gfxTargetGlobalLoc;

	gfxSourceGlobalLoc = GetShip(sourceShipName).AS_GetGlobalFiringLocation();
	vSourceLoc.X = gfxSourceGlobalLoc.GetFloat("x");
	vSourceLoc.Y = gfxSourceGlobalLoc.GetFloat("y");

	gfxTargetGlobalLoc = GetShip(targetShipName).AS_GetGlobalFiringLocation();
	vTargetLoc.X = gfxTargetGlobalLoc.GetFloat("x");
	vTargetLoc.Y = gfxTargetGlobalLoc.GetFloat("y");

//	LogInternal(GetFuncName() @ "vSource" @ vSourceLoc.X @ vSourceLoc.Y @ "vTarget" @ vTargetLoc.X @ vTargetLoc.Y @ "standardShotDistance" @ GetFloat("standardShotDistance"));
	
	fDistance = V2DSize(vTargetLoc - vSourceLoc);
	fAdjustedDuration = fDistance / GetFloat("standardShotDistance") * fDuration;
	`Log(GetFuncName() @ "fDuration=" $ fDuration $ ", fDistance" $ fDistance $ ", fAdjustedDuratione=" $ fAdjustedDuration,, 'SquadronUnleashed'); 
	return fAdjustedDuration;
}
function SetUFOTarget(coerce string ShipName)
{
	if(m_strCurrentUFOTarget != ShipName)
	{
		if(m_strCurrentUFOTarget != "")
		{
			GetShip(m_strCurrentUFOTarget).SetUFOTarget(false);
		}
		m_strCurrentUFOTarget = ShipName;
	}
	GetShip(m_strCurrentUFOTarget).SetUFOTarget(true);
}
function SetLeaderFlag(coerce string ShipName, optional bool bVisible=true)
{
	GetShip(ShipName).m_gfxLeaderFlag.SetVisible(bVisible);
}
function string GetSelectedShipName()
{
	return m_strSelectedShip;
}
function float GetCombatScale()
{
	return GetObject("combatContainer").GetDisplayInfo().XScale / 100.0;
}

/** Replaces PlayerTakeDamage (AS function) with specified fnCallback on Unreal side. 
 *  Make sure fnCallback handles all necessary mechanics. 
 *  It is NOT possible to execute original Action Script version with "super."
 */
function AS_SetPlayerTakeDamageDelegate(delegate<ShipTakeDamage> fnCallback)
{
	ActionScriptSetFunction("PlayerTakeDamage");
}
function AS_SetAlienTakeDamageDelegate(delegate<ShipTakeDamage> fnCallback)
{
	ActionScriptSetFunction("AlienTakeDamage");
}
function AS_AlienTakeDamage()
{
	//empty - we want to disable it to ensure freedom in assigning damage to specific targetShip
}
function AS_PlayerTakeDamage()
{
	//empty - we want to disable it to ensure freedom in assigning damage to specific targetShip
}
function float AS_CalculateDurationOffsetBasedOnDistance(float fAttackDuration)
{
	return ActionScriptFloat("CalculateDurationOffsetBasedOnDistance");
}
DefaultProperties
{
}