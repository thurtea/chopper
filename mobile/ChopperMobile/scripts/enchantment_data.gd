class_name EnchantmentData
extends Resource

## A temporary buff granted after a tree falls.

## Prompt 3.3's own tunable values for how often an enchantment is
## granted: a flat per-kill chance, plus a guaranteed grant every Nth
## kill so a long unlucky streak is never possible. GameState reads these
## directly rather than duplicating them.
const GRANT_CHANCE: float = 0.18
const MILESTONE_INTERVAL: int = 10

enum Kind { EMPOWERED, ELEMENTAL_SURGE, GOLD_RUSH, AUTO_BOOST }

@export var kind: Kind = Kind.EMPOWERED
@export var remaining_trees: int = 0
@export var remaining_seconds: float = 0.0
@export var description: String = ""
@export var magnitude: float = 1.0


func is_expired() -> bool:
	return remaining_trees <= 0 and remaining_seconds <= 0.0


static func empowered() -> EnchantmentData:
	var enchantment := EnchantmentData.new()
	enchantment.kind = Kind.EMPOWERED
	enchantment.remaining_trees = 5
	enchantment.magnitude = 1.4
	enchantment.description = "Next 5 trees take +40% damage"
	return enchantment


static func elemental_surge(element: TreeData.Element) -> EnchantmentData:
	var enchantment := EnchantmentData.new()
	enchantment.kind = Kind.ELEMENTAL_SURGE
	enchantment.remaining_trees = 3
	enchantment.magnitude = float(element)
	enchantment.description = "Free %s Element Power" % TreeData.display_name(element)
	return enchantment


static func gold_rush() -> EnchantmentData:
	var enchantment := EnchantmentData.new()
	enchantment.kind = Kind.GOLD_RUSH
	enchantment.remaining_trees = 1
	enchantment.magnitude = 3.0
	enchantment.description = "Next tree gives 3× Chops"
	return enchantment


static func auto_boost() -> EnchantmentData:
	var enchantment := EnchantmentData.new()
	enchantment.kind = Kind.AUTO_BOOST
	enchantment.remaining_seconds = 20.0
	enchantment.magnitude = 1.5
	enchantment.description = "Auto Chopper is 50% faster for 20 seconds"
	return enchantment
