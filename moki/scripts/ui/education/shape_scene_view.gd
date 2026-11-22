class_name ShapeSceneView
extends ActivityView
## Dibujo compuesto de figuras (vista SCENE): cada parte es una tarjeta sin
## marco colocada en su sitio del lienzo, en orden de dibujo. Se toca solo
## dentro de la figura; si dos partes se tocan, gana la de encima.


func _build() -> void:
	var column: BoxContainer = centered_box(true)
	var frame := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.99, 0.95)
	style.border_color = ActivityCard.BORDER
	style.set_border_width_all(5)
	style.set_corner_radius_all(24)
	style.set_content_margin_all(8)
	frame.add_theme_stylebox_override("panel", style)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(frame)
	var canvas := Control.new()
	canvas.custom_minimum_size = ShapeScenes.CANVAS
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(canvas)
	for i in instance.cards.size():
		var part: CardData = instance.cards[i]
		var card := ActivityCard.new()
		card.setup(i, part, bank, part.area.size.y, part.area.size.x)
		card.make_frameless()
		card.position = part.area.position
		card.size = part.area.size
		card.pressed.connect(_on_card_pressed)
		cards.append(card)
		canvas.add_child(card)
