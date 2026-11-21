class_name LessonProgressBar
extends Control
## Progreso de la lección como puntos: hechos (llenos), actual (grande), pendientes.
## Sin números ni puntuaciones.

const DONE: Color = Color("#5DBB4A")
const CURRENT: Color = Color("#FFB020")
const PENDING: Color = Color(0.45, 0.3, 0.2, 0.25)

var total: int = 0
var done: int = 0


func set_progress(done_count: int, total_count: int) -> void:
	done = done_count
	total = total_count
	custom_minimum_size = Vector2(maxi(total, 1) * 44, 40)
	queue_redraw()


func _draw() -> void:
	if total <= 0:
		return
	var step: float = size.x / total
	for i in total:
		var center := Vector2(step * (i + 0.5), size.y / 2.0)
		if i < done:
			draw_circle(center, 13.0, DONE)
		elif i == done:
			draw_circle(center, 16.0, CURRENT)
		else:
			draw_circle(center, 11.0, PENDING)
