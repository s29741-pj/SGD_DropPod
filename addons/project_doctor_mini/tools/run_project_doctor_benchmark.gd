@tool
extends SceneTree

const ProjectScanner = preload("res://addons/project_doctor_mini/scanner/project_scanner.gd")
const BENCHMARK_ROOT_DIR := "res://tests/generated"
const BENCHMARK_DIR := "res://tests/generated/benchmark_case"
const BENCHMARK_FILE_COUNT := 500

func _init() -> void:
	_delete_path_recursive(ProjectSettings.globalize_path(BENCHMARK_ROOT_DIR))
	if not _create_benchmark_fixture():
		printerr("Could not create benchmark fixture files.")
		quit(1)
		return

	var scanner := ProjectScanner.new()
	var report := scanner.scan()
	var version_info := Engine.get_version_info()
	var version_label := "%s.%s.%s" % [version_info.get("major", 0), version_info.get("minor", 0), version_info.get("patch", 0)]
	var scanned_file_count := _count_project_files("res://")

	print("Project Doctor benchmark complete: %d generated files, %d total files scanned, %d ms, Godot %s" % [
		BENCHMARK_FILE_COUNT,
		scanned_file_count,
		int(report.get("scan_duration_ms", 0)),
		version_label
	])

	_delete_path_recursive(ProjectSettings.globalize_path(BENCHMARK_ROOT_DIR))
	quit(0)

func _create_benchmark_fixture() -> bool:
	var benchmark_global_path := ProjectSettings.globalize_path(BENCHMARK_DIR)
	if DirAccess.make_dir_recursive_absolute(benchmark_global_path) != OK:
		return false

	for index in BENCHMARK_FILE_COUNT:
		var file_path := BENCHMARK_DIR.path_join("generated_%03d.gd" % index)
		var file := FileAccess.open(file_path, FileAccess.WRITE)
		if file == null:
			return false
		file.store_string("extends Node\n\nfunc ready_marker_%03d() -> void:\n\tpass\n" % index)

	return true

func _count_project_files(path: String) -> int:
	var dir := DirAccess.open(path)
	if dir == null:
		return 0

	var count := 0
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var child_path := path.path_join(entry)
			if dir.current_is_dir():
				count += _count_project_files(child_path)
			else:
				count += 1
		entry = dir.get_next()
	dir.list_dir_end()
	return count

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
