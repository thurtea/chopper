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


func _ready() -> void:
	GameState.stats_changed.connect(_refresh_ui)
	_refresh_ui()


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
