extends Control

signal choice_selected(choice_index: int)
signal closed

const ChoiceButtonScene := preload("res://scenes/ui/components/choice_button.tscn")

@onready var title_label: Label = $MainMargin/RootVBox/TextPanel/TextMargin/TextVBox/TitleLabel
@onready var description_label: RichTextLabel = $MainMargin/RootVBox/TextPanel/TextMargin/TextVBox/DescriptionLabel
@onready var result_label: RichTextLabel = $MainMargin/RootVBox/TextPanel/TextMargin/TextVBox/ResultLabel
@onready var choice_list: VBoxContainer = $MainMargin/RootVBox/TextPanel/TextMargin/TextVBox/ChoiceList
@onready var close_button: Button = $MainMargin/RootVBox/TextPanel/TextMargin/TextVBox/CloseButton
@onready var portrait_note_label: Label = $MainMargin/RootVBox/VisualPanel/VisualMargin/VisualVBox/PortraitNoteLabel
@onready var background_note_label: Label = $MainMargin/RootVBox/VisualPanel/VisualMargin/VisualVBox/BackgroundNoteLabel

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_button_pressed)
	portrait_note_label.text = "TODO: 角色立绘 / 半身插图 / 发言头像"
	background_note_label.text = "TODO: 事件背景图 / 对话框皮肤 / 光效过场"

func present_event(event_data: Dictionary) -> void:
	visible = true
	title_label.text = String(event_data.get("display_name", "未命名事件"))
	description_label.text = String(event_data.get("description", ""))
	result_label.text = ""
	close_button.visible = false
	_clear_choices()

	var choices: Array = event_data.get("choices", [])
	for index in range(choices.size()):
		var choice_data: Dictionary = choices[index]
		var choice_button := ChoiceButtonScene.instantiate()
		choice_list.add_child(choice_button)
		choice_button.setup(index, String(choice_data.get("text", "继续")))
		choice_button.chosen.connect(_on_choice_button_chosen)

func show_resolution(event_result: Dictionary) -> void:
	result_label.text = String(event_result.get("result_text", ""))
	_clear_choices()
	close_button.visible = true

func hide_layer() -> void:
	visible = false
	_clear_choices()
	result_label.text = ""

func _clear_choices() -> void:
	for child in choice_list.get_children():
		child.queue_free()

func _on_choice_button_chosen(choice_index: int) -> void:
	choice_selected.emit(choice_index)

func _on_close_button_pressed() -> void:
	hide_layer()
	closed.emit()
