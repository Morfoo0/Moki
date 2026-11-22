@tool
class_name CombinationGenerator
extends ActivityGenerator
## Actividades del Mundo de Combinación (necesita un CombinationBank). Usan lo
## enseñado en Letras (vocales y sus dibujos), Números (1-10) y Figuras.
##
## Vocales entre vocales:
## - VOWEL_PICK: "toca la O" entre otras vocales.
## - VOWEL_SOUND: "Moki dice «iii»: ¿qué vocal suena así?".
## - VOWEL_CASE: la pareja pequeñita (o grande) de una vocal.
## - VOWEL_GRID: "busca todas las E" entre vocales (SEARCH).
## - VOWEL_INITIAL: un dibujo → "¿con qué vocal empieza?".
## - IMAGE_FOR_VOWEL: "¿qué dibujo empieza con U?".
## - FIND_IMAGES: "toca los dibujos que empiezan con A" (SEARCH).
## - WORD_VOWEL: "toca las O de la palabra" (SEARCH).
## - SORT_VOWELS: dibujos a la cesta de su vocal inicial (SORT).
## Figuras + números:
## - COUNT_SHAPES: conjunto de figuras mezcladas → "¿cuántos triángulos hay?".
## - COMPARE_SHAPES: "¿dónde hay más (o menos) círculos?" entre dos conjuntos.
## - TAP_N_SHAPES: "toca 3 cuadrados" entre figuras mezcladas (Moki cuenta).
## - SCENE_COUNT: contar las figuras de un dibujo tocándolas (Moki cuenta).
## - CORNERS_SHAPE: "¿qué figura tiene 3 esquinas?" (una sola válida).
## - SORT_ROUND: figuras redondas / con esquinas (SORT).
## Letras + números:
## - VOWEL_COUNT: dibujos mezclados → "¿cuántos empiezan con A?".
## - TAP_N_VOWEL: "toca 4 letras E" (Moki cuenta).
## - SORT_SYMBOLS: letras / números (y figuras si with_shapes) (SORT).

enum Mode {
	VOWEL_PICK, VOWEL_SOUND, VOWEL_CASE, VOWEL_GRID, VOWEL_INITIAL, IMAGE_FOR_VOWEL, FIND_IMAGES,
	WORD_VOWEL, SORT_VOWELS, COUNT_SHAPES, COMPARE_SHAPES, TAP_N_SHAPES, SCENE_COUNT, CORNERS_SHAPE,
	SORT_ROUND, VOWEL_COUNT, TAP_N_VOWEL, SORT_SYMBOLS,
}

@export var mode: Mode = Mode.VOWEL_PICK
## SORT_SYMBOLS: añadir la cesta de las figuras con dificultad 3 o más.
@export var with_shapes: bool = false

const SH := ShapeGeometry.Shape
## Letras que no se mezclan con números (la I se confunde con el 1).
const SYMBOL_LETTERS: PackedStringArray = ["A", "E", "O", "U"]


