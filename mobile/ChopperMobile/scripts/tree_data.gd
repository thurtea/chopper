class_name TreeData
extends Resource

## One tree in the chopping queue: current target or an upcoming preview.

enum Element { NONE, FIRE, ICE, BOLT, EARTH, WIND }

@export var health: int = 100
@export var max_health: int = 100
@export var element: Element = Element.NONE
@export var chop_reward: int = 10
@export var tree_level: int = 1
@export var difficulty: int = 1
@export var is_boss: bool = false
@export var is_enchanted: bool = false


static func make(level: int, element_type: Element, stars: int) -> TreeData:
	var tree := TreeData.new()
	tree.tree_level = maxi(level, 1)
	tree.element = element_type
	tree.difficulty = clampi(stars, 1, 3)
	tree.max_health = UpgradeConfig.tree_max_health(tree.tree_level, tree.difficulty)
	tree.health = tree.max_health
	tree.chop_reward = UpgradeConfig.tree_chop_reward(tree.tree_level, tree.difficulty)
	return tree


func take_damage(amount: int) -> int:
	var applied := clampi(amount, 0, health)
	health = maxi(health - amount, 0)
	return applied


func is_fallen() -> bool:
	return health <= 0


func health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return float(health) / float(max_health)


static func color_for(element_type: Element) -> Color:
	match element_type:
		Element.FIRE:
			return Color(0.86, 0.32, 0.22)
		Element.ICE:
			return Color(0.35, 0.62, 0.92)
		Element.BOLT:
			return Color(0.95, 0.82, 0.12)
		Element.EARTH:
			return Color(0.55, 0.4, 0.24)
		Element.WIND:
			return Color(0.22, 0.78, 0.55)
		_:
			return Color(0.34, 0.55, 0.28)


static func display_name(element_type: Element) -> String:
	match element_type:
		Element.FIRE:
			return "Fire"
		Element.ICE:
			return "Ice"
		Element.BOLT:
			return "Bolt"
		Element.EARTH:
			return "Earth"
		Element.WIND:
			return "Wind"
		_:
			return "None"


## Five-element wheel for Element Power bonuses (Prompt 2.2/3.2): Fire beats
## Ice, Ice beats Bolt, Bolt beats Earth, Earth beats Wind, Wind beats Fire.
## A closed loop so every element has exactly one favourable and one
## unfavourable matchup against a different element. NONE on either side is
## always neutral. Corrected for Prompt 3.2, whose own design-doc wording
## ("Matching element = bonus damage. Opposing element = reduced damage.
## Neutral = normal damage.") makes explicit what Prompt 2.2's own version
## of this function got wrong: attacking with the same element the tree
## has is "Matching" (a bonus), not neutral. "Neutral" is reserved for
## NONE on either side, or two different, non-opposing elements.
static func elemental_multiplier(attack: Element, defend: Element) -> float:
	if attack == Element.NONE or defend == Element.NONE:
		return 1.0
	if attack == defend:
		return UpgradeConfig.ELEMENT_MATCH_MULTIPLIER
	var beats := {
		Element.FIRE: Element.ICE,
		Element.ICE: Element.BOLT,
		Element.BOLT: Element.EARTH,
		Element.EARTH: Element.WIND,
		Element.WIND: Element.FIRE,
	}
	if beats.get(attack) == defend:
		return UpgradeConfig.ELEMENT_MATCH_MULTIPLIER
	if beats.get(defend) == attack:
		return UpgradeConfig.ELEMENT_RESIST_MULTIPLIER
	return 1.0
