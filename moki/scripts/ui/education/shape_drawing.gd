class_name ShapeDrawing
extends Control
## Dibuja una figura (CardData SHAPE) con geometría exacta: relleno, contorno
## y, al acertar, un borde de color. Responde a toques solo DENTRO de la
## figura (útil en los dibujos compuestos, donde las partes se tocan entre sí).

const OUTLINE_WIDTH: float = 4.0

var data: CardData
## Margen interior respecto al lado menor (0-0.5).
var margin_ratio: float = 0.0
var highlight: Color = Color(0, 0, 0, 0)


func setup(card: CardData, margin: float = 0.0) -> void:
	data = card
	margin_ratio = margin
	resized.connect(queue_redraw)
	queue_redraw()


func shape_points() -> PackedVector2Array:
	if data == null:
		return PackedVector2Array()
	var margin: float = minf(size.x, size.y) * margin_ratio
	return ShapeGeometry.points(data, Rect2(Vector2(margin, margin), size - Vector2(margin, margin) * 2.0))


func contains_point(point: Vector2) -> bool:
	var points: PackedVector2Array = shape_points()
	return points.size() >= 3 and Geometry2D.is_point_in_polygon(point, points)


func set_highlight(color: Color) -> void:
	highlight = color
	queue_redraw()


func _draw() -> void:
	var points: PackedVector2Array = shape_points()
	if points.size() < 3:
		return
	draw_colored_polygon(points, data.color)
	var outline: PackedVector2Array = points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, data.color.darkened(0.35), OUTLINE_WIDTH, true)
	if highlight.a > 0.0:
		draw_polyline(outline, highlight, OUTLINE_WIDTH * 2.5, true)
