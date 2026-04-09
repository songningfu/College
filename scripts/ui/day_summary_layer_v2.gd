extends CanvasLayer

signal next_day_pressed
signal phone_cta_pressed

@onready var day_title: Label = $SummaryPanel/VBox/Header/DayTitle
@onready var flavor_text: Label = $SummaryPanel/VBox/Header/FlavorText
@onready var morning_act: Label = $SummaryPanel/VBox/ContentRow/ActionCol/ActionList/MorningAct
@onready var afternoon_act: Label = $SummaryPanel/VBox/ContentRow/ActionCol/ActionList/AfternoonAct
@onready var evening_act: Label = $SummaryPanel/VBox/ContentRow/ActionCol/ActionList/EveningAct
@onready var event_list: VBoxContainer = $SummaryPanel/VBox/ContentRow/ActionCol/EventList
@onready var stats_rows: VBoxContainer = $SummaryPanel/VBox/ContentRow/StatsCol/StatsRows
@onready var npc_grid: HBoxContainer = $SummaryPanel/VBox/RelationSection/NPCGrid
@onready var phone_cta: Button = $SummaryPanel/VBox/BtnRow/PhoneCTA
@onready var next_day_btn: Button = $SummaryPanel/VBox/BtnRow/NextDayBtn

func _ready() -> void:
	_setup_styles()
	phone_cta.pressed.connect(_on_phone_cta_pressed)
	next_day_btn.pressed.connect(_on_next_day_pressed)

func _setup_styles() -> void:
	# 面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(ThemeColors.BG_PRIMARY, 0.96)
	panel_style.set_corner_radius_all(16)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(1, 1, 1, 0.08)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 32
	panel_style.shadow_offset = Vector2(0, 8)
	$SummaryPanel.add_theme_stylebox_override("panel", panel_style)

	# 手机 CTA 按钮样式
	var phone_style = StyleBoxFlat.new()
	phone_style.bg_color = ThemeColors.ACCENT
	phone_style.set_corner_radius_all(8)
	phone_cta.add_theme_stylebox_override("normal", phone_style)
	phone_cta.add_theme_color_override("font_color", ThemeColors.BG_PRIMARY)
	phone_cta.add_theme_font_size_override("font_size", 16)

	# 脉冲动画
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(phone_cta, "modulate:a", 0.8, 0.4)
	pulse_tween.tween_property(phone_cta, "modulate:a", 1.0, 0.4)

	# 下一天按钮样式
	_update_next_day_button_style(false)

func _update_next_day_button_style(has_unread: bool) -> void:
	var next_style = StyleBoxFlat.new()
	if has_unread:
		next_style.bg_color = ThemeColors.TEXT_DISABLED
		next_day_btn.add_theme_color_override("font_color", ThemeColors.TEXT_SECONDARY)
	else:
		next_style.bg_color = ThemeColors.ACCENT
		next_day_btn.add_theme_color_override("font_color", ThemeColors.BG_PRIMARY)
	next_style.set_corner_radius_all(8)
	next_day_btn.add_theme_stylebox_override("normal", next_style)
	next_day_btn.add_theme_font_size_override("font_size", 16)

func show_layer(summary_data: Dictionary) -> void:
	visible = true

	# 设置标题
	var day = summary_data.get("day", 1)
	var weekday = _get_weekday(day)
	day_title.text = "Day %02d 结束 · %s" % [day, weekday]
	flavor_text.text = str(summary_data.get("flavor_text", ""))

	# 设置行动记录
	var actions = summary_data.get("actions", {})
	morning_act.text = "上午：%s" % str(actions.get("morning", "无"))
	afternoon_act.text = "下午：%s" % str(actions.get("afternoon", "无"))
	evening_act.text = "晚间：%s" % str(actions.get("evening", "无"))

	# 设置事件列表
	_load_events(summary_data.get("events", []))

	# 设置数值变化
	_load_stats(summary_data.get("stats_changes", {}))

	# 设置关系变化
	_load_relations(summary_data.get("relation_changes", []))

	# 设置按钮状态
	var has_unread = summary_data.get("has_unread_messages", false)
	phone_cta.visible = has_unread
	_update_next_day_button_style(has_unread)

	# 淡入动画
	$SummaryPanel.modulate.a = 0
	var tween = create_tween()
	tween.tween_property($SummaryPanel, "modulate:a", 1.0, 0.3)

