extends Node
## Autoload "EducationProgress": progreso educativo persistente.
## Guarda (sección "education" de SaveService): mundos y niveles desbloqueados,
## niveles completados, historial de lecciones, actividades recientes,
## desempeño por concepto y etapa, y pistas usadas.
##
## Independiente del cuidado de Moki: no usa NeedsManager ni Inventory.
## Nunca resta progreso: terminar una lección siempre cuenta.

signal progress_changed

const CATALOG_PATH: String = "res://resources/education/education_catalog.tres"
const SAVE_SECTION: String = "education"
const DATA_VERSION: int = 1
const MAX_LESSONS: int = 10
const MAX_SIGNATURES: int = 40
## Peso de la última actividad en la media móvil de cada etapa (no se domina
## un concepto con una sola respuesta).
const STAGE_WEIGHT: float = 0.3
## Dominio necesario y lecciones mínimas para considerar un concepto dominado.
const MASTERY_THRESHOLD: float = 0.8
const MASTERY_MIN_LESSONS: int = 2
## Actividades mínimas de un concepto para sacar conclusiones (repaso).
const MIN_EVIDENCE: int = 4
## Necesidad que se asume sin datos suficientes: neutra (ni fácil ni difícil).
const NEUTRAL_NEED: float = 0.5

var catalog: EducationCatalog

var _data: Dictionary = {}


func _ready() -> void:
	catalog = load(CATALOG_PATH) as EducationCatalog
	reset()
	SaveService.register_section(SAVE_SECTION, to_dict, _apply_saved)


func reset() -> void:
	_data = {
		"version": DATA_VERSION,
		"unlocked_worlds": [],
		"unlocked_levels": [],
		"completed_levels": {},
		"lessons": {},
		"recent_activities": {},
		"concepts": {},
		"hints_total": 0,
		"last_difficulty": {},
	}
	if catalog == null:
		return
	for world: WorldDefinition in catalog.worlds:
		if world.unlocked_by_default:
			_data["unlocked_worlds"].append(String(world.id))
			if not world.levels.is_empty():
				_data["unlocked_levels"].append(String(world.levels[0].id))
	progress_changed.emit()


# --- Consulta ------------------------------------------------------------------

func is_world_unlocked(world_id: StringName) -> bool:
	return _data["unlocked_worlds"].has(String(world_id))


func is_level_unlocked(level_id: StringName) -> bool:
	return _data["unlocked_levels"].has(String(level_id))


func times_completed(level_id: StringName) -> int:
	return int(_data["completed_levels"].get(String(level_id), 0))


func get_lessons(level_id: StringName) -> Array:
	return _data["lessons"].get(String(level_id), [])


func get_concept(concept_id: StringName) -> Dictionary:
	return _data["concepts"].get(String(concept_id), {})


func get_hints_total() -> int:
	return int(_data["hints_total"])


func get_mastery(level: LevelDefinition) -> float:
	if level.concept_ids.is_empty():
		return 0.0
	var total: float = 0.0
	for concept_id: StringName in level.concept_ids:
		total += float(get_concept(concept_id).get("mastery", 0.0))
	return total / level.concept_ids.size()


func is_mastered(level: LevelDefinition) -> bool:
	return get_mastery(level) >= MASTERY_THRESHOLD and get_lessons(level.id).size() >= MASTERY_MIN_LESSONS


func get_recent_signatures(level_id: StringName) -> PackedStringArray:
	return PackedStringArray(_data["recent_activities"].get(String(level_id), []))


## Cuánta práctica necesita un concepto (0 = la resuelve sola y con soltura,
## 1 = le cuesta mucho), calculado SOLO con datos guardados. Con menos de
## MIN_EVIDENCE actividades no se concluye nada: necesidad neutra.
## Mira patrones (medias móviles, tasas por actividad, lecciones recientes),
## nunca una respuesta aislada. Nunca se muestra al niño como nota.
func concept_need(concept_id: StringName) -> Dictionary:
	var concept: Dictionary = get_concept(concept_id)
	var activities: int = int(concept.get("activities", 0))
	var by_stage: Dictionary = concept.get("by_stage", {})
	var discriminate: float = float(by_stage.get(str(ActivityTemplate.Stage.DISCRIMINATE), -1.0))
	if activities < MIN_EVIDENCE:
		return {"need": NEUTRAL_NEED, "sufficient": false, "activities": activities, "discriminate": discriminate}
	# Dominio: solo las etapas practicadas (no practicar una etapa no es dificultad).
	var practiced: float = 0.0
	for stage_key: String in by_stage:
		practiced += float(by_stage[stage_key])
	practiced /= maxf(1.0, by_stage.size())
	var hints_rate: float = clampf(float(concept.get("hints_used", 0)) / activities / 2.0, 0.0, 1.0)
	var error_rate: float = clampf(float(concept.get("errors", 0)) / activities / 3.0, 0.0, 1.0)
	var need: float = 0.45 * (1.0 - practiced) + 0.25 * hints_rate + 0.2 * error_rate + 0.1 * _recent_struggle(concept_id)
	return {"need": clampf(need, 0.0, 1.0), "sufficient": true, "activities": activities, "discriminate": discriminate}


