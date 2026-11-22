@tool
class_name PartVariant
extends Resource
## Una variante visual de una pieza de personaje (un PNG y su punto de articulación).
##
## pivot: coordenadas en píxeles DENTRO del PNG del punto que debe coincidir con
## el hueso (hombro, cadera, cuello...). Como cada PNG está recortado a su
## contenido, cada variante necesita su propio pivote.

@export var texture: Texture2D
@export var pivot: Vector2 = Vector2.ZERO
## Escala de normalización (p. ej. fotogramas dibujados a distinto tamaño).
## Solo la usa un CharacterPart con use_variant_scale = true.
@export var scale: float = 1.0
