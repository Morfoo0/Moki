@tool
class_name CombinationBank
extends ContentBank
## Contenido de una lección del Mundo de Combinación. No copia contenido:
## referencia los bancos de las vocales (dibujos, palabras, sonidos), un banco
## de números y uno de figuras. Cada actividad recibe el banco que entiende su
## generador (resolve_for), así que las plantillas de Números y Figuras se
## reutilizan tal cual.

@export_group("Bancos reutilizados")
## Bancos de las vocales (Mundo de Letras).
@export var vowel_banks: Array[ContentBank] = []
## Números del 1 al 10 y objetos para contar (plantillas num_*).
@export var numbers: NumberBank
## Las cinco figuras y sus objetos (plantillas sh_*).
@export var shapes: ShapeBank

@export_group("Combinación")
## Cantidad máxima en los conteos de esta lección.
@export_range(2, 10) var max_count: int = 6

var _words: Array[WordEntry] = []


func resolve_for(template: ActivityTemplate, _rng: RandomNumberGenerator) -> ContentBank:
	var generator: ActivityGenerator = template.generator
	if generator is NumberSymbolGenerator or generator is QuantityGenerator:
		return numbers
	if generator is ShapeGenerator or generator is ShapeObjectGenerator:
		return shapes
	return self


## Vocales disponibles (mayúsculas), en orden.
func vowels() -> PackedStringArray:
	var result := PackedStringArray()
	for bank: ContentBank in vowel_banks:
		result.append(ContentBank.normalize(bank.target))
	return result


func bank_of(vowel: String) -> ContentBank:
	for bank: ContentBank in vowel_banks:
		if ContentBank.normalize(bank.target) == ContentBank.normalize(vowel):
			return bank
	return null


func lower_of(vowel: String) -> String:
	var bank: ContentBank = bank_of(vowel)
	return bank.target_lower if bank != null else vowel.to_lower()


## Todas las palabras con dibujo que empiezan por una vocal (las de Letras),
## con su vocal inicial. Solo las aptas para la dificultad.
func vowel_words(difficulty: int) -> Array[WordEntry]:
	_collect()
	var result: Array[WordEntry] = []
	for entry: WordEntry in _words:
		if entry.min_difficulty <= difficulty:
			result.append(entry)
	return result


func words_starting_with(vowel: String, difficulty: int) -> Array[WordEntry]:
	var result: Array[WordEntry] = []
	for entry: WordEntry in vowel_words(difficulty):
		if entry.starts_with(vowel):
			result.append(entry)
	return result


## Vocal inicial de una palabra (normalizada: "ábaco" → "A").
static func initial_vowel(entry: WordEntry) -> String:
	return ContentBank.normalize(entry.initial())


func _collect() -> void:
	if not _words.is_empty():
		return
	for bank: ContentBank in vowel_banks:
		for entry: WordEntry in bank.words_with_target:
			if entry != null and entry.starts_with(bank.target):
				_words.append(entry)
