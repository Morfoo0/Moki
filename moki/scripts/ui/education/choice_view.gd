class_name ChoiceView
extends ActivityView
## Elegir una tarjeta. Opcionalmente muestra una tarjeta de enunciado arriba
## (p. ej. la imagen en "¿con qué letra empieza?", el grupo que hay que contar
## o la fila de números con un hueco).

const WIDE_PROMPT_WIDTH: float = 560.0


func _build() -> void:
	var column: BoxContainer = centered_box(true)
	var group_options: bool = not instance.cards.is_empty() and (instance.cards[0].kind == CardData.Kind.GROUP
		or instance.cards[0].kind == CardData.Kind.COLLECTION)
	if instance.prompt_card != null:
		var prompt := ActivityCard.new()
		if instance.prompt_card.wide:
			# Apaisada: grupos de hasta 10 objetos o filas de números.
			var tall: bool = instance.prompt_card.kind == CardData.Kind.GROUP or instance.prompt_card.kind == CardData.Kind.COLLECTION
			var height: float = 190.0 if tall else 150.0
			prompt.setup(-1, instance.prompt_card, bank, height, WIDE_PROMPT_WIDTH)
		else:
			prompt.setup(-1, instance.prompt_card, bank, 120.0 if group_options else 170.0)
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
	if group_options:
		# Grupos grandes para que se puedan contar sin esfuerzo.
		side = 220.0 if instance.prompt_card != null else 240.0
	for i in instance.cards.size():
		row.add_child(make_card(i, side))
