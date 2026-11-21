class_name MokiCare
extends Node
## Cuidados de Moki en la habitación: dar de comer y descansar.
##
## - Comer: arrastrar un alimento de la barra hasta Moki, o tocar el alimento
##   y después tocar a Moki. El uso real lo hace Inventory.use().
## - Descansar: botón de descanso u objetos de la habitación con acción REST
##   (el osito). Tocar a Moki o el botón lo despierta. Nunca es obligatorio.
##
## No contiene datos de objetos ni de necesidades: todo sale de los recursos.

## Mensaje breve para el niño (la habitación lo muestra en su rótulo).
signal message_requested(text: String)
signal fed(item: ItemDefinition)

@export var stage: MokiStage
@export var inventory_bar: InventoryBar
@export var rest_button: Button
## Icono del botón de descanso (luna para dormir, sol para despertar).
@export var rest_icon: ItemIcon
## Elementos visibles solo mientras descansa (oscurecer la habitación, "Zzz").
@export var rest_visuals: Array[CanvasItem] = []
## Capa donde se dibuja la comida que vuela hacia Moki.
@export var effects_layer: Control
## Punto de la boca de Moki en sus coordenadas locales (origen = pies).
@export var mouth_offset: Vector2 = Vector2(0, -345)

const FULL_MESSAGE: String = "¡Estoy lleno!"
const FLY_TIME: float = 0.45

var _moki: Moki


func _ready() -> void:
	_moki = stage.moki
	stage.tap_handler = _on_moki_tapped
	stage.drop_filter = _accepts_drop
	stage.data_dropped.connect(_on_data_dropped)
	if rest_button != null:
		rest_button.pressed.connect(toggle_rest)
	NeedsManager.resting_changed.connect(_on_resting_changed)
	_on_resting_changed(NeedsManager.is_resting())


# --- Comer ---------------------------------------------------------------------

## Intenta dar un alimento a Moki. Devuelve el resultado de Inventory.
func feed(item_id: StringName) -> int:
	var item: ItemDefinition = Inventory.get_item(item_id)
	if item == null or item.action != ItemDefinition.Action.FEED:
		return Inventory.UseResult.WRONG_TARGET
	var result: int = Inventory.can_use(item_id, ItemDefinition.Target.MOKI)
	if result == Inventory.UseResult.NOT_NEEDED:
		if inventory_bar != null:
			inventory_bar.clear_selection()
		_say_no()
		return result
	if result == Inventory.UseResult.NOT_AVAILABLE:
		var slot: InventorySlot = inventory_bar.get_slot(item_id) if inventory_bar != null else null
		if slot != null:
			slot.shake()
		return result
	if result != Inventory.UseResult.OK:
		return result
	if NeedsManager.is_resting():
		NeedsManager.set_resting(false)
	result = Inventory.use(item_id, ItemDefinition.Target.MOKI)
	if inventory_bar != null:
		inventory_bar.clear_selection()
	_fly_to_mouth(item)
	return result


func _accepts_drop(data: Variant) -> bool:
	if not data is Dictionary or data.get("type") != InventorySlot.DRAG_TYPE:
		return false
	var item: ItemDefinition = Inventory.get_item(data.get("item_id", &""))
	return item != null and item.target == ItemDefinition.Target.MOKI


func _on_data_dropped(data: Variant) -> void:
	feed(data["item_id"])


func _on_moki_tapped() -> bool:
	if NeedsManager.is_resting():
		NeedsManager.set_resting(false)
		return true
	if inventory_bar != null and not inventory_bar.get_selected().is_empty():
		feed(inventory_bar.get_selected())
		return true
	return false


func _fly_to_mouth(item: ItemDefinition) -> void:
	var start: Vector2 = _mouth_position() + Vector2(0, -120)
	var slot: InventorySlot = inventory_bar.get_slot(item.id) if inventory_bar != null else null
	if slot != null:
		start = slot.get_global_rect().get_center()
	if effects_layer == null:
		_on_food_eaten(item)
		return
	var food := ItemIcon.new()
	food.item = item
	food.size = Vector2(90, 90)
	food.pivot_offset = food.size / 2.0
	effects_layer.add_child(food)
	food.global_position = start - food.size / 2.0
	var tween: Tween = food.create_tween().set_parallel()
	tween.tween_property(food, "global_position", _mouth_position() - food.size / 2.0, FLY_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(food, "scale", Vector2.ONE * 0.3, FLY_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(food.queue_free)
	tween.chain().tween_callback(_on_food_eaten.bind(item))


func _on_food_eaten(item: ItemDefinition) -> void:
	if not item.reaction.is_empty():
		_moki.react(item.reaction)
		_moki.set_expression(item.reaction_mood)
	if not item.use_message.is_empty():
		message_requested.emit(item.use_message)
	fed.emit(item)


func _say_no() -> void:
	# Sin castigo: Moki ladea la cabeza con calma y no se gasta nada.
	if not _moki.is_reacting():
		_moki.react(&"tilt")
		_moki.set_expression(Moki.Mood.NEUTRAL)
	message_requested.emit(FULL_MESSAGE)


func _mouth_position() -> Vector2:
	return _moki.get_global_transform_with_canvas() * mouth_offset


# --- Descansar -----------------------------------------------------------------

func toggle_rest() -> void:
	NeedsManager.set_resting(not NeedsManager.is_resting())


## Objetos de la habitación con acción (p. ej. el osito -> descansar).
## Devuelve true si el objeto tenía una acción que se gestionó aquí.
func handle_room_item(room_item: RoomItem) -> bool:
	if room_item.item == null:
		return false
	match room_item.item.action:
		ItemDefinition.Action.REST:
			if not NeedsManager.is_resting():
				NeedsManager.set_resting(true)
				if not room_item.item.use_message.is_empty():
					message_requested.emit(room_item.item.use_message)
			else:
				NeedsManager.set_resting(false)
			return true
	return false


func _on_resting_changed(resting: bool) -> void:
	for visual: CanvasItem in rest_visuals:
		if visual == null:
			continue
		visual.visible = true
		var tween: Tween = visual.create_tween()
		tween.tween_property(visual, "modulate:a", 1.0 if resting else 0.0, 0.6)
		if not resting:
			tween.tween_callback(visual.hide)
	if rest_icon != null:
		rest_icon.placeholder = ItemDefinition.Placeholder.SUN if resting else ItemDefinition.Placeholder.MOON
	if rest_button != null:
		rest_button.tooltip_text = "Despertar" if resting else "Descansar"
