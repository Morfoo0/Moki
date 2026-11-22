@tool
class_name Moki
extends Node2D
## Moki, la mascota. Personaje cutout híbrido:
##
## - Modo "rig": torso, cola, cabeza, brazos y piernas como piezas sueltas sobre
##   Skeleton2D/Bone2D. Se activa solo cuando existe un torso para la vista actual
##   en moki_torsos.tres (hoy no hay torsos, ver docs/development_log.md).
## - Modo "pose completa" (el que se usa): cada expresión es una ilustración de
##   cuerpo entero (assets/characters/moki/expressions/), en moki_expressions.tres.
##   Cada pose tiene su pivote en el suelo, entre los pies, así que Moki no
##   "salta" al cambiar de expresión. Se muestra a su tamaño real (sin ampliar).
##
## Las animaciones mueven el nodo Body (afecta a ambos modos) y los huesos (solo
## visibles en modo rig). Cambiar de expresión cambia la pose entera, pero es
## independiente de la animación que se esté reproduciendo.
##
## El origen del nodo es el suelo, entre los pies.

signal reacted(reaction: StringName)
signal expression_changed(expression: Mood)

## Los valores se guardan como números en recursos (DialogueLine.mood,
## ItemDefinition.reaction_mood...): las expresiones nuevas van al final.
## NEUTRAL = calmado (el reposo). TIRED = cansado, HUNGRY = irritado por hambre,
## TALKING = secuencia de habla (normalmente se activa con talk()).
enum Mood { NEUTRAL, HAPPY, LAUGHING, SURPRISED, ANGRY, CURIOUS, THINKING, SAD, SCARED, SLEEPING, EATING, TIRED, HUNGRY, TALKING }
enum View { FRONT, THREE_QUARTER, SIDE }

## Expresión → variante de moki_expressions.tres (el primer fotograma si la
## expresión tiene secuencia en SEQUENCES).
const EXPRESSION_KEYS: Dictionary[Mood, StringName] = {
	Mood.NEUTRAL: &"calmado_1",
	Mood.HAPPY: &"feliz_1",
	Mood.LAUGHING: &"laughing",
	Mood.SURPRISED: &"sorprendido_1",
	Mood.ANGRY: &"angry",
	Mood.CURIOUS: &"curious",
	Mood.THINKING: &"thinking",
	Mood.SAD: &"sad",
	Mood.SCARED: &"scared",
	Mood.SLEEPING: &"sleeping",
	Mood.EATING: &"eating",
	Mood.TIRED: &"cansado_1",
	Mood.HUNGRY: &"hirritado_1",
	Mood.TALKING: &"hablando_1",
}
## Secuencias de fotogramas (en bucle): fotogramas y fotogramas por segundo.
## Todos los fotogramas comparten pivote en el suelo y tamaño de cabeza, así
## que solo cambian la cara y pequeños gestos.
const SEQUENCES: Dictionary[Mood, Dictionary] = {
	Mood.NEUTRAL: {"frames": [&"calmado_1", &"calmado_2", &"calmado_3", &"calmado_2"], "fps": 1.2},
	# Cansado: ojos pesados y bostezo (el fotograma 4, con "Zzz", es la
	# transición a dormir; no forma parte del bucle para no confundirlo).
	Mood.TIRED: {"frames": [&"cansado_1", &"cansado_2", &"cansado_1", &"cansado_2", &"cansado_3", &"cansado_3", &"cansado_2"], "fps": 1.2},
	Mood.HUNGRY: {"frames": [&"hirritado_1", &"hirritado_2", &"hirritado_2", &"hirritado_3", &"hirritado_4", &"hirritado_3", &"hirritado_1"], "fps": 1.6},
	# Habla: cerrada, entreabierta, abierta, cerrada, abierta, entreabierta.
	Mood.TALKING: {"frames": [&"hablando_1", &"hablando_2", &"hablando_3", &"hablando_4", &"hablando_5", &"hablando_6"], "fps": 8.0},
	Mood.HAPPY: {"frames": [&"feliz_1", &"feliz_2", &"feliz_3", &"feliz_4"], "fps": 4.0},
	Mood.SURPRISED: {"frames": [&"sorprendido_1", &"sorprendido_2", &"sorprendido_3", &"sorprendido_4"], "fps": 4.0},
}
## Expresiones que la habla no tapa: dormido, y comiendo (su mensaje, p. ej.
## "¡Ñam!", sale a la vez y no se puede comer y hablar a la vez).
const NOT_TALKING: Array[Mood] = [Mood.SLEEPING, Mood.EATING]
## Transición al empezar a descansar: cabeceo con "Zzz" antes de la pose dormido.
const SLEEP_TRANSITION_FRAME: StringName = &"cansado_4"
const SLEEP_TRANSITION_TIME: float = 0.9
const VIEW_KEYS: Dictionary[View, StringName] = {
	View.FRONT: &"front",
	View.THREE_QUARTER: &"3q",
	View.SIDE: &"side",
}

