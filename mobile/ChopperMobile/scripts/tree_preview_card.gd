extends PanelContainer

@onready var icon: TextureRect = %Icon
@onready var element_swatch: ColorRect = %ElementSwatch
@onready var element_label: Label = %ElementLabel
@onready var difficulty_label: Label = %DifficultyLabel

var _idle_tween: Tween


func _ready() -> void:
	icon.resized.connect(_center_icon_pivot)
	_center_icon_pivot()
	# Child _ready runs before the parent's, but the card is already in
	# PreviewRow by then, so get_index() is 0/1/2 and can stagger the
	# three idles out of phase. The delay is a one-shot prefix, not
	# part of the looping tween, or it would accumulate each cycle.
	var delay := float(get_index()) * 0.4
	if delay > 0.0:
		var starter := create_tween()
		starter.tween_interval(delay)
		starter.tween_callback(_start_idle_loop)
	else:
		_start_idle_loop()


func set_preview(tree: TreeData) -> void:
	var tint := GameState.element_color(tree.element)
	icon.modulate = tint.lightened(0.15)
	element_swatch.color = tint
	element_label.text = GameState.element_display_name(tree.element)
	var stars: int = clampi(tree.difficulty, 1, 3)
	difficulty_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)


## Prompt 4.3: a slow sway + breathe on the tree icon so the upcoming
## strip feels alive. Rotation and scale only: this card is a
## size_flags_horizontal=3 child of an HBoxContainer, and animating
## .position would be overwritten by the next layout pass. The idle
## loop is started once from _ready and is not restarted by
## set_preview(), which fires on every GameState.stats_changed.
func _start_idle_loop() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	_center_icon_pivot()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(icon, "rotation", deg_to_rad(3.2), 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.parallel().tween_property(icon, "scale", Vector2(1.06, 1.06), 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(icon, "rotation", deg_to_rad(-3.2), 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.parallel().tween_property(icon, "scale", Vector2(0.96, 0.96), 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _center_icon_pivot() -> void:
	icon.pivot_offset = icon.size * 0.5
