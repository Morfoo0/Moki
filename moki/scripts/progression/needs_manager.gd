extends Node
## Autoload "NeedsManager": valores, paso del tiempo y estados de las necesidades.
##
## No conoce a Chibbi ni a la interfaz: comunica todo con señales.
## Las necesidades salen de NeedsConfig (res://resources/needs/chibbi_needs.tres).
## Convención: 100 = satisfecha, 0 = sin atender. No hay castigos ni muerte.

signal need_changed(need_id: StringName, value: float)
signal need_state_changed(need_id: StringName, state: NeedDefinition.State, previous: NeedDefinition.State)
signal overall_state_changed(state: NeedDefinition.State)
signal needs_loaded

const CONFIG_PATH: String = "res://resources/needs/chibbi_needs.tres"
const SAVE_SECTION: String = "needs"
const MAX_VALUE: float = 100.0
## Máximo de segundos que cuenta un fotograma (evita saltos tras pausas del sistema).
const MAX_FRAME_STEP: float = 5.0

var config: NeedsConfig

var _values: Dictionary[StringName, float] = {}
var _states: Dictionary[StringName, NeedDefinition.State] = {}
var _overall: NeedDefinition.State = NeedDefinition.State.GOOD
var _paused: bool = false
var _elapsed: float = 0.0


func _ready() -> void:
	config = load(CONFIG_PATH) as NeedsConfig
	if config == null:
		push_error("NeedsManager: no se pudo cargar %s" % CONFIG_PATH)
		return
	reset()
	SaveService.autosave_interval = config.autosave_interval
	SaveService.register_section(SAVE_SECTION, to_dict, _apply_saved)


func _process(delta: float) -> void:
	if _paused or config == null:
		return
	_elapsed += minf(delta, MAX_FRAME_STEP) * config.time_scale
	if _elapsed < config.tick_interval:
		return
	var step: float = _elapsed
	_elapsed = 0.0
	for definition: NeedDefinition in config.needs:
		_set_value(definition, _values[definition.id] - definition.decay_per_minute * step / 60.0)


# --- Consulta ------------------------------------------------------------------

func get_definitions() -> Array[NeedDefinition]:
	return config.needs if config != null else ([] as Array[NeedDefinition])


func get_definition(need_id: StringName) -> NeedDefinition:
	return config.get_definition(need_id) if config != null else null


func get_value(need_id: StringName) -> float:
	return _values.get(need_id, 0.0)


func get_state(need_id: StringName) -> NeedDefinition.State:
	return _states.get(need_id, NeedDefinition.State.GOOD)


## El peor estado entre todas las necesidades.
func get_overall_state() -> NeedDefinition.State:
	return _overall


## Necesidad con el valor más bajo (&"" si no hay ninguna).
func get_lowest_need() -> StringName:
	var lowest: StringName = &""
	for need_id: StringName in _values:
		if lowest.is_empty() or _values[need_id] < _values[lowest]:
			lowest = need_id
	return lowest


func is_paused() -> bool:
	return _paused


# --- Modificación --------------------------------------------------------------

## Suma (o resta) puntos. Punto de entrada para futuras acciones (comer, bañarse...).
func change(need_id: StringName, amount: float) -> void:
	var definition: NeedDefinition = get_definition(need_id)
	if definition == null:
		push_warning("NeedsManager: necesidad desconocida '%s'." % need_id)
		return
	_set_value(definition, _values[need_id] + amount)


func set_value(need_id: StringName, value: float) -> void:
	var definition: NeedDefinition = get_definition(need_id)
	if definition != null:
		_set_value(definition, value)


## Detiene o reanuda el paso del tiempo (p. ej. durante una actividad).
func set_paused(paused: bool) -> void:
	_paused = paused


## Vuelve todas las necesidades a su valor inicial.
func reset() -> void:
	_values.clear()
	_states.clear()
	for definition: NeedDefinition in config.needs:
		_values[definition.id] = clampf(definition.initial_value, config.min_value, MAX_VALUE)
		_states[definition.id] = definition.state_for(_values[definition.id])
	_refresh_all()


# --- Persistencia --------------------------------------------------------------

func to_dict() -> Dictionary:
	var values: Dictionary = {}
	for need_id: StringName in _values:
		values[String(need_id)] = snappedf(_values[need_id], 0.01)
	return {"values": values}


func _apply_saved(data: Dictionary, saved_at: int) -> void:
	var saved_values: Variant = data.get("values")
	if not saved_values is Dictionary:
		return
	var away_minutes: float = 0.0
	if config.offline_decay and saved_at > 0:
		var now: int = int(Time.get_unix_time_from_system())
		away_minutes = clampf((now - saved_at) / 60.0, 0.0, config.offline_max_minutes)
	for definition: NeedDefinition in config.needs:
		var key: String = String(definition.id)
		var value: float = _values[definition.id]
		var stored: Variant = (saved_values as Dictionary).get(key)
		if stored is float or stored is int:
			value = float(stored)
		if away_minutes > 0.0 and value > config.offline_floor:
			value = maxf(value - definition.decay_per_minute * away_minutes, config.offline_floor)
		_values[definition.id] = clampf(value, config.min_value, MAX_VALUE)
		_states[definition.id] = definition.state_for(_values[definition.id])
	_refresh_all()
	needs_loaded.emit()


# --- Interno -------------------------------------------------------------------

func _set_value(definition: NeedDefinition, value: float) -> void:
	var clamped: float = clampf(value, config.min_value, MAX_VALUE)
	if is_equal_approx(clamped, _values[definition.id]):
		return
	_values[definition.id] = clamped
	need_changed.emit(definition.id, clamped)
	var previous: NeedDefinition.State = _states[definition.id]
	var state: NeedDefinition.State = definition.state_for(clamped, previous)
	if state != previous:
		_states[definition.id] = state
		need_state_changed.emit(definition.id, state, previous)
		_update_overall()


## Notifica todos los valores y estados actuales (tras reiniciar o cargar).
func _refresh_all() -> void:
	for need_id: StringName in _values:
		need_changed.emit(need_id, _values[need_id])
		need_state_changed.emit(need_id, _states[need_id], _states[need_id])
	_update_overall(true)


func _update_overall(force: bool = false) -> void:
	var worst: NeedDefinition.State = NeedDefinition.State.GOOD
	for need_id: StringName in _states:
		worst = maxi(worst, _states[need_id]) as NeedDefinition.State
	if worst != _overall or force:
		_overall = worst
		overall_state_changed.emit(worst)
