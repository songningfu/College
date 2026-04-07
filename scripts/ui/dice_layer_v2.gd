extends CanvasLayer

signal dice_finished

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var dice_panel: PanelContainer = $DicePanel
@onready var event_title: Label = $DicePanel/VBox/Header/EventTitle
@onready var attr_label: Label = $DicePanel/VBox/Header/AttrLabel
@onready var left_die: Panel = $DicePanel/VBox/DiceRow/LeftDie
@onready var left_val: Label = $DicePanel/VBox/DiceRow/LeftDie/DieVal
@onready var right_die: Panel = $DicePanel/VBox/DiceRow/RightDie
@onready var right_val: Label = $DicePanel/VBox/DiceRow/RightDie/DieVal
@onready var modifier_text: Label = $DicePanel/VBox/ModifierText
@onready var roll_btn: Button = $DicePanel/VBox/RollBtn
@onready var calc_label: Label = $DicePanel/VBox/CalcLabel
@onready var divider: ColorRect = $DicePanel/VBox/Divider
@onready var result_section: VBoxContainer = $DicePanel/VBox/ResultSection
@onready var result_title: Label = $DicePanel/VBox/ResultSection/ResultTitle
@onready var result_desc: RichTextLabel = $DicePanel/VBox/ResultSection/ResultDesc
@onready var result_stats: Label = $DicePanel/VBox/ResultSection/ResultStats
@onready var continue_btn: Button = $DicePanel/VBox/ContinueBtn
@onready var result_glow: ColorRect = $DicePanel/ResultGlow

var dice_data: Dictionary = {}
var roll_result: Dictionary = {}

func _ready() -> void:
	_setup_styles()
	roll_btn.pressed.connect(_on_roll_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)

func _setup_styles() -> void:
	# 面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(ThemeColors.BG_PRIMARY, 0.96)
	panel_style.set_corner_radius_all(16)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(1, 1, 1, 0.1)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 32
	panel_style.shadow_offset = Vector2(0, 8)
	dice_panel.add_theme_stylebox_override("panel", panel_style)

	# 骰子样式
	_setup_die_style(left_die)
	_setup_die_style(right_die)

	# 掷骰按钮样式
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = ThemeColors.ACCENT
	btn_style.set_corner_radius_all(8)
	roll_btn.add_theme_stylebox_override("normal", btn_style)
	roll_btn.add_theme_color_override("font_color", ThemeColors.BG_PRIMARY)
	roll_btn.add_theme_font_size_override("font_size", 18)

	var btn_hover = btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(ThemeColors.ACCENT_LIGHT)
	roll_btn.add_theme_stylebox_override("hover", btn_hover)

	# 继续按钮样式
	var continue_style = StyleBoxFlat.new()
	continue_style.bg_color = ThemeColors.BG_PANEL
	continue_style.set_corner_radius_all(8)
	continue_style.border_width_left = 1
	continue_style.border_width_top = 1
	continue_style.border_width_right = 1
	continue_style.border_width_bottom = 1
	continue_style.border_color = Color(1, 1, 1, 0.1)
	continue_btn.add_theme_stylebox_override("normal", continue_style)
	continue_btn.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)

	var continue_hover = continue_style.duplicate() as StyleBoxFlat
	continue_hover.border_color = ThemeColors.ACCENT
	continue_btn.add_theme_stylebox_override("hover", continue_hover)

func _setup_die_style(die: Panel) -> void:
	var die_style = StyleBoxFlat.new()
	die_style.bg_color = ThemeColors.BG_HOVER
	die_style.set_corner_radius_all(12)
	die_style.border_width_left = 2
	die_style.border_width_top = 2
	die_style.border_width_right = 2
	die_style.border_width_bottom = 2
	die_style.border_color = Color(1, 1, 1, 0.12)
	die.add_theme_stylebox_override("panel", die_style)

func show_layer(data: Dictionary) -> void:
	dice_data = data
	visible = true

	# 设置初始状态
	event_title.text = str(data.get("event_name", "判定"))
	attr_label.text = "判定属性：%s" % str(data.get("attribute", "未知"))
	modifier_text.text = str(data.get("modifier_description", ""))

	left_val.text = "?"
	right_val.text = "?"
	roll_btn.visible = true
	calc_label.visible = false
	divider.visible = false
	result_section.visible = false
	continue_btn.visible = false
	result_glow.visible = false

	# 淡入动画
	dim_overlay.modulate.a = 0
	dice_panel.modulate.a = 0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_overlay, "modulate:a", 1.0, 0.3)
	tween.tween_property(dice_panel, "modulate:a", 1.0, 0.3)

func _on_roll_pressed() -> void:
	roll_btn.visible = false
	_start_rolling()

func _start_rolling() -> void:
	# 阶段二：滚动动画
	var roll_timer = Timer.new()
	add_child(roll_timer)
	roll_timer.wait_time = 0.05
	roll_timer.timeout.connect(_on_roll_tick)

	var roll_count = 0
	var max_rolls = 16  # 800ms / 50ms

	roll_timer.timeout.connect(func():
		roll_count += 1
		left_val.text = str(randi_range(1, 6))
		right_val.text = str(randi_range(1, 6))

		# 抖动动画
		left_die.position.y = randf_range(-4, 4)
		left_die.rotation_degrees = randf_range(-3, 3)
		right_die.position.y = randf_range(-4, 4)
		right_die.rotation_degrees = randf_range(-3, 3)

		# 边框变色
		var die_style = left_die.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		die_style.border_color = Color(ThemeColors.ACCENT, 0.4)
		left_die.add_theme_stylebox_override("panel", die_style)
		right_die.add_theme_stylebox_override("panel", die_style.duplicate())

		if roll_count >= max_rolls:
			roll_timer.stop()
			_finish_rolling()
	)

	roll_timer.start()