func generate(rng: RandomNumberGenerator, difficulty: int, bank: ContentBank) -> ActivityInstance:
	var combo := bank as CombinationBank
	var instance := ActivityInstance.new()
	var correct_cards: Array[CardData] = []
	var vowel: String = pick(Array(combo.vowels()), rng)
	var others: Array = _other_vowels(combo, vowel)
	instance.fill_values = _vowel_fill(combo, vowel)
	instance.model_card = CardData.letter(vowel, 0, 150)
	match mode:
		Mode.VOWEL_PICK:
			_letter_choice(instance, correct_cards, vowel, others, by_difficulty([2, 3, 4, 4, 5], difficulty), difficulty, bank, rng)
		Mode.VOWEL_SOUND:
			instance.model_card = null  # sería la respuesta
			var sound_card := CardData.letter(combo.bank_of(vowel).sound, 0, 56, bank.colors[bank.colors.size() - 2])
			sound_card.kind = CardData.Kind.WORD
			instance.prompt_card = sound_card
			_letter_choice(instance, correct_cards, vowel, others, by_difficulty([2, 3, 3, 4, 5], difficulty), difficulty, bank, rng)
		Mode.VOWEL_CASE:
			var reverse: bool = difficulty >= 3 and rng.randf() < 0.4
			instance.model_card = null
			instance.prompt_card = CardData.letter(combo.lower_of(vowel) if reverse else vowel, 0, 110)
			instance.fill_values["shown"] = (combo.lower_of(vowel) + " pequeñita") if reverse else (vowel + " grande")
			instance.fill_values["pair"] = "grande" if reverse else "pequeñita"
			var answer := styled_letter(vowel if reverse else combo.lower_of(vowel), difficulty, bank, rng)
			correct_cards.append(answer)
			instance.cards.append(answer)
			for other: String in sample(others, by_difficulty([2, 3, 3, 4, 4], difficulty) - 1, rng):
				instance.cards.append(styled_letter(other if reverse else combo.lower_of(other), difficulty, bank, rng))
		Mode.VOWEL_GRID:
			var cells: int = by_difficulty([6, 8, 9, 12, 12], difficulty)
			var targets: int = by_difficulty([2, 2, 3, 3, 4], difficulty)
			var lower: bool = difficulty >= 4
			for i in cells:
				var is_target: bool = i < targets
				var value: String = vowel if is_target else pick(others, rng)
				if lower and i % 2 == 1:
					value = combo.lower_of(value)
				var card := styled_letter(value, difficulty, bank, rng, 72)
				instance.cards.append(card)
				if is_target:
					correct_cards.append(card)
		Mode.VOWEL_INITIAL:
			var entry: WordEntry = pick(combo.vowel_words(difficulty), rng)
			vowel = CombinationBank.initial_vowel(entry)
			instance.fill_values = _vowel_fill(combo, vowel)
			instance.fill_values["word"] = entry.word.to_lower()
			instance.fill_values["article"] = entry.article
			instance.fill_values["this_is"] = WordImageGenerator.DEMONSTRATIVES.get(entry.article, "Este es")
			instance.prompt_card = CardData.image(entry)
			instance.model_card = null
			_letter_choice(instance, correct_cards, vowel, _other_vowels(combo, vowel),
				by_difficulty([2, 3, 3, 4, 5], difficulty), mini(difficulty, 3), bank, rng)
		Mode.IMAGE_FOR_VOWEL:
			var answer := CardData.image(pick(combo.words_starting_with(vowel, difficulty), rng))
			correct_cards.append(answer)
			instance.cards.append(answer)
			for other: String in sample(others, by_difficulty([2, 3, 3, 4, 4], difficulty) - 1, rng):
				instance.cards.append(CardData.image(pick(combo.words_starting_with(other, difficulty), rng)))
		Mode.FIND_IMAGES:
			var matching: Array = shuffled(combo.words_starting_with(vowel, difficulty), rng)
			var targets: int = mini(by_difficulty([1, 2, 2, 3, 3], difficulty), matching.size())
			var cells: int = by_difficulty([6, 6, 8, 9, 9], difficulty)
			var pool: Array = []
			for other: String in others:
				pool.append_array(combo.words_starting_with(other, difficulty))
			pool = shuffled(pool, rng)
			for i in cells:
				var is_target: bool = i < targets
				var card := CardData.image(matching[i] if is_target else pool[(i - targets) % pool.size()])
				instance.cards.append(card)
				if is_target:
					correct_cards.append(card)
		Mode.WORD_VOWEL:
			var source: ContentBank = combo.bank_of(vowel)
			var words: PackedStringArray = source.spelling_words_easy.duplicate()
			if difficulty >= 3:
				words.append_array(source.spelling_words_hard)
			if difficulty >= 4:
				words = source.spelling_words_hard
			var word: String = pick(Array(words), rng)
			instance.fill_values["word"] = word
			for letter: String in word.split(""):
				var card := CardData.letter(letter, 0, 80)
				instance.cards.append(card)
				if ContentBank.normalize(letter) == vowel:
					instance.correct.append(instance.cards.size() - 1)
				else:
					instance.removable.append(instance.cards.size() - 1)
			instance.signature = "WORD|%s|%s" % [word, vowel]
			return instance
		Mode.SORT_VOWELS:
			var bins: Array = [vowel]
			bins.append_array(sample(others, 2 if difficulty >= 3 else 1, rng))
			for v: String in bins:
				instance.bins.append(CardData.letter(v, 0, 90))
			instance.fill_values["letters"] = " y ".join(PackedStringArray(bins))
			for i in maxi(by_difficulty([3, 4, 4, 5, 6], difficulty), bins.size()):
				var category: int = i % bins.size()
				var card := CardData.image(pick(combo.words_starting_with(bins[category], difficulty), rng))
				card.category = category
				instance.cards.append(card)
				correct_cards.append(card)
		Mode.COUNT_SHAPES:
			var target: int = rng.randi_range(0, 4)
			var amount: int = rng.randi_range(1, mini(combo.max_count, by_difficulty([3, 4, 5, 6, 8], difficulty)))
			instance.fill_values = ShapeBank.fill_for(target)
			instance.model_card = null
			var items: Array[CardData] = _mixed_shapes(target, amount, difficulty, bank, rng)
			var arrangement: CardData.Layout = CardData.Layout.GRID if difficulty <= 3 else CardData.Layout.SCATTER
			instance.prompt_card = CardData.collection(items, arrangement, rng.randi())
			instance.prompt_card.wide = true
			_number_choice(instance, correct_cards, amount, by_difficulty([2, 3, 3, 4, 4], difficulty), difficulty, bank, rng)
		Mode.COMPARE_SHAPES:
			var target: int = rng.randi_range(0, 4)
			var less: bool = difficulty >= 4 and rng.randf() < 0.5
			instance.fill_values = ShapeBank.fill_for(target)
			instance.fill_values["more_less"] = "menos" if less else "más"
			instance.model_card = null
			var high: int = mini(combo.max_count, 6)
			var a: int = rng.randi_range(1, high)
			var gap: int = 1 if difficulty >= 4 else 2
			var options_b: Array[int] = []
			for value in range(1, high + 1):
				if absi(value - a) >= gap:
					options_b.append(value)
			var b: int = pick(options_b, rng)
			var best: int = mini(a, b) if less else maxi(a, b)
			for amount: int in [a, b]:
				# Con dificultad alta, el conjunto con más figuras pedidas no es el más grande.
				var extra: int = by_difficulty([0, 1, 2, 2, 3], difficulty)
				if difficulty >= 3:
					extra = maxi(0, 7 - amount)
				# Siempre en filas: en tarjetas medianas, desordenadas serían demasiado pequeñas.
				var card := CardData.collection(_mixed_shapes(target, amount, difficulty, bank, rng, extra),
					CardData.Layout.GRID, rng.randi())
				instance.cards.append(card)
				if amount == best:
					correct_cards.append(card)
		Mode.TAP_N_SHAPES:
			var target: int = rng.randi_range(0, 4)
			var cells: int = by_difficulty([6, 8, 9, 12, 12], difficulty)
			var present: int = mini(by_difficulty([3, 4, 4, 5, 6], difficulty), cells - 2)
			var amount: int = rng.randi_range(1, present - 1)
			instance.fill_values = ShapeBank.fill_for(target)
			instance.fill_values["number"] = str(amount)
			instance.fill_values["shape_n"] = ShapeBank.NAMES[target] if amount == 1 else ShapeBank.PLURALS[target]
			instance.model_card = ShapeGenerator._model(target, bank)
			var pool: Array = _other_shapes(target, difficulty)
			for i in cells:
				var is_target: bool = i < present
				var card: CardData = ShapeGeometry.random_card(target if is_target else pick(pool, rng), difficulty, rng, bank.colors)
				instance.cards.append(card)
				if is_target:
					correct_cards.append(card)
			instance.required = amount
			instance.count_feedback = true
			shuffle_cards(instance, correct_cards, rng)
			instance.signature = "TAP_N_SHAPES|%d|%d|%s" % [target, amount, signature_of("", instance.cards)]
			return instance
		Mode.SCENE_COUNT:
			var target: int = rng.randi_range(0, 4)
			var options: Array[int] = []
			for index: int in ShapeScenes.scenes_with(target):
				if _count_in_scene(index, target) >= 2:
					options.append(index)
			if options.is_empty():
				options = ShapeScenes.scenes_with(target)
			var index: int = pick(options, rng)
			instance.fill_values = ShapeBank.fill_for(target)
			instance.fill_values["scene"] = ShapeScenes.SCENES[index]["name"]
			instance.model_card = ShapeGenerator._model(target, bank)
			for card: CardData in ShapeScenes.build(index):
				instance.cards.append(card)
			for i in instance.cards.size():
				if instance.cards[i].shape == target:
					instance.correct.append(i)
				else:
					instance.removable.append(i)
			instance.count_feedback = true
			instance.signature = "SCENE_COUNT|%s|%d" % [ShapeScenes.SCENES[index]["id"], target]
			return instance
		Mode.CORNERS_SHAPE:
			_corners_question(instance, correct_cards, difficulty, bank, rng)
		Mode.SORT_ROUND:
			instance.model_card = null
			var round_bin := CardData.collection(_shape_examples([SH.CIRCLE, SH.OVAL], bank), CardData.Layout.GRID, 0, "redondas")
			var corner_bin := CardData.collection(_shape_examples([SH.TRIANGLE, SH.SQUARE], bank), CardData.Layout.GRID, 0, "con esquinas")
			instance.bins.append(round_bin)
			instance.bins.append(corner_bin)
			for i in by_difficulty([3, 4, 4, 5, 6], difficulty):
				var rounded: bool = i % 2 == 0
				var shape: int = pick([SH.CIRCLE, SH.OVAL] if rounded else [SH.SQUARE, SH.TRIANGLE, SH.RECTANGLE], rng)
				var card: CardData = ShapeGeometry.random_card(shape, difficulty, rng, bank.colors)
				card.category = 0 if rounded else 1
				instance.cards.append(card)
				correct_cards.append(card)
		Mode.VOWEL_COUNT:
			var candidates: Array = []
			for v: String in combo.vowels():
				if combo.words_starting_with(v, difficulty).size() >= 2:
					candidates.append(v)
			vowel = pick(candidates, rng)
			others = _other_vowels(combo, vowel)
			instance.fill_values = _vowel_fill(combo, vowel)
			instance.model_card = null
			var matching: Array = shuffled(combo.words_starting_with(vowel, difficulty), rng)
			var amount: int = rng.randi_range(1, mini(matching.size(), by_difficulty([2, 3, 3, 4, 4], difficulty)))
			var pool: Array = []
			for other: String in others:
				pool.append_array(combo.words_starting_with(other, difficulty))
			pool = shuffled(pool, rng)
			var items: Array[CardData] = []
			for i in amount:
				items.append(CardData.image(matching[i]))
			for i in mini(by_difficulty([2, 3, 4, 4, 5], difficulty), pool.size()):
				items.append(CardData.image(pool[i]))
			items.assign(shuffled(items, rng))
			instance.prompt_card = CardData.collection(items, CardData.Layout.GRID, rng.randi())
			instance.prompt_card.wide = true
			_number_choice(instance, correct_cards, amount, by_difficulty([2, 3, 3, 4, 4], difficulty), difficulty, bank, rng)
		Mode.TAP_N_VOWEL:
			var cells: int = by_difficulty([6, 8, 9, 12, 12], difficulty)
			var present: int = mini(by_difficulty([3, 4, 4, 5, 6], difficulty), cells - 2)
			var amount: int = rng.randi_range(2 if present > 2 else 1, present - 1)
			instance.fill_values["number"] = str(amount)
			instance.fill_values["letters_n"] = "letra" if amount == 1 else "letras"
			for i in cells:
				var is_target: bool = i < present
				var card := styled_letter(vowel if is_target else pick(others, rng), difficulty, bank, rng, 72)
				instance.cards.append(card)
				if is_target:
					correct_cards.append(card)
			instance.required = amount
			instance.count_feedback = true
			shuffle_cards(instance, correct_cards, rng)
			instance.signature = "TAP_N_VOWEL|%s|%d|%s" % [vowel, amount, signature_of("", instance.cards)]
			return instance
		Mode.SORT_SYMBOLS:
			instance.model_card = null
			var letter_examples: Array[CardData] = []
			for v: String in ["A", "E", "O"]:
				letter_examples.append(CardData.letter(v, 0, 60))
			var number_examples: Array[CardData] = []
			for n in [1, 2, 3]:
				number_examples.append(CardData.number(n, 0, 60))
			instance.bins.append(CardData.collection(letter_examples, CardData.Layout.GRID, 0, "letras"))
			instance.bins.append(CardData.collection(number_examples, CardData.Layout.GRID, 0, "números"))
			var kinds: int = 2
			if with_shapes and difficulty >= 3:
				instance.bins.append(CardData.collection(_shape_examples([SH.CIRCLE, SH.TRIANGLE, SH.SQUARE], bank),
					CardData.Layout.GRID, 0, "figuras"))
				kinds = 3
			instance.fill_values["kinds"] = "letras, números y figuras" if kinds == 3 else "letras y números"
			for i in maxi(by_difficulty([4, 4, 5, 6, 6], difficulty), kinds):
				var category: int = i % kinds
				var card: CardData
				match category:
					0:
						card = CardData.letter(pick(Array(SYMBOL_LETTERS), rng), 0, 100, bank.colors[rng.randi_range(0, bank.colors.size() - 1)])
					1:
						card = CardData.number(rng.randi_range(2, 9), 0, 100, bank.colors[rng.randi_range(0, bank.colors.size() - 1)])
					_:
						card = ShapeGeometry.random_card(rng.randi_range(0, 4), mini(difficulty, 2), rng, bank.colors)
				card.category = category
				instance.cards.append(card)
				correct_cards.append(card)
	shuffle_cards(instance, correct_cards, rng)
	instance.signature = signature_of(Mode.keys()[mode], instance.cards)
	if instance.prompt_card != null:
		instance.signature += "|" + instance.prompt_card.token()
	return instance


