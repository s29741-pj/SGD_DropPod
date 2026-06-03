@tool
extends RefCounted

const ProcessUsageCheck = preload("res://addons/project_doctor_mini/scanner/checks/process_usage_check.gd")
const ExportPresetsCheck = preload("res://addons/project_doctor_mini/scanner/checks/export_presets_check.gd")
const ImportSettingsCheck = preload("res://addons/project_doctor_mini/scanner/checks/import_settings_check.gd")

const SETTINGS_FILE_PATH := "res://project_doctor_settings.cfg"
const DEFAULT_LARGE_TEXTURE_THRESHOLD := 2048
const DEFAULT_SCENE_NODE_COUNT_THRESHOLD := 250
const DEFAULT_IGNORED_PATH_PATTERNS := ["res://reports", "res://sandbox_screenshot", "res://docs/examples", "res://examples/demo_project/**", "res://tests/fixtures/**"]
const DEFAULT_IGNORED_FINDINGS := []
const DEFAULT_BASELINE_FILE := "res://project_doctor_baseline.json"
const DEFAULT_ENABLE_EXPERIMENTAL_UNUSED_FILES := false
const LARGE_TEXTURE_THRESHOLD_SETTING := "project_doctor_mini/large_texture_threshold"
const SCENE_NODE_COUNT_THRESHOLD_SETTING := "project_doctor_mini/scene_node_count_threshold"
const IGNORED_PATH_PATTERNS_SETTING := "project_doctor_mini/ignored_path_patterns"
const LEGACY_IGNORED_FOLDERS_SETTING := "project_doctor_mini/ignored_folders"
const IGNORED_FINDINGS_SETTING := "project_doctor_mini/ignored_finding_ids"
const LEGACY_IGNORED_FINDINGS_SETTING := "project_doctor_mini/ignored_findings"
const BASELINE_FILE_SETTING := "project_doctor_mini/baseline_file"
const EXPERIMENTAL_UNUSED_FILES_SETTING := "project_doctor_mini/enable_experimental_unused_files"
const TOOL_NAME := "Godot Project Doctor Mini"
const TOOL_VERSION_FALLBACK := "0.2.8"
const SEVERITY_ORDER := {
	"error": 0,
	"warning": 1,
	"info": 2
}
const RESOURCE_TEXT_EXTENSIONS := ["tscn", "tres", "cfg", "godot", "import", "md"]
const TEXTURE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]
const UNUSED_CANDIDATE_EXTENSIONS := ["png", "jpg", "jpeg", "webp", "wav", "ogg", "mp3", "tres", "res", "tscn", "gdshader"]

var findings: Array[Dictionary] = []
var files: Array[String] = []
var folders: Array[String] = []
var referenced_paths: Dictionary = {}
var large_texture_threshold := DEFAULT_LARGE_TEXTURE_THRESHOLD
var scene_node_count_threshold := DEFAULT_SCENE_NODE_COUNT_THRESHOLD
var ignored_path_patterns: Array = []
var ignored_finding_ids: Dictionary = {}
var baseline_entries: Array = []
var experimental_unused_files_enabled := DEFAULT_ENABLE_EXPERIMENTAL_UNUSED_FILES

func scan() -> Dictionary:
	var start_ticks := Time.get_ticks_msec()

	findings.clear()
	files.clear()
	folders.clear()
	referenced_paths.clear()

	var effective_settings := _load_effective_settings()
	large_texture_threshold = int(effective_settings.get("large_texture_threshold", DEFAULT_LARGE_TEXTURE_THRESHOLD))
	scene_node_count_threshold = int(effective_settings.get("scene_node_count_threshold", DEFAULT_SCENE_NODE_COUNT_THRESHOLD))
	ignored_path_patterns = effective_settings.get("ignored_path_patterns", DEFAULT_IGNORED_PATH_PATTERNS)
	ignored_finding_ids = _build_lookup(effective_settings.get("ignored_finding_ids", DEFAULT_IGNORED_FINDINGS))
	experimental_unused_files_enabled = bool(effective_settings.get("enable_experimental_unused_files", DEFAULT_ENABLE_EXPERIMENTAL_UNUSED_FILES))
	baseline_entries = _load_baseline_entries(str(effective_settings.get("baseline_file", "")))

	_walk_directory("res://")
	_collect_references()
	_check_missing_scripts()
	_check_broken_resource_paths()
	_check_large_textures()
	_check_scene_node_counts()
	_append_findings(ProcessUsageCheck.new().run(files, Callable(self , "_read_text_file")))
	_check_empty_folders()
	_check_unused_files()
	_append_findings(ImportSettingsCheck.new().run(files, large_texture_threshold))
	_append_findings(ExportPresetsCheck.new().run())
	_filter_findings()
	_sort_findings()

	var tool_version := _load_tool_version()

	return {
		"tool": TOOL_NAME,
		"tool_version": tool_version,
		"generated_at": Time.get_datetime_string_from_system(true),
		"project_root": "res://",
		"scan_duration_ms": Time.get_ticks_msec() - start_ticks,
		"summary": _build_summary(),
		"findings": findings
	}

