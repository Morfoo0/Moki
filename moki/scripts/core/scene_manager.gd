extends CanvasLayer
## Autoload "SceneManager": cambia de escena con un fundido a negro.
## Uso: SceneManager.change_scene(ScenePaths.HOME)

signal scene_changed(path: String)

const FADE_DURATION: float = 0.3

var _fade_rect: ColorRect
var _is_changing: bool = false
var _params: Dictionary = {}


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_rect)


## params: datos opcionales para la escena nueva (p. ej. {"level_id": &"letters_a"}).
## La escena los lee con SceneManager.get_params().
func change_scene(path: String, params: Dictionary = {}) -> void:
	if _is_changing:
		return
	if not ResourceLoader.exists(path):
		push_error("SceneManager: la escena no existe: %s" % path)
		return

	_is_changing = true
	_params = params.duplicate()
	# Bloquea toques durante la transición.
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	await _fade_to(1.0)

	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("SceneManager: no se pudo cambiar a %s (error %d)" % [path, error])
	else:
		# Espera a que la nueva escena esté en el árbol.
		await get_tree().process_frame
		scene_changed.emit(path)

	await _fade_to(0.0)

	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_changing = false


## Parámetros pasados en el último change_scene() (vacío si no hubo).
func get_params() -> Dictionary:
	return _params


func is_changing() -> bool:
	return _is_changing


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", alpha, FADE_DURATION)
	await tween.finished
