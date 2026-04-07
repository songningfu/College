extends Control

@onready var today_view: Control = $TodayView
@onready var story_layer: Control = $StoryLayer
@onready var dice_layer: Control = $DiceLayer
@onready var phone_layer: Control = $PhoneLayer
@onready var day_summary_layer: Control = $DaySummaryLayer

var _current_cards: Array = []
var _expanded_period: String = "morning"
var _day_start_stats: Dictionary = {}
var _day_start_relationships: Dictionary = {}
var _pending_event_result: Dictionary = {}

func _ready() -> void:
	randomize()
	_connect_view_signals()
	_connect_core_signals()
	GameManager.reset_run()
	_cache_day_start_state()
	_refresh_views()

func _connect_view_signals() -> void:
	today_view.start_requested.connect(_on_start_requested)
	today_view.card_selected.connect(_on_card_selected)
	today_view.period_selected.connect(_on_period_selected)
	today_view.phone_requested.connect(_on_phone_requested)
	story_layer.choice_selected.connect(_on_story_choice_selected)
	story_layer.closed.connect(_on_story_closed)
	dice_layer.continued.connect(_on_dice_continued)
	phone_layer.closed.connect(_on_phone_closed)
	day_summary_layer.next_day_requested.connect(_on_next_day_requested)
	day_summary_layer.phone_requested.connect(_on_phone_requested)

func _connect_core_signals() -> void:
	DayManager.day_started.connect(_on_day_started)
	DayManager.period_ready.connect(_on_period_ready)
	DayManager.event_started.connect(_on_event_started)
	DayManager.action_resolved.connect(_on_action_resolved)
	DayManager.day_ended.connect(_on_day_ended)
	GameManager.state_changed.connect(_on_state_changed)

func _on_start_requested() -> void:
	story_layer.hide_layer()
	dice_layer.hide_layer()
	day_summary_layer.hide_summary()
	phone_layer.hide_layer()
	_pending_event_result = {}
	_current_cards.clear()
	DayManager.start_day()

func _on_card_selected(card_id: String) -> void:
	DayManager.select_card(card_id)

func _on_period_selected(period: String) -> void:
	_expanded_period = period
	_refresh_views()

func _on_phone_requested() -> void:
	phone_layer.open_layer("messages")

func _on_story_choice_selected(choice_index: int) -> void:
	DayManager.resolve_event_choice(choice_index)

func _on_story_closed() -> void:
	_refresh_views()

func _on_dice_continued() -> void:
	if _pending_event_result.is_empty():
		return
	story_layer.show_resolution(_pending_event_result)
	_pending_event_result = {}

func _on_phone_closed() -> void:
	_refresh_views()

func _on_next_day_requested() -> void:
	story_layer.hide_layer()
	dice_layer.hide_layer()
	day_summary_layer.hide_summary()
	phone_layer.hide_layer()
	_pending_event_result = {}
	_current_cards.clear()
	DayManager.continue_next_day()

func _on_day_started(_day: int) -> void:
	_cache_day_start_state()
	_expanded_period = GameManager.current_period()
	_refresh_views()

func _on_period_ready(period: String, cards: Array) -> void:
	_current_cards = cards
	_expanded_period = period
	_refresh_views()

func _on_event_started(event_data: Dictionary) -> void:
	story_layer.present_event(event_data)

func _on_action_resolved(result: Dictionary) -> void:
	_refresh_views()
	var event_result: Dictionary = result.get("event_result", {})
	if event_result.is_empty():
		story_layer.hide_layer()
		dice_layer.hide_layer()
		_pending_event_result = {}
		return
	if event_result.has("roll"):
		_pending_event_result = event_result
		dice_layer.present_roll(event_result.get("roll", {}))
		return
	_pending_event_result = {}
	story_layer.show_resolution(event_result)

func _on_day_ended(_day: int, summary: Dictionary) -> void:
	var stat_delta: Dictionary = _calculate_delta(_day_start_stats, summary.get("stats", {}))
	var relationship_delta: Dictionary = _calculate_delta(_day_start_relationships, summary.get("relationships", {}))
	day_summary_layer.show_summary(summary, stat_delta, relationship_delta, GameManager.current_day >= GameManager.MAX_DAY)
	_refresh_views()

func _on_state_changed(_phase: String, _day: int, _period: String) -> void:
	_refresh_views()

func _refresh_views() -> void:
	var snapshot: Dictionary = {
		"phase": GameManager.current_phase,
		"day": GameManager.current_day,
		"period": GameManager.current_period(),
		"daily_points_remaining": GameManager.daily_points_remaining,
		"period_points_remaining": GameManager.period_points_remaining,
		"stats": GameManager.stats.duplicate(true),
		"relationships": GameManager.relationships.duplicate(true),
	}
	today_view.render(snapshot, _current_cards, _expanded_period)

func _cache_day_start_state() -> void:
	_day_start_stats = GameManager.stats.duplicate(true)
	_day_start_relationships = GameManager.relationships.duplicate(true)

func _calculate_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in after.keys():
		var before_value: float = float(before.get(key, 0))
		var after_value: float = float(after.get(key, 0))
		var delta: float = after_value - before_value
		if is_zero_approx(delta):
			continue
		if is_equal_approx(after_value, floor(after_value)) and is_equal_approx(before_value, floor(before_value)):
			result[key] = int(delta)
		else:
			result[key] = delta
	return result
