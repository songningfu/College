@tool
extends Control

enum HoverHintMode {
	SHOW,
	HIDE,
}

signal card_selected(card_id: String)
signal confirm_action_pressed
signal phone_button_pressed
signal computer_button_pressed

const ActionCardScene = preload("res://scenes/ui/components/action_card.tscn")
const RESOURCE_TRACK_COLOR := Color("#202739")
const RESOURCE_TRACK_TINT := Color("#8cb4c9", 0.16)
const RESOURCE_TRACK_BORDER := Color("#a9c9da", 0.30)
const ENERGY_BAR_HIGH := Color("#f3c45f")
const ENERGY_BAR_MID := Color("#e8a838")
const FUNC_BTN_BG := Color("#1d2435")
const FUNC_BTN_BG_HOVER := Color("#283147")
const FUNC_BTN_BORDER := Color("#a9c9da", 0.22)
const FUNC_BTN_DISABLED_BG := Color("#141a28")
const FUNC_BTN_DISABLED_BORDER := Color("#8ea0b5", 0.14)
const MOOD_BAR_HIGH := Color("#ff9c78")
const MOOD_BAR_MID := Color("#e39a86")

# 状态栏节点
@onready var player_name_label: Label = $StatusBar/ModuleCanvas/NameModule/PlayerName
@onready var energy_ind: Control = $StatusBar/ModuleCanvas/ResourceModule/ResourceGroup/EnergyInd
@onready var energy_value: Label = $StatusBar/ModuleCanvas/ResourceModule/ResourceGroup/EnergyInd/BarWrap/Value
@onready var energy_bar: ProgressBar = $StatusBar/ModuleCanvas/ResourceModule/ResourceGroup/EnergyInd/BarWrap/Bar
@onready var mood_ind: Control = $StatusBar/ModuleCanvas/ResourceModule/ResourceGroup/MoodInd
@onready var mood_value: Label = $StatusBar/ModuleCanvas/ResourceModule/ResourceGroup/MoodInd/BarWrap/Value
@onready var mood_bar: ProgressBar = $StatusBar/ModuleCanvas/ResourceModule/ResourceGroup/MoodInd/BarWrap/Bar
@onready var money_ind: Control = $StatusBar/ModuleCanvas/ResourceModule/ResourceGroup/MoneyInd
@onready var money_value: Label = $StatusBar/ModuleCanvas/ResourceModule/ResourceGroup/MoneyInd/Value

@onready var knowledge_ind: Control = $StatusBar/ModuleCanvas/AttrModule/AttrGroup/Knowledge
@onready var knowledge_value: Label = $StatusBar/ModuleCanvas/AttrModule/AttrGroup/Knowledge/Value
@onready var eloquence_ind: Control = $StatusBar/ModuleCanvas/AttrModule/AttrGroup/Eloquence
@onready var eloquence_value: Label = $StatusBar/ModuleCanvas/AttrModule/AttrGroup/Eloquence/Value
@onready var physique_ind: Control = $StatusBar/ModuleCanvas/AttrModule/AttrGroup/Physique
@onready var physique_value: Label = $StatusBar/ModuleCanvas/AttrModule/AttrGroup/Physique/Value
@onready var insight_ind: Control = $StatusBar/ModuleCanvas/AttrModule/AttrGroup/Insight
@onready var insight_value: Label = $StatusBar/ModuleCanvas/AttrModule/AttrGroup/Insight/Value

@onready var phone_btn: TextureButton = $StatusBar/ModuleCanvas/FuncModule/FuncBtns/PhoneBtn
@onready var unread_dot: ColorRect = $StatusBar/ModuleCanvas/FuncModule/FuncBtns/PhoneBtn/UnreadDot
@onready var computer_btn: TextureButton = $StatusBar/ModuleCanvas/FuncModule/FuncBtns/ComputerBtn

# 中景舞台区节点
@onready var day_label: Label = $StageArea/DayLabel
@onready var period_label: Label = $StageArea/PeriodLabel
@onready var context_text: Label = $StageArea/ContextText

