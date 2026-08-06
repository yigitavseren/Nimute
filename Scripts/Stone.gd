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
		base_color = Color(1, 1, 1) # Çizimin kendi renklerini koru
		self.self_modulate = Color(1, 1, 1, 0)
		$Icon.texture = load("res://Assets/bomb.png")
		$Icon.scale = Vector2(1.0, 1.0)
		$Icon.position = Vector2(0, 0)
	elif type == "lily_pad":
		base_color = Color(1, 1, 1)
		self.self_modulate = Color(1, 1, 1, 0)
		$Icon.texture = load("res://Assets/lily_pad.png")
		$Icon.scale = Vector2(1.0, 1.0)
		$Icon.position = Vector2(0, 0)
	elif type == "armored":
		base_color = Color(1, 1, 1)
		self.self_modulate = Color(1, 1, 1, 0)
		$Icon.texture = load("res://Assets/armored.png")
		$Icon.scale = Vector2(1.0, 1.0)
		$Icon.position = Vector2(0, 0)
	elif type == "lifebuoy":
		base_color = Color(1, 1, 1) 
		self.self_modulate = Color(1, 1, 1, 0)
		$Icon.texture = load("res://Assets/lifebuoy_transparent.png")
		$Icon.scale = Vector2(1.8, 1.8)
		$Icon.position = Vector2(-17.6, -17.6) # Centering the scaled up icon
	elif type == "piranha":
		var tex = load("res://Assets/piranha.png")
		if tex:
			base_color = Color(1, 1, 1)
			self.self_modulate = Color(1, 1, 1, 0) # Resim varsa arkaplanı gizle
			$Icon.texture = tex
			$Icon.scale = Vector2(1.7, 1.7)
			$Icon.position = Vector2(-15.4, -15.4) 
			self.text = ""
		else:
			# Resim henüz eklenmediyse geçici siyah renk ve text göster
			base_color = Color(0.1, 0.1, 0.1)
			self.self_modulate = Color(0.1, 0.1, 0.1, 1)
			$Icon.texture = null
			self.text = ">:<"
	else:
		base_color = Color(1, 1, 1)
		self.self_modulate = Color(1, 1, 1, 1)
		$Icon.texture = null
		$Icon.scale = Vector2(1.0, 1.0)
		$Icon.position = Vector2(0, 0)
		self.text = ""
	
	modulate = base_color

