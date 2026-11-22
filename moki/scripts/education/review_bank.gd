@tool
class_name ReviewBank
extends CombinationBank
## Banco de una lección del Mundo de Repaso. Reutiliza el contenido de los
## mundos anteriores (como CombinationBank) y lo adapta al niño con su
## desempeño REAL guardado (EducationProgress.concept_need):
## - prepare(): elige con más frecuencia las vocales, números y figuras que más
##   práctica necesitan (peso = MAINTENANCE + necesidad: lo dominado sigue
##   saliendo de vez en cuando y lo que no tiene datos se explora por igual);
## - template_bonus(): da prioridad a las dinámicas que trabajan lo que cuesta
##   (figuras parecidas, contar, vocal en contexto) o, si todo va bien, a los
##   retos de contexto y combinados;
## - concepts_for(): cada actividad actualiza el concepto que practicó
##   (letter_e, numbers_7_8, shapes_square...): el perfil se sigue construyendo;
## - extra_intro(): Moki dice qué se repasará, sin etiquetar al niño.

enum Focus { VOWELS, NUMBERS, SHAPES, MIXED, ALL }

## Peso mínimo de cualquier objetivo (mantenimiento de lo dominado).
const MAINTENANCE: float = 0.15
## Necesidad a partir de la cual se nombra en la introducción.
const MENTION_NEED: float = 0.45
## Necesidad media por debajo de la cual se considera que "va muy bien".
const STRONG_NEED: float = 0.25
## Bonus máximo de una dinámica (menor que la penalización por repetirla).
const MAX_BONUS: float = 3.0

const VOWEL_CONCEPTS: Dictionary = {
	"A": &"letter_a", "E": &"letter_e", "I": &"letter_i", "O": &"letter_o", "U": &"letter_u",
}
const SHAPE_CONCEPTS: Array[StringName] = [
	&"shapes_circle", &"shapes_square", &"shapes_triangle", &"shapes_rectangle", &"shapes_oval",
]
## Dinámicas para figuras que se confunden, para contar y para la vocal en contexto.
const CONFUSION_TEMPLATES: Array[StringName] = [&"sh_twins", &"sh_odd", &"sh_corners", &"cb_corners_shape"]
const COUNTING_TEMPLATES: Array[StringName] = [
	&"num_count", &"num_count_tap", &"num_find_group", &"num_compare",
	&"cb_count_shapes", &"cb_vowel_count", &"cb_tap_n_shapes", &"cb_tap_n_vowel",
]
const VOWEL_CONTEXT_TEMPLATES: Array[StringName] = [
	&"cb_vowel_initial", &"cb_image_for_vowel", &"cb_find_images", &"cb_word_vowel", &"cb_vowel_count",
]
## Retos que piden aplicar lo aprendido en contextos nuevos o combinados.
const CHALLENGE_TEMPLATES: Array[StringName] = [
	&"cb_count_shapes", &"cb_compare_shapes", &"cb_scene_count", &"cb_vowel_count", &"cb_tap_n_vowel",
	&"cb_tap_n_shapes", &"cb_sort_symbols3", &"sh_scene", &"num_sequence", &"cb_word_vowel",
]

@export var focus: Focus = Focus.ALL

var _needs: Dictionary = {}


## Concepto de los números (por pareja de lecciones: 7 → numbers_7_8).
static func number_concept(value: int) -> StringName:
	var first: int = value if value % 2 == 1 else value - 1
	return StringName("numbers_%d_%d" % [first, first + 1])


## Todos los conceptos de origen que puede repasar.
func source_concepts() -> Array[StringName]:
	var result: Array[StringName] = []
	for vowel: String in VOWEL_CONCEPTS:
		result.append(VOWEL_CONCEPTS[vowel])
	for value in [1, 3, 5, 7, 9]:
		result.append(number_concept(value))
	result.append_array(SHAPE_CONCEPTS)
	return result


## Necesidad de un concepto (neutra, 0,5, si no hay datos: EducationProgress.NEUTRAL_NEED).
func need_of(concept_id: StringName) -> float:
	return float(_needs.get(concept_id, {}).get("need", 0.5))


func prepare(needs: Dictionary) -> void:
	_needs = needs
	vowel_weights = {}
	for vowel: String in VOWEL_CONCEPTS:
		vowel_weights[vowel] = MAINTENANCE + need_of(VOWEL_CONCEPTS[vowel])
	if numbers != null:
		numbers.target_weights = {}
		for value in range(1, 11):
			numbers.target_weights[value] = MAINTENANCE + need_of(number_concept(value))
	shape_weights = {}
	for shape in 5:
		shape_weights[shape] = MAINTENANCE + need_of(SHAPE_CONCEPTS[shape])
	if shapes != null:
		shapes.target_weights = shape_weights.duplicate()