func _walk_directory(path: String) -> void:
	if _is_ignored_path(path):
		return

	var dir := DirAccess.open(path)
	if dir == null:
		_add_finding("scan_error", "error", path, "Could not open directory.", "Check folder permissions or project state.")
		return

	folders.append(path)
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var child_path := path.path_join(entry)
			if _is_ignored_path(child_path):
				entry = dir.get_next()
				continue
			if dir.current_is_dir():
				_walk_directory(child_path)
			else:
				files.append(child_path)
		entry = dir.get_next()
	dir.list_dir_end()

func _collect_references() -> void:
	var markdown_regex := RegEx.new()
	markdown_regex.compile("!?\\[[^\\]]*\\]\\(([^)]+)\\)")

	for file_path in files:
		var extension := file_path.get_extension().to_lower()
		if extension != "gd" and not _has_extension(file_path, RESOURCE_TEXT_EXTENSIONS):
			continue

		var text := _read_text_file(file_path)
		if text == "":
			continue

		if extension == "md":
			_collect_markdown_references(file_path, text, markdown_regex)
			continue

		for line in text.split("\n"):
			if extension == "gd" and not _is_gdscript_resource_load_line(line):
				continue

			for resource_path in _extract_resource_paths_from_line(line):
				referenced_paths[resource_path] = true

func _check_missing_scripts() -> void:
	for file_path in files:
		if not _has_extension(file_path, ["tscn", "tres"]):
			continue

		var text := _read_text_file(file_path)
		if text == "":
			continue

		for line in text.split("\n"):
			if line.contains("type=\"Script\"") and line.contains("path=\"res://"):
				var script_path := _extract_resource_path(line)
				if script_path != "" and not FileAccess.file_exists(script_path):
					_add_finding(
						"missing_script",
						"error",
						file_path,
						"Scene or resource references a missing script: %s" % script_path,
						"Restore the script or remove the broken reference."
					)

func _check_broken_resource_paths() -> void:
	for resource_path in referenced_paths.keys():
		if resource_path == "res://":
			continue
		if _is_ignored_path(resource_path):
			continue
		if not _resource_path_exists(resource_path):
			_add_finding(
				"broken_resource_path",
				"error",
				resource_path,
				"Referenced resource path does not exist.",
				"Update the reference or restore the missing resource."
			)

func _check_large_textures() -> void:
	for file_path in files:
		if not _has_extension(file_path, TEXTURE_EXTENSIONS):
			continue

		var image := Image.new()
		var error := image.load(file_path)
		if error != OK:
			_add_finding("texture_load_error", "warning", file_path, "Could not read texture dimensions.", "Reimport or validate the texture file.")
			continue

		var width := image.get_width()
		var height := image.get_height()
		if width > large_texture_threshold or height > large_texture_threshold:
			_add_finding(
				"large_texture",
				"warning",
				file_path,
				"Texture is %dx%d, above the %dpx threshold." % [width, height, large_texture_threshold],
				"Resize, compress, or use platform-specific import settings."
			)

func _check_scene_node_counts() -> void:
	for file_path in files:
		if not _has_extension(file_path, ["tscn"]):
			continue

		var node_count := 0
		var text := _read_text_file(file_path)
		if text == "":
			continue

		for line in text.split("\n"):
			if line.begins_with("[node "):
				node_count += 1

		if node_count > scene_node_count_threshold:
			_add_finding(
				"scene_too_many_nodes",
				"warning",
				file_path,
				"Scene has %d nodes, above the %d node threshold." % [node_count, scene_node_count_threshold],
				"Consider splitting the scene or reviewing generated node structure."
			)

