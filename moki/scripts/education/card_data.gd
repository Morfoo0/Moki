class_name CardData
extends RefCounted
## Contenido concreto de una tarjeta de actividad (letra, imagen, palabra,
## numeral o grupo de objetos para contar).

## NUMBER: un numeral ("7", "10"). GROUP: "count" objetos iguales (texture o glyph).
## (Los tipos nuevos van al final.)
enum Kind { LETTER, IMAGE, WORD, NUMBER, GROUP }
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


## Valor de un numeral (NUMBER) o cantidad de un grupo (GROUP).
func value() -> int:
	return count if kind == Kind.GROUP else int(text)


## Token estable para firmas de contenido.
func token() -> String:
	if kind == Kind.GROUP:
		return "%s:%s:%d" % [Kind.keys()[kind], text, layout]
	return "%s:%s:%d" % [Kind.keys()[kind], text, font_index]
