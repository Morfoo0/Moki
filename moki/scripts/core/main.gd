extends Node
## Punto de entrada del juego. Más adelante puede mostrar un splash
## o cargar la partida guardada antes de ir a la habitación de Chibbi.


func _ready() -> void:
	SceneManager.change_scene.call_deferred(ScenePaths.HOME)
