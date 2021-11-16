extends Node2D

var level = Rect2()
var level_sections = []
var min_section_size = 5
var max_section_size = 11 # Must be at least double the size of min section size
var min_room_size = 4
var max_room_size = 8
var rooms = []
var doors = []

enum CellType { ROOM_WALL, ROOM_FLOOR, DOOR, DUNGEON_WALL, DUNGEON_FLOOR, SPAWN, EXIT, ENEMY, PATHING_TILE, ITEM }

onready var navmap = $WalkerNav
onready var walker = $WalkerNav/Walker
onready var level_tilemap = $WalkerNav/GeneratedLevel
onready var spawn_tilemap = $Spawns

#func _ready():
#	randomize()

func _process(_delta):
	if Input.is_action_just_pressed('ui_select'):
		generate(16)
	if Input.is_action_just_pressed('ui_accept'):
		spawn_tilemap.clear()
		create_spawn_and_exit()
		spawn_enemies()

func generate(size):
	navmap = $WalkerNav
	walker = $WalkerNav/Walker
	level_tilemap = $WalkerNav/GeneratedLevel
	spawn_tilemap = $Spawns
	level_tilemap.clear()
	spawn_tilemap.clear()
	draw_size(size)
	
	generate_sections(size)
	level_tilemap.clear()
	
	if generate_rooms() == 'ERROR':
		return generate(size)
	
	add_nav_tiles()
	level_tilemap.update_dirty_quadrants()
	
	if generate_pathways() == 'ERROR':
		return generate(size)
	
	create_spawn_and_exit()
	spawn_enemies()
	spawn_items()
	
	return {'level': level_tilemap, 'spawns': spawn_tilemap, 'CellType': CellType}

func generate_sections(size):
	level = Rect2(0, 0, size, size)
	level_sections = []
	
	var splitting_arr = [level]
	
	while (splitting_arr.size() > 0):
		var new_arr = []
		for section in splitting_arr:
			if (section.size.x > max_section_size || section.size.y > max_section_size) || randf() > 0.25:
				var dir = ['x', 'y']
				dir.shuffle()
				if !(section.size[dir[0]] > min_section_size * 2):
					dir.pop_front()
				if (section.size[dir[0]] > min_section_size * 2):
					var split_pos = round(rand_range(min_section_size, section.size[dir[0]] - min_section_size + 1))
					var new_section_1 = Rect2()
					new_section_1.position = section.position
					new_section_1.size = section.size
					new_section_1.size[dir[0]] = split_pos
					var new_section_2 = Rect2()
					new_section_2.position = section.position
					new_section_2.size = section.size
					new_section_2.position[dir[0]] += split_pos - 1
					new_section_2.end[dir[0]] = section.end[dir[0]]
					new_arr.append_array([new_section_1, new_section_2])
				else:
					level_sections.append(section)
			else:
				level_sections.append(section)
		splitting_arr = new_arr
	
	draw_sections()

func draw_size(size):
	level_tilemap.clear()
	var rect = Rect2(0, 0, size, size)
	for y in range(rect.end.y - rect.position.y):
		for x in range(rect.end.x - rect.position.x):
			level_tilemap.set_cell(rect.position.x + x, rect.position.y + y, CellType.ROOM_WALL)

func draw_sections():
	level_tilemap.clear()
	for section in level_sections:
		for y in range(section.end.y - section.position.y):
			for x in range(section.end.x - section.position.x):
				if y == 0 || x == 0 || y == section.size.y - 1 || x == section.size.x - 1:
					level_tilemap.set_cell(section.position.x + x, section.position.y + y, CellType.ROOM_WALL)
				else:
					level_tilemap.set_cell(section.position.x + x, section.position.y + y, CellType.ROOM_FLOOR)

