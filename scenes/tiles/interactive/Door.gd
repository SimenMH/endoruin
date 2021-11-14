extends Pawn

onready var grid = get_parent()

func on_interact():
	grid.clear_cell(global_position)
	$DoorClosed.visible = false
	$CollisionShape2D.disabled = true
