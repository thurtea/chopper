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
@onready var enchantment_icons: HBoxContainer = %EnchantmentIcons
@onready var enchantment_banner: PanelContainer = %EnchantmentBanner
@onready var enchantment_banner_text: Label = %EnchantmentBannerText
@onready var prestige_banner: PanelContainer = %PrestigeBanner
@onready var prestige_banner_text: Label = %PrestigeBannerText
@onready var prestige_confirm_dialog: ConfirmationDialog = %PrestigeConfirmDialog
@onready var play_inner: Control = %PlayInner
@onready var tree_sprite: TextureRect = %TreeSprite
@onready var chopper_sprite: TextureRect = %ChopperSprite
@onready var hit_particles: CPUParticles2D = %HitParticles
@onready var hit_particles_leaf: CPUParticles2D = %HitParticlesLeaf
@onready var kill_particles: CPUParticles2D = %KillParticles
@onready var kill_particles_leaf: CPUParticles2D = %KillParticlesLeaf
@onready var ui_margin: MarginContainer = %Margin
@onready var wood_frame_inner: PanelContainer = %WoodFrameInner

var _shake_tween: Tween
var _swing_tween: Tween
var _fall_tween: Tween
var _tree_shake_tween: Tween
var _health_tween: Tween
var _enchantment_banner_tween: Tween
var _prestige_pulse_tween: Tween
var _prestige_banner_tween: Tween

# Prompt 4.1: tracks which TreeData the health bar is currently showing
# (Resource identity, not value equality) so a brand-new tree (after a
# kill) snaps the bar straight to full instead of visibly animating up
# from wherever the old tree's bar was sitting.
var _last_health_tree: TreeData = null

# Prompt 4.3: designed margins in scenes/main.tscn, kept as the floor
# so a desktop window (safe area == full window) still has the original
# padding. Safe-area insets are added on top, never replace these.
const UI_MARGIN_LEFT := 24
const UI_MARGIN_TOP := 24
const UI_MARGIN_RIGHT := 24
const UI_MARGIN_BOTTOM := 18
const FRAME_INSET := 14.0

const COST_AFFORDABLE := Color(1, 1, 1, 0.9)
const COST_UNAFFORDABLE := Color(0.95, 0.35, 0.32, 1)
const COST_MUTED := Color(1, 1, 1, 0.45)
const COST_READY := Color(1, 0.84, 0.2, 1)


func _ready() -> void:
	GameState.stats_changed.connect(_refresh_ui)
	GameState.prestiged.connect(_on_prestiged)
	tree_sprite.gui_input.connect(_on_tree_gui_input)
	better_axe_button.pressed.connect(func() -> void: _try_buy(GameState.buy_better_axe))
	auto_chopper_button.pressed.connect(func() -> void: _try_buy(GameState.buy_auto_chopper))
	element_power_button.pressed.connect(func() -> void: _try_buy(GameState.buy_element_power))
	prestige_button.pressed.connect(_on_prestige_pressed)
	prestige_confirm_dialog.confirmed.connect(func() -> void: _try_buy(GameState.prestige_reset))
	fire_button.pressed.connect(func() -> void: _select_element(TreeData.Element.FIRE))
	ice_button.pressed.connect(func() -> void: _select_element(TreeData.Element.ICE))
	bolt_button.pressed.connect(func() -> void: _select_element(TreeData.Element.BOLT))
	earth_button.pressed.connect(func() -> void: _select_element(TreeData.Element.EARTH))
	wind_button.pressed.connect(func() -> void: _select_element(TreeData.Element.WIND))
	prestige_button.resized.connect(_center_prestige_pivot)
	_center_prestige_pivot()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
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
	# Prompt 4.2: AudioManager owns playback. Both fire immediately on
	# tap (not delayed to the visual hit frame) so a clicker-speed tap
	# still gets instant audio confirmation.
	AudioManager.play_swing()
	AudioManager.play_hit()
	_spawn_floating_number("-%d" % int(result["damage"]), Color(1, 0.95, 0.82, 1))
	_burst(hit_particles, hit_particles_leaf)
	_shake(6.0)
	if result["fell"]:
		_play_tree_fall()
		AudioManager.play_tree_fall()
		AudioManager.play_collect()
		_spawn_floating_number(
			"+%d Chops" % int(result["reward"]), Color(1, 0.84, 0.2, 1), Vector2(0, -30)
		)
		_burst(kill_particles, kill_particles_leaf)
		_shake(14.0)
		if result["enchantment"] != null:
			_show_enchantment_banner(result["enchantment"])
			AudioManager.play_enchantment()
	else:
		# Kill already plays its own bigger, distinct tree-fall motion;
		# this per-hit wobble is only for a hit that does not fell the
		# tree, so the two effects never fight over tree_sprite.rotation
		# in the same frame.
		_shake_tree()


