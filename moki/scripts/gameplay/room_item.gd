@tool
class_name RoomItem
extends TextureRect
## Objeto de la habitación (mueble, juguete, libro, caja, decoración...).
##
## - Se dimensiona a partir de su PNG con art_scale (sin deformarlo).
## - Solo responde a toques sobre sus píxeles opacos, así los objetos que están
##   dentro o encima de un mueble se pueden tocar por separado.
## - Al tocarlo hace un pequeño rebote y emite "selected". La lógica de qué
##   pasa después vive en quien escucha la señal (p. ej. ChibbiRoom).

signal selected(item: RoomItem)

enum Category { DECOR, FURNITURE, TOY, BOOK, BIN, PROP }

## Identificador estable para futuras interacciones (guardado, misiones...).
@export var item_id: StringName = &""
## Nombre que se muestra al niño al tocar el objeto.
@export var display_name: String = ""
@export var category: Category = Category.DECOR
## Si es false, el objeto es puramente visual y deja pasar los toques.
@export var interactive: bool = true:
	set(value):
		interactive = value
		_update_mouse_filter()
## Escala del PNG original. El tamaño del nodo se calcula a partir de ella.
@export_range(0.05, 4.0, 0.01) var art_scale: float = 1.0:
	set(value):
		art_scale = value
		fit_to_texture()
## Opacidad mínima (0-1) que cuenta como "tocable".
@export_range(0.0, 1.0, 0.01) var alpha_threshold: float = 0.2

const PRESS_SCALE: float = 1.08
const PRESS_TIME: float = 0.09

var _hit_mask: BitMap
var _tween: Tween


func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	fit_to_texture()
	_update_mouse_filter()
	if not Engine.is_editor_hint():
		_build_hit_mask()


## Ajusta el tamaño al PNG multiplicado por art_scale y coloca el pivote abajo al centro.
func fit_to_texture() -> void:
	if texture == null:
		return
	size = texture.get_size() * art_scale
	pivot_offset = Vector2(size.x / 2.0, size.y)


func _update_mouse_filter() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE


func _build_hit_mask() -> void:
	if texture == null:
		return
	var image: Image = texture.get_image()
	if image == null:
		return
	if image.is_compressed():
		image.decompress()
	_hit_mask = BitMap.new()
	_hit_mask.create_from_image_alpha(image, alpha_threshold)


func _has_point(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, size).has_point(point):
		return false
	if _hit_mask == null:
		return true
	var mask_size: Vector2i = _hit_mask.get_size()
	var pixel := Vector2i(point / size * Vector2(mask_size))
	if flip_h:
		pixel.x = mask_size.x - 1 - pixel.x
	if flip_v:
		pixel.y = mask_size.y - 1 - pixel.y
	pixel = pixel.clamp(Vector2i.ZERO, mask_size - Vector2i.ONE)
	return _hit_mask.get_bitv(pixel)


func _gui_input(event: InputEvent) -> void:
	# Los toques de pantalla llegan como clic emulado (emulate_mouse_from_touch).
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	_play_feedback()
	selected.emit(self)


func _play_feedback() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	scale = Vector2.ONE
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(PRESS_SCALE, 1.0 / PRESS_SCALE), PRESS_TIME)
	_tween.tween_property(self, "scale", Vector2.ONE, PRESS_TIME * 2.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
