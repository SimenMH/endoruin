extends Pawn

onready var stats = PlayerData.stats
onready var parent = get_parent()
onready var inventory = $CanvasLayer/GUI/Inventory

var is_active = true
var dir_input = Vector2()
var prev_dir = Vector2()
var interactive = null

var health_regen = 3
var regen_count = 0

func _ready():
	GameData.player_node = self
	update_player_stats()

func _process(_delta):
	get_player_input()
	update_gui()

func update_gui():
	$CanvasLayer/GUI/Health.text = 'Health: ' + str(stats.health) + '/' + str(stats.max_health)
	$CanvasLayer/GUI/Armour.text = str(stats.armour)

func end_turn():
	regen_count += 1
	if regen_count >= health_regen:
		stats.health = min(stats.health + 1, stats.max_health)
		regen_count = 0
	$TurnTimer.start()
	parent.next_turn()

func get_player_input():
	if Input.is_action_just_pressed('open_inventory'):
		inventory.visible = !inventory.visible
		is_active = !inventory.visible
	
	if $TurnTimer.is_stopped() && is_active:
		get_player_action()

func get_player_action():
	var input_direction = get_input_direction()
	if Input.is_action_pressed('wait'):
		end_turn()
	elif interactive && Input.is_action_pressed('interact'):
		interactive.on_interact()
		end_turn()
	elif input_direction:
		var target_position = parent.request_move(self, input_direction)
		if target_position:
			move_to(target_position)
		end_turn()

func get_input_direction():
	var new_dir = Vector2.ZERO
	var x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y_input = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	# If input has not changed
	if (Vector2(x_input, y_input) == dir_input):
		new_dir = prev_dir
	# Else if only one or neither direction is being pressed
	elif (x_input == 0 || y_input == 0):
		new_dir = Vector2(x_input, y_input)
	# Else check which key was pressed last
	else:
		var x_changed = x_input != dir_input.x
		var y_changed = y_input != dir_input.y
		
		if x_changed:
			new_dir = Vector2(x_input, 0)
		elif y_changed:
			new_dir = Vector2(0, y_input)
	
	dir_input = Vector2(x_input, y_input)
	prev_dir = new_dir
	return new_dir

func move_to(target_position):
	var move_direction = (position - target_position).normalized()
	$Pivot.position = move_direction * 16
	$Tween.interpolate_property($Pivot, "position", null, Vector2.ZERO, 0.125, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	position = target_position

func bump(dir):
	$Tween.interpolate_property($Pivot, "position", dir * 2, Vector2.ZERO, 0.075, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()

func take_damage(value):
	if value != 0:
		var damage_reduction = 1 - (stats.armour / (stats.armour + 20))
		var damage = round(value * damage_reduction)
		if damage == 0:
			print('Attack grazed')
		else:
			stats.health -= damage

func pickup_item(item):
	return inventory.add_to_inventory2(item)

func _on_Interact_area_entered(area):
	interactive = area

func _on_Interact_area_exited(area):
	if interactive == area:
		interactive = null

func update_player_stats():
	var equipment = PlayerData.equipment
	var armour = 0
	for key in equipment:
		if equipment[key] && equipment[key].has('armour'):
			armour += equipment[key].armour
	PlayerData.stats.armour = armour
