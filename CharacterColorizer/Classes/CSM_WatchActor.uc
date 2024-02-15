class CSM_WatchActor extends Actor;

var XGUnit m_kUnit;
var Texture m_kCharSkin;
var int m_hWatchSkin;

function WatchMaterialsForUnit(XGUnit kUnit)
{
	m_kUnit = kUnit;
	m_kUnit.GetPawn().Mesh.GetMaterial(0).GetTextureParameterValue('Diffuse', m_kCharSkin);
	if(!kUnit.IsDeadOrDying())
	{
		m_hWatchSkin = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(kUnit.GetPawn().Mesh, 'Materials', self, RefreshSkin, 0);
	}
}
function RefreshSkin()
{
	local Texture kCurrent;

	if(UnitIsBusy())
	{
		SetTimer(0.20);
		return;
	}
	m_kUnit.GetPawn().Mesh.GetMaterial(0).GetTextureParameterValue('Diffuse', kCurrent);
	if(kCurrent != m_kCharSkin)
	{
		class'CharSkinsMutator'.static.ApplySkin(m_kUnit, m_kCharSkin, false);
		SetTimer(0.10);// a safety "one more" pass
	}
	if(m_kUnit.IsInState('Dead'))
	{
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_hWatchSkin);
	}
}
function bool UnitIsBusy()
{
	local bool bBusy;

	bBusy = m_kUnit.AreDyingActionsInQueue();
	bBusy = bBusy || (XComSeeker(m_kUnit.GetPawn()) != none && m_kUnit.GetPawn().Mesh.GetMaterial(0).IsA('MaterialInstanceTimeVarying'));
	bBusy = bBusy || (XComOutsider(m_kUnit.GetPawn()) != none && m_kUnit.GetPawn().Mesh.GetMaterial(0).IsA('MaterialInstanceTimeVarying'));
	return bBusy;
}
function Timer()
{
	RefreshSkin();
}
DefaultProperties
{
}
