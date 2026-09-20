extends Control

@onready var chops_value: Label = %ChopsValue
@onready var cps_value: Label = %CpsValue
@onready var tree_level_value: Label = %TreeLevelValue
@onready var tree_level_badge: Label = %TreeLevelBadge
@onready var tree_element_badge: Label = %TreeElementBadge
@onready var health_bar: ProgressBar = %HealthBar
@onready var prestige_badge: Label = %PrestigeBadge
@onready var axe_cost: Label = %AxeCost
@onready var auto_cost: Label = %AutoCost
@onready var element_cost: Label = %ElementCost
@onready var preview_row: HBoxContainer = %PreviewRow
@onready var better_axe_button: Button = %BetterAxe
@onready var auto_chopper_button: Button = %AutoChopper
@onready var element_power_button: Button = %ElementPower
@onready var prestige_button: Button = %PrestigeReset
@onready var prestige_hint: Label = %PrestigeHint
@onready var fire_button: Button = %Fire
@onready var ice_button: Button = %Ice
@onready var bolt_button: Button = %Bolt
@onready var earth_button: Button = %Earth
@onready var wind_button: Button = %Wind
@onready var chopper_element_badge: Label = %ChopperElementBadge
@onready var play_inner: Control = %PlayInner
@onready var tree_sprite: TextureRect = %TreeSprite
@onready var chopper_sprite: TextureRect = %ChopperSprite
@onready var hit_particles: CPUParticles2D = %HitParticles
@onready var kill_particles: CPUParticles2D = %KillParticles
@onready var hit_sfx: AudioStreamPlayer = %HitSfx

var _shake_tween: Tween
var _swing_tween: Tween
var _fall_tween: Tween


func _ready() -> void:
	GameState.stats_changed.connect(_refresh_ui)
	tree_sprite.gui_input.connect(_on_tree_gui_input)
	better_axe_button.pressed.connect(func() -> void: GameState.buy_better_axe())
	auto_chopper_button.pressed.connect(func() -> void: GameState.buy_auto_chopper())
	element_power_button.pressed.connect(func() -> void: GameState.buy_element_power())
	prestige_button.pressed.connect(func() -> void: GameState.prestige_reset())
	fire_button.pressed.connect(func() -> void: GameState.select_element(TreeData.Element.FIRE))
	ice_button.pressed.connect(func() -> void: GameState.select_element(TreeData.Element.ICE))
	bolt_button.pressed.connect(func() -> void: GameState.select_element(TreeData.Element.BOLT))
	earth_button.pressed.connect(func() -> void: GameState.select_element(TreeData.Element.EARTH))
	wind_button.pressed.connect(func() -> void: GameState.select_element(TreeData.Element.WIND))
	_refresh_ui()


## Prompt 2.2: manual chopping. Accepts both a mouse click and a touch
## tap on the tree sprite (pointing/emulate_touch_from_mouse is also on
## in project.godot, so the mouse branch alone covers the editor too).
func _on_tree_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_chop()
	elif event is InputEventScreenTouch and event.pressed:
		_chop()


func _chop() -> void:
	var result: Dictionary = GameState.chop_current_tree()
	_play_axe_swing()
	hit_sfx.play()
	_spawn_floating_number("-%d" % int(result["damage"]), Color(1, 0.95, 0.82, 1))
	_burst(hit_particles)
	_shake(6.0)
	if result["fell"]:
		_play_tree_fall()
		_spawn_floating_number(
			"+%d Chops" % int(result["reward"]), Color(1, 0.84, 0.2, 1), Vector2(0, -30)
		)
		_burst(kill_particles)
		_shake(14.0)


func _refresh_ui() -> void:
	var tree := GameState.current_tree
	var chopper := GameState.chopper
	chops_value.text = str(GameState.chops)
	cps_value.text = "%.1f" % (chopper.auto_chop_rate * chopper.prestige_multiplier)
	tree_level_value.text = str(tree.tree_level)
	tree_level_badge.text = "Lv. %d" % tree.tree_level
	health_bar.max_value = tree.max_health
	health_bar.value = tree.health
	prestige_badge.text = "Prestige %d" % GameState.prestige_level
	_refresh_tree_element_badge(tree, chopper)
	_refresh_chopper_element_badge(chopper)
	_refresh_upgrade_buttons(chopper)
	_refresh_element_buttons(chopper)
	_refresh_previews()


