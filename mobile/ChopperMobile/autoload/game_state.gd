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
## back up to its previous length.
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


## Prompt 2.3: weighted generation. Difficulty (stars) is still a plain
## uniform roll, unchanged from Prompt 2.2; only which element gets
## picked is weighted now.
func _generate_tree(level: int) -> TreeData:
	return TreeData.make(level, _pick_weighted_element(), randi_range(1, 3))


## Picks an element for a newly generated tree, weighted so the player
## regularly faces a real mix, some matching whatever Element Power they
## might have active, some countering it, rather than Prompt 2.2's flat
## uniform pick (which could just as easily run five Fire trees in a row
## as give any real variety). The five-element wheel itself
## (TreeData.elemental_multiplier()) is unchanged; this only decides
## which element shows up on the tree, not what it does once it does.
func _pick_weighted_element() -> TreeData.Element:
	var elements: Array[TreeData.Element] = [
		TreeData.Element.NONE, TreeData.Element.FIRE, TreeData.Element.ICE,
		TreeData.Element.BOLT, TreeData.Element.EARTH, TreeData.Element.WIND,
	]
	# A NONE tree skips the elemental decision entirely, so it gets a
	# smaller base weight than any single real element: facing an
	# element is meant to be the common case, since that is the actual
	# "prepare or push" strategic hook Part 1 of the design doc describes.
	var base_weight := {
		TreeData.Element.NONE: 1.0,
		TreeData.Element.FIRE: 2.0,
		TreeData.Element.ICE: 2.0,
		TreeData.Element.BOLT: 2.0,
		TreeData.Element.EARTH: 2.0,
		TreeData.Element.WIND: 2.0,
	}
	# Everything the player can currently see and plan around: the tree
	# they are fighting plus the whole preview queue. Weighting against
	# this exact window, not some longer hidden history, keeps the
	# variety tied to what actually shows up on screen.
	var visible: Array[TreeData.Element] = [current_tree.element]
	for tree in upcoming_trees:
		visible.append(tree.element)

	var weights: Array[float] = []
	var total := 0.0
	for element in elements:
		var count := 0
		for seen in visible:
			if seen == element:
				count += 1
		# Each existing appearance already visible halves this element's
		# weight: a second Fire tree in the window is plausible, a
		# fourth is very unlikely, and no element's weight can ever
		# reach exactly zero (it just keeps shrinking).
		var weight: float = base_weight[element] * pow(0.5, count)
		weights.append(weight)
		total += weight

	var roll := randf() * total
	for i in elements.size():
		roll -= weights[i]
		if roll <= 0.0:
			return elements[i]
	return elements[-1]
