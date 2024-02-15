//By extending XGEntity we sign up the class to the ActorClassesToRecord 
//so instances of this class will be saved and can be "fished out" after loading from save
class AscHelper_ScienceLabs extends XGEntity;

struct TResearchLead
{
	var string Name; //will be probably pushed to the UI/HUD
	var float Modifier;//hourly-progress of the main project is multiplied by this and applied to the progress of iTech
	var int Salary;

	structdefaultproperties
	{
		Modifier=0.50
	}
};

struct TResearchTeam
{
	var int iTech; //tech id assigned to the team
	var TResearchLead tLeader;
};

//the list variables we want to be saved
struct CheckpointRecord_AscHelper_ScienceLabs extends CheckpointRecord
{
	var array<TResearchTeam> m_arrResearchTeams;
	var array<TResearchLead> m_arrResearchLeads;
};

var array<TResearchTeam> m_arrResearchTeams;
var array<TResearchLead> m_arrResearchLeads;
var array<int> m_arrOvertime;//this is supposed to store progress "above" what is required to finish a project
var int m_iWatchLabsTimeSpent; //just a pointer to the watchVariable, useful when we want to EnableDisableWatchVariable
var bool m_bUpdatingProgress;//important flag to know that we are currently modifying projects' progress and some stuff must not be done then

