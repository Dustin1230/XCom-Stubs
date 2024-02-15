/**The purpose of an instance of this class is to store and process the queue of "to-be-saved-data".
 * This is necessary to take the load off the main loop by putting saving process into a state
 * because ParseString is handy but cumbersome in terms of iterations.*/
class XGSH_QueueHelper extends Actor;

var array<TTableMenuOption> m_arrSaveValueQueue;


event PostBeginPlay()
{
	super.PostBeginPlay();
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(self, 'm_arrSaveValueQueue', self, ProcessSaveQueue);
}
function ProcessSaveQueue()
{
	if(!IsInState('SavingData', true))
	{
		PushState('SavingData');
	}
}
function QueueSaveValue(coerce string sContainerName, coerce string sObject, coerce string sKey, coerce string sValue)
{
	local TTableMenuOption tEntry;

	tEntry.arrStrings.AddItem(sContainerName);
	tEntry.arrStrings.AddItem(sObject);
	tEntry.arrStrings.AddItem(sKey);
	tEntry.arrStrings.AddItem(sValue);
	m_arrSaveValueQueue.AddItem(tEntry);
}
state SavingData
{
	event PushedState()
	{
		//MESSENGER().Message(m_kUnit @ GetFuncName() @ GetStateName());
	}
	event PoppedState()
	{
		//MESSENGER().Message(m_kUnit @ GetFuncName() @ GetStateName());
	}
	function XGRecapSaveData GetContainer(string strID)
	{
		local XGRecapSaveData kContainer;

		foreach DynamicActors(class'XGRecapSaveData', kContainer)
		{
			if(string(kContainer) ~= strID)
			{
				break;
			}
		}
		return kContainer;
	}
Begin:
	while(m_arrSaveValueQueue.Length > 0)
	{
		class'XGSaveHelper'.static.SaveValueString(GetContainer(m_arrSaveValueQueue[0].arrStrings[0]), m_arrSaveValueQueue[0].arrStrings[1], m_arrSaveValueQueue[0].arrStrings[2], m_arrSaveValueQueue[0].arrStrings[3]);
		m_arrSaveValueQueue.Remove(0, 1);
		Sleep(0.01);
	}
	PopState();
}

DefaultProperties
{
	bAlwaysTick=true
}