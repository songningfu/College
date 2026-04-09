extends Control

var log_text: RichTextLabel
var auto_run: bool = true
var day_delay: float = 0.05

var game_mgr: Node
var attr_sys: Node
var rel_sys: Node
var card_sys: Node
var event_sys: Node
var day_mgr: Node


func _ready() -> void:
	randomize()
	_build_ui()

	game_mgr = get_node("/root/GameManager")
	attr_sys = get_node("/root/AttributeSystem")
	rel_sys = get_node("/root/RelationshipSystem")
	card_sys = get_node("/root/CardSystem")
	event_sys = get_node("/root/EventSystem")
	day_mgr = get_node("/root/DayManager")

	day_mgr.day_started.connect(_on_day_started)
	day_mgr.period_ready.connect(_on_period_ready)
	day_mgr.execution_finished.connect(_on_execution_finished)
	day_mgr.event_triggered.connect(_on_event_triggered)
	day_mgr.event_choice_resolved.connect(_on_event_choice_resolved)
	day_mgr.day_ended.connect(_on_day_ended)

	_log("=== College 21天自动测试 ===")
	_log("验证目标：")
	_log("1. 军训期间（Day 3-9）精力管理是否吃紧")
	_log("2. 顾遥好感在 Day 20 是否落在 75-85 区间")
	_log("3. 每个时段手牌是否有实质选择差异")
	_log("")

	await get_tree().create_timer(1.0).timeout
	_start_test()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "College 核心循环 21天测试"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_text.custom_minimum_size = Vector2(0, 400)
	vbox.add_child(log_text)


func _start_test() -> void:
	game_mgr.reset()

	# 注册NPC
	rel_sys.register_npc(&"lin_yifeng", 15)
	rel_sys.register_npc(&"zhou_wen", 15)
	rel_sys.register_npc(&"chen_xiangxing", 15)
	rel_sys.register_npc(&"shen_yanqi", 15)
	rel_sys.register_npc(&"gu_yao", 30)  # 修订2：初始30
	rel_sys.register_npc(&"chen_wang", 10)

	_log("[初始化] 顾遥初始好感：30（修订后）")
	_log("")

	day_mgr.start_day()


func _on_day_started(day: int) -> void:
	_log("[Day %d 开始]" % day)
	var energy: int = attr_sys.get_resource(&"energy")
	_log("  精力回复到：%d" % energy)


func _on_period_ready(period: StringName, hand: Array) -> void:
	var period_label: String = _period_name(period)
	_log("  [%s] 发牌 %d 张" % [period_label, hand.size()])

	# 显示手牌组成
	var guaranteed_count: int = 0
	var random_count: int = 0
	for card in hand:
		if card.is_guaranteed or card.is_class_card:
			guaranteed_count += 1
		else:
			random_count += 1

	_log("    保底卡：%d 张，随机卡：%d 张" % [guaranteed_count, random_count])

	# 显示卡名
	var card_names: Array[String] = []
	for card in hand:
		card_names.append(card.display_name)
	_log("    卡牌：%s" % ", ".join(card_names))

	# 自动选卡
	if auto_run:
		await get_tree().create_timer(day_delay).timeout
		_auto_play_card()


func _auto_play_card() -> void:
	var hand: Array = card_sys.get_hand()
	var playable: Array = hand.filter(
		func(c) -> bool:
			return c.action_point_cost <= day_mgr.current_period_ap
	)

	if playable.is_empty():
		_log("  无可用卡牌，跳过时段")
		# 无法直接调用私有方法，让系统自然处理
		return

	# 优先选择非保底卡（测试随机池）
	var non_guaranteed: Array = playable.filter(func(c) -> bool: return not c.is_guaranteed and not c.is_class_card)
	var pick
	if not non_guaranteed.is_empty():
		pick = non_guaranteed[randi() % non_guaranteed.size()]
	else:
		pick = playable[randi() % playable.size()]

	_log("    选择：%s（%d点，%d精力）" % [pick.display_name, pick.action_point_cost, pick.energy_cost])
	day_mgr.play_card(pick.id)


func _on_execution_finished(_card_id: StringName, results: Dictionary) -> void:
	if results.get("low_energy_penalty", false):
		_log("    [低精力惩罚] 属性增益减半")

	var effects: Array = results.get("effects", [])
	for eff: Dictionary in effects:
		var target_name: String = String(eff["target"])
		var delta: int = eff["delta"]
		var delta_sign: String = "+" if delta > 0 else ""
		_log("      %s %s%d" % [target_name, delta_sign, delta])


