class_name BigButton
extends Button
## Botón grande y reutilizable para niños en edad preescolar.
## Si se asigna target_scene, navega a esa escena al presionarlo.

@export_file("*.tscn") var target_scene: String = ""
@export var press_scale: float = 0.9

const PRESS_DURATION: float = 0.08


func _ready() -> void:
	resized.connect(_update_pivot)
	_update_pivot()
	button_down.connect(_animate_scale.bind(press_scale))
	button_up.connect(_animate_scale.bind(1.0))
	pressed.connect(_on_pressed)


func _update_pivot() -> void:
	pivot_offset = size / 2.0


func _animate_scale(target: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * target, PRESS_DURATION)


func _on_pressed() -> void:
	if not target_scene.is_empty():
		SceneManager.change_scene(target_scene)
