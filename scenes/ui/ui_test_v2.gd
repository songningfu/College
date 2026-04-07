extends Control

@onready var today_view = $TodayView
@onready var story_layer = $StoryLayer
@onready var dice_layer = $DiceLayer
@onready var phone_layer = $PhoneLayer
@onready var day_summary_layer = $DaySummaryLayer

@onready var test_today_btn = $TestControls/VBox/TestTodayBtn
@onready var test_story_btn = $TestControls/VBox/TestStoryBtn
@onready var test_dice_btn = $TestControls/VBox/TestDiceBtn
@onready var test_phone_btn = $TestControls/VBox/TestPhoneBtn
@onready var test_summary_btn = $TestControls/VBox/TestSummaryBtn

func _ready() -> void:
	test_today_btn.pressed.connect(_test_today_view)
	test_story_btn.pressed.connect(_test_story_layer)
	test_dice_btn.pressed.connect(_test_dice_layer)
	test_phone_btn.pressed.connect(_test_phone_layer)
	test_summary_btn.pressed.connect(_test_summary_layer)

	# 默认显示 TodayView
	_test_today_view()

func _test_today_view() -> void:
	print("测试 TodayView")

	var game_state = {
		"day": 1,
		"period": "morning",
		"phase": "SCHEDULING",
		"energy": 7,
		"energy_max": 10,
		"mood": 6,
		"money": 200,
		"attributes": {
			"knowledge": 2,
			"eloquence": 2,
			"physique": 2,
			"insight": 2
		},
		"ap_remaining": 2,
		"has_unread_messages": true
	}

	today_view.update_view(game_state)

	# 加载测试卡牌
	var test_cards = [
		{
			"id": "card_class_1",
			"display_name": "专业课",
			"category": "class",
			"action_point_cost": 2,
			"energy_cost": 1,
			"effects": {
				"knowledge": 1,
				"energy": -1
			},
			"is_guaranteed": false,
			"is_class_card": true
		},
		{
			"id": "card_social_1",
			"display_name": "社团活动",
			"category": "social",
			"action_point_cost": 1,
			"effects": {
				"eloquence": 1,
				"mood": 1
			},
			"relationship_effects": {
				"林一帆": {"value": 2, "visible": true}
			},
			"is_guaranteed": false
		},
		{
			"id": "card_rest_1",
			"display_name": "宿舍休息",
			"category": "rest",
			"action_point_cost": 1,
			"effects": {
				"energy": 2,
				"mood": 1
			},
			"is_guaranteed": true
		},
		{
			"id": "card_exercise_1",
			"display_name": "操场跑步",
			"category": "exercise",
			"action_point_cost": 1,
			"energy_cost": 1,
			"effects": {
				"physique": 1,
				"energy": -1,
				"mood": 1
			},
			"is_guaranteed": false
		},
		{
			"id": "card_fun_1",
			"display_name": "刷手机",
			"category": "fun",
			"action_point_cost": 1,
			"effects": {
				"mood": 1
			},
			"is_guaranteed": true
		}
	]

	today_view.load_cards(test_cards)

func _test_story_layer() -> void:
	print("测试 StoryLayer")

	story_layer.show_layer()

	# 设置场景背景
	story_layer.set_scene_background(Color("#2a2520"))

	# 显示对白
	await get_tree().create_timer(0.5).timeout
	story_layer.show_dialog("林一帆", "嘿，你也是新生吧？我叫林一帆，计算机系的。")

	# 等待点击
	await story_layer.dialog_finished

	story_layer.show_dialog("你", "你好，我也是计算机系的。", null, true)

	await story_layer.dialog_finished

	# 显示选项
	var choices = [
		{"text": "主动介绍自己", "available": true},
		{"text": "询问他的专业方向", "available": true},
		{"text": "随便聊聊天气", "available": true}
	]
	story_layer.show_choices(choices)

func _test_dice_layer() -> void:
	print("测试 DiceLayer")

	var dice_data = {
		"event_name": "课堂发言",
		"attribute": "口才",
		"modifier": 3,
		"modifier_description": "你的口才还不错，而且今天心情不坏。（+3）",
		"threshold": 10,
		"results": {
			"critical_success": {
				"description": "你的发言清晰有力，连老师都多看了你一眼。",
				"effects_summary": "口才经验+1 · 心情+1 · 班级印象+3"
			},
			"success": {
				"description": "你顺利完成了发言，表现不错。",
				"effects_summary": "口才经验+1 · 班级印象+1"
			},
			"partial_success": {
				"description": "你磕磕绊绊地说完了，还算过得去。",
				"effects_summary": "口才经验+1"
			},
			"failure": {
				"description": "你有些紧张，说得不太流畅。",
				"effects_summary": "心情-1"
			},
			"critical_failure": {
				"description": "你紧张得说不出话，场面一度很尴尬。",
				"effects_summary": "心情-2 · 班级印象-2"
			}
		}
	}

	dice_layer.show_layer(dice_data)

func _test_phone_layer() -> void:
	print("测试 PhoneLayer")

	var contacts = [
		{
			"npc_id": "lin_yifan",
			"name": "林一帆",
			"preview": "晚上一起去食堂？",
			"time": "18:30",
			"has_unread": true,
			"messages": [
				{"text": "嘿，在吗？", "is_player": false},
				{"text": "在的，怎么了？", "is_player": true},
				{"text": "晚上一起去食堂？", "is_player": false}
			],
			"reply_options": [
				"好啊，几点？",
				"不好意思，今晚有事",
				"我再看看吧"
			]
		},
		{
			"npc_id": "shen_qinghe",
			"name": "沈清禾",
			"preview": "今天的作业你做了吗？",
			"time": "16:20",
			"has_unread": false,
			"messages": [
				{"text": "今天的作业你做了吗？", "is_player": false},
				{"text": "还没呢，你呢？", "is_player": true},
				{"text": "我也还没，要不一起做？", "is_player": false},
				{"text": "好啊", "is_player": true}
			],
			"reply_options": []
		}
	]

	phone_layer.load_contacts(contacts)
	phone_layer.show_layer()

func _test_summary_layer() -> void:
	print("测试 DaySummaryLayer")

	var summary_data = {
		"day": 1,
		"flavor_text": "你的第一个大学夜晚，安静又漫长。",
		"actions": {
			"morning": "上专业课",
			"afternoon": "社团活动",
			"evening": "宿舍闲聊"
		},
		"events": [
			"第一次注意到沈清禾",
			"和林一帆成为朋友"
		],
		"stats_changes": {
			"knowledge": {"old": 2, "new": 3},
			"eloquence": {"old": 2, "new": 2},
			"physique": {"old": 2, "new": 2},
			"insight": {"old": 2, "new": 3},
			"energy": {"old": 7, "new": 5},
			"mood": {"old": 6, "new": 7},
			"money": {"old": 200, "new": 180}
		},
		"relation_changes": [
			{"name": "林一帆", "value": 22, "change": 2},
			{"name": "沈清禾", "value": 17, "change": 2},
			{"name": "周驰", "value": 18, "change": 0},
			{"name": "许川", "value": 15, "change": 0}
		],
		"has_unread_messages": true
	}

	day_summary_layer.show_layer(summary_data)
