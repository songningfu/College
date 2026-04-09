extends Node

signal card_unlocked(card_id: StringName)
signal hand_dealt(period: StringName, hand: Array)

const HAND_SIZE: int = 5
const DAY1_ONLY_CARD_IDS: Array[StringName] = [
	&"check_in_registration",
	&"familiarize_dorm_building",
	&"complete_registration",
	&"organize_belongings",
	&"buy_daily_supplies",
	&"dorm_chat_first_night",
]
const DAY1_PERIOD_POOL := {
	&"morning": [&"check_in_registration", &"familiarize_dorm_building", &"explore_campus", &"canteen", &"dorm_rest"],
	&"afternoon": [&"complete_registration", &"organize_belongings", &"buy_daily_supplies", &"explore_campus", &"canteen"],
	&"evening": [&"dorm_chat_first_night", &"browse_phone", &"canteen", &"dorm_rest"],
}

class ActionCard extends RefCounted:
	var id: StringName
	var display_name: String
	var category: StringName
	var action_point_cost: int
	var energy_cost: int
	var effects: Array[Dictionary]
	var unlock_condition: Dictionary
	var period_restriction: StringName
	var is_unlocked: bool = false
	var is_guaranteed: bool = false
	var is_class_card: bool = false

	func get_display_cost() -> String:
		if energy_cost < 0:
			return "%d行动点 / 回复%d精力" % [action_point_cost, -energy_cost]
		return "%d行动点 / %d精力" % [action_point_cost, energy_cost]


## 所有卡牌 { card_id: ActionCard }
var all_cards: Dictionary = {}
## 当前手牌
var current_hand: Array = []
## 当日推荐卡牌 { period: Array[StringName] }
var daily_recommendations: Dictionary = {}
## 课表 { day: { period: StringName(card_id) } }
var class_schedule: Dictionary = {}


func _ready() -> void:
	_init_cards()
	_init_class_schedule()


func reset() -> void:
	current_hand.clear()
	daily_recommendations.clear()
	for cid: StringName in all_cards:
		all_cards[cid].is_unlocked = false


