class SU_SoundMgr extends XGStrategyActor;

var array<SoundCue> m_arrSoundsToPlay;

event PostBeginPlay()
{
	m_arrSoundsToPlay.Length = 0;//just an init to avoid Accessed None
	if(SquadronUnleashed(Owner).PilotVoiceSet.Length == 0 || SquadronUnleashed(Owner).PilotVoiceSet.Find("Default") < 0)
	{
		SquadronUnleashed(Owner).PilotVoiceSet.InsertItem(0, "Default");
	}
}
function QueueSound(SoundCue kCue, optional bool bInsert)
{
	if(bInsert && m_arrSoundsToPlay.Length > 2)
	{
		m_arrSoundsToPlay.InsertItem(1, kCue);//ensures not being cut off
	}
	else
	{
		m_arrSoundsToPlay.AddItem(kCue);
	}
}
event Tick(float fDeltaTime)
{
	ProcessQueue();
}
function ProcessQueue()
{
	if(!IsTimerActive())
	{
		Timer();
	}
}
function Timer()
{
	local float fNextCueTimer;

	if(m_arrSoundsToPlay.Length > 0)
	{
		if(PRES().m_kInterceptionEngagement != none && PRES().m_kInterceptionEngagement.m_bViewingResults)
		{
			SetTimer(2.0,false, 'ClearQueue');
		}
		else
		{
			if(m_arrSoundsToPlay.Length > 2)
			{
				m_arrSoundsToPlay.Length = 2;//trim too long queue
			}
			if(m_arrSoundsToPlay[0] != none)
			{
				fNextCueTimer = Min(1.5, m_arrSoundsToPlay[0].GetCueDuration());
				PlaySound(m_arrSoundsToPlay[0]);
				SetTimer(fNextCueTimer);
			}
			m_arrSoundsToPlay.Remove(0, 1);
		}
	}
}
function ClearQueue()
{
	m_arrSoundsToPlay.Length = 0;
}
DefaultProperties
{
}
