extends Node2D


func on_interact():
	get_tree().call_group('game', 'start_game')
