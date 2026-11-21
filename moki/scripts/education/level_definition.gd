@tool
class_name LevelDefinition
extends Resource
## Un nivel = un objetivo educativo permanente. Cada vez que se juega se genera
## una lección distinta (LessonBuilder) a partir de sus plantillas.

@export var id: StringName = &""
@export var title: String = ""
## Objetivo educativo (para el adulto y la documentación).
@export_multiline var objective: String = ""
## Conceptos que trabaja (desempeño guardado por concepto).
@export var concept_ids: Array[StringName] = []
## Lo que Moki explica al empezar: qué aprenderá, qué hacer, cómo funciona y un ejemplo.
@export var intro: Array[DialogueLine] = []
## Frases de cierre (se elige una).
@export var outro: Array[DialogueLine] = []
@export var templates: Array[ActivityTemplate] = []
@export var content: ContentBank
@export_range(1, 12) var lesson_min: int = 5
@export_range(1, 12) var lesson_max: int = 8
## Niveles que se desbloquean al completar este.
@export var unlocks: Array[StringName] = []


func templates_for_stage(stage: ActivityTemplate.Stage) -> Array[ActivityTemplate]:
	var result: Array[ActivityTemplate] = []
	for template: ActivityTemplate in templates:
		if template != null and template.stage == stage:
			result.append(template)
	return result


func get_template(template_id: StringName) -> ActivityTemplate:
	for template: ActivityTemplate in templates:
		if template != null and template.id == template_id:
			return template
	return null
