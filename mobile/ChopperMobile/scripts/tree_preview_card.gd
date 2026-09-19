extends PanelContainer

@onready var icon: TextureRect = %Icon
@onready var element_swatch: ColorRect = %ElementSwatch
@onready var element_label: Label = %ElementLabel
@onready var difficulty_label: Label = %DifficultyLabel


func set_preview(tree: TreeData) -> void:
	var tint := GameState.element_color(tree.element)
	icon.modulate = tint.lightened(0.15)
	element_swatch.color = tint
	element_label.text = GameState.element_display_name(tree.element)
	var stars: int = clampi(tree.difficulty, 1, 3)
	difficulty_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
