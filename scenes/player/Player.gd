extends Pawn

onready var parent = get_parent()

var player_turn = true
var max_health = 25
var health = 25

var dir_input = Vector2()
var prev_dir = Vector2()


var interactive = null

func _ready():
	$CanvasLayer/GUI/Health.text = 'Health: ' + str(health) + '/' + str(max_health)

func _process(_delta):
	var input_direction = get_input_direction()
	if !$TurnTimer.is_stopped(): return
	if Input.is_action_pressed('wait'):
		parent.next_turn()
		$TurnTimer.start()
		return
	if interactive && Input.is_action_pressed('interact'):
		interactive.on_interact()
		return
	if !input_direction: return
	$TurnTimer.start()
	
	var target_position = parent.request_move(self, input_direction)
	if target_position:
		move_to(target_position)
		position = target_position
	parent.next_turn()


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
	$Tween.interpolate_property($Pivot, "position", null, Vector2(), 0.125, Tween.TRANS_LINEAR)
	$Tween.start()

func bump(dir):
	$Tween.interpolate_property($Pivot, "position", dir * 2, Vector2.ZERO, 0.075, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()

func take_damage(value):
	health -= value
	$CanvasLayer/GUI/Health.text = 'Health: ' + str(health) + '/' + str(max_health)


func _on_Interact_area_entered(area):
	interactive = area

func _on_Interact_area_exited(area):
	if interactive == area:
		interactive = null
