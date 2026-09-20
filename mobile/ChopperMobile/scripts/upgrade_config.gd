class_name UpgradeConfig
extends RefCounted

## Prompt 3.1: every tunable cost/value for the four core upgrades lives
## here, in one place, per the design doc's own "All upgrade costs and
## values must live in one easy-to-tune dictionary or resource" rule.
## Pure constants and pure derivation functions only: nothing here reads
## or writes game state. GameState calls these when a purchase happens.

# --- Better Axe: permanent, scaling-cost damage upgrade ---
const BETTER_AXE_BASE_COST: int = 10
const BETTER_AXE_COST_GROWTH: float = 1.15
const BETTER_AXE_BASE_DAMAGE: int = 1
const BETTER_AXE_DAMAGE_PER_LEVEL: int = 1

# --- Auto Chopper: permanent, scaling-cost passive Chops/sec upgrade ---
const AUTO_CHOPPER_BASE_COST: int = 100
const AUTO_CHOPPER_COST_GROWTH: float = 1.2
const AUTO_CHOPPER_RATE_PER_LEVEL: float = 0.5

# --- Element Power: flat-cost, repeatable temporary buff ---
# Not a scaling-cost permanent level like the two above: this buys a
# limited-use buff (see ELEMENT_POWER_TREES), so a rising cost would
# punish exactly the repeated tactical use the design doc asks for
# ("a temporary buff you can buy or earn").
const ELEMENT_POWER_COST: int = 50
const ELEMENT_POWER_TREES: int = 3

# --- Prestige Reset: unlocks at a Chop threshold, grants a permanent multiplier ---
const PRESTIGE_CHOP_THRESHOLD: int = 1000
const PRESTIGE_MULTIPLIER_PER_LEVEL: float = 0.1


static func better_axe_cost(level: int) -> int:
	return int(round(BETTER_AXE_BASE_COST * pow(BETTER_AXE_COST_GROWTH, level)))


static func auto_chopper_cost(level: int) -> int:
	return int(round(AUTO_CHOPPER_BASE_COST * pow(AUTO_CHOPPER_COST_GROWTH, level)))


static func axe_damage_for_level(level: int) -> int:
	return BETTER_AXE_BASE_DAMAGE + level * BETTER_AXE_DAMAGE_PER_LEVEL


static func auto_chop_rate_for_level(level: int) -> float:
	return level * AUTO_CHOPPER_RATE_PER_LEVEL


static func prestige_multiplier_for_level(level: int) -> float:
	return 1.0 + level * PRESTIGE_MULTIPLIER_PER_LEVEL