func _on_roll_tick() -> void:
	pass  # 由闭包处理

func _finish_rolling() -> void:
	# 生成最终结果
	var die1 = randi_range(1, 6)
	var die2 = randi_range(1, 6)
	var modifier = int(dice_data.get("modifier", 0))
	var total = die1 + die2 + modifier

	roll_result = {
		"die1": die1,
		"die2": die2,
		"modifier": modifier,
		"total": total
	}

	# 左骰定格
	await get_tree().create_timer(0.1).timeout
	_settle_die(left_die, left_val, die1)

	# 右骰定格
	await get_tree().create_timer(0.2).timeout
	_settle_die(right_die, right_val, die2)

	# 面板震动
	var shake_tween = create_tween()
	shake_tween.tween_property(dice_panel, "position:x", dice_panel.position.x + 2, 0.025)
	shake_tween.tween_property(dice_panel, "position:x", dice_panel.position.x, 0.025)

	# 等待后显示结果
	await get_tree().create_timer(0.4).timeout
	_show_result()

func _settle_die(die: Panel, val_label: Label, value: int) -> void:
	val_label.text = str(value)

	# 弹跳动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(die, "position:y", 0, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(die, "rotation_degrees", 0, 0.1).set_ease(Tween.EASE_OUT)

	# 边框闪白
	var flash_style = die.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	flash_style.border_color = Color(1, 1, 1, 0.6)
	die.add_theme_stylebox_override("panel", flash_style)

	await tween.finished

	var fade_tween = create_tween()
	fade_tween.tween_property(flash_style, "border_color", Color(1, 1, 1, 0.12), 0.15)

func _show_result() -> void:
	# 扩展面板
	var expand_tween = create_tween()
	expand_tween.tween_property(dice_panel, "custom_minimum_size:y", 640, 0.3)
	await expand_tween.finished

	# 显示计算式
	calc_label.visible = true
	var die1 = roll_result["die1"]
	var die2 = roll_result["die2"]
	var modifier = roll_result["modifier"]
	var total = roll_result["total"]

	# 逐步显示计算
	calc_label.text = str(die1)
	await get_tree().create_timer(0.2).timeout
	calc_label.text = "%d + %d" % [die1, die2]
	await get_tree().create_timer(0.2).timeout

	if modifier != 0:
		var mod_color = "[color=#5a9e8f]" if modifier > 0 else "[color=#d4564a]"
		calc_label.text = "%d + %d %s%+d[/color]" % [die1, die2, mod_color, modifier]
		await get_tree().create_timer(0.2).timeout

	calc_label.text = "%d + %d + %d = %d" % [die1, die2, modifier, total]

	# 显示分隔线和结果
	await get_tree().create_timer(0.3).timeout
	divider.visible = true
	result_section.visible = true
	continue_btn.visible = true

	# 根据结果设置样式
	_apply_result_style(total)

func _apply_result_style(total: int) -> void:
	var threshold = int(dice_data.get("threshold", 10))
	var result_type = ""

	if total >= threshold + 4:
		result_type = "critical_success"
		result_title.text = "大成功！"
		result_title.add_theme_color_override("font_color", ThemeColors.ACCENT_LIGHT)
		result_title.add_theme_font_size_override("font_size", 28)
		result_glow.visible = true
		result_glow.color = Color(ThemeColors.ACCENT, 0.06)
		_update_die_border(ThemeColors.ACCENT_LIGHT)
	elif total >= threshold:
		result_type = "success"
		result_title.text = "成功"
		result_title.add_theme_color_override("font_color", ThemeColors.ENERGY_COLOR)
		result_title.add_theme_font_size_override("font_size", 24)
		_update_die_border(ThemeColors.ENERGY_COLOR)
	elif total >= threshold - 2:
		result_type = "partial_success"
		result_title.text = "还行"
		result_title.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
		result_title.add_theme_font_size_override("font_size", 22)
	elif total >= threshold - 4:
		result_type = "failure"
		result_title.text = "失败"
		result_title.add_theme_color_override("font_color", ThemeColors.FAIL_GREY)
		result_title.add_theme_font_size_override("font_size", 22)
		dice_panel.modulate = Color(0.95, 0.95, 0.95)
	else:
		result_type = "critical_failure"
		result_title.text = "搞砸了…"
		result_title.add_theme_color_override("font_color", ThemeColors.FAIL_DARK)
		result_title.add_theme_font_size_override("font_size", 24)
		result_glow.visible = true
		result_glow.color = Color(ThemeColors.FAIL_DARK, 0.08)

	# 设置结果描述和数值
	var result_data = dice_data.get("results", {}).get(result_type, {})
	result_desc.text = "[center]%s[/center]" % str(result_data.get("description", ""))
	result_stats.text = str(result_data.get("effects_summary", ""))

func _update_die_border(color: Color) -> void:
	var left_style = left_die.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	left_style.border_color = color
	left_die.add_theme_stylebox_override("panel", left_style)

	var right_style = right_die.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	right_style.border_color = color
	right_die.add_theme_stylebox_override("panel", right_style)

func _on_continue_pressed() -> void:
	# 淡出动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_property(dice_panel, "modulate:a", 0.0, 0.3)
	await tween.finished

	visible = false
	dice_finished.emit(roll_result)