## Qué concepto de origen practicó una actividad (para actualizar su desempeño).
func concepts_for(instance: ActivityInstance) -> Array[StringName]:
	var result: Array[StringName] = []
	if instance == null or instance.template == null:
		return result
	var generator: ActivityGenerator = instance.template.generator
	var values: Dictionary = instance.fill_values
	if generator is NumberSymbolGenerator or generator is QuantityGenerator:
		if values.has("number"):
			result.append(number_concept(int(values["number"])))
	elif generator is ShapeGenerator or generator is ShapeObjectGenerator:
		var shape: int = ShapeBank.NAMES.find(values.get("name", ""))
		if shape >= 0:
			result.append(SHAPE_CONCEPTS[shape])
	elif generator is CombinationGenerator:
		var mode: int = generator.get("mode")
		if mode == CombinationGenerator.Mode.SORT_SYMBOLS or mode == CombinationGenerator.Mode.SORT_ROUND:
			return result  # clasificar clases de cosas: no practica un objetivo concreto
		if values.has("letter") and VOWEL_CONCEPTS.has(values["letter"]):
			result.append(VOWEL_CONCEPTS[values["letter"]])
		var shape: int = ShapeBank.NAMES.find(values.get("name", ""))
		if shape >= 0:
			result.append(SHAPE_CONCEPTS[shape])
	return result


## Bonus por dinámica según las necesidades (0 si no hay datos suficientes).
func template_bonus(level: LevelDefinition, needs: Dictionary) -> Dictionary:
	var bonus: Dictionary = {}
	var vowel_need: float = _max_need(needs, VOWEL_CONCEPTS.values())
	var count_need: float = _max_need(needs, [number_concept(1), number_concept(3), number_concept(5),
		number_concept(7), number_concept(9)])
	var confusion: float = 0.0
	for concept_id: StringName in [&"shapes_square", &"shapes_rectangle", &"shapes_circle", &"shapes_oval"]:
		var info: Dictionary = needs.get(concept_id, {})
		if info.get("sufficient", false) and float(info.get("discriminate", -1.0)) >= 0.0:
			confusion = maxf(confusion, 1.0 - float(info["discriminate"]))
	# "Va muy bien": hay datos de al menos la mitad de los conceptos, la media es
	# baja y NINGUNO necesita práctica (si alguno la necesita, eso va primero).
	var sufficient: int = 0
	var total_need: float = 0.0
	var highest: float = 0.0
	for concept_id: StringName in needs:
		if needs[concept_id].get("sufficient", false):
			sufficient += 1
			total_need += float(needs[concept_id]["need"])
			highest = maxf(highest, float(needs[concept_id]["need"]))
	var strong: bool = sufficient > 0 and sufficient * 2 >= needs.size() and total_need / sufficient < STRONG_NEED \
		and highest < MENTION_NEED
	for template: ActivityTemplate in level.templates:
		var value: float = 0.0
		if CONFUSION_TEMPLATES.has(template.id):
			value = maxf(value, MAX_BONUS * confusion)
		if COUNTING_TEMPLATES.has(template.id):
			value = maxf(value, MAX_BONUS * count_need)
		if VOWEL_CONTEXT_TEMPLATES.has(template.id):
			value = maxf(value, MAX_BONUS * vowel_need)
		if strong and CHALLENGE_TEMPLATES.has(template.id):
			value = maxf(value, MAX_BONUS * 0.7)
		if value > 0.0:
			bonus[template.id] = minf(value, MAX_BONUS)
	return bonus


## La necesidad más alta entre conceptos CON datos suficientes (0 si ninguno).
static func _max_need(needs: Dictionary, concept_ids: Array) -> float:
	var best: float = 0.0
	for concept_id: StringName in concept_ids:
		var info: Dictionary = needs.get(concept_id, {})
		if info.get("sufficient", false):
			best = maxf(best, float(info["need"]))
	return best


## Una frase según el perfil: qué se practicará hoy (sin etiquetar al niño).
func extra_intro() -> Array[DialogueLine]:
	var candidates: Array = []
	var any_data: bool = false
	for concept_id: StringName in _relevant_concepts():
		var info: Dictionary = _needs.get(concept_id, {})
		if not info.get("sufficient", false):
			continue
		any_data = true
		if float(info["need"]) >= MENTION_NEED:
			candidates.append([float(info["need"]), concept_id])
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var text: String
	if not any_data:
		text = "Hoy jugaremos con un poco de todo. ¡Así sabré qué juegos te gustan más!"
	elif candidates.is_empty():
		text = "¡Ya sabes muchísimo! Hoy te traigo retos en lugares nuevos."
	else:
		var names: PackedStringArray = []
		for pair: Array in candidates.slice(0, 2):
			names.append(_concept_name(pair[1]))
		text = "Hoy vamos a jugar otra vez con %s: ¡practicar nos hace crecer!" % " y ".join(names)
	return [DialogueLine.make(text, DialogueLine.Kind.TIP, Moki.Mood.HAPPY)]


func _relevant_concepts() -> Array[StringName]:
	var all: Array[StringName] = source_concepts()
	match focus:
		Focus.VOWELS:
			return all.slice(0, 5)
		Focus.NUMBERS:
			return all.slice(5, 10)
		Focus.SHAPES:
			return all.slice(10, 15)
	return all


## Nombre para Moki: "la E", "los números 7 y 8", "el cuadrado".
static func _concept_name(concept_id: StringName) -> String:
	var key := String(concept_id)
	if key.begins_with("letter_"):
		return "la " + key.trim_prefix("letter_").to_upper()
	if key.begins_with("numbers_"):
		var parts: PackedStringArray = key.trim_prefix("numbers_").split("_")
		return "los números %s y %s" % [parts[0], parts[1]]
	var shape: int = SHAPE_CONCEPTS.find(concept_id)
	return "el " + ShapeBank.NAMES[shape] if shape >= 0 else key
