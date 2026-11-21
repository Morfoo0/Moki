class_name ChibbiStage
extends Control
## Zona de la interfaz donde vive Chibbi.
## Coloca a Chibbi (un Node2D) centrado y apoyado abajo, lo escala si no cabe y
## convierte los toques sobre él en reacciones. Al ser un Control, encaja en los
## contenedores de la UI y recibe toques sin activar el picking físico.

## Chibbi que se coloca dentro de este escenario.
@export var chibbi: Chibbi
## Distancia entre el borde inferior y los pies.
@export var bottom_margin: float = 40.0
## Alto de referencia del personaje, incluido el espacio del salto.
@export var character_height: float = 560.0
## Zona táctil alrededor de Chibbi (ancho, alto) en px sin escalar, desde los pies hacia arriba.
@export var touch_area: Vector2 = Vector2(320.0, 480.0)

## Se emite al tocar a Chibbi.
signal tapped
## Se emite al soltar sobre Chibbi datos aceptados por drop_filter.
signal data_dropped(data: Variant)

## Opcional: func() -> bool. Si devuelve true, el toque ya se gestionó y Chibbi
## no hace su reacción aleatoria.
var tap_handler: Callable
## Opcional: func(data) -> bool. Qué datos se pueden soltar sobre Chibbi.
## Si no se asigna, Chibbi no acepta que le suelten nada.
var drop_filter: Callable


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	if chibbi == null:
		return
	var available: float = size.y - bottom_margin
	var fit: float = clampf(available / character_height, 0.3, 1.0)
	chibbi.scale = Vector2.ONE * fit
	chibbi.position = Vector2(size.x / 2.0, size.y - bottom_margin)


func _gui_input(event: InputEvent) -> void:
	# Los toques de pantalla llegan como clic emulado (emulate_mouse_from_touch).
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if chibbi != null and _touch_rect().has_point(click.position):
		accept_event()
		tapped.emit()
		# Si otro sistema gestiona el toque (p. ej. dar de comer), no reacciona por defecto.
		if tap_handler.is_valid() and tap_handler.call():
			return
		chibbi.react_to_tap()


# --- Soltar objetos sobre Chibbi (arrastrar y soltar) --------------------------

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return drop_filter.is_valid() and _touch_rect().has_point(at_position) and drop_filter.call(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	data_dropped.emit(data)


## Solo la zona táctil de Chibbi cuenta como parte del escenario, así los
## objetos que queden detrás del resto del rectángulo siguen recibiendo toques.
func _has_point(point: Vector2) -> bool:
	return chibbi != null and _touch_rect().has_point(point)


func _touch_rect() -> Rect2:
	var area: Vector2 = touch_area * chibbi.scale
	return Rect2(chibbi.position - Vector2(area.x / 2.0, area.y), area)
