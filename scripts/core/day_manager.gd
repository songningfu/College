extends Node

signal day_started(day: int)
signal period_ready(period: StringName, hand: Array)
signal execution_started(card_id: StringName)
signal execution_finished(card_id: StringName, results: Dictionary)
signal event_triggered(event: RefCounted)
signal day_ended(day: int, summary: Dictionary)

var current_period_ap: int = 2
var daily_changes: Dictionary = {}

var game_mgr: Node
var attr_sys: Node
var rel_sys: Node
var card_sys: Node
var event_sys: Node


func _ready() -> void:
	game_mgr = get_node("/root/GameManager")
	attr_sys = get_node("/root/AttributeSystem")
	rel_sys = get_node("/root/RelationshipSystem")
	card_sys = get_node("/root/CardSystem")
	event_sys = get_node("/root/EventSystem")


func start_day() -> void:
	var day: int = game_mgr.current_day
	_reset_daily_tracking()
	attr_sys.daily_restore()
	card_sys.update_unlocks(day, rel_sys)
	card_sys.clear_recommendations()

	# Day 2 教学推荐
	if day == 2:
		var morning_recs: Array[StringName] = [&"explore_campus"]
		var afternoon_recs: Array[StringName] = [&"canteen"]
		var evening_recs: Array[StringName] = [&"dorm_chat"]
		card_sys.set_recommendations(&"morning", morning_recs)
		card_sys.set_recommendations(&"afternoon", afternoon_recs)
		card_sys.set_recommendations(&"evening", evening_recs)

	event_sys.build_daily_queue(day, attr_sys, rel_sys)
	rel_sys.process_daily_decay()

	day_started.emit(day)
	_start_period()


func _start_period() -> void:
	var period: StringName = game_mgr.get_current_period()
	current_period_ap = 2

	# 检查顺延事件
	event_sys.check_deferred_events(period)

	var period_events: Array = event_sys.get_events_for_period(period)
	if not period_events.is_empty():
		var top_event = period_events[0]
		if top_event.priority >= 80:
			_trigger_event(top_event)
			_finish_period()
			return

	if game_mgr.is_period_locked():
		if game_mgr.is_military_training_day():
			_execute_military_training()
		_finish_period()
		return

	# 发牌
	game_mgr.set_phase(GameManager.Phase.SCHEDULING)
	var hand: Array = card_sys.deal_hand(period, game_mgr.current_day)
	period_ready.emit(period, hand)


func play_card(card_id: StringName) -> void:
	var card = card_sys.all_cards[card_id]
	current_period_ap -= card.action_point_cost
	attr_sys.modify_resource(&"energy", -card.energy_cost)
	var low_energy_penalty: bool = attr_sys.is_energy_low() and card.energy_cost > 0

	game_mgr.set_phase(GameManager.Phase.EXECUTING)
	execution_started.emit(card_id)
	var results: Dictionary = _apply_card_effects(card, low_energy_penalty)
	execution_finished.emit(card_id, results)

	var period: StringName = game_mgr.get_current_period()
	var period_events: Array = event_sys.get_events_for_period(period)
	for event in period_events:
		if event.priority < 80 and not event.is_consumed:
			_trigger_event(event)
			break

	if current_period_ap <= 0:
		_finish_period()
	else:
		# 时段内剩余行动点，从当前手牌中过滤可用卡
		game_mgr.set_phase(GameManager.Phase.SCHEDULING)
		var remaining_hand: Array = []
		for c in card_sys.get_hand():
			if c.action_point_cost <= current_period_ap:
				remaining_hand.append(c)
		if remaining_hand.is_empty():
			_finish_period()
		else:
			period_ready.emit(period, remaining_hand)