# 时段条节点
@onready var morning_slot: Panel = $PeriodBar/HBox/MorningSlot
@onready var morning_status: Label = $PeriodBar/HBox/MorningSlot/HBox/Status
@onready var morning_line: ColorRect = $PeriodBar/HBox/MorningSlot/ActiveLine
@onready var afternoon_slot: Panel = $PeriodBar/HBox/AfternoonSlot
@onready var afternoon_status: Label = $PeriodBar/HBox/AfternoonSlot/HBox/Status
@onready var evening_slot: Panel = $PeriodBar/HBox/EveningSlot
@onready var evening_status: Label = $PeriodBar/HBox/EveningSlot/HBox/Status

# 手牌区节点
@onready var title_label: Label = $HandArea/VBox/TitleRow/Title
@onready var confirm_btn: Button = $HandArea/VBox/TitleRow/ConfirmBtn
@onready var card_row: HBoxContainer = $HandArea/VBox/CardRow
@onready var detail_panel: Panel = $HandArea/VBox/DetailPanel
@onready var detail_card_name: Label = $HandArea/VBox/DetailPanel/MarginContainer/VBox/CardName
@onready var detail_card_info: Label = $HandArea/VBox/DetailPanel/MarginContainer/VBox/CardInfo
@onready var detail_content: RichTextLabel = $HandArea/VBox/DetailPanel/MarginContainer/VBox/DetailContent
@onready var low_energy_warning: Label = $HandArea/VBox/DetailPanel/MarginContainer/VBox/LowEnergyWarning

var current_cards: Array[Node] = []
var selected_card_id: String = ""
var current_phase: String = "SCHEDULING"
var energy_pulse_tween: Tween
var mood_pulse_tween: Tween
var energy_value_tween: Tween
var mood_value_tween: Tween
var context_tween: Tween
var hover_context_text: String = ""

func _ready() -> void:
	phone_btn.pressed.connect(_on_phone_pressed)
	computer_btn.pressed.connect(_on_computer_pressed)
	confirm_btn.pressed.connect(_on_confirm_pressed)

	_setup_styles()
	_bind_top_bar_hover_hints()
	detail_panel.visible = false

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_setup_styles")

func _setup_styles() -> void:
	# 状态栏样式
	var status_style = StyleBoxFlat.new()
	status_style.bg_color = Color(ThemeColors.BG_DEEP, 0.95)
	status_style.border_width_bottom = 1
	status_style.border_color = ThemeColors.BORDER_DEFAULT
	$StatusBar.add_theme_stylebox_override("panel", status_style)

	# 时段条样式
	var period_style = StyleBoxFlat.new()
	period_style.bg_color = ThemeColors.BG_DEEP
	period_style.border_width_top = 1
	period_style.border_width_bottom = 1
	period_style.border_color = Color(1, 1, 1, 0.06)
	$PeriodBar.add_theme_stylebox_override("panel", period_style)

	# 手牌区样式
	var hand_style = StyleBoxFlat.new()
	hand_style.bg_color = Color(ThemeColors.BG_PANEL, 0.9)
	hand_style.border_width_top = 1
	hand_style.border_color = Color(1, 1, 1, 0.1)
	$HandArea.add_theme_stylebox_override("panel", hand_style)

	# 确认按钮样式
	_update_confirm_button_style(false)

	# 详情面板样式
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color(ThemeColors.BG_HOVER, 0.95)
	detail_style.set_corner_radius_all(8)
	detail_panel.add_theme_stylebox_override("panel", detail_style)

	# 精力条样式
	_apply_resource_bar_style(energy_bar, ENERGY_BAR_HIGH)

	# 心情条样式
	_apply_resource_bar_style(mood_bar, MOOD_BAR_HIGH)

	energy_value.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	mood_value.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	energy_value.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	mood_value.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	energy_value.add_theme_constant_override("shadow_offset_x", 0)
	energy_value.add_theme_constant_override("shadow_offset_y", 1)
	mood_value.add_theme_constant_override("shadow_offset_x", 0)
	mood_value.add_theme_constant_override("shadow_offset_y", 1)

	_setup_function_buttons()
	_setup_attribute_dots()