## Prompt 4.2: upgrade / prestige buttons only emit pressed when they
## are not disabled, and _refresh_upgrade_buttons() disables them when
## unaffordable, so a successful buy is the expected path. Still gated
## on the return value so a race (tap landing after chops drop) does
## not play a purchase chime for a no-op.
func _try_buy(buy: Callable) -> void:
	if buy.call():
		AudioManager.play_upgrade()


func _select_element(element: TreeData.Element) -> void:
	GameState.select_element(element)
	AudioManager.play_ui_click()


## Prompt 5.1: Prestige is a full run reset, so the button no longer fires
## it immediately (that was Prompt 3.1's placeholder). It opens a
## confirmation dialog spelling out exactly what resets and what the
## permanent payoff is; only PrestigeConfirmDialog's "confirmed" signal
## (wired in _ready()) actually calls GameState.prestige_reset(). The
## button is disabled whenever can_prestige() is false, so reaching this
## handler already implies prestige is available.
func _on_prestige_pressed() -> void:
	var chopper := GameState.chopper
	var next_multiplier := UpgradeConfig.prestige_multiplier_for_level(GameState.prestige_level + 1)
	prestige_confirm_dialog.dialog_text = (
		"Reset your Chops, Better Axe, Auto Chopper, and Element Power, plus the current tree and any active enchantments.\n\n"
		+ "Prestige level and multiplier are permanent: x%.1f -> x%.1f, forever." % [
			chopper.prestige_multiplier, next_multiplier
		]
	)
	prestige_confirm_dialog.popup_centered()


## Prompt 5.1's own "better feedback when prestiging": a big centered
## banner (distinct from the small corner EnchantmentBanner) spelling out
## the level just reached and the multiplier change, since prestige_reset()
## has already wiped the run's own on-screen numbers by the time this fires.
func _on_prestiged(new_level: int, new_multiplier: float, previous_multiplier: float) -> void:
	prestige_banner_text.text = "Prestige %d! x%.1f -> x%.1f Chops & Damage, permanently" % [
		new_level, previous_multiplier, new_multiplier
	]
	if _prestige_banner_tween and _prestige_banner_tween.is_valid():
		_prestige_banner_tween.kill()
	prestige_banner.modulate.a = 0.0
	_prestige_banner_tween = create_tween()
	_prestige_banner_tween.tween_property(prestige_banner, "modulate:a", 1.0, 0.3)
	_prestige_banner_tween.tween_interval(3.0)
	_prestige_banner_tween.tween_property(prestige_banner, "modulate:a", 0.0, 0.5)


func _refresh_ui() -> void:
	var tree := GameState.current_tree
	var chopper := GameState.chopper
	chops_value.text = str(GameState.chops)
	cps_value.text = "%.1f" % GameState.effective_auto_chop_rate()
	tree_level_value.text = str(tree.tree_level)
	tree_level_badge.text = "Lv. %d" % tree.tree_level
	_refresh_health_bar(tree)
	prestige_badge.text = "Prestige %d - x%.1f" % [GameState.prestige_level, chopper.prestige_multiplier]
	_refresh_tree_element_badge(tree, chopper)
	_refresh_chopper_element_badge(chopper)
	_refresh_upgrade_buttons(chopper)
	_refresh_element_buttons(chopper)
	_refresh_enchantment_icons()
	_refresh_previews()


