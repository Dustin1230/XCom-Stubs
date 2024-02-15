class MMAbilitiesBuilder extends Object
	config(AbilityMods);

struct TAbilityStat
{
	var int iAbility;
	var int iValue;
};
var config array<TAbilityStat> AbilityCooldowns;
var config array<TAbilityStat> AbilityDuration;
var config array<TAbilityStat> AbilityRange;
var config array<TAbilityStat> AbilityCategory;
var config array<TAbilityStat> AbilityTargetType;
var config array<TAbilityStat> AddAbilityProperty;
var config array<TAbilityStat> AddAbilityDisplayProperty;
var config array<TAbilityStat> AddAbilityEffect;
var config array<TAbilityStat> RemoveAbilityProperty;
var config array<TAbilityStat> RemoveAbilityDisplayProperty;
var config array<TAbilityStat> RemoveAbilityEffect;

static function ApplyAbilityMods()
{
	ApplyAbilityCooldowns();
	ApplyAbilityDurations();
	ApplyAbilityRanges();
	ApplyAbilityCategories();
	ApplyAbilityTargetTypes();
	RemoveAbilityProperties();
	RemoveAbilityDisplayProperties();
	RemoveAbilityEffects();
	AddAbilityProperties();
	AddAbilityDisplayProperties();
	AddAbilityEffects();
}
static function ApplyAbilityCooldowns()
{
	local TAbilityStat tStat;
	local XGAbilityTree kAbilityTree;

	kAbilityTree = class'MiniModsTactical'.static.GRI().m_kGameCore.m_kAbilities;
	foreach default.AbilityCooldowns(tStat)
	{
		kAbilityTree.m_arrAbilities[tStat.iAbility].iCooldown = tStat.iValue;
	}
}
static function ApplyAbilityDurations()
{
	local TAbilityStat tStat;
	local XGAbilityTree kAbilityTree;

	kAbilityTree = class'MiniModsTactical'.static.GRI().m_kGameCore.m_kAbilities;
	foreach default.AbilityDuration(tStat)
	{
		kAbilityTree.m_arrAbilities[tStat.iAbility].iDuration = tStat.iValue;
	}
}
static function ApplyAbilityRanges()
{
	local TAbilityStat tStat;
	local XGAbilityTree kAbilityTree;

	kAbilityTree = class'MiniModsTactical'.static.GRI().m_kGameCore.m_kAbilities;
	foreach default.AbilityRange(tStat)
	{
		kAbilityTree.m_arrAbilities[tStat.iAbility].iRange = tStat.iValue;
	}
}
static function ApplyAbilityCategories()
{
	local TAbilityStat tStat;
	local XGAbilityTree kAbilityTree;

	kAbilityTree = class'MiniModsTactical'.static.GRI().m_kGameCore.m_kAbilities;
	foreach default.AbilityCategory(tStat)
	{
		kAbilityTree.m_arrAbilities[tStat.iAbility].iCategory = tStat.iValue;
	}
}
static function ApplyAbilityTargetTypes()
{
	local TAbilityStat tStat;
	local XGAbilityTree kAbilityTree;

	kAbilityTree = class'MiniModsTactical'.static.GRI().m_kGameCore.m_kAbilities;
	foreach default.AbilityTargetType(tStat)
	{
		kAbilityTree.m_arrAbilities[tStat.iAbility].iTargetType = tStat.iValue;
	}
}
static function AddAbilityProperties()
{
	local TAbilityStat tStat;
	local XGAbilityTree kAbilityTree;

	kAbilityTree = class'MiniModsTactical'.static.GRI().m_kGameCore.m_kAbilities;
	foreach default.AddAbilityProperty(tStat)
	{
		kAbilityTree.m_arrAbilities[tStat.iAbility].aProperties[tStat.iValue] = 1;
	}
}
static function RemoveAbilityProperties()
{
	local TAbilityStat tStat;
	local XGAbilityTree kAbilityTree;

	kAbilityTree = class'MiniModsTactical'.static.GRI().m_kGameCore.m_kAbilities;
	foreach default.RemoveAbilityProperty(tStat)
	{
		kAbilityTree.m_arrAbilities[tStat.iAbility].aProperties[tStat.iValue] = 0;
	}
}
static function AddAbilityDisplayProperties()
{
	local TAbilityStat tStat;
	local XGAbilityTree kAbilityTree;

	kAbilityTree = class'MiniModsTactical'.static.GRI().m_kGameCore.m_kAbilities;
	foreach default.AddAbilityDisplayProperty(tStat)
	{
		kAbilityTree.m_arrAbilities[tStat.iAbility].aDisplayProperties[tStat.iValue] = 1;
	}
}
static function RemoveAbilityDisplayProperties()
{
	local TAbilityStat tStat;
	local XGAbilityTree kAbilityTree;

	kAbilityTree = class'MiniModsTactical'.static.GRI().m_kGameCore.m_kAbilities;
	foreach default.RemoveAbilityDisplayProperty(tStat)
	{
		kAbilityTree.m_arrAbilities[tStat.iAbility].aDisplayProperties[tStat.iValue] = 0;
	}
}
static function AddAbilityEffects()
{
	local TAbilityStat tStat;
	local XGAbilityTree kAbilityTree;

	kAbilityTree = class'MiniModsTactical'.static.GRI().m_kGameCore.m_kAbilities;
	foreach default.AddAbilityEffect(tStat)
	{
		kAbilityTree.m_arrAbilities[tStat.iAbility].aEffects[tStat.iValue] = 1;
	}
}
static function RemoveAbilityEffects()
{
	local TAbilityStat tStat;
	local XGAbilityTree kAbilityTree;

	kAbilityTree = class'MiniModsTactical'.static.GRI().m_kGameCore.m_kAbilities;
	foreach default.RemoveAbilityEffect(tStat)
	{
		kAbilityTree.m_arrAbilities[tStat.iAbility].aEffects[tStat.iValue] = 0;
	}
}
DefaultProperties
{
}
