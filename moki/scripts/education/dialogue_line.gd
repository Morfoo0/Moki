@tool
class_name DialogueLine
extends Resource
## Una frase de Chibbi. Preparada para narración: "spoken" permite un texto
## distinto para la voz (p. ej. "aaa" escrito como se pronuncia) y "voice_key"
## identificará un audio grabado en el futuro.

enum Kind { INSTRUCTION, EXPLANATION, TIP, HINT, RIDDLE, PRAISE, ENCOURAGE }

@export_multiline var text: String = ""
## Texto para la voz (vacío = se lee "text").
@export var spoken: String = ""
@export var kind: Kind = Kind.INSTRUCTION
## Expresión de Chibbi mientras dice la frase (Chibbi.Mood). Nunca ANGRY.
@export var mood: Chibbi.Mood = Chibbi.Mood.HAPPY
## Clave de un audio grabado (futuro). Vacío = narración sintética.
@export var voice_key: StringName = &""


static func make(line_text: String, line_kind: Kind = Kind.INSTRUCTION, line_mood: Chibbi.Mood = Chibbi.Mood.HAPPY,
		line_spoken: String = "") -> DialogueLine:
	var line := DialogueLine.new()
	line.text = line_text
	line.kind = line_kind
	line.mood = line_mood
	line.spoken = line_spoken
	return line


func get_spoken_text() -> String:
	return spoken if not spoken.is_empty() else text
