@tool
class_name MenuIcon
extends Control
## Icono vectorial minimalista de trazo redondeado (sin PNG): mando de juego o
## casita. Se dibuja ajustado a su tamaño y no recibe toques.

enum Shape { GAMEPAD, HOUSE }

@export var shape: Shape = Shape.GAMEPAD:
	set(value):
		shape = value
		queue_redraw()
@export var color: Color = Color(1, 0.957, 0.878):
	set(value):
		color = value
		queue_redraw()
## Color de los detalles recortados sobre la silueta (cruceta y botones del mando).
@export var detail_color: Color = Color(0.604, 0.42, 0.271):
	set(value):
		detail_color = value
		queue_redraw()
## Grosor del trazo en proporción al lado del icono.
@export_range(0.03, 0.2, 0.01) var stroke: float = 0.09:
	set(value):
		stroke = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var side: float = minf(size.x, size.y)
	var origin: Vector2 = (size - Vector2(side, side)) / 2.0
	var width: float = maxf(side * stroke, 1.5)
	match shape:
		Shape.GAMEPAD:
			_draw_gamepad(origin, side, width)
		Shape.HOUSE:
			_draw_house(origin, side, width)


## Punto en coordenadas normalizadas (0-1) dentro del cuadrado del icono.
func _p(origin: Vector2, side: float, x: float, y: float) -> Vector2:
	return origin + Vector2(x, y) * side


func _draw_gamepad(o: Vector2, s: float, w: float) -> void:
	# Silueta rellena: cuerpo redondeado + dos asas abajo.
	var corner: float = 0.14 * s
	var body := Rect2(_p(o, s, 0.08, 0.28), Vector2(0.84, 0.36) * s)
	draw_rect(body.grow_individual(-corner, 0, -corner, 0), color)
	draw_rect(body.grow_individual(0, -corner, 0, -corner), color)
	for c: Vector2 in [body.position + Vector2(corner, corner), Vector2(body.end.x - corner, body.position.y + corner),
			Vector2(body.position.x + corner, body.end.y - corner), body.end - Vector2(corner, corner)]:
		draw_circle(c, corner, color)
	draw_circle(_p(o, s, 0.25, 0.64), 0.16 * s, color)
	draw_circle(_p(o, s, 0.75, 0.64), 0.16 * s, color)
	# Cruceta y botones "huecos" (color del botón).
	var cross: Vector2 = _p(o, s, 0.28, 0.47)
	var arm: float = 0.09 * s
	draw_line(cross + Vector2(-arm, 0), cross + Vector2(arm, 0), detail_color, w, true)
	draw_line(cross + Vector2(0, -arm), cross + Vector2(0, arm), detail_color, w, true)
	draw_circle(_p(o, s, 0.67, 0.41), w * 0.7, detail_color)
	draw_circle(_p(o, s, 0.77, 0.52), w * 0.7, detail_color)


func _draw_house(o: Vector2, s: float, w: float) -> void:
	var roof: PackedVector2Array = [_p(o, s, 0.12, 0.48), _p(o, s, 0.5, 0.14), _p(o, s, 0.88, 0.48)]
	draw_polyline(roof, color, w, true)
	var walls: PackedVector2Array = [_p(o, s, 0.24, 0.42), _p(o, s, 0.24, 0.86),
		_p(o, s, 0.76, 0.86), _p(o, s, 0.76, 0.42)]
	draw_polyline(walls, color, w, true)
	# Puerta redondeada arriba.
	var door: PackedVector2Array = [_p(o, s, 0.42, 0.86), _p(o, s, 0.42, 0.64)]
	draw_polyline(door, color, w, true)
	draw_arc(_p(o, s, 0.5, 0.64), 0.08 * s, PI, TAU, 16, color, w, true)
	draw_line(_p(o, s, 0.58, 0.64), _p(o, s, 0.58, 0.86), color, w, true)
	# Remates redondos en las esquinas del tejado y la base.
	for point: Vector2 in [roof[0], roof[1], roof[2], walls[1], walls[2]]:
		draw_circle(point, w / 2.0, color)
