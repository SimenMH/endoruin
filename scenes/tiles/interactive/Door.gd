extends Pawn

onready var grid = get_parent()

enum Status { CLOSED, OPEN }


func on_interact():
	grid.clear_cell(global_position)
	$Sprite.frame = Status.OPEN
	$CollisionShape2D.disabled = true
