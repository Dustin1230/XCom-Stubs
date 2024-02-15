class WeaponSortMutate extends XComMutator
	config(AltTree)
  	hidecategories(Navigation);

struct TObjectGroups
{
    var string objectGroup;
    var config array<XGGameData.EItemType> objSort;
};

struct TObjectMods
{
    var string objectGroup;
    var int iTech;
    var int iFTech;
  	var int iPerk;
  	var bool bUnlimited;
    var int iDamageBonus;
    var int iAimBonus;
    var int iCritChanceBonus;
  	var int iCritDmgBonus;
    var int iAmmoBonus;
    var int iHPBonus;
  	var int iWillBonus;
    var int iRangeBonus;
    var float fDRBonus;
    var int iDefenseBonus;
    var int iMobilityBonus;
};


var config array<TObjectGroups> objectGroups;
var config array<TObjectMods> objectMods;
//var AltTechTree m_kAltTree;
//var AltItemTree m_kAltItems;
var WeaponSortCheckpoint m_kWSCheckpoint;
var PlayerController m_kSender;

/*function AltTechTree ALTTREE()
{
	return m_kAltTree;
}

function XGTechTree TECHTREE()
{
	LogInternal("This Is Alright");
    return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().GetLabs().m_kTree;
    //return ReturnValue;    
}

function XGFacility_Labs LABS()
{
    return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().m_kLabs;
    //return ReturnValue;    
}

function XGFacility_Engineering ENGINEERING()
{
    return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().m_kEngineering;
    //return ReturnValue;    
}

function XGStorage STORAGE()
{
    return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().m_kEngineering.GetStorage();
    //return ReturnValue;    
}

function XGTacticalGameCore theGameCore()
{
	return XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore;
	//return ReturnValue;
}

function bool IsOptionEnabled(XGGameData.EGameplayOption eOption)
{
    return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().m_arrSecondWave[eOption] > 0;
    //return ReturnValue;    
}

simulated function UIInterfaceMgr GetHUD()
{
    return m_kHUD;
    //return ReturnValue;    
}*/

simulated function XGTacticalGameCore TACTICAL()
{
    return XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kGameCore;
    //return ReturnValue;
}
	
