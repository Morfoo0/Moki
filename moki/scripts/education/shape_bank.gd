@tool
class_name ShapeBank
extends ContentBank
## Contenido de una lección de figuras: la figura nueva, las que se repasan y
## los objetos cotidianos de cada forma. Extiende ContentBank para reutilizar
## colores y encajar en LevelDefinition.content.

## Nombres y plurales (índice = ShapeGeometry.Shape).
const NAMES: PackedStringArray = ["círculo", "cuadrado", "triángulo", "rectángulo", "óvalo"]
const PLURALS: PackedStringArray = ["círculos", "cuadrados", "triángulos", "rectángulos", "óvalos"]
## Qué distingue a cada figura, con palabras sencillas.
const FACTS: PackedStringArray = [
	"El círculo es redondo, como una rueda: no tiene esquinas ni lados rectos.",
	"El cuadrado tiene 4 lados igual de largos y 4 esquinas.",
	"El triángulo tiene 3 lados y 3 esquinas, como una rebanada de pizza.",
	"El rectángulo tiene 4 esquinas y 4 lados: 2 largos y 2 cortos, como una puerta.",
	"El óvalo es redondo pero alargado, como un huevo: no tiene esquinas.",
]
const RIDDLES: PackedStringArray = [
	"Adivina, adivinanza: soy redondo como una rueda y no tengo ni una esquina. ¿Quién soy?",
	"Adivina, adivinanza: tengo 4 lados igualitos y 4 esquinas. ¿Quién soy?",
	"Adivina, adivinanza: tengo 3 esquinas, como una rebanada de pizza. ¿Quién soy?",
	"Adivina, adivinanza: tengo 4 esquinas, 2 lados largos y 2 cortos, como una puerta. ¿Quién soy?",
	"Adivina, adivinanza: soy redondo pero estirado, como un huevo. ¿Quién soy?",
]
## La figura con la que más se confunde cada una.
const SIMILAR: PackedInt32Array = [
	ShapeGeometry.Shape.OVAL, ShapeGeometry.Shape.RECTANGLE, ShapeGeometry.Shape.SQUARE,
	ShapeGeometry.Shape.SQUARE, ShapeGeometry.Shape.CIRCLE,
]
## Cómo distinguirla de la parecida.
const SIMILAR_HINTS: PackedStringArray = [
	"El óvalo también es redondo, pero está estirado, como un huevo. El círculo es igual de ancho que de alto.",
	"El rectángulo también tiene 4 esquinas, pero tiene 2 lados largos y 2 cortos. El cuadrado tiene sus 4 lados iguales.",
	"Cuenta las esquinas: el triángulo tiene 3 y el cuadrado tiene 4.",
	"El cuadrado también tiene 4 esquinas, pero sus 4 lados son igual de largos. El rectángulo tiene 2 largos y 2 cortos.",
	"El círculo también es redondo, pero es igual de ancho que de alto. El óvalo está estirado, como un huevo.",
]

@export_group("Figuras")
## Figura(s) que presenta la lección.
@export var shapes: PackedInt32Array = [ShapeGeometry.Shape.CIRCLE]
## Figuras de lecciones anteriores que se repasan.
@export var review: PackedInt32Array = []
@export_range(0.0, 1.0) var review_chance: float = 0.25

@export_group("Objetos")
## Objetos cotidianos de todas las formas (también de las aún no aprendidas,
## como "otras cosas" al comparar).
@export var objects: Array[ShapeObject] = []


static func name_of(shape: int) -> String:
	return NAMES[shape]


func pick_target(rng: RandomNumberGenerator, _difficulty: int) -> int:
	if not review.is_empty() and rng.randf() < review_chance:
		return review[rng.randi_range(0, review.size() - 1)]
	return shapes[rng.randi_range(0, shapes.size() - 1)]


## Figuras ya conocidas en esta lección.
func known() -> Array[int]:
	var result: Array[int] = []
	for shape: int in review:
		result.append(shape)
	for shape: int in shapes:
		if not result.has(shape):
			result.append(shape)
	return result


## Otras figuras para comparar con "target": con dificultad baja, primero las
## muy distintas (la parecida al final); con dificultad alta, la parecida primero.
func distractor_shapes(target: int, difficulty: int, rng: RandomNumberGenerator) -> Array[int]:
	var similar: int = SIMILAR[target]
	var others: Array[int] = []
	for shape: int in ActivityGenerator.shuffled(range(NAMES.size()), rng):
		if shape != target and shape != similar:
			others.append(shape)
	var result: Array[int] = []
	if difficulty >= 4:
		result.append(similar)
		result.append_array(others)
	else:
		result.append_array(others)
		result.append(similar)
	return result


func objects_of(shape: int) -> Array[ShapeObject]:
	var result: Array[ShapeObject] = []
	for item: ShapeObject in objects:
		if item != null and item.shape == shape:
			result.append(item)
	return result


func objects_not_of(shape: int) -> Array[ShapeObject]:
	var result: Array[ShapeObject] = []
	for item: ShapeObject in objects:
		if item != null and item.shape != shape:
			result.append(item)
	return result


## Valores para los textos de una actividad sobre "shape".
static func fill_for(shape: int, item: ShapeObject = null) -> Dictionary:
	var values := {
		"name": NAMES[shape],
		"plural": PLURALS[shape],
		"fact": FACTS[shape],
		"riddle": RIDDLES[shape],
		"similar": SIMILAR_HINTS[shape],
		"similar_name": NAMES[SIMILAR[shape]],
	}
	if item != null:
		values["object"] = item.definite()
	return values
