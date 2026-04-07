extends Node

# 基础色
const BG_PRIMARY = Color("#1a1f2e")
const BG_PANEL = Color("#232940")
const BG_HOVER = Color("#2d3450")
const BG_DEEP = Color("#131825")

# 强调色
const ACCENT = Color("#e8a838")
const ACCENT_LIGHT = Color("#f0c75e")

# 功能色
const ENERGY_COLOR = Color("#5a9e8f")
const MOOD_SAFE = Color("#e8a838")
const MOOD_DANGER = Color("#d4564a")
const DANGER_COLOR = Color("#d4564a")
const FAIL_DARK = Color("#8a4a4a")
const FAIL_GREY = Color("#6a6a7a")

# 文字色
const TEXT_PRIMARY = Color("#e8e8e8")
const TEXT_SECONDARY = Color("#8890a4")
const TEXT_DISABLED = Color("#555b6e")

# 边框
const BORDER_DEFAULT = Color(1.0, 1.0, 1.0, 0.08)
const BORDER_ACCENT = Color("#e8a838")

# 卡牌类别色
const CARD_CLASS = Color("#3a5f8a")
const CARD_SOCIAL = Color("#c47832")
const CARD_REST = Color("#6a4f8a")
const CARD_EXERCISE = Color("#4a8a5a")
const CARD_FUN = Color("#8a4a6a")
const CARD_NIGHTLIFE = Color("#2a3a5a")
const CARD_EXPLORE = Color("#5a7a5a")
const CARD_WORK = Color("#7a6a3a")

# 类别色映射
static func get_category_color(category: String) -> Color:
	match category:
		"class": return CARD_CLASS
		"social": return CARD_SOCIAL
		"rest": return CARD_REST
		"exercise": return CARD_EXERCISE
		"fun": return CARD_FUN
		"nightlife": return CARD_NIGHTLIFE
		"explore": return CARD_EXPLORE
		"work": return CARD_WORK
		_: return BG_PANEL