func _init_cards() -> void:
	all_cards.clear()

	# === 常驻保底卡 ===
	_add_card(&"dorm_rest", "宿舍休息", &"rest", 1, -3,
		[], {"type": "day", "value": 1}, &"any", true, false)

	_add_card(&"canteen", "食堂吃饭", &"social", 1, -1,
		[{"target": &"mood", "type": "resource", "delta": 1}],
		{"type": "day", "value": 1}, &"any", true, false)

	_add_card(&"self_study", "自习", &"class", 1, 1,
		[{"target": &"knowledge", "type": "attribute", "delta": 1}],
		{"type": "day", "value": 1}, &"any", true, false)

	_add_card(&"browse_phone", "刷手机", &"fun", 1, 0,
		[{"target": &"mood", "type": "resource", "delta": 1}],
		{"type": "day", "value": 1}, &"any", true, false)

	# === Day 1 专属卡 ===
	_add_card(&"check_in_registration", "新生报到", &"life", 1, 1,
		[{"target": &"insight", "type": "attribute", "delta": 1},
		 {"target": &"mood", "type": "resource", "delta": 1}],
		{"type": "day", "value": 1}, &"morning", false, false)

	_add_card(&"familiarize_dorm_building", "熟悉宿舍楼", &"explore", 1, 1,
		[{"target": &"insight", "type": "attribute", "delta": 1}],
		{"type": "day", "value": 1}, &"morning", false, false)

	_add_card(&"complete_registration", "补完报到", &"life", 1, 1,
		[{"target": &"insight", "type": "attribute", "delta": 1},
		 {"target": &"mood", "type": "resource", "delta": 1}],
		{"type": "day", "value": 1}, &"afternoon", false, false)

	_add_card(&"organize_belongings", "整理床位", &"life", 1, 1,
		[{"target": &"insight", "type": "attribute", "delta": 1},
		 {"target": &"chen_xiangxing", "type": "relation", "delta": 1}],
		{"type": "day", "value": 1}, &"afternoon", false, false)

	_add_card(&"buy_daily_supplies", "买生活用品", &"life", 1, 1,
		[{"target": &"money", "type": "resource", "delta": -20},
		 {"target": &"mood", "type": "resource", "delta": 2}],
		{"type": "day", "value": 1}, &"afternoon", false, false)

	_add_card(&"dorm_chat_first_night", "睡前闲聊", &"social", 1, 1,
		[{"target": &"_fixed_roommate", "type": "relation", "delta": 2},
		 {"target": &"mood", "type": "resource", "delta": 1}],
		{"type": "day", "value": 1}, &"evening", false, false)

	# === 课程卡（有课时段保底） ===
	_add_card(&"attend_major_class", "上专业课", &"class", 2, 1,
		[{"target": &"knowledge", "type": "attribute", "delta": 1}],
		{"type": "day", "value": 10}, &"any", false, true)

	_add_card(&"attend_public_class", "上公共课", &"class", 2, 1,
		[{"target": &"knowledge", "type": "attribute", "delta": 1}],
		{"type": "day", "value": 10}, &"any", false, true)

	# === 随机池卡牌 ===
	_add_card(&"dorm_chat", "宿舍闲聊", &"social", 1, 1,
		[{"target": &"_fixed_roommate", "type": "relation", "delta": 2}],
		{"type": "day", "value": 2}, &"any", false, false)

	_add_card(&"chat_with", "找人聊天", &"social", 1, 1,
		[{"target": &"_selected_npc", "type": "relation", "delta": 2}],
		{"type": "relation_any", "value": 20}, &"any", false, false)

	_add_card(&"part_time_job", "兼职打工", &"work", 2, 2,
		[{"target": &"money", "type": "resource", "delta": 30},
		 {"target": &"insight", "type": "attribute", "delta": 1}],
		{"type": "day", "value": 10}, &"any", false, false)

	_add_card(&"play_games", "打游戏", &"fun", 1, 0,
		[{"target": &"mood", "type": "resource", "delta": 2},
		 {"target": &"zhou_wen", "type": "relation", "delta": 1}],
		{"type": "day", "value": 3}, &"any", false, false)

	_add_card(&"jogging", "跑步", &"exercise", 1, 2,
		[{"target": &"physique", "type": "attribute", "delta": 1}],
		{"type": "day", "value": 1}, &"any", false, false)

	_add_card(&"gym", "健身", &"exercise", 2, 3,
		[{"target": &"physique", "type": "attribute", "delta": 2}],
		{"type": "day", "value": 10}, &"any", false, false)

	_add_card(&"club_activity", "社团活动", &"club", 2, 1,
		[{"target": &"insight", "type": "attribute", "delta": 1},
		 {"target": &"eloquence", "type": "attribute", "delta": 1},
		 {"target": &"gu_yao", "type": "relation", "delta": 2}],
		{"type": "day", "value": 15}, &"any", true, false)

	_add_card(&"explore_campus", "逛校园", &"explore", 1, 1,
		[{"target": &"insight", "type": "attribute", "delta": 1},
		 {"target": &"mood", "type": "resource", "delta": 1}],
		{"type": "day", "value": 1}, &"any", false, false)

	_add_card(&"late_night_food", "夜宵局", &"nightlife", 2, 2,
		[{"target": &"eloquence", "type": "attribute", "delta": 1},
		 {"target": &"_selected_npc", "type": "relation", "delta": 3},
		 {"target": &"money", "type": "resource", "delta": -20}],
		{"type": "relation_any", "value": 35}, &"evening", false, false)

	_add_card(&"ktv", "KTV", &"nightlife", 2, 3,
		[{"target": &"mood", "type": "resource", "delta": 3},
		 {"target": &"money", "type": "resource", "delta": -50}],
		{"type": "relation", "npc": &"lin_yifeng", "value": 35}, &"evening", false, false)

	# === 军训期专属卡 ===
	_add_card(&"night_jog", "操场夜跑", &"exercise", 1, 1,
		[{"target": &"physique", "type": "attribute", "delta": 1},
		 {"target": &"mood", "type": "resource", "delta": 1}],
		{"type": "day", "value": 4}, &"evening", false, false)

	_add_card(&"chat_senior", "找学长聊天", &"social", 1, 1,
		[{"target": &"insight", "type": "attribute", "delta": 1},
		 {"target": &"chen_wang", "type": "relation", "delta": 2}],
		{"type": "day", "value": 4}, &"evening", false, false)

	_add_card(&"sneak_phone", "偷看手机", &"fun", 1, 0,
		[{"target": &"mood", "type": "resource", "delta": 1}],
		{"type": "day", "value": 4}, &"evening", false, false)

	# === 沈清禾隐性关联卡 ===
	_add_card(&"linger_field", "在操场多待一会", &"exercise", 1, 1,
		[{"target": &"physique", "type": "attribute", "delta": 1},
		 {"target": &"shen_yanqi", "type": "relation", "delta": 2}],
		{"type": "day", "value": 5}, &"evening", false, false)

	_add_card(&"read_class_chat", "翻看班群聊天记录", &"fun", 1, 0,
		[{"target": &"mood", "type": "resource", "delta": 1},
		 {"target": &"shen_yanqi", "type": "relation", "delta": 1}],
		{"type": "day", "value": 7}, &"evening", false, false)


