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
	cps_value.text = str(chopper.auto_chop_rate)
	tree_level_value.text = str(tree.tree_level)
	tree_level_badge.text = "Lv. %d" % tree.tree_level
	tree_element_badge.text = GameState.element_display_name(tree.element)
	tree_element_badge.add_theme_color_override(
		"font_color",
		GameState.element_color(tree.element).lightened(0.2)
	)
	health_bar.max_value = tree.max_health
	health_bar.value = tree.health
	prestige_badge.text = "Prestige %d" % GameState.prestige_level
	axe_cost.text = "Cost: 10"
	auto_cost.text = "Cost: 100"
	element_cost.text = "Cost: 50"
	_refresh_previews()


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
