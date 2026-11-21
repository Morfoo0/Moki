class_name BubbleTail
extends Control
## Cola del bocadillo: triángulo que sale del borde izquierdo del bocadillo
## y apunta hacia el retrato de Moki.

var fill: Color = Color.WHITE
var border: Color = Color(0.45, 0.3, 0.2)
const BORDER_WIDTH: float = 4.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var mid: float = size.y * 0.5
	# La base se solapa con el borde del bocadillo (a la derecha) y la punta
	# apunta a la boca del retrato (a la izquierda, algo más abajo).
	var base_top := Vector2(size.x + BORDER_WIDTH, mid - 20.0)
	var base_bottom := Vector2(size.x + BORDER_WIDTH, mid + 16.0)
	var tip := Vector2(0.0, mid + 26.0)
	draw_colored_polygon(PackedVector2Array([base_top, tip, base_bottom]), fill)
	draw_line(base_top - Vector2(BORDER_WIDTH, 0), tip, border, BORDER_WIDTH, true)
	draw_line(tip, base_bottom - Vector2(BORDER_WIDTH, 0), border, BORDER_WIDTH, true)