func _check_empty_folders() -> void:
	for folder_path in folders:
		if folder_path == "res://":
			continue
		if _is_folder_empty(folder_path):
			_add_finding("empty_folder", "info", folder_path, "Folder is empty.", "Remove it or add a .gdignore if it is intentionally empty.")

func _check_unused_files() -> void:
	if not experimental_unused_files_enabled:
		return

	for file_path in files:
		if file_path == "res://icon.svg":
			continue
		if not _has_extension(file_path, UNUSED_CANDIDATE_EXTENSIONS):
			continue
		if not referenced_paths.has(file_path):
			_add_finding(
				"possibly_unused_file",
				"info",
				file_path,
				"Experimental check: file is not referenced by scanned text resources.",
				"Treat this as advisory only and verify manually before deleting. Dynamic loads may not be detected."
			)

func _build_summary() -> Dictionary:
	var summary := {"errors": 0, "warnings": 0, "info": 0}
	for finding in findings:
		match finding.get("severity", "info"):
			"error":
				summary.errors += 1
			"warning":
				summary.warnings += 1
			_:
				summary.info += 1
	return summary

func _add_finding(id: String, severity: String, path: String, message: String, recommendation: String) -> void:
	findings.append({
		"id": id,
		"severity": severity,
		"title": id.capitalize(),
		"path": path,
		"message": message,
		"recommendation": recommendation
	})

func _append_findings(new_findings: Array[Dictionary]) -> void:
	findings.append_array(new_findings)

func _has_extension(path: String, extensions: Array) -> bool:
	return path.get_extension().to_lower() in extensions

func _is_gdscript_resource_load_line(line: String) -> bool:
	return line.contains("preload(") or line.contains("load(") or line.contains("ResourceLoader.load(")

func _extract_resource_path(text: String) -> String:
	var start := text.find("res://")
	if start == -1:
		return ""

	var end := text.find("\"", start)
	if end == -1:
		return text.substr(start)
	return text.substr(start, end - start)

func _extract_resource_paths_from_line(line: String) -> Array:
	var resource_paths: Array = []
	var search_from := 0

	while true:
		var start := line.find("res://", search_from)
		if start == -1:
			break

		var end := start
		while end < line.length():
			var character := line[end]
			if character == '"' or character == "'" or character == ")" or character == "]" or character == ",":
				break
			end += 1

		resource_paths.append(line.substr(start, end - start).strip_edges())
		search_from = end + 1

	return resource_paths

func _is_folder_empty(path: String) -> bool:
	var dir := DirAccess.open(path)
	if dir == null:
		return false

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			dir.list_dir_end()
			return false
		entry = dir.get_next()
	dir.list_dir_end()
	return true

func _read_text_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _collect_markdown_references(markdown_file_path: String, text: String, markdown_regex: RegEx) -> void:
	var in_fenced_code_block := false

	for line in text.split("\n"):
		var trimmed_line := line.strip_edges()
		if trimmed_line.begins_with("```") or trimmed_line.begins_with("~~~"):
			in_fenced_code_block = not in_fenced_code_block
			continue

		if in_fenced_code_block:
			continue

		for result in markdown_regex.search_all(line):
			var raw_path := result.get_string(1).strip_edges()
			var resolved_path := _resolve_markdown_path(markdown_file_path, raw_path)
			if resolved_path != "":
				referenced_paths[resolved_path] = true

func _resolve_markdown_path(markdown_file_path: String, raw_path: String) -> String:
	if raw_path == "":
		return ""

	var clean_path := raw_path.split("#")[0].split("?")[0].strip_edges()
	if clean_path == "":
		return ""
	if clean_path.begins_with("http://") or clean_path.begins_with("https://"):
		return ""
	if clean_path.begins_with("mailto:") or clean_path.begins_with("data:"):
		return ""

	if clean_path.begins_with("res://"):
		return clean_path

	var project_root_candidate := "res://" + clean_path.trim_prefix("./")
	if _resource_path_exists(project_root_candidate):
		return project_root_candidate

	var base_dir := markdown_file_path.get_base_dir()
	var global_path := ProjectSettings.globalize_path(base_dir.path_join(clean_path))
	var localized_path := ProjectSettings.localize_path(global_path)
	if _resource_path_exists(localized_path):
		return localized_path
	return ""

func _resource_path_exists(resource_path: String) -> bool:
	if FileAccess.file_exists(resource_path):
		return true

	return DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(resource_path))