func _on_event_triggered(event) -> void:
	_log("  [事件] %s" % event.display_name)
	if not event.relation_effects.is_empty():
		for npc_id: StringName in event.relation_effects:
			var delta: int = event.relation_effects[npc_id]
			_log("    %s 好感 %+d" % [String(npc_id), delta])
	if auto_run:
		await get_tree().create_timer(day_delay).timeout
		if not event.choices.is_empty():
			var pick_index: int = randi() % event.choices.size()
			var choice_text: String = str(event.choices[pick_index].get("text", "继续"))
			_log("    自动选择：%s" % choice_text)
			day_mgr.resolve_event_choice(pick_index)
		else:
			day_mgr.continue_story_event()


func _on_event_choice_resolved(_event, payload: Dictionary) -> void:
	var result_text: String = str(payload.get("result_text", ""))
	if not result_text.is_empty():
		_log("    结果：%s" % result_text)
	var next_event_id: StringName = StringName(payload.get("next_event", &""))
	if next_event_id != &"":
		await get_tree().create_timer(day_delay).timeout
		day_mgr.continue_after_event_choice(next_event_id)


func _on_day_ended(day: int, summary: Dictionary) -> void:
	var final_energy: int = summary["final_resources"].get(&"energy", 0)
	var final_mood: int = summary["final_resources"].get(&"mood", 0)

	_log("[Day %d 结束]" % day)
	_log("  最终精力：%d，心情：%d" % [final_energy, final_mood])

	# 显示关键NPC好感
	if &"gu_yao" in summary["final_relations"]:
		var gu_yao_rel: int = summary["final_relations"][&"gu_yao"]
		_log("  顾遥好感：%d" % gu_yao_rel)

	if &"shen_qinghe" in summary["final_relations"]:
		var shen_rel: int = summary["final_relations"][&"shen_qinghe"]
		_log("  沈清禾好感：%d" % shen_rel)

	# Day 9 军训结束总结
	if day == 9:
		_log("")
		_log("=== 军训期结束总结 ===")
		_log("  观察：Day 3-9 精力管理是否吃紧？")
		_log("")

	# Day 20 顾遥线检查点
	if day == 20:
		_log("")
		_log("=== Day 20 顾遥线检查点 ===")
		var gu_yao_rel: int = summary["final_relations"].get(&"gu_yao", 0)
		if gu_yao_rel >= 80:
			_log("  [成功] 顾遥好感 %d >= 80，可进入约会线" % gu_yao_rel)
		elif gu_yao_rel >= 75:
			_log("  [接近] 顾遥好感 %d，接近目标但未达标" % gu_yao_rel)
		else:
			_log("  [失败] 顾遥好感 %d < 75，错过约会线" % gu_yao_rel)
		_log("")

	_log("")

	if day >= 21:
		_log("=== 21天测试完成 ===")
		_log_final_summary(summary)
		await get_tree().create_timer(0.5).timeout
		get_tree().quit()
		return

	if auto_run:
		await get_tree().create_timer(day_delay).timeout
		day_mgr.continue_to_next_day()


func _log_final_summary(summary: Dictionary) -> void:
	_log("")
	_log("最终数值：")
	for attr_id: StringName in [&"knowledge", &"eloquence", &"physique", &"insight"]:
		var val: int = summary["final_attributes"].get(attr_id, 0)
		_log("  %s: %d" % [_attr_name(attr_id), val])

	_log("")
	_log("最终资源：")
	for res_id: StringName in [&"energy", &"money", &"mood"]:
		var val: int = summary["final_resources"].get(res_id, 0)
		_log("  %s: %d" % [_res_name(res_id), val])

	_log("")
	_log("最终关系：")
	for npc_id: StringName in summary["final_relations"]:
		var val: int = summary["final_relations"][npc_id]
		_log("  %s: %d" % [String(npc_id), val])


func _log(text: String) -> void:
	print(text)  # 输出到控制台
	if log_text:
		log_text.append_text(text + "\n")


func _period_name(period: StringName) -> String:
	match period:
		&"morning": return "上午"
		&"afternoon": return "下午"
		&"evening": return "晚间"
		_: return String(period)


func _attr_name(attr_id: StringName) -> String:
	match attr_id:
		&"knowledge": return "学识"
		&"eloquence": return "口才"
		&"physique": return "体魄"
		&"insight": return "见识"
		_: return String(attr_id)


func _res_name(res_id: StringName) -> String:
	match res_id:
		&"energy": return "精力"
		&"money": return "金钱"
		&"mood": return "心情"
		_: return String(res_id)
