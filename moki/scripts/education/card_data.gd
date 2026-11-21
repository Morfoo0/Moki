class_name CardData
extends RefCounted
## Contenido concreto de una tarjeta de actividad (letra, imagen o palabra).

enum Kind { LETTER, IMAGE, WORD }

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


## Token estable para firmas de contenido.
func token() -> String:
	return "%s:%s:%d" % [Kind.keys()[kind], text, font_index]
