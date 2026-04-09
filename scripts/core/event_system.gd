extends Node

signal event_queue_updated()

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
	var story_text: String = ""
	var speaker_name: String = ""
	var next_event: StringName = &""
	var is_consumed: bool = false
	var attach_to: StringName = &""
	var valid_until_day: int = -1
	var deferred: bool = false
	var manual_only: bool = false
	var keep_period_open: bool = false
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

	# === Day 1: 报到日（208宿舍固定阵容） ===
	var day1_arrival := _create_event(&"day1_arrival", "抵达 208", &"fixed", &"morning")
	day1_arrival.trigger_day = 1
	day1_arrival.priority = 95
	day1_arrival.story_text = "你拖着箱子站在 208 门口。门推开时，屋里还是空的，只有四张床位、没铺平的木板味，还有一整个陌生大学生活正安静地等着你。"
	day1_arrival.keep_period_open = true
	all_events[day1_arrival.id] = day1_arrival

	var day1_noon_feng := _create_event(&"day1_noon_lin_yifeng", "林逸枫先到了", &"fixed", &"afternoon")
	day1_noon_feng.trigger_day = 1
	day1_noon_feng.priority = 95
	day1_noon_feng.related_npcs = [&"lin_yifeng"]
	day1_noon_feng.story_text = "中午回到 208 时，门已经半掩着。靠窗那边先多了个人，锅盖头压得很低，拖鞋停在床边。他抬眼看了你一下，又把视线落回手边的东西上，没有先开口。"
	day1_noon_feng.keep_period_open = true
	all_events[day1_noon_feng.id] = day1_noon_feng

	var day1_noon_feng_choice := _create_event(&"day1_noon_lin_yifeng_choice", "和林逸枫的第一句", &"conditional", &"afternoon")
	day1_noon_feng_choice.conditions = [{"type": "day", "value": 1}]
	day1_noon_feng_choice.priority = 70
	day1_noon_feng_choice.related_npcs = [&"lin_yifeng"]
	day1_noon_feng_choice.story_text = "他看上去不像想寒暄的人，但也没有把你挡在外面。空气空了半拍，像是在等你先把这句开场补上。"
	day1_noon_feng_choice.attach_to = &"day1_noon_lin_yifeng"
	day1_noon_feng_choice.manual_only = true
	day1_noon_feng_choice.keep_period_open = true
	day1_noon_feng_choice.choices = [
		{
			"text": "先开口：‘我也是 208 的。’",
			"result_text": "林逸枫这才低低应了一声：‘嗯。林逸枫。’像是把自我介绍补齐了。",
			"next_event": &"day1_noon_chen_xiangxing",
			"relation_effects": {&"lin_yifeng": 2},
			"attribute_effects": {&"eloquence": 1},
			"resource_effects": {&"mood": 1}
		},
		{
			"text": "先把箱子推进去，再偏头问他：‘你也刚到？’",
			"result_text": "他看了你一眼，语气还是淡的：‘比你早一点。’说完才把名字报出来。",
			"next_event": &"day1_noon_chen_xiangxing",
			"relation_effects": {&"lin_yifeng": 1},
			"attribute_effects": {&"insight": 1},
			"resource_effects": {}
		}
	]
	all_events[day1_noon_feng_choice.id] = day1_noon_feng_choice

	var day1_noon_xing := _create_event(&"day1_noon_chen_xiangxing", "陈向星和家里人来了", &"conditional", &"afternoon")
	day1_noon_xing.conditions = [{"type": "day", "value": 1}]
	day1_noon_xing.priority = 69
	day1_noon_xing.related_npcs = [&"chen_xiangxing"]
	day1_noon_xing.story_text = "又过了一阵，门口重新热闹起来。陈向星跟着父母和姐姐一起进来，白净得像刚从高中毕业，眼镜后的目光有点青涩。行李、问路声和脚步声一下把宿舍塞满了。"
	day1_noon_xing.attach_to = &"day1_noon_lin_yifeng_choice"
	day1_noon_xing.keep_period_open = true
	all_events[day1_noon_xing.id] = day1_noon_xing

	var day1_noon_xing_hometown := _create_event(&"day1_noon_chen_xiangxing_hometown", "陈向星父亲问你哪里人", &"conditional", &"afternoon")
	day1_noon_xing_hometown.conditions = [{"type": "day", "value": 1}]
	day1_noon_xing_hometown.priority = 68
	day1_noon_xing_hometown.related_npcs = [&"chen_xiangxing"]
	day1_noon_xing_hometown.speaker_name = "陈向星父亲"
	day1_noon_xing_hometown.story_text = "你是哪里人？"
	day1_noon_xing_hometown.attach_to = &"day1_noon_chen_xiangxing"
	day1_noon_xing_hometown.manual_only = true
	day1_noon_xing_hometown.keep_period_open = true
	day1_noon_xing_hometown.choices = [
		{
			"text": "北方。",
			"result_text": "他父亲点了点头，语气很沉静：‘北方啊，我很喜欢。’",
			"next_event": &"day1_noon_dice",
			"relation_effects": {&"chen_xiangxing": 2},
			"attribute_effects": {},
			"resource_effects": {&"mood": 1}
		},
		{
			"text": "南方。",
			"result_text": "他父亲点了点头，语气还是沉静的：‘南方啊，我很喜欢。’",
			"next_event": &"day1_noon_dice",
			"relation_effects": {&"chen_xiangxing": 2},
			"attribute_effects": {},
			"resource_effects": {&"mood": 1}
		}
	]
	all_events[day1_noon_xing_hometown.id] = day1_noon_xing_hometown

	var day1_noon_dice := _create_event(&"day1_noon_dice", "报到节奏一下快起来了", &"conditional", &"afternoon")
	day1_noon_dice.conditions = [{"type": "day", "value": 1}]
	day1_noon_dice.priority = 67
	day1_noon_dice.related_npcs = [&"lin_yifeng", &"chen_xiangxing"]
	day1_noon_dice.story_text = "宿舍里一下子挤进来好几个人，问路、搬东西、记名字，全都赶在一块。你得在这阵热闹里把自己的节奏稳住。"
	day1_noon_dice.attach_to = &"day1_noon_chen_xiangxing_hometown"
	day1_noon_dice.manual_only = true
	day1_noon_dice.keep_period_open = true
	all_events[day1_noon_dice.id] = day1_noon_dice

	var day1_noon_dice_good := _create_event(&"day1_noon_dice_good", "中午报到接住了", &"conditional", &"afternoon")
	day1_noon_dice_good.conditions = [{"type": "day", "value": 1}]
	day1_noon_dice_good.priority = 66
	day1_noon_dice_good.related_npcs = [&"chen_xiangxing"]
	day1_noon_dice_good.speaker_name = "陈向星"
	day1_noon_dice_good.story_text = "你记得还挺快。刚才一下子进来那么多人，我都还有点懵。"
	day1_noon_dice_good.attach_to = &"day1_noon_dice"
	all_events[day1_noon_dice_good.id] = day1_noon_dice_good

	var day1_noon_dice_bad := _create_event(&"day1_noon_dice_bad", "中午报到有点乱", &"conditional", &"afternoon")
	day1_noon_dice_bad.conditions = [{"type": "day", "value": 1}]
	day1_noon_dice_bad.priority = 66
	day1_noon_dice_bad.related_npcs = [&"chen_xiangxing"]
	day1_noon_dice_bad.story_text = "人一多，宿舍里一下就乱了起来。陈向星把自己的箱子往里拖了拖，像是想给你也空出一点位置。"
	day1_noon_dice_bad.attach_to = &"day1_noon_dice"
	all_events[day1_noon_dice_bad.id] = day1_noon_dice_bad

	var day1_night := _create_event(&"day1_night_settle", "208 的第一晚", &"fixed", &"evening")
	day1_night.trigger_day = 1
	day1_night.priority = 95
	day1_night.related_npcs = [&"lin_yifeng", &"zhou_wen", &"chen_xiangxing", &"shen_yanqi"]
	day1_night.story_text = "到了晚上，208 总算坐满了。周文抱着一袋零食很自然地接话，沈砚麒把行李收得很整齐，只在抬头时安静看你一眼。白天分散的声音现在都落回这间宿舍里，像第一晚终于把人凑齐。"
	day1_night.next_event = &"day1_night_dice"
	all_events[day1_night.id] = day1_night

	var day1_night_dice := _create_event(&"day1_night_dice", "208 的第一轮夜谈", &"conditional", &"evening")
	day1_night_dice.conditions = [{"type": "day", "value": 1}]
	day1_night_dice.priority = 94
	day1_night_dice.related_npcs = [&"lin_yifeng", &"zhou_wen", &"chen_xiangxing", &"shen_yanqi"]
	day1_night_dice.story_text = "灯还没关，话题已经从家乡绕到专业、游戏和高中宿舍。你知道这不是正式的什么时刻，但第一晚说出口的话，往往会被记很久。"
	day1_night_dice.attach_to = &"day1_night_settle"
	day1_night_dice.manual_only = true
	all_events[day1_night_dice.id] = day1_night_dice

	var day1_night_dice_good := _create_event(&"day1_night_dice_good", "夜谈一下接住了", &"conditional", &"evening")
	day1_night_dice_good.conditions = [{"type": "day", "value": 1}]
	day1_night_dice_good.priority = 93
	day1_night_dice_good.related_npcs = [&"zhou_wen", &"chen_xiangxing", &"shen_yanqi"]
	day1_night_dice_good.speaker_name = "周文"
	day1_night_dice_good.story_text = "行啊，208 第一晚算是开了个好头。"
	day1_night_dice_good.attach_to = &"day1_night_dice"
	day1_night_dice_good.keep_period_open = true
	all_events[day1_night_dice_good.id] = day1_night_dice_good

	var day1_night_dice_bad := _create_event(&"day1_night_dice_bad", "夜谈有点卡住", &"conditional", &"evening")
	day1_night_dice_bad.conditions = [{"type": "day", "value": 1}]
	day1_night_dice_bad.priority = 93
	day1_night_dice_bad.related_npcs = [&"shen_yanqi"]
	day1_night_dice_bad.speaker_name = "沈砚麒"
	day1_night_dice_bad.story_text = "第一天这样也正常。"
	day1_night_dice_bad.attach_to = &"day1_night_dice"
	day1_night_dice_bad.keep_period_open = true
	all_events[day1_night_dice_bad.id] = day1_night_dice_bad

	# === 军训期固定事件 ===
	_add_fixed_event(&"day3_first_assembly", "第一次集合", 3, &"morning", 90,
		[&"shen_yanqi"], {&"shen_yanqi": 1}, {}, {})

	# === 沈砚麒递水（条件事件，军训期） ===
	var shen_water := _create_event(&"shen_water", "沈砚麒递水", &"conditional", &"afternoon")
	shen_water.conditions = [
		{"type": "day_range", "min": 5, "max": 9},
		{"type": "relation", "npc": &"shen_yanqi", "op": ">=", "value": 10}
	]
	shen_water.priority = 60
	shen_water.related_npcs = [&"shen_yanqi"]
	shen_water.relation_effects = {&"shen_yanqi": 3}
	shen_water.resource_effects = {&"mood": 1}
	shen_water.valid_until_day = 9
	all_events[shen_water.id] = shen_water

	# === Day 9: 军训结束 ===
	_add_fixed_event(&"day9_military_end", "军训结束", 9, &"evening", 90,
		[&"shen_yanqi"], {&"shen_yanqi": 2}, {&"physique": 1}, {&"mood": 2})

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
		[&"gu_yao", &"shen_yanqi"], {&"gu_yao": 5}, {}, {&"money": -40, &"mood": 2})

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
		if ev.trigger_period != &"any" and ev.trigger_period != period:
			continue
		if ev.attach_to != &"":
			if not all_events.has(ev.attach_to):
				continue
			var attached_event: GameEvent = all_events[ev.attach_to]
			if not attached_event.is_consumed:
				continue
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


func get_event(event_id: StringName) -> GameEvent:
	if all_events.has(event_id):
		return all_events[event_id]
	return null