func _setup_function_buttons() -> void:
	_apply_function_button_style(phone_btn, false)
	_apply_function_button_style(computer_btn, false)
	_update_function_buttons(current_phase, false)

func _apply_function_button_style(button: TextureButton, is_disabled: bool) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = FUNC_BTN_DISABLED_BG if is_disabled else FUNC_BTN_BG
	normal_style.set_border_width_all(1)
	normal_style.border_color = FUNC_BTN_DISABLED_BORDER if is_disabled else FUNC_BTN_BORDER
	normal_style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = FUNC_BTN_DISABLED_BG if is_disabled else FUNC_BTN_BG_HOVER
	hover_style.set_border_width_all(1)
	hover_style.border_color = FUNC_BTN_DISABLED_BORDER if is_disabled else FUNC_BTN_BORDER
	hover_style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("disabled", normal_style)

func _update_function_buttons(_phase: String, has_unread: bool) -> void:
	unread_dot.visible = has_unread

	phone_btn.disabled = false
	phone_btn.modulate.a = 0.92
	_apply_function_button_style(phone_btn, false)

	computer_btn.disabled = false
	computer_btn.modulate.a = 0.7
	_apply_function_button_style(computer_btn, false)

func _setup_attribute_dots() -> void:
	var configs := [
		{
			"path": "StatusBar/ModuleCanvas/AttrModule/AttrGroup/Knowledge/Dot",
			"color": ThemeColors.CARD_CLASS,
		},
		{
			"path": "StatusBar/ModuleCanvas/AttrModule/AttrGroup/Eloquence/Dot",
			"color": ThemeColors.CARD_SOCIAL,
		},
		{
			"path": "StatusBar/ModuleCanvas/AttrModule/AttrGroup/Physique/Dot",
			"color": ThemeColors.CARD_EXERCISE,
		},
		{
			"path": "StatusBar/ModuleCanvas/AttrModule/AttrGroup/Insight/Dot",
			"color": ThemeColors.CARD_EXPLORE,
		},
	]

	for config in configs:
		var dot := get_node_or_null(config["path"]) as ColorRect
		if dot == null:
			continue
		dot.color = config["color"]

func _bind_top_bar_hover_hints() -> void:
	var hints := [
		{"node": player_name_label, "text": "这里是玩家名字。"},
		{"node": energy_ind, "text": "精力决定你还能安排多少消耗体力的行动。"},
		{"node": mood_ind, "text": "心情反映你今天的状态，会影响整体节奏。"},
		{"node": money_ind, "text": "这里显示你当前可用的生活费。"},
		{"node": knowledge_ind, "text": "学识偏向课程、作业和知识积累。"},
		{"node": eloquence_ind, "text": "口才影响交流表达和社交表现。"},
		{"node": physique_ind, "text": "体魄反映运动能力和身体状态。"},
		{"node": insight_ind, "text": "见识偏向观察力、判断和对人事的理解。"},
		{"node": computer_btn, "text": "电脑入口还在制作中。"},
		{"node": phone_btn, "text": "手机里可以查看联系人和消息。"},
	]

	for item in hints:
		var node := item["node"] as Control
		if node == null:
			continue
		node.mouse_filter = Control.MOUSE_FILTER_STOP
		if not node.mouse_entered.is_connected(_on_hover_hint_changed.bind(node, item["text"], HoverHintMode.SHOW)):
			node.mouse_entered.connect(_on_hover_hint_changed.bind(node, item["text"], HoverHintMode.SHOW))
		if not node.mouse_exited.is_connected(_on_hover_hint_changed.bind(node, item["text"], HoverHintMode.HIDE)):
			node.mouse_exited.connect(_on_hover_hint_changed.bind(node, item["text"], HoverHintMode.HIDE))

func _on_hover_hint_changed(_node: Control, text: String, mode: int) -> void:
	if mode == HoverHintMode.SHOW:
		hover_context_text = text
		show_context_text(text, 1.4)
		return
	if hover_context_text == text:
		hover_context_text = ""
		if context_tween and is_instance_valid(context_tween):
			context_tween.kill()
		context_text.text = ""
		context_text.modulate.a = 0.0

