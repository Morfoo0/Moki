class_name MokiNeedsLink
extends Node
## Traduce el estado de las necesidades (NeedsManager) al comportamiento de Moki.
##
## Moki no depende de las necesidades: este nodo es el único puente.
## Expresión de reposo (prioridad):
##   1. descansando → dormido (con la transición de cabeceo);
##   2. hambre o energía en estado bajo/crítico → irritado por hambre / cansado.
##      Si las dos están bajas, la de peor estado; si empatan, el hambre (se
##      resuelve al momento comiendo; el cansancio ya se resuelve descansando);
##   3. en cualquier otro caso → calmado.
## Hablar y las reacciones van por encima temporalmente (ver Moki) y al terminar
## vuelven a esta expresión, recalculada en cada cambio de estado.
## Principios: sin castigos ni presión. Moki solo pide atención, con calma,
## cuando una necesidad está en estado crítico, y nunca mientras descansa.

## Pide atención (p. ej. para que el HUD resalte una necesidad).
signal attention_requested(need_id: StringName)

@export var moki: Moki
## Animación con la que Moki llama la atención.
@export var attention_reaction: StringName = &"tilt"
## Segundos entre llamadas de atención con una necesidad en estado crítico.
@export var critical_attention_interval: float = 30.0
## Velocidad de la animación de reposo mientras descansa (respiración lenta).
@export_range(0.1, 1.0, 0.05) var resting_animation_speed: float = 0.4
## Reacción al despertar.
@export var wake_reaction: StringName = &"bounce"

const HUNGER: StringName = &"hunger"
const ENERGY: StringName = &"energy"
## Estado a partir del cual una necesidad se nota en la cara.
const LOW_STATE: NeedDefinition.State = NeedDefinition.State.LOW

var _attention_elapsed: float = 0.0


func _ready() -> void:
	if moki == null:
		push_warning("MokiNeedsLink: falta asignar 'moki'.")
		set_process(false)
		return
	NeedsManager.need_state_changed.connect(_on_need_state_changed)
	NeedsManager.needs_loaded.connect(_refresh_rest_expression)
	NeedsManager.resting_changed.connect(_on_resting_changed)
	_apply_resting(NeedsManager.is_resting(), false)


func _process(delta: float) -> void:
	if NeedsManager.is_resting() or NeedsManager.get_overall_state() != NeedDefinition.State.CRITICAL:
		_attention_elapsed = 0.0
		return
	_attention_elapsed += delta
	if _attention_elapsed < critical_attention_interval or moki.is_reacting():
		return
	_attention_elapsed = 0.0
	moki.react(attention_reaction)
	# react() pone la expresión propia de la reacción; aquí se mantiene la de reposo.
	moki.set_expression(moki.rest_expression)
	attention_requested.emit(NeedsManager.get_lowest_need())


## Expresión de reposo según las necesidades (sin descanso).
static func needs_expression(hunger: NeedDefinition.State, energy: NeedDefinition.State) -> Moki.Mood:
	var hungry: bool = hunger >= LOW_STATE
	var tired: bool = energy >= LOW_STATE
	if hungry and tired:
		return Moki.Mood.TIRED if energy > hunger else Moki.Mood.HUNGRY
	if hungry:
		return Moki.Mood.HUNGRY
	if tired:
		return Moki.Mood.TIRED
	return Moki.Mood.NEUTRAL


func _on_need_state_changed(_need_id: StringName, _state: NeedDefinition.State, _previous: NeedDefinition.State) -> void:
	_refresh_rest_expression()


func _refresh_rest_expression() -> void:
	if NeedsManager.is_resting():
		return
	moki.set_rest_expression(needs_expression(NeedsManager.get_state(HUNGER), NeedsManager.get_state(ENERGY)))


func _on_resting_changed(resting: bool) -> void:
	_apply_resting(resting, true)


func _apply_resting(resting: bool, animate: bool) -> void:
	moki.set_animation_speed(resting_animation_speed if resting else 1.0)
	if resting:
		# Cabeceo con "Zzz", pose dormido y respiración lenta.
		moki.set_rest_expression(Moki.Mood.SLEEPING)
		if animate:
			moki.play_sleep_transition()
		return
	_refresh_rest_expression()
	if animate and not moki.is_reacting():
		moki.react(wake_reaction)
