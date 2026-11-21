class_name LessonPlan
extends RefCounted
## Plan de una lección: huecos (plantilla + dificultad objetivo). Las
## instancias concretas se generan al empezar cada actividad, con la
## dificultad adaptada en ese momento.

var level: LevelDefinition
var base_difficulty: int = 1
## [{template: ActivityTemplate, difficulty: int}]
var slots: Array[Dictionary] = []


func add_slot(template: ActivityTemplate, difficulty: int) -> void:
	slots.append({"template": template, "difficulty": difficulty})


func insert_slot(at: int, template: ActivityTemplate, difficulty: int) -> void:
	slots.insert(at, {"template": template, "difficulty": difficulty})


func size() -> int:
	return slots.size()


func template_ids() -> Array:
	var ids: Array = []
	for slot: Dictionary in slots:
		ids.append((slot["template"] as ActivityTemplate).id)
	return ids
