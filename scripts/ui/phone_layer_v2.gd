extends CanvasLayer

signal phone_closed
signal message_sent(npc_id: String, choice_index: int)

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var phone_frame: PanelContainer = $PhoneFrame
@onready var close_btn: Button = $PhoneFrame/VBox/Screen/ListView/VBox/ListTitle/HBox/CloseBtn
@onready var contacts_container: VBoxContainer = $PhoneFrame/VBox/Screen/ListView/VBox/Scroll/Contacts
@onready var list_view: Control = $PhoneFrame/VBox/Screen/ListView
@onready var chat_view: Control = $PhoneFrame/VBox/Screen/ChatView
@onready var back_btn: Button = $PhoneFrame/VBox/Screen/ChatView/VBox/ChatTitle/HBox/BackBtn
@onready var chat_name: Label = $PhoneFrame/VBox/Screen/ChatView/VBox/ChatTitle/HBox/Name
@onready var chat_content: VBoxContainer = $PhoneFrame/VBox/Screen/ChatView/VBox/ChatScroll/ChatContent

var contacts_data: Array = []
var current_chat_npc: String = ""

func _ready() -> void:
	_setup_styles()
	close_btn.pressed.connect(_on_close_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	dim_overlay.gui_input.connect(_on_dim_overlay_gui_input)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if chat_view.visible:
			_on_back_pressed()
		else:
			_on_close_pressed()
		get_viewport().set_input_as_handled()

func _setup_styles() -> void:
	# 手机壳样式
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = ThemeColors.BG_HOVER
	frame_style.set_corner_radius_all(32)
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.border_color = ThemeColors.TEXT_DISABLED
	frame_style.shadow_color = Color(0, 0, 0, 0.5)
	frame_style.shadow_size = 32
	frame_style.shadow_offset = Vector2(0, 8)
	phone_frame.add_theme_stylebox_override("panel", frame_style)

	# 屏幕样式
	var screen_style = StyleBoxFlat.new()
	screen_style.bg_color = ThemeColors.BG_PRIMARY
	screen_style.set_corner_radius_all(20)
	$PhoneFrame/VBox/Screen.add_theme_stylebox_override("panel", screen_style)

func show_layer() -> void:
	visible = true
	phone_frame.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(phone_frame, "modulate:a", 1.0, 0.3)

func hide_layer() -> void:
	var tween = create_tween()
	tween.tween_property(phone_frame, "modulate:a", 0.0, 0.3)
	await tween.finished
	visible = false

func load_contacts(contacts: Array) -> void:
	contacts_data = contacts
	list_view.visible = true
	chat_view.visible = false
	current_chat_npc = ""
	_rebuild_contact_list()

func apply_reply_result(npc_id: String, reply_text: String, npc_reply: String, preview_text: String, time_text: String) -> void:
	for i in range(contacts_data.size()):
		var contact: Dictionary = contacts_data[i]
		if str(contact.get("npc_id", "")) != npc_id:
			continue
		var messages: Array = contact.get("messages", []).duplicate(true)
		messages.append({"text": reply_text, "is_player": true})
		messages.append({"text": npc_reply, "is_player": false})
		contact["messages"] = messages
		contact["reply_options"] = []
		contact["has_unread"] = false
		contact["preview"] = preview_text
		contact["time"] = time_text
		contacts_data[i] = contact
		_rebuild_contact_list()
		if current_chat_npc == npc_id and chat_view.visible:
			_open_chat(npc_id)
		break

func _rebuild_contact_list() -> void:
	for child in contacts_container.get_children():
		child.queue_free()
	for contact in contacts_data:
		contacts_container.add_child(_create_contact_row(contact))

func _create_contact_row(contact: Dictionary) -> Panel:
	var row = Panel.new()
	row.custom_minimum_size = Vector2(376, 72)

	# 样式
	var row_style = StyleBoxFlat.new()
	row_style.bg_color = ThemeColors.BG_PRIMARY
	row.add_theme_stylebox_override("panel", row_style)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	# 左边距
	var left_margin = Control.new()
	left_margin.custom_minimum_size = Vector2(16, 0)
	hbox.add_child(left_margin)

	# 头像
	var avatar = TextureRect.new()
	avatar.custom_minimum_size = Vector2(48, 48)
	avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# TODO: 设置头像纹理
	hbox.add_child(avatar)

	# 信息区
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	# 名称和未读点
	var name_hbox = HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(name_hbox)

	var name_label = Label.new()
	name_label.text = str(contact.get("name", "未知"))
	name_label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", 16)
	name_hbox.add_child(name_label)

	if contact.get("has_unread", false):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.color = ThemeColors.DANGER_COLOR
		name_hbox.add_child(dot)

	# 预览文本
	var preview = Label.new()
	preview.text = str(contact.get("preview", ""))
	preview.add_theme_color_override("font_color", ThemeColors.TEXT_SECONDARY)
	preview.add_theme_font_size_override("font_size", 14)
	preview.clip_text = true
	vbox.add_child(preview)

	# 时间
	var time_label = Label.new()
	time_label.text = str(contact.get("time", ""))
	time_label.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
	time_label.add_theme_font_size_override("font_size", 12)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(time_label)

	# 右边距
	var right_margin = Control.new()
	right_margin.custom_minimum_size = Vector2(16, 0)
	hbox.add_child(right_margin)

	# 分隔线
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(300, 1)
	divider.color = Color(1, 1, 1, 0.04)
	divider.position = Vector2(76, 71)
	row.add_child(divider)

	# 点击事件
	var button = Button.new()
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.flat = true
	button.pressed.connect(func(): _open_chat(str(contact.get("npc_id", ""))))
	row.add_child(button)

	return row

func _open_chat(npc_id: String) -> void:
	current_chat_npc = npc_id

	# 查找联系人数据
	var contact_data: Dictionary = {}
	for contact in contacts_data:
		if contact.get("npc_id") == npc_id:
			contact_data = contact
			break

	if contact_data.is_empty():
		return

	# 设置聊天标题
	chat_name.text = str(contact_data.get("name", ""))

	# 清除旧消息
	for child in chat_content.get_children():
		child.queue_free()

	# 加载消息历史
	var messages = contact_data.get("messages", [])
	for msg in messages:
		if msg.get("is_player", false):
			_add_player_bubble(str(msg.get("text", "")))
		else:
			_add_npc_bubble(str(msg.get("text", "")))

	# 如果有待回复选项，显示选项
	var reply_options = contact_data.get("reply_options", [])
	if not reply_options.is_empty():
		_add_reply_options(reply_options)

	# 切换视图
	list_view.visible = false
	chat_view.visible = true

func _add_npc_bubble(text: String) -> void:
	var bubble = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bubble.custom_minimum_size = Vector2(0, 0)

	var bubble_style = StyleBoxFlat.new()
	bubble_style.bg_color = ThemeColors.BG_HOVER
	bubble_style.set_corner_radius_all(12)
	bubble_style.corner_radius_top_left = 4
	bubble_style.content_margin_left = 12
	bubble_style.content_margin_top = 12
	bubble_style.content_margin_right = 12
	bubble_style.content_margin_bottom = 12
	bubble.add_theme_stylebox_override("panel", bubble_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 96)
	bubble.add_child(margin)

	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	label.add_theme_font_size_override("font_size", 15)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(260, 0)
	margin.add_child(label)

	chat_content.add_child(bubble)

func _add_player_bubble(text: String) -> void:
	var bubble = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_END
	bubble.custom_minimum_size = Vector2(0, 0)

	var bubble_style = StyleBoxFlat.new()
	bubble_style.bg_color = Color("#3a5f3a")
	bubble_style.set_corner_radius_all(12)
	bubble_style.corner_radius_top_right = 4
	bubble_style.content_margin_left = 12
	bubble_style.content_margin_top = 12
	bubble_style.content_margin_right = 12
	bubble_style.content_margin_bottom = 12
	bubble.add_theme_stylebox_override("panel", bubble_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 96)
	margin.add_theme_constant_override("margin_right", 16)
	bubble.add_child(margin)

	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	label.add_theme_font_size_override("font_size", 15)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(280, 0)
	margin.add_child(label)

	chat_content.add_child(bubble)

func _add_reply_options(options: Array) -> void:
	for i in range(options.size()):
		var option_text = str(options[i])
		var option_btn = _create_reply_button(option_text, i)
		chat_content.add_child(option_btn)

func _create_reply_button(text: String, index: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 48)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color("#3a5f3a")
	btn_style.set_corner_radius_all(12)
	btn_style.corner_radius_top_right = 4
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(1, 1, 1, 0.08)
	btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = btn_style.duplicate() as StyleBoxFlat
	hover_style.border_color = ThemeColors.ACCENT
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	btn.add_theme_font_size_override("font_size", 15)

	btn.pressed.connect(func(): _on_reply_selected(index))

	return btn

func _on_reply_selected(index: int) -> void:
	message_sent.emit(current_chat_npc, index)

	# 移除选项按钮
	var to_remove = []
	for child in chat_content.get_children():
		if child is Button:
			to_remove.append(child)

	for child in to_remove:
		child.queue_free()

	# 等待 NPC 回复（由外部系统处理）

func _on_back_pressed() -> void:
	list_view.visible = true
	chat_view.visible = false

func _on_close_pressed() -> void:
	phone_closed.emit()
	hide_layer()

func _on_dim_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_close_pressed()
		get_viewport().set_input_as_handled()
