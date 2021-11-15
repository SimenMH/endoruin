extends Node2D

export(PackedScene) var level_generator

enum CellType { PLAYER, NPC, ENEMY, INTERACTIVE, WALL }

onready var tilemap = $Navigation2D/TileMap
onready var gridmap = $Navigation2D/GridMap

var tilemap_scene = preload('res://scenes/levels/TileMap.tscn')
var gridmap_scene = preload('res://scenes/levels/GridMap.tscn')
var player = preload('res://scenes/player/Player.tscn')
var enemy = preload('res://scenes/enemy/Enemy.tscn')
var door = preload('res://scenes/tiles/interactive/Door.tscn')
var exit = preload('res://scenes/tiles/interactive/Exit.tscn')
var dungeon_wall = preload('res://scenes/tiles/terrain/DungeonWall.tscn')
var dungeon_floor = preload('res://scenes/tiles/terrain/DungeonFloor.tscn')
var room_wall = preload('res://scenes/tiles/terrain/RoomWall.tscn')
var room_floor = preload('res://scenes/tiles/terrain/RoomFloor.tscn')

func _physics_process(_delta):
	if Input.is_action_just_pressed('ui_select'):
		start_game()

func start_game():
	if tilemap:
		tilemap.queue_free()
	if gridmap:
		gridmap.queue_free()
	var generator_instance = level_generator.instance()
	generator_instance.visible = false
	add_child(generator_instance)
	var new_level = generator_instance.generate(16)
	render_level(new_level)
	
	# TODO: Move this queue_free to bottom of render_level function
	yield(get_tree().create_timer(0.1), "timeout")
	generator_instance.queue_free()

func render_level(level):
	# Create Tilemaps
	tilemap = tilemap_scene.instance()
	gridmap = gridmap_scene.instance()
	$Navigation2D.add_child(tilemap)
	$Navigation2D.add_child(gridmap)

	# Spawn Player
	var spawn = level.spawns.get_used_cells_by_id(level.CellType.SPAWN)[0]
	var new_player = player.instance()
	new_player.position = gridmap.map_to_world(spawn) + gridmap.cell_size / 2
	gridmap.add_child(new_player)
	gridmap.set_cellv(spawn, CellType.PLAYER)
	
	# Create Walls
	for tile in level.level.get_used_cells_by_id(level.CellType.ROOM_WALL):
		var new_wall = room_wall.instance()
		new_wall.position = gridmap.map_to_world(tile) + gridmap.cell_size / 2
		gridmap.add_child(new_wall)
		gridmap.set_cellv(tile, CellType.WALL)
	for tile in level.level.get_used_cells_by_id(level.CellType.DUNGEON_WALL):
		var new_wall = dungeon_wall.instance()
		new_wall.position = gridmap.map_to_world(tile) + gridmap.cell_size / 2
		gridmap.add_child(new_wall)
		gridmap.set_cellv(tile, CellType.WALL)
	
	# Create Floor
	for tile in level.level.get_used_cells_by_id(level.CellType.DUNGEON_FLOOR):
		var new_floor = dungeon_floor.instance()
		new_floor.position = tilemap.map_to_world(tile) + tilemap.cell_size / 2
		tilemap.add_child(new_floor)
		tilemap.set_cellv(tile, 11)
	for tile in level.level.get_used_cells_by_id(level.CellType.ROOM_FLOOR):
		var new_floor = room_floor.instance()
		new_floor.position = tilemap.map_to_world(tile) + gridmap.cell_size / 2
		tilemap.add_child(new_floor)
		tilemap.set_cellv(tile, 11)
	
	# Create Doors
	for tile in level.level.get_used_cells_by_id(level.CellType.DOOR):
		var new_door = door.instance()
		new_door.position = gridmap.map_to_world(tile) + gridmap.cell_size / 2
		gridmap.add_child(new_door)
		gridmap.set_cellv(tile, CellType.INTERACTIVE)
		tilemap.set_cellv(tile, 11)
	
	# Spawn Enemies
	for tile in level.spawns.get_used_cells_by_id(level.CellType.ENEMY):
		var new_enemy = enemy.instance()
		new_enemy.position = gridmap.map_to_world(tile) + gridmap.cell_size / 2
		gridmap.add_child(new_enemy)
		gridmap.set_cellv(tile, CellType.ENEMY)
	
	# Spawn Exit
	var exit_pos = level.spawns.get_used_cells_by_id(level.CellType.EXIT)[0]
	var new_exit = exit.instance()
	new_exit.position = gridmap.map_to_world(exit_pos) + gridmap.cell_size / 2
	tilemap.add_child(new_exit)
	tilemap.set_cellv(exit_pos, 11)
	
	get_tree().call_group('end_turn', '_on_end_turn')

func get_new_path(start, end):
	var new_path = $Navigation2D.get_simple_path(start, end, false)
	if new_path:
		$Line2D.points = new_path
		return new_path
