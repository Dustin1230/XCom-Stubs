/** The concepts used in this code are based on the work of 'tracktwo' - the great modder and author of such cool mods like Loadout Manager,
 *  Line of Sight Indicators or Campaign Summary. His original work to be found on nexusmods.com.*/
class XHHelper_Sightlines extends Actor;

var bool m_bIconIndicator;

`define MyStatic class'MyXCom'.static

/** Converts each of specified parameters to a string and joins them all into one string (with "," separator) .*/
function string BuildParamString(optional coerce string P1, optional coerce string P2, optional coerce string P3, optional coerce string P4, optional coerce string P5, optional coerce string P6, optional coerce string P7, optional coerce string P8, optional coerce string P9, optional coerce string P10)
{
	local string strToReturn;

	strToReturn = P1 $ "," $ P2 $ "," $ P3 $ "," $ P4 $ "," $ P5 $ "," $ P6 $ "," $ P7 $ "," $ P8 $ "," $ P9 $ "," $ P10;
	while(Right(strToReturn, 1) == ",")
	{
		strToReturn = Left(strToReturn, Len(strToReturn) - 1);
	}
	return strToReturn;
}
/** Wrapper for Mutate call.
 *  @param MutateString Defaults to "NameOfClass.FuncName:NameOfCallingActor" which is fine in overriding classes. Otherwise you should specify the string manually.
 */
function Mutate(optional string MutateString=class'MyXCom'.static.GetFunctionName(true, 4) $ ":" $ string(self))
{
	class'Engine'.static.GetCurrentWorldInfo().Game.BaseMutator.Mutate(MutateString, GetALocalPlayerController());
}
function SubscribeToUnitFlagUpdate(UIUnitFlag kFlag)
{
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(kFlag.m_kUnit, 'm_iZombieMoraleLoss', kFlag, kFlag.RealizeEKG);
}
/** Show/hide OW icon indicator*/
function UpdateOWIcon(UIUnitFlag kFlag)
{
	local ASValue myValue;
	local array<ASValue> myArray;
	local int ekgState;
	local GFxObject gfxOWIcon;
	local ASColorTransform tColorTransform;
	local ASDisplayInfo tDisplay;

	if(SightlineMutator(class'XComHexMods'.static.GetMutator("Sightlines.SightlineMutator")) == none)
	{
		return;
	}
	if(kFlag != none)
	{
		gfxOWIcon = kFlag.manager.GetVariableObject(kFlag.GetMCPath() $ ".overwatchMC");
		ekgState = int(kFlag.m_kUnit.IsPanicked() || kFlag.m_kUnit.IsPanicking() || kFlag.m_kUnit.IsPanicActive());	
		m_bIconIndicator = SightlineMutator(class'XComHexMods'.static.GetMutator("Sightlines.SightlineMutator")).SightIndicator == eIndicator_Overwatch;
		if((kFlag.m_kUnit.m_iZombieMoraleLoss & 0x40000000) != 0 && m_bIconIndicator)
		{
			kFlag.m_ekgState = ekgState;
			myValue.Type = AS_Boolean;
			myValue.B = true;
			myArray.AddItem(myValue);
			kFlag.Invoke("SetWeapon", myArray);
		}
		else if(!m_bIconIndicator || (kFlag.m_kUnit.m_iZombieMoraleLoss & 0x60000000) == 0)
		{
			kFlag.SetWeapon();
		}
		tColorTransform = gfxOWIcon.GetColorTransform();
		tDisplay = gfxOWIcon.GetDisplayInfo();
			tColorTransform.add.R = 0.0;
			tColorTransform.add.G = 0.0;
			tColorTransform.add.B = 0.0;
			tColorTransform.multiply.R = 1.0;
			tColorTransform.multiply.G = 1.0;
			tColorTransform.multiply.B = 1.0;
			tColorTransform.multiply.A = 1.0;
			tDisplay.XScale=100.0;
			tDisplay.YScale=100.0;
		if(m_bIconIndicator)
		{
			if((kFlag.m_kUnit.m_iZombieMoraleLoss & 0x60000000) != 0)
			{
				tColorTransform.add.R = 252.0;
				tColorTransform.add.G = 205.0;
				tColorTransform.add.B = 52.0;
				tColorTransform.multiply.R = 0.01;
				tColorTransform.multiply.G = 0.01;
				tColorTransform.multiply.B = 0.01;
				tColorTransform.multiply.A = 0.70;
				if(kFlag.m_kUnit.m_aCurrentStats[eStat_Reaction] <= 0)
				{
					tDisplay.XScale=50.0;
					tDisplay.YScale=50.0;
					//tColorTransform.add.R = 0.0;
					//tColorTransform.add.G = 100.0;
					//tColorTransform.multiply.B = 0.01;
					//tColorTransform.multiply.A = 0.70;
				}
			}
		}
		gfxOWIcon.SetColorTransform(tColorTransform);
		gfxOWIcon.SetDisplayInfo(tDisplay);
	}
}
/**	Remove helper units from m_arrVisibleCivilians*/
function OnUnitEndMove(string strParams)
{
	local string sName;
	local XGUnit kUnit;
	local int i;

	sName = class'MyXCom'.static.GetParameterString(1, strParams);
	kUnit = XGUnit(class'MyXCom'.static.GetActor(class'XGUnit', sName));
	if(kUnit.m_arrVisibleCivilians.Length > 0)
	{
		for(i = kUnit.m_arrVisibleCivilians.Length; i >= 0; --i)
		{
			if(!kUnit.m_arrVisibleCivilians[i].IsVisible())
			{
				kUnit.m_arrVisibleCivilians.Remove(i, 1);
			}
		}
	}
}
/** Not allow helper units block interaction*/
function FixUpdateInteractclaim(XGUnit kUnit, string strParams, out string sCallback)
{
	//skip UpdateInteractClaim for LoS helper units
	if(kUnit.IsAlien_CheckByCharType() && kUnit.GetTeam() == eTeam_Neutral)
	{
		sCallback="Return"; //this makes CustomCode return "true"
	}
}
/** Make "Poisoned" pop-ups not appear on the helper units*/
function FixOnEnterPoison(XGUnit kUnit, string strParams, out string sCallback)
{
	if(kUnit.IsAlien_CheckByCharType() && kUnit.GetTeam() == eTeam_Neutral)
	{
		sCallback="Return"; //this makes CustomCode return "true"
	}
}
/** Make LoS updated with using grapple locations?*/
function FixIndicatorsOnGrapple(XGUnit kUnit, string strParams, out string sCallback)
{
	if(kUnit.GetAction() != none && XGAction_Targeting(kUnit.GetAction()) != none && XGAction_Targeting(kUnit.GetAction()).m_kShot != none && XGAbility_Grapple(XGAction_Targeting(kUnit.GetAction()).m_kShot) != none)
	{
		kUnit.m_bBuildAbilitiesTriggeredFromVisibilityChange = false;
		sCallback = "Return";
	}
}
/** XGUnitNativeBase.SetBETemplate: Do not set up the bioelectric skin particle effect template for helper units.
 *  This ensures we don't detect them with bioelectric skin.
 */
function FixBioelectricSkin(XGUnit kUnit, string strParams, out string sCallback)
{
	//skip UpdateInteractClaim for LoS helper units
	if(kUnit.IsAlien_CheckByCharType() && kUnit.GetTeam() == eTeam_Neutral)
	{
		sCallback="Return"; //this makes CustomCode return "true" and skip execution of original SetBETemplate
	}
}
/** Make helpers not appear on motion tracker's radar*/
function UpdateBlipsForHelpers()
{
	local XGUnit kUnit;
	local UITacticalHUD_Radar kRadar;
	local int I;
    local string Data;

	kRadar = XComPresentationLayer(XComPlayerController(WorldInfo.GetALocalPlayerController()).m_Pres).m_kTacticalHUD.m_kRadar;
	for(I = 0; I < kRadar.m_arrBlips.Length; ++I)
	{
		kUnit = XGUnit(kRadar.m_arrBlips[I].TargetActor);
		//check if this is a blip for helper
		if(kUnit != none && kUnit.IsAlien_CheckByCharType() && kUnit.GetTeam() == eTeam_Neutral)
		{
			//hide blip for a helper
			kRadar.m_arrBlips[I].Type = eBlipType_None;
		}
		Data $= (string(int(kRadar.m_arrBlips[I].Type)) $ "," $ string(kRadar.m_arrBlips[I].Loc.X) $ "," $ string(kRadar.m_arrBlips[I].Loc.Y));
		if(I < (kRadar.m_arrBlips.Length - 1))
		{
			Data $= "//";
		}
	}
	if(kRadar.m_arrBlips.Length == 0)
	{
		Data $= "0,0,0";
	}
	kRadar.AS_UpdateBlips(Data);
}
DefaultProperties
{
}
