class_name SearchView
extends ActivityView
## Encontrar todas las tarjetas objetivo: cuadrícula o letras de una palabra.


func mark_found(index: int) -> void:
	mark_correct(index)


func _build() -> void:
	var column: BoxContainer = centered_box(true)
	var count: int = instance.cards.size()
	var is_word: bool = instance.signature.begins_with("WORD|")
	var grid := GridContainer.new()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", 14 if is_word else 18)
	grid.add_theme_constant_override("v_separation", 18)
	var side: float
	if is_word:
		grid.columns = count
		side = clampf(1100.0 / count - 14.0, 90.0, 140.0)
	else:
		grid.columns = 3 if count in [6, 9] else 4
		var rows: int = ceili(float(count) / grid.columns)
		side = clampf(AREA_HEIGHT / rows - 18.0, 70.0, 140.0)
	column.add_child(grid)
	for i in count:
		grid.add_child(make_card(i, side))
