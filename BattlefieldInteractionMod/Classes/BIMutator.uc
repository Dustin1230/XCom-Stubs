class BIMutator extends XComMutator;

var string m_strBuildVersion;

/** This will be displayed in "Mutators" list when using UI Mod Manager*/
function string GetDebugName()
{
	return Class.Name @ m_strBuildVersion;
}
event PostBeginPlay()
{
	super.PostBeginPlay();
	`log(GetDebugName() @ "online");
}
function Actor GetActorByName(string ObjName)
{
	local Actor A;

	foreach DynamicActors(class'Actor', A)
	{
		if(string(A.Name) == ObjName)
		{
			return A;
		}
	}
	return none;
}
function XComPresentationLayer PRES()
{
	return XComPresentationLayer(XComTacticalController(GetALocalPlayerController()).m_Pres);
}
function WorldMessage(string sPopUp, Vector vLoc)
{
	PRES().GetWorldMessenger().Message(sPopUp, vLoc,,1,,,,,5.0);
}
function MutateUpdateInteractClaim(string UnitObjName, PlayerController Sender)
{
	local XGUnit kUnit, kOther;
	local array<Name> arrBoneNames;
	local Name nBone;

	kUnit = XGUnit(GetActorByName(UnitObjName));
	foreach DynamicActors(class'XGUnit', kOther)
	{
		if(kOther.IsCriticallyWounded() && kOther.GetPawn() != none && kUnit != kOther && kUnit != kOther.m_kZombieVictim)
		{
			if( VSizeSq(kOther.GetPawn().Location - kUnit.GetPawn().Location) <= 144.0*144.0)
			{
				kOther.GetPawn().Mesh.GetBoneNames(arrBoneNames);	
				foreach arrBoneNames(nBone)
				{
					`log(kOther.SafeGetCharacterName() @ "bone:" @ nBone);
				}
				//AttachPawn(kUnit.GetPawn(), kOther.GetPawn());//FIXME: only pawn is moved, XGUnit stays in place
				AttachXGUnit(kUnit, kOther);
			}
		}
	}
}

function AttachPawn(Pawn kAttachTo, Pawn kOther)
{
//	local bool PrevCollideActors, PrevBlockActors;

//	PrevCollideActors = kOther.bCollideActors;
//	PrevBlockActors = kOther.bBlockActors;

	kOther.SetCollision(false, false);
	kOther.bCollideWorld = False;
	kOther.SetHardAttach(True);
	//kAttachTo.bCanBeBaseForPawns = True;
	//kOther.SetPhysics(PHYS_Flying);
	XComUnitPawn(kOther).StartRagDoll(true);
	if(XComUnitPawn(kOther).GetGameUnit().SetLocation(XComUnitPawn(kAttachTo).GetHeadLocation()))
	{
		XComUnitPawn(kOther).GetGameUnit().SetBase(kAttachTo, , kAttachTo.Mesh, 'Attach');
		XGUnit(XComUnitPawn(kOther).GetGameUnit()).m_kZombieVictim = XGUnit(XComUnitPawn(kAttachTo).GetGameUnit());
	}
	//kOther.SetCollision(false, PrevBlockActors);
	//XComUnitPawn(kOther).GetGameUnit().SetHardAttach(true);
	//XComUnitPawn(kOther).GetGameUnit().SetBase(kAttachTo);

}
function AttachXGUnit(XGUnit kAttachTo, XGUnit kOther)
{
	kOther.SetCollision(false, false, true);
	kOther.GetPawn().SetCollision(false, false, true);
	kOther.bCollideWorld = False;
	kOther.GetPawn().bCollideWorld = false;
	kOther.SetHardAttach(True);
	//kAttachTo.bCanBeBaseForPawns = True;
	kOther.GetPawn().SetPhysics(PHYS_Flying);
	kOther.SetPhysics(PHYS_Flying);
	kOther.GetPawn().StartRagDoll(true);
	if(kOther.SetLocation(kAttachTo.getpawn().GetHeadLocation()))
	{
		WorldMessage("PickUp", kOther.GetPawn().Location);
		kOther.SetBase(kAttachTo, , kAttachTo.GetPawn().Mesh, 'Attach');
		kOther.m_kZombieVictim = kAttachTo;
	}
}

//function DetachPawn()
//{
//	Pawn.SetBase(None);
//	if (Pawn.Physics == PHYS_Flying)
//		Pawn.SetPhysics(PHYS_Falling);
//	bCanBeBaseForPawns = False;
//	Pawn.SetHardAttach(False);
//	Pawn.SetCollision(Pawn.default.bCollideActors, Pawn.default.bBlockActors);
//	Pawn.bCollideWorld = True;
//}
DefaultProperties
{
	m_strBuildVersion="1.0"
}
