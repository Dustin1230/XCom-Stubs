/** UFOAlert is the screen being shown when UFO Mission appears on the Geoscape for the first time.
 *  As soon as button "Launch Interceptors" is pressed it gets replaced by UFORadarContactAlert instead.
 */

//DEPRECATED (sort of)
class SU_UFOAlert extends UIMissionControl_UFOAlert
	 hidecategories(Navigation);

var XGShip_UFO m_kUFO;

simulated function UpdateData()
{
    local int I, colorState;
    local TMCAlert kAlert;
    local array<string> speciesList;
    local string formattedSpecies1, formattedSpecies2;

	if(m_kUFO.m_iStatus == 0)
	{
		class'SU_Utils'.static.DetermineUFOStance(m_kUFO);
		m_kUFO.m_iStatus = 1;//mark as already set the stance
	}
    kAlert = GetMgr().m_kCurrentAlert;
    colorState = ((XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGameCore().GetHQ().IsHyperwaveActive()) ? 10 : 13);
    AS_SetTitle(class'UIUtilities'.static.GetHTMLColoredText(Caps(kAlert.txtTitle.StrValue), colorState));
    AS_SetContact(class'UIUtilities'.static.GetHTMLColoredText(Caps(kAlert.arrLabeledText[0].strLabel), colorState), kAlert.arrLabeledText[0].StrValue);
    AS_SetLocation(class'UIUtilities'.static.GetHTMLColoredText(Caps(kAlert.arrLabeledText[1].strLabel), colorState), kAlert.arrLabeledText[1].StrValue);
    AS_SetClass(class'UIUtilities'.static.GetHTMLColoredText(Caps(kAlert.arrLabeledText[2].strLabel), colorState), kAlert.arrLabeledText[2].StrValue);
    if(colorState == 10)
    {
        ParseStringIntoArray(kAlert.arrLabeledText[5].StrValue, speciesList, "//", true);
        while(I < speciesList.Length)
        {
           if(I < 6)
            {
                formattedSpecies1 $= speciesList[++I];
                if((I < 6) && I < speciesList.Length)
                {
                    formattedSpecies1 $= "\\n";
                }
            }
            else
            {
                formattedSpecies2 $= speciesList[++I];
                if(I < speciesList.Length)
                {
                    formattedSpecies2 $= "\\n";
                }
            }
        }
        AS_SetHyperwaveData(m_strHyperwavePanelTitle, Caps(kAlert.arrLabeledText[3].strLabel), kAlert.arrLabeledText[3].StrValue, Caps(kAlert.arrLabeledText[4].strLabel), kAlert.arrLabeledText[4].StrValue $ (" (" $ (string(I) $ " species) ")), Caps(kAlert.arrLabeledText[5].strLabel), formattedSpecies1, formattedSpecies2);
    }
    UpdateButtonText();
}

defaultproperties
{
    s_alertName="OVERRIDE IN CHILDREN"
    m_bShowBackButtonOnMissionControl=true
}


