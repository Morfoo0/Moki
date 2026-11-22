@tool
class_name NumberBank
extends ContentBank
## Contenido de una lección de números: los números nuevos, los que se
## repasan, el máximo que se usa en conteos y secuencias, y los objetos para
## contar. Extiende ContentBank para reutilizar tipografías y colores (y para
## encajar en LevelDefinition.content).

## Nombres de los números (índice = número).
const NAMES: PackedStringArray = ["cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez"]
## Forma de cada número, para las pistas.
const SHAPES: Dictionary = {
	1: "El 1 es un palito derechito con una gorrita.",
	2: "El 2 parece un patito nadando en el agua.",
	3: "El 3 tiene dos pancitas redondas, una arriba y otra abajo, abiertas hacia un lado.",
	4: "El 4 parece una sillita al revés, con un palito que baja derecho.",
	5: "El 5 tiene un sombrero plano arriba y una pancita redonda abajo.",
	6: "El 6 es como un caracol: tiene la bolita abajo.",
	7: "El 7 tiene un techo arriba y una pata larga, como un bastón.",
	8: "El 8 parece un muñeco de nieve: una bolita encima de otra.",
	9: "El 9 parece un globo con su hilo: la bolita arriba y el palito abajo.",
	10: "El 10 son dos números juntitos: un 1 y un 0, que es redondo como una rueda.",
}
## Acertijos de cantidad (nunca dicen el número).
const RIDDLES: Dictionary = {
	1: "Adivina, adivinanza: soy flaquito y siempre voy primero. ¿Quién soy?",
	2: "Adivina, adivinanza: soy tantos como tus ojos. ¿Quién soy?",
	3: "Adivina, adivinanza: soy tantas como las ruedas de un triciclo. ¿Quién soy?",
	4: "Adivina, adivinanza: soy tantas como las patas de un perrito. ¿Quién soy?",
	5: "Adivina, adivinanza: soy tantos como los dedos de una mano. ¿Quién soy?",
	6: "Adivina, adivinanza: soy tantas como las patas de una hormiguita. ¿Quién soy?",
	7: "Adivina, adivinanza: soy tantos como los colores del arcoíris. ¿Quién soy?",
	8: "Adivina, adivinanza: soy tantas como las patas de una araña. ¿Quién soy?",
	9: "Adivina, adivinanza: vengo justo antes del diez. ¿Quién soy?",
	10: "Adivina, adivinanza: soy tantos como los dedos de tus dos manos. ¿Quién soy?",
}
## Números que se confunden con cada uno (distractores difíciles).
const SIMILAR: Dictionary = {
	1: [7, 4], 2: [5, 7], 3: [8, 5], 4: [1, 9], 5: [2, 3, 6],
	6: [9, 8, 5], 7: [1, 2], 8: [3, 6, 9], 9: [6, 4], 10: [1, 6],
}
## Cómo distinguir cada número de sus parecidos.
const SIMILAR_HINTS: Dictionary = {
	1: "El 7 se parece al 1, pero tiene un techo largo arriba. El 1 solo tiene una gorrita.",
	2: "El 5 se parece al 2, pero tiene un sombrero plano arriba. El 2 es como un patito.",
	3: "El 8 se parece al 3, pero está cerrado del todo. El 3 está abierto por un lado.",
	4: "El 4 tiene esquinas y un palito que baja derecho. ¿Cuáles tienen esa forma?",
	5: "El 2 se parece al 5, pero el 5 tiene un sombrero plano arriba.",
	6: "El 9 es un 6 de cabeza: el 6 tiene la bolita abajo y el 9 arriba.",
	7: "El 1 se parece al 7, pero el 7 tiene un techo largo arriba.",
	8: "El 3 se parece al 8, pero el 8 está cerrado: son dos bolitas completas.",
	9: "El 6 es un 9 de cabeza: el 9 tiene la bolita arriba y el 6 abajo.",
	10: "El 10 son dos números juntos: un palito y una rueda.",
}
const MAX_SUPPORTED: int = 10

