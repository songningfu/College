extends PanelContainer

signal pressed(period: String)

@onready var title_label: Label = $Margin/VBox/HeaderRow/TitleLabel
@onready var state_label: Label = $Margin/VBox/HeaderRow/StateLabel
@onready var ap_label: Label = $Margin/VBox/HeaderRow/ApLabel
@onready var detail_label: Label = $Margin/VBox/BottomRow/DetailLabel
@onready var slot_preview_label: Label = $Margin/VBox/BottomRow/SlotPreviewLabel
@onready var toggle_button: Button = $Margin/VBox/HeaderRow/ToggleButton

var _view_data: Dictionary = {}
var _period: String = ""
var _ready_done: bool = false

func _ready() -> void:
	toggle_button.pressed.connect(_on_toggle_button_pressed)
	_ready_done = true
	_apply_view()

func setup(period: String, display_name: String, state_text: String, detail_text: String, active: bool, expanded: bool, ap_text: String = "", slot_preview: Array[String] = []) -> void:
	_period = period
	_view_data = {
		"display_name": display_name,
		"state_text": state_text,
		"detail_text": detail_text,
		"active": active,
		"expanded": expanded,
		"ap_text": ap_text,
		"slot_preview": slot_preview.duplicate(),
	}
	_apply_view()

func _apply_view() -> void:
	if not _ready_done:
		return
	var display_name: String = String(_view_data.get("display_name", _period))
	var state_text: String = String(_view_data.get("state_text", ""))
	var detail_text: String = String(_view_data.get("detail_text", ""))
	var active: bool = bool(_view_data.get("active", false))
	var expanded: bool = bool(_view_data.get("expanded", false))
	var ap_text: String = String(_view_data.get("ap_text", ""))
	var slot_preview: Array = _view_data.get("slot_preview", [])

	title_label.text = display_name
	state_label.text = state_text
	ap_label.text = ap_text
	detail_label.text = detail_text
	slot_preview_label.text = _slot_preview_text(slot_preview)
	toggle_button.disabled = not active
	if active and expanded:
		toggle_button.text = "当前"
	elif active:
		toggle_button.text = "查看"
	else:
		toggle_button.text = "锁定"

	if not active:
		self_modulate = Color(0.76, 0.76, 0.76, 1)
	elif expanded:
		self_modulate = Color(1, 1, 1, 1)
	else:
		self_modulate = Color(0.92, 0.92, 0.92, 1)

func _slot_preview_text(slot_preview: Array) -> String:
	var left_text: String = "空位"
	var right_text: String = "待扩展"
	if slot_preview.size() > 0:
		left_text = String(slot_preview[0])
	if slot_preview.size() > 1:
		right_text = String(slot_preview[1])
	return "A %s / B %s" % [left_text, right_text]

func _on_toggle_button_pressed() -> void:
	pressed.emit(_period)
