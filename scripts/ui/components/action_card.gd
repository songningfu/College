extends PanelContainer

signal card_selected(card_id: String)
signal card_hovered(card_id: String)
signal card_unhovered(card_id: String)

@onready var category_zone: Panel = $VBox/CategoryZone
@onready var category_bg: ColorRect = $VBox/CategoryZone/CategoryBg
@onready var category_icon: Label = $VBox/CategoryZone/CategoryIcon
@onready var category_name: Label = $VBox/CategoryZone/CategoryName
@onready var ap_badge: Panel = $VBox/CategoryZone/APBadge
@onready var ap_value: Label = $VBox/CategoryZone/APBadge/APValue
@onready var class_tag: Panel = $VBox/CategoryZone/ClassTag
@onready var class_tag_label: Label = $VBox/CategoryZone/ClassTag/Label
@onready var guide_arrow: Label = $VBox/CategoryZone/GuideArrow

@onready var info_zone: Panel = $VBox/InfoZone
@onready var card_name: Label = $VBox/InfoZone/VBox/CardName
@onready var effects: RichTextLabel = $VBox/InfoZone/VBox/Effects
@onready var guaranteed_dot: Label = $VBox/InfoZone/VBox/GuaranteedDot

var card_id: String = ""
var card_data: Dictionary = {}
var is_selected: bool = false
var is_hovered: bool = false
var is_available: bool = true
var is_guaranteed: bool = false
var is_class_recommended: bool = false
var show_guide: bool = false

var original_position: Vector2
var hover_tween: Tween
var select_tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(160, 240)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

	_setup_styles()
	original_position = position

func _setup_styles() -> void:
	# 整卡样式
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = ThemeColors.BG_PANEL
	card_style.set_corner_radius_all(8)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = ThemeColors.BORDER_DEFAULT
	card_style.shadow_color = Color(0, 0, 0, 0.2)
	card_style.shadow_size = 8
	card_style.shadow_offset = Vector2(0, 2)
	add_theme_stylebox_override("panel", card_style)

	# AP badge 样式
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = ThemeColors.BG_DEEP
	badge_style.set_corner_radius_all(14)
	ap_badge.add_theme_stylebox_override("panel", badge_style)

	# 课程标签样式
	var class_style = StyleBoxFlat.new()
	class_style.bg_color = ThemeColors.ACCENT
	class_style.set_corner_radius_all(4)
	class_tag.add_theme_stylebox_override("panel", class_style)

func setup(data: Dictionary) -> void:
	card_data = data.duplicate(true)
	card_id = str(data.get("id", ""))

	var category = str(data.get("category", "rest"))
	var cat_color = ThemeColors.get_category_color.call(category)
	category_bg.color = cat_color

	# 类别图标和名称
	category_icon.text = _get_category_icon(category)
	category_name.text = _get_category_name(category)

	# AP 消耗
	var ap_cost = int(data.get("action_point_cost", 1))
	ap_value.text = str(ap_cost)

	# 卡名
	card_name.text = str(data.get("display_name", "未命名"))

	# 效果摘要
	_build_effects_text()

	# 常驻标记
	is_guaranteed = bool(data.get("is_guaranteed", false))
	guaranteed_dot.visible = is_guaranteed

	# 课程推荐标记
	is_class_recommended = bool(data.get("is_class_card", false))
	class_tag.visible = is_class_recommended

	# 引导箭头（Day 2-3）
	show_guide = bool(data.get("show_guide", false))
	guide_arrow.visible = show_guide
	if show_guide:
		_start_guide_animation()

func _get_category_icon(category: String) -> String:
	match category:
		"class": return "📖"
		"social": return "💬"
		"rest": return "🌙"
		"exercise": return "💪"
		"fun": return "🎮"
		"nightlife": return "🍺"
		"explore": return "🔍"
		"work": return "💰"
		_: return "❓"

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

func _build_effects_text() -> void:
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
		effects.text = "[center][color=#8890a4]无明显效果[/color][/center]"
	else:
		effects.text = "[center]" + " · ".join(text_parts) + "[/center]"

func set_available(available: bool) -> void:
	is_available = available
	modulate.a = 1.0 if available else 0.35

func set_selected(selected: bool) -> void:
	if is_selected == selected:
		return
	is_selected = selected
	_update_visual_state()

func _on_mouse_entered() -> void:
	if not is_available:
		return
	is_hovered = true
	card_hovered.emit(card_id)
	_update_visual_state()

func _on_mouse_exited() -> void:
	is_hovered = false
	card_unhovered.emit(card_id)
	_update_visual_state()

func _on_gui_input(event: InputEvent) -> void:
	if not is_available:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			card_selected.emit(card_id)

func _update_visual_state() -> void:
	if hover_tween:
		hover_tween.kill()
	if select_tween:
		select_tween.kill()

	var target_offset = 0.0
	var border_color = ThemeColors.BORDER_DEFAULT
	var shadow_size = 8

	if is_selected:
		target_offset = -16.0
		border_color = ThemeColors.BORDER_ACCENT
		shadow_size = 16
	elif is_hovered:
		target_offset = -6.0
		border_color = Color(1, 1, 1, 0.15)
		shadow_size = 16

	# 位置动画
	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_OUT)
	hover_tween.set_trans(Tween.TRANS_CUBIC)
	hover_tween.tween_property(self, "position:y", original_position.y + target_offset, 0.2)

	# 边框和阴影
	var card_style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	card_style.border_color = border_color
	card_style.shadow_size = shadow_size
	if is_selected:
		card_style.border_width_left = 2
		card_style.border_width_top = 2
		card_style.border_width_right = 2
		card_style.border_width_bottom = 2
	add_theme_stylebox_override("panel", card_style)

func _start_guide_animation() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(guide_arrow, "position:y", guide_arrow.position.y - 2, 0.4)
	tween.tween_property(guide_arrow, "position:y", guide_arrow.position.y + 2, 0.4)
