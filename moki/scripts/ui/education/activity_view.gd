class_name ActivityView
extends Control
## Base de las vistas de actividad (CHOICE, SEARCH, SORT). Solo presenta y
## recoge la interacción; la lógica está en LessonSession.
## Para un tipo de actividad nuevo: crear una subclase y registrarla en create().

signal card_pressed(card_index: int)
## SORT: tarjeta colocada en una cesta.
signal card_placed(card_index: int, bin_index: int)

var instance: ActivityInstance
var bank: ContentBank
var cards: Array[ActivityCard] = []


static func create(view_type: ActivityTemplate.ViewType) -> ActivityView:
	match view_type:
		ActivityTemplate.ViewType.SEARCH:
			return SearchView.new()
		ActivityTemplate.ViewType.SORT:
			return SortView.new()
	return ChoiceView.new()


func setup(p_instance: ActivityInstance, p_bank: ContentBank) -> void:
	instance = p_instance
	bank = p_bank
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


## Subclases: construir la presentación.
func _build() -> void:
	pass


func make_card(index: int, side: float) -> ActivityCard:
	var card := ActivityCard.new()
	card.setup(index, instance.cards[index], bank, side)
	card.pressed.connect(_on_card_pressed)
	cards.append(card)
	return card


func get_card(index: int) -> ActivityCard:
	for card: ActivityCard in cards:
		if card.card_index == index:
			return card
	return null


func mark_correct(index: int) -> void:
	var card: ActivityCard = get_card(index)
	if card != null:
		card.mark_correct()
		card.locked = true


func mark_wrong(index: int) -> void:
	var card: ActivityCard = get_card(index)
	if card != null:
		card.shake()


func retire_cards(indices: Array[int]) -> void:
	for index: int in indices:
		var card: ActivityCard = get_card(index)
		if card != null:
			card.retire()


func set_locked(value: bool) -> void:
	for card: ActivityCard in cards:
		if value:
			card.locked = true


func _on_card_pressed(index: int) -> void:
	card_pressed.emit(index)


## Alto disponible para la actividad (entre el guía y los botones inferiores).
const AREA_HEIGHT: float = 370.0


## Contenedor centrado reutilizable.
func centered_box(vertical: bool = true) -> BoxContainer:
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 28)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)
	return box
