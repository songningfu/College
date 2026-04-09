extends Control

const DEMO_RELATIONS := {
	&"lin_yifeng": {"name": "林逸枫", "initial": 15},
	&"zhou_wen": {"name": "周文", "initial": 15},
	&"chen_xiangxing": {"name": "陈向星", "initial": 15},
	&"shen_yanqi": {"name": "沈砚麒", "initial": 15},
	&"gu_yao": {"name": "顾遥", "initial": 30},
	&"chen_wang": {"name": "陈望", "initial": 10},
}
const DAY1_PLAYER_PORTRAIT := preload("res://素材/女主/通用测试.png")
const DAY1_DICE_EVENT_IDS: Array[StringName] = [&"day1_noon_dice", &"day1_night_dice"]

@onready var today_view = $TodayView
@onready var story_layer = $StoryLayer
@onready var dice_layer = $DiceLayer
@onready var phone_layer = $PhoneLayer
@onready var day_summary_layer = $DaySummaryLayer
@onready var test_controls: PanelContainer = $TestControls

@onready var test_today_btn = $TestControls/VBox/TestTodayBtn
@onready var test_story_btn = $TestControls/VBox/TestStoryBtn
@onready var test_dice_btn = $TestControls/VBox/TestDiceBtn
@onready var test_phone_btn = $TestControls/VBox/TestPhoneBtn
@onready var test_summary_btn = $TestControls/VBox/TestSummaryBtn

var game_mgr: Node
var attr_sys: Node
var rel_sys: Node
var card_sys: Node
var event_sys: Node
var day_mgr: Node

var current_selected_card_id: StringName = &""
var current_hand_lookup: Dictionary = {}
var current_period_actions := {
	"morning": "无",
	"afternoon": "无",
	"evening": "无",
}
var today_event_titles: Array[String] = []
var last_event_choices: Array = []
var unread_contact_ids: Dictionary = {}
var pending_choice_followup_event_id: StringName = &""
var pending_choice_finishes_period: bool = false
var day1_impression_note: String = ""
var pending_intro_text: String = ""
var pending_intro_event = null
var pending_dice_event = null
var pending_dice_result: Dictionary = {}
var is_dragging_test_controls: bool = false
var test_controls_drag_offset := Vector2.ZERO

func _ready() -> void:
	randomize()
	_resolve_nodes()
	_connect_runtime_signals()
	_connect_test_controls()
	_connect_ui_signals()
	_start_run()

func _resolve_nodes() -> void:
	game_mgr = get_node("/root/GameManager")
	attr_sys = get_node("/root/AttributeSystem")
	rel_sys = get_node("/root/RelationshipSystem")
	card_sys = get_node("/root/CardSystem")
	event_sys = get_node("/root/EventSystem")
	day_mgr = get_node("/root/DayManager")

func _connect_runtime_signals() -> void:
	if not day_mgr.day_started.is_connected(_on_day_started):
		day_mgr.day_started.connect(_on_day_started)
	if not day_mgr.period_ready.is_connected(_on_period_ready):
		day_mgr.period_ready.connect(_on_period_ready)
	if not day_mgr.execution_finished.is_connected(_on_execution_finished):
		day_mgr.execution_finished.connect(_on_execution_finished)
	if not day_mgr.event_triggered.is_connected(_on_event_triggered):
		day_mgr.event_triggered.connect(_on_event_triggered)
	if not day_mgr.day_ended.is_connected(_on_day_ended):
		day_mgr.day_ended.connect(_on_day_ended)
	if not day_mgr.event_choice_resolved.is_connected(_on_event_choice_resolved):
		day_mgr.event_choice_resolved.connect(_on_event_choice_resolved)

