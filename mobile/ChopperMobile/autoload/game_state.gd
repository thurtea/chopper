extends Node

## Autoload singleton. Holds currency, upgrades, prestige, and the current run.

signal chops_changed(amount: int)
signal stats_changed
## Prompt 5.1: fired after a successful prestige_reset(), once the new
## level/multiplier are already live, so the UI can show a one-shot "what
## you just got" summary without re-deriving it from before/after diffing
## stats_changed snapshots itself.
signal prestiged(new_level: int, new_multiplier: float, previous_multiplier: float)
## Chops granted for time away, after a successful load. 0 means none.
signal offline_earnings_granted(amount: int)

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

# Fractional Chops/sec accumulator (Prompt 3.1's Auto Chopper): chops is
# an int, so a rate like 0.5/sec can't be added directly every frame
# without losing the fraction. See _process() below.
var _auto_chop_accumulator: float = 0.0

# Prompt 3.3: total tree kills this run, used only to decide when a
# milestone-guaranteed enchantment is due. Not player-facing.
var _trees_chopped_total: int = 0

# --- Prompt 5.3: persistent save ---
# A separate file from AudioManager's own user://audio.cfg (Prompt 4.2),
# which already saves/loads independently and keeps doing so; this file
# is only the run state (currency, upgrades, prestige, current tree,
# queue, enchantments). JSON over ConfigFile because the queue and
# enchantment list are arrays of structured records, not flat key/value
# pairs. SAVE_VERSION exists so a future format change can detect and
# migrate (or discard) an older save instead of misreading it.
const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 2
const AUTOSAVE_WAIT_SECONDS := 30.0

## Chops granted on the most recent load for time spent away. The UI
## reads this after _ready(); a v1 save migrates with this left at 0.
var offline_earnings: int = 0


func _ready() -> void:
	randomize()
	if not _load_game():
		upcoming_trees = [
			TreeData.make(2, TreeData.Element.FIRE, 2),
			TreeData.make(3, TreeData.Element.ICE, 1),
			TreeData.make(4, TreeData.Element.EARTH, 3),
		]
	stats_changed.emit()
	var autosave := Timer.new()
	autosave.wait_time = AUTOSAVE_WAIT_SECONDS
	autosave.autostart = true
	autosave.timeout.connect(_save_game)
	add_child(autosave)


## Godot 4.7 Node notifications (class_node.html): pause is 2015,
## application focus-out is 2017, window close-request is 1006.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
			or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()


## Auto Chopper's passive income (Prompt 3.1). Purely a Chops generator,
## decoupled from the tree-chopping mechanic itself, matching the design
## doc's own "Auto Chopper (passive chops per second)" bottom-panel spec,
## not an auto-clicking axe. Runs every frame automatically: a Node's
## _process() needs no explicit set_process(true) call to be enabled.
func _process(delta: float) -> void:
	_tick_enchantments_by_time(delta)
	if chopper.auto_chop_rate <= 0.0:
		return
	_auto_chop_accumulator += effective_auto_chop_rate() * delta
	if _auto_chop_accumulator >= 1.0:
		var whole := int(_auto_chop_accumulator)
		_auto_chop_accumulator -= float(whole)
		chops += whole


## Real effective Chops/sec right now, including the prestige multiplier
## and any active Auto Boost enchantment (Prompt 3.3). What the UI's CPS
## display reads, so it never drifts from what _process() actually pays out.
func effective_auto_chop_rate() -> float:
	return chopper.auto_chop_rate * chopper.prestige_multiplier * _auto_boost_multiplier()


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
	damage = maxi(1, int(round(damage * chopper.prestige_multiplier)))
	damage = maxi(1, int(round(damage * _empowered_multiplier())))
	var applied := current_tree.take_damage(damage)
	var fell := current_tree.is_fallen()
	var reward := 0
	var granted: EnchantmentData = null
	if fell:
		reward = maxi(1, int(round(
			current_tree.chop_reward * chopper.prestige_multiplier * _gold_rush_multiplier()
		)))
		chops += reward
		_advance_tree()
		_tick_enchantments_by_tree()
		granted = _maybe_grant_enchantment()
	stats_changed.emit()
	if fell:
		_save_game()
	return {"damage": applied, "fell": fell, "reward": reward, "enchantment": granted}


