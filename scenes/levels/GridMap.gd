extends TileMap

enum CellType { PLAYER, NPC, ENEMY, INTERACTIVE, WALL }
const CELL_NAMES = ['Player', 'NPC', 'Enemy', 'Interactive', 'Wall']

#func _ready():
#	for child in get_children():
#		set_cellv(world_to_map(child.position), child.type)

func get_cell_pawn(cell, type = CellType.NPC):
	for node in get_children():
		if node.type == type && world_to_map(node.position) == cell:
			return(node)

func request_move(pawn, direction):
	var cell_start = world_to_map(pawn.position)
	var cell_target = cell_start + direction

	var cell_tile_id = get_cellv(cell_target)
	if cell_tile_id == -1:
		set_cellv(cell_target, pawn.type)
		set_cellv(cell_start, -1)
		return map_to_world(cell_target) + cell_size / 2
	
	match pawn.type:
		CellType.PLAYER:
			player_action(pawn, direction, cell_tile_id, cell_target)
		CellType.ENEMY:
			enemy_action(pawn, direction, cell_tile_id, cell_target)

func player_action(pawn, direction, cell_type, cell_target):
	match cell_type:
		CellType.ENEMY:
			var target_pawn = get_cell_pawn(cell_target, cell_type)
			if target_pawn:
				if target_pawn.has_method('take_damage'):
					target_pawn.take_damage(1)
				pawn.bump(direction)
		CellType.INTERACTIVE:
			var target_pawn = get_cell_pawn(cell_target, cell_type)
			if target_pawn:
				if target_pawn.has_method('on_interact'):
					target_pawn.on_interact()
				pawn.bump(direction)

func enemy_action(pawn, direction, cell_type, cell_target):
	match cell_type:
		CellType.PLAYER:
			var target_player = get_cell_pawn(cell_target, cell_type)
			if target_player:
				target_player.take_damage(1)
				pawn.bump(direction)

func clear_cell(cell_position):
	set_cellv(world_to_map(cell_position), -1)


func next_turn():
	get_tree().call_group('end_turn', '_on_end_turn')
