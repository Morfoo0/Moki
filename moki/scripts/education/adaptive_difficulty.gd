class_name AdaptiveDifficulty
extends RefCounted
## Ajuste suave de la dificultad DENTRO de una lección.
## - 2 aciertos seguidos al primer intento y sin pistas → +1 (máximo +1).
## - Muchas pistas, muchos errores o actividad saltada → −1 (mínimo −2) y se
##   pide un refuerzo del concepto.
## Nunca hay saltos bruscos: un paso cada vez.

enum Action { NONE, RAISE, LOWER }

const MAX_OFFSET: int = 1
const MIN_OFFSET: int = -2
const STRUGGLE_HINTS: int = 2
const STRUGGLE_ERRORS: int = 3

var offset: int = 0
var _streak: int = 0


func adjust(planned: int) -> int:
	return clampi(planned + offset, 1, 5)


func record(result: Dictionary) -> Action:
	var hints: int = result.get("hints", 0)
	var errors: int = result.get("errors", 0)
	if result.get("first_try", false) and hints == 0:
		_streak += 1
		if _streak >= 2 and offset < MAX_OFFSET:
			offset += 1
			_streak = 0
			return Action.RAISE
		return Action.NONE
	_streak = 0
	if hints >= STRUGGLE_HINTS or errors >= STRUGGLE_ERRORS or result.get("skipped", false):
		offset = maxi(offset - 1, MIN_OFFSET)
		return Action.LOWER
	return Action.NONE