func _connect_ui_signals() -> void:
	if not today_view.card_selected.is_connected(_on_today_card_selected):
		today_view.card_selected.connect(_on_today_card_selected)
	if not today_view.confirm_action_pressed.is_connected(_on_confirm_action_pressed):
		today_view.confirm_action_pressed.connect(_on_confirm_action_pressed)
	if not today_view.phone_button_pressed.is_connected(_on_phone_button_pressed):
		today_view.phone_button_pressed.connect(_on_phone_button_pressed)
	if not today_view.computer_button_pressed.is_connected(_on_computer_button_pressed):
		today_view.computer_button_pressed.connect(_on_computer_button_pressed)
	if not story_layer.dialog_finished.is_connected(_on_story_dialog_finished):
		story_layer.dialog_finished.connect(_on_story_dialog_finished)
	if not story_layer.choice_selected.is_connected(_on_story_choice_selected):
		story_layer.choice_selected.connect(_on_story_choice_selected)
	if not dice_layer.dice_finished.is_connected(_on_day1_dice_finished):
		dice_layer.dice_finished.connect(_on_day1_dice_finished)
	if not day_summary_layer.next_day_pressed.is_connected(_on_next_day_pressed):
		day_summary_layer.next_day_pressed.connect(_on_next_day_pressed)
	if not day_summary_layer.phone_cta_pressed.is_connected(_on_phone_button_pressed):
		day_summary_layer.phone_cta_pressed.connect(_on_phone_button_pressed)
	if not phone_layer.phone_closed.is_connected(_refresh_today_view):
		phone_layer.phone_closed.connect(_refresh_today_view)
	if not phone_layer.message_sent.is_connected(_on_phone_message_sent):
		phone_layer.message_sent.connect(_on_phone_message_sent)

func _connect_test_controls() -> void:
	test_controls.gui_input.connect(_on_test_controls_gui_input)
	test_today_btn.pressed.connect(_test_today_view)
	test_story_btn.pressed.connect(_test_story_layer)
	test_dice_btn.pressed.connect(_test_dice_layer)
	test_phone_btn.pressed.connect(_test_phone_layer)
	test_summary_btn.pressed.connect(_test_summary_layer)

func _start_run() -> void:
	game_mgr.reset()
	for npc_id: StringName in DEMO_RELATIONS:
		rel_sys.register_npc(npc_id, int(DEMO_RELATIONS[npc_id]["initial"]))
	current_selected_card_id = &""
	current_hand_lookup.clear()
	today_event_titles.clear()
	unread_contact_ids.clear()
	pending_choice_followup_event_id = &""
	pending_choice_finishes_period = false
	pending_intro_text = ""
	pending_intro_event = null
	pending_dice_event = null
	pending_dice_result.clear()
	day1_impression_note = ""
	_reset_period_actions()
	day_mgr.start_day()

func _on_day_started(day: int) -> void:
	current_selected_card_id = &""
	current_hand_lookup.clear()
	today_event_titles.clear()
	pending_choice_followup_event_id = &""
	pending_choice_finishes_period = false
	pending_intro_text = _day_intro_text(day)
	pending_intro_event = null
	pending_dice_event = null
	pending_dice_result.clear()
	day1_impression_note = ""
	_reset_period_actions()
	_refresh_today_view()

func _on_period_ready(_period: StringName, hand: Array) -> void:
	current_selected_card_id = &""
	current_hand_lookup = _build_hand_lookup(hand)
	today_view.update_view(_build_game_state())
	today_view.load_cards(_serialize_hand(hand))
	today_view.show_context_text(_build_period_context())

func _on_execution_finished(card_id: StringName, _results: Dictionary) -> void:
	var period_key := String(game_mgr.get_current_period())
	var played_name := _get_card_display_name(card_id)
	current_period_actions[period_key] = played_name
	current_selected_card_id = &""
	_refresh_today_view()
	today_view.show_context_text("已执行：%s" % played_name)

func _on_event_triggered(event) -> void:
	var title := String(event.display_name)
	if not today_event_titles.has(title):
		today_event_titles.append(title)
	if event.related_npcs.size() > 0:
		for npc_id: StringName in event.related_npcs:
			unread_contact_ids[npc_id] = true
	if not pending_intro_text.is_empty() and game_mgr.current_day == 1 and String(game_mgr.get_current_period()) == "morning":
		pending_intro_event = event
		story_layer.show_layer()
		story_layer.set_scene_background(Color("#131017"))
		story_layer.hide_character("left")
		story_layer.hide_character("right")
		story_layer.show_fullscreen_text(pending_intro_text)
		pending_intro_text = ""
		return
	if _should_open_day1_dice(event):
		pending_dice_event = event
	_show_story_event(event)

func _on_day_ended(_day: int, summary: Dictionary) -> void:
	day_summary_layer.show_layer(_build_summary_data(summary))

func _on_today_card_selected(card_id: String) -> void:
	current_selected_card_id = StringName(card_id)

func _on_confirm_action_pressed() -> void:
	if current_selected_card_id == &"":
		return
	day_mgr.play_card(current_selected_card_id)

