extends StaticBody2D

onready var player = get_tree().get_root().find_node('Player', true, false)
var corners = [Vector2(0, 0), Vector2(9, 9), Vector2(-9, 9), Vector2(9, -9), Vector2(-9, -9)]
var player_corners = [Vector2(0, 0), Vector2(8, 8), Vector2(-8, 8), Vector2(8, -8), Vector2(-8, -8)]
var hit_pos = [] # Temporary
var seen = false

var max_range = 64

func _ready():
	owner.modulate = Color(1, 1, 1, 0)

func _on_end_turn():
	$DelayTimer.start(0.1)

func check_visibility():
	hit_pos = []
#	update()
	if player && is_instance_valid(player):
		if !seen && (global_position.distance_to(player.global_position) <= max_range):
			var space_state = get_world_2d().direct_space_state
			for corner in corners:
				for player_corner in player_corners:
					var intersect_ray = space_state.intersect_ray(global_position + corner, player.global_position + player_corner, [owner, self], collision_mask)
					if intersect_ray && intersect_ray.collider == player:
						seen = true
						$Tween.interpolate_property(owner, 'modulate', Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.25, Tween.TRANS_LINEAR)
						$Tween.start()
						return
					# Temporary
#					hit_pos.append({'start': corner, 'hit': intersect_ray.position})
	else:
		player = get_tree().get_root().find_node('Player', true, false)

# Temporary
#func _draw():
#	for pos in hit_pos:
#		draw_circle((pos.hit - global_position), 1, Color(1.0, .329, .298))
#		draw_line(position + pos.start, (pos.hit - global_position), Color(1.0, .329, .298))


func _on_DelayTimer_timeout():
	check_visibility()
