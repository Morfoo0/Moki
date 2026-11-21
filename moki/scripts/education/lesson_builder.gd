class_name LessonBuilder
extends RefCounted
## Construye una lección (LessonPlan) para un nivel a partir del historial y
## el desempeño del niño. No depende solo del azar:
## - la dificultad base sale del dominio del concepto y nunca salta más de ±1
##   respecto a la lección anterior;
## - la estructura sigue las etapas del aprendizaje (reconocer → distinguir →
##   asociar → contexto → [extras en las etapas que más le cuestan] → reforzar);
## - cada plantilla se puntúa: penaliza repetirla (en esta lección, en la
##   anterior y en las recientes) y premia las etapas que más le cuestan;
## - nunca dos actividades seguidas con la misma plantilla ni con la misma
##   vista (búsqueda con vuelta atrás; si fuera imposible, repetición controlada);
## - si la lección sale igual que la anterior, se vuelve a construir.

const MAX_REBUILDS: int = 12

const CORE_STAGES: Array[ActivityTemplate.Stage] = [
	ActivityTemplate.Stage.RECOGNIZE, ActivityTemplate.Stage.DISCRIMINATE,
	ActivityTemplate.Stage.ASSOCIATE, ActivityTemplate.Stage.CONTEXT,
]


## snapshot: ver EducationProgress.get_snapshot().
static func build(level: LevelDefinition, snapshot: Dictionary, rng: RandomNumberGenerator) -> LessonPlan:
	var plan: LessonPlan
	var last: Array = snapshot.get("last_templates", [])
	for attempt in MAX_REBUILDS:
		plan = _build_once(level, snapshot, rng)
		if plan.template_ids() != last:
			break
	return plan


static func base_difficulty(snapshot: Dictionary) -> int:
	var mastery: float = snapshot.get("mastery", 0.0)
	var target: int = 1 + roundi(mastery * 3.0) + (1 if mastery >= 0.85 else 0)
	var last: int = snapshot.get("last_difficulty", -1)
	if last >= 1:
		target = clampi(target, last - 1, last + 1)
	return clampi(target, 1, 5)


static func lesson_size(level: LevelDefinition, snapshot: Dictionary) -> int:
	var mastery: float = snapshot.get("mastery", 0.0)
	var size: int = 6
	if mastery >= 0.6:
		size = 7
	if mastery >= 0.8:
		size = 8
	if snapshot.get("struggle", 0.0) >= 1.5:
		size = 5
	return clampi(size, level.lesson_min, level.lesson_max)


## Marca de hueco extra (práctica de las etapas que más cuestan).
const EXTRA: int = -1


## Etapas de cada hueco: las principales en orden, huecos extra (EXTRA) justo
## antes del refuerzo y refuerzo al final.
static func stage_sequence(size: int) -> Array:
	var stages: Array = CORE_STAGES.duplicate()
	for i in maxi(size - CORE_STAGES.size() - 1, 0):
		stages.append(EXTRA)
	stages.append(ActivityTemplate.Stage.REINFORCE)
	return stages.slice(0, size)


## Las dos etapas (de distinguir, asociar y contexto) que más le cuestan.
static func needy_stages(stage_scores: Dictionary) -> Array:
	var needy: Array = CORE_STAGES.slice(1)
	needy.sort_custom(func(a: int, b: int) -> bool: return stage_scores.get(a, 0.0) < stage_scores.get(b, 0.0))
	return needy.slice(0, 2)


static func _build_once(level: LevelDefinition, snapshot: Dictionary, rng: RandomNumberGenerator) -> LessonPlan:
	var plan := LessonPlan.new()
	plan.level = level
	plan.base_difficulty = base_difficulty(snapshot)
	var size: int = lesson_size(level, snapshot)
	var mastery: float = snapshot.get("mastery", 0.0)
	var stages: Array = stage_sequence(size)
	var extra_pool: Array[ActivityTemplate] = []
	for stage: int in needy_stages(snapshot.get("stage_scores", {})):
		extra_pool.append_array(level.templates_for_stage(stage))
	var chosen: Array[ActivityTemplate] = []
	if not _assign(0, stages, level, snapshot, rng, chosen, true, extra_pool):
		chosen.clear()
		_assign(0, stages, level, snapshot, rng, chosen, false, extra_pool)
	for i in chosen.size():
		var difficulty: int = plan.base_difficulty
		if i == 0:
			difficulty = maxi(1, plan.base_difficulty - 1)  # calentamiento
		elif i >= int(chosen.size() * 2.0 / 3.0) and mastery >= 0.3:
			difficulty = mini(5, plan.base_difficulty + 1)  # subida suave al final
		plan.add_slot(chosen[i], chosen[i].clamp_difficulty(difficulty))
	return plan


static func _pool_for(stage: int, level: LevelDefinition, extra_pool: Array[ActivityTemplate]) -> Array[ActivityTemplate]:
	var pool: Array[ActivityTemplate] = extra_pool if stage == EXTRA else level.templates_for_stage(stage)
	return pool if not pool.is_empty() else level.templates


## Búsqueda con vuelta atrás. strict_view = no repetir vista seguida.
static func _assign(i: int, stages: Array, level: LevelDefinition, snapshot: Dictionary,
		rng: RandomNumberGenerator, chosen: Array[ActivityTemplate], strict_view: bool,
		extra_pool: Array[ActivityTemplate]) -> bool:
	if i >= stages.size():
		return true
	var previous: ActivityTemplate = chosen.back() if not chosen.is_empty() else null
	var pool: Array[ActivityTemplate] = _pool_for(stages[i], level, extra_pool)
	for template: ActivityTemplate in _ordered_candidates(pool, previous, chosen, snapshot, rng, strict_view):
		chosen.append(template)
		if _assign(i + 1, stages, level, snapshot, rng, chosen, strict_view, extra_pool):
			return true
		chosen.pop_back()
	return false


## Candidatos válidos ordenados por puntuación con azar ponderado
## (muestreo sin reemplazo de Efraimidis-Spirakis).
static func _ordered_candidates(pool: Array[ActivityTemplate], previous: ActivityTemplate,
		chosen: Array[ActivityTemplate], snapshot: Dictionary, rng: RandomNumberGenerator,
		strict_view: bool) -> Array[ActivityTemplate]:
	var last_lesson: Array = snapshot.get("last_templates", [])
	var recent: Array = snapshot.get("recent_templates", [])
	var stage_scores: Dictionary = snapshot.get("stage_scores", {})
	var keyed: Array = []
	for template: ActivityTemplate in pool:
		if previous != null and template.id == previous.id:
			continue  # nunca la misma plantilla seguida
		if strict_view and previous != null and template.view_type == previous.view_type:
			continue
		var score: float = 10.0
		if chosen.has(template):
			score -= 6.0
		if last_lesson.has(template.id):
			score -= 4.0
		if recent.has(template.id):
			score -= 2.0
		score += (1.0 - stage_scores.get(template.stage, 0.0)) * 3.0
		var key: float = pow(maxf(rng.randf(), 0.0001), 1.0 / maxf(score, 0.5))
		keyed.append([key, template])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var result: Array[ActivityTemplate] = []
	for pair: Array in keyed:
		result.append(pair[1])
	return result
