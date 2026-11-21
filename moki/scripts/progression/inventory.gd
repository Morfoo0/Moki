extends Node
## Autoload "Inventory": cantidades de objetos y su uso.
##
## Los objetos se definen como datos (ItemDefinition) en un ItemCatalog.
## Usar un objeto valida el destino, aplica sus efectos mediante
## NeedsManager.change() y gasta una unidad si es consumible.
## Se guarda con SaveService (sección "inventory").

signal quantity_changed(item_id: StringName, quantity: int)
signal item_used(item: ItemDefinition, target: ItemDefinition.Target)
signal use_refused(item: ItemDefinition, result: UseResult)

enum UseResult { OK, UNKNOWN_ITEM, NOT_AVAILABLE, WRONG_TARGET, NOT_NEEDED }

const CATALOG_PATH: String = "res://resources/items/item_catalog.tres"
const SAVE_SECTION: String = "inventory"
## Por encima de este valor una necesidad se considera "satisfecha" para
## refuse_when_not_needed (no hace falta llenarla hasta 100).
const SATISFIED_VALUE: float = 95.0
## Cantidad que se devuelve para objetos ilimitados.
const UNLIMITED: int = -1

var catalog: ItemCatalog

var _quantities: Dictionary[StringName, int] = {}


func _ready() -> void:
	catalog = load(CATALOG_PATH) as ItemCatalog
	if catalog == null:
		push_error("Inventory: no se pudo cargar %s" % CATALOG_PATH)
		return
	reset()
	SaveService.register_section(SAVE_SECTION, to_dict, _apply_saved)


# --- Consulta ------------------------------------------------------------------

func get_item(item_id: StringName) -> ItemDefinition:
	return catalog.get_item(item_id) if catalog != null else null


## Objetos que se muestran en la barra de inventario (opcionalmente de un tipo).
func get_inventory_items(item_type: int = -1) -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	if catalog == null:
		return result
	for item: ItemDefinition in catalog.items:
		if item != null and item.show_in_inventory and (item_type < 0 or item.type == item_type):
			result.append(item)
	return result


## Cantidad disponible (UNLIMITED = -1 para objetos ilimitados).
func get_quantity(item_id: StringName) -> int:
	var item: ItemDefinition = get_item(item_id)
	if item != null and item.unlimited:
		return UNLIMITED
	return _quantities.get(item_id, 0)


func has_item(item_id: StringName) -> bool:
	var quantity: int = get_quantity(item_id)
	return quantity == UNLIMITED or quantity > 0


## Comprueba si el objeto se puede usar ahora sobre ese destino.
func can_use(item_id: StringName, target: ItemDefinition.Target) -> UseResult:
	var item: ItemDefinition = get_item(item_id)
	if item == null:
		return UseResult.UNKNOWN_ITEM
	if item.target != target:
		return UseResult.WRONG_TARGET
	if item.consumable and not has_item(item_id):
		return UseResult.NOT_AVAILABLE
	if item.refuse_when_not_needed and not _is_needed(item):
		return UseResult.NOT_NEEDED
	return UseResult.OK


# --- Modificación --------------------------------------------------------------

## Usa el objeto: aplica sus efectos y gasta una unidad. Devuelve el resultado.
func use(item_id: StringName, target: ItemDefinition.Target) -> UseResult:
	var result: UseResult = can_use(item_id, target)
	var item: ItemDefinition = get_item(item_id)
	if result != UseResult.OK:
		if item != null:
			use_refused.emit(item, result)
		return result
	for need_id: StringName in item.effects:
		NeedsManager.change(need_id, item.effects[need_id])
	if item.consumable and not item.unlimited:
		_set_quantity(item, _quantities.get(item_id, 0) - 1)
	item_used.emit(item, target)
	return UseResult.OK


## Añade unidades (p. ej. futuras recompensas).
func add(item_id: StringName, amount: int = 1) -> void:
	var item: ItemDefinition = get_item(item_id)
	if item != null and not item.unlimited:
		_set_quantity(item, _quantities.get(item_id, 0) + amount)


## Vuelve a las cantidades iniciales del catálogo.
func reset() -> void:
	_quantities.clear()
	for item: ItemDefinition in catalog.items:
		if item != null and not item.unlimited:
			_quantities[item.id] = clampi(item.initial_quantity, 0, item.max_quantity)
			quantity_changed.emit(item.id, _quantities[item.id])


# --- Persistencia --------------------------------------------------------------

func to_dict() -> Dictionary:
	var quantities: Dictionary = {}
	for item_id: StringName in _quantities:
		quantities[String(item_id)] = _quantities[item_id]
	return {"quantities": quantities}


func _apply_saved(data: Dictionary, _saved_at: int) -> void:
	var saved: Variant = data.get("quantities")
	if not saved is Dictionary:
		return
	for item: ItemDefinition in catalog.items:
		if item == null or item.unlimited:
			continue
		var stored: Variant = (saved as Dictionary).get(String(item.id))
		if stored is float or stored is int:
			_set_quantity(item, int(stored))


# --- Interno -------------------------------------------------------------------

func _set_quantity(item: ItemDefinition, quantity: int) -> void:
	var clamped: int = clampi(quantity, 0, item.max_quantity)
	if _quantities.get(item.id, -999) == clamped:
		return
	_quantities[item.id] = clamped
	quantity_changed.emit(item.id, clamped)


## True si alguna necesidad que el objeto mejora no está ya satisfecha.
## Objetos sin efectos positivos siempre se consideran útiles.
func _is_needed(item: ItemDefinition) -> bool:
	var improves_something: bool = false
	for need_id: StringName in item.effects:
		if item.effects[need_id] <= 0.0:
			continue
		improves_something = true
		if NeedsManager.get_value(need_id) < SATISFIED_VALUE:
			return true
	return not improves_something
