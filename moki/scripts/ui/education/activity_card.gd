class_name ActivityCard
extends Control
## Tarjeta de actividad: muestra una letra, una imagen o una palabra (CardData).
## Se toca con ratón o dedo (el toque se emula como clic). Se puede arrastrar
## si draggable = true (actividades de clasificar).

signal pressed(card_index: int)

const DRAG_TYPE: String = "edu_card"
const BG: Color = Color(1, 0.99, 0.95)
const BORDER: Color = Color(0.96, 0.73, 0.45)
const SELECTED: Color = Color("#2F7FD1")
const CORRECT: Color = Color("#5DBB4A")

var card_index: int = -1
var data: CardData
var draggable: bool = false
var locked: bool = false

var _style := StyleBoxFlat.new()
var _panel := Panel.new()
var _label := Label.new()
var _image := TextureRect.new()
var _press_inside: bool = false

static var _emoji: SystemFont


## Fuente de emoji del sistema (Windows, Apple, Android/Linux), compartida.
static func emoji_font() -> SystemFont:
	if _emoji == null:
		_emoji = SystemFont.new()
		_emoji.font_names = PackedStringArray(["Segoe UI Emoji", "Apple Color Emoji", "Noto Color Emoji"])
	return _emoji


func setup(index: int, card: CardData, bank: ContentBank, side: float) -> void:
	card_index = index
	data = card
	custom_minimum_size = Vector2(side, side)
	pivot_offset = Vector2(side, side) / 2.0
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	_style.bg_color = BG
	_style.border_color = BORDER
	_style.set_border_width_all(5)
	_style.set_corner_radius_all(int(side * 0.16))
	_style.shadow_color = Color(0, 0, 0, 0.12)
	_style.shadow_size = 4
	_panel.add_theme_stylebox_override("panel", _style)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)
	if card.kind == CardData.Kind.IMAGE and card.texture == null and not card.glyph.is_empty():
		# Dibujo provisional: emoji con la fuente de emoji del sistema.
		_label.text = card.glyph
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.add_theme_font_override("font", emoji_font())
		_label.add_theme_font_size_override("font_size", int(side * 0.55))
		add_child(_label)
	elif card.kind == CardData.Kind.IMAGE:
		_image.texture = card.texture
		_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_image.set_anchors_preset(Control.PRESET_FULL_RECT)
		var margin: int = int(side * 0.1)
		_image.offset_left = margin
		_image.offset_top = margin
		_image.offset_right = -margin
		_image.offset_bottom = -margin
		add_child(_image)
	else:
		_label.text = card.text
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var font: Font = bank.get_font(card.font_index) if bank != null else null
		if font != null:
			_label.add_theme_font_override("font", font)
		var max_size: int = int(side * (0.78 if card.text.length() == 1 else 0.4))
		_label.add_theme_font_size_override("font_size", mini(card.font_size, max_size))
		_label.add_theme_color_override("font_color", card.color)
		add_child(_label)
	tooltip_text = card.spoken


func set_selected(selected: bool) -> void:
	_style.border_color = SELECTED if selected else BORDER
	_style.set_border_width_all(9 if selected else 5)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * (1.08 if selected else 1.0), 0.12)


## Acierto: borde y brillo verde con un rebote.
func mark_correct() -> void:
	_style.border_color = CORRECT
	_style.set_border_width_all(10)
	_style.bg_color = Color("#E9F8E3")
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.15, 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)


## Error: sacudida suave (sin colores negativos ni castigo).
func shake() -> void:
	var tween: Tween = create_tween()
	for offset: float in [-10.0, 10.0, -6.0, 6.0, 0.0]:
		tween.tween_property(self, "rotation_degrees", offset * 0.6, 0.05)


## La pista visual retira esta tarjeta.
func retire() -> void:
	locked = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.12, 0.35)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT or locked:
		return
	if click.pressed:
		_press_inside = true
		accept_event()
	elif _press_inside:
		_press_inside = false
		accept_event()
		pressed.emit(card_index)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable or locked:
		return null
	_press_inside = false
	var preview := Control.new()
	var copy := ActivityCard.new()
	copy.setup(card_index, data, null, custom_minimum_size.x * 0.8)
	copy.position = -copy.custom_minimum_size / 2.0
	preview.add_child(copy)
	set_drag_preview(preview)
	return {"type": DRAG_TYPE, "index": card_index}
