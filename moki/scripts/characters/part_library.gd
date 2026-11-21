@tool
class_name PartLibrary
extends Resource
## Conjunto de variantes intercambiables para una pieza (cabezas, brazos, piernas...).
## Las claves se usan desde CharacterPart.variant y desde las pistas de AnimationPlayer.

@export var variants: Dictionary[StringName, PartVariant] = {}


func has_variant(key: StringName) -> bool:
	return variants.has(key) and variants[key] != null and variants[key].texture != null


func get_variant(key: StringName) -> PartVariant:
	return variants.get(key) as PartVariant
