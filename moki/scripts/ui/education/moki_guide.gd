class_name MokiGuide
extends HBoxContainer
## Moki como guía: solo su rostro (cabezas existentes, sin arte nuevo) y un
## bocadillo de cómic con cola que apunta hacia él. Muestra instrucciones,
## explicaciones, consejos, pistas, acertijos y felicitaciones, y los lee en
## voz alta con Narrator (los niños aún no leen). Reutilizable en cualquier
## pantalla educativa.

signal help_pressed
signal listen_pressed

## Retratos: la zona de la cara de cada ilustración de expresión (AtlasTexture
## sobre los mismos PNG; no son imágenes nuevas).
const HEADS: PartLibrary = preload("res://resources/character/moki_portraits.tres")
const MOOD_KEYS: Dictionary[Moki.Mood, StringName] = {
	Moki.Mood.NEUTRAL: &"happy",  # no hay pose neutral: el reposo es feliz
	Moki.Mood.HAPPY: &"happy",
	Moki.Mood.LAUGHING: &"laughing",
	Moki.Mood.SURPRISED: &"surprised",
	Moki.Mood.ANGRY: &"happy",  # el guía nunca se muestra enfadado
	Moki.Mood.CURIOUS: &"curious",
	Moki.Mood.THINKING: &"thinking",
	Moki.Mood.SAD: &"happy",  # el guía no se muestra triste ni asustado
	Moki.Mood.SCARED: &"happy",
	Moki.Mood.SLEEPING: &"happy",
	Moki.Mood.EATING: &"happy",
}
## Color de fondo de cada tipo de frase (pistas y acertijos se distinguen).
const KIND_COLORS: Dictionary[DialogueLine.Kind, Color] = {
	DialogueLine.Kind.HINT: Color("#FFF6D8"),
	DialogueLine.Kind.RIDDLE: Color("#F1E8FF"),
	DialogueLine.Kind.PRAISE: Color("#E9F8E3"),
}
const BUBBLE_COLOR: Color = Color(1, 1, 1)
const BUBBLE_BORDER: Color = Color(0.45, 0.3, 0.2)

var current_line: DialogueLine

@onready var _portrait: TextureRect = %Portrait
@onready var _tail: BubbleTail = %Tail
@onready var _bubble: PanelContainer = %Bubble
@onready var _text: Label = %Text
@onready var _model_slot: CenterContainer = %ModelSlot
@onready var _listen: Button = %ListenButton
@onready var _help: Button = %HelpButton

var _bubble_style := StyleBoxFlat.new()


func _ready() -> void:
	_bubble_style.bg_color = BUBBLE_COLOR
	_bubble_style.border_color = BUBBLE_BORDER
	_bubble_style.set_border_width_all(4)
	_bubble_style.set_corner_radius_all(30)
	_bubble_style.content_margin_left = 24
	_bubble_style.content_margin_right = 24
	_bubble_style.content_margin_top = 12
	_bubble_style.content_margin_bottom = 12
	_bubble.add_theme_stylebox_override("panel", _bubble_style)
	_tail.fill = BUBBLE_COLOR
	_tail.border = BUBBLE_BORDER
	_listen.pressed.connect(func() -> void:
		replay()
		listen_pressed.emit())
	_help.pressed.connect(func() -> void: help_pressed.emit())
	_listen.visible = Narrator.can_speak()
	set_expression(Moki.Mood.HAPPY)


func show_guide() -> void:
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


func hide_guide() -> void:
	Narrator.stop()
	visible = false


## Dice una frase: actualiza texto, expresión, color del bocadillo y voz.
func say(line: DialogueLine) -> void:
	if line == null:
		return
	current_line = line
	_text.text = line.text
	set_expression(line.mood)
	var color: Color = KIND_COLORS.get(line.kind, BUBBLE_COLOR)
	_bubble_style.bg_color = color
	_tail.fill = color
	_tail.queue_redraw()
	_pop()
	Narrator.speak(line)


func say_text(text: String, kind: DialogueLine.Kind = DialogueLine.Kind.EXPLANATION,
		mood: Moki.Mood = Moki.Mood.HAPPY) -> void:
	say(DialogueLine.make(text, kind, mood))


func replay() -> void:
	if current_line != null:
		Narrator.speak(current_line)
		_pop()


func get_text() -> String:
	return _text.text


func set_expression(mood: Moki.Mood) -> void:
	var variant: PartVariant = HEADS.get_variant(MOOD_KEYS.get(mood, &"happy"))
	if variant != null:
		_portrait.texture = variant.texture


## Pista visual: muestra una tarjeta modelo dentro del bocadillo.
func show_model(card: CardData, bank: ContentBank) -> void:
	clear_model()
	if card == null:
		return
	var model := ActivityCard.new()
	model.setup(-1, card, bank, 110)
	model.locked = true
	_model_slot.add_child(model)
	_model_slot.visible = true


func clear_model() -> void:
	for child: Node in _model_slot.get_children():
		child.queue_free()
	_model_slot.visible = false


func set_help_enabled(enabled: bool) -> void:
	_help.disabled = not enabled


func _pop() -> void:
	_portrait.pivot_offset = _portrait.size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(_portrait, "rotation_degrees", -6.0, 0.1)
	tween.tween_property(_portrait, "rotation_degrees", 4.0, 0.12)
	tween.tween_property(_portrait, "rotation_degrees", 0.0, 0.1)