## Prompt 3.2: when Element Power is active, the existing tree element
## badge also shows whether the active element is favourable or
## unfavourable against this specific tree, the actual "should I push or
## prepare" information the design doc's strategic hook depends on. With
## no Element Power active, this is unchanged from Prompt 1.2: just the
## tree's own element.
func _refresh_tree_element_badge(tree: TreeData, chopper: ChopperData) -> void:
	var base_text := GameState.element_display_name(tree.element)
	var base_color := GameState.element_color(tree.element).lightened(0.2)
	if not chopper.has_element_power():
		tree_element_badge.text = base_text
		tree_element_badge.add_theme_color_override("font_color", base_color)
		return
	var multiplier := TreeData.elemental_multiplier(chopper.active_element, tree.element)
	if multiplier > 1.0:
		tree_element_badge.text = base_text + " (Weak!)"
		tree_element_badge.add_theme_color_override("font_color", Color(1, 0.86, 0.3, 1))
	elif multiplier < 1.0:
		tree_element_badge.text = base_text + " (Resist)"
		tree_element_badge.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8, 1))
	else:
		tree_element_badge.text = base_text
		tree_element_badge.add_theme_color_override("font_color", base_color)


## Prompt 3.2's own "clear visual indicator on Chopper ... when an
## element is active": empty (so nothing shows) whenever Element Power
## is not active.
func _refresh_chopper_element_badge(chopper: ChopperData) -> void:
	if chopper.has_element_power():
		chopper_element_badge.text = "%s Power (%d left)" % [
			GameState.element_display_name(chopper.active_element),
			chopper.element_trees_remaining,
		]
		chopper_element_badge.add_theme_color_override(
			"font_color", GameState.element_color(chopper.active_element).lightened(0.3)
		)
	else:
		chopper_element_badge.text = ""


## Prompt 3.1: real costs (from UpgradeConfig) and afford-gated buttons,
## replacing the static placeholder cost text Prompt 1.2's UI shipped with.
func _refresh_upgrade_buttons(chopper: ChopperData) -> void:
	var axe_price := UpgradeConfig.better_axe_cost(GameState.axe_level)
	axe_cost.text = "Cost: %d" % axe_price
	better_axe_button.disabled = GameState.chops < axe_price

	var auto_price := UpgradeConfig.auto_chopper_cost(GameState.auto_chopper_level)
	auto_cost.text = "Cost: %d" % auto_price
	auto_chopper_button.disabled = GameState.chops < auto_price

	if chopper.has_element_power():
		element_cost.text = "Active: %d left" % chopper.element_trees_remaining
	elif chopper.selected_element == TreeData.Element.NONE:
		element_cost.text = "Pick an element"
	else:
		element_cost.text = "Cost: %d" % UpgradeConfig.ELEMENT_POWER_COST
	element_power_button.disabled = (
		GameState.chops < UpgradeConfig.ELEMENT_POWER_COST
		or chopper.selected_element == TreeData.Element.NONE
	)

	var prestige_ready := GameState.can_prestige()
	if prestige_ready:
		var next_multiplier := UpgradeConfig.prestige_multiplier_for_level(GameState.prestige_level + 1)
		prestige_hint.text = "Ready! x%.1f -> x%.1f" % [chopper.prestige_multiplier, next_multiplier]
	else:
		prestige_hint.text = "Unlocks at %d" % UpgradeConfig.PRESTIGE_CHOP_THRESHOLD
	prestige_button.disabled = not prestige_ready