func _on_phone_button_pressed() -> void:
	phone_layer.load_contacts(_build_contacts_data())
	phone_layer.show_layer()

func _on_computer_button_pressed() -> void:
	today_view.show_context_text("电脑功能制作中")

func _on_next_day_pressed() -> void:
	day_mgr.continue_to_next_day()

func _on_story_dialog_finished() -> void:
	if pending_intro_event != null:
		var intro_event = pending_intro_event
		pending_intro_event = null
		_show_story_event(intro_event)
		return
	if not last_event_choices.is_empty():
		story_layer.show_choices(last_event_choices)
		return
	if pending_dice_event != null:
		story_layer.hide_layer(0.15)
		dice_layer.show_layer(_build_day1_dice_data(pending_dice_event))
		return
	if pending_choice_followup_event_id != &"":
		var next_event_id := pending_choice_followup_event_id
		pending_choice_followup_event_id = &""
		pending_choice_finishes_period = false
		day_mgr.continue_after_event_choice(next_event_id)
		_sync_story_layer_after_advance()
		return
	if pending_choice_finishes_period:
		pending_choice_finishes_period = false
		day_mgr.continue_after_event_choice(&"")
		_sync_story_layer_after_advance()
		return
	day_mgr.continue_story_event()
	_sync_story_layer_after_advance()

func _on_story_choice_selected(index: int) -> void:
	if index < 0 or index >= last_event_choices.size():
		return
	last_event_choices.clear()
	day_mgr.resolve_event_choice(index)


func _on_event_choice_resolved(_event, payload: Dictionary) -> void:
	pending_choice_followup_event_id = StringName(payload.get("next_event", &""))
	pending_choice_finishes_period = bool(payload.get("period_finished", false))
	day1_impression_note = str(payload.get("result_text", ""))
	story_layer.show_narration(day1_impression_note)

func _on_phone_message_sent(npc_id: String, choice_index: int) -> void:
	unread_contact_ids.erase(StringName(npc_id))
	var contact_name := _get_npc_name(StringName(npc_id))
	var options: Array = _get_phone_reply_options(StringName(npc_id))
	var reply_text: String = options[choice_index] if choice_index >= 0 and choice_index < options.size() else "收到"
	phone_layer.apply_reply_result(
		npc_id,
		reply_text,
		_build_contact_reply(StringName(npc_id)),
		reply_text,
		_build_contact_time()
	)
	_refresh_today_view()
	today_view.show_context_text("你回复了 %s" % contact_name)

func _build_game_state() -> Dictionary:
	return {
		"day": game_mgr.current_day,
		"period": String(game_mgr.get_current_period()),
		"phase": _phase_to_text(game_mgr.current_phase),
		"energy": attr_sys.get_resource(&"energy"),
		"energy_max": int(attr_sys.RESOURCE_CONFIGS[&"energy"]["max"]),
		"mood": attr_sys.get_resource(&"mood"),
		"mood_max": int(attr_sys.RESOURCE_CONFIGS[&"mood"]["max"]),
		"money": attr_sys.get_resource(&"money"),
		"attributes": {
			"knowledge": attr_sys.get_attribute(&"knowledge"),
			"eloquence": attr_sys.get_attribute(&"eloquence"),
			"physique": attr_sys.get_attribute(&"physique"),
			"insight": attr_sys.get_attribute(&"insight"),
		},
		"ap_remaining": day_mgr.current_period_ap,
		"has_unread_messages": not unread_contact_ids.is_empty(),
	}

func _serialize_hand(hand: Array) -> Array:
	var cards: Array = []
	var period: StringName = game_mgr.get_current_period()
	for card in hand:
		var effects := {}
		var relation_effects := {}
		for effect: Dictionary in card.effects:
			var target := String(effect.get("target", &""))
			var delta := int(effect.get("delta", 0))
			match String(effect.get("type", "")):
				"attribute", "resource":
					effects[_effect_target_name(target)] = delta
				"relation":
					var relation_name := _relation_target_name(target)
					relation_effects[relation_name] = {"value": delta, "visible": not relation_name.begins_with("随机")}
		cards.append({
			"id": String(card.id),
			"display_name": card.display_name,
			"category": String(card.category),
			"action_point_cost": card.action_point_cost,
			"energy_cost": card.energy_cost,
			"effects": effects,
			"relationship_effects": relation_effects,
			"is_guaranteed": card.is_guaranteed,
			"is_class_card": card.is_class_card,
			"show_guide": card_sys.is_recommended(card.id, period),
		})
	return cards

