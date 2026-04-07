extends Control

signal card_selected(card_id: String)
signal confirm_action_pressed
signal phone_button_pressed
signal computer_button_pressed

const ActionCardScene = preload("res://scenes/ui/components/action_card.tscn")

# 状态栏
@onready var status_bar: PanelContainer = $StatusBar
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

# 中景舞台区
@onready var stage_area: Control = $StageArea
@onready var day_label: Label = $StageArea/DayLabel
@onready var period_label: Label = $StageArea/PeriodLabel
@onready var context_text: Label = $StageArea/ContextText

# 时段条
@onready var period_bar: PanelContainer = $PeriodBar
@onready var morning_slot: Panel = $PeriodBar/HBox/MorningSlot
@onready var morning_status: Label = $PeriodBar/HBox/MorningSlot/HBox/Status
@onready var afternoon_slot: Panel = $PeriodBar/HBox/AfternoonSlot
@onready var afternoon_status: Label = $PeriodBar/HBox/AfternoonSlot/HBox/Status
@onready var evening_slot: Panel = $PeriodBar/HBox/EveningSlot
@onready var evening_status: Label = $PeriodBar/HBox/EveningSlot/HBox/Status

# 手牌区
@onready var hand_area: PanelContainer = $HandArea
@onready var title_label: Label = $HandArea/VBox/TitleRow/Title
@onready var confirm_btn: Button = $HandArea/VBox/TitleRow/ConfirmBtn
@onready var card_row: HBoxContainer = $HandArea/VBox/CardRow
@onready var detail_panel: Panel = $HandArea/VBox/DetailPanel
@onready var detail_content: RichTextLabel = $HandArea/VBox/DetailPanel/MarginContainer/DetailContent

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
	status_bar.add_theme_stylebox_override("panel", status_style)

	# 时段条样式
	var period_style = StyleBoxFlat.new()
	period_style.bg_color = ThemeColors.BG_DEEP
	period_style.border_width_top = 1
	period_style.border_width_bottom = 1
	period_style.border_color = Color(1, 1, 1, 0.06)
	period_bar.add_theme_stylebox_override("panel", period_style)

	# 手牌区样式
	var hand_style = StyleBoxFlat.new()
	hand_style.bg_color = Color(ThemeColors.BG_PANEL, 0.9)
	hand_style.border_width_top = 1
	hand_style.border_color = Color(1, 1, 1, 0.1)
	hand_area.add_theme_stylebox_override("panel", hand_style)

	# 确认按钮样式
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = ThemeColors.ACCENT
	btn_style.set_corner_radius_all(8)
	confirm_btn.add_theme_stylebox_override("normal", btn_style)
	confirm_btn.add_theme_stylebox_override("hover", btn_style)
	confirm_btn.add_theme_stylebox_override("pressed", btn_style)

	var btn_disabled = StyleBoxFlat.new()
	btn_disabled.bg_color = ThemeColors.TEXT_DISABLED
	btn_disabled.set_corner_radius_all(8)
	confirm_btn.add_theme_stylebox_override("disabled", btn_disabled)

func update_view(game_state: Dictionary) -> void:
	var day = game_state.get("day", 1)
	var period = game_state.get("period", "morning")
	var phase = game_state.get("phase", "SCHEDULING")
	current_phase = phase

	# 更新状态栏资源
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

func load_cards(cards_data: Array) -> void:
	# 清空现有卡牌
	for card in current_cards:
		card.queue_free()
	current_cards.clear()

	# 创建新卡牌
	for card_data in cards_data:
		var card = ActionCardScene.instantiate()
		card_row.add_child(card)
		card.setup(card_data)
		card.card_selected.connect(_on_card_selected)
		card.card_hovered.connect(_on_card_hovered)
		card.card_unhovered.connect(_on_card_unhovered)
		current_cards.append(card)

	# 居中对齐
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER

func _on_card_selected(card_id: String) -> void:
	if selected_card_id == card_id:
		# 取消选择
		selected_card_id = ""
		_update_card_selection()
		detail_panel.visible = false
	else:
		# 选择新卡
		selected_card_id = card_id
		_update_card_selection()
		_show_card_detail(card_id)

	card_selected.emit(card_id)

