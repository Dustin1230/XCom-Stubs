class SeqAct_ActivateNarrative extends SequenceAction
    hidecategories(Object)
    native(Level)
    forcescriptorder(true);

var() XComNarrativeMoment NarrMoment;
var Actor TargetActor;
var XGUnit UnitInstigator;

event Activated(){}
function OnNarrativeComplete(){}

defaultproperties
{
    bCallHandler=false
    bLatentExecution=true
    bAutoActivateOutputLinks=false
    OutputLinks(0)=(LinkDesc="Out")
    OutputLinks(1)=(LinkDesc="Completed")
    VariableLinks(0)=(ExpectedType=Class'Engine.SeqVar_Object',LinkDesc="Target Actor",PropertyName=TargetActor)
    VariableLinks(1)=(ExpectedType=Class'Engine.SeqVar_Object',LinkDesc="Unit Instigator",PropertyName=UnitInstigator)
    ObjName="Activate Narrative"
}