@export_group("Números")
## Números que presenta la lección (los que más aparecen).
@export var numbers: PackedInt32Array = [1, 2]
## Números de lecciones anteriores que se repasan.
@export var review: PackedInt32Array = []
## Probabilidad de que una actividad trabaje un número de repaso.
@export_range(0.0, 1.0) var review_chance: float = 0.25
## Número más alto que se usa en conteos, comparaciones y secuencias.
@export_range(1, 10) var max_number: int = 2

@export_group("Objetos")
## Objetos para contar (WordEntry.word en plural: "manzanas").
@export var objects: Array[WordEntry] = []

## Pesos opcionales por número para pick_target() (los usa Repaso para dar más
## práctica a lo que costó). Vacío = el reparto de siempre.
var target_weights: Dictionary = {}


static func name_of(value: int) -> String:
	return NAMES[value] if value >= 0 and value < NAMES.size() else str(value)


## El número que trabaja una actividad: los nuevos casi siempre; a veces uno
## de repaso. Con dificultad baja se prefiere el más pequeño de los nuevos.
func pick_target(rng: RandomNumberGenerator, difficulty: int) -> int:
	if not target_weights.is_empty():
		return CombinationBank.weighted_pick(Array(numbers), target_weights, rng)
	if not review.is_empty() and rng.randf() < review_chance:
		return review[rng.randi_range(0, review.size() - 1)]
	if difficulty <= 1 and numbers.size() > 1 and rng.randf() < 0.65:
		return numbers[0]
	return numbers[rng.randi_range(0, numbers.size() - 1)]


## Números ya conocidos en esta lección (1..max_number).
func known() -> Array[int]:
	var result: Array[int] = []
	for i in range(1, max_number + 1):
		result.append(i)
	return result


## Distractores numéricos para "target", de más a menos útiles:
## primero los conocidos de la lección y luego otros (parecidos solo con
## dificultad alta; con dificultad baja, los que no se parecen).
func number_distractors(target: int, difficulty: int, rng: RandomNumberGenerator) -> Array[int]:
	var similar: Array = SIMILAR.get(target, [])
	var known_others: Array[int] = []
	for value: int in known():
		if value != target:
			known_others.append(value)
	var others: Array[int] = []
	for value in range(1, MAX_SUPPORTED + 1):
		if value == target or known_others.has(value):
			continue
		if difficulty <= 2 and similar.has(value):
			continue
		others.append(value)
	var result: Array[int] = []
	if difficulty >= 4:
		for value: int in ActivityGenerator.shuffled(similar, rng):
			result.append(value)
	for value: int in ActivityGenerator.shuffled(known_others, rng):
		if not result.has(value):
			result.append(value)
	for value: int in ActivityGenerator.shuffled(others, rng):
		if not result.has(value):
			result.append(value)
	return result


## Forma singular de un objeto ("peces" → "pez", "flores" → "flor").
static func singular(plural: String) -> String:
	if plural.ends_with("ces"):
		return plural.left(-3) + "z"
	if plural.ends_with("res") or plural.ends_with("les"):
		return plural.left(-2)
	return plural.left(-1) if plural.ends_with("s") else plural


## Valores para los textos de una actividad sobre "value" con el objeto "entry".
static func fill_for(value: int, entry: WordEntry = null) -> Dictionary:
	var values := {
		"number": str(value),
		"name": name_of(value),
		"shape": SHAPES.get(value, ""),
		"riddle": RIDDLES.get(value, ""),
		"similar": SIMILAR_HINTS.get(value, ""),
		"fingers": "un dedo" if value == 1 else "%s dedos" % name_of(value),
	}
	if entry != null:
		var feminine: bool = entry.article.begins_with("una")
		values["object"] = entry.word
		values["object_n"] = singular(entry.word) if value == 1 else entry.word
		values["cuantos"] = "cuántas" if feminine else "cuántos"
		values["Cuantos"] = "Cuántas" if feminine else "Cuántos"
	return values
