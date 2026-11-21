extends Node
## Autoload "Narrator": lee en voz alta las frases de Chibbi.
##
## Orden de preferencia por frase:
##   1. Audio grabado (DialogueLine.voice_key → res://resources/education/voice/<clave>.ogg/.wav)
##   2. Voz sintética del sistema (TTS) en español, si existe.
##   3. Nada (solo texto), sin errores.
## Al decir una frase nueva se corta la anterior.

signal speaking_started(text: String)

const VOICE_DIR: String = "res://resources/education/voice/"
const LANGUAGE: String = "es"

## Se puede desactivar (p. ej. ajustes de padres).
## DESACTIVADO TEMPORALMENTE: cada frase nueva corta la anterior (speak() hace
## stop()), así que la voz se oía entrecortada en las lecciones. Para reactivarla
## basta con poner true; el botón "Oír" vuelve a aparecer solo.
## Pendiente: cola de frases que espere a que termine cada una.
var enabled: bool = false
## Velocidad (0.5 - 2.0) y volumen (0 - 100) de la voz sintética.
var rate: float = 0.9
var volume: int = 90

var _voice_id: String = ""
var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	if ProjectSettings.get_setting("audio/general/text_to_speech", false) and DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(LANGUAGE)
		if not voices.is_empty():
			_voice_id = voices[0]


## True si hay alguna forma de voz disponible (oculta el botón "escuchar" si no).
func can_speak() -> bool:
	return enabled and (not _voice_id.is_empty() or DirAccess.dir_exists_absolute(VOICE_DIR))


func has_tts() -> bool:
	return not _voice_id.is_empty()


func speak(line: DialogueLine) -> void:
	if line == null:
		return
	stop()
	if not enabled:
		return
	var stream: AudioStream = _recorded(line.voice_key)
	if stream != null:
		_player.stream = stream
		_player.play()
	elif not _voice_id.is_empty():
		DisplayServer.tts_speak(line.get_spoken_text(), _voice_id, volume, 1.0, rate)
	speaking_started.emit(line.get_spoken_text())


func stop() -> void:
	if _player != null and _player.playing:
		_player.stop()
	if not _voice_id.is_empty() and DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()


func _recorded(voice_key: StringName) -> AudioStream:
	if voice_key.is_empty():
		return null
	for extension: String in [".ogg", ".wav", ".mp3"]:
		var path: String = VOICE_DIR + String(voice_key) + extension
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null
