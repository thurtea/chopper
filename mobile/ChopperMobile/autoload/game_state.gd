extends Node

## Autoload singleton. Holds currency, upgrades, prestige, and the current run.

signal chops_changed(amount: int)
signal stats_changed

# --- Currency ---
var chops: int = 0:
	set(value):
		chops = max(value, 0)
		chops_changed.emit(chops)
		stats_changed.emit()

# --- Upgrades (levels; combat values live on chopper) ---
var axe_level: int = 0
var auto_chopper_level: int = 0
var element_power_level: int = 0

# --- Prestige ---
var prestige_level: int = 0

# --- Models ---
var chopper: ChopperData = ChopperData.new()
var current_tree: TreeData = TreeData.make(1, TreeData.Element.NONE, 1)
var upcoming_trees: Array[TreeData] = []
var active_enchantments: Array[EnchantmentData] = []


func _ready() -> void:
	randomize()
	if upcoming_trees.is_empty():
		upcoming_trees = [
			TreeData.make(2, TreeData.Element.FIRE, 2),
			TreeData.make(3, TreeData.Element.ICE, 1),
			TreeData.make(4, TreeData.Element.EARTH, 3),
		]
	stats_changed.emit()


func element_color(element: TreeData.Element) -> Color:
	return TreeData.color_for(element)


func element_display_name(element: TreeData.Element) -> String:
	return TreeData.display_name(element)


## Prompt 2.2: applies one manual chop to current_tree. GameState owns the
## resulting state change (damage, Chops, queue advance); the returned
## Dictionary is only for the view layer's animation/feedback, never a
## second source of truth. Keys: damage (int, actually applied), fell
## (bool), reward (int, 0 unless fell).
func chop_current_tree() -> Dictionary:
	var damage := chopper.axe_damage
	if chopper.has_element_power():
		var multiplier := TreeData.elemental_multiplier(chopper.active_element, current_tree.element)
		damage = maxi(1, int(round(damage * multiplier)))
	var applied := current_tree.take_damage(damage)
	var fell := current_tree.is_fallen()
	var reward := 0
	if fell:
		reward = current_tree.chop_reward
		chops += reward
		_advance_tree()
	stats_changed.emit()
	return {"damage": applied, "fell": fell, "reward": reward}


## Pops the next tree off the queue into current_tree and tops the queue
## back up to its previous length. Generation here is deliberately a plain
## random pick, just enough that the queue never runs dry; Prompt 2.3 is
## where weighted, decision-driving generation belongs.
func _advance_tree() -> void:
	if upcoming_trees.is_empty():
		current_tree = _generate_tree(current_tree.tree_level + 1)
	else:
		current_tree = upcoming_trees.pop_front()
	upcoming_trees.append(_generate_tree(_next_queue_level()))


func _next_queue_level() -> int:
	if upcoming_trees.is_empty():
		return current_tree.tree_level + 1
	return upcoming_trees[-1].tree_level + 1


func _generate_tree(level: int) -> TreeData:
	var elements: Array[TreeData.Element] = [
		TreeData.Element.NONE, TreeData.Element.FIRE, TreeData.Element.ICE,
		TreeData.Element.BOLT, TreeData.Element.EARTH, TreeData.Element.WIND,
	]
	var element: TreeData.Element = elements[randi() % elements.size()]
	return TreeData.make(level, element, randi_range(1, 3))