func _build_hand_lookup(hand: Array) -> Dictionary:
	var lookup := {}
	for card in hand:
		lookup[card.id] = card
	return lookup

func _show_story_event(event) -> void:
	last_event_choices = []
	story_layer.show_layer()
	story_layer.set_scene_background(_event_background_color(event))
	_apply_day1_story_staging(event)
	var npc_name := _primary_event_speaker(event)
	var body := _event_body_text(event)
	if npc_name.is_empty():
		story_layer.show_narration(body)
	else:
		story_layer.show_dialog(npc_name, body)
	if event.choices.size() > 0:
		last_event_choices = _adapt_event_choices(event.choices)

func _adapt_event_choices(choices: Array) -> Array:
	var adapted: Array = []
	for choice in choices:
		adapted.append({
			"text": str(choice.get("text", "继续")),
			"available": choice.get("available", true),
		})
	return adapted

func _build_summary_data(summary: Dictionary) -> Dictionary:
	var stats_changes := {}
	var attr_old := _build_old_values(summary.get("final_attributes", {}), summary.get("changes", {}).get("attributes", {}))
	var res_old := _build_old_values(summary.get("final_resources", {}), summary.get("changes", {}).get("resources", {}))
	for key in attr_old:
		stats_changes[String(key)] = {"old": attr_old[key], "new": summary["final_attributes"].get(key, attr_old[key])}
	for key in res_old:
		stats_changes[String(key)] = {"old": res_old[key], "new": summary["final_resources"].get(key, res_old[key])}
	return {
		"day": summary.get("day", game_mgr.current_day),
		"flavor_text": _build_summary_flavor_text(summary),
		"actions": current_period_actions.duplicate(true),
		"events": today_event_titles.duplicate(),
		"stats_changes": stats_changes,
		"relation_changes": _build_relation_changes(summary),
		"has_unread_messages": not unread_contact_ids.is_empty(),
	}

func _build_old_values(final_values: Dictionary, deltas: Dictionary) -> Dictionary:
	var old_values := {}
	for key in final_values:
		old_values[key] = int(final_values[key]) - int(deltas.get(key, 0))
	return old_values

func _build_relation_changes(summary: Dictionary) -> Array:
	var changes: Dictionary = summary.get("changes", {}).get("relations", {})
	var final_relations: Dictionary = summary.get("final_relations", {})
	var result: Array = []
	for npc_id: StringName in DEMO_RELATIONS:
		var final_value := int(final_relations.get(npc_id, rel_sys.get_relation(npc_id)))
		var delta := int(changes.get(npc_id, 0))
		result.append({
			"name": _get_npc_name(npc_id),
			"value": final_value,
			"change": delta,
		})
	return result

func _apply_day1_story_staging(event) -> void:
	story_layer.hide_character("left")
	story_layer.hide_character("right")
	if game_mgr.current_day != 1:
		return
	if StringName(event.id) in [StringName(&"day1_arrival"), StringName(&"day1_noon_dice"), StringName(&"day1_night_dice"), StringName(&"day1_night_settle")]:
		story_layer.show_character("left", DAY1_PLAYER_PORTRAIT)
		return
	if event.related_npcs.size() > 0:
		story_layer.show_character("left", DAY1_PLAYER_PORTRAIT)

func _should_open_day1_dice(event) -> bool:
	return game_mgr.current_day == 1 and StringName(event.id) in DAY1_DICE_EVENT_IDS

