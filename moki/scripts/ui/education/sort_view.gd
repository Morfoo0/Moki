class_name SortView
extends ActivityView
## Clasificar tarjetas en cestas. Dos formas, pensadas para preescolares:
## tocar la tarjeta y luego tocar la cesta, o arrastrarla hasta la cesta.

var _selected: int = -1
var _bins: Array[SortBin] = []


func _build() -> void:
	var column: BoxContainer = centered_box(true)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	var side: float = 130.0 if instance.cards.size() <= 5 else 120.0
	if not instance.cards.is_empty() and instance.cards[0].kind == CardData.Kind.GROUP:
		side += 25.0  # grupos de objetos: un poco más grandes para contarlos
	for i in instance.cards.size():
		var card: ActivityCard = make_card(i, side)
		card.draggable = true
		row.add_child(card)
	var bins_row := HBoxContainer.new()
	bins_row.add_theme_constant_override("separation", 80)
	bins_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bins_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(bins_row)
	for b in instance.bins.size():
		var bin := SortBin.new()
		bin.setup(b, instance.bins[b], bank)
		bin.pressed.connect(_on_bin_pressed)
		bin.dropped.connect(func(card_index: int, bin_index: int) -> void: card_placed.emit(card_index, bin_index))
		bins_row.add_child(bin)
		_bins.append(bin)


func get_bin(index: int) -> SortBin:
	return _bins[index] if index >= 0 and index < _bins.size() else null


## Tarjeta bien colocada: se mueve (en pequeño) a su cesta.
func mark_placed(card_index: int, bin_index: int) -> void:
	var card: ActivityCard = get_card(card_index)
	if card == null:
		return
	if _selected == card_index:
		_selected = -1
	card.set_selected(false)
	card.locked = true
	card.modulate.a = 0.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bin: SortBin = get_bin(bin_index)
	if bin != null:
		bin.add_item(card.data)


func _on_card_pressed(index: int) -> void:
	if _selected >= 0 and get_card(_selected) != null:
		get_card(_selected).set_selected(false)
	_selected = -1 if _selected == index else index
	if _selected >= 0:
		get_card(_selected).set_selected(true)
	card_pressed.emit(index)


func _on_bin_pressed(bin_index: int) -> void:
	if _selected < 0:
		return
	# Si la cesta es la equivocada, la tarjeta sigue seleccionada para reintentar.
	card_placed.emit(_selected, bin_index)


func mark_wrong(index: int) -> void:
	var card: ActivityCard = get_card(index)
	if card != null:
		card.shake()