# --- Utilidades ------------------------------------------------------------------

static func _other_vowels(combo: CombinationBank, vowel: String) -> Array:
	var result: Array = []
	for v: String in combo.vowels():
		if v != vowel:
			result.append(v)
	return result


static func _vowel_fill(combo: CombinationBank, vowel: String) -> Dictionary:
	var source: ContentBank = combo.bank_of(vowel)
	return {
		"letter": vowel,
		"letter_lower": combo.lower_of(vowel),
		"sound": source.sound if source != null else vowel.to_lower(),
	}


## CHOICE de letras: la correcta y "count - 1" de "others".
static func _letter_choice(instance: ActivityInstance, correct_cards: Array[CardData], answer_text: String,
		others: Array, count: int, difficulty: int, bank: ContentBank, rng: RandomNumberGenerator) -> void:
	var answer := styled_letter(answer_text, difficulty, bank, rng)
	correct_cards.append(answer)
	instance.cards.append(answer)
	for other: String in sample(others, count - 1, rng):
		instance.cards.append(styled_letter(other, difficulty, bank, rng))


## CHOICE de números: la cantidad correcta y vecinas (1-10, sin repetir).
static func _number_choice(instance: ActivityInstance, correct_cards: Array[CardData], amount: int, count: int,
		difficulty: int, bank: ContentBank, rng: RandomNumberGenerator) -> void:
	var answer := styled_number(amount, mini(difficulty, 3), bank, rng)
	correct_cards.append(answer)
	instance.cards.append(answer)
	var near: Array[int] = []
	for delta: int in shuffled([1, -1, 2, -2, 3], rng):
		var value: int = amount + delta
		if value >= 1 and value <= 10 and not near.has(value):
			near.append(value)
	if difficulty <= 2:
		near.reverse()  # más fácil: las más lejanas primero
	for value: int in near.slice(0, count - 1):
		instance.cards.append(styled_number(value, mini(difficulty, 3), bank, rng))