func _apply_resource_bar_style(bar: ProgressBar, fill_color: Color) -> void:
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = RESOURCE_TRACK_COLOR
	bg_style.set_border_width_all(1)
	bg_style.border_color = RESOURCE_TRACK_BORDER
	bg_style.set_corner_radius_all(9)
	bg_style.content_margin_left = 2
	bg_style.content_margin_top = 2
	bg_style.content_margin_right = 2
	bg_style.content_margin_bottom = 2
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(7)
	bar.add_theme_stylebox_override("fill", fill_style)
	bar.add_theme_constant_override("outline_size", 0)
	bar.add_theme_font_size_override("font_size", 1)

func _update_confirm_button_style(enabled: bool) -> void:
	var btn_style = StyleBoxFlat.new()
	if enabled:
		btn_style.bg_color = ThemeColors.ACCENT
		confirm_btn.add_theme_color_override("font_color", ThemeColors.BG_PRIMARY)
	else:
		btn_style.bg_color = ThemeColors.TEXT_DISABLED
		confirm_btn.add_theme_color_override("font_color", ThemeColors.TEXT_SECONDARY)
	btn_style.set_corner_radius_all(8)
	confirm_btn.add_theme_stylebox_override("normal", btn_style)
	confirm_btn.add_theme_stylebox_override("hover", btn_style)
	confirm_btn.add_theme_stylebox_override("pressed", btn_style)
	confirm_btn.add_theme_stylebox_override("disabled", btn_style)

func update_view(game_state: Dictionary) -> void:
	var day = game_state.get("day", 1)
	var period = game_state.get("period", "morning")
	var phase = game_state.get("phase", "SCHEDULING")
	current_phase = phase

	# 更新资源显示
	var energy = game_state.get("energy", 7)
	var energy_max = game_state.get("energy_max", 10)
	var mood = game_state.get("mood", 6)
	var mood_max = game_state.get("mood_max", 10)
	var money = game_state.get("money", 200)

	energy_value.text = "%d/%d" % [energy, energy_max]
	energy_bar.max_value = energy_max
	_animate_progress_value(energy_bar, energy, true)
	_update_energy_color(energy, energy_max)

	mood_value.text = "%d/%d" % [mood, mood_max]
	mood_bar.max_value = mood_max
	_animate_progress_value(mood_bar, mood, false)
	_update_mood_color(mood)

	money_value.text = str(money)

	# 更新四维属性
	var attrs = game_state.get("attributes", {})
	knowledge_value.text = str(attrs.get("knowledge", 2))
	eloquence_value.text = str(attrs.get("eloquence", 2))
	physique_value.text = str(attrs.get("physique", 2))
	insight_value.text = str(attrs.get("insight", 2))
	player_name_label.text = str(game_state.get("player_name", "玩家名"))

	# 更新功能按钮状态
	var has_unread = game_state.get("has_unread_messages", false)
	_update_function_buttons(phase, has_unread)

	# 更新日期和时段
	var weekday = _get_weekday(day)
	day_label.text = "Day %02d · %s" % [day, weekday]
	period_label.text = "%s · 校园日景" % _get_period_name(period)

	# 更新时段条
	_update_period_bar(period, game_state.get("ap_remaining", 2))

	# 更新手牌标题
	title_label.text = "%s · 行动手牌" % _get_period_name(period)

func _animate_progress_value(bar: ProgressBar, target_value: float, is_energy: bool) -> void:
	var tween_ref: Tween = energy_value_tween if is_energy else mood_value_tween
	if tween_ref and is_instance_valid(tween_ref):
		tween_ref.kill()

	if is_zero_approx(bar.value - target_value):
		bar.value = target_value
		if is_energy:
			energy_value_tween = null
		else:
			mood_value_tween = null
		return

	tween_ref = create_tween()
	tween_ref.tween_property(bar, "value", target_value, 0.22)
	if is_energy:
		energy_value_tween = tween_ref
	else:
		mood_value_tween = tween_ref

