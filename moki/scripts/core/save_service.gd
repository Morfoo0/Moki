extends Node
## Autoload "SaveService": guardado genérico por secciones en user://moki_save.json.
##
## Cada sistema registra una sección con un getter (-> Dictionary) y un setter
## (datos: Dictionary, guardado_en_unix: int). Las secciones de una partida que
## todavía no se han registrado se conservan al volver a guardar.
##
## Guarda automáticamente: en cada cambio de escena, cada autosave_interval
## segundos, al cerrar la ventana y cuando la app pasa a segundo plano (móvil).

signal saved
signal loaded

const SAVE_PATH: String = "user://moki_save.json"
const SAVE_VERSION: int = 1

## Segundos entre guardados automáticos (0 = desactivado).
var autosave_interval: float = 30.0

var _getters: Dictionary[String, Callable] = {}
var _setters: Dictionary[String, Callable] = {}
var _file_sections: Dictionary = {}
var _saved_at: int = 0
var _autosave_elapsed: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()
	SceneManager.scene_changed.connect(_on_scene_changed)


func _process(delta: float) -> void:
	if autosave_interval <= 0.0:
		return
	_autosave_elapsed += delta
	if _autosave_elapsed >= autosave_interval:
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()


## Registra una sección. Si la partida cargada ya tenía datos, se aplican al instante.
func register_section(section: String, getter: Callable, setter: Callable) -> void:
	_getters[section] = getter
	_setters[section] = setter
	if _file_sections.has(section) and _file_sections[section] is Dictionary:
		setter.call(_file_sections[section], _saved_at)


func save_game() -> bool:
	_autosave_elapsed = 0.0
	var sections: Dictionary = _file_sections.duplicate(true)
	for section: String in _getters:
		sections[section] = _getters[section].call()
	_saved_at = int(Time.get_unix_time_from_system())
	var data: Dictionary = {"version": SAVE_VERSION, "saved_at": _saved_at, "sections": sections}

	var temp_path: String = SAVE_PATH + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveService: no se pudo escribir %s (%s)" % [temp_path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var error: Error = DirAccess.rename_absolute(temp_path, SAVE_PATH)
	if error != OK:
		push_warning("SaveService: no se pudo reemplazar %s (%s)" % [SAVE_PATH, error_string(error)])
		return false
	_file_sections = sections
	saved.emit()
	return true


## Lee el archivo. Si no existe, está dañado o es de una versión más nueva,
## se empieza una partida nueva (sin borrar nada).
func load_game() -> void:
	_file_sections = {}
	_saved_at = 0
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var text: String = FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_warning("SaveService: partida dañada, se empieza una nueva.")
		return
	var data: Dictionary = parsed
	if int(data.get("version", 0)) > SAVE_VERSION or not data.get("sections") is Dictionary:
		push_warning("SaveService: versión de partida no compatible, se empieza una nueva.")
		return
	_file_sections = data["sections"]
	_saved_at = int(data.get("saved_at", 0))
	for section: String in _setters:
		if _file_sections.get(section) is Dictionary:
			_setters[section].call(_file_sections[section], _saved_at)
	loaded.emit()


## Momento del último guardado (Unix, segundos). 0 si no hay partida.
func get_saved_at() -> int:
	return _saved_at


func _on_scene_changed(_path: String) -> void:
	save_game()
