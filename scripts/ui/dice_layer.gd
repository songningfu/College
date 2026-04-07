extends Control

signal continued

@onready var title_label: Label = $Center/Panel/PanelMargin/VBox/TitleLabel
@onready var die_one_label: Label = $Center/Panel/PanelMargin/VBox/DiceRow/DieOneLabel
@onready var die_two_label: Label = $Center/Panel/PanelMargin/VBox/DiceRow/DieTwoLabel
@onready var formula_label: Label = $Center/Panel/PanelMargin/VBox/FormulaLabel
@onready var threshold_label: Label = $Center/Panel/PanelMargin/VBox/ThresholdLabel
@onready var outcome_label: Label = $Center/Panel/PanelMargin/VBox/OutcomeLabel
@onready var note_label: Label = $Center/Panel/PanelMargin/VBox/NoteLabel
@onready var continue_button: Button = $Center/Panel/PanelMargin/VBox/ContinueButton

func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_button_pressed)
	note_label.text = "TODO: 两枚大骰子贴图 / 掷骰动画 / 成败闪光 / 音效"

func present_roll(roll: Dictionary) -> void:
	visible = true
	var stat_name: String = String(roll.get("stat", "检定"))
	var die1: int = int(roll.get("die1", 0))
	var die2: int = int(roll.get("die2", 0))
	var modifier: int = int(roll.get("modifier", 0))
	var total: int = int(roll.get("total", 0))
	var threshold: int = int(roll.get("threshold", 0))
	var success: bool = bool(roll.get("success", false))

	title_label.text = "%s检定" % stat_name
	die_one_label.text = str(die1)
	die_two_label.text = str(die2)
	formula_label.text = "%d + %d + 修正 %+d = %d" % [die1, die2, modifier, total]
	threshold_label.text = "阈值 %d" % threshold
	outcome_label.text = "成功" if success else "失败"

func hide_layer() -> void:
	visible = false

func _on_continue_button_pressed() -> void:
	hide_layer()
	continued.emit()
