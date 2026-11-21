@tool
class_name WorldDefinition
extends Resource
## Un mundo educativo: lista ordenada y fija de niveles.

@export var id: StringName = &""
@export var title: String = ""
@export var color: Color = Color("#2F7FD1")
@export var unlocked_by_default: bool = false
## Nivel (de otro mundo) cuya finalización desbloquea este mundo y su primer
## nivel (p. ej. Números tras "letters_u"). Vacío = solo por defecto.
@export var unlocked_after_level: StringName = &""
## Niveles jugables, en orden.
@export var levels: Array[LevelDefinition] = []
## Niveles previstos aún no creados (se muestran como "Próximamente").
@export var upcoming_levels: PackedStringArray = []
