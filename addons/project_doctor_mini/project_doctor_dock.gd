@tool
extends VBoxContainer

const ProjectScanner = preload("res://addons/project_doctor_mini/scanner/project_scanner.gd")
const MarkdownReportWriter = preload("res://addons/project_doctor_mini/report/markdown_report_writer.gd")
const JsonReportWriter = preload("res://addons/project_doctor_mini/report/json_report_writer.gd")
const REPORTS_DIR := "res://reports"
const MARKDOWN_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.md"
const JSON_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.json"
const SETTINGS_FILE_PATH := "res://project_doctor_settings.cfg"
const DEFAULT_LARGE_TEXTURE_THRESHOLD := 2048
const DEFAULT_SCENE_NODE_COUNT_THRESHOLD := 250
const DEFAULT_IGNORED_PATH_PATTERNS := ["res://reports", "res://sandbox_screenshot", "res://docs/examples", "res://examples/demo_project/**", "res://tests/fixtures/**"]
const DEFAULT_IGNORED_FINDING_IDS := []
const DEFAULT_BASELINE_FILE := "res://project_doctor_baseline.json"
const DEFAULT_ENABLE_EXPERIMENTAL_UNUSED_FILES := false

var status_label: Label
var summary_label: Label
var results: Tree
var scan_button: Button
var open_reports_button: Button
var open_markdown_button: Button
var open_json_button: Button
var errors_filter: CheckBox
var warnings_filter: CheckBox
var info_filter: CheckBox
var settings_toggle_button: Button
var settings_container: VBoxContainer
var large_texture_threshold_spin: SpinBox
var scene_node_count_threshold_spin: SpinBox
var ignored_path_patterns_edit: TextEdit
var ignored_finding_ids_edit: TextEdit
var baseline_file_input: LineEdit
var experimental_unused_checkbox: CheckBox
var save_settings_button: Button
var reload_settings_button: Button
var latest_report: Dictionary = {}

