class_name ChibbiNeedsLink
extends Node
## Traduce el estado de las necesidades (NeedsManager) al comportamiento de Chibbi.
##
## Chibbi no depende de las necesidades: este nodo es el único puente. Cuando
## existan expresiones de hambre o sueño, solo cambia este mapeo.
## Principios: sin castigos ni presión. Chibbi solo pide atención, con calma,
## cuando una necesidad está en estado crítico, y nunca mientras descansa.

## Pide atención (p. ej. para que el HUD resalte una necesidad).
signal attention_requested(need_id: StringName)

@export var chibbi: Chibbi
## Animación con la que Chibbi llama la atención.
@export var attention_reaction: StringName = &"tilt"
## Segundos entre llamadas de atención con una necesidad en estado crítico.
@export var critical_attention_interval: float = 30.0
## Velocidad de la animación de reposo mientras descansa (respiración lenta).
@export_range(0.1, 1.0, 0.05) var resting_animation_speed: float = 0.4
## Reacción al despertar.
@export var wake_reaction: StringName = &"bounce"

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
	NeedsManager.resting_changed.connect(_on_resting_changed)
	_apply_resting(NeedsManager.is_resting(), false)


func _process(delta: float) -> void:
	if NeedsManager.is_resting() or NeedsManager.get_overall_state() != NeedDefinition.State.CRITICAL:
		_attention_elapsed = 0.0
		return
	_attention_elapsed += delta
	if _attention_elapsed < critical_attention_interval or chibbi.is_reacting():
		return
	_attention_elapsed = 0.0
	chibbi.react(attention_reaction)
	# react() pone la expresión propia de la reacción; aquí se mantiene la de reposo.
	chibbi.set_expression(chibbi.rest_expression)
	attention_requested.emit(NeedsManager.get_lowest_need())


func _on_overall_state_changed(state: NeedDefinition.State) -> void:
	if not NeedsManager.is_resting():
		chibbi.set_rest_expression(REST_EXPRESSIONS.get(state, Chibbi.Mood.NEUTRAL))


func _on_resting_changed(resting: bool) -> void:
	_apply_resting(resting, true)


func _apply_resting(resting: bool, animate: bool) -> void:
	chibbi.set_animation_speed(resting_animation_speed if resting else 1.0)
	if resting:
		# No hay cara de sueño todavía: cara tranquila y respiración lenta.
		chibbi.set_rest_expression(Chibbi.Mood.NEUTRAL)
		return
	chibbi.set_rest_expression(REST_EXPRESSIONS.get(NeedsManager.get_overall_state(), Chibbi.Mood.NEUTRAL))
	if animate and not chibbi.is_reacting():
		chibbi.react(wake_reaction)
