extends StaticBody2D

onready var player = get_tree().get_root().find_node('Player', true, false)
var corners = [Vector2(0, 0), Vector2(7, 7), Vector2(-7, 7), Vector2(7, -7), Vector2(-7, -7)]
var player_corners = [Vector2(0, 0)] #, Vector2(8, 8), Vector2(-8, 8), Vector2(8, -8), Vector2(-8, -8)]
var seen = false

var max_range = 48

func _on_end_turn():
	$DelayTimer.start(0.1)

func check_visibility():
	if player && is_instance_valid(player):
		if (global_position.distance_to(player.global_position) <= max_range):
			var space_state = get_world_2d().direct_space_state
			for corner in corners:
				for player_corner in player_corners:
					var intersect_ray = space_state.intersect_ray(global_position + corner, player.global_position + player_corner, [owner, self], collision_mask)
					if intersect_ray && intersect_ray.collider == player:
						if !seen:
							owner.update_visibility(true)
							seen = true
						return
		if seen:
			owner.update_visibility(false)
			seen = false
		return
	else:
		player = get_tree().get_root().find_node('Player', true, false)

func _on_DelayTimer_timeout():
	check_visibility()