func _apply_card_effects(card, low_energy_penalty: bool) -> Dictionary:
	var results: Dictionary = {
		"card_id": card.id,
		"card_name": card.display_name,
		"effects": [],
		"low_energy_penalty": low_energy_penalty
	}

	for eff: Dictionary in card.effects:
		var target: StringName = eff["target"]
		var delta: int = eff["delta"]

		if low_energy_penalty and eff["type"] == "attribute":
			delta = int(floor(delta * 0.5))

		match eff["type"]:
			"attribute":
				attr_sys.modify_attribute(target, delta)
				_track_change("attributes", target, delta)
				results["effects"].append({"type": "attribute", "target": target, "delta": delta})
			"resource":
				attr_sys.modify_resource(target, delta)
				_track_change("resources", target, delta)
				results["effects"].append({"type": "resource", "target": target, "delta": delta})
			"relation":
				if target == &"_random_roommate":
					var roommates: Array[StringName] = [&"zhou_chi", &"lin_yifan", &"ma_jun"]
					target = roommates[randi() % roommates.size()]
				elif target == &"_selected_npc":
					# 简化：随机选一个已注册NPC
					var npcs: Array = rel_sys.relations.keys()
					if not npcs.is_empty():
						target = npcs[randi() % npcs.size()]

				if target in rel_sys.relations:
					rel_sys.modify_relation(target, delta)
					_track_change("relations", target, delta)
					results["effects"].append({"type": "relation", "target": target, "delta": delta})

	return results


func _execute_military_training() -> void:
	attr_sys.modify_resource(&"energy", -4)
	attr_sys.modify_attribute(&"physique", 1)
	_track_change("attributes", &"physique", 1)
	var classmates: Array[StringName] = [&"shen_qinghe"]
	for npc: StringName in classmates:
		if npc in rel_sys.relations:
			rel_sys.modify_relation(npc, 1)
			_track_change("relations", npc, 1)


func _trigger_event(event) -> void:
	game_mgr.set_phase(GameManager.Phase.EVENT)
	event_triggered.emit(event)

	# 应用事件效果
	for npc_id: StringName in event.relation_effects:
		var delta: int = event.relation_effects[npc_id]
		rel_sys.modify_relation(npc_id, delta)
		_track_change("relations", npc_id, delta)

	for attr_id: StringName in event.attribute_effects:
		var delta: int = event.attribute_effects[attr_id]
		attr_sys.modify_attribute(attr_id, delta)
		_track_change("attributes", attr_id, delta)

	for res_id: StringName in event.resource_effects:
		var delta: int = event.resource_effects[res_id]
		attr_sys.modify_resource(res_id, delta)
		_track_change("resources", res_id, delta)

	event_sys.consume_event(event)


func _finish_period() -> void:
	if game_mgr.advance_period():
		_start_period()
	else:
		_end_day()


func _end_day() -> void:
	var summary: Dictionary = {
		"day": game_mgr.current_day,
		"changes": daily_changes.duplicate(true),
		"final_attributes": {},
		"final_resources": {},
		"final_relations": {}
	}

	for attr_id: StringName in attr_sys.attributes:
		summary["final_attributes"][attr_id] = attr_sys.get_attribute(attr_id)

	for res_id: StringName in attr_sys.resources:
		summary["final_resources"][res_id] = attr_sys.get_resource(res_id)

	for npc_id: StringName in rel_sys.relations:
		summary["final_relations"][npc_id] = rel_sys.get_relation(npc_id)

	game_mgr.set_phase(GameManager.Phase.DAY_SUMMARY)
	day_ended.emit(game_mgr.current_day, summary)


func continue_to_next_day() -> void:
	game_mgr.advance_day()
	if game_mgr.current_phase != GameManager.Phase.DEMO_END:
		start_day()


func _reset_daily_tracking() -> void:
	daily_changes = {
		"attributes": {},
		"resources": {},
		"relations": {}
	}


func _track_change(category: String, key: StringName, delta: int) -> void:
	if category not in daily_changes:
		daily_changes[category] = {}
	if key not in daily_changes[category]:
		daily_changes[category][key] = 0
	daily_changes[category][key] += delta
