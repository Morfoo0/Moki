class_name CardData
extends RefCounted
## Contenido concreto de una tarjeta de actividad (letra, imagen, palabra,
## numeral o grupo de objetos para contar).

## NUMBER: un numeral ("7", "10"). GROUP: "count" objetos iguales (texture o glyph).
## SHAPE: una figura geométrica dibujada por código (ShapeGeometry).
## COLLECTION: un conjunto de elementos distintos ("items": figuras, dibujos,
## letras o números) en una tarjeta, cada uno en su celda.
## (Los tipos nuevos van al final.)
enum Kind { LETTER, IMAGE, WORD, NUMBER, GROUP, SHAPE, COLLECTION }
## Disposición de los objetos de un GROUP. Nunca se superponen.
## GRID: filas ordenadas. DICE: puntos como en un dado (1-6). SCATTER: cada
## objeto en una celda distinta, desplazado al azar dentro de ella.
enum Layout { GRID, DICE, SCATTER }

var kind: Kind = Kind.LETTER
## Letra o palabra que se muestra (para IMAGE, la palabra se usa solo como "spoken").
var text: String = ""
var texture: Texture2D
## IMAGE sin textura: emoji provisional (WordEntry.glyph).
var glyph: String = ""
## Índice de tipografía en ContentBank (0 = la del juego).
var font_index: int = 0
var font_size: int = 110
var color: Color = Color("#5B3A29")
## Lo que diría la narración al señalar la tarjeta.
var spoken: String = ""
## Para actividades de clasificar: índice de la cesta correcta.
var category: int = -1
## GROUP: cuántos objetos, cómo se colocan y semilla de la colocación (la
## misma tarjeta se dibuja siempre igual, también al arrastrarla).
var count: int = 1
var layout: Layout = Layout.GRID
var layout_seed: int = 0
## Tarjeta de enunciado apaisada (p. ej. una fila de números "2  3  _  5").
var wide: bool = false
## SHAPE: figura (ShapeGeometry.Shape), variante de triángulo, proporción
## (lado largo / corto), giro en grados y tamaño relativo (0-1).
var shape: int = 0
var shape_variant: int = 0
var shape_aspect: float = 1.0
var shape_rotation: float = 0.0
var shape_scale: float = 1.0
## Parte de un dibujo compuesto (vista SCENE): rectángulo en el lienzo.
var area: Rect2 = Rect2()
## COLLECTION: los elementos del conjunto (se colocan con layout/layout_seed).
var items: Array[CardData] = []


static func letter(value: String, font: int = 0, size: int = 110, tint: Color = Color("#5B3A29")) -> CardData:
	var card := CardData.new()
	card.kind = Kind.LETTER
	card.text = value
	card.font_index = font
	card.font_size = size
	card.color = tint
	card.spoken = value
	return card


static func image(entry: WordEntry) -> CardData:
	var card := CardData.new()
	card.kind = Kind.IMAGE
	card.text = entry.word
	card.texture = entry.texture
	card.glyph = entry.glyph if entry.texture == null else ""
	card.spoken = entry.spoken_word()
	return card


static func number(value: int, font: int = 0, size: int = 110, tint: Color = Color("#5B3A29")) -> CardData:
	var card := CardData.letter(str(value), font, size, tint)
	card.kind = Kind.NUMBER
	return card


## Grupo de "amount" objetos iguales (entry.word en plural: "manzanas").
static func group(entry: WordEntry, amount: int, arrangement: Layout = Layout.GRID, arrangement_seed: int = 0) -> CardData:
	var card := CardData.new()
	card.kind = Kind.GROUP
	card.text = "%d %s" % [amount, entry.word]
	card.texture = entry.texture
	card.glyph = entry.glyph if entry.texture == null else ""
	card.count = amount
	card.layout = arrangement
	card.layout_seed = arrangement_seed
	card.spoken = card.text
	return card


static func shape_card(figure: int, tint: Color, variant: int = 0, aspect: float = 1.0,
		turn: float = 0.0, relative_size: float = 1.0) -> CardData:
	var card := CardData.new()
	card.kind = Kind.SHAPE
	card.shape = figure
	card.color = tint
	card.shape_variant = variant
	card.shape_aspect = aspect
	card.shape_rotation = turn
	card.shape_scale = relative_size
	card.text = ShapeBank.NAMES[figure]
	card.spoken = card.text
	return card


## Conjunto de elementos distintos. "label" identifica el conjunto en las firmas.
static func collection(elements: Array[CardData], arrangement: Layout = Layout.GRID,
		arrangement_seed: int = 0, label: String = "") -> CardData:
	var card := CardData.new()
	card.kind = Kind.COLLECTION
	card.items = elements
	card.count = elements.size()
	card.layout = arrangement
	card.layout_seed = arrangement_seed
	var tokens: PackedStringArray = []
	for element: CardData in elements:
		tokens.append(element.token())
	tokens.sort()
	card.text = label if not label.is_empty() else ",".join(tokens)
	card.spoken = ""
	return card


## Valor de un numeral (NUMBER) o cantidad de un grupo (GROUP).
func value() -> int:
	return count if kind == Kind.GROUP else int(text)


## Token estable para firmas de contenido.
func token() -> String:
	if kind == Kind.GROUP:
		return "%s:%s:%d" % [Kind.keys()[kind], text, layout]
	if kind == Kind.SHAPE:
		return "SHAPE:%d:%d:%d:%s" % [shape, shape_variant, roundi(shape_rotation / 15.0), color.to_html(false)]
	return "%s:%s:%d" % [Kind.keys()[kind], text, font_index]