## Figuras distintas de "target" para mezclar (con dificultad alta, también la parecida).
static func _other_shapes(target: int, difficulty: int) -> Array:
	var result: Array = []
	for shape in 5:
		if shape != target and (difficulty >= 4 or shape != ShapeBank.SIMILAR[target]):
			result.append(shape)
	return result


## "amount" figuras "target" mezcladas con otras figuras ("extra" < 0 = según la dificultad).
static func _mixed_shapes(target: int, amount: int, difficulty: int, bank: ContentBank, rng: RandomNumberGenerator,
		extra: int = -1) -> Array[CardData]:
	var items: Array[CardData] = []
	for i in amount:
		items.append(ShapeGeometry.random_card(target, mini(difficulty, 4), rng, bank.colors))
	if extra < 0:
		extra = by_difficulty([2, 3, 4, 5, 5], difficulty)
	extra = mini(extra, 12 - amount)
	var pool: Array = _other_shapes(target, difficulty)
	for i in extra:
		items.append(ShapeGeometry.random_card(pick(pool, rng), mini(difficulty, 4), rng, bank.colors))
	for item: CardData in items:
		item.shape_scale = maxf(item.shape_scale, 0.8)  # en un conjunto, cada figura ya ocupa una celda pequeña
	items.assign(shuffled(items, rng))
	return items


