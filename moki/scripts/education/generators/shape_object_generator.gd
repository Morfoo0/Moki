@tool
class_name ShapeObjectGenerator
extends ActivityGenerator
## Figuras y objetos cotidianos (necesita un ShapeBank).
## - PICK_OBJECT: "¿qué cosa tiene forma de círculo?" (CHOICE de objetos).
## - OBJECT_SHAPE: "mira la pelota: ¿qué forma tiene?" (CHOICE de figuras).
## - FIND_OBJECTS: "toca todas las cosas con forma de círculo" (SEARCH).
## - SORT_OBJECTS: cada cosa a la cesta de su forma (SORT).
## - SORT_SHAPES: cada figura a la cesta de su forma (SORT).
## Cestas: la figura y otra conocida (o "?" = otras formas en la primera
## lección); con dificultad alta y suficientes figuras conocidas, tres cestas.

enum Mode { PICK_OBJECT, OBJECT_SHAPE, FIND_OBJECTS, SORT_OBJECTS, SORT_SHAPES }

@export var mode: Mode = Mode.PICK_OBJECT

## Marca de la cesta "otras formas".
const OTHER: int = -1


func generate(rng: RandomNumberGenerator, difficulty: int, bank: ContentBank) -> ActivityInstance:
	var shapes := bank as ShapeBank
	var instance := ActivityInstance.new()
	var correct_cards: Array[CardData] = []
	var target: int = shapes.pick_target(rng, difficulty)
	var item: ShapeObject = pick(shapes.objects_of(target), rng)
	instance.fill_values = ShapeBank.fill_for(target, item)
	instance.model_card = ShapeGenerator._model(target, bank)
	match mode:
		Mode.PICK_OBJECT:
			var count: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
			var answer := CardData.image(item)
			correct_cards.append(answer)
			instance.cards.append(answer)
			# Un objeto de cada forma distinta, para que solo uno encaje.
			for shape: int in shapes.distractor_shapes(target, difficulty, rng).slice(0, count - 1):
				instance.cards.append(CardData.image(pick(shapes.objects_of(shape), rng)))
		Mode.OBJECT_SHAPE:
			var count: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
			instance.prompt_card = CardData.image(item)
			instance.model_card = null  # sería la respuesta
			var answer: CardData = ShapeGenerator._card(target, mini(difficulty, 2), bank, rng)
			correct_cards.append(answer)
			instance.cards.append(answer)
			for shape: int in shapes.distractor_shapes(target, difficulty, rng).slice(0, count - 1):
				instance.cards.append(ShapeGenerator._card(shape, mini(difficulty, 2), bank, rng))
		Mode.FIND_OBJECTS:
			var cells: int = by_difficulty([6, 6, 8, 9, 12], difficulty)
			var targets: int = by_difficulty([2, 2, 3, 3, 4], difficulty)
			var matching: Array = shuffled(shapes.objects_of(target), rng)
			var others: Array = shuffled(shapes.objects_not_of(target), rng)
			for i in cells:
				var is_target: bool = i < targets
				var source: Array = matching if is_target else others
				var card := CardData.image(source[(i if is_target else i - targets) % source.size()])
				instance.cards.append(card)
				if is_target:
					correct_cards.append(card)
		Mode.SORT_OBJECTS, Mode.SORT_SHAPES:
			var bins: Array[int] = _bins(shapes, target, difficulty, rng)
			for shape: int in bins:
				if shape == OTHER:
					var other_bin := CardData.letter("?", 0, 90)
					other_bin.spoken = "otras formas"
					instance.bins.append(other_bin)
				else:
					instance.bins.append(CardData.shape_card(shape, bank.colors[0], 0,
						ShapeGenerator._model(shape, bank).shape_aspect, 0.0, 0.9))
			var count: int = maxi(by_difficulty([3, 4, 4, 5, 6], difficulty), bins.size())
			for i in count:
				var category: int = i % bins.size()
				var shape: int = bins[category]
				var card: CardData
				if mode == Mode.SORT_OBJECTS:
					var pool: Array[ShapeObject] = shapes.objects_not_of(target) if shape == OTHER else shapes.objects_of(shape)
					card = CardData.image(pick(pool, rng))
				else:
					if shape == OTHER:
						shape = shapes.distractor_shapes(target, 1, rng)[0]
					card = ShapeGenerator._card(shape, difficulty, bank, rng)
				card.category = category
				instance.cards.append(card)
				correct_cards.append(card)
	shuffle_cards(instance, correct_cards, rng)
	instance.signature = signature_of(Mode.keys()[mode], instance.cards)
	if instance.prompt_card != null:
		instance.signature += "|" + instance.prompt_card.token()
	return instance


## Cestas de clasificar: la figura objetivo y otra conocida; tres con
## dificultad alta si se conocen suficientes; "?" si no se conoce ninguna más.
static func _bins(shapes: ShapeBank, target: int, difficulty: int, rng: RandomNumberGenerator) -> Array[int]:
	var others: Array[int] = []
	for shape: int in shuffled(shapes.known(), rng):
		if shape != target:
			others.append(shape)
	if others.is_empty():
		return [target, OTHER]
	var bins: Array[int] = [target, others[0]]
	if difficulty >= 3 and others.size() >= 2:
		bins.append(others[1])
	return bins
