@tool
class_name Chibbi
extends Node2D
## Chibbi, la mascota. Personaje cutout híbrido:
##
## - Modo "rig": torso, cola, cabeza, brazos y piernas como piezas sueltas sobre
##   Skeleton2D/Bone2D. Se activa solo cuando existe un torso para la vista actual
##   en chibbi_torsos.tres (hoy no hay torsos, ver docs/development_log.md).
## - Modo "pose completa": muestra el body_* de la vista actual con la cabeza de
##   expresión superpuesta exactamente sobre la cabeza integrada.
##
## Las animaciones mueven el nodo Body (afecta a ambos modos) y los huesos (solo
## visibles en modo rig). Las expresiones cambian solo la textura de la cabeza, así
## que son independientes de la animación que se esté reproduciendo.
##
## El origen del nodo es el suelo, entre los pies.

signal reacted(reaction: StringName)
signal expression_changed(expression: Mood)

enum Mood { NEUTRAL, HAPPY, LAUGHING, SURPRISED, ANGRY }
enum View { FRONT, THREE_QUARTER, SIDE }

const EXPRESSION_KEYS: Dictionary[Mood, StringName] = {
	Mood.NEUTRAL: &"neutral",
	Mood.HAPPY: &"happy",
	Mood.LAUGHING: &"laughing",
	Mood.SURPRISED: &"surprised",
	Mood.ANGRY: &"angry",
}
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

## Expresión a la que vuelve Chibbi cuando no está reaccionando.
@export var rest_expression: Mood = Mood.NEUTRAL

@export_group("Sombra")
@export var shadow_size: Vector2 = Vector2(110, 18)
@export var shadow_color: Color = Color(0.3, 0.2, 0.1, 0.18)

var _last_reaction: StringName = &""

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


func is_rig_mode() -> bool:
	return _torso != null and _torso.library != null and _torso.library.has_variant(VIEW_KEYS[view])


func is_reacting() -> bool:
	return _animation_player.is_playing() and REACTIONS.has(_animation_player.current_animation)


## Reproduce una reacción con su expresión. Al terminar vuelve a idle y neutral.
## Cada animación fija la pose completa en su primer fotograma, así que no
## arrastra valores de la animación anterior.
func react(reaction: StringName) -> void:
	if not REACTIONS.has(reaction) or not _animation_player.has_animation(reaction):
		push_warning("Chibbi: reacción desconocida '%s'." % reaction)
		return
	_last_reaction = reaction
	set_expression(REACTIONS[reaction])
	_animation_player.play(reaction)
	reacted.emit(reaction)


## Reacción aleatoria al tocar a Chibbi (no repite la anterior y no interrumpe).
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

	_full_pose.variant = key
	_full_pose.visible = not rig
	_full_pose_head.visible = not rig

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
	var key: StringName = StringName("%s_%s" % [VIEW_KEYS[view], EXPRESSION_KEYS[expression]])
	_head.variant = key
	_full_pose_head.variant = key


func _on_animation_finished(anim_name: StringName) -> void:
	if not REACTIONS.has(anim_name):
		return
	set_expression(rest_expression)
	_animation_player.play(ANIM_IDLE)
