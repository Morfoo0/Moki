class_name NeedsHud
extends PanelContainer
## Fila de medidores de necesidades. Crea un NeedMeter por cada necesidad de
## NeedsManager, así que una necesidad nueva en la configuración aparece sola.

signal need_selected(need_id: StringName)

const METER_SCENE: PackedScene = preload("res://scenes/ui/need_meter.tscn")

var _meters: Dictionary[StringName, NeedMeter] = {}

@onready var _row: HBoxContainer = %Meters


func _ready() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(1, 0.98, 0.93, 0.92)
	panel.border_color = Color(0.96, 0.73, 0.45)
	panel.set_border_width_all(5)
	panel.set_corner_radius_all(28)
	panel.set_content_margin_all(14)
	add_theme_stylebox_override("panel", panel)

	for definition: NeedDefinition in NeedsManager.get_definitions():
		var meter: NeedMeter = METER_SCENE.instantiate()
		_row.add_child(meter)
		meter.setup(definition)
		meter.set_value(NeedsManager.get_value(definition.id))
		meter.set_state(NeedsManager.get_state(definition.id))
		meter.pressed.connect(func(need_id: StringName) -> void: need_selected.emit(need_id))
		_meters[definition.id] = meter
	NeedsManager.need_changed.connect(_on_need_changed)
	NeedsManager.need_state_changed.connect(_on_need_state_changed)


func get_meter(need_id: StringName) -> NeedMeter:
	return _meters.get(need_id)


func highlight(need_id: StringName) -> void:
	var meter: NeedMeter = get_meter(need_id)
	if meter != null:
		meter.highlight()


func _on_need_changed(need_id: StringName, value: float) -> void:
	var meter: NeedMeter = get_meter(need_id)
	if meter != null:
		meter.set_value(value)


func _on_need_state_changed(need_id: StringName, state: NeedDefinition.State, _previous: NeedDefinition.State) -> void:
	var meter: NeedMeter = get_meter(need_id)
	if meter != null:
		meter.set_state(state)
