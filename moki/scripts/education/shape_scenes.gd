class_name ShapeScenes
extends RefCounted
## Dibujos compuestos de figuras (vista SCENE) en un lienzo de CANVAS píxeles.
## Cada parte: [figura, x, y, ancho, alto, giro, variante de triángulo, color].
## Las partes conservan su geometría real: los cuadrados y círculos ocupan
## rectángulos cuadrados; los rectángulos y óvalos, rectángulos alargados (la
## proporción y si está de pie se deducen del rectángulo). El orden es el de
## dibujo: las últimas quedan encima.

const CANVAS: Vector2 = Vector2(720, 360)

const PALETTE: PackedColorArray = [
	Color("#E85D3F"), Color("#2F7FD1"), Color("#3E9B4F"), Color("#E0B21B"), Color("#8E5BC8"),
	Color("#8B5A3C"), Color("#F08A24"), Color("#7EC8E3"), Color("#EDE6DA"), Color("#7D8790"), Color("#E88AB0"),
]
enum Tint { RED, BLUE, GREEN, YELLOW, PURPLE, BROWN, ORANGE, SKY, SNOW, GRAY, PINK }

const C: int = ShapeGeometry.Shape.CIRCLE
const S: int = ShapeGeometry.Shape.SQUARE
const T: int = ShapeGeometry.Shape.TRIANGLE
const R: int = ShapeGeometry.Shape.RECTANGLE
const O: int = ShapeGeometry.Shape.OVAL
const EQ: int = ShapeGeometry.Triangle.EQUILATERAL
const TALL: int = ShapeGeometry.Triangle.TALL
const WIDE: int = ShapeGeometry.Triangle.WIDE

