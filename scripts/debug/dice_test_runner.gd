extends Node

const OUTPUT_PATH := "res://debug_dice_output.json"

func _ready() -> void:
	randomize()
	GameManager.reset_run()
	DayManager.start_day()
	var cards: Array[Dictionary] = DayManager.get_current_cards()
	var found := false
	for card in cards:
		if String(card.get("id", "")) == "attend_class":
			found = true
			break
	if not found:
		_write_output({"error": "attend_class not available"})
		get_tree().quit(1)
		return
	DayManager.select_card("attend_class")
	DayManager.resolve_event_choice(0)
	var roll: Dictionary = GameManager.last_roll
	var summary := {
		"card": "attend_class",
		"event": "class_roll_call",
		"stat": String(roll.get("stat", "")),
		"die1": int(roll.get("die1", 0)),
		"die2": int(roll.get("die2", 0)),
		"modifier": int(roll.get("modifier", 0)),
		"total": int(roll.get("total", 0)),
		"threshold": int(roll.get("threshold", 0)),
		"success": bool(roll.get("success", false)),
		"学力": int(GameManager.stats.get("学力", 0)),
		"心理": int(GameManager.stats.get("心理", 0)),
		"current_phase": GameManager.current_phase,
		"current_period": GameManager.current_period(),
		"period_points_remaining": GameManager.period_points_remaining,
		"daily_points_remaining": GameManager.daily_points_remaining
	}
	_write_output(summary)
	print("AUTO_TEST_DICE_RESULT: %s" % JSON.stringify(summary))
	get_tree().quit()

func _write_output(payload: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))
