extends Node

signal event_queue_updated()
signal event_triggered(event: RefCounted)

const RANDOM_EVENT_CHANCE: float = 0.3

## 所有事件 { event_id: GameEvent }
var all_events: Dictionary = {}
## 今日事件队列
var today_queue: Array = []


class GameEvent extends RefCounted:
	var id: StringName
	var display_name: String
	var event_type: StringName  # &"fixed", &"conditional", &"random"
	var trigger_day: int = -1
	var trigger_period: StringName = &"any"
	var conditions: Array = []
	var priority: int = 50
	var related_npcs: Array[StringName] = []
	var dialog_path: String = ""
	var is_consumed: bool = false
	var attach_to: StringName = &""
	var valid_until_day: int = -1
	var deferred: bool = false
	## 固定好感效果 { npc_id: int }
	var relation_effects: Dictionary = {}
	## 属性效果 { attr_id: int }
	var attribute_effects: Dictionary = {}
	## 资源效果 { res_id: int }
	var resource_effects: Dictionary = {}
	## 选项列表（简化版，用于测试）
	var choices: Array[Dictionary] = []


func _ready() -> void:
	_init_events()


func reset() -> void:
	today_queue.clear()
	for eid: StringName in all_events:
		var ev: GameEvent = all_events[eid]
		ev.is_consumed = false
		ev.deferred = false


func _init_events() -> void:
	all_events.clear()

	# === Day 1: 报到日（纯剧情） ===
	_add_fixed_event(&"day1_arrival", "报到日", 1, &"morning", 95,
		[&"roommates"], {}, {}, {&"mood": 1})

	# === 军训期固定事件 ===
	_add_fixed_event(&"day3_first_assembly", "第一次集合", 3, &"morning", 90,
		[&"shen_qinghe"], {&"shen_qinghe": 1}, {}, {})

	# === 沈清禾递水（条件事件，军训期） ===
	var shen_water := _create_event(&"shen_water", "沈清禾递水", &"conditional", &"afternoon")
	shen_water.conditions = [
		{"type": "day_range", "min": 5, "max": 9},
		{"type": "relation", "npc": &"shen_qinghe", "op": ">=", "value": 10}
	]
	shen_water.priority = 60
	shen_water.related_npcs = [&"shen_qinghe"]
	shen_water.relation_effects = {&"shen_qinghe": 3}
	shen_water.resource_effects = {&"mood": 1}
	shen_water.valid_until_day = 9
	all_events[shen_water.id] = shen_water

	# === Day 9: 军训结束 ===
	_add_fixed_event(&"day9_military_end", "军训结束", 9, &"evening", 90,
		[&"shen_qinghe"], {&"shen_qinghe": 2}, {&"physique": 1}, {&"mood": 2})

	# === Day 10: 正式开学 ===
	_add_fixed_event(&"day10_semester_start", "正式开学", 10, &"morning", 95,
		[], {}, {}, {&"mood": 1})

	# === Day 14: 第一次小组作业（顾遥线关键） ===
	_add_fixed_event(&"day14_group_work", "第一次小组作业", 14, &"afternoon", 90,
		[&"gu_yao"], {&"gu_yao": 8}, {&"knowledge": 1}, {})

	# === Day 16: 社团聚餐 ===
	_add_fixed_event(&"day16_club_dinner", "社团聚餐", 16, &"evening", 70,
		[&"gu_yao"], {&"gu_yao": 5}, {&"eloquence": 1}, {&"money": -30})

	# === Day 18: 聚餐 ===
	_add_fixed_event(&"day18_dinner", "班级聚餐", 18, &"evening", 85,
		[&"gu_yao", &"shen_qinghe"], {&"gu_yao": 5}, {}, {&"money": -40, &"mood": 2})

	# === 散场后同行（条件事件，绑定day18_dinner） ===
	var walk := _create_event(&"gu_yao_walk_together", "散场后同行", &"conditional", &"evening")
	walk.conditions = [
		{"type": "relation", "npc": &"gu_yao", "op": ">=", "value": 50}
	]
	walk.priority = 75
	walk.related_npcs = [&"gu_yao"]
	walk.relation_effects = {&"gu_yao": 5}
	walk.resource_effects = {&"mood": 1}
	walk.attach_to = &"day18_dinner"
	walk.valid_until_day = 19
	all_events[walk.id] = walk

	# === 聊天窗口亮到深夜（条件事件） ===
	var late_chat := _create_event(&"gu_yao_late_chat", "聊天窗口亮到深夜", &"conditional", &"evening")
	late_chat.conditions = [
		{"type": "day_range", "min": 19, "max": 20},
		{"type": "relation", "npc": &"gu_yao", "op": ">=", "value": 60}
	]
	late_chat.priority = 70
	late_chat.related_npcs = [&"gu_yao"]
	late_chat.relation_effects = {&"gu_yao": 8}
	late_chat.resource_effects = {&"mood": 2}
	late_chat.valid_until_day = 20
	all_events[late_chat.id] = late_chat

	# === Day 20: 周末约会检查点 ===
	_add_fixed_event(&"day20_weekend", "周末", 20, &"morning", 60,
		[&"gu_yao"], {}, {}, {&"mood": 1})

	# === Day 21: Demo结尾 ===
	_add_fixed_event(&"day21_ending", "学期片段结束", 21, &"evening", 95,
		[], {}, {}, {})

	# === 随机事件：班群热闹 ===
	var class_chat := _create_event(&"random_class_chat", "班群突然热闹起来", &"random", &"evening")
	class_chat.conditions = [{"type": "day_range", "min": 3, "max": 21}]
	class_chat.priority = 30
	class_chat.resource_effects = {&"mood": 1}
	all_events[class_chat.id] = class_chat

	# === 随机事件：食堂偶遇 ===
	var canteen_meet := _create_event(&"random_canteen_meet", "食堂偶遇", &"random", &"any")
	canteen_meet.conditions = [{"type": "day_range", "min": 10, "max": 21}]
	canteen_meet.priority = 35
	canteen_meet.related_npcs = [&"gu_yao"]
	canteen_meet.relation_effects = {&"gu_yao": 2}
	all_events[canteen_meet.id] = canteen_meet