func _add_card(id: StringName, display_name: String, category: StringName,
		ap_cost: int, energy_cost: int, effects: Array,
		unlock_condition: Dictionary, period_restriction: StringName,
		guaranteed: bool, class_card: bool) -> void:
	var card := ActionCard.new()
	card.id = id
	card.display_name = display_name
	card.category = category
	card.action_point_cost = ap_cost
	card.energy_cost = energy_cost
	for e in effects:
		card.effects.append(e)
	card.unlock_condition = unlock_condition
	card.period_restriction = period_restriction
	card.is_guaranteed = guaranteed
	card.is_class_card = class_card
	all_cards[id] = card


func _init_class_schedule() -> void:
	class_schedule[10] = {&"morning": &"attend_major_class"}
	class_schedule[11] = {&"morning": &"attend_public_class"}
	class_schedule[12] = {&"afternoon": &"attend_major_class"}
	class_schedule[13] = {&"morning": &"attend_public_class"}
	class_schedule[14] = {&"morning": &"attend_major_class", &"afternoon": &"attend_public_class"}
	class_schedule[15] = {&"morning": &"attend_major_class"}
	class_schedule[16] = {&"afternoon": &"attend_public_class"}
	class_schedule[17] = {&"morning": &"attend_major_class"}
	class_schedule[18] = {&"morning": &"attend_public_class"}
	class_schedule[19] = {&"afternoon": &"attend_major_class"}
	class_schedule[20] = {&"morning": &"attend_public_class"}
	class_schedule[21] = {}


func update_unlocks(current_day: int, rel_sys: Node) -> void:
	for cid: StringName in all_cards:
		var card: ActionCard = all_cards[cid]
		if card.is_unlocked:
			continue
		var cond: Dictionary = card.unlock_condition
		var unlocked: bool = false
		match cond.get("type", ""):
			"day":
				unlocked = current_day >= cond["value"]
			"relation":
				unlocked = rel_sys.get_relation(StringName(cond["npc"])) >= cond["value"]
			"relation_any":
				for npc_id: StringName in rel_sys.relations:
					if rel_sys.get_relation(npc_id) >= cond["value"]:
						unlocked = true
						break
		if unlocked:
			card.is_unlocked = true
			card_unlocked.emit(cid)


func deal_hand(period: StringName, current_day: int) -> Array:
	current_hand.clear()
	if current_day == 1 and DAY1_PERIOD_POOL.has(period):
		return _deal_day1_hand(period)

	# 第一步：常驻保底卡
	var guaranteed: Array = []
	for cid: StringName in all_cards:
		var card: ActionCard = all_cards[cid]
		if not card.is_unlocked or not card.is_guaranteed:
			continue
		if card.period_restriction != &"any" and card.period_restriction != period:
			continue
		guaranteed.append(card)

	# 第二步：课表保底
	if current_day in class_schedule:
		var day_sched: Dictionary = class_schedule[current_day]
		if period in day_sched:
			var class_cid: StringName = day_sched[period]
			if class_cid in all_cards and all_cards[class_cid].is_unlocked:
				var cc: ActionCard = all_cards[class_cid]
				if cc not in guaranteed:
					guaranteed.append(cc)

	# 第三步：加入手牌
	for card in guaranteed:
		current_hand.append(card)

	# 第四步：随机池填充
	var remaining: int = HAND_SIZE - current_hand.size()
	if remaining > 0:
		var pool: Array = []
		for cid: StringName in all_cards:
			var card: ActionCard = all_cards[cid]
			if not card.is_unlocked or card.is_guaranteed or card.is_class_card:
				continue
			if current_day > 1 and cid in DAY1_ONLY_CARD_IDS:
				continue
			if card.period_restriction != &"any" and card.period_restriction != period:
				continue
			if card in current_hand:
				continue
			pool.append(card)
		pool.shuffle()
		for i: int in range(mini(remaining, pool.size())):
			current_hand.append(pool[i])

	hand_dealt.emit(period, current_hand)
	return current_hand


func _deal_day1_hand(period: StringName) -> Array:
	var pool_ids: Array = DAY1_PERIOD_POOL[period]
	for card_id: StringName in pool_ids:
		if all_cards.has(card_id) and all_cards[card_id].is_unlocked:
			current_hand.append(all_cards[card_id])
	hand_dealt.emit(period, current_hand)
	return current_hand


func get_hand() -> Array:
	return current_hand


func set_recommendations(period: StringName, card_ids: Array[StringName]) -> void:
	daily_recommendations[period] = card_ids

func is_recommended(card_id: StringName, period: StringName) -> bool:
	if period in daily_recommendations:
		return card_id in daily_recommendations[period]
	return false

func clear_recommendations() -> void:
	daily_recommendations.clear()