const ANIM_IDLE: StringName = &"idle"
## Reacción -> expresión que se muestra mientras dura.
const REACTIONS: Dictionary[StringName, Mood] = {
	&"bounce": Mood.LAUGHING,
	&"wave": Mood.HAPPY,
	&"surprised": Mood.SURPRISED,
	&"tilt": Mood.HAPPY,
}
const TAP_REACTIONS: Array[StringName] = [&"bounce", &"wave", &"surprised", &"tilt"]

@export var view: View = View.FRONT:
	set(value):
		view = value
		_refresh()

@export var expression: Mood = Mood.NEUTRAL:
	set(value):
		var changed: bool = value != expression
		expression = value
		_apply_expression()
		if changed and is_node_ready() and not Engine.is_editor_hint():
			expression_changed.emit(value)

## Expresión a la que vuelve Moki cuando no está reaccionando.
@export var rest_expression: Mood = Mood.NEUTRAL

@export_group("Sombra")
@export var shadow_size: Vector2 = Vector2(110, 18)
@export var shadow_color: Color = Color(0.3, 0.2, 0.1, 0.18)

var _last_reaction: StringName = &""
## Segundos que le quedan hablando (capa temporal sobre la expresión).
var _talk_left: float = 0.0
## Segundos que quedan de la transición a dormir.
var _transition_left: float = 0.0
## Reproductor de fotogramas: qué se muestra y por dónde va.
var _shown: Mood = Mood.NEUTRAL
var _frame_index: int = 0
var _frame_time: float = 0.0

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _full_pose: CharacterPart = %FullPose
@onready var _full_pose_head: CharacterPart = %FullPoseHead
@onready var _torso: CharacterPart = %TorsoSprite
@onready var _tail: CharacterPart = %TailSprite
@onready var _head: CharacterPart = %HeadSprite
@onready var _limbs: Array[CharacterPart] = [%ArmLSprite, %ArmRSprite, %LegLSprite, %LegRSprite]


func _ready() -> void:
	_refresh()
	queue_redraw()
	if Engine.is_editor_hint():
		return
	_animation_player.animation_finished.connect(_on_animation_finished)
	_animation_player.play(ANIM_IDLE)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _transition_left > 0.0:
		_transition_left -= delta
		if _transition_left <= 0.0:
			_update_display()
	if _talk_left > 0.0:
		_talk_left -= delta
		if _talk_left <= 0.0:
			_talk_left = 0.0
			_update_display()  # vuelve a la expresión de ahora (no a la de antes)
	var sequence: Dictionary = SEQUENCES.get(_shown, {})
	if sequence.is_empty() or _transition_left > 0.0:
		return
	_frame_time += delta * _animation_player.speed_scale
	var step: float = 1.0 / float(sequence["fps"])
	if _frame_time >= step:
		_frame_time = fmod(_frame_time, step)
		_frame_index = (_frame_index + 1) % sequence["frames"].size()
		_full_pose.variant = sequence["frames"][_frame_index]


func _draw() -> void:
	# Sombra elíptica en el suelo (no necesita arte).
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, shadow_size.y / shadow_size.x))
	draw_circle(Vector2.ZERO, shadow_size.x, shadow_color)


# --- API pública ---------------------------------------------------------------

## Cambia la expresión sin afectar a la animación en curso.
func set_expression(value: Mood) -> void:
	expression = value


## Cambia la expresión de reposo. Si no hay una reacción en curso se aplica ya;
## si la hay, se aplicará al terminar.
func set_rest_expression(value: Mood) -> void:
	rest_expression = value
	if is_node_ready() and not is_reacting():
		set_expression(value)


