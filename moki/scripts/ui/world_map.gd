class_name WorldMap
extends Control
## Mapa de mundos: se genera a partir de EducationCatalog. Los mundos
## bloqueados o sin niveles aparecen deshabilitados ("Próximamente").

const BUTTON: PackedScene = preload("res://scenes/ui/big_button.tscn")

@onready var _worlds: GridContainer = %Worlds


func _ready() -> void:
	for world: WorldDefinition in EducationProgress.catalog.worlds:
		var playable: bool = EducationProgress.is_world_unlocked(world.id) and not world.levels.is_empty()
		var button: Button = BUTTON.instantiate()
		button.name = "World_%s" % world.id
		button.text = world.title if playable else "%s\n%s" % [world.title, _locked_note(world)]
		button.disabled = not playable
		button.custom_minimum_size = Vector2(320, 130)
		button.add_theme_font_size_override("font_size", 40 if playable else 30)
		if playable:
			button.pressed.connect(SceneManager.change_scene.bind(ScenePaths.LEVEL_MAP, {"world_id": world.id}))
		_worlds.add_child(button)


## Por qué no se puede jugar: aún sin niveles, o falta terminar otro mundo.
func _locked_note(world: WorldDefinition) -> String:
	if not world.levels.is_empty() and not world.unlocked_after_level.is_empty():
		var previous: WorldDefinition = EducationProgress.catalog.world_of(world.unlocked_after_level)
		if previous != null:
			return "(al terminar %s)" % previous.title
	return "(próximamente)"
