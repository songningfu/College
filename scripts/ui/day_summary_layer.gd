extends Control

signal next_day_requested
signal phone_requested

@onready var day_label: Label = $Center/Panel/PanelMargin/VBox/DayLabel
@onready var stats_delta_label: RichTextLabel = $Center/Panel/PanelMargin/VBox/ContentRow/StatsPanel/StatsMargin/StatsDeltaLabel
@onready var relationship_delta_label: RichTextLabel = $Center/Panel/PanelMargin/VBox/ContentRow/RelationshipPanel/RelationshipMargin/RelationshipDeltaLabel
@onready var snapshot_label: RichTextLabel = $Center/Panel/PanelMargin/VBox/SnapshotPanel/SnapshotMargin/SnapshotLabel
@onready var open_phone_button: Button = $Center/Panel/PanelMargin/VBox/ButtonRow/OpenPhoneButton
@onready var next_day_button: Button = $Center/Panel/PanelMargin/VBox/ButtonRow/NextDayButton
@onready var background_note_label: Label = $Center/Panel/PanelMargin/VBox/BackgroundNoteLabel

func _ready() -> void:
	visible = false
	open_phone_button.pressed.connect(_on_open_phone_button_pressed)
	next_day_button.pressed.connect(_on_next_day_button_pressed)
	background_note_label.text = "TODO: 日结算背景 / 便签纸 / 手帐式美术包装"

func show_summary(summary: Dictionary, stat_delta: Dictionary, relationship_delta: Dictionary, is_demo_end: bool = false) -> void:
	visible = true
	day_label.text = "Day %02d 结算" % int(summary.get("day", 1))
	stats_delta_label.text = _format_delta_block("今日属性变化", stat_delta)
	relationship_delta_label.text = _format_delta_block("今日关系变化", relationship_delta)
	var stats: Dictionary = summary.get("stats", {})
	var relationships: Dictionary = summary.get("relationships", {})
	snapshot_label.text = "[b]收束快照[/b]\n学力 %s / 绩点 %s / 生活费 %s / 社交 %s / 健康 %s / 心理 %s\n舍友 %s / 顾遥 %s" % [
		str(stats.get("学力", 0)),
		str(stats.get("绩点", 0)),
		str(stats.get("生活费", 0)),
		str(stats.get("社交", 0)),
		str(stats.get("健康", 0)),
		str(stats.get("心理", 0)),
		str(relationships.get("舍友", 0)),
		str(relationships.get("顾遥", 0)),
	]
	next_day_button.text = "查看结束占位" if is_demo_end else "进入下一天"

func hide_summary() -> void:
	visible = false

func _format_delta_block(title: String, delta_map: Dictionary) -> String:
	if delta_map.is_empty():
		return "[b]%s[/b]\n无变化" % title
	var lines: Array[String] = ["[b]%s[/b]" % title]
	for key in delta_map.keys():
		var value = delta_map[key]
		if value is float and not is_equal_approx(value, round(value)):
			lines.append("%s %+0.2f" % [String(key), float(value)])
		else:
			lines.append("%s %+d" % [String(key), int(value)])
	return "\n".join(lines)

func _on_open_phone_button_pressed() -> void:
	phone_requested.emit()

func _on_next_day_button_pressed() -> void:
	next_day_requested.emit()