func _build_day1_dice_data(event) -> Dictionary:
	if StringName(event.id) == &"day1_noon_dice":
		return {
			"event_name": "中午报到判定",
			"attribute": "见识",
			"modifier": attr_sys.get_attribute(&"insight"),
			"modifier_description": "你得在人和事一下子挤进来的节奏里把自己稳住。",
			"threshold": 9,
			"results": {
				"critical_success": {"description": "你很快把人名、位置和流程都理顺了，节奏甚至被你带得稳下来。", "effects_summary": "见识+1 · 心情+1 · 陈向星好感+1"},
				"success": {"description": "你没有乱，报到和认人都顺利接上。", "effects_summary": "心情+1 · 陈向星好感+1"},
				"partial_success": {"description": "场面有点乱，但你还是把该做的事做完了。", "effects_summary": "无额外变化"},
				"failure": {"description": "你被这阵热闹冲得有点发懵，只能勉强跟上。", "effects_summary": "心情-1"},
				"critical_failure": {"description": "你一时有点手忙脚乱，连自己放到哪的东西都差点忘了。", "effects_summary": "心情-1 · 精力-1"}
			}
		}
	return {
		"event_name": "208 夜谈判定",
		"attribute": "口才",
		"modifier": attr_sys.get_attribute(&"eloquence"),
		"modifier_description": "第一晚说出口的话，往往会被记很久。",
		"threshold": 10,
		"results": {
			"critical_success": {"description": "你一句话就把气氛接住了，208 第一晚的印象因此亮了起来。", "effects_summary": "口才+1 · 心情+1 · 208舍友好感+2"},
			"success": {"description": "你顺着大家的话题接了进去，夜谈自然地热了起来。", "effects_summary": "心情+1 · 208舍友好感+1"},
			"partial_success": {"description": "你说得不多，但也算稳稳地留在了话题里。", "effects_summary": "无额外变化"},
			"failure": {"description": "你有点接不上大家的节奏，只能在旁边听着。", "effects_summary": "心情-1"},
			"critical_failure": {"description": "你刚开口就冷了场，自己都想快点翻过去。", "effects_summary": "心情-1 · 208舍友好感-1"}
		}
	}

func _apply_day1_dice_effects(event_id: StringName, result: Dictionary) -> void:
	var total := int(result.get("total", 0))
	if event_id == &"day1_noon_dice":
		if total >= 13:
			attr_sys.modify_attribute(&"insight", 1)
			attr_sys.modify_resource(&"mood", 1)
			rel_sys.modify_relation(&"chen_xiangxing", 1)
			day_mgr._track_change("attributes", &"insight", 1)
			day_mgr._track_change("resources", &"mood", 1)
			day_mgr._track_change("relations", &"chen_xiangxing", 1)
		elif total >= 9:
			attr_sys.modify_resource(&"mood", 1)
			rel_sys.modify_relation(&"chen_xiangxing", 1)
			day_mgr._track_change("resources", &"mood", 1)
			day_mgr._track_change("relations", &"chen_xiangxing", 1)
		elif total <= 4:
			attr_sys.modify_resource(&"mood", -1)
			attr_sys.modify_resource(&"energy", -1)
			day_mgr._track_change("resources", &"mood", -1)
			day_mgr._track_change("resources", &"energy", -1)
		elif total <= 6:
			attr_sys.modify_resource(&"mood", -1)
			day_mgr._track_change("resources", &"mood", -1)
		return
	if total >= 14:
		attr_sys.modify_attribute(&"eloquence", 1)
		attr_sys.modify_resource(&"mood", 1)
		day_mgr._track_change("attributes", &"eloquence", 1)
		day_mgr._track_change("resources", &"mood", 1)
		for npc_id: StringName in [&"lin_yifeng", &"zhou_wen", &"chen_xiangxing", &"shen_yanqi"]:
			rel_sys.modify_relation(npc_id, 2)
			day_mgr._track_change("relations", npc_id, 2)
	elif total >= 10:
		attr_sys.modify_resource(&"mood", 1)
		day_mgr._track_change("resources", &"mood", 1)
		for npc_id: StringName in [&"lin_yifeng", &"zhou_wen", &"chen_xiangxing", &"shen_yanqi"]:
			rel_sys.modify_relation(npc_id, 1)
			day_mgr._track_change("relations", npc_id, 1)
	elif total <= 5:
		attr_sys.modify_resource(&"mood", -1)
		day_mgr._track_change("resources", &"mood", -1)
		for npc_id: StringName in [&"lin_yifeng", &"zhou_wen", &"chen_xiangxing", &"shen_yanqi"]:
			rel_sys.modify_relation(npc_id, -1)
			day_mgr._track_change("relations", npc_id, -1)
	elif total <= 7:
		attr_sys.modify_resource(&"mood", -1)
		day_mgr._track_change("resources", &"mood", -1)

