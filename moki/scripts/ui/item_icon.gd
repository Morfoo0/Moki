@tool
class_name ItemIcon
extends Control
## Dibuja el icono de un objeto. Si el ItemDefinition no tiene "icon", dibuja un
## icono PROVISIONAL vectorial según "placeholder" (manzana, plátano, galleta,
## luna, sol). Al asignar el arte definitivo en el .tres, se usa automáticamente.

@export var item: ItemDefinition:
	set(value):
		item = value
		queue_redraw()
## Icono provisional a dibujar si no hay item (p. ej. el botón de descanso).
@export var placeholder: ItemDefinition.Placeholder = ItemDefinition.Placeholder.NONE:
	set(value):
		placeholder = value
		queue_redraw()
## Color del fondo sobre el que se dibuja (para recortar la luna creciente).
@export var background_color: Color = Color(1, 0.98, 0.93)

const OUTLINE: Color = Color(0.45, 0.3, 0.2)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if item != null and item.icon != null:
		var tex_size: Vector2 = item.icon.get_size()
		var k: float = minf(size.x / tex_size.x, size.y / tex_size.y)
		var draw_size: Vector2 = tex_size * k
		draw_texture_rect(item.icon, Rect2((size - draw_size) / 2.0, draw_size), false)
		return
	var shape: ItemDefinition.Placeholder = item.placeholder if item != null else placeholder
	var s: float = minf(size.x, size.y)
	var o: Vector2 = (size - Vector2(s, s)) / 2.0
	match shape:
		ItemDefinition.Placeholder.APPLE:
			_draw_apple(o, s)
		ItemDefinition.Placeholder.BANANA:
			_draw_banana(o, s)
		ItemDefinition.Placeholder.COOKIE:
			_draw_cookie(o, s)
		ItemDefinition.Placeholder.MOON:
			_draw_moon(o, s)
		ItemDefinition.Placeholder.SUN:
			_draw_sun(o, s)


func _p(o: Vector2, s: float, x: float, y: float) -> Vector2:
	return o + Vector2(x, y) * s


func _draw_apple(o: Vector2, s: float) -> void:
	draw_line(_p(o, s, 0.5, 0.26), _p(o, s, 0.55, 0.1), Color("#8B5A2B"), s * 0.06, true)
	draw_circle(_p(o, s, 0.5, 0.58), s * 0.36 + s * 0.03, OUTLINE.darkened(0.1))
	draw_circle(_p(o, s, 0.5, 0.58), s * 0.36, Color("#F0453A"))
	draw_circle(_p(o, s, 0.38, 0.47), s * 0.08, Color(1, 1, 1, 0.55))
	var leaf := PackedVector2Array([_p(o, s, 0.56, 0.17), _p(o, s, 0.7, 0.07), _p(o, s, 0.82, 0.1), _p(o, s, 0.7, 0.2)])
	draw_colored_polygon(leaf, Color("#5DBB4A"))


func _draw_banana(o: Vector2, s: float) -> void:
	var center: Vector2 = _p(o, s, 0.5, -0.05)
	var radius: float = s * 0.6
	draw_arc(center, radius, PI * 0.22, PI * 0.78, 24, OUTLINE, s * 0.25, true)
	draw_arc(center, radius, PI * 0.22, PI * 0.78, 24, Color("#FFD43B"), s * 0.19, true)
	draw_arc(center, radius - s * 0.05, PI * 0.3, PI * 0.7, 18, Color(1, 1, 1, 0.35), s * 0.04, true)
	for a: float in [PI * 0.22, PI * 0.78]:
		draw_circle(center + Vector2.from_angle(a) * radius, s * 0.05, Color("#7A5230"))


func _draw_cookie(o: Vector2, s: float) -> void:
	draw_circle(_p(o, s, 0.5, 0.5), s * 0.41, OUTLINE)
	draw_circle(_p(o, s, 0.5, 0.5), s * 0.38, Color("#E8A85C"))
	draw_circle(_p(o, s, 0.5, 0.5), s * 0.3, Color("#F0BC74"))
	for chip: Vector2 in [Vector2(0.37, 0.38), Vector2(0.6, 0.34), Vector2(0.5, 0.55), Vector2(0.34, 0.62), Vector2(0.66, 0.62)]:
		draw_circle(_p(o, s, chip.x, chip.y), s * 0.05, Color("#5B3A1E"))


func _draw_moon(o: Vector2, s: float) -> void:
	draw_circle(_p(o, s, 0.5, 0.5), s * 0.36, Color("#FFD43B"))
	draw_circle(_p(o, s, 0.36, 0.4), s * 0.31, background_color)
	draw_circle(_p(o, s, 0.72, 0.2), s * 0.04, Color("#FFD43B"))
	draw_circle(_p(o, s, 0.82, 0.38), s * 0.03, Color("#FFD43B"))


func _draw_sun(o: Vector2, s: float) -> void:
	var c: Vector2 = _p(o, s, 0.5, 0.5)
	for i in 8:
		var dir: Vector2 = Vector2.from_angle(i * TAU / 8.0)
		draw_line(c + dir * s * 0.28, c + dir * s * 0.44, Color("#FFB020"), s * 0.07, true)
	draw_circle(c, s * 0.24, Color("#FFD43B"))
