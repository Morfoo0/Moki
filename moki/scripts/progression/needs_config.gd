@tool
class_name NeedsConfig
extends Resource
## Configuración global del sistema de necesidades.
## Para añadir una necesidad basta con añadir una NeedDefinition a "needs".

@export var needs: Array[NeedDefinition] = []

@export_group("Tiempo")
## Cada cuántos segundos se aplica la bajada (y se emiten señales).
@export_range(0.1, 10.0, 0.1) var tick_interval: float = 1.0
## Multiplicador de velocidad (útil para probar; 1 = tiempo real).
@export_range(0.0, 600.0, 0.1) var time_scale: float = 1.0
## Valor mínimo al que puede bajar una necesidad (sin castigos: nunca "muere").
@export_range(0.0, 100.0, 1.0) var min_value: float = 0.0

@export_group("App cerrada")
## Si es true, al volver se aplica la bajada del tiempo que la app estuvo cerrada.
@export var offline_decay: bool = false
## Máximo de minutos de ausencia que se tienen en cuenta.
@export_range(0.0, 1440.0, 1.0) var offline_max_minutes: float = 60.0
## La bajada por ausencia nunca deja una necesidad por debajo de este valor.
@export_range(0.0, 100.0, 1.0) var offline_floor: float = 30.0
## Si Moki se dejó descansando, minutos de ausencia que cuentan para recuperarse.
## (Solo se aplican las recuperaciones; nunca baja nada mientras la app está cerrada.)
@export_range(0.0, 1440.0, 1.0) var offline_rest_max_minutes: float = 480.0

@export_group("Descanso")
## Moki se despierta solo cuando todas las necesidades que se recuperan al
## descansar llegan a 100.
@export var wake_when_rested: bool = true

@export_group("Guardado")
## Cada cuántos segundos se guarda automáticamente (0 = solo en eventos).
@export_range(0.0, 600.0, 1.0) var autosave_interval: float = 30.0


func get_definition(need_id: StringName) -> NeedDefinition:
	for definition: NeedDefinition in needs:
		if definition != null and definition.id == need_id:
			return definition
	return null