## Prompt 4.1's own "smooth health bar animation." A genuinely new tree
## (tracked by Resource identity, not by value: a fresh kill's tree could
## coincidentally share the same level/health as the one before it)
## snaps straight to its own max health; the same tree taking further
## damage tweens smoothly down to the new value instead of jumping.
func _refresh_health_bar(tree: TreeData) -> void:
	health_bar.max_value = tree.max_health
	if _health_tween and _health_tween.is_valid():
		_health_tween.kill()
	if tree != _last_health_tree:
		_last_health_tree = tree
		health_bar.value = tree.health
		return
	_health_tween = create_tween()
	_health_tween.tween_property(health_bar, "value", tree.health, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


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
## Prompt 4.3 colours the cost/hint labels: red when the player cannot
## afford the upgrade, gold when Prestige is ready, muted grey for
## "Pick an element" (not a price, but still a blocked state).
func _refresh_upgrade_buttons(chopper: ChopperData) -> void:
	var axe_price := UpgradeConfig.better_axe_cost(GameState.axe_level)
	var axe_ok := GameState.chops >= axe_price
	axe_cost.text = "Cost: %d" % axe_price
	better_axe_button.disabled = not axe_ok
	_set_cost_color(axe_cost, COST_AFFORDABLE if axe_ok else COST_UNAFFORDABLE)

	var auto_price := UpgradeConfig.auto_chopper_cost(GameState.auto_chopper_level)
	var auto_ok := GameState.chops >= auto_price
	auto_cost.text = "Cost: %d" % auto_price
	auto_chopper_button.disabled = not auto_ok
	_set_cost_color(auto_cost, COST_AFFORDABLE if auto_ok else COST_UNAFFORDABLE)

	var element_ok := (
		GameState.chops >= UpgradeConfig.ELEMENT_POWER_COST
		and chopper.selected_element != TreeData.Element.NONE
	)
	if chopper.has_element_power():
		element_cost.text = "Active: %d left" % chopper.element_trees_remaining
		_set_cost_color(element_cost, COST_READY)
	elif chopper.selected_element == TreeData.Element.NONE:
		element_cost.text = "Pick an element"
		_set_cost_color(element_cost, COST_MUTED)
	else:
		element_cost.text = "Cost: %d" % UpgradeConfig.ELEMENT_POWER_COST
		_set_cost_color(element_cost, COST_AFFORDABLE if element_ok else COST_UNAFFORDABLE)
	element_power_button.disabled = not element_ok

	var prestige_ready := GameState.can_prestige()
	var next_multiplier := UpgradeConfig.prestige_multiplier_for_level(GameState.prestige_level + 1)
	if prestige_ready:
		prestige_hint.text = "Ready! x%.1f -> x%.1f" % [chopper.prestige_multiplier, next_multiplier]
		_set_cost_color(prestige_hint, COST_READY)
	else:
		# Prompt 5.1: always preview the multiplier payoff, not just the
		# Chops threshold, so the player can weigh "is this worth resetting
		# my run for" before they are even close to affording it.
		prestige_hint.text = "x%.1f -> x%.1f at %d" % [
			chopper.prestige_multiplier, next_multiplier, UpgradeConfig.PRESTIGE_CHOP_THRESHOLD
		]
		_set_cost_color(prestige_hint, COST_MUTED)
	prestige_button.disabled = not prestige_ready
	_set_prestige_pulse(prestige_ready)


func _set_cost_color(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)


## Prompt 4.3: Prestige button pulses (scale + a slight brightness
## breathe) only while can_prestige() is true. Idempotent: a stats
## refresh that keeps it ready must not restart the tween from scratch,
## or the pulse would hitch every chop once the player is over the
## threshold. Scale rather than position, because PrestigeReset lives
## in a GridContainer that would overwrite .position on the next layout.
func _set_prestige_pulse(active: bool) -> void:
	if not active:
		if _prestige_pulse_tween and _prestige_pulse_tween.is_valid():
			_prestige_pulse_tween.kill()
		prestige_button.scale = Vector2.ONE
		prestige_button.modulate = Color.WHITE
		return
	if _prestige_pulse_tween and _prestige_pulse_tween.is_valid():
		return
	_center_prestige_pivot()
	_prestige_pulse_tween = create_tween().set_loops()
	_prestige_pulse_tween.tween_property(prestige_button, "scale", Vector2(1.07, 1.07), 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_prestige_pulse_tween.parallel().tween_property(
		prestige_button, "modulate", Color(1.18, 1.12, 1.35), 0.55
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_prestige_pulse_tween.tween_property(prestige_button, "scale", Vector2.ONE, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_prestige_pulse_tween.parallel().tween_property(
		prestige_button, "modulate", Color.WHITE, 0.55
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _center_prestige_pivot() -> void:
	prestige_button.pivot_offset = prestige_button.size * 0.5


## Prompt 4.3: keep interactive UI (and the inner gold frame) inside the
## display's unobscured rectangle so notches / home indicators / camera
## cutouts do not cover buttons or the header. Sky, ground, and the
## outer wooden bezel stay full-bleed on purpose: they are decoration,
## and filling the cutout avoids black bars. Desktop reports a safe
## area equal to the window, so the extra pad is zero and the original
## 24/24/24/18 margins remain.
func _apply_safe_area() -> void:
	var pad := _safe_area_pads()
	ui_margin.add_theme_constant_override("margin_left", UI_MARGIN_LEFT + int(round(pad.x)))
	ui_margin.add_theme_constant_override("margin_top", UI_MARGIN_TOP + int(round(pad.y)))
	ui_margin.add_theme_constant_override("margin_right", UI_MARGIN_RIGHT + int(round(pad.z)))
	ui_margin.add_theme_constant_override("margin_bottom", UI_MARGIN_BOTTOM + int(round(pad.w)))
	wood_frame_inner.offset_left = FRAME_INSET + pad.x
	wood_frame_inner.offset_top = FRAME_INSET + pad.y
	wood_frame_inner.offset_right = -(FRAME_INSET + pad.z)
	wood_frame_inner.offset_bottom = -(FRAME_INSET + pad.w)


func _safe_area_pads() -> Vector4:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0:
		return Vector4.ZERO
	var safe := DisplayServer.window_get_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	var viewport_size := get_viewport().get_visible_rect().size
	var sx := viewport_size.x / window_size.x
	var sy := viewport_size.y / window_size.y
	return Vector4(
		maxf(0.0, float(safe.position.x) * sx),
		maxf(0.0, float(safe.position.y) * sy),
		maxf(0.0, float(window_size.x - safe.end.x) * sx),
		maxf(0.0, float(window_size.y - safe.end.y) * sy)
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED or what == NOTIFICATION_APPLICATION_RESUMED:
		if is_node_ready():
			_apply_safe_area()


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


## Prompt 3.3's own "Active enchantments are shown as small icons near
## the top": rebuilt fully from GameState.active_enchantments every
## refresh, the same "just redraw from state" approach the preview strip
## already uses, rather than tracking per-enchantment nodes by hand.
## Elemental Surge never appears here: it applies itself immediately
## through the existing Chopper element badge instead of lingering in
## active_enchantments (see GameState._grant_random_enchantment()).
func _refresh_enchantment_icons() -> void:
	for child in enchantment_icons.get_children():
		child.queue_free()
	for enchantment in GameState.active_enchantments:
		var label := Label.new()
		label.text = _enchantment_short_tag(enchantment)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", _enchantment_color(enchantment.kind))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		enchantment_icons.add_child(label)


func _enchantment_short_tag(enchantment: EnchantmentData) -> String:
	match enchantment.kind:
		EnchantmentData.Kind.EMPOWERED:
			return "Empowered x%d" % enchantment.remaining_trees
		EnchantmentData.Kind.GOLD_RUSH:
			return "Gold Rush"
		EnchantmentData.Kind.AUTO_BOOST:
			return "Boost %ds" % maxi(0, int(ceil(enchantment.remaining_seconds)))
		_:
			return enchantment.description


func _enchantment_color(kind: EnchantmentData.Kind) -> Color:
	match kind:
		EnchantmentData.Kind.EMPOWERED:
			return Color(1, 0.7, 0.3, 1)
		EnchantmentData.Kind.GOLD_RUSH:
			return Color(1, 0.86, 0.2, 1)
		EnchantmentData.Kind.AUTO_BOOST:
			return Color(0.55, 0.85, 1, 1)
		_:
			return Color(1, 1, 1, 1)


## Prompt 3.3's own "clear popup or banner the player can read and then
## dismiss": reads as auto-dismissing here (fades in, holds, fades out)
## rather than requiring a tap, so it never blocks the tap-to-chop loop
## the whole game is built around.
func _show_enchantment_banner(enchantment: EnchantmentData) -> void:
	enchantment_banner_text.text = "Enchantment: " + enchantment.description
	if _enchantment_banner_tween and _enchantment_banner_tween.is_valid():
		_enchantment_banner_tween.kill()
	enchantment_banner.modulate.a = 0.0
	_enchantment_banner_tween = create_tween()
	_enchantment_banner_tween.tween_property(enchantment_banner, "modulate:a", 1.0, 0.25)
	_enchantment_banner_tween.tween_interval(2.5)
	_enchantment_banner_tween.tween_property(enchantment_banner, "modulate:a", 0.0, 0.4)


func _refresh_previews() -> void:
	var cards := preview_row.get_children()
	for i in cards.size():
		if i < GameState.upcoming_trees.size() and cards[i].has_method("set_preview"):
			cards[i].set_preview(GameState.upcoming_trees[i])


## Prompt 4.1's own "proper multi-frame axe swing (anticipation -> hit ->
## recovery)": there is still no real swing spritesheet on disk (the only
## other Chopper art, chopper-axe.png, turned out to be a full concept-art
## illustration on its own background, not an isolated axe or animation
## frames, so it is not usable here). This is the tween-only version that
## note already flagged, now genuinely multi-stage instead of Prompt 2.2's
## rotation-only version: anticipation (lean back + wind-up scale) -> hit
## (a sharp forward rotation with an impact scale-squash, together) -> a
## brief overshoot -> eased recovery back to rest. Rotation and scale
## only, deliberately: chopper_sprite is a container-managed child
## (ChopperColumn, a VBoxContainer), so animating its own .position would
## risk being silently overwritten by the next container layout pass;
## rotation/scale are never touched by container layout, unlike position.
func _play_axe_swing() -> void:
	if _swing_tween and _swing_tween.is_valid():
		_swing_tween.kill()
	chopper_sprite.rotation = 0.0
	chopper_sprite.scale = Vector2.ONE
	_swing_tween = create_tween()

	# Anticipation: wind up.
	_swing_tween.tween_property(chopper_sprite, "rotation", -0.24, 0.09) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_swing_tween.parallel().tween_property(chopper_sprite, "scale", Vector2(1.06, 0.94), 0.09) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Hit: a sharp forward rotation and an impact squash together.
	_swing_tween.tween_property(chopper_sprite, "rotation", 0.42, 0.06) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_swing_tween.parallel().tween_property(chopper_sprite, "scale", Vector2(0.92, 1.08), 0.06) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Recovery: ease everything back to rest, with a touch of overshoot.
	_swing_tween.tween_property(chopper_sprite, "rotation", 0.0, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_swing_tween.parallel().tween_property(chopper_sprite, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Prompt 4.1's own "tree shakes on every hit," distinct from the
## tree-fall animation (a kill) and from the whole-screen _shake() below:
## a quick small rotation wobble on tree_sprite itself.
func _shake_tree() -> void:
	if _tree_shake_tween and _tree_shake_tween.is_valid():
		_tree_shake_tween.kill()
	tree_sprite.rotation = 0.0
	_tree_shake_tween = create_tween()
	_tree_shake_tween.tween_property(tree_sprite, "rotation", deg_to_rad(-4.0), 0.04)
	_tree_shake_tween.tween_property(tree_sprite, "rotation", deg_to_rad(3.0), 0.05)
	_tree_shake_tween.tween_property(tree_sprite, "rotation", 0.0, 0.06)


## Tree topples over and fades, then pops back to neutral for whatever
## tree GameState just advanced current_tree to (there is only one tree
## texture, so a plain reset reads as "the next tree" with no extra art).
func _play_tree_fall() -> void:
	if _fall_tween and _fall_tween.is_valid():
		_fall_tween.kill()
	if _tree_shake_tween and _tree_shake_tween.is_valid():
		_tree_shake_tween.kill()
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


## Prompt 4.1's own "leaf and wood-chip particles on hit": each tier now
## fires a matched chip (brown, heavier, falls fast) and leaf (green,
## lighter, drifts and spins via angular_velocity/damping) burst
## together over the tree, instead of Prompt 2.2's single flat-color
## placeholder.
func _burst(chip: CPUParticles2D, leaf: CPUParticles2D) -> void:
	var pos := _tree_center_in_play_inner()
	chip.position = pos
	chip.restart()
	chip.emitting = true
	leaf.position = pos
	leaf.restart()
	leaf.emitting = true


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
