class szUITutorialMutator extends XComMutator;

event PostBeginPlay()
{
	LogInternal(GetFuncName() @ "Hello world");
	RegisterWatchVars();
}

function RegisterWatchVars()
{
	LogInternal(GetFuncName() @ "1. Hello world");
	if(WorldInfo.MyWatchVariableMgr == none || PRES() == none)
	{
		SetTimer(1.0, false, GetFuncName());
		return;
	}
	LogInternal(GetFuncName() @ "2. Hello world");
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(PRES(), 'm_kItemCard', self, OnItemCardUp);

}
function XComHQPresentationLayer PRES()
{
	return XComHQPresentationLayer(XComPlayerController(WorldInfo.GetALocalPlayerController()).m_Pres);
}
function OnItemCardUp()
{
	if(PRES().m_kItemCard == none)
		return;
	else
	{
		LogInternal(GetFuncName() @ "Hello world");
		SetTimer(0.20, false, 'AdjustItemCardX');
	}
}
function AdjustItemCardX()
{
	local GFxObject gfxCard;
	local float fX, fY;

	LogInternal(GetFuncName() @ "Hello world");
	gfxCard = PRES().GetHUD().GetVariableObject(string(PRES().m_kItemCard.GetMCPath()));
	fX = gfxCard.GetFloat("_x");
	fY = gfxCard.GetFloat("_y");
	fX = fX + 300.0; //move the card by 300 pixels to the right (vs the original spawning location which is probably centered)
	gfxCard.SetFloat("_x", fX); //set the new value back to "_x"
	//let's move the image
	//the path is theScreen.theItemCard.image
	fY = gfxCard.GetObject("theItemCard").GetObject("image").GetFloat("_y"); //_y is shift relative to the ItemCard panel, not relative to screen!!!
	gfxCard.GetObject("theItemCard").GetObject("image").SetFloat("_y", fY -100.0); //this will probably move the image outside the card and make it invisible? let's see!
}
DefaultProperties
{
}
