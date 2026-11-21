class_name ChibbiRoom
extends Control
## Habitación de Chibbi. Escucha los RoomItem de la escena y reenvía la
## selección con item_selected, para que otros sistemas (necesidades, misiones,
## minijuegos) se conecten más adelante sin tocar los objetos.
##
## Por ahora la respuesta es solo visual: muestra el nombre del objeto y Chibbi
## hace una reacción según la categoría.

signal item_selected(item: RoomItem)

## Reacción provisional de Chibbi por categoría de objeto.
const CATEGORY_REACTIONS: Dictionary[RoomItem.Category, StringName] = {
	RoomItem.Category.TOY: &"bounce",
	RoomItem.Category.BOOK: &"tilt",
	RoomItem.Category.BIN: &"surprised",
	RoomItem.Category.PROP: &"tilt",
	RoomItem.Category.FURNITURE: &"wave",
}
const CAPTION_TIME: float = 1.6

var _caption_tween: Tween

@onready var _chibbi: Chibbi = %Chibbi
@onready var _caption: Label = %Caption
@onready var _needs_hud: NeedsHud = get_node_or_null("%NeedsHud")
@onready var _needs_link: ChibbiNeedsLink = get_node_or_null("%ChibbiNeedsLink")


func _ready() -> void:
	_caption.modulate.a = 0.0
	for item: RoomItem in get_items():
		item.selected.connect(_on_item_selected)
	if _needs_hud != null:
		_needs_hud.need_selected.connect(_on_need_selected)
		if _needs_link != null:
			_needs_link.attention_requested.connect(_needs_hud.highlight)


## Todos los RoomItem de la habitación, en orden de árbol.
func get_items() -> Array[RoomItem]:
	var items: Array[RoomItem] = []
	_collect_items(self, items)
	return items


func _collect_items(node: Node, items: Array[RoomItem]) -> void:
	for child: Node in node.get_children():
		if child is RoomItem:
			items.append(child as RoomItem)
		_collect_items(child, items)


func _on_item_selected(item: RoomItem) -> void:
	item_selected.emit(item)
	if not item.display_name.is_empty():
		_show_caption(item.display_name)
	var reaction: StringName = CATEGORY_REACTIONS.get(item.category, &"")
	if not reaction.is_empty() and not _chibbi.is_reacting():
		_chibbi.react(reaction)


func _on_need_selected(need_id: StringName) -> void:
	var definition: NeedDefinition = NeedsManager.get_definition(need_id)
	if definition != null:
		_show_caption(definition.display_name)


func _show_caption(text: String) -> void:
	_caption.text = text
	if _caption_tween != null and _caption_tween.is_valid():
		_caption_tween.kill()
	_caption.modulate.a = 1.0
	_caption_tween = create_tween()
	_caption_tween.tween_interval(CAPTION_TIME)
	_caption_tween.tween_property(_caption, "modulate:a", 0.0, 0.4)