func _init() -> void:
	name = "Project Doctor"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var title := Label.new()
	title.text = "Godot Project Doctor Mini"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.tooltip_text = "Scan the current Godot project and review findings inside the editor."
	add_child(title)

	var actions_row := HBoxContainer.new()
	actions_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(actions_row)

	scan_button = Button.new()
	scan_button.text = "Scan Project"
	scan_button.tooltip_text = "Run the project scan and export Markdown/JSON reports."
	scan_button.pressed.connect(_scan_project)
	actions_row.add_child(scan_button)

	open_reports_button = Button.new()
	open_reports_button.text = "Open Reports Folder"
	open_reports_button.tooltip_text = "Open the generated reports directory on disk."
	open_reports_button.pressed.connect(_open_reports_folder)
	actions_row.add_child(open_reports_button)

	var report_actions_row := HBoxContainer.new()
	report_actions_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(report_actions_row)

	open_markdown_button = Button.new()
	open_markdown_button.text = "Open Markdown Report"
	open_markdown_button.tooltip_text = "Open reports/project-doctor-report.md if it exists."
	open_markdown_button.pressed.connect(_open_markdown_report)
	report_actions_row.add_child(open_markdown_button)

	open_json_button = Button.new()
	open_json_button.text = "Open JSON Report"
	open_json_button.tooltip_text = "Open reports/project-doctor-report.json if it exists."
	open_json_button.pressed.connect(_open_json_report)
	report_actions_row.add_child(open_json_button)

	var settings_panel := PanelContainer.new()
	settings_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(settings_panel)

	var settings_panel_content := VBoxContainer.new()
	settings_panel.add_child(settings_panel_content)

	settings_toggle_button = Button.new()
	settings_toggle_button.text = "Settings"
	settings_toggle_button.toggle_mode = true
	settings_toggle_button.tooltip_text = "Show or hide saved scanner settings loaded from project_doctor_settings.cfg."
	settings_toggle_button.toggled.connect(_on_settings_toggle_toggled)
	settings_panel_content.add_child(settings_toggle_button)

	settings_container = VBoxContainer.new()
	settings_container.visible = false
	settings_panel_content.add_child(settings_container)

	var settings_help := Label.new()
	settings_help.text = "Saved to project_doctor_settings.cfg. Lists accept one value per line."
	settings_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_help.tooltip_text = "These values are shared by dock scans and headless scans."
	settings_container.add_child(settings_help)

	var thresholds_grid := GridContainer.new()
	thresholds_grid.columns = 2
	thresholds_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_container.add_child(thresholds_grid)

	var large_texture_label := Label.new()
	large_texture_label.text = "Large Texture Threshold"
	large_texture_label.tooltip_text = "Warn when a texture exceeds this width or height in pixels."
	thresholds_grid.add_child(large_texture_label)

	large_texture_threshold_spin = SpinBox.new()
	large_texture_threshold_spin.min_value = 1
	large_texture_threshold_spin.max_value = 16384
	large_texture_threshold_spin.step = 1
	large_texture_threshold_spin.rounded = true
	large_texture_threshold_spin.tooltip_text = "Pixels. Shared with headless scans through project_doctor_settings.cfg."
	thresholds_grid.add_child(large_texture_threshold_spin)

	var scene_node_count_label := Label.new()
	scene_node_count_label.text = "Scene Node Threshold"
	scene_node_count_label.tooltip_text = "Warn when a scene contains more nodes than this threshold."
	thresholds_grid.add_child(scene_node_count_label)

	scene_node_count_threshold_spin = SpinBox.new()
	scene_node_count_threshold_spin.min_value = 1
	scene_node_count_threshold_spin.max_value = 100000
	scene_node_count_threshold_spin.step = 1
	scene_node_count_threshold_spin.rounded = true
	scene_node_count_threshold_spin.tooltip_text = "Node count limit used by the scene size check."
	thresholds_grid.add_child(scene_node_count_threshold_spin)

	var baseline_file_label := Label.new()
	baseline_file_label.text = "Baseline File"
	baseline_file_label.tooltip_text = "Accepted findings file, usually res://project_doctor_baseline.json."
	thresholds_grid.add_child(baseline_file_label)

	baseline_file_input = LineEdit.new()
	baseline_file_input.placeholder_text = DEFAULT_BASELINE_FILE
	baseline_file_input.tooltip_text = "Project-relative path to the accepted-findings baseline JSON file."
	thresholds_grid.add_child(baseline_file_input)

	var ignored_paths_label := Label.new()
	ignored_paths_label.text = "Ignored Path Patterns"
	ignored_paths_label.tooltip_text = "One project-relative path or glob per line, for example res://reports or res://tests/fixtures/**."
	settings_container.add_child(ignored_paths_label)

	ignored_path_patterns_edit = TextEdit.new()
	ignored_path_patterns_edit.custom_minimum_size = Vector2(0, 72)
	ignored_path_patterns_edit.tooltip_text = "One path or glob per line."
	settings_container.add_child(ignored_path_patterns_edit)

	var ignored_ids_label := Label.new()
	ignored_ids_label.text = "Ignored Finding IDs"
	ignored_ids_label.tooltip_text = "One finding ID per line, for example export_presets_missing."
	settings_container.add_child(ignored_ids_label)

	ignored_finding_ids_edit = TextEdit.new()
	ignored_finding_ids_edit.custom_minimum_size = Vector2(0, 72)
	ignored_finding_ids_edit.tooltip_text = "One finding ID per line."
	settings_container.add_child(ignored_finding_ids_edit)

	experimental_unused_checkbox = CheckBox.new()
	experimental_unused_checkbox.text = "Enable experimental unused-file detection"
	experimental_unused_checkbox.tooltip_text = "Keeps possibly_unused_file enabled for advisory scans only."
	settings_container.add_child(experimental_unused_checkbox)

	var settings_actions := HBoxContainer.new()
	settings_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_container.add_child(settings_actions)

	save_settings_button = Button.new()
	save_settings_button.text = "Save Settings"
	save_settings_button.tooltip_text = "Persist the current dock settings to project_doctor_settings.cfg."
	save_settings_button.pressed.connect(_save_settings)
	settings_actions.add_child(save_settings_button)

	reload_settings_button = Button.new()
	reload_settings_button.text = "Reload Settings"
	reload_settings_button.tooltip_text = "Reload settings from project_doctor_settings.cfg and discard unsaved edits in this panel."
	reload_settings_button.pressed.connect(_reload_settings)
	settings_actions.add_child(reload_settings_button)

	var filters_row := HBoxContainer.new()
	filters_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(filters_row)

	var filters_label := Label.new()
	filters_label.text = "Show:"
	filters_label.tooltip_text = "Filter the findings list by severity."
	filters_row.add_child(filters_label)

	errors_filter = _create_filter_toggle("Errors", "Show error findings.")
	filters_row.add_child(errors_filter)

	warnings_filter = _create_filter_toggle("Warnings", "Show warning findings.")
	filters_row.add_child(warnings_filter)

	info_filter = _create_filter_toggle("Info", "Show informational findings.")
	filters_row.add_child(info_filter)

	status_label = Label.new()
	status_label.text = "Ready."
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.tooltip_text = "Current scan status and report export result."
	add_child(status_label)

	summary_label = Label.new()
	summary_label.text = "Errors: 0 | Warnings: 0 | Info: 0"
	summary_label.tooltip_text = "Summary of findings in the latest scan report."
	add_child(summary_label)

	results = Tree.new()
	results.columns = 4
	results.set_column_title(0, "Severity")
	results.set_column_title(1, "Finding")
	results.set_column_title(2, "Path")
	results.set_column_title(3, "Message")
	results.set_column_titles_visible(true)
	results.set_column_expand(0, false)
	results.set_column_expand(1, false)
	results.set_column_expand_ratio(2, 2)
	results.set_column_expand_ratio(3, 3)
	results.hide_root = true
	results.tooltip_text = "Latest findings from the project scan."
	results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results.custom_minimum_size = Vector2(0, 220)
	add_child(results)

	_load_settings_into_controls()

