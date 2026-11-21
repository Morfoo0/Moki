class_name ChibbiNeedsLink
extends Node
## Traduce el estado de las necesidades (NeedsManager) al comportamiento de Chibbi.
##
## Chibbi no depende de las necesidades: este nodo es el único puente. Cuando
## existan expresiones de hambre, sueño o tristeza, solo cambia este mapeo.
## Nunca usa expresiones negativas como enfado: no hay castigos.

## Pide atención (p. ej. para que el HUD resalte una necesidad baja).
signal attention_requested(need_id: StringName)

@export var chibbi: Chibbi
## Animación con la que Chibbi llama la atención cuando una necesidad está baja.
@export var attention_reaction: StringName = &"tilt"
## Segundos entre llamadas de atención con una necesidad en estado bajo.
@export var low_attention_interval: float = 20.0
## Segundos entre llamadas de atención con una necesidad en estado crítico.
@export var critical_attention_interval: float = 10.0

## Expresión de reposo según el peor estado.
const REST_EXPRESSIONS: Dictionary[NeedDefinition.State, Chibbi.Mood] = {
	NeedDefinition.State.GOOD: Chibbi.Mood.HAPPY,
	NeedDefinition.State.MEDIUM: Chibbi.Mood.NEUTRAL,
	NeedDefinition.State.LOW: Chibbi.Mood.NEUTRAL,
	NeedDefinition.State.CRITICAL: Chibbi.Mood.NEUTRAL,
}

var _attention_elapsed: float = 0.0


func _ready() -> void:
	if chibbi == null:
		push_warning("ChibbiNeedsLink: falta asignar 'chibbi'.")
		set_process(false)
		return
	NeedsManager.overall_state_changed.connect(_on_overall_state_changed)
	_on_overall_state_changed(NeedsManager.get_overall_state())


func _process(delta: float) -> void:
	var interval: float = _attention_interval()
	if interval <= 0.0:
		_attention_elapsed = 0.0
		return
	_attention_elapsed += delta
	if _attention_elapsed < interval or chibbi.is_reacting():
		return
	_attention_elapsed = 0.0
	var need_id: StringName = NeedsManager.get_lowest_need()
	chibbi.react(attention_reaction)
	# react() pone la expresión propia de la reacción; aquí se mantiene la de reposo.
	chibbi.set_expression(chibbi.rest_expression)
	attention_requested.emit(need_id)


func _attention_interval() -> float:
	match NeedsManager.get_overall_state():
		NeedDefinition.State.CRITICAL:
			return critical_attention_interval
		NeedDefinition.State.LOW:
			return low_attention_interval
	return 0.0


func _on_overall_state_changed(state: NeedDefinition.State) -> void:
	chibbi.set_rest_expression(REST_EXPRESSIONS.get(state, Chibbi.Mood.NEUTRAL))
