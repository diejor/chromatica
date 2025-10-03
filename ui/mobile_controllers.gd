class_name MobileControl
extends Control

@export var only_mobile: bool = true

func is_mobile() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios")

func set_input_enabled(on: bool):
	if only_mobile and is_mobile():
		visible = on
