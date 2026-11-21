class_name NeedMeter
extends VBoxContainer
## Medidor de una necesidad para preescolares: insignia de color (icono o
## inicial) y una barra redondeada cuyo color indica el estado. Sin números.

signal pressed(need_id: StringName)

const STATE_COLORS: Dictionary[NeedDefinition.State, Color] = {
	NeedDefinition.State.GOOD: Color("#7BC74D"),
	NeedDefinition.State.MEDIUM: Color("#FFC93C"),
	NeedDefinition.State.LOW: Color("#FF9A3D"),
	NeedDefinition.State.CRITICAL: Color("#FF6B6B"),
}
const BAR_BACKGROUND: Color = Color(1, 1, 1, 0.85)
const BAR_BORDER: Color = Color(0.45, 0.3, 0.2, 0.35)
const PULSE_SCALE: float = 1.12

var need_id: StringName = &""

var _fill_style := StyleBoxFlat.new()
var _pulse_tween: Tween
var _state: NeedDefinition.State = NeedDefinition.State.GOOD

@onready var _badge: Panel = %Badge
@onready var _icon: TextureRect = %Icon
@onready var _initial: Label = %Initial
@onready var _bar: ProgressBar = %Bar


func _ready() -> void:
	_badge.resized.connect(func() -> void: _badge.pivot_offset = _badge.size / 2.0)
	_fill_style.set_corner_radius_all(12)
	_bar.add_theme_stylebox_override("fill", _fill_style)
	var background := StyleBoxFlat.new()
	background.bg_color = BAR_BACKGROUND
	background.border_color = BAR_BORDER
	background.set_border_width_all(3)
	background.set_corner_radius_all(12)
	_bar.add_theme_stylebox_override("background", background)
	_apply_state_color()


## Configura el medidor a partir de su definición.
func setup(definition: NeedDefinition) -> void:
	need_id = definition.id
	tooltip_text = definition.display_name
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = definition.color
	badge_style.border_color = Color.WHITE
	badge_style.set_border_width_all(4)
	badge_style.set_corner_radius_all(64)
	_badge.add_theme_stylebox_override("panel", badge_style)
	_icon.texture = definition.icon
	_icon.visible = definition.icon != null
	_initial.text = definition.display_name.left(1).to_upper()
	_initial.visible = definition.icon == null


func set_value(value: float) -> void:
	_bar.value = value


func set_state(state: NeedDefinition.State) -> void:
	_state = state
	_apply_state_color()
	# Solo el estado crítico pulsa, y con calma: el color ya informa del resto.
	_set_pulsing(state == NeedDefinition.State.CRITICAL, 0.9)


## Resalte breve (p. ej. cuando Moki pide atención sobre esta necesidad).
func highlight() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_badge, "scale", Vector2.ONE * 1.3, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_badge, "scale", Vector2.ONE, 0.25)


func _apply_state_color() -> void:
	_fill_style.bg_color = STATE_COLORS.get(_state, Color.WHITE)


func _set_pulsing(enabled: bool, half_period: float) -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_badge.scale = Vector2.ONE
	if not enabled:
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_badge, "scale", Vector2.ONE * PULSE_SCALE, half_period).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_badge, "scale", Vector2.ONE, half_period).set_trans(Tween.TRANS_SINE)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		highlight()
		pressed.emit(need_id)