func _scan_project() -> void:
	_set_scan_controls_enabled(false)
	status_label.text = "Scanning project..."
	latest_report.clear()
	results.clear()

	var scanner := ProjectScanner.new()
	var report: Dictionary = scanner.scan()
	latest_report = report

	var reports_dir_ready := _ensure_reports_dir()
	var markdown_ok := false
	var json_ok := false
	if reports_dir_ready:
		markdown_ok = MarkdownReportWriter.new().write(report, MARKDOWN_REPORT_PATH)
		json_ok = JsonReportWriter.new().write(report, JSON_REPORT_PATH)

	_render_report(report)
	if not reports_dir_ready:
		status_label.text = "Scan complete, but the reports folder could not be created."
	elif markdown_ok and json_ok:
		status_label.text = "Scan complete. Reports: %s | %s" % [MARKDOWN_REPORT_PATH, JSON_REPORT_PATH]
	else:
		status_label.text = "Scan complete with export issues. Check the Output/Debugger panel."
	_set_scan_controls_enabled(true)

func _ensure_reports_dir() -> bool:
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORTS_DIR)) == OK

func _render_report(report: Dictionary) -> void:
	latest_report = report

	var summary: Dictionary = report.get("summary", {})
	summary_label.text = "Errors: %d | Warnings: %d | Info: %d" % [
		summary.get("errors", 0),
		summary.get("warnings", 0),
		summary.get("info", 0)
	]

	_refresh_results()

