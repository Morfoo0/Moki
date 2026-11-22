@tool
class_name MotionLines
extends Node2D
## Dos líneas de movimiento curvas (p. ej. junto a la cola de Moki) que se
## mueven en un vaivén suave. Vectorial, sin PNG.

@export var color: Color = Color(0.353, 0.227, 0.133, 0.55):
	set(value):
		color = value
		queue_redraw()
@export var width: float = 4.0
## Radio de los arcos: el primero y, algo más grande, el segundo.
@export var radius: float = 18.0
## Separación entre los dos arcos.
@export var spacing: float = 12.0
## Ciclos por segundo del vaivén.
@export var speed: float = 0.6
## Amplitud del vaivén en px.
@export var sway: float = 3.0

var _time: float = 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var phase: float = sin(_time * TAU * speed)
	for i in 2:
		var offset := Vector2(spacing * i + sway * phase * (1.0 + i * 0.5), 0.0)
		var r: float = radius + spacing * i
		# Arco abierto hacia la izquierda (hacia la cola), centrado en el origen.
		draw_arc(offset - Vector2(r * 0.6, 0.0), r, -PI * 0.3, PI * 0.3, 16, color, width, true)
