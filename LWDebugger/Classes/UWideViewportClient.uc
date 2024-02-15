class UWideViewportClient extends XComGameViewportClient;

var float m_fTimeToLog;

event Tick(float DeltaTime)
{
	m_fTimeToLog +=DeltaTime;
	if(m_fTimeToLog > 2.0)
	{
		`log("hello");
		PollForHUD();
		m_fTimeToLog = 0.0f;
	}
}

function PollForHUD()
{
    local XComTacticalHUD kHUD;

	if(XComTacticalGRI(Class'Engine'.static.GetCurrentWorldInfo().GRI) != none && XComTacticalGRI(Class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle != none)
	{
 
		kHUD = XComTacticalHUD(XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).myHUD);
		`log("error: no hud", kHUD == none, GetFuncName());
		`log("mouseWorldDirection.x" @ kHUD.CachedMouseWorldDirection.X @ "mouseWorldDirection.y" @ kHud.CachedMouseWorldDirection.Y @ "cameraWorldDirection.x" @ kHUD.CachedCameraWorldDirection.X @ "cameraWorldDirectio.y" @ kHUD.CachedCameraWorldDirection.Y , kHUD != none, GetFuncName());
		kHUD.ViewSize.X = 1280;
	}
}
event SetProgressMessage(EProgressMessageType MessageType, string Message, optional string Title, optional bool bIgnoreFutureNetworkMessages)
{
	`log(GetFuncName(),,class.name);
	super.SetProgressMessage(MessageType, Message, Title, bIgnoreFutureNetworkMessages);
}
DefaultProperties
{
}
