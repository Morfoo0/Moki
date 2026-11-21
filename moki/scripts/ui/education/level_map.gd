class_name LevelMap
extends Control
## Mapa de niveles de un mundo: orden fijo. Desbloqueados (jugables),
## completados (✓) y próximos (bloqueados). Se genera a partir de los datos.

const BUTTON: PackedScene = preload("res://scenes/ui/big_button.tscn")

var world: WorldDefinition

@onready var _title: Label = %Title
@onready var _levels: HBoxContainer = %Levels


func _ready() -> void:
	var params: Dictionary = SceneManager.get_params()
	world = EducationProgress.catalog.get_world(StringName(params.get("world_id", "letters")))
	_title.text = world.title
	var number: int = 0
	for level: LevelDefinition in world.levels:
		number += 1
		var unlocked: bool = EducationProgress.is_level_unlocked(level.id)
		var done: bool = EducationProgress.times_completed(level.id) > 0
		var button: Button = _add_button("%d\n%s%s" % [number, level.title, "  ✓" if done else ""], not unlocked)
		button.name = "Level_%s" % level.id
		if unlocked:
			button.pressed.connect(SceneManager.change_scene.bind(ScenePaths.LESSON, {"level_id": level.id}))
	for title: String in world.upcoming_levels:
		number += 1
		_add_button("%d\n%s\n(próximamente)" % [number, title], true)


func _add_button(text: String, locked: bool) -> Button:
	var button: Button = BUTTON.instantiate()
	button.text = text
	button.disabled = locked
	button.custom_minimum_size = Vector2(200, 200)
	button.add_theme_font_size_override("font_size", 30 if not locked else 24)
	_levels.add_child(button)
	return button
