/**DEPRECATED - for the time being?
 */
class AscUIComponent_ProjectList extends UIStrategyComponent_EventList;

var array<TTech> m_arrOngoingProjects;

simulated function GoToView(int iView);

simulated function Init(XComPlayerController _controller, UIFxsMovie _manager, UI_FxsScreen _screen)
{
	LogInternal(GetFuncName(), 'AscUIComponent_ProjectList');
    super.Init(_controller, _manager, _screen);
	SetTimer(0.10, false, 'OnInit');
}

simulated function OnInit()
{
	local int numProjects;

	LogInternal(GetFuncName(), 'AscUIComponent_ProjectList');
	super(UI_FxsPanel).OnInit();
	AS_ExpandListVertically(m_bExpandListVertically);
	AS_OverrideMaxItemsPerColumn(m_iMaxEventsPerRow);
	numProjects = GetNumOngoingProjects();
	m_iMaxEventsPerRow = numProjects;
	if(numProjects > 0)
	{
		m_strEventListLabel = class'UIUtilities'.static.CapsCheckForGermanScharfesS(class'UIUtilities'.static.GetDaysString(2));
	}
	else
	{
		m_strEventListLabel = "";
	}
	if(m_iMaxEventsPerRow == 1)
	{
		AS_SetTitle("Project in progress", m_strEventListLabel);
	}
	else
	{
		AS_SetTitle("Projects in progress", m_strEventListLabel);
	}
	UpdateData();
}
function int GetNumOngoingProjects()
{
	local int iTech, iTotalTechs, iProgress, iNumInProgress;
	local TTech tProject; 

	m_arrOngoingProjects.Length = 0;
	iTotalTechs = GetMgr().TECHTREE().m_arrTechs.Length;
	LogInternal(GetFuncName() @ "iTotalTechs="$ iTotalTechs);
	for(iTech=0; iTech < iTotalTechs; ++iTech)
	{
		tProject = GetMgr().TECHTREE().GetTech(iTech); //tProject.iHours tells hours left on project
		iProgress = GetMgr().LABS().m_arrProgress[iTech]; //iProgress tells hours spent on project
		if(iProgress > 0 && tProject.iHours > 0 || GetMgr().LABS().m_kProject.iTech == tProject.iTech)
		{
			LogInternal(GetFuncName() @ "found ongoing project on tech" @ tProject.strName);
			m_arrOngoingProjects.AddItem(tProject);
			++iNumInProgress;
		}
	}
	LogInternal(GetFuncName() @ "iNumInProgress="$ iNumInProgress);
	return iNumInProgress;
}
simulated function UpdateData()
{
	local int I, iNumProjects;
	local TTech tProject; 

	m_arrOngoingProjects.Length = 0;
	//if(!b_IsInitialized || XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().m_bGameOver)
	//{
	//	return;
	//}
	LogInternal(GetFuncName(), 'AscUIComponent_ProjectList');
	Invoke("clear");
	iNumProjects = GetNumOngoingProjects();
	for(I=0; I < iNumProjects; ++I)
	{
		tProject = m_arrOngoingProjects[I];
		AS_AddEvent(tProject.strName, class'UIUtilities'.static.GetDaysString(tProject.iHours / 24), string(tProject.iHours / 24), GetEventImageLabel(0,-1));
	}
	if(iNumProjects > 0)
	{
		Show();
	}
	else
	{
		Hide();
	}
}
simulated function ExpandEventList()
{
	if(m_arrOngoingProjects.Length > m_iMaxEventsPerRow)
	{
		AS_SetTitle("Projects in progress", m_strEventListLabel);
		Invoke("ExpandList");
		m_bIsExpanded = true;
		UpdateButtonHelp();
	}
}
function ContractEventList()
{
	if(m_bIsExpanded)
	{
		if(m_iMaxEventsPerRow == 1)
		{
			AS_SetTitle("Project in progress", m_strEventListLabel);
		}
		Invoke("ContractList");
		m_bIsExpanded = false;
		UpdateButtonHelp();
		if(!XComHQPresentationLayer(XComHeadquartersController(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController).m_Pres).GetHUD().IsMouseActive())
		{
			UIStrategyHUD(screen).ShowZoomButtonHelp();
		}
	}
}
simulated function UpdateButtonHelp()
{
	local string helpString;
	local delegate<onButtonClickedDelegate> mouseCallback;

	if(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().m_bInFacilityTransition)
	{
		return;
	}
	if(m_arrOngoingProjects.Length > m_iMaxEventsPerRow)
	{
		helpString = "";
		mouseCallback = None;
		if(m_bIsExpanded)
		{
			if(manager.IsMouseActive())
			{
				helpString = m_strContractEventList;
				mouseCallback = ContractEventList;
			}
		}
		else
		{
			helpString = m_strExpandEventList;
			if(manager.IsMouseActive())
			{
				mouseCallback = ExpandEventList;
			}
		}
		if(UIStrategyHUD(screen).m_kHelpBar.IsInited())
		{
			UIStrategyHUD(screen).m_kHelpBar.ClearButtonHelp();
			if(helpString != "")
			{
				UIStrategyHUD(screen).m_kHelpBar.AddRightHelp(helpString, "Icon_RT_R2", mouseCallback);
			}
			if(controllerRef.IsTouchEnabled())
			{
				UIStrategyHUD(screen).Touch_ShowPauseButtonHelp();
			}
		}
	}
}
DefaultProperties
{
}
