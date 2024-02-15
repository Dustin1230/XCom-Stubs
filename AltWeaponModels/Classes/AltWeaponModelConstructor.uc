class AltWeaponModelConstructor extends ActorFactorySkeletalMesh
	dependson(AltWeaponsMutator);

var MaterialInterface MaterialBase;

//[0019.56] ScriptLog: Found textureParamName Diffuse
//[0019.56] ScriptLog: Found textureParamName Normal
//[0019.56] ScriptLog: Found textureParamName Spc_Ems_Ref

function Init()
{
}
function ApplyTextures(XComWeapon Weapon, TConfigWeaponModelData tInfo)
{
	local int iMat;
	local SkeletalMeshComponent SMC;
	local MaterialInstanceConstant MIC;
	local string sPackage;
	local Texture2D TextureSample;
	local Texture outTexture;
	local LinearColor cmod;

	SkeletalMesh=none;
	if(tInfo.MeshPath!="")
	{
		SkeletalMesh = SkeletalMesh(DynamicLoadObject(tInfo.MeshPath, class'SkeletalMesh', true));
	}
	if(SkeletalMesh != none)
	{
		SMC = SkeletalMeshComponent(Weapon.Mesh);
		MaterialBase = MaterialInstanceConstant((XComContentManager(Class'Engine'.static.GetEngine().GetContentManager()).GetWeaponTemplate(EItemType(tInfo.ItemType)).Mesh).GetMaterial(0)).Parent;
		SMC.SetSkeletalMesh(SkeletalMesh);
		`log(GetFuncName() @ tinfo.MeshPath @ "num elements" @ SMC.GetNumElements());
		sPackage = Left(tInfo.MeshPath, InStr(tInfo.MeshPath, "."));
		for(iMat=0; iMat < SMC.GetNumElements(); ++iMat)
		{
			//check if the main texture is there for the element
			TextureSample = Texture2D(DynamicLoadObject(sPackage$".Materials.Material"$iMat$"_DIFF", class'Texture2D', true));
			//apply the main texture:
			if(TextureSample != none)
			{
				MIC = new (Weapon) class'MaterialInstanceConstant';
				MIC.SetParent(MaterialBase);
				MIC.SetTextureParameterValue('Diffuse', TextureSample);
				MIC.GetTextureParameterValue('Diffuse', outTexture);
				`log(outTexture.Name);
				
				//apply normal map if exists"
				TextureSample = Texture2D(DynamicLoadObject(sPackage$".Materials.Material"$iMat$"_NRM", class'Texture2D', true));
				if(TextureSample != none)
				{
					MIC.SetTextureParameterValue('Normal', TextureSample);
					MIC.GetTextureParameterValue('Normal', outTexture);
					`log(outTexture.Name);
				}
				//apply specular map if exists"
				TextureSample = Texture2D(DynamicLoadObject(sPackage$".Materials.Material"$iMat$"_SPC", class'Texture2D', true));
				if(TextureSample != none)
				{
					MIC.SetTextureParameterValue('Spc_Ems_Ref', TextureSample);
					MIC.GetTextureParameterValue('Spc_Ems_Ref', outTexture);
					`log(outTexture.Name);
				}
				cmod = MakeLinearColor(5.9, 6.0, 6.0, 6.0);
				MIC.SetVectorParameterValue('CMOD', cmod);
				cmod = MakeLinearColor(1.0, 1.0, 1.0, 50.0);
				MIC.SetVectorParameterValue('SpcColor_SpcGloss', cmod);

				MIC.SetBooleanParameterValue('Add_Reflection', true);
				SMC.SetMaterial(iMat, MIC);

			}
		}
	}
}

defaultproperties
{
//begin object class=Material Name=MaterialTemplate
//    begin object class=MaterialExpressionTextureSampleParameter2D name=MaterialExpressionTexture_DIFF
//		ParameterName="Diffuse"
//		Material=MaterialTemplate
//    end object

//    begin object class=MaterialExpressionTextureSampleParameter2D name=MaterialExpressionTexture_NRM
//		ParameterName="Normal"
//        Material=MaterialTemplate
//    end object

//    begin object class=MaterialExpressionTextureSampleParameter2D name=MaterialExpressionTexture_SPC 
//		ParameterName="Specular"
//        Material=MaterialTemplate
//    end object

//    Expressions(0)=MaterialExpressionTexture_DIFF
//    Expressions(1)=MaterialExpressionTexture_NRM
//    Expressions(2)=MaterialExpressionTexture_SPC

//    DiffuseColor=(Expression=MaterialExpressionTexture_DIFF,Mask=1,MaskR=1,MaskG=1,MaskB=1)
//    SpecularColor=(Expression=MaterialExpressionTexture_SPC,OutputIndex=4,Mask=1,MaskA=1)
//    Normal=(Expression=MaterialExpressionTexture_NRM,Mask=1,MaskR=1,MaskG=1,MaskB=1)
//    bUsedWithSkeletalMesh=true
//end object
//MaterialBase=MaterialTemplate
}