## Pops the next tree off the queue into current_tree and tops the queue
## back up to its previous length. Also counts down Element Power's
## remaining-trees window, since "the next N trees" (Prompt 3.1) means N
## tree kills, not N individual hits.
func _advance_tree() -> void:
	if chopper.has_element_power():
		chopper.element_trees_remaining -= 1
		if chopper.element_trees_remaining <= 0:
			chopper.active_element = TreeData.Element.NONE
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


## Prompt 3.1: the four core upgrades. Costs/values all come from
## UpgradeConfig (scripts/upgrade_config.gd), the one tunable place.
## Every buy_*() returns false and changes nothing if the player cannot
## afford it, true and applies the purchase otherwise.

func buy_better_axe() -> bool:
	var cost := UpgradeConfig.better_axe_cost(axe_level)
	if chops < cost:
		return false
	chops -= cost
	axe_level += 1
	chopper.axe_damage = UpgradeConfig.axe_damage_for_level(axe_level)
	stats_changed.emit()
	_save_game()
	return true


func buy_auto_chopper() -> bool:
	var cost := UpgradeConfig.auto_chopper_cost(auto_chopper_level)
	if chops < cost:
		return false
	chops -= cost
	auto_chopper_level += 1
	chopper.auto_chop_rate = UpgradeConfig.auto_chop_rate_for_level(auto_chopper_level)
	stats_changed.emit()
	_save_game()
	return true


## Prompt 3.2: the five Fire/Ice/Bolt/Earth/Wind buttons call this to set
## which element Element Power will activate on the next purchase.
func select_element(element: TreeData.Element) -> void:
	chopper.selected_element = element
	stats_changed.emit()


## Activates Element Power for the next UpgradeConfig.ELEMENT_POWER_TREES
## trees, using whichever element select_element() last set. Requires a
## selection first (Prompt 2.2's own placeholder random pick is gone as of
## Prompt 3.2): with no element chosen, there is nothing meaningful to
## activate, so this fails the same way an unaffordable purchase does.
func buy_element_power() -> bool:
	if chopper.selected_element == TreeData.Element.NONE:
		return false
	if chops < UpgradeConfig.ELEMENT_POWER_COST:
		return false
	chops -= UpgradeConfig.ELEMENT_POWER_COST
	element_power_level += 1
	chopper.active_element = chopper.selected_element
	chopper.element_trees_remaining = UpgradeConfig.ELEMENT_POWER_TREES
	stats_changed.emit()
	_save_game()
	return true


func can_prestige() -> bool:
	return chops >= UpgradeConfig.prestige_threshold_for_level(prestige_level)


## Core prestige reset from Prompt 3.1 (become available past a threshold,
## reset the run, grant a permanent multiplier), plus Prompt 5.1's own
## `prestiged` emit so the UI can show a one-shot "what you just got"
## summary. main.gd gates the actual call behind a confirmation dialog;
## this function itself is unconditional once can_prestige() passes.
func prestige_reset() -> bool:
	if not can_prestige():
		return false
	var previous_multiplier := chopper.prestige_multiplier
	prestige_level += 1
	var new_multiplier := UpgradeConfig.prestige_multiplier_for_level(prestige_level)
	chops = 0
	axe_level = 0
	auto_chopper_level = 0
	element_power_level = 0
	chopper = ChopperData.new()
	chopper.prestige_multiplier = new_multiplier
	current_tree = TreeData.make(1, TreeData.Element.NONE, 1)
	# Built one at a time, not as a single array literal: each call reads
	# current_tree/upcoming_trees for its own anti-clustering weighting
	# (_pick_weighted_element()), so the queue must already reflect every
	# tree generated so far, not just the pre-reset state.
	upcoming_trees = []
	upcoming_trees.append(_generate_tree(2))
	upcoming_trees.append(_generate_tree(3))
	upcoming_trees.append(_generate_tree(4))
	active_enchantments = []
	_trees_chopped_total = 0
	stats_changed.emit()
	prestiged.emit(prestige_level, new_multiplier, previous_multiplier)
	_save_game()
	return true