func _refresh_results() -> void:
	results.clear()
	if latest_report.is_empty():
		return

	var root := results.create_item()
	var visible_count := 0
	for finding: Dictionary in latest_report.get("findings", []):
		if not _is_finding_visible(finding):
			continue

		var item := results.create_item(root)
		item.set_text(0, str(finding.get("severity", "info")).capitalize())
		item.set_text(1, str(finding.get("title", finding.get("id", "unknown"))))
		item.set_text(2, str(finding.get("path", "")))
		item.set_text(3, str(finding.get("message", "")))
		visible_count += 1

	if visible_count == 0:
		var empty_item := results.create_item(root)
		empty_item.set_text(3, "No findings match the active filters.")

func _create_filter_toggle(text: String, tooltip: String) -> CheckBox:
	var toggle := CheckBox.new()
	toggle.text = text
	toggle.button_pressed = true
	toggle.tooltip_text = tooltip
	toggle.toggled.connect(_on_filter_toggled)
	return toggle

func _on_filter_toggled(_enabled: bool) -> void:
	_refresh_results()

func _is_finding_visible(finding: Dictionary) -> bool:
	match str(finding.get("severity", "info")):
		"error":
			return errors_filter.button_pressed
		"warning":
			return warnings_filter.button_pressed
		_:
			return info_filter.button_pressed

func _open_reports_folder() -> void:
	if not _ensure_reports_dir():
		status_label.text = "Could not create reports folder: %s" % REPORTS_DIR
		return

	var open_error := OS.shell_open(ProjectSettings.globalize_path(REPORTS_DIR))
	if open_error == OK:
		status_label.text = "Opened reports folder: %s" % REPORTS_DIR
	else:
		status_label.text = "Could not open reports folder: %s" % REPORTS_DIR

func _open_markdown_report() -> void:
	_open_report_file(MARKDOWN_REPORT_PATH, "Markdown report")

func _open_json_report() -> void:
	_open_report_file(JSON_REPORT_PATH, "JSON report")

func _open_report_file(report_path: String, label: String) -> void:
	if not FileAccess.file_exists(report_path):
		status_label.text = "%s not found. Run a scan first." % label
		return

	var open_error := OS.shell_open(ProjectSettings.globalize_path(report_path))
	if open_error == OK:
		status_label.text = "Opened %s: %s" % [label.to_lower(), report_path]
	else:
		status_label.text = "Could not open %s: %s" % [label.to_lower(), report_path]

func _on_settings_toggle_toggled(pressed: bool) -> void:
	settings_container.visible = pressed

func _reload_settings() -> void:
	_load_settings_into_controls()
	status_label.text = "Reloaded scanner settings from %s" % SETTINGS_FILE_PATH

func _load_settings_into_controls() -> void:
	var settings := _load_settings()
	large_texture_threshold_spin.value = int(settings.get("large_texture_threshold", DEFAULT_LARGE_TEXTURE_THRESHOLD))
	scene_node_count_threshold_spin.value = int(settings.get("scene_node_count_threshold", DEFAULT_SCENE_NODE_COUNT_THRESHOLD))
	baseline_file_input.text = str(settings.get("baseline_file", DEFAULT_BASELINE_FILE))
	experimental_unused_checkbox.button_pressed = bool(settings.get("enable_experimental_unused_files", DEFAULT_ENABLE_EXPERIMENTAL_UNUSED_FILES))
	ignored_path_patterns_edit.text = "\n".join(settings.get("ignored_path_patterns", DEFAULT_IGNORED_PATH_PATTERNS))
	ignored_finding_ids_edit.text = "\n".join(settings.get("ignored_finding_ids", DEFAULT_IGNORED_FINDING_IDS))

