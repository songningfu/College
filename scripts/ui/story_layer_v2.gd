extends CanvasLayer

signal dialog_finished
signal choice_selected(choice_index: int)

@onready var background: Control = $Background
@onready var char_area: Control = $CharArea
@onready var scene_bg: ColorRect = $Background/SceneBg
@onready var left_portrait: TextureRect = $CharArea/LeftChar/Portrait
@onready var left_avatar: TextureRect = $CharArea/LeftChar/AvatarFallback/Avatar
@onready var left_avatar_fallback: Control = $CharArea/LeftChar/AvatarFallback
@onready var right_portrait: TextureRect = $CharArea/RightChar/Portrait
@onready var right_avatar: TextureRect = $CharArea/RightChar/AvatarFallback/Avatar
@onready var right_avatar_fallback: Control = $CharArea/RightChar/AvatarFallback

@onready var dialog_box: PanelContainer = $DialogBox
@onready var speaker_avatar: TextureRect = $DialogBox/MarginContainer/HBox/SpeakerAvatar
@onready var speaker_name: Label = $DialogBox/MarginContainer/HBox/VBox/SpeakerName
@onready var dialog_text: RichTextLabel = $DialogBox/MarginContainer/HBox/VBox/DialogText
@onready var continue_hint: Label = $DialogBox/ContinueHint

@onready var narration_box: PanelContainer = $NarrationBox
@onready var narr_text: RichTextLabel = $NarrationBox/MarginContainer/NarrText

@onready var choice_box: VBoxContainer = $ChoiceBox
@onready var transition_overlay: ColorRect = $TransitionOverlay
@onready var full_screen_text: RichTextLabel = $FullScreenText

const ChoiceButtonScene = preload("res://scenes/ui/components/choice_button.tscn")

var current_dialog: Dictionary = {}
var is_typing: bool = false
var typing_timer: Timer
var char_index: int = 0
var full_text: String = ""
var typing_speed: float = 0.04
var is_fullscreen_mode: bool = false

func _ready() -> void:
	_setup_styles()
	_setup_typing_timer()
	_setup_input_passthrough()

	# 继续提示脉冲动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(continue_hint, "modulate:a", 0.4, 0.3)
	tween.tween_property(continue_hint, "modulate:a", 1.0, 0.3)

func _setup_styles() -> void:
	# 对白框样式
	var dialog_style = StyleBoxFlat.new()
	dialog_style.bg_color = Color(ThemeColors.BG_PRIMARY, 0.88)
	dialog_style.set_corner_radius_all(12)
	dialog_style.border_width_left = 1
	dialog_style.border_width_top = 1
	dialog_style.border_width_right = 1
	dialog_style.border_width_bottom = 1
	dialog_style.border_color = ThemeColors.BORDER_DEFAULT
	dialog_style.shadow_color = Color(0, 0, 0, 0.3)
	dialog_style.shadow_size = 16
	dialog_style.shadow_offset = Vector2(0, 4)
	dialog_box.add_theme_stylebox_override("panel", dialog_style)

	# 旁白框样式
	var narr_style = StyleBoxFlat.new()
	narr_style.bg_color = Color(ThemeColors.BG_PRIMARY, 0.92)
	narr_style.set_corner_radius_all(12)
	narr_style.border_width_left = 1
	narr_style.border_width_top = 1
	narr_style.border_width_right = 1
	narr_style.border_width_bottom = 1
	narr_style.border_color = ThemeColors.BORDER_DEFAULT
	narr_style.shadow_color = Color(0, 0, 0, 0.3)
	narr_style.shadow_size = 16
	narr_style.shadow_offset = Vector2(0, 4)
	narration_box.add_theme_stylebox_override("panel", narr_style)

func _setup_typing_timer() -> void:
	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.timeout.connect(_on_typing_tick)
	add_child(typing_timer)

