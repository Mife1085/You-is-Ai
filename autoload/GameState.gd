extends Node
## Глобальное состояние: уровень, попытка, очки, история попыток, сохранение.

const SAVE_PATH := "user://save.json"

var current_level: int = 1
var attempt: int = 1
var score: int = 0
var best_score: int = 0

## Кадры текущей попытки: [{ "t": float, "monitors": PackedFloat32Array, "buttons": PackedByteArray }]
var attempt_frames: Array = []

## Завершённые попытки: [{ "level":int, "attempt":int, "score":int, "won":bool, "frames":Array }]
var attempts: Array = []

func _ready() -> void:
	load_game()

func reset_attempt_frames() -> void:
	attempt_frames.clear()

func push_frame(t: float, monitor_values: Array, button_states: Array) -> void:
	attempt_frames.append({
		"t": t,
		"monitors": monitor_values.duplicate(),
		"buttons": button_states.duplicate(),
	})

func commit_attempt(won: bool) -> void:
	attempts.append({
		"level": current_level,
		"attempt": attempt,
		"score": score,
		"won": won,
		"frames": attempt_frames.duplicate(true),
	})
	if score > best_score:
		best_score = score
	attempt += 1
	attempt_frames.clear()
	save_game()

func save_game() -> void:
	var data := {
		"current_level": current_level,
		"attempt": attempt,
		"score": score,
		"best_score": best_score,
		"attempts_count": attempts.size(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	current_level = int(parsed.get("current_level", 1))
	attempt     = int(parsed.get("attempt", 1))
	best_score  = int(parsed.get("best_score", 0))
	print("[GameState] Загружено: уровень %d, попытка %d, рекорд %d" % [current_level, attempt, best_score])
