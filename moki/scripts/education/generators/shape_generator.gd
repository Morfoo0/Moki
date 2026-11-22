@tool
class_name ShapeGenerator
extends ActivityGenerator
## Actividades con figuras geométricas dibujadas (necesita un ShapeBank).
## - PICK: "toca el círculo" entre otras figuras (CHOICE).
## - MATCH: "¿dónde hay otra figura igual?" (otro color y tamaño; CHOICE).
## - GRID: "busca todos los círculos" (SEARCH; tamaños, colores y giros).
## - ODD_ONE_OUT: varias iguales y una distinta (con dificultad alta, la parecida).
## - TWINS: solo la figura y su parecida (cuadrado/rectángulo, círculo/óvalo).
## - CORNERS: "¿cuántas esquinas (o lados) tiene?" (CHOICE con números).
## - SCENE: encontrar la figura dentro de un dibujo compuesto (vista SCENE).
## El color, el tamaño y el giro nunca cambian la respuesta.

enum Mode { PICK, MATCH, GRID, ODD_ONE_OUT, TWINS, CORNERS, SCENE }

@export var mode: Mode = Mode.PICK


func generate(rng: RandomNumberGenerator, difficulty: int, bank: ContentBank) -> ActivityInstance:
	var shapes := bank as ShapeBank
	var instance := ActivityInstance.new()
	var correct_cards: Array[CardData] = []
	var target: int = shapes.pick_target(rng, difficulty)
	if mode == Mode.CORNERS and not ShapeGeometry.has_corners(target):
		target = _polygon_target(shapes, rng)
	instance.fill_values = ShapeBank.fill_for(target)
	instance.model_card = _model(target, bank)
	match mode:
		Mode.PICK, Mode.MATCH:
			var count: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
			var answer: CardData = _card(target, difficulty, bank, rng)
			if mode == Mode.MATCH:
				var prompt: CardData = _card(target, difficulty, bank, rng)
				# La gemela tiene otro color: hay que fijarse en la forma.
				while bank.colors.size() > 1 and answer.color == prompt.color:
					answer.color = bank.colors[rng.randi_range(0, bank.colors.size() - 1)]
				instance.prompt_card = prompt
				instance.model_card = null  # el modelo ya está a la vista
			correct_cards.append(answer)
			instance.cards.append(answer)
			for shape: int in shapes.distractor_shapes(target, difficulty, rng).slice(0, count - 1):
				instance.cards.append(_card(shape, difficulty, bank, rng))
		Mode.GRID:
			var cells: int = by_difficulty([6, 8, 9, 12, 12], difficulty)
			var targets: int = by_difficulty([2, 2, 3, 3, 4], difficulty)
			var pool: Array = shapes.distractor_shapes(target, difficulty, rng).slice(0, by_difficulty([2, 2, 3, 3, 4], difficulty))
			for i in cells:
				var is_target: bool = i < targets
				var card: CardData = _card(target if is_target else pick(pool, rng), difficulty, bank, rng)
				instance.cards.append(card)
				if is_target:
					correct_cards.append(card)
		Mode.ODD_ONE_OUT:
			var copies: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
			for i in copies:
				instance.cards.append(_card(target, maxi(difficulty, 2), bank, rng))
			var intruder_shape: int = ShapeBank.SIMILAR[target] if difficulty >= 3 else \
				shapes.distractor_shapes(target, 1, rng)[0]
			var intruder: CardData = _card(intruder_shape, difficulty, bank, rng)
			correct_cards.append(intruder)
			instance.cards.append(intruder)
		Mode.TWINS:
			# Mismo color y tamaño: solo cambia la forma.
			var twin: int = ShapeBank.SIMILAR[target]
			var tint: Color = bank.colors[rng.randi_range(0, bank.colors.size() - 1)]
			var answer: CardData = _card(target, mini(difficulty, 2), bank, rng)
			var other: CardData = _card(twin, mini(difficulty, 2), bank, rng)
			for card: CardData in [answer, other]:
				card.color = tint
				card.shape_scale = 0.9
			instance.fill_values["twin"] = ShapeBank.NAMES[twin]
			correct_cards.append(answer)
			instance.cards.append(answer)
			instance.cards.append(other)
			if difficulty >= 4:
				var third: int = shapes.distractor_shapes(target, 1, rng)[0]
				if third != twin:
					instance.cards.append(_card(third, 2, bank, rng))
		Mode.CORNERS:
			var ask_sides: bool = difficulty >= 3 and rng.randf() < 0.5
			instance.fill_values["part"] = "lados" if ask_sides else "esquinas"
			instance.fill_values["part_one"] = "lado" if ask_sides else "esquina"
			var prompt: CardData = _card(target, difficulty, bank, rng)
			prompt.shape_scale = 1.0
			instance.prompt_card = prompt
			instance.model_card = null  # la figura ya está a la vista
			var value: int = ShapeGeometry.corners(target)  # mismos lados que esquinas
			var count: int = by_difficulty([2, 3, 3, 4, 4], difficulty)
			var answer := CardData.number(value)
			correct_cards.append(answer)
			instance.cards.append(answer)
			for other: int in [3, 4, 5, 2]:
				if other != value and instance.cards.size() < count:
					instance.cards.append(CardData.number(other))
		Mode.SCENE:
			var options: Array[int] = ShapeScenes.scenes_with(target)
			if difficulty <= 2:
				options = options.slice(0, maxi(2, ceili(options.size() / 2.0)))  # los más sencillos
			var index: int = pick(options, rng)
			instance.fill_values["scene"] = ShapeScenes.SCENES[index]["name"]
			for card: CardData in ShapeScenes.build(index):
				instance.cards.append(card)
			for i in instance.cards.size():
				if instance.cards[i].shape == target:
					instance.correct.append(i)
				else:
					instance.removable.append(i)
			instance.signature = "SCENE|%s|%d" % [ShapeScenes.SCENES[index]["id"], target]
			return instance
	shuffle_cards(instance, correct_cards, rng)
	instance.signature = signature_of(Mode.keys()[mode], instance.cards)
	if instance.prompt_card != null:
		instance.signature += "|" + instance.prompt_card.token()
	return instance


static func _card(shape: int, difficulty: int, bank: ContentBank, rng: RandomNumberGenerator) -> CardData:
	return ShapeGeometry.random_card(shape, difficulty, rng, bank.colors)


## Figura modelo de la pista visual: recta y de tamaño completo.
static func _model(shape: int, bank: ContentBank) -> CardData:
	var aspect: float = 1.8 if shape == ShapeGeometry.Shape.RECTANGLE else (1.55 if shape == ShapeGeometry.Shape.OVAL else 1.0)
	return CardData.shape_card(shape, bank.colors[2], 0, aspect, 0.0, 0.9)


## Una figura con esquinas conocida en la lección (para contar esquinas).
static func _polygon_target(shapes: ShapeBank, rng: RandomNumberGenerator) -> int:
	var options: Array[int] = []
	for shape: int in shapes.known():
		if ShapeGeometry.has_corners(shape):
			options.append(shape)
	return options[rng.randi_range(0, options.size() - 1)] if not options.is_empty() else ShapeGeometry.Shape.SQUARE
