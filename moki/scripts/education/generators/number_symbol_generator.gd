@tool
class_name NumberSymbolGenerator
extends ActivityGenerator
## Actividades con el símbolo de los números (necesita un NumberBank).
## - MATCH: "busca el mismo número" (enunciado con el numeral; CHOICE).
## - NAME: "toca el número tres" (nombre → símbolo; CHOICE).
## - GRID: "busca todos los 3" entre números parecidos (SEARCH).
## - ODD_ONE_OUT: varios 3 en distintas tipografías y un intruso (CHOICE).
## - HIDDEN: el número escondido entre dibujos (SEARCH).
## - SEQUENCE: "2 3 _ 5: ¿qué número falta?" (CHOICE). Nunca falta el primero.
## - ORDER: tocar los números del más pequeño al más grande (SEARCH ordenado).

enum Mode { MATCH, NAME, GRID, ODD_ONE_OUT, HIDDEN, SEQUENCE, ORDER }

@export var mode: Mode = Mode.MATCH

## Marca del hueco en una secuencia ("2   3   ?   5").
const GAP: String = "?"


func generate(rng: RandomNumberGenerator, difficulty: int, bank: ContentBank) -> ActivityInstance:
	var numbers := bank as NumberBank
	var instance := ActivityInstance.new()
	var correct_cards: Array[CardData] = []
	var target: int = numbers.pick_target(rng, difficulty)
	instance.fill_values = NumberBank.fill_for(target)
	instance.model_card = CardData.number(target, 0, 150)
	match mode:
		Mode.MATCH, Mode.NAME:
			var count: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
			if mode == Mode.MATCH:
				instance.prompt_card = CardData.number(target, 0, 110)
				instance.model_card = null  # el modelo ya está a la vista
			var answer := styled_number(target, difficulty, bank, rng)
			correct_cards.append(answer)
			instance.cards.append(answer)
			for value: int in numbers.number_distractors(target, difficulty, rng).slice(0, count - 1):
				instance.cards.append(styled_number(value, difficulty, bank, rng))
		Mode.GRID:
			var cells: int = by_difficulty([6, 8, 9, 12, 12], difficulty)
			var targets: int = by_difficulty([2, 2, 3, 3, 4], difficulty)
			var pool: Array = numbers.number_distractors(target, difficulty, rng).slice(0, by_difficulty([2, 3, 3, 4, 4], difficulty))
			for i in cells:
				var is_target: bool = i < targets
				var card := styled_number(target if is_target else pick(pool, rng), difficulty, bank, rng, 72)
				instance.cards.append(card)
				if is_target:
					correct_cards.append(card)
		Mode.ODD_ONE_OUT:
			var copies: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
			var fonts: Array = shuffled(range(bank.font_count()), rng)
			for i in copies:
				var tint: Color = bank.colors[rng.randi_range(0, bank.colors.size() - 1)]
				instance.cards.append(CardData.number(target, fonts[i % fonts.size()], 110, tint))
			var pool: Array = NumberBank.SIMILAR.get(target, []) if difficulty >= 3 else \
				numbers.number_distractors(target, difficulty, rng).slice(0, 2)
			var intruder := styled_number(pick(pool, rng), difficulty, bank, rng)
			correct_cards.append(intruder)
			instance.cards.append(intruder)
		Mode.HIDDEN:
			var cells: int = by_difficulty([6, 6, 8, 9, 12], difficulty)
			var targets: int = 1 if difficulty <= 3 else 2
			var images: Array = sample(numbers.objects, cells - targets, rng)
			for i in targets:
				var card := styled_number(target, difficulty, bank, rng, 80)
				instance.cards.append(card)
				correct_cards.append(card)
			var numbers_left: int = 0 if difficulty <= 2 else (cells - targets) / 3
			var pool: Array = numbers.number_distractors(target, difficulty, rng).slice(0, 3)
			for i in cells - targets:
				if i < numbers_left:
					instance.cards.append(styled_number(pick(pool, rng), difficulty, bank, rng, 80))
				else:
					instance.cards.append(CardData.image(images[i % images.size()]))
		Mode.SEQUENCE:
			_build_sequence(instance, correct_cards, numbers, target, difficulty, rng)
		Mode.ORDER:
			_build_order(instance, numbers, target, difficulty, rng)
			instance.signature = signature_of("ORDER", instance.cards)
			return instance
	shuffle_cards(instance, correct_cards, rng)
	instance.signature = signature_of(Mode.keys()[mode], instance.cards)
	if instance.prompt_card != null:
		instance.signature += "|" + instance.prompt_card.text
	return instance


## Fila de números consecutivos con un hueco (nunca el primero).
func _build_sequence(instance: ActivityInstance, correct_cards: Array[CardData], numbers: NumberBank,
		target: int, difficulty: int, rng: RandomNumberGenerator) -> void:
	var missing: int = maxi(target, 2)
	var length: int = mini(by_difficulty([3, 3, 4, 4, 5], difficulty), numbers.max_number)
	var start: int = 1
	while length >= 2:
		var low: int = maxi(1, missing - length + 1)
		var high: int = mini(missing - 1, numbers.max_number - length + 1)
		if low <= high:
			start = rng.randi_range(low, high)
			break
		length -= 1
	var parts: PackedStringArray = []
	for value in range(start, start + length):
		parts.append(GAP if value == missing else str(value))
	var text: String = "   ".join(parts)
	instance.fill_values = NumberBank.fill_for(missing)
	instance.fill_values["sequence"] = text
	instance.fill_values["first"] = str(start)
	var prompt := CardData.letter(text, 0, 64)
	prompt.kind = CardData.Kind.WORD
	prompt.wide = true
	instance.prompt_card = prompt
	instance.model_card = null  # sería la respuesta
	var count: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
	var options: Array[int] = []
	if difficulty >= 3:
		for value: int in [missing + 1, missing - 1, missing + 2, missing - 2]:
			if value >= 1 and value <= NumberBank.MAX_SUPPORTED:
				options.append(value)
	for value: int in numbers.number_distractors(missing, difficulty, rng):
		if not options.has(value):
			options.append(value)
	var answer := styled_number(missing, difficulty, numbers, rng)
	correct_cards.append(answer)
	instance.cards.append(answer)
	for value: int in options.slice(0, count - 1):
		instance.cards.append(styled_number(value, difficulty, numbers, rng))


## Números desordenados que hay que tocar de menor a mayor. Con dificultad
## alta, no consecutivos.
func _build_order(instance: ActivityInstance, numbers: NumberBank, target: int, difficulty: int,
		rng: RandomNumberGenerator) -> void:
	var length: int = mini(by_difficulty([2, 3, 3, 4, 5], difficulty), numbers.max_number)
	var values: Array[int] = []
	if difficulty >= 4 and numbers.max_number > length:
		values.append(target)
		for value: int in shuffled(numbers.known(), rng):
			if values.size() >= length:
				break
			if value != target:
				values.append(value)
	else:
		var start: int = rng.randi_range(maxi(1, target - length + 1), mini(target, numbers.max_number - length + 1))
		for value in range(start, start + length):
			values.append(value)
	values.sort()
	instance.model_card = null
	instance.ordered = true
	instance.fill_values["first_value"] = str(values[0])
	var cards: Array[CardData] = []
	for value: int in values:
		cards.append(styled_number(value, difficulty, numbers, rng))
	for card: CardData in shuffled(cards, rng):
		instance.cards.append(card)
	# Respuestas en orden creciente; no hay distractores que retirar.
	for card: CardData in cards:
		instance.correct.append(instance.cards.find(card))
