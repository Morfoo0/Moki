class_name InventoryBar
extends PanelContainer
## Barra de inventario: una casilla por objeto del catálogo que se muestra en
## el inventario (opcionalmente filtrado por tipo). Objetos nuevos en el
## catálogo aparecen solos. Gestiona qué objeto está seleccionado.

signal selection_changed(item_id: StringName)

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory_slot.tscn")

## Tipo de objeto a mostrar (-1 = todos). Por defecto, comida.
@export var item_type: int = ItemDefinition.ItemType.FOOD

var _slots: Dictionary[StringName, InventorySlot] = {}
var _selected: StringName = &""

@onready var _row: HBoxContainer = %Slots


func _ready() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(1, 0.98, 0.93, 0.92)
	panel.border_color = Color(0.96, 0.73, 0.45)
	panel.set_border_width_all(5)
	panel.set_corner_radius_all(28)
	panel.set_content_margin_all(12)
	add_theme_stylebox_override("panel", panel)

	for item: ItemDefinition in Inventory.get_inventory_items(item_type):
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		_row.add_child(slot)
		slot.setup(item)
		slot.set_quantity(Inventory.get_quantity(item.id))
		slot.pressed.connect(_on_slot_pressed)
		_slots[item.id] = slot
	Inventory.quantity_changed.connect(_on_quantity_changed)


func get_slot(item_id: StringName) -> InventorySlot:
	return _slots.get(item_id)


func get_selected() -> StringName:
	return _selected


func select(item_id: StringName) -> void:
	if _selected == item_id:
		return
	if _slots.has(_selected):
		_slots[_selected].set_selected(false)
	_selected = item_id if _slots.has(item_id) else &""
	if _slots.has(_selected):
		_slots[_selected].set_selected(true)
	selection_changed.emit(_selected)


func clear_selection() -> void:
	select(&"")


func _on_slot_pressed(item_id: StringName) -> void:
	var slot: InventorySlot = get_slot(item_id)
	if slot != null and not slot.is_available():
		slot.shake()
		return
	# Tocar otra vez la casilla seleccionada la deselecciona.
	select(&"" if _selected == item_id else item_id)


func _on_quantity_changed(item_id: StringName, quantity: int) -> void:
	var slot: InventorySlot = get_slot(item_id)
	if slot == null:
		return
	slot.set_quantity(quantity)
	if quantity == 0 and _selected == item_id:
		clear_selection()
