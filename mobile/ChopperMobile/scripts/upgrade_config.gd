class_name UpgradeConfig
extends RefCounted

## Prompt 3.1: every tunable cost/value for the four core upgrades lives
## here, in one place, per the design doc's own "All upgrade costs and
## values must live in one easy-to-tune dictionary or resource" rule.
## Prompt 5.2 extends that same rule to the rest of the progression curve
## (tree health/reward scaling, elemental multipliers, and enchantment
## chances/magnitudes), which used to be hardcoded across TreeData and
## EnchantmentData. Pure constants and pure derivation functions only:
## nothing here reads or writes game state. GameState calls these when a
## purchase happens, and TreeData/EnchantmentData call these to build
## themselves.

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

# --- Elemental wheel: bonus/penalty when Element Power's active element
# matches/opposes the tree's own element (TreeData.elemental_multiplier).
const ELEMENT_MATCH_MULTIPLIER: float = 1.5
const ELEMENT_RESIST_MULTIPLIER: float = 0.65

# --- Tree scaling: max health and Chop reward per tree, both a flat base
# plus a per-(level*difficulty) term. Prompt 5.2 tuning note: the base
# terms are deliberately small relative to the per-level terms (unlike
# the flat 80-health / 0-reward-base Prompt 2.x shipped with) so early
# trees die in a handful of taps instead of ~50-70 seconds of tapping
# before the very first Better Axe purchase is even reachable.
const TREE_HEALTH_BASE: int = 6
const TREE_HEALTH_PER_LEVEL: int = 5
const TREE_REWARD_BASE: int = 2
const TREE_REWARD_PER_LEVEL: float = 2.5

# --- Prestige Reset: unlocks at a (per-cycle-growing) Chop threshold,
# grants a permanent multiplier to all chop damage and Chop rewards.
# Prompt 5.2 tuning note: the multiplier applies to both damage and
# reward, so raw Chops/sec after a reset scales roughly with the square
# of the multiplier until upgrades catch back up. PRESTIGE_THRESHOLD_GROWTH
# exists specifically to counteract that so later cycles do not get
# dramatically shorter than earlier ones (simulated: ~6.5-9 real minutes
# per cycle across the first 8 prestiges with these constants, instead of
# collapsing toward instant re-prestiges).
const PRESTIGE_BASE_THRESHOLD: int = 1000
const PRESTIGE_THRESHOLD_GROWTH: float = 1.3
const PRESTIGE_MULTIPLIER_PER_LEVEL: float = 0.18

# --- Enchantments: how often one is granted after a kill, and each kind's
# own magnitude/duration. Moved here from EnchantmentData so every number
# that shapes pacing lives in one file, per the design doc's Prompt 5.2
# instruction to expose damage scaling, cost scaling, enchantment chances,
# and elemental multipliers "in one place."
const ENCHANTMENT_GRANT_CHANCE: float = 0.18
const ENCHANTMENT_MILESTONE_INTERVAL: int = 10
const EMPOWERED_TREES: int = 5
const EMPOWERED_MULTIPLIER: float = 1.4
const GOLD_RUSH_TREES: int = 1
const GOLD_RUSH_MULTIPLIER: float = 3.0
const AUTO_BOOST_SECONDS: float = 20.0
const AUTO_BOOST_MULTIPLIER: float = 1.5


static func better_axe_cost(level: int) -> int:
	return int(round(BETTER_AXE_BASE_COST * pow(BETTER_AXE_COST_GROWTH, level)))


static func auto_chopper_cost(level: int) -> int:
	return int(round(AUTO_CHOPPER_BASE_COST * pow(AUTO_CHOPPER_COST_GROWTH, level)))


static func axe_damage_for_level(level: int) -> int:
	return BETTER_AXE_BASE_DAMAGE + level * BETTER_AXE_DAMAGE_PER_LEVEL


static func auto_chop_rate_for_level(level: int) -> float:
	return level * AUTO_CHOPPER_RATE_PER_LEVEL


static func tree_max_health(level: int, difficulty: int) -> int:
	return TREE_HEALTH_BASE + TREE_HEALTH_PER_LEVEL * level * difficulty


static func tree_chop_reward(level: int, difficulty: int) -> int:
	return TREE_REWARD_BASE + int(round(TREE_REWARD_PER_LEVEL * level * difficulty))


## The Chop total required to prestige *from* prestige_level (i.e. what
## GameState.chops must reach to unlock the reset that takes the player
## from prestige_level to prestige_level + 1). Grows per level so
## increasingly large prestige_multiplier values do not shrink every
## later cycle toward an instant, meaningless reset.
static func prestige_threshold_for_level(level: int) -> int:
	return int(round(PRESTIGE_BASE_THRESHOLD * pow(PRESTIGE_THRESHOLD_GROWTH, level)))


static func prestige_multiplier_for_level(level: int) -> float:
	return 1.0 + level * PRESTIGE_MULTIPLIER_PER_LEVEL