function Mutate(string MutateString, PlayerController Sender)
{
	//local XGFacility_Labs iLab;
	//local XGFacility_Engineering iItem;
	
	m_kSender = Sender;
	
	LogInternal("This is 1");
	/*if(MutateString == "XGFacility_Labs.Init")
	{
		m_kAltTree = Spawn(class'AltTechTree');
		foreach AllActors(class'XGFacility_Labs', iLab)
		{
			LogInternal("This is Fun");
			iLab.m_kTree = m_kAltTree;
		}
	}
	if(MutateString == "XGFacility_Engineering.Init")
	{
		m_kAltItems = Spawn(class'AltItemTree');
		foreach AllActors(class'XGFacility_Engineering', iItem)
		{
			LogInternal("This is Success");
			iItem.m_kItems = m_kAltItems;
		}
	}*/
	if(MutateString == "CompletedFoundryProject")
	{
		Init();
	}
  	if (Left(MutateString, 10) == "ObjectSort")
	{
		`Log("Mutate: ObjectSort");
		if(Split(MutateString, "_", true) != "")
    	{
    		BuildObjectMods(int(Split(MutateString, "_", true)));
    	}
		else
    	{
    		BuildObjectMods();
    	}
    }
	super.Mutate(MutateString, Sender);
}

function CreateActor()
{
	local bool foundActor;
	local WeaponSortCheckpoint wsc;
	
	foundActor = false;
	// End:0x48
	foreach AllActors(class'WeaponSortCheckpoint', wsc)
	{
		foundActor = true;
		m_kWSCheckpoint = wsc;
		// End:0x48
		break;
    }
    // End:0x83
	if(!foundActor)
	{
		m_kWSCheckpoint = Spawn(class'WeaponSortCheckpoint', m_kSender);
	}
}

function Init()
{
	BuildObjectMods();
	if(m_kWSCheckpoint == none)
	{
		CreateActor();
	}
	m_kWSCheckpoint.CompletedProject();
}

function BuildObjectMods(optional int SoldierID)
{
    local int iObjectMods, iObject;
  	local int bonusValue[11]; 
    local array<int> arrBackPackItems;
    local XGSoldierUI kSoldierUI;
    local XComHQPresentationLayer kPres;
    local XComPlayerController PC;
    local XGParamTag kTag;
  	local XGCharacter kChar;
	local XComGameInfo CurrentGameInfo;
	local XGUnit Unit;
	local bool bHasPerk;
	local int iGroup;
	local int iSort;

	CurrentGameInfo = XComGameInfo(WorldInfo.Game);
	
 	if(XComHeadquartersGame(CurrentGameInfo) != none)
    {
		PC = XComPlayerController(GetALocalPlayerController());
		kPres = XComHQPresentationLayer(PC.m_Pres);
		kSoldierUI = XGSoldierUI(kPres.GetMgr(class'XGSoldierUI',,, true));
    }
    
    kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
    
    if(SoldierID > 0)
    {
		foreach AllActors(class'XGUnit', Unit)
    	{
      		if(XGCharacter_Soldier(Unit.m_kCharacter) != none)
       		{
          		if(XGCharacter_Soldier(Unit.m_kCharacter).m_kSoldier.iID == SoldierID)
            	{
              		kChar = Unit.m_kCharacter;
                  	break;
            	}
        	}
    	}
    }

    TACTICAL().GetBackpackItemArray(kChar.m_kChar.kInventory, arrBackPackItems);
 
    if(m_kWSCheckpoint == none)
    {
      	CreateActor();
    }
	
	for(iObjectMods = 0; iObjectMods < objectMods.length; iObjectMods++)
	{
      	for(iGroup = 0; iGroup < objectGroups.length; iGroup++)
        {
		
			if(kSoldierUI != none)
			{
				bHasPerk = kSoldierUI.m_kSoldier.HasPerk(objectMods[iObjectMods].iPerk);
			}
			else
			{
				if(kChar != none)
				{
					bHasPerk = kChar.HasUpgrade(objectMods[iObjectMods].iPerk);
				}
				else {
					bHasPerk = false;
				}
			}
		
			if((objectMods[iObjectMods].iTech == -1 || m_kWSCheckpoint.iRsrchComplete[objectMods[iObjectMods].iTech] == 1) && (objectMods[iObjectMods].iFTech == -1 || m_kWSCheckpoint.iFndryComplete[objectMods[iObjectMods].iFTech] == 1) && (objectMods[iObjectMods].iPerk == -1 || bHasPerk))
       		{
          		foreach arrBackPackItems(iObject)
            	{
                	if(objectGroups[iGroup].objectGroup ~= objectMods[iObjectMods].objectGroup)
                    {
					
						for(iSort = 0; iSort < objectGroups[iGroup].objSort.length; iSort++)
						{
							if(objectGroups[iGroup].objSort[iSort] == EItemType(iObject))
							{
								bonusValue[0] += objectMods[iObjectMods].iDamageBonus;
								bonusValue[1] += objectMods[iObjectMods].iAimBonus; 
								bonusValue[2] += objectMods[iObjectMods].iCritChanceBonus;
								bonusValue[3] += objectMods[iObjectMods].iCritDmgBonus;
								bonusValue[4] += objectMods[iObjectMods].iAmmoBonus;
								bonusValue[5] += objectMods[iObjectMods].iHPBonus;
								bonusValue[6] += int(objectMods[iObjectMods].fDRBonus * 10);
								bonusValue[7] += objectMods[iObjectMods].iDefenseBonus;
								bonusValue[8] += objectMods[iObjectMods].iWillBonus;
								bonusValue[9] += objectMods[iObjectMods].iRangeBonus;
								bonusValue[10] += objectMods[iObjectMods].iMobilityBonus; 
							}
						}
            		}
                }
            }
        }
		kTag.StrValue2 = string(bonusValue[0]); 
		kTag.StrValue2 $= "_" $ string(bonusValue[1]); 
		kTag.StrValue2 $= "_" $ string(bonusValue[2]); 
		kTag.StrValue2 $= "_" $ string(bonusValue[3]);
		kTag.StrValue2 $= "_" $ string(bonusValue[4]);
		kTag.StrValue2 $= "_" $ string(bonusValue[5]);
		kTag.StrValue2 $= "_" $ string(bonusValue[6]);
		kTag.StrValue2 $= "_" $ string(bonusValue[7]);
		kTag.StrValue2 $= "_" $ string(bonusValue[8]); 
		kTag.StrValue2 $= "_" $ string(bonusValue[9]); 
		kTag.StrValue2 $= "_" $ string(bonusValue[10]); 
    }
}