class_name InventorySlot
extends Control
## Casilla de un objeto del inventario. Se toca para seleccionarla o se
## arrastra hacia Chibbi. Muestra la cantidad si el objeto no es ilimitado.

signal pressed(item_id: StringName)

const DRAG_TYPE: String = "inventory_item"
const SLOT_COLOR: Color = Color(1, 0.98, 0.93)
const BORDER_COLOR: Color = Color(0.96, 0.73, 0.45)
const SELECTED_COLOR: Color = Color("#FF6B6B")

var item: ItemDefinition

var _selected: bool = false
var _available: bool = true
var _press_inside: bool = false
var _style := StyleBoxFlat.new()

@onready var _background: Panel = %Background
@onready var _icon: ItemIcon = %Icon
@onready var _count: Label = %Count


func _ready() -> void:
	_style.bg_color = SLOT_COLOR
	_style.set_corner_radius_all(24)
	_background.add_theme_stylebox_override("panel", _style)
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	_refresh_style()


func setup(definition: ItemDefinition) -> void:
	item = definition
	tooltip_text = definition.display_name
	_icon.item = definition


## quantity = Inventory.UNLIMITED (-1) oculta el contador.
func set_quantity(quantity: int) -> void:
	_count.visible = quantity >= 0
	_count.text = str(quantity)
	_available = quantity != 0
	modulate.a = 1.0 if _available else 0.35
	_refresh_style()


func set_selected(selected: bool) -> void:
	_selected = selected
	_refresh_style()
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * (1.1 if selected else 1.0), 0.12)


func is_available() -> bool:
	return _available


## Pequeña sacudida (p. ej. cuando no quedan unidades).
func shake() -> void:
	var tween: Tween = create_tween()
	for offset: float in [-8.0, 8.0, -5.0, 0.0]:
		tween.tween_property(_background, "position:x", offset, 0.05)


func _refresh_style() -> void:
	_style.border_color = SELECTED_COLOR if _selected else BORDER_COLOR
	_style.set_border_width_all(8 if _selected else 4)


func _gui_input(event: InputEvent) -> void:
	# Toque (pulsar y soltar sin arrastrar) = seleccionar.
	var click := event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if click.pressed:
		_press_inside = true
		accept_event()
	elif _press_inside:
		_press_inside = false
		accept_event()
		pressed.emit(item.id)


func _get_drag_data(_at_position: Vector2) -> Variant:
	_press_inside = false
	if item == null:
		return null
	if not _available:
		shake()
		return null
	var preview := Control.new()
	var icon := ItemIcon.new()
	icon.item = item
	icon.size = Vector2(110, 110)
	icon.position = -icon.size / 2.0
	preview.add_child(icon)
	set_drag_preview(preview)
	return {"type": DRAG_TYPE, "item_id": item.id}