func _filter_findings() -> void:
	var filtered_findings: Array[Dictionary] = []
	for finding in findings:
		var finding_id := str(finding.get("id", ""))
		var finding_path := str(finding.get("path", ""))

		if ignored_finding_ids.has(finding_id):
			continue
		if _is_ignored_path(finding_path):
			continue
		if _is_baselined_finding(finding):
			continue

		filtered_findings.append(finding)
	findings = filtered_findings

func _load_effective_settings() -> Dictionary:
	var settings := {
		"large_texture_threshold": DEFAULT_LARGE_TEXTURE_THRESHOLD,
		"scene_node_count_threshold": DEFAULT_SCENE_NODE_COUNT_THRESHOLD,
		"ignored_path_patterns": DEFAULT_IGNORED_PATH_PATTERNS.duplicate(),
		"ignored_finding_ids": DEFAULT_IGNORED_FINDINGS.duplicate(),
		"baseline_file": DEFAULT_BASELINE_FILE if FileAccess.file_exists(DEFAULT_BASELINE_FILE) else "",
		"enable_experimental_unused_files": DEFAULT_ENABLE_EXPERIMENTAL_UNUSED_FILES
	}

	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE_PATH) == OK:
		settings["large_texture_threshold"] = int(config.get_value("scanner", "large_texture_threshold", settings["large_texture_threshold"]))
		settings["scene_node_count_threshold"] = int(config.get_value("scanner", "scene_node_count_threshold", settings["scene_node_count_threshold"]))
		settings["ignored_path_patterns"] = _get_string_array_value(config.get_value("scanner", "ignored_path_patterns", settings["ignored_path_patterns"]), true)
		settings["ignored_finding_ids"] = _get_string_array_value(config.get_value("scanner", "ignored_finding_ids", settings["ignored_finding_ids"]), false)
		settings["baseline_file"] = _normalize_resource_path(str(config.get_value("scanner", "baseline_file", settings["baseline_file"])))
		settings["enable_experimental_unused_files"] = bool(config.get_value("scanner", "enable_experimental_unused_files", settings["enable_experimental_unused_files"]))

	if ProjectSettings.has_setting(LARGE_TEXTURE_THRESHOLD_SETTING):
		settings["large_texture_threshold"] = int(ProjectSettings.get_setting(LARGE_TEXTURE_THRESHOLD_SETTING, settings["large_texture_threshold"]))
	if ProjectSettings.has_setting(SCENE_NODE_COUNT_THRESHOLD_SETTING):
		settings["scene_node_count_threshold"] = int(ProjectSettings.get_setting(SCENE_NODE_COUNT_THRESHOLD_SETTING, settings["scene_node_count_threshold"]))
	if ProjectSettings.has_setting(IGNORED_PATH_PATTERNS_SETTING):
		settings["ignored_path_patterns"] = _get_string_array_value(ProjectSettings.get_setting(IGNORED_PATH_PATTERNS_SETTING, settings["ignored_path_patterns"]), true)
	elif ProjectSettings.has_setting(LEGACY_IGNORED_FOLDERS_SETTING):
		settings["ignored_path_patterns"] = _get_string_array_value(ProjectSettings.get_setting(LEGACY_IGNORED_FOLDERS_SETTING, settings["ignored_path_patterns"]), true)
	if ProjectSettings.has_setting(IGNORED_FINDINGS_SETTING):
		settings["ignored_finding_ids"] = _get_string_array_value(ProjectSettings.get_setting(IGNORED_FINDINGS_SETTING, settings["ignored_finding_ids"]), false)
	elif ProjectSettings.has_setting(LEGACY_IGNORED_FINDINGS_SETTING):
		settings["ignored_finding_ids"] = _get_string_array_value(ProjectSettings.get_setting(LEGACY_IGNORED_FINDINGS_SETTING, settings["ignored_finding_ids"]), false)
	if ProjectSettings.has_setting(BASELINE_FILE_SETTING):
		settings["baseline_file"] = _normalize_resource_path(str(ProjectSettings.get_setting(BASELINE_FILE_SETTING, settings["baseline_file"])))
	if ProjectSettings.has_setting(EXPERIMENTAL_UNUSED_FILES_SETTING):
		settings["enable_experimental_unused_files"] = bool(ProjectSettings.get_setting(EXPERIMENTAL_UNUSED_FILES_SETTING, settings["enable_experimental_unused_files"]))

	return settings

