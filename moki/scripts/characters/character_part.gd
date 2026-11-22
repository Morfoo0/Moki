@tool
class_name CharacterPart
extends Sprite2D
## Sprite de una pieza de personaje que toma su textura y pivote de una PartLibrary.
##
## El origen del nodo siempre coincide con el punto de articulación de la variante
## activa, así que cambiar de variante (p. ej. brazo recto -> brazo doblado) no
## desplaza la pieza respecto a su hueso. "variant" se puede animar con una pista
## discreta de AnimationPlayer.
## Si la librería no tiene la variante pedida, la pieza queda vacía (sin textura).

@export var library: PartLibrary:
	set(value):
		library = value
		_apply()

@export var variant: StringName = &"":
	set(value):
		variant = value
		_apply()

## Aplica PartVariant.scale a este sprite (escala uniforme alrededor del
## pivote). Desactivado por defecto: los sprites con escala propia (p. ej.
## extremidades reflejadas) no se ven afectados.
@export var use_variant_scale: bool = false:
	set(value):
		use_variant_scale = value
		_apply()


func _ready() -> void:
	_apply()


func has_current_variant() -> bool:
	return library != null and library.has_variant(variant)


func _apply() -> void:
	centered = false
	if library == null or variant.is_empty():
		texture = null
		return
	var data: PartVariant = library.get_variant(variant)
	if data == null:
		if not library.variants.is_empty():
			push_warning("CharacterPart '%s': variante '%s' no existe." % [name, variant])
		texture = null
		return
	texture = data.texture
	offset = -data.pivot
	if use_variant_scale:
		scale = Vector2.ONE * data.scale


func _validate_property(property: Dictionary) -> void:
	# La textura y el offset salen de la librería: no se guardan en la escena.
	if property.name in [&"texture", &"offset", &"centered"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE
