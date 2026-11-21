class_name LessonSession
extends RefCounted
## Ejecuta una lección: genera cada actividad al empezarla (con la dificultad
## adaptada), evalúa respuestas, da ayuda progresiva y registra el desempeño.
## No conoce la interfaz: todo se comunica con señales. La interfaz decide
## cuándo pasar a la siguiente actividad (next_activity()).
##
## Reglas: sin vidas ni puntos; los errores nunca restan; nunca se bloquea
## (tras agotar la ayuda se pasa a una actividad más sencilla); la ayuda
## nunca revela la respuesta.

signal activity_started(instance: ActivityInstance, index: int, total: int)
## Respuesta parcial o errónea (la actividad continúa).
signal feedback(card_index: int, correct: bool, line: DialogueLine)
signal hint_given(step: int, line: DialogueLine, removed_cards: Array[int], model_card: CardData)
signal activity_finished(result: Dictionary, line: DialogueLine)
signal lesson_finished(summary: Dictionary)

const PRAISE_FIRST_TRY: PackedStringArray = [
	"¡Muy bien! ¡Esa es!", "¡Genial, lo encontraste!", "¡Eso es! ¡Qué buen ojo tienes!", "¡Perfecto!",
]
const PRAISE_EFFORT: PackedStringArray = [
	"¡Lo pensaste muy bien y lo lograste!", "¡Seguiste intentando y lo conseguiste!",
	"¡Bravo! Practicar así es como se aprende.",
]
const PARTIAL: PackedStringArray = ["¡Muy bien, encontraste una! ¿Hay más?", "¡Eso es! Sigue buscando."]
const SORT_OK: PackedStringArray = ["¡Ahí va!", "¡Muy bien!", "¡Eso es!"]
const SKIP_LINE: String = "¡Vamos a practicarlo de otra forma!"
const WRONG_FALLBACK: String = "Casi. ¡Vuelve a intentarlo!"

var level: LevelDefinition
var plan: LessonPlan
var rng: RandomNumberGenerator
var adaptive := AdaptiveDifficulty.new()
## Firmas a evitar (historial reciente + las de esta lección).
var avoid_signatures := PackedStringArray()

var index: int = -1
var instance: ActivityInstance
var results: Array[Dictionary] = []
var finished: bool = false

var _ladder: HintLadder
var _errors: int = 0
var _found: Array[int] = []
var _removed: Array[int] = []
var _signatures: PackedStringArray = []
var _activity_done: bool = false


func _init(p_level: LevelDefinition, p_plan: LessonPlan, p_rng: RandomNumberGenerator,
		recent_signatures: PackedStringArray = PackedStringArray()) -> void:
	level = p_level
	plan = p_plan
	rng = p_rng
	avoid_signatures = recent_signatures.duplicate()


func total() -> int:
	return plan.size()


## Empieza la siguiente actividad (o termina la lección).
func next_activity() -> void:
	if finished:
		return
	index += 1
	if index >= plan.size():
		_finish()
		return
	var slot: Dictionary = plan.slots[index]
	var template: ActivityTemplate = slot["template"]
	instance = template.generate(rng, adaptive.adjust(slot["difficulty"]), level.content, avoid_signatures)
	avoid_signatures.append(instance.signature)
	_signatures.append(instance.signature)
	_ladder = HintLadder.new()
	_errors = 0
	_found.clear()
	_removed.clear()
	_activity_done = false
	activity_started.emit(instance, index, plan.size())


## Tarjetas ya encontradas (SEARCH/SORT) o retiradas por la pista visual.
func is_card_settled(card_index: int) -> bool:
	return _found.has(card_index) or _removed.has(card_index)


## Respuesta en CHOICE o SEARCH.
func answer(card_index: int) -> void:
	if _activity_done or is_card_settled(card_index):
		return
	if instance.is_correct(card_index):
		if instance.view_type() == ActivityTemplate.ViewType.SEARCH:
			_found.append(card_index)
			if _found.size() < instance.correct.size():
				feedback.emit(card_index, true, _line(PARTIAL, DialogueLine.Kind.PRAISE, Moki.Mood.HAPPY))
				return
		_complete(false)
		return
	_wrong(card_index)


## Respuesta en SORT: colocar una tarjeta en una cesta.
func place(card_index: int, bin_index: int) -> void:
	if _activity_done or is_card_settled(card_index):
		return
	if instance.cards[card_index].category == bin_index:
		_found.append(card_index)
		if _found.size() < instance.cards.size():
			feedback.emit(card_index, true, _line(SORT_OK, DialogueLine.Kind.PRAISE, Moki.Mood.HAPPY))
			return
		_complete(false)
		return
	_wrong(card_index)


## Ayuda pedida por el niño.
func request_help() -> void:
	if _activity_done:
		return
	_give_hint(_ladder.on_help())


