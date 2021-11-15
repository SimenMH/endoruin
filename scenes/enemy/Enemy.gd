extends Pawn

onready var parent = get_parent()
onready var player = get_tree().get_root().find_node('Player', true, false)

var health = 3
var view_range = 32
var activity_level = 0.25 # 0.1 > 1.0
var step = 0
var path = []

func _ready():
	$LineOfSight.cast_to.x = view_range
	modulate = Color(1, 1, 1, 0)

func take_damage(value):
	health -= value
	if health <= 0:
		parent.clear_cell(position)
		queue_free()

func _on_end_turn():
	if health != 0:
		var move_direction = pathfind()

		if move_direction:
			var target_position = parent.request_move(self, move_direction)
			if target_position:
				move_to(target_position)
				position = target_position
		elif randf() <= activity_level:
			var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
			directions.shuffle()
			for dir in directions:
				var target_position = parent.request_move(self, dir)
				if target_position:
					move_to(target_position)
					position = target_position
					break

func move_to(target_position):
	var move_direction = (position - target_position).normalized()
	$Pivot.position = move_direction * 16
	$Tween.interpolate_property($Pivot, "position", null, Vector2(), 0.125, Tween.TRANS_LINEAR)
	$Tween.start()

func bump(dir):
	$Tween.interpolate_property($Pivot, "position", dir * 2, Vector2.ZERO, 0.075, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()

func pathfind():
	if player && is_instance_valid(player):
		$LineOfSight.rotation = (global_position.direction_to(player.global_position)).angle()
		if $LineOfSight.get_collider() == player:
			path = get_tree().get_root().find_node('Game', true, false).get_new_path(global_position, player.global_position)
			if path:
				var direction = (path[1] - global_position).normalized()
				step = 2
				return direction
		elif path && step < path.size():
			var direction = (path[step] - global_position).normalized()
			step += 1
			return direction
	else:
		player = get_tree().get_root().find_node('Player', true, false)

func update_visibility(cur_visible):
	if cur_visible:
		$Tween.interpolate_property(self, 'modulate', Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.25, Tween.TRANS_LINEAR)
		$Tween.start()
	else:
		$Tween.interpolate_property(self, 'modulate', Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.25, Tween.TRANS_LINEAR)
		$Tween.start()
