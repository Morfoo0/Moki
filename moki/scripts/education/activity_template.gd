@tool
class_name ActivityTemplate
extends Resource
## Una dinámica educativa que se puede generar de muchas formas.
## El generador produce instancias concretas (ActivityInstance) según la dificultad.

## Vista que presenta la actividad (reutilizable entre mundos).
## SCENE: encontrar partes dentro de un dibujo compuesto; se evalúa como SEARCH.
## (Las vistas nuevas van al final: los .tres guardan la vista como número.)
enum ViewType { CHOICE, SEARCH, SORT, SCENE }
## Etapa del aprendizaje del concepto (orden de una lección).
enum Stage { RECOGNIZE, DISCRIMINATE, ASSOCIATE, CONTEXT, REINFORCE }
## Escalones de la ayuda progresiva.
enum HintStep { REPHRASE, VERBAL, RIDDLE, VISUAL }

@export var id: StringName = &""
@export var title: String = ""
@export var view_type: ViewType = ViewType.CHOICE
@export var stage: Stage = Stage.RECOGNIZE
@export_range(1, 5) var difficulty_min: int = 1
@export_range(1, 5) var difficulty_max: int = 5

@export_group("Textos")
## Instrucción principal. El generador puede sustituir {word} y {article}.
@export_multiline var instruction: String = ""
## Instrucción para la voz (vacío = la misma).
@export var instruction_spoken: String = ""
## Ayuda progresiva: [reformular, pista verbal, acertijo/comparación, pista visual].
## Nunca deben decir dónde está ni cuál es la respuesta.
@export var hints: PackedStringArray = []
## Texto para la voz de cada pista (vacío = el mismo).
@export var hints_spoken: PackedStringArray = []

@export_group("Generación")
@export var generator: ActivityGenerator


func clamp_difficulty(difficulty: int) -> int:
	return clampi(difficulty, difficulty_min, difficulty_max)


func hint_line(step: HintStep, instance: ActivityInstance) -> DialogueLine:
	var index: int = mini(step, hints.size() - 1)
	var text: String = instance.fill(hints[index]) if index >= 0 else ""
	var spoken: String = instance.fill(hints_spoken[index]) if index < hints_spoken.size() else ""
	var kind: DialogueLine.Kind = DialogueLine.Kind.RIDDLE if step == HintStep.RIDDLE else DialogueLine.Kind.HINT
	return DialogueLine.make(text, kind, Moki.Mood.NEUTRAL, spoken)


## Genera una instancia evitando, si es posible, firmas usadas recientemente.
func generate(rng: RandomNumberGenerator, difficulty: int, bank: ContentBank,
		avoid_signatures: PackedStringArray = PackedStringArray()) -> ActivityInstance:
	var level: int = clamp_difficulty(difficulty)
	var instance: ActivityInstance
	for attempt in 8:
		instance = generator.generate(rng, level, bank)
		if not avoid_signatures.has(instance.signature):
			break
	instance.template = self
	instance.difficulty = level
	instance.instruction = DialogueLine.make(instance.fill(instruction), DialogueLine.Kind.INSTRUCTION,
		Moki.Mood.HAPPY, instance.fill(instruction_spoken))
	return instance
