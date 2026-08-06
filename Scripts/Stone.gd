extends Button

signal stone_clicked(row_index, col_index, stone_node)

var row_index : int = -1
var col_index : int = 0
var is_selected : bool = false
var base_color : Color = Color(1, 1, 1)

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	emit_signal("stone_clicked", row_index, col_index, self)

func select():
	is_selected = true
	modulate = Color(0.8, 0.2, 0.2) # Karanlık kırmızı (seçili)

func deselect():
	is_selected = false
	modulate = base_color # Normal

func set_type(type: String):
	if type == "bomb":
		base_color = Color(0.2, 0.2, 0.2)
		self.self_modulate = Color(1, 1, 1, 0)
		$Icon.texture = load("res://Assets/bomb.png")
	elif type == "lily_pad":
		base_color = Color(0.1, 0.8, 0.2)
		self.self_modulate = Color(1, 1, 1, 0)
		$Icon.texture = load("res://Assets/lily_pad.png")
	elif type == "armored":
		base_color = Color(0.6, 0.2, 0.8)
		self.self_modulate = Color(1, 1, 1, 0)
		$Icon.texture = load("res://Assets/armored.png")
	else:
		base_color = Color(1, 1, 1)
		self.self_modulate = Color(1, 1, 1, 1)
		$Icon.texture = null
	
	modulate = base_color