const SCENES: Array = [
	{"id": "casa", "name": "una casa", "parts": [
		[C, 600, 20, 80, 80, 0, 0, Tint.YELLOW],
		[R, 510, 240, 30, 110, 0, 0, Tint.BROWN],
		[C, 470, 140, 110, 110, 0, 0, Tint.GREEN],
		[S, 220, 150, 200, 200, 0, 0, Tint.ORANGE],
		[T, 200, 30, 240, 120, 0, WIDE, Tint.RED],
		[R, 295, 250, 50, 100, 0, 0, Tint.BROWN],
		[S, 240, 175, 50, 50, 0, 0, Tint.SKY],
		[S, 350, 175, 50, 50, 0, 0, Tint.SKY],
	]},
	{"id": "coche", "name": "un coche", "parts": [
		[R, 628, 90, 14, 150, 0, 0, Tint.GRAY],
		[T, 595, 20, 80, 69, 0, EQ, Tint.YELLOW],
		[R, 240, 70, 240, 100, 0, 0, Tint.BLUE],
		[S, 265, 90, 60, 60, 0, 0, Tint.SKY],
		[S, 395, 90, 60, 60, 0, 0, Tint.SKY],
		[R, 130, 160, 460, 120, 0, 0, Tint.RED],
		[C, 175, 240, 100, 100, 0, 0, Tint.GRAY],
		[C, 445, 240, 100, 100, 0, 0, Tint.GRAY],
	]},
	{"id": "cohete", "name": "un cohete", "parts": [
		[C, 80, 50, 30, 30, 0, 0, Tint.YELLOW],
		[C, 620, 80, 40, 40, 0, 0, Tint.YELLOW],
		[C, 140, 260, 26, 26, 0, 0, Tint.YELLOW],
		[C, 560, 270, 30, 30, 0, 0, Tint.YELLOW],
		[T, 245, 230, 70, 61, 0, EQ, Tint.RED],
		[T, 405, 230, 70, 61, 0, EQ, Tint.RED],
		[O, 325, 300, 70, 45, 0, 0, Tint.ORANGE],
		[R, 310, 100, 100, 200, 0, 0, Tint.SKY],
		[T, 310, 14, 100, 87, 0, EQ, Tint.RED],
		[C, 335, 130, 50, 50, 0, 0, Tint.BLUE],
		[C, 335, 200, 50, 50, 0, 0, Tint.BLUE],
	]},
	{"id": "muneco", "name": "un muñeco de nieve", "parts": [
		[C, 600, 25, 75, 75, 0, 0, Tint.YELLOW],
		[C, 280, 190, 160, 160, 0, 0, Tint.SNOW],
		[C, 305, 85, 110, 110, 0, 0, Tint.SNOW],
		[T, 356, 126, 40, 46, 90, EQ, Tint.ORANGE],
		[S, 330, 10, 60, 60, 0, 0, Tint.PURPLE],
		[R, 300, 70, 120, 30, 0, 0, Tint.PURPLE],
		[C, 348, 225, 24, 24, 0, 0, Tint.BROWN],
		[C, 348, 275, 24, 24, 0, 0, Tint.BROWN],
	]},
	{"id": "barco", "name": "un barco", "parts": [
		[C, 590, 30, 80, 80, 0, 0, Tint.YELLOW],
		[R, 352, 50, 16, 190, 0, 0, Tint.BROWN],
		[S, 368, 30, 30, 30, 0, 0, Tint.RED],
		[T, 370, 60, 119, 170, 0, TALL, Tint.SNOW],
		[T, 250, 100, 98, 140, 0, TALL, Tint.RED],
		[R, 180, 240, 360, 80, 0, 0, Tint.BROWN],
		[O, 70, 290, 80, 50, 0, 0, Tint.ORANGE],
		[C, 160, 280, 20, 20, 0, 0, Tint.SKY],
	]},
	{"id": "tren", "name": "un tren", "parts": [
		[O, 255, 20, 70, 45, 0, 0, Tint.GRAY],
		[O, 300, 5, 62, 40, 0, 0, Tint.GRAY],
		[R, 230, 88, 36, 62, 0, 0, Tint.BROWN],
		[S, 80, 60, 100, 100, 0, 0, Tint.BLUE],
		[S, 105, 80, 50, 50, 0, 0, Tint.SKY],
		[R, 80, 150, 230, 120, 0, 0, Tint.RED],
		[R, 340, 160, 180, 110, 0, 0, Tint.GREEN],
		[S, 400, 180, 60, 60, 0, 0, Tint.SKY],
		[S, 550, 160, 110, 110, 0, 0, Tint.YELLOW],
		[C, 100, 250, 70, 70, 0, 0, Tint.GRAY],
		[C, 220, 250, 70, 70, 0, 0, Tint.GRAY],
		[C, 360, 250, 70, 70, 0, 0, Tint.GRAY],
		[C, 450, 250, 70, 70, 0, 0, Tint.GRAY],
		[C, 570, 250, 70, 70, 0, 0, Tint.GRAY],
	]},
	{"id": "helado", "name": "un helado y una paleta", "parts": [
		[S, 90, 230, 110, 110, 0, 0, Tint.PINK],
		[R, 563, 180, 16, 150, 0, 0, Tint.BROWN],
		[C, 516, 80, 110, 110, 0, 0, Tint.PURPLE],
		[T, 300, 180, 119, 170, 180, TALL, Tint.ORANGE],
		[C, 290, 100, 140, 140, 0, 0, Tint.PINK],
		[C, 345, 70, 30, 30, 0, 0, Tint.RED],
	]},
	{"id": "pez", "name": "un pez", "parts": [
		[R, 60, 220, 22, 130, 0, 0, Tint.GREEN],
		[R, 650, 210, 22, 140, 0, 0, Tint.GREEN],
		[T, 135, 120, 110, 127, 90, EQ, Tint.ORANGE],
		[T, 320, 70, 80, 40, 0, WIDE, Tint.ORANGE],
		[O, 220, 110, 280, 170, 0, 0, Tint.YELLOW],
		[C, 420, 160, 40, 40, 0, 0, Tint.BLUE],
		[C, 560, 60, 40, 40, 0, 0, Tint.SKY],
		[C, 610, 120, 26, 26, 0, 0, Tint.SKY],
		[C, 540, 130, 30, 30, 0, 0, Tint.SKY],
		[S, 300, 300, 50, 50, 0, 0, Tint.GRAY],
	]},
]


## Índices de los dibujos que contienen la figura, del más sencillo (menos
## partes) al más complejo.
static func scenes_with(shape: int) -> Array[int]:
	var result: Array[int] = []
	for i in SCENES.size():
		for part: Array in SCENES[i]["parts"]:
			if part[0] == shape:
				result.append(i)
				break
	result.sort_custom(func(a: int, b: int) -> bool: return SCENES[a]["parts"].size() < SCENES[b]["parts"].size())
	return result


## Tarjetas SHAPE de un dibujo (en orden de dibujo), con su área en el lienzo.
static func build(index: int) -> Array[CardData]:
	var cards: Array[CardData] = []
	for part: Array in SCENES[index]["parts"]:
		var shape: int = part[0]
		var area := Rect2(part[1], part[2], part[3], part[4])
		var rotation: float = part[5]
		var aspect: float = 1.0
		if shape == R or shape == O:
			aspect = maxf(area.size.x, area.size.y) / minf(area.size.x, area.size.y)
			if area.size.y > area.size.x:
				rotation += 90.0  # de pie
		var card := CardData.shape_card(shape, PALETTE[part[7]], part[6], aspect, rotation, 1.0)
		card.area = area
		cards.append(card)
	return cards
