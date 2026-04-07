extends Button

signal choice_pressed

@onready var choice_text: Label = $HBox/ChoiceText
@onready var choice_icon: Label = $HBox/IconContainer/Icon
@onready var cost_label: Label = $HBox/IconContainer/CostLabel

var choice_data: Dictionary = {}
var is_available: bool = true

func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_setup_styles()

func _setup_styles() -> void:
	# 默认样式
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(ThemeColors.BG_PANEL, 0.92)
	normal_style.set_corner_radius_all(8)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(1, 1, 1, 0.1)
	add_theme_stylebox_override("normal", normal_style)

	# hover 样式
	var hover_style = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = ThemeColors.BG_HOVER
	hover_style.border_color = Color(ThemeColors.ACCENT, 0.6)
	add_theme_stylebox_override("hover", hover_style)

	# pressed 样式
	var pressed_style = hover_style.duplicate() as StyleBoxFlat
	add_theme_stylebox_override("pressed", pressed_style)

	# disabled 样式
	var disabled_style = normal_style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(ThemeColors.BG_PANEL, 0.4)
	add_theme_stylebox_override("disabled", disabled_style)

func setup(data: Dictionary) -> void:
	choice_data = data

	var text_content = str(data.get("text", "选项"))
	choice_text.text = text_content

	# 检查选项类型
	var has_dice = data.get("requires_dice", false)
	var cost = data.get("cost", 0)
	var requires_relation = data.get("requires_relation", 0)

	# 设置图标
	if has_dice:
		choice_icon.text = "🎲"
		choice_icon.visible = true
	elif cost > 0:
		choice_icon.text = "💰"
		cost_label.text = "-%d" % cost
		choice_icon.visible = true
		cost_label.visible = true
	elif requires_relation > 0:
		choice_icon.text = "❤"
		choice_icon.modulate.a = 0.4
		choice_icon.visible = true
	else:
		choice_icon.visible = false
		cost_label.visible = false

	# 检查是否可用
	is_available = data.get("available", true)
	disabled = not is_available

	if not is_available:
		choice_text.modulate = Color(ThemeColors.TEXT_DISABLED)
		modulate.a = 0.4

func _on_mouse_entered() -> void:
	if is_available:
		# 添加前缀箭头
		if not choice_text.text.begins_with("▸ "):
			choice_text.text = "▸ " + choice_text.text

func _on_mouse_exited() -> void:
	# 移除前缀箭头
	if choice_text.text.begins_with("▸ "):
		choice_text.text = choice_text.text.substr(2)

func _on_pressed() -> void:
	if is_available:
		# 点击缩放动画
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(0.97, 0.97), 0.05)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05)

		# 底色闪烁
		var flash_style = get_theme_stylebox("pressed").duplicate() as StyleBoxFlat
		flash_style.bg_color = Color(ThemeColors.ACCENT, 0.2)
		add_theme_stylebox_override("pressed", flash_style)

		choice_pressed.emit()
