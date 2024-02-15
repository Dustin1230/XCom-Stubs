class AscUIContinentSelect extends UIContinentSelect;

simulated function XGContinentUI GetMgr()
{
	//this ensures all (?) data management for the screen will be handled by AscXGContinentUI
    if(m_kLocalMgr == none)
    {
        m_kLocalMgr = AscXGContinentUI(XComHQPresentationLayer(controllerRef.m_Pres).GetMgr(class'AscXGContinentUI', (self), m_iView));
    }
    return m_kLocalMgr;
}
//my experience shows that final cannot be overriden even if we cheat the compiler.... but worth trying anyway

simulated function UpdateInfoPanelData(int iContinent)
{
    local TContOption kOption;

	kOption = GetMgr().m_kMainMenu.arrContOptions[iContinent];
	AS_UpdateInfo(kOption.txtBonusLabel.StrValue, kOption.txtBonusTitle.StrValue, kOption.txtBonusDesc.StrValue);            
	if(GetMgr().m_iChosenContinent < 0)
	{
		XComHQPresentationLayer(Owner).CAMLookAtEarth(GetMgr().Continent(GetMgr().m_arrContinents[iContinent]).GetHQLocation(), 1.0, 0.50);                                                                                                                                                                                                                                                
	}
	else
	{
	    XComHQPresentationLayer(Owner).CAMLookAtEarth(GetMgr().Country(GetMgr().m_arrContinents[iContinent] & 255).GetCoords(), 1.0, 1.0);                                                                                                                                                                                                                                                
	}
}
simulated function bool OnCancel(optional string Str="")
{
	if(GetMgr().IsA('AscXGContinentUI') && GetMgr().m_iChosenContinent != -1)
	{
		AscXGContinentUI(GetMgr()).AS_ClearItemList();
		m_iContinent = GetMgr().m_iChosenContinent;
		GetMgr().m_iChosenContinent = -1;
		AscXGContinentUI(GetMgr()).PopulateContinentsArray();	
		maxContinents = GetMgr().m_arrContinents.Length;
		GetMgr().UpdateView();
		//AscXGContinentUI(kUI.GetMgr()).DumpScreenInfo();
		return true;
	}
	else
	{
		return super.OnCancel(Str);
	}
}

DefaultProperties
{
}
