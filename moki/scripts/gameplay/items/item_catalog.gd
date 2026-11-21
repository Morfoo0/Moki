@tool
class_name ItemCatalog
extends Resource
## Lista de objetos disponibles en el juego. Para añadir un objeto basta con
## crear su ItemDefinition (.tres) y añadirlo aquí.

@export var items: Array[ItemDefinition] = []


func get_item(item_id: StringName) -> ItemDefinition:
	for item: ItemDefinition in items:
		if item != null and item.id == item_id:
			return item
	return null


func get_items_of_type(item_type: ItemDefinition.ItemType) -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for item: ItemDefinition in items:
		if item != null and item.type == item_type:
			result.append(item)
	return result
