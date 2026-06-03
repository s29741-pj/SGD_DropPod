@tool
extends SceneTree

const DEMO_PROJECT_PATH := "res://examples/demo_project"
const DEMO_PLUGIN_PATH := DEMO_PROJECT_PATH + "/addons/project_doctor_mini"
const SOURCE_PLUGIN_PATH := "res://addons/project_doctor_mini"
const DEMO_REPORT_PATH := DEMO_PROJECT_PATH + "/reports/project-doctor-report.json"
const DEMO_REPORTS_DIR := DEMO_PROJECT_PATH + "/reports"

func _init() -> void:
	var failures: Array[String] = []
	var demo_project_global_path := ProjectSettings.globalize_path(DEMO_PROJECT_PATH)
	var demo_plugin_global_path := ProjectSettings.globalize_path(DEMO_PLUGIN_PATH)
	var demo_reports_global_path := ProjectSettings.globalize_path(DEMO_REPORTS_DIR)
	var demo_godot_cache_path := ProjectSettings.globalize_path(DEMO_PROJECT_PATH + "/.godot")

	_cleanup_demo_generated_state(demo_plugin_global_path, demo_reports_global_path, demo_godot_cache_path)
	if not _copy_directory_recursive(ProjectSettings.globalize_path(SOURCE_PLUGIN_PATH), demo_plugin_global_path):
		printerr("Could not copy plugin into demo project for integration scan.")
		quit(1)
		return

	var output: Array = []
	var exit_code := OS.execute(OS.get_executable_path(), [
		"--headless",
		"--path",
		demo_project_global_path,
		"--script",
		"res://addons/project_doctor_mini/tools/run_project_scan.gd"
	], output, true)
	if exit_code != 0:
		failures.append("Demo project scan command failed with exit code %d." % exit_code)

	if not FileAccess.file_exists(DEMO_REPORT_PATH):
		failures.append("Demo project report was not written: %s" % DEMO_REPORT_PATH)
	else:
		var report_text := FileAccess.get_file_as_string(DEMO_REPORT_PATH)
		var parsed := JSON.parse_string(report_text)
		if typeof(parsed) != TYPE_DICTIONARY:
			failures.append("Demo project report is not valid JSON.")
		else:
			var findings: Array = parsed.get("findings", [])
			if not _has_finding(findings, "missing_script"):
				failures.append("Demo project report is missing the expected missing_script finding.")
			if not _has_finding(findings, "large_texture"):
				failures.append("Demo project report is missing the expected large_texture finding.")
			if not _has_finding(findings, "export_preset_missing_export_path"):
				failures.append("Demo project report is missing the expected export_preset_missing_export_path finding.")

	_cleanup_demo_generated_state(demo_plugin_global_path, demo_reports_global_path, demo_godot_cache_path)

	if failures.is_empty():
		print("Project Doctor integration test passed.")
		quit(0)
		return

	for line in output:
		print(str(line))
	for failure in failures:
		printerr(failure)
	quit(1)

func _has_finding(findings: Array, finding_id: String) -> bool:
	for finding_variant in findings:
		if typeof(finding_variant) != TYPE_DICTIONARY:
			continue
		if str(finding_variant.get("id", "")) == finding_id:
			return true
	return false

func _cleanup_demo_generated_state(plugin_global_path: String, reports_global_path: String, godot_cache_global_path: String) -> void:
	_delete_path_recursive(plugin_global_path)
	_delete_path_recursive(reports_global_path)
	_delete_path_recursive(godot_cache_global_path)

func _copy_directory_recursive(source_global_path: String, target_global_path: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(target_global_path) != OK:
		return false

	var source_dir := DirAccess.open(source_global_path)
	if source_dir == null:
		return false

	source_dir.list_dir_begin()
	var entry := source_dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var source_entry := source_global_path.path_join(entry)
			var target_entry := target_global_path.path_join(entry)
			if source_dir.current_is_dir():
				if not _copy_directory_recursive(source_entry, target_entry):
					source_dir.list_dir_end()
					return false
			else:
				if not _copy_file(source_entry, target_entry):
					source_dir.list_dir_end()
					return false
		entry = source_dir.get_next()
	source_dir.list_dir_end()
	return true

func _copy_file(source_global_path: String, target_global_path: String) -> bool:
	var source_file := FileAccess.open(source_global_path, FileAccess.READ)
	if source_file == null:
		return false

	var target_file := FileAccess.open(target_global_path, FileAccess.WRITE)
	if target_file == null:
		return false

	target_file.store_buffer(source_file.get_buffer(source_file.get_length()))
	return true

func _delete_path_recursive(global_path: String) -> void:
	if FileAccess.file_exists(global_path):
		DirAccess.remove_absolute(global_path)
		return
	if not DirAccess.dir_exists_absolute(global_path):
		return

	var dir := DirAccess.open(global_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			_delete_path_recursive(global_path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(global_path)
