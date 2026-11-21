@tool
class_name WordEntry
extends Resource
## Palabra con su imagen (recursos existentes del juego).

@export var word: String = ""
@export var texture: Texture2D
## Artículo para frases ("un", "una", "unos"...).
@export var article: String = "un"
## Dificultad mínima para usarla (p. ej. palabras con tilde a partir de 3).
@export_range(1, 5) var min_difficulty: int = 1


func initial() -> String:
	return word.left(1).to_upper()


## True si empieza por la letra (la vocal con tilde cuenta como la misma letra).
func starts_with(letter: String) -> bool:
	return ContentBank.normalize(initial()) == ContentBank.normalize(letter)


func spoken_word() -> String:
	return word.to_lower()