func _get_string_array_value(raw_value: Variant, normalize_as_path: bool) -> Array:
	var values: Array[String] = []

	if raw_value is PackedStringArray:
		for entry in raw_value:
			values.append(_normalize_string_value(str(entry), normalize_as_path))
		return values

	if raw_value is Array:
		for entry in raw_value:
			values.append(_normalize_string_value(str(entry), normalize_as_path))
		return values

	var text_value := str(raw_value).strip_edges()
	if text_value == "":
		return []

	for entry in text_value.split(",", false):
		values.append(_normalize_string_value(entry, normalize_as_path))
	return values

func _normalize_string_value(value: String, normalize_as_path: bool) -> String:
	return _normalize_resource_path(value) if normalize_as_path else value.strip_edges()

func _normalize_resource_path(path: String) -> String:
	var trimmed_path := path.strip_edges()
	if trimmed_path == "":
		return ""
	if trimmed_path.begins_with("res://"):
		return trimmed_path.trim_suffix("/")
	return ("res://" + trimmed_path.trim_prefix("./")).trim_suffix("/")

func _build_lookup(values: Array) -> Dictionary:
	var lookup := {}
	for value in values:
		var normalized_value := str(value).strip_edges()
		if normalized_value != "":
			lookup[normalized_value] = true
	return lookup

func _load_baseline_entries(baseline_file_path: String) -> Array:
	if baseline_file_path == "" or not FileAccess.file_exists(baseline_file_path):
		return []

	var file := FileAccess.open(baseline_file_path, FileAccess.READ)
	if file == null:
		return []

	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []

	var accepted_findings: Array = parsed.get("accepted_findings", [])
	if typeof(accepted_findings) != TYPE_ARRAY:
		return []

	return accepted_findings

func _is_ignored_path(path: String) -> bool:
	if path == "":
		return false

	for raw_pattern in ignored_path_patterns:
		var pattern := str(raw_pattern).strip_edges()
		if pattern == "":
			continue
		if _matches_path_pattern(path, pattern):
			return true

	return false

func _matches_path_pattern(path: String, pattern: String) -> bool:
	var normalized_pattern := _normalize_resource_path(pattern)
	if normalized_pattern.contains("*"):
		var regex := RegEx.new()
		regex.compile("^%s$" % _glob_to_regex(normalized_pattern))
		return regex.search(path) != null

	return path == normalized_pattern or path.begins_with(normalized_pattern + "/")

func _glob_to_regex(pattern: String) -> String:
	var regex := ""
	var index := 0
	while index < pattern.length():
		var character := pattern[index]
		if character == "*":
			var is_double := index + 1 < pattern.length() and pattern[index + 1] == "*"
			if is_double:
				regex += ".*"
				index += 2
				continue
			regex += "[^/]*"
			index += 1
			continue

		if character == "." or character == "+" or character == "?" or character == "^" or character == "$" or character == "(" or character == ")" or character == "[" or character == "]" or character == "{" or character == "}" or character == "|" or character == "\\":
			regex += "\\" + character
		else:
			regex += character
		index += 1

	return regex

func _is_baselined_finding(finding: Dictionary) -> bool:
	for entry_variant in baseline_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_variant
		if str(entry.get("id", "")) != str(finding.get("id", "")):
			continue
		if _normalize_resource_path(str(entry.get("path", ""))) != _normalize_resource_path(str(finding.get("path", ""))):
			continue

		var entry_message := str(entry.get("message", "")).strip_edges()
		if entry_message != "" and entry_message != str(finding.get("message", "")).strip_edges():
			continue

		return true

	return false

func _load_tool_version() -> String:
	var config := ConfigFile.new()
	var error := config.load("res://addons/project_doctor_mini/plugin.cfg")
	if error != OK:
		return TOOL_VERSION_FALLBACK

	return str(config.get_value("plugin", "version", TOOL_VERSION_FALLBACK))

func _sort_findings() -> void:
	findings.sort_custom(_compare_findings)

func _compare_findings(left: Dictionary, right: Dictionary) -> bool:
	var left_severity := SEVERITY_ORDER.get(left.get("severity", "info"), 2)
	var right_severity := SEVERITY_ORDER.get(right.get("severity", "info"), 2)
	if left_severity != right_severity:
		return left_severity < right_severity

	var left_path := str(left.get("path", ""))
	var right_path := str(right.get("path", ""))
	if left_path != right_path:
		return left_path < right_path

	return str(left.get("id", "")) < str(right.get("id", ""))
