class_name LessonScreen
extends Control
## Pantalla de lección: une LessonSession (lógica), MokiGuide (guía con
## bocadillo) y las vistas de actividad. Flujo:
##   introducción de Moki → actividades (con ayuda progresiva) → celebración.
## Registra el desempeño en EducationProgress. No toca el cuidado de Moki.

## Nada avanza solo: el niño pulsa "Seguir" cuando ha leído/escuchado a Moki.
## Retardo antes de mostrar "Seguir" (evita que un doble toque salte la frase).
@export var continue_unlock_delay: float = 0.6

var level: LevelDefinition
var world: WorldDefinition
var session: LessonSession

var _view: ActivityView
var _rng := RandomNumberGenerator.new()
var _continue_requested: bool = false
var _last_pressed: int = -1
var _pulse: Tween

@onready var _guide: MokiGuide = %MokiGuide
@onready var _title: Label = %Title
@onready var _progress: LessonProgressBar = %Progress
@onready var _host: Control = %ActivityHost
@onready var _continue: Button = %ContinueButton
@onready var _exit: Button = %ExitButton
@onready var _end_panel: Control = %EndPanel
@onready var _again: Button = %AgainButton
@onready var _map: Button = %MapButton


func _ready() -> void:
	var params: Dictionary = SceneManager.get_params()
	var catalog: EducationCatalog = EducationProgress.catalog
	level = catalog.get_level(StringName(params.get("level_id", "letters_a")))
	world = catalog.world_of(level.id)
	var level_number: int = world.levels.find(level) + 1
	_title.text = "%s · Nivel %d: %s" % [world.title, level_number, level.title]
	_end_panel.visible = false
	_continue.pressed.connect(func() -> void: _continue_requested = true)
	_continue.visible = false
	_exit.pressed.connect(_go_to_map)
	_map.pressed.connect(_go_to_map)
	_again.pressed.connect(func() -> void: SceneManager.change_scene(ScenePaths.LESSON, {"level_id": level.id}))
	_guide.help_pressed.connect(_on_help)
	_guide.set_help_enabled(false)

	_rng.randomize()
	var plan: LessonPlan = LessonBuilder.build(level, EducationProgress.get_snapshot(level), _rng)
	session = LessonSession.new(level, plan, _rng, EducationProgress.get_recent_signatures(level.id))
	session.activity_started.connect(_on_activity_started)
	session.feedback.connect(_on_feedback)
	session.hint_given.connect(_on_hint)
	session.activity_finished.connect(_on_activity_finished)
	session.lesson_finished.connect(_on_lesson_finished)
	_progress.set_progress(0, plan.size())
	_run_intro()


func _run_intro() -> void:
	for line: DialogueLine in level.intro:
		_guide.say(line)
		await _wait_for_continue()
		if not is_inside_tree():
			return
	_guide.set_help_enabled(true)
	session.next_activity()


## Muestra "Seguir" (tras un pequeño retardo) y espera a que el niño lo pulse.
## Nunca avanza por tiempo.
func _wait_for_continue() -> void:
	_continue_requested = false
	_continue.visible = false
	await get_tree().create_timer(continue_unlock_delay).timeout
	if not is_inside_tree():
		return
	_continue_requested = false
	_show_continue()
	while not _continue_requested and is_inside_tree():
		await get_tree().process_frame
	_hide_continue()


func _show_continue() -> void:
	_continue.visible = true
	_continue.pivot_offset = _continue.size / 2.0
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_pulse = create_tween().set_loops()
	_pulse.tween_property(_continue, "scale", Vector2.ONE * 1.08, 0.6).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(_continue, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)


func _hide_continue() -> void:
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_continue.scale = Vector2.ONE
	_continue.visible = false


# --- Actividades ----------------------------------------------------------------

func _on_activity_started(instance: ActivityInstance, index: int, total: int) -> void:
	if _view != null:
		_view.queue_free()
	_guide.clear_model()
	_guide.set_help_enabled(true)
	_progress.set_progress(index, total)
	_view = ActivityView.create(instance.view_type())
	_host.add_child(_view)
	_view.setup(instance, level.content)
	_view.card_pressed.connect(_on_card_pressed)
	_view.card_placed.connect(func(card_index: int, bin_index: int) -> void:
		_last_pressed = card_index
		session.place(card_index, bin_index))
	_guide.say(instance.instruction)


func _on_card_pressed(card_index: int) -> void:
	if session.instance.view_type() == ActivityTemplate.ViewType.SORT:
		return  # en clasificar, tocar solo selecciona; se responde al tocar la cesta
	_last_pressed = card_index
	session.answer(card_index)


func _on_help() -> void:
	session.request_help()


func _on_feedback(card_index: int, correct: bool, line: DialogueLine) -> void:
	if correct:
		if _view is SortView:
			(_view as SortView).mark_placed(card_index, session.instance.cards[card_index].category)
		else:
			_view.mark_correct(card_index)
	else:
		_view.mark_wrong(card_index)
	if line != null:
		_guide.say(line)


func _on_hint(step: int, line: DialogueLine, removed: Array[int], model: CardData) -> void:
	_guide.say(line)
	if model != null:
		_guide.show_model(model, level.content)
	_view.retire_cards(removed)


func _on_activity_finished(result: Dictionary, line: DialogueLine) -> void:
	_guide.set_help_enabled(false)
	if not result["skipped"]:
		var instance: ActivityInstance = session.instance
		match instance.view_type():
			ActivityTemplate.ViewType.CHOICE:
				_view.mark_correct(_last_pressed)
			ActivityTemplate.ViewType.SEARCH:
				for card_index: int in instance.correct:
					_view.mark_correct(card_index)
			ActivityTemplate.ViewType.SORT:
				# La última tarjeta colocada (sin feedback propio) va a su cesta.
				(_view as SortView).mark_placed(_last_pressed, instance.cards[_last_pressed].category)
	_view.set_locked(true)
	_guide.say(line)
	EducationProgress.record_activity(level, result)
	_progress.set_progress(session.index + 1, session.total())
	await _wait_for_continue()
	if is_inside_tree():
		session.next_activity()


func _on_lesson_finished(summary: Dictionary) -> void:
	EducationProgress.record_lesson(level, summary)
	if _view != null:
		_view.queue_free()
		_view = null
	_progress.set_progress(session.total(), session.total())
	_guide.clear_model()
	var line: DialogueLine = summary.get("line")
	if line != null:
		_guide.say(line)
	_end_panel.visible = true


func _go_to_map() -> void:
	Narrator.stop()
	SceneManager.change_scene(ScenePaths.LEVEL_MAP, {"world_id": world.id})
