extends Node

func _ready() -> void:
	print("=== 最小测试开始 ===")

	# 测试各系统是否存在
	var game_mgr = get_node_or_null("/root/GameManager")
	var attr_sys = get_node_or_null("/root/AttributeSystem")
	var rel_sys = get_node_or_null("/root/RelationshipSystem")
	var card_sys = get_node_or_null("/root/CardSystem")
	var event_sys = get_node_or_null("/root/EventSystem")
	var day_mgr = get_node_or_null("/root/DayManager")

	print("GameManager: ", game_mgr != null)
	print("AttributeSystem: ", attr_sys != null)
	print("RelationshipSystem: ", rel_sys != null)
	print("CardSystem: ", card_sys != null)
	print("EventSystem: ", event_sys != null)
	print("DayManager: ", day_mgr != null)

	if not game_mgr or not attr_sys or not rel_sys or not card_sys or not event_sys or not day_mgr:
		print("错误：某些系统未加载")
		get_tree().quit()
		return

	print("\n=== 测试系统初始化 ===")
	game_mgr.reset()

	print("初始 Phase: ", game_mgr.current_phase)
	print("初始 Day: ", game_mgr.current_day)

	# 注册NPC
	rel_sys.register_npc(&"gu_yao", 30)
	print("顾遥初始好感: ", rel_sys.get_relation(&"gu_yao"))

	# 测试属性
	print("初始学识: ", attr_sys.get_attribute(&"knowledge"))
	print("初始精力: ", attr_sys.get_resource(&"energy"))

	# 测试卡牌数量
	print("卡牌总数: ", card_sys.all_cards.size())

	# 测试事件数量
	print("事件总数: ", event_sys.all_events.size())

	print("\n=== 所有系统正常 ===")
	get_tree().quit()