## Prompt 3.3: the enchantment system. Grants happen from chop_current_tree()
## on a kill; ongoing effects (Empowered, Gold Rush, Auto Boost) are applied
## by reading active_enchantments each time they matter (damage, reward,
## auto-chop rate) and ticked down by tree kill or by time, whichever that
## kind actually uses (EnchantmentData.is_expired() already only cares
## about the one counter a given kind ever sets away from zero). Elemental
## Surge is the one exception: it applies itself immediately by reusing the
## existing Element Power mechanism (Prompt 3.1/3.2) instead of being
## tracked here, since "free Element Power" already has a real
## implementation, not a new one to build.

func _empowered_multiplier() -> float:
	var multiplier := 1.0
	for enchantment in active_enchantments:
		if enchantment.kind == EnchantmentData.Kind.EMPOWERED:
			multiplier *= enchantment.magnitude
	return multiplier


func _gold_rush_multiplier() -> float:
	var multiplier := 1.0
	for enchantment in active_enchantments:
		if enchantment.kind == EnchantmentData.Kind.GOLD_RUSH:
			multiplier *= enchantment.magnitude
	return multiplier


func _auto_boost_multiplier() -> float:
	var multiplier := 1.0
	for enchantment in active_enchantments:
		if enchantment.kind == EnchantmentData.Kind.AUTO_BOOST:
			multiplier *= enchantment.magnitude
	return multiplier


## Counts down every active enchantment's remaining_trees by one (a
## no-op for time-only kinds, whose remaining_trees stays 0), removing
## any that are now expired. Called once per kill, after the kill's own
## reward already read _gold_rush_multiplier(), so "the next tree" is
## the tree that was just chopped, not the one after it.
func _tick_enchantments_by_tree() -> void:
	var i := active_enchantments.size() - 1
	while i >= 0:
		var enchantment: EnchantmentData = active_enchantments[i]
		if enchantment.remaining_trees > 0:
			enchantment.remaining_trees -= 1
		if enchantment.is_expired():
			active_enchantments.remove_at(i)
		i -= 1


## Same idea as _tick_enchantments_by_tree(), for the one time-based kind
## (Auto Boost). Called every frame from _process(); emits stats_changed
## only when something actually expired, so the active-enchantment icons
## in the UI clear themselves promptly without spamming the signal every
## single frame otherwise.
func _tick_enchantments_by_time(delta: float) -> void:
	var changed := false
	var i := active_enchantments.size() - 1
	while i >= 0:
		var enchantment: EnchantmentData = active_enchantments[i]
		if enchantment.remaining_seconds > 0.0:
			enchantment.remaining_seconds -= delta
		if enchantment.is_expired():
			active_enchantments.remove_at(i)
			changed = true
		i -= 1
	if changed:
		stats_changed.emit()


## Called once per kill. Guarantees an enchantment every
## UpgradeConfig.ENCHANTMENT_MILESTONE_INTERVAL-th kill; otherwise a flat
## UpgradeConfig.ENCHANTMENT_GRANT_CHANCE chance. Returns the granted
## EnchantmentData (for the one-shot "you got X!" banner) or null.
func _maybe_grant_enchantment() -> EnchantmentData:
	_trees_chopped_total += 1
	var guaranteed := _trees_chopped_total % UpgradeConfig.ENCHANTMENT_MILESTONE_INTERVAL == 0
	if not guaranteed and randf() > UpgradeConfig.ENCHANTMENT_GRANT_CHANCE:
		return null
	return _grant_random_enchantment()


