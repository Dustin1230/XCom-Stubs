class GiantMiniModsTactical extends LWR_MiniModsTactical;

function PostLevelLoaded(PlayerController Sender)
{
  super(MiniModsTactical).PostLevelLoaded(Sender);
}
function PostLoadSaveGame(PlayerController Sender)
{
  super(MiniModsTactical).PostLoadSaveGame(Sender);
}

DefaultProperties
{
}
