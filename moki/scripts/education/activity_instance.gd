class_name ActivityInstance
extends RefCounted
## Una actividad concreta, lista para mostrarse: tarjetas, respuestas correctas
## y datos para las pistas. La crea un ActivityGenerator.

var template: ActivityTemplate
var difficulty: int = 1
var instruction: DialogueLine
var cards: Array[CardData] = []
## CHOICE: un índice. SEARCH: todos los índices que hay que encontrar.
var correct: Array[int] = []
## SORT: etiquetas de las cestas (cada CardData.category apunta a una).
var bins: Array[CardData] = []
## Tarjeta de enunciado (p. ej. la imagen en "¿con qué letra empieza?").
var prompt_card: CardData
## Tarjeta modelo para la pista visual (p. ej. una A grande).
var model_card: CardData
## Tarjetas que la pista visual puede retirar (nunca deja menos de 2 opciones).
var removable: Array[int] = []
## Firma del contenido para evitar repeticiones.
var signature: String = ""
## Valores para sustituir en textos ({word}, {article}...).
var fill_values: Dictionary = {}
## SEARCH: cuántas tarjetas correctas hay que tocar (0 = todas). Para "toca 3
## manzanas" entre más manzanas: todas son correctas y bastan 3.
var required: int = 0
## SEARCH: hay que tocar las correctas en el orden de "correct" (ordenar números).
var ordered: bool = false
## SEARCH: Moki cuenta en voz alta cada acierto ("¡Uno!", "¡Dos!"...).
var count_feedback: bool = false


## Cuántas tarjetas hay que encontrar para completar un SEARCH.
func needed() -> int:
	return required if required > 0 else correct.size()


func fill(text: String) -> String:
	return text.format(fill_values) if not fill_values.is_empty() else text


func is_correct(index: int) -> bool:
	return correct.has(index)


func view_type() -> ActivityTemplate.ViewType:
	return template.view_type


## Distractores que se retiran con la pista visual: la mitad, dejando
## siempre al menos 2 opciones en pantalla (nunca revela la respuesta).
func visual_hint_removals() -> Array[int]:
	var result: Array[int] = []
	var remaining: int = cards.size()
	var budget: int = removable.size() / 2
	for index: int in removable:
		if result.size() >= budget or remaining <= 2:
			break
		result.append(index)
		remaining -= 1
	return result
