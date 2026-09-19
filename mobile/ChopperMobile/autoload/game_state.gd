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
