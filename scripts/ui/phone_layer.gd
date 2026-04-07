extends Control

signal closed

const ChatPreviewItemScene := preload("res://scenes/ui/components/chat_preview_item.tscn")

@onready var close_button: Button = $PhoneFrame/PhoneMargin/RootVBox/TopBar/CloseButton
@onready var messages_tab: Button = $PhoneFrame/PhoneMargin/RootVBox/TabRow/MessagesTab
@onready var profile_tab: Button = $PhoneFrame/PhoneMargin/RootVBox/TabRow/ProfileTab
@onready var store_tab: Button = $PhoneFrame/PhoneMargin/RootVBox/TabRow/StoreTab
@onready var settings_tab: Button = $PhoneFrame/PhoneMargin/RootVBox/TabRow/SettingsTab
@onready var chat_list: VBoxContainer = $PhoneFrame/PhoneMargin/RootVBox/ContentRow/ListPanel/ListMargin/ListScroll/ChatList
@onready var detail_title_label: Label = $PhoneFrame/PhoneMargin/RootVBox/ContentRow/DetailPanel/DetailMargin/DetailVBox/DetailTitleLabel
@onready var detail_body_label: RichTextLabel = $PhoneFrame/PhoneMargin/RootVBox/ContentRow/DetailPanel/DetailMargin/DetailVBox/DetailBodyLabel
@onready var detail_note_label: Label = $PhoneFrame/PhoneMargin/RootVBox/ContentRow/DetailPanel/DetailMargin/DetailVBox/DetailNoteLabel
@onready var wallpaper_note_label: Label = $PhoneFrame/PhoneMargin/RootVBox/WallpaperNoteLabel

var _threads: Array[Dictionary] = [
	{
		"id": "guyao",
		"name": "顾遥",
		"preview": "你今天去社团宣讲了吗？",
		"meta": "19:42 / TODO: 未读角标",
		"messages": [
			"顾遥：你今天去社团宣讲了吗？",
			"你：刚结束，还在回宿舍路上。",
			"顾遥：那你下次来可以提前一点，我给你留前排位子。",
		],
	},
	{
		"id": "roommate_group",
		"name": "宿舍群",
		"preview": "晚上要不要去夜宵局？",
		"meta": "22:10 / 群聊",
		"messages": [
			"林一帆：晚上要不要去夜宵局？",
			"周驰：我都行。",
			"许川：看你们，我晚点也能下楼。",
		],
	},
]

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_button_pressed)
	messages_tab.pressed.connect(func() -> void: _show_messages())
	profile_tab.pressed.connect(func() -> void: _show_profile())
	store_tab.pressed.connect(func() -> void: _show_store())
	settings_tab.pressed.connect(func() -> void: _show_settings())
	wallpaper_note_label.text = "TODO: 手机壁纸 / 状态栏图标 / 更真实的 Win 风桌面式细节"

func open_layer(default_screen: String = "messages") -> void:
	visible = true
	match default_screen:
		"profile":
			_show_profile()
		"store":
			_show_store()
		"settings":
			_show_settings()
		_:
			_show_messages()

func hide_layer() -> void:
	visible = false

func _show_messages() -> void:
	_set_active_tab(messages_tab)
	_clear_chat_list()
	for thread_data in _threads:
		var item := ChatPreviewItemScene.instantiate()
		chat_list.add_child(item)
		item.setup(thread_data)
		item.opened.connect(_on_chat_item_opened)
	if not _threads.is_empty():
		_open_thread(String(_threads[0].get("id", "")))
	else:
		detail_title_label.text = "消息"
		detail_body_label.text = "暂无消息。"
		detail_note_label.text = "TODO: 真实消息数据接关系系统。"

func _show_profile() -> void:
	_set_active_tab(profile_tab)
	_clear_chat_list()
	detail_title_label.text = "个人资料占位"
	detail_body_label.text = "[b]TODO: 角色信息 / 关系标签 / 头像卡片[/b]\n\n这里后续可以放顾遥、舍友、学长学姐的资料页。"
	detail_note_label.text = "当前先保留结构，不接正式关系后端。"

func _show_store() -> void:
	_set_active_tab(store_tab)
	_clear_chat_list()
	detail_title_label.text = "软件商城占位"
	detail_body_label.text = "[b]TODO: 软件商城、特殊卡购买、下载入口[/b]\n\n后续可接电脑 / 手机双端功能联动。"
	detail_note_label.text = "当前为本地 mock 页面。"

func _show_settings() -> void:
	_set_active_tab(settings_tab)
	_clear_chat_list()
	detail_title_label.text = "手机设置占位"
	detail_body_label.text = "[b]TODO: 壁纸、通知、字体、音效、假系统设置项[/b]\n\n这里应比游戏总菜单更生活化。"
	detail_note_label.text = "当前仅验证 UI 分页骨架。"

func _set_active_tab(active_button: Button) -> void:
	for button in [messages_tab, profile_tab, store_tab, settings_tab]:
		button.disabled = button == active_button

func _open_thread(thread_id: String) -> void:
	for thread_data in _threads:
		if String(thread_data.get("id", "")) != thread_id:
			continue
		detail_title_label.text = String(thread_data.get("name", "聊天"))
		var lines: Array = thread_data.get("messages", [])
		detail_body_label.text = "\n".join(lines)
		detail_note_label.text = "TODO: 聊天气泡、输入框、时间戳、表情与头像素材"
		return

func _clear_chat_list() -> void:
	for child in chat_list.get_children():
		child.queue_free()

func _on_chat_item_opened(thread_id: String) -> void:
	_open_thread(thread_id)

func _on_close_button_pressed() -> void:
	hide_layer()
	closed.emit()
