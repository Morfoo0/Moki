class_name HintLadder
extends RefCounted
## Ayuda progresiva de una actividad:
##   1 reformular → 2 pista verbal → 3 acertijo/comparación → 4 pista visual.
## Cada error o cada petición de ayuda sube un escalón. Después del último
## escalón, si el niño sigue fallando EXTRA_TRIES veces, se sugiere pasar a
## otra actividad más sencilla (nunca se bloquea ni se revela la respuesta).

const SKIP: int = -1
const EXTRA_TRIES: int = 2

var hints_given: int = 0
var _extra_errors: int = 0


## Tras un error: el escalón de ayuda que toca, o SKIP.
func on_error() -> int:
	if hints_given < ActivityTemplate.HintStep.size():
		return _give()
	_extra_errors += 1
	if _extra_errors >= EXTRA_TRIES:
		return SKIP
	return ActivityTemplate.HintStep.VISUAL  # recordar la pista visual


## Ayuda pedida por el niño: el siguiente escalón (o repetir el último).
func on_help() -> int:
	if hints_given < ActivityTemplate.HintStep.size():
		return _give()
	return ActivityTemplate.HintStep.VISUAL


func _give() -> int:
	var step: int = hints_given
	hints_given += 1
	return step