func _on_day1_dice_finished(result: Dictionary) -> void:
	pending_dice_result = result.duplicate(true)
	if pending_dice_event == null:
		return
	var event_id: StringName = pending_dice_event.id
	_apply_day1_dice_effects(event_id, result)
	var followup_event_id := _resolve_day1_dice_followup_event_id(event_id, result)
	_consume_unused_day1_dice_followups(event_id, followup_event_id)
	pending_dice_event = null
	day1_impression_note = str(dice_layer.result_desc.get_parsed_text()).strip_edges()
	if followup_event_id != &"":
		day_mgr.continue_after_event_choice(followup_event_id)
	else:
		day_mgr.continue_story_event()
	_sync_story_layer_after_advance()

func _resolve_day1_dice_followup_event_id(event_id: StringName, result: Dictionary) -> StringName:
	var total := int(result.get("total", 0))
	if event_id == &"day1_noon_dice":
		return &"day1_noon_dice_good" if total >= 9 else &"day1_noon_dice_bad"
	if event_id == &"day1_night_dice":
		return &"day1_night_dice_good" if total >= 10 else &"day1_night_dice_bad"
	return &""

func _consume_unused_day1_dice_followups(event_id: StringName, selected_event_id: StringName) -> void:
	var candidate_ids: Array[StringName] = []
	if event_id == &"day1_noon_dice":
		candidate_ids = [&"day1_noon_dice_good", &"day1_noon_dice_bad"]
	elif event_id == &"day1_night_dice":
		candidate_ids = [&"day1_night_dice_good", &"day1_night_dice_bad"]
	else:
		return
	for candidate_id: StringName in candidate_ids:
		if candidate_id == selected_event_id:
			continue
		var candidate = event_sys.get_event(candidate_id)
		if candidate != null and not candidate.is_consumed:
			event_sys.consume_event(candidate)

func _build_summary_flavor_text(summary: Dictionary) -> String:
	var event_count := today_event_titles.size()
	var relation_changes: Dictionary = summary.get("changes", {}).get("relations", {})
	if game_mgr.current_day == 1:
		if not day1_impression_note.is_empty():
			return "报到的第一天结束了。%s" % day1_impression_note
		if event_count > 0:
			return "你的大学第一天落下来了，208 的门也在今天真正打开。"
	if event_count > 0:
		return "今天发生了 %d 件值得记住的事。" % event_count
	for npc_id: StringName in relation_changes:
		if int(relation_changes[npc_id]) > 0:
			return "你和 %s 又更熟了一点。" % _get_npc_name(npc_id)
	return "一天结束了，大学生活还在继续。"

func _build_contacts_data() -> Array:
	var contacts: Array = []
	for npc_id: StringName in DEMO_RELATIONS:
		contacts.append({
			"npc_id": String(npc_id),
			"name": _get_npc_name(npc_id),
			"preview": _build_contact_preview(npc_id),
			"time": _build_contact_time(),
			"has_unread": unread_contact_ids.has(npc_id),
			"messages": _build_contact_messages(npc_id),
			"reply_options": _get_phone_reply_options(npc_id),
		})
	return contacts

func _build_contact_messages(npc_id: StringName) -> Array:
	var messages: Array = []
	messages.append({"text": "今天过得怎么样？", "is_player": false})
	if unread_contact_ids.has(npc_id):
		messages.append({"text": _build_contact_preview(npc_id), "is_player": false})
	elif game_mgr.current_day == 1 and not day1_impression_note.is_empty() and npc_id in [&"lin_yifeng", &"chen_xiangxing", &"shen_yanqi", &"zhou_wen"]:
		messages.append({"text": "刚搬进来第一天，感觉 208 还挺有意思的。", "is_player": false})
	else:
		messages.append({"text": "有空再一起走走。", "is_player": false})
	return messages

func _get_phone_reply_options(_npc_id: StringName) -> Array:
	return [
		"好啊，等会聊",
		"我刚忙完",
		"明天见面说",
	]

func _build_contact_preview(npc_id: StringName) -> String:
	if game_mgr.current_day == 1 and unread_contact_ids.has(npc_id):
		match npc_id:
			&"lin_yifeng":
				return "208 今晚总算热闹起来了，你刚才那句开场还挺不错。"
			&"zhou_wen":
				return "我把零食放桌上了，饿了直接拿，别太客气。"
			&"chen_xiangxing":
				return "你收拾东西挺利索，明天出门别忘了带校园卡。"
			&"shen_yanqi":
				return "今天有点累，早点休息。你已经把大家名字记住了吗？"
	if unread_contact_ids.has(npc_id):
		return "刚才那件事，我还在想。"
	var value: int = rel_sys.get_relation(npc_id)
	if value >= 40:
		return "最近跟你聊天挺舒服的。"
	if value >= 20:
		return "今天也算过得还行。"
	return "新的一天加油。"

