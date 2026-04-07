extends Button

signal opened(thread_id: String)

var _thread_id: String = ""

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(thread_data: Dictionary) -> void:
	_thread_id = String(thread_data.get("id", ""))
	get_node("Margin/VBox/NameLabel").text = String(thread_data.get("name", "未命名联系人"))
	get_node("Margin/VBox/PreviewLabel").text = String(thread_data.get("preview", "暂无消息"))
	get_node("Margin/VBox/MetaLabel").text = String(thread_data.get("meta", "TODO: 时间 / 未读标识"))

func _on_pressed() -> void:
	opened.emit(_thread_id)