## Pistas y saltos en las últimas lecciones del nivel al que pertenece el concepto (0-1).
func _recent_struggle(concept_id: StringName) -> float:
	if catalog == null:
		return 0.0
	for world: WorldDefinition in catalog.worlds:
		for level: LevelDefinition in world.levels:
			if level == null or not level.concept_ids.has(concept_id):
				continue
			var hints: int = 0
			var skipped: int = 0
			var count: int = 0
			for lesson: Dictionary in get_lessons(level.id).slice(-3):
				for result: Dictionary in lesson.get("results", []):
					hints += int(result.get("hints", 0))
					skipped += 1 if result.get("skipped", false) else 0
					count += 1
			if count == 0:
				return 0.0
			return clampf(float(hints) / count / 2.0 + float(skipped) / count, 0.0, 1.0)
	return 0.0


## Información para LessonBuilder.
func get_snapshot(level: LevelDefinition) -> Dictionary:
	var lessons: Array = get_lessons(level.id)
	var last_templates: Array = []
	var recent_templates: Array = []
	var struggle: float = 0.0
	if not lessons.is_empty():
		var last: Dictionary = lessons.back()
		for template_id: String in last.get("templates", []):
			last_templates.append(StringName(template_id))
		var hints: int = 0
		for result: Dictionary in last.get("results", []):
			hints += int(result.get("hints", 0))
		struggle = float(hints) / maxf(1.0, last.get("results", []).size())
		for lesson: Dictionary in lessons.slice(-3):
			for template_id: String in lesson.get("templates", []):
				recent_templates.append(StringName(template_id))
	var stage_scores: Dictionary = {}
	for concept_id: StringName in level.concept_ids:
		var by_stage: Dictionary = get_concept(concept_id).get("by_stage", {})
		for stage_key: String in by_stage:
			stage_scores[int(stage_key)] = float(by_stage[stage_key])
	var snapshot := {
		"mastery": get_mastery(level),
		"stage_scores": stage_scores,
		"last_difficulty": int(_data["last_difficulty"].get(String(level.id), -1)),
		"last_templates": last_templates,
		"recent_templates": recent_templates,
		"recent_signatures": get_recent_signatures(level.id),
		"struggle": struggle,
	}
	if level.content is ReviewBank:
		_add_review_info(level, snapshot)
	return snapshot


## Repaso: necesidades de los conceptos de origen, prioridad de dinámicas y, si
## aún no hay lecciones de Repaso, un dominio de partida basado en los conceptos
## de origen con datos suficientes (no se empieza desde cero sin motivo).
func _add_review_info(level: LevelDefinition, snapshot: Dictionary) -> void:
	var bank := level.content as ReviewBank
	var needs: Dictionary = {}
	for concept_id: StringName in bank.source_concepts():
		needs[concept_id] = concept_need(concept_id)
	snapshot["needs"] = needs
	snapshot["template_bonus"] = bank.template_bonus(level, needs)
	snapshot["no_repeats"] = true  # repaso variado: no repetir una dinámica si hay otra
	if get_lessons(level.id).is_empty():
		var total: float = 0.0
		var known: int = 0
		for concept_id: StringName in needs:
			if needs[concept_id]["sufficient"]:
				total += 1.0 - float(needs[concept_id]["need"])
				known += 1
		if known > 0:
			# Como mucho 0,84: la primera lección de repaso empieza en dificultad 4,
			# nunca directamente en la máxima.
			snapshot["mastery"] = minf(total / known, 0.84)


# --- Registro ------------------------------------------------------------------