func generate_rooms():
	level_sections.shuffle()
	rooms = []
	doors = []
	for borders in level_sections:
		if rooms.size() > ceil(level_sections.size() / 4):
			if randf() < float(rooms.size()) / float(level_sections.size()):
				break
		var width = round(rand_range(min_room_size, min(borders.size.x, max_room_size)))
		var height = round(rand_range(min_room_size, min(borders.size.y, max_room_size)))
		
		var pos = Vector2(
			round(rand_range(borders.position.x, borders.end.x - width)),
			round(rand_range(borders.position.y, borders.end.y - height))
		)
		
		var new_room = Rect2(pos, Vector2(width, height))
		
		rooms.append(new_room)
	
	for room in rooms:
		for y in range(room.end.y - room.position.y):
			for x in range(room.end.x - room.position.x):
				if y == 0 || x == 0 || y == room.size.y - 1 || x == room.size.x - 1:
					level_tilemap.set_cell(room.position.x + x, room.position.y + y, CellType.ROOM_WALL)
				else:
					level_tilemap.set_cell(room.position.x + x, room.position.y + y, CellType.ROOM_FLOOR)
		
	# Set doors
	for room in rooms:
		var door_pos = find_door_position(room)
		if door_pos != null:
			level_tilemap.set_cellv(door_pos, CellType.DOOR)
			doors.append(door_pos)
		else:
			return 'ERROR'

func find_door_position(room):
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	directions.shuffle()
	for direction in directions:
		var new_pos
		
		match direction:
			Vector2.UP:
				var tiles = range(room.position.x + 1, room.end.x - 1)
				tiles.shuffle()
				for x in tiles:
					new_pos = Vector2(x, room.position.y)
			Vector2.DOWN:
				var tiles = range(room.position.x + 1, room.end.x - 1)
				tiles.shuffle()
				for x in tiles:
					new_pos = Vector2(x, room.end.y - 1)
			Vector2.LEFT:
				var tiles = range(room.position.y + 1, room.end.y - 1)
				tiles.shuffle()
				for y in tiles:
					new_pos = Vector2(room.position.x, y)
			Vector2.RIGHT:
				var tiles = range(room.position.y + 1, room.end.y - 1)
				tiles.shuffle()
				for y in tiles:
					new_pos = Vector2(room.end.x - 1, y)
		
		if new_pos != null:
			if (level_tilemap.get_cellv(new_pos + direction) == -1):
				if ((new_pos + direction).x >= level.position.x && (new_pos + direction).y >= level.position.y &&
					(new_pos + direction).x <= level.end.x && (new_pos + direction).y <= level.end.y
				):
					return new_pos

func add_nav_tiles():
	for y in range(level.position.y, level.end.y + 1):
		for x in range(level.position.x, level.end.x + 1):
			if level_tilemap.get_cell(x, y) == -1:
				level_tilemap.set_cell(x, y, CellType.PATHING_TILE)
	return true

