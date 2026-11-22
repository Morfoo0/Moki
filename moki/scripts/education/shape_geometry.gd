class_name ShapeGeometry
extends RefCounted
## Geometría exacta de las figuras del Mundo de Figuras. Todas se dibujan por
## código y se escalan de forma uniforme, así que conservan sus propiedades:
## el cuadrado tiene 4 lados iguales, el rectángulo 2 largos y 2 cortos, el
## óvalo es más ancho que alto y el círculo tiene radio constante.

enum Shape { CIRCLE, SQUARE, TRIANGLE, RECTANGLE, OVAL }

## Triángulos: equilátero, isósceles alto, rectángulo e isósceles ancho (tejados).
enum Triangle { EQUILATERAL, TALL, RIGHT, WIDE }

const ROUND_SEGMENTS: int = 64
## Proporciones (lado largo / lado corto) que nunca se confunden con la figura parecida.
const RECTANGLE_ASPECT: Vector2 = Vector2(1.6, 2.0)
const OVAL_ASPECT: Vector2 = Vector2(1.45, 1.7)
## Giro máximo del cuadrado (girado 45° parece un "rombo" para un niño pequeño).
const SQUARE_MAX_TILT: float = 20.0


static func corners(shape: int) -> int:
	match shape:
		Shape.SQUARE, Shape.RECTANGLE:
			return 4
		Shape.TRIANGLE:
			return 3
	return 0


static func has_corners(shape: int) -> bool:
	return corners(shape) > 0


## Puntos de la figura centrados en el origen, sin girar (el lado largo en horizontal).
static func base_points(shape: int, variant: int = 0, aspect: float = 1.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	match shape:
		Shape.CIRCLE, Shape.OVAL:
			var ry: float = 0.5 / (maxf(aspect, 1.0) if shape == Shape.OVAL else 1.0)
			for i in ROUND_SEGMENTS:
				var angle: float = TAU * i / ROUND_SEGMENTS
				points.append(Vector2(cos(angle) * 0.5, sin(angle) * ry))
		Shape.SQUARE:
			points = PackedVector2Array([Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)])
		Shape.RECTANGLE:
			var half_h: float = 0.5 / maxf(aspect, 1.0)
			points = PackedVector2Array([Vector2(-0.5, -half_h), Vector2(0.5, -half_h), Vector2(0.5, half_h), Vector2(-0.5, half_h)])
		Shape.TRIANGLE:
			match variant:
				Triangle.TALL:
					points = PackedVector2Array([Vector2(0, -0.5), Vector2(0.35, 0.5), Vector2(-0.35, 0.5)])
				Triangle.RIGHT:
					points = PackedVector2Array([Vector2(-0.5, -0.4), Vector2(0.5, 0.4), Vector2(-0.5, 0.4)])
				Triangle.WIDE:
					points = PackedVector2Array([Vector2(0, -0.25), Vector2(0.5, 0.25), Vector2(-0.5, 0.25)])
				_:
					var h: float = sqrt(3.0) / 2.0
					points = PackedVector2Array([Vector2(0, -h / 2.0), Vector2(0.5, h / 2.0), Vector2(-0.5, h / 2.0)])
	return points


## Puntos de una tarjeta SHAPE dentro de "rect": girados, escalados de forma
## uniforme (card.shape_scale) y centrados.
static func points(card: CardData, rect: Rect2) -> PackedVector2Array:
	var base: PackedVector2Array = base_points(card.shape, card.shape_variant, card.shape_aspect)
	var turned := PackedVector2Array()
	var angle: float = deg_to_rad(card.shape_rotation)
	for point: Vector2 in base:
		turned.append(point.rotated(angle))
	var bounds := Rect2(turned[0], Vector2.ZERO)
	for point: Vector2 in turned:
		bounds = bounds.expand(point)
	var scale: float = minf(rect.size.x / maxf(bounds.size.x, 0.0001), rect.size.y / maxf(bounds.size.y, 0.0001))
	scale *= clampf(card.shape_scale, 0.05, 1.0)
	var offset: Vector2 = rect.get_center() - bounds.get_center() * scale
	var result := PackedVector2Array()
	for point: Vector2 in turned:
		result.append(point * scale + offset)
	return result


## Una figura al azar según la dificultad: el tamaño y el color varían desde
## el principio (no deben importar); el giro, desde la dificultad 3; los
## triángulos de otras formas, desde la 2.
static func random_card(shape: int, difficulty: int, rng: RandomNumberGenerator, palette: PackedColorArray) -> CardData:
	var variant: int = 0
	var aspect: float = 1.0
	var rotation: float = 0.0
	match shape:
		Shape.TRIANGLE:
			var variants: Array = [Triangle.EQUILATERAL]
			if difficulty >= 2:
				variants.append(Triangle.TALL)
			if difficulty >= 3:
				variants.append_array([Triangle.RIGHT, Triangle.WIDE])
			variant = variants[rng.randi_range(0, variants.size() - 1)]
			if difficulty >= 3:
				rotation = 15.0 * rng.randi_range(0, 23)
		Shape.RECTANGLE, Shape.OVAL:
			var limits: Vector2 = RECTANGLE_ASPECT if shape == Shape.RECTANGLE else OVAL_ASPECT
			aspect = rng.randf_range(limits.x, limits.y)
			if difficulty >= 2 and rng.randf() < 0.5:
				rotation = 90.0  # de pie
			if difficulty >= 3:
				rotation += rng.randf_range(-15.0, 15.0)
		Shape.SQUARE:
			if difficulty >= 3:
				rotation = rng.randf_range(-SQUARE_MAX_TILT, SQUARE_MAX_TILT)
	var scale: float = rng.randf_range(0.85, 1.0) if difficulty <= 1 else rng.randf_range(0.55, 1.0)
	var tint: Color = palette[rng.randi_range(0, palette.size() - 1)]
	return CardData.shape_card(shape, tint, variant, aspect, rotation, scale)
