extends Control

signal card_selected(card_id: String)
signal confirm_action_pressed
signal phone_button_pressed
signal computer_button_pressed

const ActionCardScene = preload("res://scenes/ui/components/action_card.tscn")

# 状态栏节点
@onready var energy_value: Label = $StatusBar/HBox/ResourceGroup/EnergyInd/Value
@onready var energy_bar: ProgressBar = $StatusBar/HBox/ResourceGroup/EnergyInd/Bar
@onready var mood_value: Label = $StatusBar/HBox/ResourceGroup/MoodInd/Value
@onready var mood_bar: ProgressBar = $StatusBar/HBox/ResourceGroup/MoodInd/Bar
@onready var money_value: Label = $StatusBar/HBox/ResourceGroup/MoneyInd/Value

@onready var knowledge_value: Label = $StatusBar/HBox/AttrGroup/Knowledge/Value
@onready var eloquence_value: Label = $StatusBar/HBox/AttrGroup/Eloquence/Value
@onready var physique_value: Label = $StatusBar/HBox/AttrGroup/Physique/Value
@onready var insight_value: Label = $StatusBar/HBox/AttrGroup/Insight/Value

@onready var phone_btn: TextureButton = $StatusBar/HBox/FuncBtns/PhoneBtn
@onready var unread_dot: ColorRect = $StatusBar/HBox/FuncBtns/PhoneBtn/UnreadDot
@onready var computer_btn: TextureButton = $StatusBar/HBox/FuncBtns/ComputerBtn

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

func _ready() -> void:
	phone_btn.pressed.connect(_on_phone_pressed)
	computer_btn.pressed.connect(_on_computer_pressed)
	confirm_btn.pressed.connect(_on_confirm_pressed)

	_setup_styles()
	detail_panel.visible = false

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
	var energy_bar_style = StyleBoxFlat.new()
	energy_bar_style.bg_color = ThemeColors.ENERGY_COLOR
	energy_bar_style.set_corner_radius_all(2)
	energy_bar.add_theme_stylebox_override("fill", energy_bar_style)

	# 心情条样式
	var mood_bar_style = StyleBoxFlat.new()
	mood_bar_style.bg_color = ThemeColors.ACCENT
	mood_bar_style.set_corner_radius_all(2)
	mood_bar.add_theme_stylebox_override("fill", mood_bar_style)

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
	var money = game_state.get("money", 200)

	energy_value.text = "%d/%d" % [energy, energy_max]
	energy_bar.max_value = energy_max
	energy_bar.value = energy
	_update_energy_color(energy, energy_max)

	mood_value.text = str(mood)
	mood_bar.value = mood
	_update_mood_color(mood)

	money_value.text = str(money)

	# 更新四维属性
	var attrs = game_state.get("attributes", {})
	knowledge_value.text = str(attrs.get("knowledge", 2))
	eloquence_value.text = str(attrs.get("eloquence", 2))
	physique_value.text = str(attrs.get("physique", 2))
	insight_value.text = str(attrs.get("insight", 2))

	# 更新手机按钮状态
	var has_unread = game_state.get("has_unread_messages", false)
	unread_dot.visible = has_unread

	# 排班阶段手机按钮不可用
	if phase == "SCHEDULING":
		phone_btn.modulate.a = 0.3
		phone_btn.disabled = true
	else:
		phone_btn.modulate.a = 0.7
		phone_btn.disabled = false

	# 更新日期和时段
	var weekday = _get_weekday(day)
	day_label.text = "Day %02d · %s" % [day, weekday]
	period_label.text = "%s · 校园日景" % _get_period_name(period)

	# 更新时段条
	_update_period_bar(period, game_state.get("ap_remaining", 2))

	# 更新手牌标题
	title_label.text = "%s · 行动手牌" % _get_period_name(period)

func _update_energy_color(energy: int, energy_max: int) -> void:
	var bar_style = energy_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	if energy > 5:
		bar_style.bg_color = ThemeColors.ENERGY_COLOR
	elif energy >= 3:
		bar_style.bg_color = ThemeColors.ACCENT
	else:
		bar_style.bg_color = ThemeColors.DANGER_COLOR
		# 低精力脉冲动画
		if not has_node("EnergyPulseTween"):
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(energy_bar, "modulate:a", 0.6, 0.4)
			tween.tween_property(energy_bar, "modulate:a", 1.0, 0.4)
	energy_bar.add_theme_stylebox_override("fill", bar_style)

func _update_mood_color(mood: int) -> void:
	var bar_style = mood_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	if mood >= 7:
		bar_style.bg_color = ThemeColors.ACCENT
	elif mood >= 4:
		bar_style.bg_color = ThemeColors.TEXT_SECONDARY
	else:
		bar_style.bg_color = ThemeColors.DANGER_COLOR
		# 低心情脉冲动画
		if not has_node("MoodPulseTween"):
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(mood_bar, "modulate:a", 0.6, 0.4)
			tween.tween_property(mood_bar, "modulate:a", 1.0, 0.4)
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

func _on_card_hovered(card_id: String) -> void:
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

	var tween = create_tween()
	tween.tween_property(context_text, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration)
	tween.tween_property(context_text, "modulate:a", 0.0, 0.5)

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
