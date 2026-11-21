@tool
class_name LetterChoiceGenerator
extends ActivityGenerator
## Elegir UNA tarjeta de letra (vista CHOICE).
## - PICK_TARGET: "Toca la A" entre otras letras.
## - ODD_ONE_OUT: varias A en distintas tipografías y un intruso: "¿Cuál NO es A?".
## - DISGUISED: la A "disfrazada" (tipografía, tamaño y color distintos); en
##   dificultad alta puede ser la minúscula "a".

enum Mode { PICK_TARGET, ODD_ONE_OUT, DISGUISED }

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
	shuffle_cards(instance, correct_cards, rng)
	instance.signature = signature_of(Mode.keys()[mode], instance.cards)
	return instance
