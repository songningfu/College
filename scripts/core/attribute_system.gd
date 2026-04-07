extends Node

signal attribute_changed(attr_id: StringName, old_value: int, new_value: int)
signal resource_changed(res_id: StringName, old_value: int, new_value: int)

const ATTR_MAX: int = 10
const ATTR_MIN: int = 0
const ATTR_INITIAL: int = 2

const RESOURCE_CONFIGS: Dictionary = {
	&"energy": {"min": 0, "max": 10, "initial": 8},
	&"money": {"min": 0, "max": 999, "initial": 200},
	&"mood": {"min": 0, "max": 10, "initial": 6},
}

## 四维属性: knowledge, eloquence, physique, insight
var attributes: Dictionary = {}
## 三项资源: energy, money, mood
var resources: Dictionary = {}
## 每日精力回复值
var daily_energy_restore: int = 7


func _ready() -> void:
	reset()


func reset() -> void:
	attributes = {
		&"knowledge": ATTR_INITIAL,
		&"eloquence": ATTR_INITIAL,
		&"physique": ATTR_INITIAL,
		&"insight": ATTR_INITIAL,
	}
	resources = {
		&"energy": RESOURCE_CONFIGS[&"energy"]["initial"],
		&"money": RESOURCE_CONFIGS[&"money"]["initial"],
		&"mood": RESOURCE_CONFIGS[&"mood"]["initial"],
	}
	daily_energy_restore = 7


func get_attribute(attr_id: StringName) -> int:
	return attributes.get(attr_id, 0)


func modify_attribute(attr_id: StringName, delta: int) -> void:
	if attr_id not in attributes:
		return
	var old: int = attributes[attr_id]
	attributes[attr_id] = clampi(old + delta, ATTR_MIN, ATTR_MAX)
	if attributes[attr_id] != old:
		attribute_changed.emit(attr_id, old, attributes[attr_id])


func get_resource(res_id: StringName) -> int:
	return resources.get(res_id, 0)


func modify_resource(res_id: StringName, delta: int) -> void:
	if res_id not in resources:
		return
	var old: int = resources[res_id]
	var cfg: Dictionary = RESOURCE_CONFIGS.get(res_id, {"min": 0, "max": 999})
	resources[res_id] = clampi(old + delta, cfg["min"], cfg["max"])
	if resources[res_id] != old:
		resource_changed.emit(res_id, old, resources[res_id])


func daily_restore() -> void:
	resources[&"energy"] = daily_energy_restore


func is_energy_low() -> bool:
	return resources[&"energy"] <= 2


func get_roll_modifier(attr_id: StringName) -> int:
	var base: int = get_attribute(attr_id)
	var modifier: int = int(floor(float(base) / 2.0))
	if get_resource(&"mood") >= 7:
		modifier += 1
	elif get_resource(&"mood") <= 2:
		modifier -= 1
	return modifier
