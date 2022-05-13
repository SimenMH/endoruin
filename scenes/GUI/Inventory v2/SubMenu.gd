extends VBoxContainer

var active = false
var selected_index = 0
var options = []

onready var submenu_option = preload('res://scenes/GUI/Inventory v2/SubMenuOption.tscn')

signal select_action

func _ready():
	visible = false

func _process(_delta):
	if active:
		if Input.is_action_just_pressed('ui_up'):
			navigate(-1)
		if Input.is_action_just_pressed('ui_down'):
			navigate(1)
		if Input.is_action_just_pressed('ui_accept'):
			active = false
			visible = false
			emit_signal('select_action', options[selected_index])


func open_submenu(new_options):
	options = new_options
	for n in get_children():
		remove_child(n)
	for option in options:
		var label = submenu_option.instance()
		label.text = option
		self.add_child(label)
	selected_index = 0
	get_child(0).modulate = Color(1, 1, 0.25)
	yield(get_tree(), "idle_frame")
	active = true

func navigate(dir):
	var new_index
	if selected_index == 0 && dir == -1:
		new_index = options.size() - 1
	elif selected_index == options.size() - 1 && dir == 1:
		new_index = 0
	else:
		new_index = selected_index + dir
	var selected_child = get_child(selected_index)
	selected_child.modulate = Color(1,1,1)
	
	var new_selected_child = get_child(new_index)
	new_selected_child.modulate = Color(1,1,0.25)
	
	selected_index = new_index