func hints_used() -> int:
	return _ladder.hints_given if _ladder != null else 0


func _wrong(card_index: int) -> void:
	_errors += 1
	var step: int = _ladder.on_error()
	if step == HintLadder.SKIP:
		_complete(true)
		return
	if step < 0:
		feedback.emit(card_index, false, DialogueLine.make(WRONG_FALLBACK, DialogueLine.Kind.ENCOURAGE, Moki.Mood.NEUTRAL))
		return
	feedback.emit(card_index, false, null)
	_give_hint(step)


func _give_hint(step: int) -> void:
	var line: DialogueLine = instance.template.hint_line(step, instance)
	var removed: Array[int] = []
	var model: CardData = null
	if step == ActivityTemplate.HintStep.VISUAL:
		model = instance.model_card
		if _removed.is_empty() and instance.view_type() != ActivityTemplate.ViewType.SORT:
			for card_index: int in instance.visual_hint_removals():
				if not _found.has(card_index):
					removed.append(card_index)
			_removed.append_array(removed)
	hint_given.emit(step, line, removed, model)


func _complete(skipped: bool) -> void:
	_activity_done = true
	var template: ActivityTemplate = instance.template
	var result := {
		"template": String(template.id),
		"stage": template.stage,
		"difficulty": instance.difficulty,
		"errors": _errors,
		"attempts": _errors + 1,
		"hints": _ladder.hints_given,
		"first_try": _errors == 0 and _ladder.hints_given == 0 and not skipped,
		"skipped": skipped,
		"signature": instance.signature,
	}
	results.append(result)
	var action: AdaptiveDifficulty.Action = adaptive.record(result)
	if action == AdaptiveDifficulty.Action.LOWER:
		_insert_reinforcement(template)
	var line: DialogueLine
	if skipped:
		line = DialogueLine.make(SKIP_LINE, DialogueLine.Kind.ENCOURAGE, Moki.Mood.HAPPY)
	elif result["first_try"]:
		line = _line(PRAISE_FIRST_TRY, DialogueLine.Kind.PRAISE, Moki.Mood.LAUGHING)
	else:
		line = _line(PRAISE_EFFORT, DialogueLine.Kind.PRAISE, Moki.Mood.HAPPY)
	if not skipped and not level.reinforce_lines.is_empty():
		line.text += " " + level.reinforce_lines[rng.randi_range(0, level.reinforce_lines.size() - 1)]
	activity_finished.emit(result, line)


## Refuerzo: otra actividad de la misma etapa, más sencilla y en otro contexto
## (otra plantilla si existe), justo después. Respeta el tamaño máximo.
func _insert_reinforcement(template: ActivityTemplate) -> void:
	if plan.size() >= level.lesson_max:
		return
	var next: ActivityTemplate = plan.slots[index + 1]["template"] if index + 1 < plan.size() else null
	var used: Array = plan.template_ids()
	# Preferencia: misma etapa > cualquier etapa; nunca la misma plantilla que la
	# actual o la siguiente; distinta vista si es posible; mejor si aún no se usó
	# en esta lección. Entre las válidas se elige al azar (con el RNG de la lección).
	var pools: Array = [level.templates_for_stage(template.stage), level.templates]
	for strict in [true, false]:
		for pool: Array in pools:
			var options: Array[ActivityTemplate] = []
			for candidate: ActivityTemplate in pool:
				if candidate.id == template.id or (next != null and candidate.id == next.id):
					continue
				if strict and (candidate.view_type == template.view_type
						or (next != null and candidate.view_type == next.view_type)):
					continue
				options.append(candidate)
			var fresh: Array[ActivityTemplate] = options.filter(func(c: ActivityTemplate) -> bool: return not used.has(c.id))
			var pick_from: Array[ActivityTemplate] = fresh if not fresh.is_empty() else options
			if not pick_from.is_empty():
				var chosen: ActivityTemplate = pick_from[rng.randi_range(0, pick_from.size() - 1)]
				plan.insert_slot(index + 1, chosen, chosen.clamp_difficulty(instance.difficulty - 1))
				return


func _finish() -> void:
	finished = true
	var ids: Array = []
	for result: Dictionary in results:
		ids.append(result["template"])
	var line: DialogueLine = level.outro[rng.randi_range(0, level.outro.size() - 1)] if not level.outro.is_empty() else null
	lesson_finished.emit({
		"level_id": String(level.id),
		"templates": ids,
		"signatures": Array(_signatures),
		"size": results.size(),
		"results": results,
		"base_difficulty": plan.base_difficulty,
		"line": line,
	})


func _line(options: PackedStringArray, kind: DialogueLine.Kind, mood: Moki.Mood) -> DialogueLine:
	return DialogueLine.make(options[rng.randi_range(0, options.size() - 1)], kind, mood)
