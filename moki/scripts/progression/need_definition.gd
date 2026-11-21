@tool
class_name NeedDefinition
extends Resource
## Definición configurable de una necesidad de la mascota.
##
## Convención: 100 = necesidad satisfecha, 0 = necesidad sin atender.
## (El hambre se guarda como "saciedad": 100 = lleno.)

enum State { GOOD, MEDIUM, LOW, CRITICAL }

@export var id: StringName = &""
## Nombre que se muestra al niño.
@export var display_name: String = ""
## Icono del medidor (opcional; mientras no haya arte se muestra la inicial).
@export var icon: Texture2D
## Color identificativo de la necesidad en la interfaz.
@export var color: Color = Color.WHITE

@export_group("Valores")
@export_range(0.0, 100.0, 1.0) var initial_value: float = 100.0
## Puntos que pierde por minuto de juego.
@export_range(0.0, 50.0, 0.1) var decay_per_minute: float = 1.0
## Cambio por minuto mientras Moki descansa (sustituye a la bajada normal).
## Positivo = se recupera (energía); negativo = baja más despacio (hambre).
@export_range(-50.0, 50.0, 0.1) var resting_rate_per_minute: float = 0.0

@export_group("Umbrales")
## Valor mínimo para el estado "bien".
@export_range(0.0, 100.0, 1.0) var good_min: float = 70.0
## Valor mínimo para el estado "medio".
@export_range(0.0, 100.0, 1.0) var medium_min: float = 40.0
## Valor mínimo para el estado "bajo". Por debajo es "crítico".
@export_range(0.0, 100.0, 1.0) var low_min: float = 15.0
## Margen para subir de estado (evita parpadeos cuando el valor ronda un umbral).
@export_range(0.0, 20.0, 0.5) var hysteresis: float = 3.0


## Estado para un valor. Bajar de estado es inmediato; para volver a un estado
## mejor que "previous" hay que superar su umbral más la histéresis.
func state_for(value: float, previous: State = State.GOOD) -> State:
	var raw: State = _raw_state(value)
	if raw >= previous:
		return raw
	# El valor mejoró: solo se acepta el estado mejor si supera el umbral con margen.
	var candidate: State = _raw_state(value - hysteresis)
	return mini(candidate, previous) as State


func _raw_state(value: float) -> State:
	if value >= good_min:
		return State.GOOD
	if value >= medium_min:
		return State.MEDIUM
	if value >= low_min:
		return State.LOW
	return State.CRITICAL