func _grant_random_enchantment() -> EnchantmentData:
	var kinds: Array[EnchantmentData.Kind] = [
		EnchantmentData.Kind.EMPOWERED, EnchantmentData.Kind.ELEMENTAL_SURGE,
		EnchantmentData.Kind.GOLD_RUSH, EnchantmentData.Kind.AUTO_BOOST,
	]
	var kind: EnchantmentData.Kind = kinds[randi() % kinds.size()]
	match kind:
		EnchantmentData.Kind.EMPOWERED:
			var enchantment := EnchantmentData.empowered()
			active_enchantments.append(enchantment)
			return enchantment
		EnchantmentData.Kind.GOLD_RUSH:
			var enchantment := EnchantmentData.gold_rush()
			active_enchantments.append(enchantment)
			return enchantment
		EnchantmentData.Kind.AUTO_BOOST:
			var enchantment := EnchantmentData.auto_boost()
			active_enchantments.append(enchantment)
			return enchantment
		_:
			var elements: Array[TreeData.Element] = [
				TreeData.Element.FIRE, TreeData.Element.ICE, TreeData.Element.BOLT,
				TreeData.Element.EARTH, TreeData.Element.WIND,
			]
			var element: TreeData.Element = elements[randi() % elements.size()]
			var enchantment := EnchantmentData.elemental_surge(element)
			chopper.active_element = element
			chopper.element_trees_remaining = UpgradeConfig.ELEMENT_POWER_TREES
			return enchantment


## Prompt 5.3: persistent save/load. Writes the whole run (currency,
## upgrade levels, prestige, chopper stats, current tree, upcoming
## queue, active enchantments) as JSON to SAVE_PATH. Auto-saved after
## every tree kill and every successful upgrade/prestige purchase (see
## the call sites above); never saved on a plain non-killing hit, since
## the design doc only asks for a save "after every tree kill."
## Audio settings are not part of this file: AudioManager has saved and
## loaded those independently to user://audio.cfg since Prompt 4.2.

