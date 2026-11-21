@tool
class_name ItemDefinition
extends Resource
## Definición de datos de un objeto (comida, objeto de descanso, juguete...).
## Un objeto nuevo es un .tres nuevo: no hace falta código por objeto.

enum ItemType { FOOD, REST, TOY, OTHER }
## Qué hace el objeto al usarse.
enum Action { NONE, FEED, REST }
## Sobre qué se usa.
enum Target { MOKI, ROOM }
## Icono provisional dibujado por código mientras no exista arte (ver PlaceholderIcon).
enum Placeholder { NONE, APPLE, BANANA, COOKIE, MOON, SUN }

@export var id: StringName = &""
@export var display_name: String = ""
@export var type: ItemType = ItemType.FOOD

@export_group("Aspecto")
## Icono del objeto. Si está vacío se usa el icono provisional.
@export var icon: Texture2D
@export var placeholder: Placeholder = Placeholder.NONE

@export_group("Uso")
@export var action: Action = Action.FEED
@export var target: Target = Target.MOKI
## Efecto sobre las necesidades: { id_necesidad: puntos }. Ej. { &"hunger": 20 }.
@export var effects: Dictionary[StringName, float] = {}
## Si es true, no se usa cuando ninguna necesidad que mejora lo necesita
## (p. ej. Moki ya está lleno). No se gasta y Moki lo dice con calma.
@export var refuse_when_not_needed: bool = true

@export_group("Inventario")
## Aparece en la barra de inventario.
@export var show_in_inventory: bool = true
## Se gasta una unidad al usarlo.
@export var consumable: bool = true
## Cantidad ilimitada (alimentos básicos: Moki siempre puede comer).
@export var unlimited: bool = false
@export_range(0, 99) var initial_quantity: int = 0
@export_range(1, 99) var max_quantity: int = 99

@export_group("Reacción de Moki")
## Animación existente de Moki al usarlo (bounce, wave, surprised, tilt...).
@export var reaction: StringName = &"bounce"
@export var reaction_mood: Moki.Mood = Moki.Mood.LAUGHING
## Texto breve que se muestra al usarlo (vacío = ninguno).
@export var use_message: String = ""


## Puntos que este objeto sumaría a una necesidad (0 si no la afecta).
func effect_on(need_id: StringName) -> float:
	return effects.get(need_id, 0.0)