func _on_card_hovered(card_id: String) -> void:
	pass

func _on_card_unhovered(card_id: String) -> void:
	pass

func _update_card_selection() -> void:
	for card in current_cards:
		var is_selected = (card.card_id == selected_card_id)
		card.set_selected(is_selected)

		# 未选中的卡片半透明
		if selected_card_id != "" and not is_selected:
			card.modulate.a = 0.6
		else:
			card.modulate.a = 1.0

	# 更新确认按钮
	confirm_btn.disabled = selected_card_id.is_empty()

func _show_card_detail(card_id: String) -> void:
	# 找到对应卡牌数据
	var card_node: Node = null
	for card in current_cards:
		if card.card_id == card_id:
			card_node = card
			break

	if not card_node:
		return

	var data = card_node.card_data
	var text = "[b]%s[/b]\n\n" % data.get("display_name", "")
	text += "[color=#8890a4]大类：%s | 消耗：%d AP" % [
		_get_category_name(data.get("category", "")),
		data.get("action_point_cost", 1)
	]

	var energy_cost = data.get("energy_cost", 0)
	if energy_cost > 0:
		text += " · %d 精力" % energy_cost

	text += "[/color]\n\n"

	# 效果列表
	var effects = data.get("effects", {})
	if not effects.is_empty():
		text += "[color=#e8e8e8]效果：[/color]\n"
		for key in effects:
			var value = effects[key]
			var color = "#5a9e8f" if value > 0 else "#d4564a"
			text += "[color=%s]%s %+d[/color]\n" % [color, key, value]

	detail_content.text = text

	# 展开动画
	if not detail_panel.visible:
		detail_panel.modulate.a = 0
		detail_panel.visible = true
		var tween = create_tween()
		tween.tween_property(detail_panel, "modulate:a", 1.0, 0.2)

func show_context_text(text: String) -> void:
	context_text.text = text
	context_text.modulate.a = 0
	context_text.visible = true

	var tween = create_tween()
	tween.tween_property(context_text, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(context_text, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): context_text.visible = false)

func _update_energy_color(energy: int, energy_max: int) -> void:
	var ratio = float(energy) / float(energy_max)
	if ratio > 0.5:
		energy_bar.modulate = ThemeColors.ENERGY_COLOR
	elif ratio > 0.2:
		energy_bar.modulate = ThemeColors.ACCENT
	else:
		energy_bar.modulate = ThemeColors.DANGER_COLOR
		_start_pulse_animation(energy_bar)

func _update_mood_color(mood: int) -> void:
	if mood >= 7:
		mood_bar.modulate = ThemeColors.ACCENT
	elif mood >= 4:
		mood_bar.modulate = ThemeColors.TEXT_SECONDARY
	else:
		mood_bar.modulate = ThemeColors.DANGER_COLOR
		_start_pulse_animation(mood_bar)

func _start_pulse_animation(node: Control) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(node, "modulate:a", 0.6, 0.4)
	tween.tween_property(node, "modulate:a", 1.0, 0.4)

func _update_period_bar(current_period: String, ap: int) -> void:
	var periods = ["morning", "afternoon", "evening"]
	var slots = [morning_slot, afternoon_slot, evening_slot]
	var status_labels = [morning_status, afternoon_status, evening_status]

	for i in range(3):
		var period = periods[i]
		var slot = slots[i]
		var status = status_labels[i]

		if period == current_period:
			# 进行中
			_set_period_active(slot, status, ap)
		elif periods.find(period) < periods.find(current_period):
			# 已结束
			_set_period_finished(slot, status)
		else:
			# 未开始
			_set_period_pending(slot, status)

func _set_period_active(slot: Panel, status: Label, ap: int) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(ThemeColors.ACCENT, 0.08)
	style.border_width_left = 3
	style.border_color = ThemeColors.ACCENT
	slot.add_theme_stylebox_override("panel", style)
	status.text = "进行中 · AP %d/2" % ap
	status.modulate = ThemeColors.TEXT_PRIMARY

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
