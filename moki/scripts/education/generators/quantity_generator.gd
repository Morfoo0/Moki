@tool
class_name QuantityGenerator
extends ActivityGenerator
## Actividades de cantidad: contar, relacionar número y cantidad, comparar y
## clasificar (necesita un NumberBank). En cada actividad todos los grupos usan
## el mismo objeto (no se mezclan objetos al contar).
## - COUNT: "¿cuántas manzanas hay?" (enunciado con el grupo → elegir número).
## - FIND_GROUP: "¿dónde hay 3 manzanas?" (número → elegir grupo).
## - COUNT_TAP: "toca 3 manzanas" entre más manzanas (SEARCH; Moki cuenta).
## - COMPARE: "¿dónde hay más?" (o "menos" con dificultad alta). Nunca empatan.
## - SORT: grupos a la cesta de su número (SORT).

enum Mode { COUNT, FIND_GROUP, COUNT_TAP, COMPARE, SORT }

@export var mode: Mode = Mode.COUNT

## Máximo de tarjetas en "toca N" (cabe en la cuadrícula de SearchView).
const MAX_TAP_CARDS: int = 12
## Cantidad máxima por grupo en clasificar (tarjetas pequeñas; se cuentan bien).
const SORT_MAX_AMOUNT: int = 6


func generate(rng: RandomNumberGenerator, difficulty: int, bank: ContentBank) -> ActivityInstance:
	var numbers := bank as NumberBank
	var instance := ActivityInstance.new()
	var correct_cards: Array[CardData] = []
	var target: int = numbers.pick_target(rng, difficulty)
	var entry: WordEntry = pick(numbers.objects, rng)
	instance.fill_values = NumberBank.fill_for(target, entry)
	instance.model_card = null  # en contar, el modelo sería la respuesta
	match mode:
		Mode.COUNT:
			instance.prompt_card = CardData.group(entry, target, group_layout(target, difficulty, rng), rng.randi())
			instance.prompt_card.wide = true  # hasta 10 objetos grandes, en 2 filas
			var others: Array[int] = _other_amounts(numbers, target, difficulty, rng)
			var count: int = mini(by_difficulty([2, 3, 3, 4, 4], difficulty), others.size() + 1)
			var answer := styled_number(target, mini(difficulty, 3), bank, rng)
			correct_cards.append(answer)
			instance.cards.append(answer)
			for value: int in others.slice(0, count - 1):
				instance.cards.append(styled_number(value, mini(difficulty, 3), bank, rng))
		Mode.FIND_GROUP:
			instance.prompt_card = CardData.number(target, 0, 110)
			var others: Array[int] = _other_amounts(numbers, target, difficulty, rng)
			var count: int = mini(by_difficulty([2, 2, 3, 3, 3], difficulty), others.size() + 1)
			var answer := CardData.group(entry, target, group_layout(target, difficulty, rng), rng.randi())
			correct_cards.append(answer)
			instance.cards.append(answer)
			for value: int in others.slice(0, count - 1):
				instance.cards.append(CardData.group(entry, value, group_layout(value, difficulty, rng), rng.randi()))
		Mode.COUNT_TAP:
			var total: int = mini(target + by_difficulty([1, 2, 2, 3, 3], difficulty), MAX_TAP_CARDS)
			for i in total:
				var card := CardData.image(entry)
				instance.cards.append(card)
				correct_cards.append(card)
			instance.required = target
			instance.count_feedback = true
			shuffle_cards(instance, correct_cards, rng)
			instance.signature = "COUNT_TAP|%s|%d|%d" % [entry.word, target, total]
			return instance
		Mode.COMPARE:
			var less: bool = difficulty >= 4 and rng.randf() < 0.5
			instance.fill_values["more_less"] = "menos" if less else "más"
			instance.fill_values["bigger_smaller"] = "más pequeño" if less else "más grande"
			var others: Array[int] = _other_amounts(numbers, target, difficulty, rng)
			var groups: int = mini(2 if difficulty <= 3 else 3, others.size() + 1)
			var amounts: Array[int] = [target]
			amounts.append_array(others.slice(0, groups - 1))
			var best: int = amounts.min() if less else amounts.max()
			var same_layout: CardData.Layout = CardData.Layout.GRID
			for amount: int in amounts:
				var arrangement: CardData.Layout = same_layout if difficulty <= 3 else group_layout(amount, difficulty, rng)
				var card := CardData.group(entry, amount, arrangement, rng.randi())
				instance.cards.append(card)
				if amount == best:
					correct_cards.append(card)
		Mode.SORT:
			var pair: Vector2i = _sort_pair(numbers, rng)
			var a: int = pair.x
			var b: int = pair.y
			instance.bins.append(CardData.number(a, 0, 90))
			instance.bins.append(CardData.number(b, 0, 90))
			instance.fill_values["a"] = str(a)
			instance.fill_values["b"] = str(b)
			instance.fill_values["name_a"] = NumberBank.name_of(a)
			instance.fill_values["name_b"] = NumberBank.name_of(b)
			var count: int = by_difficulty([3, 4, 4, 5, 6], difficulty)
			for i in count:
				var amount: int = a if i % 2 == 0 else b
				var item: WordEntry = entry if difficulty <= 2 else pick(numbers.objects, rng)
				var card := CardData.group(item, amount, group_layout(amount, difficulty, rng), rng.randi())
				card.category = 0 if amount == a else 1
				instance.cards.append(card)
				correct_cards.append(card)
	shuffle_cards(instance, correct_cards, rng)
	instance.signature = signature_of(Mode.keys()[mode], instance.cards)
	if instance.prompt_card != null:
		instance.signature += "|" + instance.prompt_card.token()
	return instance