func _save_game() -> void:
	var upcoming_data: Array = []
	for tree in upcoming_trees:
		upcoming_data.append(_tree_to_dict(tree))
	var enchantment_data: Array = []
	for enchantment in active_enchantments:
		enchantment_data.append(_enchantment_to_dict(enchantment))
	var data := {
		"version": SAVE_VERSION,
		"saved_unix": int(Time.get_unix_time_from_system()),
		"effective_auto_chop_rate": effective_auto_chop_rate(),
		"chops": chops,
		"axe_level": axe_level,
		"auto_chopper_level": auto_chopper_level,
		"element_power_level": element_power_level,
		"prestige_level": prestige_level,
		"trees_chopped_total": _trees_chopped_total,
		"auto_chop_accumulator": _auto_chop_accumulator,
		"chopper": _chopper_to_dict(chopper),
		"current_tree": _tree_to_dict(current_tree),
		"upcoming_trees": upcoming_data,
		"active_enchantments": enchantment_data,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("GameState: failed to open %s for writing (%s)" % [SAVE_PATH, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(data))


## Returns true if a valid save was found and loaded (skipping the
## fresh-run defaults in _ready()), false otherwise (no file, unreadable,
## wrong version, or malformed content) — any failure just leaves every
## var at its already-initialized fresh-run default.
func _load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	var version := int(data.get("version", -1))
	if version < 1 or version > SAVE_VERSION:
		return false
	if not (data.has("current_tree") and data.has("chopper")):
		return false

	chops = int(data.get("chops", 0))
	axe_level = int(data.get("axe_level", 0))
	auto_chopper_level = int(data.get("auto_chopper_level", 0))
	element_power_level = int(data.get("element_power_level", 0))
	prestige_level = int(data.get("prestige_level", 0))
	_trees_chopped_total = int(data.get("trees_chopped_total", 0))
	_auto_chop_accumulator = float(data.get("auto_chop_accumulator", 0.0))
	chopper = _chopper_from_dict(data["chopper"])
	current_tree = _tree_from_dict(data["current_tree"])

	upcoming_trees.clear()
	for tree_data in data.get("upcoming_trees", []):
		if typeof(tree_data) == TYPE_DICTIONARY:
			upcoming_trees.append(_tree_from_dict(tree_data))

	active_enchantments.clear()
	for enchantment_data in data.get("active_enchantments", []):
		if typeof(enchantment_data) == TYPE_DICTIONARY:
			active_enchantments.append(_enchantment_from_dict(enchantment_data))

	offline_earnings = 0
	if version >= 2:
		offline_earnings = _offline_chops(
			int(data.get("saved_unix", 0)),
			float(data.get("effective_auto_chop_rate", 0.0))
		)
		if offline_earnings > 0:
			chops += offline_earnings
	return true


## v1 saves have no timestamp. Missing or backwards clocks grant nothing,
## so a migrated file cannot be paid as if it were saved in 1970.
func _offline_chops(saved_unix: int, saved_rate: float) -> int:
	if saved_unix <= 0 or saved_rate <= 0.0:
		return 0
	var now := int(Time.get_unix_time_from_system())
	if now <= saved_unix:
		return 0
	var elapsed := mini(now - saved_unix, UpgradeConfig.OFFLINE_EARNINGS_CAP_SECONDS)
	return int(floor(saved_rate * float(elapsed)))


func _chopper_to_dict(data: ChopperData) -> Dictionary:
	return {
		"axe_damage": data.axe_damage,
		"auto_chop_rate": data.auto_chop_rate,
		"active_element": data.active_element,
		"selected_element": data.selected_element,
		"prestige_multiplier": data.prestige_multiplier,
		"element_trees_remaining": data.element_trees_remaining,
	}


func _chopper_from_dict(data: Dictionary) -> ChopperData:
	var chopper_data := ChopperData.new()
	chopper_data.axe_damage = int(data.get("axe_damage", 1))
	chopper_data.auto_chop_rate = float(data.get("auto_chop_rate", 0.0))
	chopper_data.active_element = int(data.get("active_element", TreeData.Element.NONE))
	chopper_data.selected_element = int(data.get("selected_element", TreeData.Element.NONE))
	chopper_data.prestige_multiplier = float(data.get("prestige_multiplier", 1.0))
	chopper_data.element_trees_remaining = int(data.get("element_trees_remaining", 0))
	return chopper_data


func _tree_to_dict(data: TreeData) -> Dictionary:
	return {
		"health": data.health,
		"max_health": data.max_health,
		"element": data.element,
		"chop_reward": data.chop_reward,
		"tree_level": data.tree_level,
		"difficulty": data.difficulty,
		"is_boss": data.is_boss,
		"is_enchanted": data.is_enchanted,
	}


func _tree_from_dict(data: Dictionary) -> TreeData:
	var tree := TreeData.new()
	tree.health = int(data.get("health", 1))
	tree.max_health = int(data.get("max_health", 1))
	tree.element = int(data.get("element", TreeData.Element.NONE))
	tree.chop_reward = int(data.get("chop_reward", 0))
	tree.tree_level = int(data.get("tree_level", 1))
	tree.difficulty = int(data.get("difficulty", 1))
	tree.is_boss = bool(data.get("is_boss", false))
	tree.is_enchanted = bool(data.get("is_enchanted", false))
	return tree


func _enchantment_to_dict(data: EnchantmentData) -> Dictionary:
	return {
		"kind": data.kind,
		"remaining_trees": data.remaining_trees,
		"remaining_seconds": data.remaining_seconds,
		"description": data.description,
		"magnitude": data.magnitude,
	}


func _enchantment_from_dict(data: Dictionary) -> EnchantmentData:
	var enchantment := EnchantmentData.new()
	enchantment.kind = int(data.get("kind", EnchantmentData.Kind.EMPOWERED))
	enchantment.remaining_trees = int(data.get("remaining_trees", 0))
	enchantment.remaining_seconds = float(data.get("remaining_seconds", 0.0))
	enchantment.description = String(data.get("description", ""))
	enchantment.magnitude = float(data.get("magnitude", 1.0))
	return enchantment
