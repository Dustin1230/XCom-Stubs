class UIModMenuDepthHelper extends Object;

var array<string> m_arrDepthIndexes;

function IncreaseDepth(string strIndex)
{
	m_arrDepthIndexes.AddItem(strIndex);
}
function DecreaseDepth()
{
	m_arrDepthIndexes.Length = m_arrDepthIndexes.Length - 1;
}
function ResetDepth()
{
	m_arrDepthIndexes.Length = 0;
}
function string GetCurrentDepthIndex()
{
	if(m_arrDepthIndexes.Length > 0)
	{
		return m_arrDepthIndexes[m_arrDepthIndexes.Length -1];
	}
	else
	{
		return "";
	}
}
function UpdateCurrentDepthIndex(string strIndex)
{
	if(m_arrDepthIndexes.Length == 0)
	{
		IncreaseDepth(strIndex);
	}
	else
	{
		m_arrDepthIndexes[m_arrDepthIndexes.Length - 1] = strIndex;
	}
}
defaultproperties
{
}
