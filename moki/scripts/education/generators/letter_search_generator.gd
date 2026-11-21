@tool
class_name LetterSearchGenerator
extends ActivityGenerator
## Encontrar TODAS las tarjetas objetivo (vista SEARCH).
## - GRID: "Busca todas las A" en una cuadrícula de letras mezcladas.
## - WORD: "Toca las A de la palabra" (letras de una palabra).
## - HIDDEN: "¿Dónde está la A?" escondida entre dibujos y otras letras.
## - MIXED_CASE: cuadrícula con mayúsculas y minúsculas; hay que tocar todas
##   las A y las a (refuerzo de las dos formas de la letra).
## (Los modos nuevos van al final: los .tres guardan el modo como número.)

enum Mode { GRID, WORD, HIDDEN, MIXED_CASE }

@export var mode: Mode = Mode.GRID


func generate(rng: RandomNumberGenerator, difficulty: int, bank: ContentBank) -> ActivityInstance:
	var instance := ActivityInstance.new()
	var correct_cards: Array[CardData] = []
	instance.model_card = CardData.letter(bank.target, 0, 150)
	match mode:
		Mode.GRID:
			var cells: int = by_difficulty([6, 8, 9, 12, 16], difficulty)
			var targets: int = by_difficulty([2, 2, 3, 3, 4], difficulty)
			var pool: Array = Array(bank.distractors_for(difficulty))
			for i in cells:
				var is_target: bool = i < targets
				var card := styled_letter(bank.target if is_target else pick(pool, rng), difficulty, bank, rng, 72)
				instance.cards.append(card)
				if is_target:
					correct_cards.append(card)
		Mode.WORD:
			var words: PackedStringArray = bank.spelling_words_easy.duplicate()
			if difficulty >= 3:
				words.append_array(bank.spelling_words_hard)
			if difficulty >= 4:
				words = bank.spelling_words_hard
			var word: String = pick(Array(words), rng)
			instance.fill_values = {"word": word}
			for letter: String in word.split(""):
				var card := CardData.letter(letter, 0, 80)
				instance.cards.append(card)
				if ContentBank.normalize(letter) == bank.target:
					correct_cards.append(card)
			# El orden de las letras de una palabra no se mezcla.
			for i in instance.cards.size():
				if correct_cards.has(instance.cards[i]):
					instance.correct.append(i)
				else:
					instance.removable.append(i)
			instance.signature = "WORD|" + word
			return instance
		Mode.HIDDEN:
			var cells: int = by_difficulty([6, 6, 8, 9, 12], difficulty)
			var targets: int = 1 if difficulty <= 3 else 2
			var images: Array = sample(bank.words_without_target, cells - targets, rng)
			for i in targets:
				var card := styled_letter(bank.target, difficulty, bank, rng, 80)
				instance.cards.append(card)
				correct_cards.append(card)
			var letters_left: int = 0 if difficulty <= 2 else (cells - targets) / 3
			for i in cells - targets:
				if i < letters_left:
					instance.cards.append(styled_letter(pick(Array(bank.distractors_for(difficulty)), rng), difficulty, bank, rng, 80))
				else:
					instance.cards.append(CardData.image(images[i % images.size()]))
		Mode.MIXED_CASE:
			var cells: int = by_difficulty([6, 8, 9, 12, 12], difficulty)
			var targets: int = by_difficulty([2, 3, 3, 4, 5], difficulty)
			var upper_pool: Array = Array(bank.distractors_for(difficulty))
			var lower_pool: Array = []
			for letter: String in bank.lower_distractors:
				if not bank.confusable_with_upper.has(letter):
					lower_pool.append(letter)
			for i in cells:
				var is_target: bool = i < targets
				var lower: bool = i % 2 == 1  # mitad mayúsculas, mitad minúsculas
				var value: String
				if is_target:
					value = bank.target_lower if lower else bank.target
				else:
					value = pick(lower_pool if lower and not lower_pool.is_empty() else upper_pool, rng)
				var card := styled_letter(value, difficulty, bank, rng, 72)
				instance.cards.append(card)
				if is_target:
					correct_cards.append(card)
	shuffle_cards(instance, correct_cards, rng)
	instance.signature = signature_of(Mode.keys()[mode], instance.cards)
	return instance
