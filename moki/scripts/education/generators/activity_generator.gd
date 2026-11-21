@tool
class_name ActivityGenerator
extends Resource
## Base de los generadores de actividades. Cada subclase crea instancias
## concretas (ActivityInstance) a partir de un ContentBank y una dificultad 1-5.
## Usa siempre el RNG recibido (nunca el global) para que la lección sea
## reproducible y controlable.


## Debe devolver una instancia con cards, correct, removable y signature.
func generate(_rng: RandomNumberGenerator, _difficulty: int, _bank: ContentBank) -> ActivityInstance:
	push_error("ActivityGenerator.generate() no implementado en %s" % resource_path)
	return ActivityInstance.new()


# --- Utilidades ---------------------------------------------------------------

static func shuffled(items: Array, rng: RandomNumberGenerator) -> Array:
	var result: Array = items.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result


static func sample(items: Array, count: int, rng: RandomNumberGenerator) -> Array:
	return shuffled(items, rng).slice(0, mini(count, items.size()))


static func pick(items: Array, rng: RandomNumberGenerator) -> Variant:
	return items[rng.randi_range(0, items.size() - 1)] if not items.is_empty() else null


## Por cuántas casillas por dificultad (índice = dificultad - 1).
static func by_difficulty(values: Array, difficulty: int) -> Variant:
	return values[clampi(difficulty - 1, 0, values.size() - 1)]


## Estilo de una letra según la dificultad: con más dificultad, más
## variedad de colores (>=3), tipografías (>=4) y tamaños.
static func styled_letter(value: String, difficulty: int, bank: ContentBank, rng: RandomNumberGenerator,
		base_size: int = 110) -> CardData:
	var font: int = 0
	var tint: Color = bank.colors[0]
	var size: int = base_size
	if difficulty >= 3:
		tint = bank.colors[rng.randi_range(0, bank.colors.size() - 1)]
		size = int(base_size * rng.randf_range(0.8, 1.1))
	if difficulty >= 4:
		font = rng.randi_range(0, bank.font_count() - 1)
	return CardData.letter(value, font, size, tint)


## Numeral con el mismo estilo por dificultad que styled_letter().
static func styled_number(value: int, difficulty: int, bank: ContentBank, rng: RandomNumberGenerator,
		base_size: int = 110) -> CardData:
	var card := styled_letter(str(value), difficulty, bank, rng, base_size)
	card.kind = CardData.Kind.NUMBER
	return card


## Disposición de un grupo según la dificultad: ordenada al principio; luego
## también como un dado (si caben) y desordenada.
static func group_layout(amount: int, difficulty: int, rng: RandomNumberGenerator) -> CardData.Layout:
	var options: Array = [CardData.Layout.GRID]
	if difficulty >= 3 and amount <= 6:
		options.append(CardData.Layout.DICE)
	if difficulty >= 4:
		options.append(CardData.Layout.SCATTER)
	return pick(options, rng)


## Mezcla las tarjetas y recalcula los índices correctos.
static func shuffle_cards(instance: ActivityInstance, correct_cards: Array[CardData], rng: RandomNumberGenerator) -> void:
	var mixed: Array = shuffled(instance.cards, rng)
	instance.cards.clear()
	instance.correct.clear()
	instance.removable.clear()
	for card: CardData in mixed:
		instance.cards.append(card)
	for i in instance.cards.size():
		if correct_cards.has(instance.cards[i]):
			instance.correct.append(i)
		else:
			instance.removable.append(i)


static func signature_of(prefix: String, cards: Array[CardData]) -> String:
	var tokens: PackedStringArray = []
	for card: CardData in cards:
		tokens.append(card.token())
	tokens.sort()
	return prefix + "|" + ",".join(tokens)