func generate_pathways():
	walker.position = level_tilemap.map_to_world(doors[0]) + level_tilemap.cell_size / 2


	var i = 1
	while (i < doors.size()):
		var door_pos = level_tilemap.map_to_world(doors[i]) + level_tilemap.cell_size / 2
		var new_path = navmap.get_simple_path(walker.global_position, door_pos, false)
		if new_path:
			var dir = (new_path[1] - walker.global_position).normalized()
			var start = level_tilemap.world_to_map(walker.position)
			var target = start + dir
			if level_tilemap.get_cellv(start) == CellType.DUNGEON_WALL || level_tilemap.get_cellv(start) == CellType.PATHING_TILE:
				level_tilemap.set_cellv(start, CellType.DUNGEON_FLOOR)
			var arr = [-1, 0, 1]
			for x in arr:
				for y in arr:
					var cur_cell = target + Vector2(x, y)
					if (level_tilemap.get_cellv(cur_cell) == CellType.PATHING_TILE
					|| level_tilemap.get_cellv(cur_cell) == -1):
						level_tilemap.set_cellv(cur_cell, CellType.DUNGEON_WALL)
			walker.position = level_tilemap.map_to_world(target) + level_tilemap.cell_size / 2
			if walker.global_position.distance_to(door_pos) < 16:
				i += 1
		else:
			return 'ERROR'
	
	
	var new_point = Vector2(round(rand_range(1, level.end.x)), round(rand_range(1, level.end.y)))
	var times_ran = 0
	i = 0
	while i < level.size.x:
		times_ran += 1
		var point_pos = level_tilemap.map_to_world(new_point) + level_tilemap.cell_size / 2
		var new_path = navmap.get_simple_path(walker.global_position, point_pos, false)
		if (level_tilemap.get_cellv(new_point) != -1 || level_tilemap.get_cellv(new_point) != CellType.ROOM_WALL):
			if new_path:
				var dir = (new_path[1] - walker.global_position).normalized()
				var start = level_tilemap.world_to_map(walker.position)
				var target = start + dir
				if (level_tilemap.get_cellv(target) != -1 || level_tilemap.get_cellv(target) != CellType.ROOM_WALL):
					if level_tilemap.get_cellv(target) == CellType.DUNGEON_WALL || level_tilemap.get_cellv(target) == CellType.PATHING_TILE:
						level_tilemap.set_cellv(target, CellType.DUNGEON_FLOOR)
					var arr = [-1, 0, 1]
					for x in arr:
						for y in arr:
							var cur_cell = target + Vector2(x, y)
							if (level_tilemap.get_cellv(cur_cell) == CellType.PATHING_TILE
							|| level_tilemap.get_cellv(cur_cell) == -1):
								level_tilemap.set_cellv(cur_cell, CellType.DUNGEON_WALL)
					walker.position = level_tilemap.map_to_world(target) + level_tilemap.cell_size / 2
					if walker.global_position.distance_to(point_pos) <= 16:
						new_point = Vector2(round(rand_range(0, level.size.x)), round(rand_range(0, level.size.y)))
						i += 1
						times_ran = 0
			else:
				new_point = Vector2(round(rand_range(0, level.size.x)), round(rand_range(0, level.size.y)))
				i += 1
				times_ran = 0
		else:
			new_point = Vector2(round(rand_range(0, level.size.x)), round(rand_range(0, level.size.y)))
			i += 1
			times_ran = 0
		if times_ran >= 9000:
			return 'ERROR'

func create_spawn_and_exit():
	var spawn_room = rooms[0]
	var exit_room = rooms[rooms.size()-1]
	var spawn_pos = Vector2(spawn_room.position.x + 1, spawn_room.position.y + 1)
	var exit_pos = Vector2(exit_room.position.x + 1, exit_room.position.y + 1)
	
	spawn_tilemap.set_cellv(spawn_pos, CellType.SPAWN)
	spawn_tilemap.set_cellv(exit_pos, CellType.EXIT)

func spawn_enemies():
	var dungeon_floor = level_tilemap.get_used_cells_by_id(4)
	dungeon_floor.shuffle()
	
	# TODO: Calculate proper enemy amount based on level size
	var enemy_amount = min(floor(rand_range(5, 10)), dungeon_floor.size() - 1)
	var enemy_locations = dungeon_floor.slice(0, enemy_amount)
	
	for pos in enemy_locations:
		spawn_tilemap.set_cellv(pos, CellType.ENEMY)

func spawn_items():
	var dungeon_floor = level_tilemap.get_used_cells_by_id(4)
	dungeon_floor.shuffle()
	
	# TODO: Calculate proper item amount based on level size
	var dungeon_item_amount = min(floor(rand_range(0, 6)), dungeon_floor.size() - 1)
	var item_locations = dungeon_floor.slice(0, dungeon_item_amount)

	# Get room floor locations
	for room in rooms:
		if randf() > 0.5:
			var room_item_amount = floor(rand_range(1, 2))
			var floor_positions = []
			for y in range(room.end.y - room.position.y):
				for x in range(room.end.x - room.position.x):
					if y != 0 && x != 0 && y != room.size.y - 1 && x != room.size.x - 1:
						floor_positions.append(Vector2(room.position.x + x, room.position.y + y))
			floor_positions.shuffle()
			item_locations += floor_positions.slice(0, room_item_amount)
	
	for pos in item_locations:
		if spawn_tilemap.get_cellv(pos) == -1:
			spawn_tilemap.set_cellv(pos, CellType.ITEM)