## Prompt 3.2: keeps the five element buttons' pressed/toggled look in
## sync with chopper.selected_element. Needed beyond the buttons' own
## click handling because prestige_reset() (Prompt 3.1) replaces chopper
## with a fresh ChopperData, which silently un-selects everything without
## the buttons themselves ever being clicked.
func _refresh_element_buttons(chopper: ChopperData) -> void:
	fire_button.button_pressed = chopper.selected_element == TreeData.Element.FIRE
	ice_button.button_pressed = chopper.selected_element == TreeData.Element.ICE
	bolt_button.button_pressed = chopper.selected_element == TreeData.Element.BOLT
	earth_button.button_pressed = chopper.selected_element == TreeData.Element.EARTH
	wind_button.button_pressed = chopper.selected_element == TreeData.Element.WIND


func _refresh_previews() -> void:
	var cards := preview_row.get_children()
	for i in cards.size():
		if i < GameState.upcoming_trees.size() and cards[i].has_method("set_preview"):
			cards[i].set_preview(GameState.upcoming_trees[i])


## Anticipate -> hit -> recover on chopper.png itself (no swing spritesheet
## yet, per tomorrow.md's own Prompt 2.2 note).
func _play_axe_swing() -> void:
	if _swing_tween and _swing_tween.is_valid():
		_swing_tween.kill()
	chopper_sprite.rotation = 0.0
	_swing_tween = create_tween()
	_swing_tween.tween_property(chopper_sprite, "rotation", -0.18, 0.06) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_property(chopper_sprite, "rotation", 0.34, 0.06) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_swing_tween.tween_property(chopper_sprite, "rotation", 0.0, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Tree topples over and fades, then pops back to neutral for whatever
## tree GameState just advanced current_tree to (there is only one tree
## texture, so a plain reset reads as "the next tree" with no extra art).
func _play_tree_fall() -> void:
	if _fall_tween and _fall_tween.is_valid():
		_fall_tween.kill()
	tree_sprite.rotation = 0.0
	tree_sprite.scale = Vector2.ONE
	tree_sprite.modulate.a = 1.0
	_fall_tween = create_tween()
	_fall_tween.tween_property(tree_sprite, "rotation", deg_to_rad(80), 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_fall_tween.parallel().tween_property(tree_sprite, "modulate:a", 0.0, 0.3)
	_fall_tween.tween_callback(func() -> void:
		tree_sprite.rotation = 0.0
		tree_sprite.modulate.a = 1.0
		tree_sprite.scale = Vector2(0.8, 0.8)
	)
	_fall_tween.tween_property(tree_sprite, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## TreeSprite sits several containers deep (CenterStage/StageRow/
## TreeColumn); its own .position is relative to that immediate parent,
## not to play_inner, which is where particles/floating numbers are
## parented so they are not fought over by container layout. Converts
## through global space to get a point in play_inner's local space.
func _tree_center_in_play_inner() -> Vector2:
	var global_center: Vector2 = tree_sprite.global_position + tree_sprite.size * 0.5
	return play_inner.get_global_transform().affine_inverse() * global_center


## Leaves + wood-chip particle burst, positioned over the tree. Matching
## exact leaf vs. chip art is Phase 4.1 polish; this is the mechanism
## (burst on every hit, a bigger one on kill).
func _burst(particles: CPUParticles2D) -> void:
	particles.position = _tree_center_in_play_inner()
	particles.restart()
	particles.emitting = true


## Screen shake on the whole Main control, not just the play area, so it
## reads as a real hit impact rather than a local wobble.
func _shake(strength: float) -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
		position = Vector2.ZERO
	_shake_tween = create_tween()
	for i in 5:
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		_shake_tween.tween_property(self, "position", offset, 0.03)
	_shake_tween.tween_property(self, "position", Vector2.ZERO, 0.05)


## Damage/reward text that arcs up from the tree and fades. A code-built
## Label rather than a dedicated scene: it is a one-shot, self-cleaning
## effect with no state worth persisting in a .tscn.
func _spawn_floating_number(text: String, color: Color, offset: Vector2 = Vector2.ZERO) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.z_index = 10
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_inner.add_child(label)
	label.position = _tree_center_in_play_inner() + Vector2(-20, -20) + offset
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 46, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.tween_callback(label.queue_free)
