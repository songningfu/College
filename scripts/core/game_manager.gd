extends Node

signal phase_changed(phase: Phase)
signal day_changed(day: int)

enum Phase {
	TITLE,
	SCHEDULING,
	EXECUTING,
	EVENT,
	DAY_SUMMARY,
	DEMO_END
}

const PERIODS: Array[StringName] = [&"morning", &"afternoon", &"evening"]
const MAX_DAY: int = 21

var current_phase: Phase = Phase.TITLE
var current_day: int = 1
var current_period_index: int = 0

## Day 2 不再受限，移除 limited_days
var limited_days: Array[int] = []


func _ready() -> void:
	pass


func reset() -> void:
	current_phase = Phase.TITLE
	current_day = 1
	current_period_index = 0
	limited_days.clear()

	var attr_sys: Node = get_node_or_null("/root/AttributeSystem")
	if attr_sys and attr_sys.has_method("reset"):
		attr_sys.reset()

	var rel_sys: Node = get_node_or_null("/root/RelationshipSystem")
	if rel_sys and rel_sys.has_method("reset"):
		rel_sys.reset()

	var card_sys: Node = get_node_or_null("/root/CardSystem")
	if card_sys and card_sys.has_method("reset"):
		card_sys.reset()

	var event_sys: Node = get_node_or_null("/root/EventSystem")
	if event_sys and event_sys.has_method("reset"):
		event_sys.reset()


func set_phase(phase: Phase) -> void:
	current_phase = phase
	phase_changed.emit(phase)


func get_current_period() -> StringName:
	if current_period_index < 0 or current_period_index >= PERIODS.size():
		return &"morning"
	return PERIODS[current_period_index]


func advance_period() -> bool:
	if current_period_index < PERIODS.size() - 1:
		current_period_index += 1
		return true
	return false


func advance_day() -> void:
	current_day += 1
	current_period_index = 0
	day_changed.emit(current_day)

	if current_day > MAX_DAY:
		set_phase(Phase.DEMO_END)


func is_period_locked() -> bool:
	return current_day in limited_days


func is_military_training_day() -> bool:
	return current_day >= 3 and current_day <= 9
