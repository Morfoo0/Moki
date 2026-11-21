class_name ChoiceView
extends ActivityView
## Elegir una tarjeta. Opcionalmente muestra una tarjeta de enunciado arriba
## (p. ej. la imagen en "¿con qué letra empieza?").


func _build() -> void:
	var column: BoxContainer = centered_box(true)
	if instance.prompt_card != null:
		var prompt := ActivityCard.new()
		prompt.setup(-1, instance.prompt_card, bank, 170)
		prompt.locked = true
		prompt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(prompt)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	var side: float = 180.0 if instance.prompt_card == null else 140.0
	if instance.cards.size() >= 5:
		side = 160.0
	for i in instance.cards.size():
		row.add_child(make_card(i, side))