func _create_event(id: StringName, display_name: String, event_type: StringName, period: StringName) -> GameEvent:
	var ev := GameEvent.new()
	ev.id = id
	ev.display_name = display_name
	ev.event_type = event_type
	ev.trigger_period = period
	return ev


func _add_fixed_event(id: StringName, display_name: String, day: int, period: StringName,
		priority: int, npcs: Array, rel_fx: Dictionary, attr_fx: Dictionary, res_fx: Dictionary) -> void:
	var ev := _create_event(id, display_name, &"fixed", period)
	ev.trigger_day = day
	ev.priority = priority
	for n in npcs:
		ev.related_npcs.append(n)
	ev.relation_effects = rel_fx
	ev.attribute_effects = attr_fx
	ev.resource_effects = res_fx
	all_events[id] = ev


func build_daily_queue(day: int, attr_sys: Node, rel_sys: Node) -> void:
	today_queue.clear()

	# 收集今日固定事件ID，用于 attach_to 检查
	var today_fixed_ids: Array[StringName] = []
	for eid: StringName in all_events:
		var ev: GameEvent = all_events[eid]
		if ev.event_type == &"fixed" and ev.trigger_day == day and not ev.is_consumed:
			today_fixed_ids.append(eid)

	for eid: StringName in all_events:
		var ev: GameEvent = all_events[eid]
		if ev.is_consumed:
			continue
		# 有效期检查
		if ev.valid_until_day > 0 and day > ev.valid_until_day:
			ev.is_consumed = true
			continue

		match ev.event_type:
			&"fixed":
				if ev.trigger_day == day:
					today_queue.append(ev)
			&"conditional":
				if _check_conditions(ev.conditions, day, attr_sys, rel_sys):
					if ev.attach_to != &"" and ev.attach_to not in today_fixed_ids:
						continue
					today_queue.append(ev)
			&"random":
				if _check_conditions(ev.conditions, day, attr_sys, rel_sys):
					if randf() < RANDOM_EVENT_CHANCE:
						today_queue.append(ev)

	today_queue.sort_custom(func(a: GameEvent, b: GameEvent) -> bool: return a.priority > b.priority)
	event_queue_updated.emit()


func get_events_for_period(period: StringName) -> Array:
	var game_mgr: Node = get_node("/root/GameManager")
	var today: int = game_mgr.current_day
	var candidates: Array = []

	for ev: GameEvent in today_queue:
		if ev.is_consumed:
			continue
		if ev.valid_until_day > 0 and today > ev.valid_until_day:
			ev.is_consumed = true
			continue
		if ev.trigger_period == &"any" or ev.trigger_period == period:
			candidates.append(ev)

	if candidates.size() <= 1:
		return candidates

	# 仲裁：固定事件优先，同类按priority排序
	candidates.sort_custom(func(a: GameEvent, b: GameEvent) -> bool:
		var a_fixed: int = 1 if a.event_type == &"fixed" else 0
		var b_fixed: int = 1 if b.event_type == &"fixed" else 0
		if a_fixed != b_fixed:
			return a_fixed > b_fixed
		return a.priority > b.priority
	)

	var result: Array = [candidates[0]]
	for i: int in range(1, candidates.size()):
		var ev: GameEvent = candidates[i]
		if ev.event_type != &"fixed":
			ev.deferred = true
	return result


func check_deferred_events(period: StringName) -> void:
	for ev: GameEvent in today_queue:
		if ev.deferred and not ev.is_consumed:
			if ev.trigger_period == &"any" or ev.trigger_period == period:
				ev.deferred = false


func consume_event(event: GameEvent) -> void:
	event.is_consumed = true


func _check_conditions(conditions: Array, day: int, attr_sys: Node, rel_sys: Node) -> bool:
	for cond: Dictionary in conditions:
		match cond["type"]:
			"day":
				if day != cond["value"]:
					return false
			"day_range":
				if day < cond["min"] or day > cond["max"]:
					return false
			"relation":
				var val: int = rel_sys.get_relation(StringName(cond["npc"]))
				if not _compare(val, cond["op"], cond["value"]):
					return false
			"attribute":
				var val: int = attr_sys.get_attribute(StringName(cond["attr"]))
				if not _compare(val, cond["op"], cond["value"]):
					return false
	return true


func _compare(val: int, op: String, target: int) -> bool:
	match op:
		">=": return val >= target
		">": return val > target
		"<=": return val <= target
		"<": return val < target
		"==": return val == target
		_: return false
