class SU_UFOSquadron extends XGEntity
	dependson(XGShip_UFO)
	config(SquadronUnleashed);
	//extending XGEntity subscribes this class to ActorClassesToRecord;

struct TUFOEscort
{
	var int iType;
	var int iHP;
	var int iStance;
	
	structdefaultproperties
	{
		iStance=1
	}
};
struct TEscortOption
{
	var int iUFOType;
	var int iReqResearch;
	var int iReqResourceLvl;
};
struct CheckpointRecord_SU_UFOSquadron extends CheckpointRecord
{
	var array<TUFOEscort> m_arrEscort;
};

var array<TUFOEscort> m_arrEscort;
var config array<TEscortOption> PossibleEscort;
var config array<TItem> EscortReward;
var config bool RANDOMIZE_NUMBER_OF_ESCORTS;
var config bool RANDOMIZE_TYPE_OF_ESCORTS;
var config bool RANDOMIZE_STANCE_OF_ESCORTS;
var config bool ENABLE_ESCORT_REWARDS;
var config bool DISABLE_UFO_ESCORTS;

function Init(EEntityGraphic eGraphic)
{	
	m_arrEscort.Add(1);
	m_arrEscort.Remove(m_arrEscort.Length-1, 1);	//just initialization of an array
	//FIXME:test debug phase
	//m_arrEscort.Add(2);
	//m_arrEscort[0].iType = 5;
	//m_arrEscort[0].iHP = class'SU_Utils'.static.GEOSCAPE().ITEMTREE().GetShip(eShip_UFOLargeScout).iHP / 2;
	//m_arrEscort[0].iStance = 1;//AGG
	//m_arrEscort[1].iType = 4;
	//m_arrEscort[1].iHP = class'SU_Utils'.static.GEOSCAPE().ITEMTREE().GetShip(eShip_UFOSmallScout).iHP;
	//m_arrEscort[1].iStance = 1;//AGG
}
function SetMotherShip(XGShip_UFO kUFO, optional bool bDetermineEscort=true)
{
	AssignGameActor(kUFO, int(GetRightMost(kUFO)));
	if(bDetermineEscort)
	{
		DetermineNewEscort();
	}
	SetTickIsDisabled(false);
}
function XGShip_UFO GetMotherShip()
{
	return XGShip_UFO(m_kGameActor);
}
function int GetNumEscorts()
{
	return m_arrEscort.Length;
}
event Tick(float fDeltaTime)
{
	if(GetMotherShip() == none)
	{
		SeekAndDestroyEscortActors();
		Destroy();
	}
	super.Tick(fDeltaTime);
}
function int GetNumShips()
{
	return GetNumEscorts() + 1;
}
function RecordEscortKilled(int idx)
{
	local int iReward;
	local TMCNotice kNotice;
	local XGParamTag kTag;

	kTag = XGParamTag(XComEngine(class'Engine'.static.GetEngine()).LocalizeContext.FindTag("XGParam"));
	if(m_arrEscort[idx].iHP != 0)
	{
		m_arrEscort[idx].iHP = 0;
		if(ENABLE_ESCORT_REWARDS)
		{
			iReward = EscortReward.Find('iCategory', class'SU_Utils'.static.GetUFOHullSize(m_arrEscort[idx].iType));
			if(iReward != -1)
			{

				kNotice.fTimer = 30.0;
				kNotice.txtNotice.iState = eUIState_Highlight;
				kTag.StrValue0 = class'XGItemTree'.default.ShipTypeNames[m_arrEscort[idx].iType];
				kNotice.txtNotice.StrValue = class'UIUtilities'.static.GetHTMLColoredText(Split(class'XComLocalizer'.static.ExpandString(class'UIInterceptionEngagement'.default.m_strReport_ShotDown), "<Bullet/> ", true), eUIState_Highlight);
				kNotice.txtNotice.StrValue = kNotice.txtNotice.StrValue;
				if(EscortReward[iReward].iCash > 0)
				{
					GetMotherShip().AddResource(eResource_Money, EscortReward[iReward].iCash);
					kNotice.txtNotice.StrValue @= class'UIUtilities'.static.GetHTMLColoredText("+" $ class'XGScreenMgr'.static.ConvertCashToString(EscortReward[iReward].iCash), eUIState_Highlight);
				}
				if(EscortReward[iReward].iAlloy > 0)
				{
					GetMotherShip().AddResource(eResource_Alloys, EscortReward[iReward].iAlloy);
					kNotice.txtNotice.StrValue @= class'UIUtilities'.static.GetHTMLColoredText("+" $ EscortReward[iReward].iAlloy @ class'XGScreenMgr'.default.m_aResourceTypeNames[eResource_Alloys], eUIState_Highlight);
				}
				if(EscortReward[iReward].iElerium > 0)
				{
					GetMotherShip().AddResource(eResource_Elerium, EscortReward[iReward].iElerium);
					kNotice.txtNotice.StrValue @= class'UIUtilities'.static.GetHTMLColoredText("+" $ EscortReward[iReward].iElerium @ class'XGScreenMgr'.default.m_aResourceTypeNames[eResource_Elerium], eUIState_Highlight);
				}
				if(class'SU_Utils'.static.PRES().m_kUIMissionControl != none)
				{
					class'SU_Utils'.static.PRES().m_kUIMissionControl.GetMgr().m_arrNotices.AddItem(kNotice);
					class'SU_Utils'.static.PRES().m_kUIMissionControl.UpdateNotices();
				}
			}
		}
	}
}
function CleanUpEscortList()
{
	local int i;

	for(i=m_arrEscort.Length-1; i >=0; --i)
	{
		if(m_arrEscort[i].iHP <= 0)
		{
			`log("m_arrEscort["$i$"].iHP="$m_arrEscort[i].iHP@"- removed from the escort list",class'SU_Utils'.static.GetSquadronMod().bVerboseLog, GetFuncName());
			m_arrEscort.Remove(i, 1);
		}
	}
}
function DetermineNewEscort()
{
	local XGShip_UFO kLead;
	local XGFacility_Hangar kHangar;
	local int i, iNumJets, iNumEscort, iType, iResources, iResearch, iThreat, iRand, iMax;
	local array<int> arrRandomizer, arrPossibleTypes;

	kLead = GetMotherShip();
	if(DISABLE_UFO_ESCORTS)
	{
		m_arrEscort.Length=0;
	}
	else if(kLead != none)
	{
		m_arrEscort.Length = 0;
		kHangar = class'SU_Utils'.static.HANGAR();
		for(i=0; i < kHangar.m_arrInts.Length; ++i)
		{
			if(kHangar.m_arrInts[i].m_iHomeContinent == kLead.GetContinent())
			{
				++iNumJets;
			}
		}
		iResources = class'SU_Utils'.static.AlienResourceLvl();
		iResearch = class'SU_Utils'.static.AlienResearch();
		iThreat = class'SU_Utils'.static.XComThreat();
		iNumEscort = Max(0, iThreat + iNumJets - 5);
		if(RANDOMIZE_NUMBER_OF_ESCORTS)
		{
			if(iNumEscort > 0)
			{
				iNumEscort = 1 + Rand(iNumEscort-1);
			}
		}
		iNumEscort = Min(3, iNumEscort);
		iType = -1;
		for(i=0; i < PossibleEscort.Length; i++)
		{
			if(iResources >= PossibleEscort[i].iReqResourceLvl && iResearch > PossibleEscort[i].iReqResearch)
			{
				if(class'SU_Utils'.static.GetUFOHullSize(kLead.GetType()) < class'SU_Utils'.static.GetUFOHullSize(PossibleEscort[i].iUFOType))
				{
					continue;
				}
				if(RANDOMIZE_TYPE_OF_ESCORTS)
				{
					arrPossibleTypes.AddItem(PossibleEscort[i].iUFOType);
					arrRandomizer.AddItem(Max(0, 360 + PossibleEscort[i].iReqResearch - iResearch));
					iMax += arrRandomizer[arrRandomizer.Length-1];
				}
				else
				{
					iType = PossibleEscort[i].iUFOType;
				}
			}
		}
		if(iNumEscort > 0 && (iType > 0 || arrPossibleTypes.Length > 0) )
		{
			m_arrEscort.Add(iNumEscort);
			for(i=0; i < iNumEscort; ++i)
			{
				if(RANDOMIZE_TYPE_OF_ESCORTS)
				{
					iRand = 1 + Rand(iMax);
					for(iType=0; iType < arrRandomizer.Length; ++iType)
					{
						iRand -= arrRandomizer[iType];
						if(iRand <= 0)
						{
							break;
						}
					}
					class'UIUtilities'.static.ClampIndexToArrayRange(arrPossibleTypes.Length, iType);
					iType = arrPossibleTypes[iType];
				}
				m_arrEscort[i].iType = iType;
				m_arrEscort[i].iHP = kLead.ITEMTREE().GetShip(EShipType(iType)).iHP;
				m_arrEscort[i].iStance = (RANDOMIZE_STANCE_OF_ESCORTS ? Rand(3) : 1);
			}
		}
	}
}
function SeekAndDestroyEscortActors()
{
	local XGShip_UFO kUFO;

	foreach DynamicActors(class'XGShip_UFO', kUFO)
	{
		if(kUFO.m_kEntity.m_iData == m_iData)//destroy the escorting UFOs
		{
			kUFO.Destroy();
		}
	}
}
DefaultProperties
{
	bTickIsDisabled=true
}
