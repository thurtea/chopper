class_name ChopperData
extends Resource

## Player combat stats for the current run.

@export var axe_damage: int = 1
@export var auto_chop_rate: float = 0.0
@export var active_element: TreeData.Element = TreeData.Element.NONE
@export var selected_element: TreeData.Element = TreeData.Element.NONE
@export var prestige_multiplier: float = 1.0
@export var element_trees_remaining: int = 0


func has_element_power() -> bool:
	return active_element != TreeData.Element.NONE and element_trees_remaining > 0
