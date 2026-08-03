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
