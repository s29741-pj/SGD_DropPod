@tool
extends EditorPlugin

const ProjectDoctorDock = preload("res://addons/project_doctor_mini/project_doctor_dock.gd")

var dock: Control

func _enter_tree() -> void:
	dock = ProjectDoctorDock.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree() -> void:
	if dock != null:
		remove_control_from_docks(dock)
		dock.free()
		dock = null
