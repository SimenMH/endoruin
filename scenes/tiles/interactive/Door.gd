extends Pawn

func on_interact():
#	if randf() > 0.5:
	get_parent().clear_cell(global_position)
	queue_free()
