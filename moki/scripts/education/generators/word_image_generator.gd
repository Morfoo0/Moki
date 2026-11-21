@tool
class_name WordImageGenerator
extends ActivityGenerator
## Asociar la letra con palabras e imágenes reales del juego.
## - PICK_IMAGE: "¿Qué dibujo empieza con A?" (CHOICE con imágenes).
## - PICK_INITIAL: "Este es un ábaco. ¿Con qué letra empieza?" (CHOICE con letras).
## - SORT: clasificar dibujos en "empieza con A" / "no empieza con A" (SORT).

enum Mode { PICK_IMAGE, PICK_INITIAL, SORT }

@export var mode: Mode = Mode.PICK_IMAGE

## Concordancia del demostrativo con el artículo ("Esta es una alfombra").
const DEMONSTRATIVES: Dictionary = {"un": "Este es", "una": "Esta es", "unos": "Estos son", "unas": "Estas son"}


func generate(rng: RandomNumberGenerator, difficulty: int, bank: ContentBank) -> ActivityInstance:
	var instance := ActivityInstance.new()
	var correct_cards: Array[CardData] = []
	instance.model_card = CardData.letter(bank.target, 0, 150)
	var with_target: Array = bank.words_for(true, difficulty)
	var without_target: Array = bank.words_for(false, difficulty)
	match mode:
		Mode.PICK_IMAGE:
			var count: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
			var answer := CardData.image(pick(with_target, rng))
			correct_cards.append(answer)
			instance.cards.append(answer)
			for entry: WordEntry in sample(without_target, count - 1, rng):
				instance.cards.append(CardData.image(entry))
		Mode.PICK_INITIAL:
			var count: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
			var entry: WordEntry = pick(with_target, rng)
			instance.prompt_card = CardData.image(entry)
			# Aquí la letra modelo SERÍA la respuesta: la pista visual solo retira opciones.
			instance.model_card = null
			instance.fill_values = {"word": entry.word.to_lower(), "article": entry.article,
				"this_is": DEMONSTRATIVES.get(entry.article, "Este es")}
			var answer := CardData.letter(bank.target, 0, 110)
			correct_cards.append(answer)
			instance.cards.append(answer)
			for letter: String in sample(Array(bank.distractors_for(difficulty)), count - 1, rng):
				instance.cards.append(CardData.letter(letter, 0, 110))
		Mode.SORT:
			var count: int = by_difficulty([3, 4, 4, 5, 6], difficulty)
			var with_count: int = maxi(1, count / 2)
			instance.bins.append(CardData.letter(bank.target, 0, 90))
			var other_bin := CardData.letter("?", 0, 90)
			other_bin.spoken = "otras letras"
			instance.bins.append(other_bin)
			for entry: WordEntry in sample(with_target, with_count, rng):
				var card := CardData.image(entry)
				card.category = 0
				instance.cards.append(card)
				correct_cards.append(card)
			for entry: WordEntry in sample(without_target, count - with_count, rng):
				var card := CardData.image(entry)
				card.category = 1
				instance.cards.append(card)
				correct_cards.append(card)
	shuffle_cards(instance, correct_cards, rng)
	if mode == Mode.PICK_INITIAL:
		instance.signature = "PICK_INITIAL|" + instance.prompt_card.text + "|" + signature_of("", instance.cards)
	else:
		instance.signature = signature_of(Mode.keys()[mode], instance.cards)
	return instance
