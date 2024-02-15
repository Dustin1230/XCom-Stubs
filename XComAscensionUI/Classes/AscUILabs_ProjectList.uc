class AscUILabs_ProjectList extends XGStrategyActor;

var int m_iNumListedProjects;
var int m_iCurrentFocusItem;
var float m_fMouseXToUpdateThreshold;
var array<AscGfxResearchProgressMC> m_arrGfxProjects;

/** Create a container of 10 GfxObject duplicates of "currentResearchMC" movie clip*/
function PopulateGfxContainer( delegate<UINavigationHelp.onButtonClickedDelegate> fnEditButtonCallback, optional string strButtonHelpIcon)
{
	local int i;
	local float _y, xOrig, yOrig;
	local AscGfxResearchProgressMC gfxObj;
	
	if(m_arrGfxProjects.Length > 0)
	{
		ClearGfxContainer();
	}
	for(i=0; i<10; ++i)
	{
		if(i==0)
		{
			gfxObj = AscGfxResearchProgressMC(PRES().m_kHUD.GetVariableObject( PRES().m_kStrategyHUD.GetMCPath() $ ".currentResearchMC", class'AscGfxResearchProgressMC'));
			gfxObj.GetPosition(xOrig, yOrig);
			yOrig = 620.0;
			gfxObj.SetPosition(xOrig, yOrig);
		}
		else
		{
			gfxObj = AscGfxResearchProgressMC(class'UIModUtils'.static.AS_DuplicateMovieClip(PRES().m_kStrategyHUD.GetMCPath() $ ".currentResearchMC", "currentResearchMC_"$i,,class'AscGfxResearchProgressMC'));
			_y = yOrig - (i * 50.0);
			gfxObj.SetPosition(xOrig, _y);
		}
		gfxObj.SetVisible(false);
		gfxObj.AS_AttachEditButton(fnEditButtonCallback, strButtonHelpIcon);
		gfxObj.GetObject("description").SetVisible(false);
		gfxObj.GetObject("emptyProgressBar").SetVisible(false);
		class'UIModUtils'.static.AS_GetInstanceAtDepth(-16384+5, gfxObj).SetVisible(false);//original progressBar
		gfxObj.AS_SetFocus(false);
		m_arrGfxProjects.AddItem(gfxObj);
	}

	PopulateDebugData();
}
function PopulateDebugData()
{
	local int i;
	
	for(i=0; i<8; ++i)
	{
		AS_AddProject("DummyProject"$i, "X Days", 0.70);		
	}	
	m_arrGfxProjects[2].AS_SetProgressColor(0,80,0);
	m_arrGfxProjects[2].AS_SetColor(true);
	m_arrGfxProjects[2].AS_SetResearchProgress("","Good Progress", "5 Days", 0.85);

	m_arrGfxProjects[3].AS_SetResearchProgress("","Newly Assigned Project", "24 Days", 0.0);


	m_arrGfxProjects[4].AS_SetProgressColor(238,28,37);
	m_arrGfxProjects[4].AS_SetColor(true);
	m_arrGfxProjects[4].AS_SetResearchProgress("","Very Slow Progress", "44 Days", 0.20);

	m_arrGfxProjects[5].AS_SetResearchProgress("","No Project Assigned", "", -1.0);

	m_arrGfxProjects[6].AS_SetProgressColor(246,116,32);
	m_arrGfxProjects[6].AS_SetColor(true);
	m_arrGfxProjects[6].AS_SetResearchProgress("","Slow Progress", "32 Days", 0.25);

	m_arrGfxProjects[1].AS_SetResearchProgress("", "100% complete", "X Days", 1.0);
}
function ClearGfxContainer(optional bool bOnChooseTech)
{
	local AscGfxResearchProgressMC gfxObj;
	local array<ASValue> arrVal;

	arrVal.Add(1);
	foreach m_arrGfxProjects(gfxObj)
	{
		gfxObj.AS_SetColor(false);
		if(gfxObj == m_arrGfxProjects[0])
		{
			gfxObj.GetObject("editButton").Invoke("removeMovieClip", arrVal);
			//restore visibility of main currentResearchMC elements (which is also used by UIChooseTech)
			gfxObj.GetObject("description").SetVisible(true);
			gfxObj.GetObject("emptyProgressBar").SetVisible(true);
			gfxObj.GetObject("title").SetVisible(true);
			class'UIModUtils'.static.AS_GetInstanceAtDepth(-16384+5, gfxObj).SetVisible(true);
			gfxObj.SetVisible(bOnChooseTech);
		}
		else
		{
			gfxObj.Invoke("removeMovieClip", arrVal);
		}
	}
	m_arrGfxProjects.Length=0;
}
function int UpdateSelectionFromMouseCursor()
{
	local AscGfxResearchProgressMC gfxObj;
	local int iClosestToMouse, iTested;	
	local float fClosest, fDist;


	//get horizontal distance between mouse cursor and the project list
	fDist = PRES().m_kHUD.GetVariableObject( PRES().m_kStrategyHUD.GetMCPath() $ ".currentResearchMC" ).GetObject("description").GetFloat("_xmouse");             
	if(fDist < m_fMouseXToUpdateThreshold)
	{
		//if mouse too far - remove "focus" gfx and skip update
		if(m_iNumListedProjects > 0 && m_iCurrentFocusItem != -1)
		{
			UpdateItemFocus(m_iCurrentFocusItem, false);
			m_iCurrentFocusItem = -1;
		}
	}
	else
	{
		//get vertical distance between mouse cursor and the bottom movie clip (MC)
		fClosest = Abs(m_arrGfxProjects[0].GetObject("description").GetFloat("_ymouse"));          
		foreach m_arrGfxProjects(gfxObj, iTested)
		{
			fDist = Abs(gfxObj.GetObject("description").GetFloat("_ymouse")-10.0);
			if(fDist < fClosest)
			{
				fClosest = fDist;
				iClosestToMouse = iTested;
			}
		}
		iClosestToMouse = Clamp(iClosestToMouse, 0, m_iNumListedProjects-1);
		if(iClosestToMouse != m_iCurrentFocusItem)
		{
			RealizeSelected(iClosestToMouse);
		}
	}
	return m_iCurrentFocusItem;
}
function  RealizeSelected(int iNewSelection)
{
	UpdateItemFocus(m_iCurrentFocusItem, false);
	m_iCurrentFocusItem = iNewSelection;
	UpdateItemFocus(m_iCurrentFocusItem, true);
}
function UpdateItemFocus(int iFocusItem, bool bHasFocus)
{
	local AscGfxResearchProgressMC gfxObj;

	if(iFocusItem > m_arrGfxProjects.Length-1 || iFocusItem < 0)
	{
		return;
	}
	gfxObj = m_arrGfxProjects[iFocusItem];
	gfxObj.AS_SetFocus(bHasFocus);
}
function ToggleVisibility(bool bVisible)
{
	local int i;
	local AscGfxResearchProgressMC gfxObj;

	foreach m_arrGfxProjects(gfxObj, i)
	{
		if(bVisible && i < m_iNumListedProjects)
		{
			gfxObj.SetVisible(true);
		}
		else
		{
			gfxObj.SetVisible(false);
		}
	}
}
function AS_AddProject(string strDescription, string strETA, float fPercentComplete=0.0, optional Color kProgressColor=MakeColor(class'AscGfxResearchProgressMC'.default.m_iCurrentProgressColorR, class'AscGfxResearchProgressMC'.default.m_iCurrentProgressColorG, class'AscGfxResearchProgressMC'.default.m_iCurrentProgressColorB))
{
	if(m_iNumListedProjects > 0)
	{
		m_arrGfxProjects[m_iNumListedProjects-1].GetObject("title").SetVisible(false);
	}
	if(m_iNumListedProjects < 10)
	{
		m_arrGfxProjects[m_iNumListedProjects++].AS_SetResearchProgress(class'XGResearchUI'.default.m_strCurrentResearchTitle, strDescription, strETA, fPercentComplete);
		m_arrGfxProjects[m_iNumListedProjects-1].AS_SetProgressColor(kProgressColor.R, kProgressColor.G, kProgressColor.B);
		m_arrGfxProjects[m_iNumListedProjects-1].AS_SetColor(true);
	}
}
DefaultProperties
{
	m_fMouseXToUpdateThreshold=-10.0
	m_iCurrentFocusItem=-1
}