func _setup_input_passthrough() -> void:
	_set_mouse_passthrough(background)
	_set_mouse_passthrough(char_area)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	full_screen_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_mouse_passthrough(dialog_box, true)
	_set_mouse_passthrough(narration_box, true)

func _set_mouse_passthrough(control: Control, keep_root: bool = false) -> void:
	if not keep_root:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control:
			_set_mouse_passthrough(child as Control)

func show_layer(fade_duration: float = 0.5) -> void:
	visible = true
	background.modulate.a = 0
	dialog_box.modulate.a = 0
	narration_box.modulate.a = 0
	choice_box.modulate.a = 1.0
	transition_overlay.color.a = 0.0
	full_screen_text.modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(background, "modulate:a", 1.0, fade_duration)
	tween.tween_property(dialog_box, "modulate:a", 1.0, fade_duration)
	tween.tween_property(narration_box, "modulate:a", 1.0, fade_duration)

func hide_layer(fade_duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(background, "modulate:a", 0.0, fade_duration)
	tween.tween_property(dialog_box, "modulate:a", 0.0, fade_duration)
	tween.tween_property(narration_box, "modulate:a", 0.0, fade_duration)
	tween.tween_property(full_screen_text, "modulate:a", 0.0, fade_duration * 0.6)
	tween.tween_property(transition_overlay, "color:a", 0.0, fade_duration * 0.6)
	await tween.finished
	full_screen_text.visible = false
	transition_overlay.visible = false
	visible = false

func set_scene_background(color: Color) -> void:
	scene_bg.color = color

func show_character(position: String, portrait_texture: Texture2D = null, avatar_texture: Texture2D = null) -> void:
	var char_control: Control
	var portrait: TextureRect
	var avatar: TextureRect
	var avatar_fallback: Control

	if position == "left":
		char_control = $CharArea/LeftChar
		portrait = left_portrait
		avatar = left_avatar
		avatar_fallback = left_avatar_fallback
	else:
		char_control = $CharArea/RightChar
		portrait = right_portrait
		avatar = right_avatar
		avatar_fallback = right_avatar_fallback

	if portrait_texture:
		portrait.texture = portrait_texture
		portrait.visible = true
		avatar_fallback.visible = false
	elif avatar_texture:
		avatar.texture = avatar_texture
		avatar_fallback.visible = true
		portrait.visible = false

	# 入场动画
	char_control.modulate.a = 0
	var start_x = 320.0 if position == "left" else 1600.0
	var slide_offset = -100 if position == "left" else 100
	char_control.position.x = start_x + slide_offset

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(char_control, "position:x", start_x, 0.3)
	tween.tween_property(char_control, "modulate:a", 1.0, 0.3)

func hide_character(position: String) -> void:
	var char_control: Control = $CharArea/LeftChar if position == "left" else $CharArea/RightChar
	var tween = create_tween()
	tween.tween_property(char_control, "modulate:a", 0.0, 0.3)

func set_character_speaking(position: String, speaking: bool) -> void:
	var char_control: Control = $CharArea/LeftChar if position == "left" else $CharArea/RightChar
	var target_alpha = 1.0 if speaking else 0.5
	var tween = create_tween()
	tween.tween_property(char_control, "modulate:a", target_alpha, 0.2)

func show_dialog(speaker: String, text: String, avatar_texture: Texture2D = null, is_player: bool = false) -> void:
	is_fullscreen_mode = false
	transition_overlay.visible = false
	full_screen_text.visible = false
	dialog_box.visible = true
	narration_box.visible = false
	choice_box.visible = false

	# 设置说话者
	if is_player:
		speaker_name.text = "你"
		speaker_name.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
		speaker_avatar.visible = false
	else:
		speaker_name.text = speaker
		speaker_name.add_theme_color_override("font_color", ThemeColors.ACCENT)
		if avatar_texture:
			speaker_avatar.texture = avatar_texture
			speaker_avatar.visible = true
		else:
			speaker_avatar.visible = false

	# 开始打字机效果
	full_text = text
	char_index = 0
	is_typing = true
	dialog_text.text = ""
	dialog_text.visible_characters = 0
	typing_timer.start()

	continue_hint.visible = false

func show_narration(text: String) -> void:
	is_fullscreen_mode = false
	transition_overlay.visible = false
	full_screen_text.visible = false
	dialog_box.visible = false
	narration_box.visible = true
	choice_box.visible = false

	# 旁白也用打字机效果
	full_text = "[center]" + text + "[/center]"
	char_index = 0
	is_typing = true
	narr_text.text = ""
	narr_text.visible_characters = 0
	typing_timer.start()

	continue_hint.visible = false

func show_fullscreen_text(text: String, overlay_alpha: float = 0.92) -> void:
	is_fullscreen_mode = true
	dialog_box.visible = false
	narration_box.visible = false
	choice_box.visible = false
	transition_overlay.visible = true
	full_screen_text.visible = true
	transition_overlay.color = Color(0, 0, 0, overlay_alpha)
	full_screen_text.modulate.a = 1.0
	full_text = "[center]" + text + "[/center]"
	char_index = 0
	is_typing = true
	full_screen_text.text = ""
	full_screen_text.visible_characters = 0
	typing_timer.start()

	continue_hint.visible = false

func _on_typing_tick() -> void:
	if not is_typing:
		return

	char_index += 1

	if is_fullscreen_mode:
		full_screen_text.text = full_text
		full_screen_text.visible_characters = char_index
	elif dialog_box.visible:
		dialog_text.text = full_text
		dialog_text.visible_characters = char_index
	else:
		narr_text.text = full_text
		narr_text.visible_characters = char_index

	if char_index >= full_text.length():
		_finish_typing()

func _finish_typing() -> void:
	is_typing = false
	typing_timer.stop()

	if is_fullscreen_mode:
		full_screen_text.visible_characters = -1
	elif dialog_box.visible:
		dialog_text.visible_characters = -1
	else:
		narr_text.visible_characters = -1

	continue_hint.visible = true

func _input(event: InputEvent) -> void:
	if not visible or choice_box.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_accept_advance_input()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_accept_advance_input()
			get_viewport().set_input_as_handled()

func _accept_advance_input() -> void:
	if is_typing:
		_finish_typing()
		return
	if is_fullscreen_mode:
		is_fullscreen_mode = false
		transition_overlay.visible = false
		full_screen_text.visible = false
	dialog_finished.emit()

func show_choices(choices: Array) -> void:
	dialog_box.visible = false
	narration_box.visible = false

	# 清除旧选项
	for child in choice_box.get_children():
		child.queue_free()

	# 创建新选项
	for i in range(choices.size()):
		var choice_data = choices[i]
		var choice_btn = ChoiceButtonScene.instantiate()
		choice_box.add_child(choice_btn)
		choice_btn.setup(choice_data)
		choice_btn.choice_pressed.connect(func(): _on_choice_selected(i))

	# 淡入动画
	choice_box.modulate.a = 0
	choice_box.position.y += 20
	choice_box.visible = true

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(choice_box, "modulate:a", 1.0, 0.3)
	tween.tween_property(choice_box, "position:y", choice_box.position.y - 20, 0.3)

func _on_choice_selected(index: int) -> void:
	choice_selected.emit(index)

	# 淡出选项
	var tween = create_tween()
	tween.tween_property(choice_box, "modulate:a", 0.0, 0.2)
	await tween.finished
	choice_box.visible = false

func scene_transition(new_color: Color, duration: float = 0.3) -> void:
	# 横向滑动切换
	var old_bg = scene_bg.duplicate()
	$Background.add_child(old_bg)

	scene_bg.color = new_color
	scene_bg.position.x = 1920

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(old_bg, "position:x", -1920, duration)
	tween.tween_property(scene_bg, "position:x", 0, duration)

	await tween.finished
	old_bg.queue_free()