func _build_contact_reply(npc_id: StringName) -> String:
	if game_mgr.current_day == 1:
		match npc_id:
			&"lin_yifeng":
				return "那就好，之后 208 还得慢慢熟起来。"
			&"zhou_wen":
				return "行，晚上要是饿了喊我。"
			&"chen_xiangxing":
				return "明早我先起，出门前叫你。"
			&"shen_yanqi":
				return "嗯，早点睡，明天见。"
	return "好，晚点再聊。"


func _build_contact_time() -> String:
	match String(game_mgr.get_current_period()):
		"morning":
			return "09:20"
		"afternoon":
			return "15:40"
		_:
			return "21:10"

func _day_intro_text(day: int) -> String:
	if day == 1:
		return "报到日。你拖着箱子穿过还很陌生的校园，208 宿舍的门牌就在走廊尽头。"
	return ""

func _sync_story_layer_after_advance() -> void:
	if game_mgr.current_phase == GameManager.Phase.EVENT:
		return
	story_layer.hide_layer()
	_refresh_today_view()

func _refresh_today_view() -> void:
	today_view.update_view(_build_game_state())

func _reset_period_actions() -> void:
	current_period_actions = {
		"morning": "无",
		"afternoon": "无",
		"evening": "无",
	}

func _phase_to_text(phase: int) -> String:
	match phase:
		GameManager.Phase.SCHEDULING:
			return "SCHEDULING"
		GameManager.Phase.EXECUTING:
			return "EXECUTING"
		GameManager.Phase.EVENT:
			return "EVENT"
		GameManager.Phase.DAY_SUMMARY:
			return "DAY_SUMMARY"
		GameManager.Phase.DEMO_END:
			return "DEMO_END"
		_:
			return "TITLE"

func _build_period_context() -> String:
	var period := String(game_mgr.get_current_period())
	if game_mgr.is_military_training_day() and period != "evening":
		return "军训还没结束，白天几乎没有喘息空间。"
	if not today_event_titles.is_empty():
		return "刚发生：%s" % today_event_titles[today_event_titles.size() - 1]
	return "%s还有 %d AP，可以继续安排。" % [_period_name(period), day_mgr.current_period_ap]

func _event_body_text(event) -> String:
	var authored_text := str(event.story_text)
	if not authored_text.is_empty():
		return authored_text
	var parts: Array[String] = []
	if event.related_npcs.size() > 0:
		parts.append("%s出现在你的视线里。" % _get_npc_name(event.related_npcs[0]))
	if not event.attribute_effects.is_empty():
		parts.append("这件事让你的状态发生了些变化。")
	if not event.resource_effects.is_empty() or not event.relation_effects.is_empty():
		parts.append("你隐约感觉，今天会被记住。")
	if parts.is_empty():
		parts.append("%s。" % String(event.display_name))
	return " ".join(parts)

func _primary_event_speaker(event) -> String:
	if not String(event.speaker_name).is_empty():
		return String(event.speaker_name)
	if game_mgr.current_day == 1:
		return ""
	if StringName(event.id) == &"day1_night_settle":
		return ""
	if StringName(event.id) in DAY1_DICE_EVENT_IDS:
		return ""
	if event.related_npcs.is_empty():
		return ""
	return _get_npc_name(event.related_npcs[0])

func _event_background_color(event) -> Color:
	if event.priority >= 90:
		return Color("#2b2330")
	if event.related_npcs.size() > 0:
		return Color("#233042")
	return Color("#2a2520")

func _effect_target_name(target: String) -> String:
	match target:
		"knowledge": return "学识"
		"eloquence": return "口才"
		"physique": return "体魄"
		"insight": return "见识"
		"energy": return "精力"
		"mood": return "心情"
		"money": return "金钱"
		_:
			return target

func _relation_target_name(target: String) -> String:
	match target:
		"_fixed_roommate": return "208舍友"
		"_selected_npc": return "随机同学"
		_:
			return _get_npc_name(StringName(target))

func _get_card_display_name(card_id: StringName) -> String:
	if current_hand_lookup.has(card_id):
		return current_hand_lookup[card_id].display_name
	if card_sys.all_cards.has(card_id):
		return card_sys.all_cards[card_id].display_name
	return String(card_id)

