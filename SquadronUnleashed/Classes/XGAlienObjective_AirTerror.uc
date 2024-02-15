class XGAlienObjective_AirTerror extends XGAlienObjective;

function CustomInit()
{
	m_kTObjective.eType = eObjective_Recon;
	//add ufo
}
function Init(TObjective kObj, int iStartDate, Vector2D v2Target, int iCountry, optional int iCity, optional EShipType eShip)
{
	local int iShip, iDate;

	m_kTObjective = kObj;
	m_iCountryTarget = iCountry;
	m_iCityTarget = iCity;
	m_v2Target = v2Target;
	if((ISCONTROLLED()) && m_kTObjective.eType == 0)
	{
		m_kTObjective.arrStartDates[0] = 14;
		m_kTObjective.arrRandDays[0] = 0;
	}
	if(eShip != 0)
	{
		for(iShip = 0; iShip < m_kTObjective.arrUFOs.Length; ++iShip)
		{
			m_kTObjective.arrUFOs[iShip] = eShip;
		}
	}
	for(iDate = 0; iDate < m_kTObjective.arrStartDates.Length; ++iDate)
	{
		m_kTObjective.arrStartDates[iDate] += iStartDate;
	}
	m_iNextMissionTimer = ConvertDaysToTimeslices(m_kTObjective.arrStartDates[0], m_kTObjective.arrRandDays[0]);
}
function LaunchNextMission()
{
	local array<int> arrFlightPlan;
	local float fDuration;
	local XGShip_UFO kUFO;

	arrFlightPlan = GetFlightPlan(m_kTObjective.arrMissions[0], fDuration);
	kUFO = LaunchUFO(m_kTObjective.arrUFOs[0], arrFlightPlan, DetermineMissionTarget(m_kTObjective.arrRadii[0]), fDuration);
	m_iSightings += 1;
	Continent(GetContinent()).m_kMonthly.iUFOsSeen += 1;
	PopFrontMission();
	SetNextMissionTimer();
	if(m_iNextMissionTimer == -1)
	{
		m_kLastUFO = kUFO;
	}
	if(m_kTObjective.eType == 4)
	{
		HQ().m_arrSatellites[HQ().GetSatellite(ECountry(m_iCountryTarget))].kSatEntity.SetHidden(false);
	}
}
function XGShip_UFO LaunchUFO(EShipType eShip, array<int> arrFlightPlan, Vector2D v2Target, float fDuration)
{
    local XGShip_UFO kUFO;

    if((eShip == 9) && m_kTObjective.eType == 3)
    {
        v2Target = m_v2Target;
    }
    if((eShip < 4) || eShip > 14)
    {
        switch(m_kTObjective.eType)
        {
            case 0:
            case 1:
            case 2:
            case 4:
            case 8:
                STAT_SetStat(103, m_kTObjective.eType);
                eShip = EShipType(AI().GetNumOutsiders());
                break;
            case 3:
            case 7:
                eShip = 9;
                break;
            case 5:
                eShip = 6;
                break;
            case 6:
            case 9:
                eShip = 14;
                break;
            default:
                eShip = 4;
                break;
            }
    }
    kUFO = Spawn(class'XGShip_UFO');
    kUFO.Init(ITEMTREE().GetShip(eShip));
    kUFO.SetObjective(self);
    kUFO.SetFlightPlan(arrFlightPlan, v2Target, ECountry(m_iCountryTarget), fDuration);
    AI().AIAddNewUFO(kUFO);
    return kUFO;
}
function array<int> GetFlightPlan(EUFOMission eMission, out float fDuration)
{
	local array<int> arrFlightPlan;

	arrFlightPlan.AddItem(0);
	arrFlightPlan.AddItem(1);
	fDuration = 24.0;
	return arrFlightPlan;
}
DefaultProperties
{
}
