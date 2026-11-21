class_name SortBin
extends PanelContainer
## Cesta de una actividad de clasificar. Se toca (con una tarjeta
## seleccionada) o se le suelta una tarjeta arrastrada.

signal pressed(bin_index: int)
signal dropped(card_index: int, bin_index: int)

var bin_index: int = -1
var _items := HFlowContainer.new()


func setup(index: int, label_card: CardData, bank: ContentBank) -> void:
	bin_index = index
	custom_minimum_size = Vector2(300, 190)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.95, 0.85)
	style.border_color = Color(0.85, 0.55, 0.3)
	style.set_border_width_all(6)
	style.set_corner_radius_all(30)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var title := Label.new()
	title.text = label_card.text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color("#5B3A29"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title)
	_items.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_items.alignment = FlowContainer.ALIGNMENT_CENTER
	column.add_child(_items)
	tooltip_text = label_card.spoken


func add_item(card: CardData) -> void:
	var icon := TextureRect.new()
	icon.texture = card.texture
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_items.add_child(icon)


func item_count() -> int:
	return _items.get_child_count()


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
		accept_event()
		pressed.emit(bin_index)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type") == ActivityCard.DRAG_TYPE


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	dropped.emit(int(data["index"]), bin_index)
