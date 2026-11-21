@tool
class_name LetterChoiceGenerator
extends ActivityGenerator
## Elegir UNA tarjeta de letra (vista CHOICE).
## - PICK_TARGET: "Toca la A" entre otras letras.
## - ODD_ONE_OUT: varias A en distintas tipografías y un intruso: "¿Cuál NO es A?".
## - DISGUISED: la A "disfrazada" (tipografía, tamaño y color distintos); en
##   dificultad alta puede ser la minúscula "a".
## - MATCH_CASE: se muestra la mayúscula y se elige su minúscula (en dificultad
##   alta, a veces al revés): "grande y pequeñita".
## - SOUND: se muestra el sonido («eee») y se elige la vocal que suena así,
##   entre otras vocales.
## (Los modos nuevos van al final: los .tres guardan el modo como número.)

enum Mode { PICK_TARGET, ODD_ONE_OUT, DISGUISED, MATCH_CASE, SOUND }

## Dificultad a partir de la cual MATCH_CASE puede ir de minúscula a mayúscula.
const REVERSE_CASE_FROM: int = 3

@export var mode: Mode = Mode.PICK_TARGET
## Dificultad a partir de la cual DISGUISED puede usar la minúscula.
@export_range(1, 5) var lowercase_from: int = 4


func generate(rng: RandomNumberGenerator, difficulty: int, bank: ContentBank) -> ActivityInstance:
	var instance := ActivityInstance.new()
	var correct_cards: Array[CardData] = []
	instance.model_card = CardData.letter(bank.target, 0, 150)
	instance.fill_values = {"letter_name": "la " + bank.target}
	match mode:
		Mode.PICK_TARGET:
			var count: int = by_difficulty([3, 3, 4, 5, 5], difficulty)
			var target := styled_letter(bank.target, difficulty, bank, rng)
			correct_cards.append(target)
			instance.cards.append(target)
			for letter: String in sample(Array(bank.distractors_for(difficulty)), count - 1, rng):
				instance.cards.append(styled_letter(letter, difficulty, bank, rng))
		Mode.ODD_ONE_OUT:
			var copies: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
			var fonts: Array = shuffled(range(bank.font_count()), rng)
			for i in copies:
				var tint: Color = bank.colors[rng.randi_range(0, bank.colors.size() - 1)]
				instance.cards.append(CardData.letter(bank.target, fonts[i % fonts.size()], 110, tint))
			var pool: PackedStringArray = bank.easy_letters if difficulty <= 2 else (
				bank.medium_letters if difficulty == 3 else bank.similar_letters)
			var intruder := styled_letter(pick(Array(pool), rng), difficulty, bank, rng)
			correct_cards.append(intruder)
			instance.cards.append(intruder)
		Mode.DISGUISED:
			var count: int = by_difficulty([3, 3, 4, 4, 5], difficulty)
			var lower: bool = difficulty >= lowercase_from and rng.randf() < 0.5
			var target_text: String = bank.target_lower if lower else bank.target
			var pool: Array = Array(bank.lower_distractors) if lower else Array(bank.distractors_for(difficulty))
			if lower:
				instance.fill_values["letter_name"] = "la " + bank.target_lower + " pequeñita"
				instance.model_card = CardData.letter(bank.target_lower, 0, 150)
			var target := CardData.letter(target_text, rng.randi_range(1, bank.font_count() - 1),
				rng.randi_range(90, 130), bank.colors[rng.randi_range(0, bank.colors.size() - 1)])
			correct_cards.append(target)
			instance.cards.append(target)
			for letter: String in sample(pool, count - 1, rng):
				instance.cards.append(CardData.letter(letter, rng.randi_range(0, bank.font_count() - 1),
					rng.randi_range(90, 130), bank.colors[rng.randi_range(0, bank.colors.size() - 1)]))
		Mode.MATCH_CASE:
			var count: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
			var reverse: bool = difficulty >= REVERSE_CASE_FROM and rng.randf() < 0.4
			# La letra modelo sería la respuesta: la pista visual solo retira opciones.
			instance.model_card = null
			instance.prompt_card = CardData.letter(bank.target_lower if reverse else bank.target, 0, 110)
			instance.fill_values["shown"] = (bank.target_lower + " pequeñita") if reverse else (bank.target + " grande")
			instance.fill_values["pair"] = "grande" if reverse else "pequeñita"
			var answer := styled_letter(bank.target if reverse else bank.target_lower, difficulty, bank, rng)
			correct_cards.append(answer)
			instance.cards.append(answer)
			var pool: Array = Array(bank.distractors_for(difficulty)) if reverse else Array(bank.lower_distractors)
			for letter: String in sample(pool, count - 1, rng):
				instance.cards.append(styled_letter(letter, difficulty, bank, rng))
		Mode.SOUND:
			var count: int = by_difficulty([2, 3, 3, 4, 5], difficulty)
			instance.model_card = null
			# Tamaño contenido para que el sonido quepa en la tarjeta de enunciado.
			var sound_card := CardData.letter(bank.sound, 0, 56, bank.colors[bank.colors.size() - 2])
			sound_card.kind = CardData.Kind.WORD
			sound_card.spoken = bank.sound
			instance.prompt_card = sound_card
			instance.fill_values["sound"] = bank.sound
			var answer := styled_letter(bank.target, difficulty, bank, rng)
			correct_cards.append(answer)
			instance.cards.append(answer)
			for letter: String in sample(Array(bank.vowel_peers()), count - 1, rng):
				instance.cards.append(styled_letter(letter, difficulty, bank, rng))
	shuffle_cards(instance, correct_cards, rng)
	instance.signature = signature_of(Mode.keys()[mode], instance.cards)
	if instance.prompt_card != null:
		instance.signature += "|" + instance.prompt_card.text
	return instance