## Cestas de SORT: los números de la lección si sus grupos caben bien en las
## tarjetas pequeñas de clasificar (hasta SORT_MAX_AMOUNT); si no, una pareja
## de números de repaso (p. ej. 5 y 6 en la lección del 7 y el 8).
static func _sort_pair(numbers: NumberBank, rng: RandomNumberGenerator) -> Vector2i:
	# Banco con muchos números (Combinación: 1-10): una pareja seguida al azar,
	# siempre legible (hasta SORT_MAX_AMOUNT). Con 2 números, como siempre.
	if numbers.numbers.size() > 2:
		var first: int = rng.randi_range(maxi(1, numbers.numbers[0]), mini(numbers.max_number, SORT_MAX_AMOUNT) - 1)
		return Vector2i(first, first + 1)
	var a: int = numbers.numbers[0]
	var b: int = numbers.numbers[1] if numbers.numbers.size() > 1 else mini(a + 1, numbers.max_number)
	if b <= SORT_MAX_AMOUNT:
		return Vector2i(a, b)
	var starts: Array[int] = []
	for value: int in numbers.review:
		if value + 1 <= SORT_MAX_AMOUNT and numbers.review.has(value + 1):
			starts.append(value)
	if starts.is_empty():
		return Vector2i(SORT_MAX_AMOUNT - 1, SORT_MAX_AMOUNT)
	# Preferencia por las parejas más altas (las más recientes).
	starts.sort()
	var start: int = starts[maxi(0, starts.size() - 1 - rng.randi_range(0, mini(2, starts.size() - 1)))]
	return Vector2i(start, start + 1)


## Otras cantidades (1..max_number, sin "target"): con dificultad baja primero
## las más lejanas (fácil de distinguir); con dificultad alta, las más cercanas.
static func _other_amounts(numbers: NumberBank, target: int, difficulty: int,
		rng: RandomNumberGenerator) -> Array[int]:
	var result: Array[int] = []
	for value: int in shuffled(numbers.known(), rng):
		if value != target:
			result.append(value)
	var near_first: bool = difficulty >= 3
	result.sort_custom(func(x: int, y: int) -> bool:
		var dx: int = absi(x - target)
		var dy: int = absi(y - target)
		return dx < dy if near_first else dx > dy)
	return result