func _get_npc_name(npc_id: StringName) -> String:
	if DEMO_RELATIONS.has(npc_id):
		return String(DEMO_RELATIONS[npc_id]["name"])
	return String(npc_id)

func _period_name(period: String) -> String:
	match period:
		"morning":
			return "上午"
		"afternoon":
			return "下午"
		"evening":
			return "晚间"
		_:
			return period

func _on_test_controls_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging_test_controls = true
			test_controls_drag_offset = get_global_mouse_position() - test_controls.global_position
		else:
			is_dragging_test_controls = false
	elif event is InputEventMouseMotion and is_dragging_test_controls:
		test_controls.global_position = get_global_mouse_position() - test_controls_drag_offset

func _test_today_view() -> void:
	var game_state = {
		"day": 1,
		"period": "morning",
		"phase": "SCHEDULING",
		"energy": 7,
		"energy_max": 10,
		"mood": 6,
		"money": 200,
		"attributes": {
			"knowledge": 2,
			"eloquence": 2,
			"physique": 2,
			"insight": 2
		},
		"ap_remaining": 2,
		"has_unread_messages": true
	}
	today_view.update_view(game_state)
	today_view.load_cards([
		{
			"id": "card_class_1",
			"display_name": "专业课",
			"category": "class",
			"action_point_cost": 2,
			"energy_cost": 1,
			"effects": {"学识": 1, "精力": -1},
			"is_guaranteed": false,
			"is_class_card": true
		},
		{
			"id": "card_social_1",
			"display_name": "社团活动",
			"category": "social",
			"action_point_cost": 1,
			"effects": {"口才": 1, "心情": 1},
			"relationship_effects": {"林逸枫": {"value": 2, "visible": true}},
			"is_guaranteed": false
		},
		{
			"id": "card_rest_1",
			"display_name": "宿舍休息",
			"category": "rest",
			"action_point_cost": 1,
			"effects": {"精力": 2, "心情": 1},
			"is_guaranteed": true
		}
	])

func _test_story_layer() -> void:
	story_layer.show_layer()
	story_layer.set_scene_background(Color("#2a2520"))
	story_layer.show_dialog("林逸枫", "嘿，你也是新生吧？我叫林逸枫，计算机系的。")

func _test_dice_layer() -> void:
	dice_layer.show_layer({
		"event_name": "课堂发言",
		"attribute": "口才",
		"modifier": 3,
		"modifier_description": "你的口才还不错，而且今天心情不坏。（+3）",
		"threshold": 10,
		"results": {
			"critical_success": {"description": "你的发言清晰有力，连老师都多看了你一眼。", "effects_summary": "口才经验+1 · 心情+1 · 班级印象+3"},
			"success": {"description": "你顺利完成了发言，表现不错。", "effects_summary": "口才经验+1 · 班级印象+1"},
			"partial_success": {"description": "你磕磕绊绊地说完了，还算过得去。", "effects_summary": "口才经验+1"},
			"failure": {"description": "你有些紧张，说得不太流畅。", "effects_summary": "心情-1"},
			"critical_failure": {"description": "你紧张得说不出话，场面一度很尴尬。", "effects_summary": "心情-2 · 班级印象-2"}
		}
	})

func _test_phone_layer() -> void:
	phone_layer.load_contacts(_build_contacts_data())
	phone_layer.show_layer()

func _test_summary_layer() -> void:
	day_summary_layer.show_layer({
		"day": 1,
		"flavor_text": "你的第一个大学夜晚，安静又漫长。",
		"actions": {"morning": "上专业课", "afternoon": "社团活动", "evening": "宿舍闲聊"},
		"events": ["第一次注意到沈砚麒", "和林逸枫成为朋友"],
		"stats_changes": {
			"knowledge": {"old": 2, "new": 3},
			"eloquence": {"old": 2, "new": 2},
			"physique": {"old": 2, "new": 2},
			"insight": {"old": 2, "new": 3},
			"energy": {"old": 7, "new": 5},
			"mood": {"old": 6, "new": 7},
			"money": {"old": 200, "new": 180}
		},
		"relation_changes": [
			{"name": "林逸枫", "value": 22, "change": 2},
			{"name": "沈砚麒", "value": 17, "change": 2},
			{"name": "周文", "value": 18, "change": 0}
		],
		"has_unread_messages": true
	})