## Figuras de ejemplo (rectas, tamaño completo) para el título de una cesta.
static func _shape_examples(shapes: Array, bank: ContentBank) -> Array[CardData]:
	var result: Array[CardData] = []
	for shape: int in shapes:
		result.append(ShapeGenerator._model(shape, bank))
	return result


static func _count_in_scene(index: int, shape: int) -> int:
	var total: int = 0
	for part: Array in ShapeScenes.SCENES[index]["parts"]:
		if part[0] == shape:
			total += 1
	return total


## "¿Qué figura tiene 3 / 4 esquinas?" o "¿cuál no tiene esquinas?". Solo una
## opción es válida: nunca aparecen juntos cuadrado y rectángulo, ni círculo y óvalo.
static func _corners_question(instance: ActivityInstance, correct_cards: Array[CardData], difficulty: int,
		bank: ContentBank, rng: RandomNumberGenerator) -> void:
	var families: Array = [[SH.CIRCLE, SH.OVAL], [SH.TRIANGLE], [SH.SQUARE, SH.RECTANGLE]]
	var asked: int = rng.randi_range(0, 2)
	var answer_shape: int = pick(families[asked], rng)
	var corners: int = ShapeGeometry.corners(answer_shape)
	instance.fill_values = ShapeBank.fill_for(answer_shape)
	instance.fill_values["question"] = "¿Qué figura no tiene esquinas?" if corners == 0 else \
		"¿Qué figura tiene %d esquinas?" % corners
	instance.fill_values["number"] = str(corners)
	instance.model_card = null
	var answer: CardData = ShapeGeometry.random_card(answer_shape, mini(difficulty, 3), rng, bank.colors)
	correct_cards.append(answer)
	instance.cards.append(answer)
	var count: int = by_difficulty([2, 3, 3, 3, 3], difficulty)
	for family: int in shuffled([0, 1, 2], rng):
		if family == asked or instance.cards.size() >= count:
			continue
		instance.cards.append(ShapeGeometry.random_card(pick(families[family], rng), mini(difficulty, 3), rng, bank.colors))
