@tool
class_name ContentBank
extends Resource
## Contenido reutilizable para actividades de una letra: letra objetivo,
## distractores por dificultad, palabras con imagen, palabras para buscar
## letras, tipografías y colores. Otro nivel (p. ej. la E) = otro ContentBank.

@export var target: String = "A"
@export var target_lower: String = "a"

@export_group("Distractores")
## Letras muy diferentes de la objetivo.
@export var easy_letters: PackedStringArray = ["O", "S", "C", "U"]
## Letras algo diferentes.
@export var medium_letters: PackedStringArray = ["E", "F", "L", "T"]
## Letras visualmente parecidas.
@export var similar_letters: PackedStringArray = ["H", "V", "M", "N", "K", "R"]
@export var lower_distractors: PackedStringArray = ["e", "o", "c", "u", "n"]

@export_group("Palabras")
## Palabras (con imagen) que empiezan por la letra.
@export var words_with_target: Array[WordEntry] = []
## Palabras (con imagen) que NO empiezan por la letra.
@export var words_without_target: Array[WordEntry] = []
## Palabras para "toca las letras de la palabra" (todas contienen la letra).
@export var spelling_words_easy: PackedStringArray = []
@export var spelling_words_hard: PackedStringArray = []

@export_group("Presentación")
## Tipografías del sistema (índice 1..n). El índice 0 es la tipografía del juego.
@export var font_names: PackedStringArray = ["Comic Sans MS", "Georgia", "Courier New", "Verdana", "Arial"]
@export var colors: PackedColorArray = [Color("#5B3A29"), Color("#E85D3F"), Color("#2F7FD1"), Color("#3E9B4F"), Color("#8E5BC8"), Color("#E0961B")]

var _fonts: Array[Font] = []


## Quita tildes y pasa a mayúsculas, para comparar letras.
static func normalize(value: String) -> String:
	return value.to_upper().replace("Á", "A").replace("É", "E").replace("Í", "I").replace("Ó", "O").replace("Ú", "U")


## Distractores según la dificultad (1-5), de más fáciles a más parecidos.
func distractors_for(difficulty: int) -> PackedStringArray:
	var pool := PackedStringArray()
	if difficulty <= 2:
		pool.append_array(easy_letters)
	if difficulty >= 2 and difficulty <= 4:
		pool.append_array(medium_letters)
	if difficulty >= 3:
		pool.append_array(similar_letters)
	return pool


func font_count() -> int:
	return font_names.size() + 1


## Tipografía por índice (0 = la del juego; null = usar la por defecto).
func get_font(index: int) -> Font:
	if index <= 0 or index > font_names.size():
		return null
	if _fonts.is_empty():
		for font_name: String in font_names:
			var font := SystemFont.new()
			font.font_names = PackedStringArray([font_name])
			_fonts.append(font)
	return _fonts[index - 1]


func words_for(with_target: bool, difficulty: int) -> Array[WordEntry]:
	var source: Array[WordEntry] = words_with_target if with_target else words_without_target
	var result: Array[WordEntry] = []
	for entry: WordEntry in source:
		if entry != null and entry.min_difficulty <= difficulty:
			result.append(entry)
	return result