func _update_energy_color(energy: int, _energy_max: int) -> void:
	var bar_style = energy_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	if energy > 5:
		bar_style.bg_color = ENERGY_BAR_HIGH
		_stop_energy_pulse()
	elif energy >= 3:
		bar_style.bg_color = ENERGY_BAR_MID
		_stop_energy_pulse()
	else:
		bar_style.bg_color = ThemeColors.DANGER_COLOR
		_start_energy_pulse()
	energy_bar.add_theme_stylebox_override("fill", bar_style)

func _update_mood_color(mood: int) -> void:
	var bar_style = mood_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	if mood >= 7:
		bar_style.bg_color = MOOD_BAR_HIGH
		_stop_mood_pulse()
	elif mood >= 4:
		bar_style.bg_color = MOOD_BAR_MID
		_stop_mood_pulse()
	else:
		bar_style.bg_color = ThemeColors.DANGER_COLOR
		_start_mood_pulse()
	mood_bar.add_theme_stylebox_override("fill", bar_style)

func load_cards(cards_data: Array) -> void:
	# 清除旧卡牌
	for card in current_cards:
		card.queue_free()
	current_cards.clear()
	selected_card_id = ""

	# 创建新卡牌
	for card_data in cards_data:
		var card = ActionCardScene.instantiate()
		card_row.add_child(card)
		card.setup(card_data)
		card.card_selected.connect(_on_card_selected)
		card.card_hovered.connect(_on_card_hovered)
		current_cards.append(card)

	detail_panel.visible = false
	_update_confirm_button_style(false)
	confirm_btn.disabled = true

func _on_card_selected(card_id: String) -> void:
	selected_card_id = card_id

	# 更新所有卡牌的选中状态
	for card in current_cards:
		card.set_selected(card.card_id == card_id)

	# 显示详情面板
	_show_card_detail(card_id)

	# 启用确认按钮
	_update_confirm_button_style(true)
	confirm_btn.disabled = false

	card_selected.emit(card_id)

func _on_card_hovered(_card_id: String) -> void:
	pass  # 可以添加 hover 提示

func _show_card_detail(card_id: String) -> void:
	var card_data: Dictionary = {}
	for card in current_cards:
		if card.card_id == card_id:
			card_data = card.card_data
			break

	if card_data.is_empty():
		return

	detail_card_name.text = str(card_data.get("display_name", ""))

	var category = _get_category_name(str(card_data.get("category", "")))
	var ap_cost = int(card_data.get("action_point_cost", 1))
	var energy_cost = int(card_data.get("energy_cost", 0))

	var cost_text = "大类：%s | 消耗：%d AP" % [category, ap_cost]
	if energy_cost > 0:
		cost_text += " · %d 精力" % energy_cost
	detail_card_info.text = cost_text

	# 构建效果文本
	_build_detail_effects(card_data)

	# 显示低精力警告
	var current_energy = int(energy_value.text.split("/")[0])
	low_energy_warning.visible = (current_energy <= 2)

	# 展开动画
	if not detail_panel.visible:
		detail_panel.modulate.a = 0
		detail_panel.visible = true
		var tween = create_tween()
		tween.tween_property(detail_panel, "modulate:a", 1.0, 0.2)

func _build_detail_effects(card_data: Dictionary) -> void:
	var text_parts: Array[String] = []

	# 属性效果
	var effects_data = card_data.get("effects", {})
	for key in effects_data:
		var value = int(effects_data[key])
		if value == 0:
			continue
		var color_tag = "[color=#5a9e8f]" if value > 0 else "[color=#d4564a]"
		text_parts.append("%s%s %+d[/color]" % [color_tag, key, value])

	# 关系效果（仅显示 visible: true 的）
	var rel_effects = card_data.get("relationship_effects", {})
	for npc_id in rel_effects:
		var rel_data = rel_effects[npc_id]
		if rel_data is Dictionary and rel_data.get("visible", true):
			var value = int(rel_data.get("value", 0))
			if value != 0:
				text_parts.append("[color=#e8a838]%s %+d[/color]" % [npc_id, value])

	if text_parts.is_empty():
		detail_content.text = "[color=#8890a4]无明显效果[/color]"
	else:
		detail_content.text = " · ".join(text_parts)

