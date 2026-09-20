class_name EnchantmentData
extends Resource

## A temporary buff granted after a tree falls. How often one is granted
## and each kind's own magnitude/duration are tunable constants on
## UpgradeConfig (Prompt 5.2 centralized them there, alongside every
## other progression number); GameState and the static constructors
## below read them from there rather than duplicating them here.

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
	enchantment.remaining_trees = UpgradeConfig.EMPOWERED_TREES
	enchantment.magnitude = UpgradeConfig.EMPOWERED_MULTIPLIER
	enchantment.description = "Next %d trees take +%d%% damage" % [
		UpgradeConfig.EMPOWERED_TREES, int(round((UpgradeConfig.EMPOWERED_MULTIPLIER - 1.0) * 100)),
	]
	return enchantment


static func elemental_surge(element: TreeData.Element) -> EnchantmentData:
	var enchantment := EnchantmentData.new()
	enchantment.kind = Kind.ELEMENTAL_SURGE
	enchantment.remaining_trees = UpgradeConfig.ELEMENT_POWER_TREES
	enchantment.magnitude = float(element)
	enchantment.description = "Free %s Element Power" % TreeData.display_name(element)
	return enchantment


static func gold_rush() -> EnchantmentData:
	var enchantment := EnchantmentData.new()
	enchantment.kind = Kind.GOLD_RUSH
	enchantment.remaining_trees = UpgradeConfig.GOLD_RUSH_TREES
	enchantment.magnitude = UpgradeConfig.GOLD_RUSH_MULTIPLIER
	enchantment.description = "Next tree gives %g× Chops" % UpgradeConfig.GOLD_RUSH_MULTIPLIER
	return enchantment


static func auto_boost() -> EnchantmentData:
	var enchantment := EnchantmentData.new()
	enchantment.kind = Kind.AUTO_BOOST
	enchantment.remaining_seconds = UpgradeConfig.AUTO_BOOST_SECONDS
	enchantment.magnitude = UpgradeConfig.AUTO_BOOST_MULTIPLIER
	enchantment.description = "Auto Chopper is %d%% faster for %d seconds" % [
		int(round((UpgradeConfig.AUTO_BOOST_MULTIPLIER - 1.0) * 100)), int(UpgradeConfig.AUTO_BOOST_SECONDS),
	]
	return enchantment