//referencet to the main labs actor of the game
function XGFacility_Labs LABS()
{
	return XComHeadquartersGame(Class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().m_kLabs;
}
//this is fired when we spawn our labs helper
function Init(EEntityGraphic eGraphic)
{
	//if there is no project yet (new game or mod installed during ongoing campaign)
	if(m_arrResearchTeams.Length == 0)
	{
		//we want to add the sole, main project to the list of projects
		m_arrResearchTeams.Add(1);//might seem unnecessary but saves one less "Accessed none" entry in the log;
		
		//if there is any project assigned in the main labs...
		if(LABS().HasProject())
		{
			//cache the sole, main project as the very first in our list of projects
			m_arrResearchTeams[0].iTech = LABS().m_kProject.iTech;
			//ParseLocalizedPropertyPath is built-in UE helper to grab entry from a localization file, expects: "Package.Section.Entry"
			m_arrResearchTeams[0].tLeader.Name = ParseLocalizedPropertyPath("XComStrategyGame.SpeakerNames.DrVahlen");
			m_arrResearchTeams[0].tLeader.Modifier=1.0;
			m_arrResearchTeams[0].tLeader.Salary=0;
		}
	}
	m_arrOvertime.Length = LABS().m_arrProgress.Length;//initialize m_arrOvertime with the same number of techs as the main lab (in case some mod added sth to the list)
	CheckForRequiresAttention();//we want to add "!" yellow mark and announcement in HQ when some team has no project or whatever important event
	WatchLabsTimeSpent();//this is crucial - we start watching TimeSpent variable of the main LABS; this way we know when to update our projects as well.
}
function UpdateProgress()
{
	local TResearchTeam tProject;
	local TResearchProject tMainProject;
	local XGFacility_Labs kLabs;
	local int i;
	local TTech kTech;
	local float fTechTimeBalanceBackup;

	if(!m_bUpdatingProgress) //we want the progress be applied once, just in case the function got fired up multiple times
	{
		//we will be using main LABS update function to apply progress to our projects and it will fire THIS function by altering TimeSpent, 
		//so we want to pause the watchVariable on the TimeSpent var
		WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchLabsTimeSpent, false);
		
		m_bUpdatingProgress = true;//set the flag
		
		//grab main LABS actor, we will be using it a few times - it's faster to grab it once than to do it each time we need it.
		kLabs = LABS(); 
		
		//we will be altering this config var to cheat the main LABS :) so we backup it
		fTechTimeBalanceBackup = Class'XGTacticalGameCore'.default.TECH_TIME_BALANCE;

		if(kLabs.HasProject())
		{
			tMainProject = kLabs.GetCurrentProject();
		}
		//we will now loop over all the teams 
		//and for each team set their project as the main project of the main LABS
		//then we alter config TECH_TIME_BALANCE with Modifier of the team
		//and then fire main LABS update function
		//this way LABS will run its "update progress on the project" applying the progress to our "side" project
		for(i=m_arrResearchTeams.Length-1; i >=0; i--)
		{
			tProject = m_arrResearchTeams[i];//grab a project from the list
			if(tProject.iTech == tMainProject.iTech || tProject.iTech == 0)
			{
				continue;//skip the main project (it's already updated) or if the team has no project
			}
			//substitute m_kProject data of the main LABS
			kTech = kLabs.TECH(tProject.iTech);//convert iTech into TTEch data from XGTechTree
			//feed the main LABS project data with our "currently iterated" project
			kLabs.m_kProject.iTech = tProject.iTech;
			kLabs.m_kProject.iActualHoursLeft = (kTech.iHours < 0 ? 1 : kTech.iHours);
			kLabs.m_kProject.iProgress = kLabs.GetProgress(tProject.iTech);//NOTE: this is operating on OUR iTech
			class'XGTacticalGameCore'.default.TECH_TIME_BALANCE = fTechTimeBalanceBackup * tProject.tLeader.Modifier;//cheat the config var
			
			//call the original Update
			kLabs.Update();
			//compensate m_iRequestCounter (cause there is "m_iRequestCounter--" line in the main Update function)
			if(LABS().m_iRequestCounter > 0)
			{
				LABS().m_iRequestCounter ++;
			}
			//remove the team if the project got completed during the Update;
			if(!kLabs.HasProject())
			{
				m_arrResearchTeams[i].iTech = 0;
			}
		}
		Class'XGTacticalGameCore'.default.TECH_TIME_BALANCE = fTechTimeBalanceBackup;//restore true config value
		if(kLabs.HasProject() && kLabs.GetCurrentProject().iTech != tMainProject.iTech)
		{
			kLabs.m_kProject = tMainProject;//restore the true main project from backup
		}
		//if main LABS has no project (cause the main project got completed)
		//set the nearest "side" project as the main project
		if(!kLabs.HasProject())
		{
			for(i=0; i < m_arrResearchTeams.Length; ++i)
			{
				if(m_arrResearchTeams[i].iTech != 0)
				{
					tProject = m_arrResearchTeams[i];
					kLabs.RefundCost(kLabs.TECH(tProject.iTech).kCost, tProject.iTech == 1);
					kLabs.SetNewProject(tProject.iTech);
					break;
				}
			}
		}
		SetTimer(0.10, false, 'WatchLabsTimeSpent');//this will re-enable the watchVariable handle
	}
	CheckForRequiresAttention();
}
function WatchLabsTimeSpent()
{
	m_bUpdatingProgress = false;//while enabling the watch handle we reset the flag
	if(m_iWatchLabsTimeSpent != -1)
		WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchLabsTimeSpent, true);
	else
		m_iWatchLabsTimeSpent = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(LABS(), 'm_arrTimeSpent', self, UpdateProgress);
}
function CheckForRequiresAttention()
{
	local bool HasIdleTeam;

	HasIdleTeam = m_arrResearchTeams.Find('iTech', 0) != -1;//a team with iTech=0 is considered "idle"

	if(HasIdleTeam && !LABS().m_bRequiresAttention)
	{
		LABS().m_bRequiresAttention = true;//this will add yellow "!" and make the voice announcement to check on LABS
	}
}
//a helper function to generate a leader with random name from soldier's second name lists
function AddResearchLead(optional string strName)
{
	local string sFirst;

	if(strName == "")
	{
		LABS().BARRACKS().m_kCharGen.GenerateName(Rand(2), Rand(eCountry_MAX), sFirst, strName);
	}
	m_arrResearchLeads.Add(1);
	m_arrResearchLeads[m_arrResearchLeads.Length-1].Name = strName;
}
function int GetTotalSalaries()
{
	local TResearchLead tLead;
	local int iTotal;

	foreach m_arrResearchLeads(tLead)
	{
		iTotal += tLead.Salary;
	}
	return iTotal;
}
//the main mutator will push this state when player goes to LABS
state InLabs
{
	event PushedState()
	{
		WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable(m_iWatchLabsTimeSpent, false);
	}
}
//the main mutator will push this state when player enters "choose tech" UI
state ChoosingTech
{
}
//this is the initial and default state for the helper
auto state InBase
{
	event PushedState()
	{
		WatchLabsTimeSpent();
	}
}
DefaultProperties
{
	m_iWatchLabsTimeSpent=-1
}