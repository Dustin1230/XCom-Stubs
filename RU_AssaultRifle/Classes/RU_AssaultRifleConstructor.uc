class RU_AssaultRifleConstructor extends ActorFactorySkeletalMesh;

simulated event PostCreateActor(Actor NewActor)
{
	SkeletalMesh=SkeletalMesh(DynamicLoadObject(MenuName, class'SkeletalMesh'));
	SkeletalMeshComponent(Weapon(NewActor).Mesh).SetSkeletalMesh(SkeletalMesh);
	Weapon(NewActor).Mesh.SetMaterial(0, MaterialInstanceConstant'Mat_AR_Mag_INST');
}

defaultproperties
{
MenuName="RU_AssaultRifle.AssaultRifle_Mesh"

begin object name=Mat_AR_Mag class=Material

    begin object name=MaterialExpressionTexture_MagDIFF class=MaterialExpressionTextureSample
        Texture=Texture2D'Materials.low_Magazine_BaseColor'
        Material=Mat_AR_Mag
    object end

    begin object name=MaterialExpressionTexture_MagNRM class=MaterialExpressionTextureSample
        Texture=Texture2D'Materials.low_Magazine_Normal'
        Material=Mat_AR_Mag
    object end

    begin object name=MaterialExpressionTexture_MagSPC class=MaterialExpressionTextureSample
        Texture=Texture2D'Materials.low_Magazine_OcclusionRoughnessMetallic'
        Material=Mat_AR_Mag
    object end

    Expressions(0)=MaterialExpressionTexture_MagDIFF
    Expressions(1)=MaterialExpressionTexture_MagNRM
    Expressions(2)=MaterialExpressionTexture_MagSPC

    DiffuseColor=(Expression=MaterialExpressionTexture_MagDIFF,Mask=1,MaskR=1,MaskG=1,MaskB=1)
    SpecularColor=(Expression=MaterialExpressionTexture_MagSPC,OutputIndex=4,Mask=1,MaskA=1)
    Normal=(Expression=MaterialExpressionTexture_MagNRM,Mask=1,MaskR=1,MaskG=1,MaskB=1)
    bUsedWithSkeletalMesh=true
object end
begin object name=Mat_AR_Mag_INST class=MaterialInstanceConstant
    Parent=Mat_AR_Mag
object end
}