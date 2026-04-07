extends Node

signal relation_changed(npc_id: StringName, old_value: int, new_value: int)
signal threshold_reached(npc_id: StringName, threshold: int)

const RELATION_MAX: int = 100
const DECAY_COOLDOWN: int = 5
const IMMUNITY_DAYS: int = 7
const DECAY_AMOUNT: int = -2
const THRESHOLDS: Array[int] = [20, 40, 60, 80]

## 好感度 { npc_id: int }
var relations: Dictionary = {}
## 已触发的阈值 { npc_id: Array[int] }
var triggered_thresholds: Dictionary = {}
## 未互动天数 { npc_id: int }
var no_interact_days: Dictionary = {}
## 注册日期 { npc_id: int }
var register_day: Dictionary = {}


func reset() -> void:
	relations.clear()
	triggered_thresholds.clear()
	no_interact_days.clear()
	register_day.clear()


func register_npc(npc_id: StringName, initial_value: int = 15) -> void:
	relations[npc_id] = clampi(initial_value, 0, RELATION_MAX)
	triggered_thresholds[npc_id] = []
	no_interact_days[npc_id] = 0
	var game_mgr: Node = get_node("/root/GameManager")
	register_day[npc_id] = game_mgr.current_day


func get_relation(npc_id: StringName) -> int:
	return relations.get(npc_id, 0)


func modify_relation(npc_id: StringName, delta: int) -> void:
	if npc_id not in relations:
		return
	var old: int = relations[npc_id]
	relations[npc_id] = clampi(old + delta, 0, RELATION_MAX)
	if delta > 0:
		no_interact_days[npc_id] = 0
	if relations[npc_id] != old:
		relation_changed.emit(npc_id, old, relations[npc_id])
	_check_thresholds(npc_id)


func _check_thresholds(npc_id: StringName) -> void:
	var val: int = relations[npc_id]
	for t: int in THRESHOLDS:
		if val >= t and t not in triggered_thresholds[npc_id]:
			triggered_thresholds[npc_id].append(t)
			threshold_reached.emit(npc_id, t)


func process_daily_decay() -> void:
	var game_mgr: Node = get_node("/root/GameManager")
	var today: int = game_mgr.current_day
	for npc_id: StringName in no_interact_days:
		# 7天豁免期
		if npc_id in register_day and (today - register_day[npc_id]) < IMMUNITY_DAYS:
			continue
		no_interact_days[npc_id] += 1
		if no_interact_days[npc_id] >= DECAY_COOLDOWN:
			modify_relation(npc_id, DECAY_AMOUNT)
			no_interact_days[npc_id] = 0


func mark_interacted(npc_id: StringName) -> void:
	if npc_id in no_interact_days:
		no_interact_days[npc_id] = 0