## Una actividad terminada (también si se saltó: cuenta como "necesitó ayuda").
func record_activity(level: LevelDefinition, result: Dictionary) -> void:
	var success: float = 1.0 if result.get("first_try", false) else (
		0.0 if result.get("skipped", false) else (0.6 if int(result.get("hints", 0)) == 0 else 0.3))
	# Conceptos del nivel + los que practicó la actividad (Repaso: la vocal, el
	# número o la figura de origen). En los demás mundos, solo los del nivel.
	var concept_ids: Array[StringName] = level.concept_ids.duplicate()
	for extra: StringName in result.get("concepts", []):
		if not concept_ids.has(extra):
			concept_ids.append(extra)
	for concept_id: StringName in concept_ids:
		var key := String(concept_id)
		var concept: Dictionary = _data["concepts"].get(key, {
			"mastery": 0.0, "by_stage": {}, "attempts": 0, "activities": 0,
			"first_try_correct": 0, "hints_used": 0, "errors": 0, "skipped": 0,
		})
		var stage_key := str(int(result.get("stage", 0)))
		var previous: float = float(concept["by_stage"].get(stage_key, 0.0))
		concept["by_stage"][stage_key] = previous * (1.0 - STAGE_WEIGHT) + success * STAGE_WEIGHT
		concept["activities"] += 1
		concept["attempts"] += int(result.get("attempts", 1))
		concept["errors"] += int(result.get("errors", 0))
		concept["hints_used"] += int(result.get("hints", 0))
		concept["first_try_correct"] += 1 if result.get("first_try", false) else 0
		concept["skipped"] += 1 if result.get("skipped", false) else 0
		# Dominio = media de las 5 etapas (las no practicadas cuentan 0).
		var total: float = 0.0
		for stage in ActivityTemplate.Stage.size():
			total += float(concept["by_stage"].get(str(stage), 0.0))
		concept["mastery"] = total / ActivityTemplate.Stage.size()
		_data["concepts"][key] = concept
	_data["hints_total"] = int(_data["hints_total"]) + int(result.get("hints", 0))
	var recent: Array = _data["recent_activities"].get(String(level.id), [])
	recent.append(result.get("signature", ""))
	_data["recent_activities"][String(level.id)] = recent.slice(-MAX_SIGNATURES)
	progress_changed.emit()
	SaveService.save_game()


## Lección terminada: cuenta como nivel completado y desbloquea los siguientes.
func record_lesson(level: LevelDefinition, summary: Dictionary) -> void:
	var key := String(level.id)
	var lessons: Array = _data["lessons"].get(key, [])
	var compact_results: Array = []
	for result: Dictionary in summary.get("results", []):
		compact_results.append({
			"template": result["template"], "stage": result["stage"], "difficulty": result["difficulty"],
			"attempts": result["attempts"], "hints": result["hints"], "first_try": result["first_try"],
			"skipped": result["skipped"],
		})
	lessons.append({
		"at": int(Time.get_unix_time_from_system()),
		"templates": summary.get("templates", []),
		"signatures": summary.get("signatures", []),
		"size": summary.get("size", 0),
		"base_difficulty": summary.get("base_difficulty", 1),
		"results": compact_results,
	})
	_data["lessons"][key] = lessons.slice(-MAX_LESSONS)
	_data["last_difficulty"][key] = int(summary.get("base_difficulty", 1))
	_data["completed_levels"][key] = times_completed(level.id) + 1
	_unlock_after(level)
	progress_changed.emit()
	SaveService.save_game()


## Lo que abre completar un nivel: sus niveles siguientes y los mundos que
## esperan a ese nivel (WorldDefinition.unlocked_after_level).
func _unlock_after(level: LevelDefinition) -> void:
	for unlocked: StringName in level.unlocks:
		if not _data["unlocked_levels"].has(String(unlocked)):
			_data["unlocked_levels"].append(String(unlocked))
	if catalog == null:
		return
	for world: WorldDefinition in catalog.worlds:
		if world.unlocked_after_level == level.id:
			_unlock_world(world)


## Desbloquea un mundo y su primer nivel.
func _unlock_world(world: WorldDefinition) -> void:
	if not _data["unlocked_worlds"].has(String(world.id)):
		_data["unlocked_worlds"].append(String(world.id))
	if not world.levels.is_empty() and not _data["unlocked_levels"].has(String(world.levels[0].id)):
		_data["unlocked_levels"].append(String(world.levels[0].id))


# --- Persistencia --------------------------------------------------------------

func to_dict() -> Dictionary:
	return _data.duplicate(true)


func _apply_saved(data: Dictionary, _saved_at: int) -> void:
	if int(data.get("version", 0)) > DATA_VERSION:
		push_warning("EducationProgress: versión de progreso no compatible; se conserva el progreso actual.")
		return
	for key: String in _data:
		if data.has(key) and typeof(data[key]) == typeof(_data[key]):
			_data[key] = data[key]
	# Lo desbloqueado por defecto siempre lo está (p. ej. un mundo nuevo).
	for world: WorldDefinition in catalog.worlds:
		if world.unlocked_by_default and not _data["unlocked_worlds"].has(String(world.id)):
			_data["unlocked_worlds"].append(String(world.id))
			if not world.levels.is_empty():
				_data["unlocked_levels"].append(String(world.levels[0].id))
	# Desbloqueo retroactivo: un nivel ya completado abre sus siguientes (y los
	# mundos que lo esperan) aunque la partida sea de antes de que existieran
	# (p. ej. la E tras la A, o Números tras la U).
	for world: WorldDefinition in catalog.worlds:
		for level: LevelDefinition in world.levels:
			if level != null and times_completed(level.id) > 0:
				_unlock_after(level)
	progress_changed.emit()