func _load_settings() -> Dictionary:
	var settings := {
		"large_texture_threshold": DEFAULT_LARGE_TEXTURE_THRESHOLD,
		"scene_node_count_threshold": DEFAULT_SCENE_NODE_COUNT_THRESHOLD,
		"ignored_path_patterns": DEFAULT_IGNORED_PATH_PATTERNS.duplicate(),
		"ignored_finding_ids": DEFAULT_IGNORED_FINDING_IDS.duplicate(),
		"baseline_file": DEFAULT_BASELINE_FILE,
		"enable_experimental_unused_files": DEFAULT_ENABLE_EXPERIMENTAL_UNUSED_FILES
	}

	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE_PATH) != OK:
		return settings

	settings["large_texture_threshold"] = int(config.get_value("scanner", "large_texture_threshold", settings["large_texture_threshold"]))
	settings["scene_node_count_threshold"] = int(config.get_value("scanner", "scene_node_count_threshold", settings["scene_node_count_threshold"]))
	settings["ignored_path_patterns"] = _get_string_array_value(config.get_value("scanner", "ignored_path_patterns", settings["ignored_path_patterns"]), true)
	settings["ignored_finding_ids"] = _get_string_array_value(config.get_value("scanner", "ignored_finding_ids", settings["ignored_finding_ids"]), false)
	settings["baseline_file"] = _normalize_resource_path(str(config.get_value("scanner", "baseline_file", settings["baseline_file"])))
	settings["enable_experimental_unused_files"] = bool(config.get_value("scanner", "enable_experimental_unused_files", settings["enable_experimental_unused_files"]))
	return settings

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("scanner", "large_texture_threshold", int(large_texture_threshold_spin.value))
	config.set_value("scanner", "scene_node_count_threshold", int(scene_node_count_threshold_spin.value))
	config.set_value("scanner", "ignored_path_patterns", PackedStringArray(_get_text_edit_entries(ignored_path_patterns_edit, true)))
	config.set_value("scanner", "ignored_finding_ids", PackedStringArray(_get_text_edit_entries(ignored_finding_ids_edit, false)))
	config.set_value("scanner", "baseline_file", _normalize_resource_path(baseline_file_input.text))
	config.set_value("scanner", "enable_experimental_unused_files", experimental_unused_checkbox.button_pressed)

	var save_error := config.save(SETTINGS_FILE_PATH)
	if save_error != OK:
		status_label.text = "Could not save scanner settings: %s" % SETTINGS_FILE_PATH
		return

	_load_settings_into_controls()
	status_label.text = "Saved scanner settings to %s" % SETTINGS_FILE_PATH

func _get_text_edit_entries(text_edit: TextEdit, normalize_as_path: bool) -> Array[String]:
	var values: Array[String] = []
	for line in text_edit.text.split("\n", false):
		for entry in line.split(",", false):
			var normalized_value := _normalize_string_value(entry, normalize_as_path)
			if normalized_value != "":
				values.append(normalized_value)
	return values

func _get_string_array_value(raw_value: Variant, normalize_as_path: bool) -> Array[String]:
	var values: Array[String] = []

	if raw_value is PackedStringArray:
		for entry in raw_value:
			var normalized_entry := _normalize_string_value(str(entry), normalize_as_path)
			if normalized_entry != "":
				values.append(normalized_entry)
		return values

	if raw_value is Array:
		for entry in raw_value:
			var normalized_entry := _normalize_string_value(str(entry), normalize_as_path)
			if normalized_entry != "":
				values.append(normalized_entry)
		return values

	return _split_text_entries(str(raw_value), normalize_as_path)

func _split_text_entries(text: String, normalize_as_path: bool) -> Array[String]:
	var values: Array[String] = []
	for line in text.split("\n", false):
		for entry in line.split(",", false):
			var normalized_entry := _normalize_string_value(entry, normalize_as_path)
			if normalized_entry != "":
				values.append(normalized_entry)
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

func _set_scan_controls_enabled(enabled: bool) -> void:
	scan_button.disabled = not enabled
	open_reports_button.disabled = not enabled
	open_markdown_button.disabled = not enabled
	open_json_button.disabled = not enabled
	save_settings_button.disabled = not enabled
	reload_settings_button.disabled = not enabled