func show_context_text(text: String, duration: float = 2.0) -> void:
	context_text.text = text
	context_text.modulate.a = 0
	if context_tween and is_instance_valid(context_tween):
		context_tween.kill()
	context_tween = create_tween()
	context_tween.tween_property(context_text, "modulate:a", 1.0, 0.3)
	context_tween.tween_interval(duration)
	context_tween.tween_property(context_text, "modulate:a", 0.0, 0.5)

func _start_energy_pulse() -> void:
	if energy_pulse_tween and is_instance_valid(energy_pulse_tween):
		return
	energy_bar.modulate.a = 1.0
	energy_pulse_tween = create_tween()
	energy_pulse_tween.set_loops()
	energy_pulse_tween.tween_property(energy_bar, "modulate:a", 0.6, 0.4)
	energy_pulse_tween.tween_property(energy_bar, "modulate:a", 1.0, 0.4)

func _stop_energy_pulse() -> void:
	if energy_pulse_tween and is_instance_valid(energy_pulse_tween):
		energy_pulse_tween.kill()
	energy_pulse_tween = null
	energy_bar.modulate.a = 1.0

func _start_mood_pulse() -> void:
	if mood_pulse_tween and is_instance_valid(mood_pulse_tween):
		return
	mood_bar.modulate.a = 1.0
	mood_pulse_tween = create_tween()
	mood_pulse_tween.set_loops()
	mood_pulse_tween.tween_property(mood_bar, "modulate:a", 0.6, 0.4)
	mood_pulse_tween.tween_property(mood_bar, "modulate:a", 1.0, 0.4)

func _stop_mood_pulse() -> void:
	if mood_pulse_tween and is_instance_valid(mood_pulse_tween):
		mood_pulse_tween.kill()
	mood_pulse_tween = null
	mood_bar.modulate.a = 1.0

func _update_period_bar(current_period: String, ap_remaining: int) -> void:
	var periods = ["morning", "afternoon", "evening"]
	var current_index = periods.find(current_period)

	for i in range(3):
		var slot: Panel
		var status: Label
		var line: ColorRect = null

		match i:
			0:
				slot = morning_slot
				status = morning_status
				line = morning_line
			1:
				slot = afternoon_slot
				status = afternoon_status
			2:
				slot = evening_slot
				status = evening_status

		if i == current_index:
			_set_period_active(slot, status, line, ap_remaining)
		elif i < current_index:
			_set_period_finished(slot, status)
		else:
			_set_period_pending(slot, status)

func _set_period_active(slot: Panel, status: Label, line: ColorRect, ap: int) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(ThemeColors.ACCENT, 0.08)
	slot.add_theme_stylebox_override("panel", style)
	status.text = "进行中 · AP %d/2" % ap
	status.modulate = ThemeColors.TEXT_PRIMARY
	if line:
		line.visible = true

func _set_period_finished(slot: Panel, status: Label) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = ThemeColors.BG_DEEP
	slot.add_theme_stylebox_override("panel", style)
	status.text = "已结束"
	status.modulate = ThemeColors.TEXT_DISABLED

func _set_period_pending(slot: Panel, status: Label) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = ThemeColors.BG_DEEP
	slot.add_theme_stylebox_override("panel", style)
	status.text = "未开始"
	status.modulate = ThemeColors.TEXT_SECONDARY

func _get_period_name(period: String) -> String:
	match period:
		"morning": return "上午"
		"afternoon": return "下午"
		"evening": return "晚间"
		_: return period

func _get_category_name(category: String) -> String:
	match category:
		"class": return "上课"
		"social": return "社交"
		"rest": return "休息"
		"exercise": return "锻炼"
		"fun": return "娱乐"
		"nightlife": return "夜生活"
		"explore": return "探索"
		"work": return "兼职"
		_: return "行动"

func _get_weekday(day: int) -> String:
	var weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
	return weekdays[(day - 1) % 7]

func _on_phone_pressed() -> void:
	phone_button_pressed.emit()

func _on_computer_pressed() -> void:
	computer_button_pressed.emit()

func _on_confirm_pressed() -> void:
	if not selected_card_id.is_empty():
		confirm_action_pressed.emit()