## Moki habla durante "seconds": se ve la secuencia de habla por encima de la
## expresión actual y, al terminar, vuelve a la expresión que tenga EN ESE
## MOMENTO (p. ej. irritado si mientras hablaba le entró hambre). Llamarla otra
## vez reinicia el mismo temporizador: nunca hay dos secuencias a la vez.
## Dormido y comiendo no se interrumpen por hablar (NOT_TALKING).
func talk(seconds: float) -> void:
	_talk_left = maxf(seconds, 0.0)
	_update_display()


func stop_talking() -> void:
	if _talk_left > 0.0:
		_talk_left = 0.0
		_update_display()


func is_talking() -> bool:
	return _talk_left > 0.0


## Duración de habla para un texto (no hay voz: se estima por su longitud).
static func talk_time(text: String) -> float:
	return clampf(0.5 + 0.05 * text.length(), 1.0, 4.0)


## Al empezar a descansar: cabeceo con "Zzz" y luego la pose dormido.
func play_sleep_transition() -> void:
	_transition_left = SLEEP_TRANSITION_TIME
	_update_display()


## Lo que se está mostrando (TALKING mientras habla).
func get_shown_mood() -> Mood:
	return _shown


## Variante (fotograma) que se muestra ahora mismo.
func get_shown_variant() -> StringName:
	return _full_pose.variant


## Velocidad de todas las animaciones (1 = normal). P. ej. 0.4 al descansar.
func set_animation_speed(speed: float) -> void:
	_animation_player.speed_scale = speed


func is_rig_mode() -> bool:
	return _torso != null and _torso.library != null and _torso.library.has_variant(VIEW_KEYS[view])


func is_reacting() -> bool:
	return _animation_player.is_playing() and REACTIONS.has(_animation_player.current_animation)


## Reproduce una reacción con su expresión. Al terminar vuelve a idle y neutral.
## Cada animación fija la pose completa en su primer fotograma, así que no
## arrastra valores de la animación anterior.
func react(reaction: StringName) -> void:
	if not REACTIONS.has(reaction) or not _animation_player.has_animation(reaction):
		push_warning("Moki: reacción desconocida '%s'." % reaction)
		return
	_last_reaction = reaction
	set_expression(REACTIONS[reaction])
	_animation_player.play(reaction)
	reacted.emit(reaction)


## Reacción aleatoria al tocar a Moki (no repite la anterior y no interrumpe).
func react_to_tap() -> void:
	if is_reacting():
		return
	var options: Array[StringName] = []
	for reaction: StringName in TAP_REACTIONS:
		if reaction != _last_reaction:
			options.append(reaction)
	react(options.pick_random())


# --- Interno -------------------------------------------------------------------

func _refresh() -> void:
	if not is_node_ready():
		return
	var key: StringName = VIEW_KEYS[view]
	var rig: bool = is_rig_mode()

	_full_pose.visible = not rig
	# La cara ya forma parte de cada pose: la cabeza superpuesta no se usa.
	_full_pose_head.visible = false

	_torso.variant = key if rig else &""
	_tail.variant = key if rig and _tail.library != null and _tail.library.has_variant(key) else &""
	_torso.visible = rig
	_tail.visible = rig
	_head.visible = rig
	for limb: CharacterPart in _limbs:
		limb.visible = rig
	_apply_expression()


func _apply_expression() -> void:
	if not is_node_ready():
		return
	_update_display()
	# Rig (desactivado): mismo esquema de claves de siempre, por si vuelve a usarse.
	_head.variant = StringName("%s_%s" % [VIEW_KEYS[view], EXPRESSION_KEYS[expression]])


## Prioridad visual: transición a dormir > dormido/comiendo > hablando > expresión actual.
func _update_display() -> void:
	if not is_node_ready():
		return
	if _transition_left > 0.0 and expression == Mood.SLEEPING:
		_full_pose.variant = SLEEP_TRANSITION_FRAME
		return
	var mood: Mood = expression
	if _talk_left > 0.0 and not expression in NOT_TALKING:
		mood = Mood.TALKING
	if mood != _shown or not SEQUENCES.has(mood):
		_frame_index = 0
		_frame_time = 0.0
	_shown = mood
	var sequence: Dictionary = SEQUENCES.get(mood, {})
	_full_pose.variant = sequence["frames"][_frame_index] if not sequence.is_empty() else EXPRESSION_KEYS[mood]


func _on_animation_finished(anim_name: StringName) -> void:
	if not REACTIONS.has(anim_name):
		return
	set_expression(rest_expression)
	_animation_player.play(ANIM_IDLE)