func _load_events(events: Array) -> void:
	# 清除旧事件
	for child in event_list.get_children():
		child.queue_free()

	# 添加事件
	for event in events:
		var event_label = Label.new()
		event_label.text = "· %s" % str(event)
		event_label.add_theme_color_override("font_color", ThemeColors.ACCENT)
		event_label.add_theme_font_size_override("font_size", 14)
		event_list.add_child(event_label)

func _load_stats(stats: Dictionary) -> void:
	# 清除旧数据
	for child in stats_rows.get_children():
		child.queue_free()

	# 属性变化
	var attributes = ["knowledge", "eloquence", "physique", "insight"]
	var attr_names = {"knowledge": "学识", "eloquence": "口才", "physique": "体魄", "insight": "见识"}

	for attr in attributes:
		if attr in stats:
			var change = stats[attr]
			_add_stat_row(attr_names[attr], change)

	# 添加间隔
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	stats_rows.add_child(spacer)

	# 资源变化
	var resources = ["energy", "mood", "money"]
	var resource_names = {"energy": "精力", "mood": "心情", "money": "金钱"}

	for res in resources:
		if res in stats:
			var change = stats[res]
			_add_stat_row(resource_names[res], change)

func _add_stat_row(label_text: String, change: Dictionary) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	stats_rows.add_child(row)

	# 属性名
	var name_label = Label.new()
	name_label.text = label_text
	name_label.custom_minimum_size = Vector2(60, 0)
	name_label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", 14)
	row.add_child(name_label)

	# 数值变化
	var old_val = change.get("old", 0)
	var new_val = change.get("new", 0)
	var diff = new_val - old_val

	var value_label = Label.new()
	value_label.text = "%d→%d" % [old_val, new_val]
	value_label.add_theme_font_size_override("font_size", 16)
	row.add_child(value_label)

	# 箭头
	if diff > 0:
		var arrow = Label.new()
		arrow.text = "↑"
		arrow.add_theme_color_override("font_color", ThemeColors.ENERGY_COLOR)
		arrow.add_theme_font_size_override("font_size", 16)
		row.add_child(arrow)
	elif diff < 0:
		var arrow = Label.new()
		arrow.text = "↓"
		arrow.add_theme_color_override("font_color", ThemeColors.DANGER_COLOR)
		arrow.add_theme_font_size_override("font_size", 16)
		row.add_child(arrow)

func _load_relations(relations: Array) -> void:
	# 清除旧卡片
	for child in npc_grid.get_children():
		child.queue_free()

	# 添加 NPC 关系卡片
	for rel in relations:
		var card = _create_npc_card(rel)
		npc_grid.add_child(card)

func _create_npc_card(rel_data: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 64)

	# 卡片样式
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = ThemeColors.BG_PANEL
	card_style.set_corner_radius_all(8)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(1, 1, 1, 0.08)
	card.add_theme_stylebox_override("panel", card_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)

	# 头像
	var avatar = TextureRect.new()
	avatar.custom_minimum_size = Vector2(32, 32)
	avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# TODO: 设置头像纹理
	hbox.add_child(avatar)

	# 信息
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	# 名称
	var name_label = Label.new()
	name_label.text = str(rel_data.get("name", ""))
	name_label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(name_label)

	# 好感值
	var relation_hbox = HBoxContainer.new()
	relation_hbox.add_theme_constant_override("separation", 4)
	vbox.add_child(relation_hbox)

	var value = rel_data.get("value", 0)
	var change = rel_data.get("change", 0)

	var value_label = Label.new()
	value_label.text = str(value)
	value_label.add_theme_font_size_override("font_size", 16)
	relation_hbox.add_child(value_label)

	if change != 0:
		var change_label = Label.new()
		change_label.text = "(%+d)" % change
		if change > 0:
			change_label.add_theme_color_override("font_color", ThemeColors.ENERGY_COLOR)
		elif change < 0:
			change_label.add_theme_color_override("font_color", ThemeColors.DANGER_COLOR)
		else:
			change_label.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
		change_label.add_theme_font_size_override("font_size", 14)
		relation_hbox.add_child(change_label)

	return card

func _get_weekday(day: int) -> String:
	var weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
	return weekdays[(day - 1) % 7]

func _on_phone_cta_pressed() -> void:
	phone_cta_pressed.emit()

func _on_next_day_pressed() -> void:
	next_day_pressed.emit()

	# 淡出动画
	var tween = create_tween()
	tween.tween_property($SummaryPanel, "modulate:a", 0.0, 0.3)
	await tween.finished
	visible = false
