@tool
extends SceneTree

const ProjectScanner = preload("res://addons/project_doctor_mini/scanner/project_scanner.gd")
const MarkdownReportWriter = preload("res://addons/project_doctor_mini/report/markdown_report_writer.gd")
const JsonReportWriter = preload("res://addons/project_doctor_mini/report/json_report_writer.gd")
const ExportPresetsCheck = preload("res://addons/project_doctor_mini/scanner/checks/export_presets_check.gd")
const ImportSettingsCheck = preload("res://addons/project_doctor_mini/scanner/checks/import_settings_check.gd")
const REPORTS_DIR := "res://reports"
const MARKDOWN_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.md"
const JSON_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.json"
const MARKDOWN_RENDER_CHECK_PATH := REPORTS_DIR + "/project-doctor-markdown-render-check.md"
const SETTINGS_FILE_PATH := "res://project_doctor_settings.cfg"
const BASELINE_FILE_PATH := "res://project_doctor_baseline.json"
const MISSING_EXPORT_PRESETS_FIXTURE := "res://tests/fixtures/scanner/export/missing_export_presets.cfg"
const INVALID_EXPORT_PRESET_FIXTURE := "res://tests/fixtures/scanner/export/invalid_export_presets.cfg"
const INCOMPLETE_EXPORT_PRESET_FIXTURE := "res://tests/fixtures/scanner/export/incomplete_export_presets.cfg"
const VALID_EXPORT_PRESET_FIXTURE := "res://tests/fixtures/scanner/export/valid_export_presets.cfg"
const MALFORMED_IMPORT_FIXTURE := "res://tests/fixtures/scanner/imports/malformed_texture.png.import"
const MISSING_SOURCE_IMPORT_FIXTURE := "res://tests/fixtures/scanner/imports/missing_source_texture.png.import"
const REQUIRED_REPORT_KEYS := [
	"tool",
	"tool_version",
	"generated_at",
	"project_root",
	"scan_duration_ms",
	"summary",
    "findings"
]
const REQUIRED_FINDING_KEYS := [
	"id",
	"severity",
	"title",
	"path",
	"message",
    "recommendation"
]
const ALLOWED_SEVERITIES := ["error", "warning", "info"]
const EXPECTED_FAKE_DOC_PATHS := [
	"res://assets/textures/example.png",
	"res://export_presets.cfg",
    "res://tests/fixtures/scanner/missing_from_code_block.png"
]
const EXPECTED_FIXTURE_REFERENCED_RESOURCE := "res://tests/fixtures/scanner/linked_data.tres"
const EXPECTED_FIXTURE_DIRECTORY := "res://tests/fixtures/scanner"
const EXPECTED_IGNORED_FIXTURE_FINDING_PATH := "res://tests/fixtures/scanner/ignored_area/broken_scene.tscn"
const EXPECTED_UNUSED_FIXTURE_RESOURCE := "res://tests/fixtures/scanner/unused_probe.tres"
const DEFAULT_IGNORED_PATH_PATTERNS := ["res://reports", "res://sandbox_screenshot", "res://docs/examples", "res://examples/demo_project/**", "res://tests/fixtures/**"]
const ACTIVE_FIXTURE_SCAN_PATTERNS := ["res://reports", "res://sandbox_screenshot", "res://docs/examples", "res://examples/demo_project/**"]

func _init() -> void:
	var scanner := ProjectScanner.new()
	var report: Dictionary = scanner.scan()
	var failures: Array[String] = []

	_validate_report(report, failures)
	_validate_scanner_behavior(report, failures)
	_validate_scanner_controls(failures)
	_validate_export_and_import_checks(failures)

	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORTS_DIR))
	if dir_error != OK:
		failures.append("Could not create reports directory: %s" % REPORTS_DIR)

	var markdown_ok := MarkdownReportWriter.new().write(report, MARKDOWN_REPORT_PATH)
	var json_ok := JsonReportWriter.new().write(report, JSON_REPORT_PATH)
	if not markdown_ok:
		failures.append("Markdown report writer returned false.")
	if not json_ok:
		failures.append("JSON report writer returned false.")

	if not FileAccess.file_exists(MARKDOWN_REPORT_PATH):
		failures.append("Markdown report was not written: %s" % MARKDOWN_REPORT_PATH)
	if not FileAccess.file_exists(JSON_REPORT_PATH):
		failures.append("JSON report was not written: %s" % JSON_REPORT_PATH)

	_validate_markdown_report_contents(report, failures)
	_validate_markdown_rendering(failures)

	if failures.is_empty():
		print("Project Doctor smoke test passed.")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)

func _validate_report(report: Dictionary, failures: Array[String]) -> void:
	for key: String in REQUIRED_REPORT_KEYS:
		if not report.has(key):
			failures.append("Report is missing required key: %s" % key)

	var summary := report.get("summary", {})
	if typeof(summary) != TYPE_DICTIONARY:
		failures.append("Report summary is not a dictionary.")
	else:
		for key: String in ["errors", "warnings", "info"]:
			if not summary.has(key):
				failures.append("Summary is missing required key: %s" % key)
			elif not _is_number(summary.get(key)):
				failures.append("Summary value is not numeric for key: %s" % key)

	if not _is_number(report.get("scan_duration_ms", null)):
		failures.append("scan_duration_ms is missing or not numeric.")

	var findings := report.get("findings", [])
	if typeof(findings) != TYPE_ARRAY:
		failures.append("Report findings is not an array.")
		return

	for finding_variant in findings:
		if typeof(finding_variant) != TYPE_DICTIONARY:
			failures.append("Finding entry is not a dictionary.")
			continue

		var finding: Dictionary = finding_variant
		for key: String in REQUIRED_FINDING_KEYS:
			if not finding.has(key):
				failures.append("Finding is missing required key: %s" % key)

		var severity := str(finding.get("severity", ""))
		if severity not in ALLOWED_SEVERITIES:
			failures.append("Finding has invalid severity: %s" % severity)

func _is_number(value: Variant) -> bool:
	var value_type := typeof(value)
	return value_type == TYPE_INT or value_type == TYPE_FLOAT

func _validate_scanner_behavior(report: Dictionary, failures: Array[String]) -> void:
	var findings: Array = report.get("findings", [])

	for fake_path in EXPECTED_FAKE_DOC_PATHS:
		if _has_finding(findings, "broken_resource_path", fake_path):
			failures.append("False positive broken_resource_path detected for example content: %s" % fake_path)

	if _has_finding(findings, "possibly_unused_file", EXPECTED_UNUSED_FIXTURE_RESOURCE):
		failures.append("Unused-file detection should be disabled by default: %s" % EXPECTED_UNUSED_FIXTURE_RESOURCE)

	if not _has_finding(findings, "export_presets_missing", "res://export_presets.cfg"):
		failures.append("Default project scan should still report export_presets_missing when export_presets.cfg is absent.")

func _validate_scanner_controls(failures: Array[String]) -> void:
	var original_settings := _read_optional_text(SETTINGS_FILE_PATH)
	var original_baseline := _read_optional_text(BASELINE_FILE_PATH)

	_write_settings(DEFAULT_IGNORED_PATH_PATTERNS, [], "", false)
	_write_baseline([])

	var fixture_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], "", false)
	if _has_finding(fixture_report.get("findings", []), "possibly_unused_file", EXPECTED_FIXTURE_REFERENCED_RESOURCE):
		failures.append("Markdown-linked fixture resource was reported as unused: %s" % EXPECTED_FIXTURE_REFERENCED_RESOURCE)
	if _has_finding(fixture_report.get("findings", []), "broken_resource_path", EXPECTED_FIXTURE_DIRECTORY):
		failures.append("Existing fixture directory was reported as broken: %s" % EXPECTED_FIXTURE_DIRECTORY)

	var ignored_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS + ["res://tests/fixtures/scanner/ignored_area/**"], [], "", false)
	if _has_finding(ignored_report.get("findings", []), "missing_script", EXPECTED_IGNORED_FIXTURE_FINDING_PATH):
		failures.append("Ignored folder fixture still produced finding: %s" % EXPECTED_IGNORED_FIXTURE_FINDING_PATH)

	var ignored_id_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, ["export_presets_missing"], "", false)
	if _has_finding(ignored_id_report.get("findings", []), "export_presets_missing", "res://export_presets.cfg"):
		failures.append("Ignored finding ID did not suppress export_presets_missing.")

	var baseline_entries := [ {
		"id": "export_presets_missing",
		"path": "res://export_presets.cfg"
	}]
	var baseline_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], BASELINE_FILE_PATH, false, baseline_entries)
	if _has_finding(baseline_report.get("findings", []), "export_presets_missing", "res://export_presets.cfg"):
		failures.append("Baseline did not suppress accepted finding export_presets_missing.")

	var experimental_unused_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], "", true)
	if not _has_finding(experimental_unused_report.get("findings", []), "possibly_unused_file", EXPECTED_UNUSED_FIXTURE_RESOURCE):
		failures.append("Experimental unused-file check did not flag the known unused fixture.")
	elif not _finding_message_contains(experimental_unused_report.get("findings", []), "possibly_unused_file", EXPECTED_UNUSED_FIXTURE_RESOURCE, "Experimental check"):
		failures.append("Experimental unused-file finding is missing the expected advisory wording.")

	var import_fixture_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], "", false)
	if not _has_finding(import_fixture_report.get("findings", []), "import_settings_unreadable", MALFORMED_IMPORT_FIXTURE):
		failures.append("Malformed import fixture was not reported through the scanner: %s" % MALFORMED_IMPORT_FIXTURE)

	var ignored_import_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS + ["res://tests/fixtures/scanner/imports/**"], [], "", false)
	if _has_finding(ignored_import_report.get("findings", []), "import_settings_unreadable", MALFORMED_IMPORT_FIXTURE):
		failures.append("Ignored import fixture path still produced finding: %s" % MALFORMED_IMPORT_FIXTURE)

	var import_baseline_entries := [ {
		"id": "import_settings_unreadable",
		"path": MALFORMED_IMPORT_FIXTURE
	}]
	var import_baseline_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], BASELINE_FILE_PATH, false, import_baseline_entries)
	if _has_finding(import_baseline_report.get("findings", []), "import_settings_unreadable", MALFORMED_IMPORT_FIXTURE):
		failures.append("Baseline did not suppress import_settings_unreadable for malformed fixture.")

	_restore_optional_text(SETTINGS_FILE_PATH, original_settings)
	_restore_optional_text(BASELINE_FILE_PATH, original_baseline)

func _validate_export_and_import_checks(failures: Array[String]) -> void:
	var missing_export_findings := ExportPresetsCheck.new().run(MISSING_EXPORT_PRESETS_FIXTURE)
	if not _has_finding(missing_export_findings, "export_presets_missing", MISSING_EXPORT_PRESETS_FIXTURE):
		failures.append("Missing export presets fixture did not report export_presets_missing.")

	var invalid_export_findings := ExportPresetsCheck.new().run(INVALID_EXPORT_PRESET_FIXTURE)
	if not _has_finding(invalid_export_findings, "export_presets_unreadable", INVALID_EXPORT_PRESET_FIXTURE):
		failures.append("Invalid export presets fixture did not report export_presets_unreadable.")

	var incomplete_export_findings := ExportPresetsCheck.new().run(INCOMPLETE_EXPORT_PRESET_FIXTURE)
	if not _has_finding(incomplete_export_findings, "export_preset_missing_export_path", INCOMPLETE_EXPORT_PRESET_FIXTURE):
		failures.append("Incomplete export preset fixture did not report export_preset_missing_export_path.")
	elif not _finding_message_contains(incomplete_export_findings, "export_preset_missing_export_path", INCOMPLETE_EXPORT_PRESET_FIXTURE, "Android"):
		failures.append("Incomplete export preset finding did not mention the affected platform/preset.")

	var valid_export_findings := ExportPresetsCheck.new().run(VALID_EXPORT_PRESET_FIXTURE)
	if not valid_export_findings.is_empty():
		failures.append("Valid export preset fixture produced noisy findings.")

	var malformed_import_findings := ImportSettingsCheck.new().run([MALFORMED_IMPORT_FIXTURE], 2048)
	if not _has_finding(malformed_import_findings, "import_settings_unreadable", MALFORMED_IMPORT_FIXTURE):
		failures.append("Malformed import fixture did not report import_settings_unreadable.")

	var missing_source_import_findings := ImportSettingsCheck.new().run([MISSING_SOURCE_IMPORT_FIXTURE], 2048)
	if not _has_finding(missing_source_import_findings, "import_settings_missing_source_file", MISSING_SOURCE_IMPORT_FIXTURE):
		failures.append("Missing-source import fixture did not report import_settings_missing_source_file.")

func _validate_markdown_report_contents(report: Dictionary, failures: Array[String]) -> void:
	var markdown_text_variant := _read_optional_text(MARKDOWN_REPORT_PATH)
	if markdown_text_variant == null:
		failures.append("Markdown report could not be read: %s" % MARKDOWN_REPORT_PATH)
		return

	var markdown_text := str(markdown_text_variant)
	if not markdown_text.contains("## Summary"):
		failures.append("Markdown report is missing the summary section.")
	if not markdown_text.contains("| Severity | Count |"):
		failures.append("Markdown report is missing the summary table header.")

	var summary: Dictionary = report.get("summary", {})
	var severity_groups := [
		{"key": "errors", "label": "Errors"},
		{"key": "warnings", "label": "Warnings"},
		{"key": "info", "label": "Info"}
	]
	for severity_group in severity_groups:
		var count := int(summary.get(severity_group.get("key", ""), 0))
		if count <= 0:
			continue

		var expected_summary := "<summary>%s (%d)</summary>" % [severity_group.get("label", ""), count]
		if not markdown_text.contains(expected_summary):
			failures.append("Markdown report is missing the expected severity details summary: %s" % expected_summary)

func _validate_markdown_rendering(failures: Array[String]) -> void:
	var sample_report := {
		"tool": "Godot Project Doctor Mini",
		"tool_version": "0.2.2",
		"generated_at": "2026-01-01T00:00:00",
		"project_root": "res://",
		"scan_duration_ms": 5,
		"summary": {
			"errors": 1,
			"warnings": 1,
			"info": 1
		},
		"findings": [
			{
				"id": "info_check",
				"severity": "info",
				"title": "Info `Tick`",
				"path": "res://info|path.gd",
				"message": "Info line 1\nInfo line 2",
				"recommendation": "Review `info` usage."
			},
			{
				"id": "broken_resource_path",
				"severity": "error",
				"title": "Broken `Resource`",
				"path": "res://broken|path.gd",
				"message": "Missing line 1\nMissing line 2",
				"recommendation": "Fix the `load()` target."
			},
			{
				"id": "large_texture",
				"severity": "warning",
				"title": "Large Texture",
				"path": "res://warning|texture.png",
				"message": "Too large for review",
				"recommendation": "Resize before export."
			}
		]
	}

	if not MarkdownReportWriter.new().write(sample_report, MARKDOWN_RENDER_CHECK_PATH):
		failures.append("Markdown render check report could not be written.")
		return

	var markdown_text_variant := _read_optional_text(MARKDOWN_RENDER_CHECK_PATH)
	if markdown_text_variant == null:
		failures.append("Markdown render check report could not be read.")
		return

	var markdown_text := str(markdown_text_variant)
	if not markdown_text.contains("| Severity | Count |"):
		failures.append("Markdown render check report is missing the summary table.")

	var expected_summaries := [
		"<summary>Errors (1)</summary>",
		"<summary>Warnings (1)</summary>",
        "<summary>Info (1)</summary>"
	]
	for expected_summary in expected_summaries:
		if not markdown_text.contains(expected_summary):
			failures.append("Markdown render check report is missing severity group: %s" % expected_summary)

	var error_index := markdown_text.find(expected_summaries[0])
	var warning_index := markdown_text.find(expected_summaries[1])
	var info_index := markdown_text.find(expected_summaries[2])
	if error_index == -1 or warning_index == -1 or info_index == -1 or not (error_index < warning_index and warning_index < info_index):
		failures.append("Markdown severity groups are not ordered Error -> Warning -> Info.")

	var details_count := markdown_text.split("<details open>", false).size() - 1
	if details_count != 3:
		failures.append("Markdown render check expected 3 collapsible sections, found %d." % details_count)

	if not markdown_text.contains("Broken \\`Resource\\`"):
		failures.append("Markdown render check did not escape backticks in finding titles.")
	if not markdown_text.contains("res://broken\\|path.gd"):
		failures.append("Markdown render check did not escape pipes in table cells.")
	if not markdown_text.contains("Missing line 1<br>Missing line 2"):
		failures.append("Markdown render check did not convert multiline text for table cells.")

func _has_finding(findings: Array, finding_id: String, path: String) -> bool:
	for finding_variant in findings:
		if typeof(finding_variant) != TYPE_DICTIONARY:
			continue

		var finding: Dictionary = finding_variant
		if str(finding.get("id", "")) == finding_id and str(finding.get("path", "")) == path:
			return true

	return false

func _finding_message_contains(findings: Array, finding_id: String, path: String, fragment: String) -> bool:
	for finding_variant in findings:
		if typeof(finding_variant) != TYPE_DICTIONARY:
			continue

		var finding: Dictionary = finding_variant
		if str(finding.get("id", "")) == finding_id and str(finding.get("path", "")) == path:
			return str(finding.get("message", "")).contains(fragment)

	return false

func _scan_with_settings(ignored_path_patterns: Array, ignored_finding_ids: Array, baseline_file: String, enable_experimental_unused_files: bool, accepted_findings: Array = []) -> Dictionary:
	_write_settings(ignored_path_patterns, ignored_finding_ids, baseline_file, enable_experimental_unused_files)
	_write_baseline(accepted_findings)
	return ProjectScanner.new().scan()

func _write_settings(ignored_path_patterns: Array, ignored_finding_ids: Array, baseline_file: String, enable_experimental_unused_files: bool) -> void:
	var config := ConfigFile.new()
	config.set_value("scanner", "large_texture_threshold", 2048)
	config.set_value("scanner", "scene_node_count_threshold", 250)
	config.set_value("scanner", "ignored_path_patterns", PackedStringArray(ignored_path_patterns))
	config.set_value("scanner", "ignored_finding_ids", PackedStringArray(ignored_finding_ids))
	config.set_value("scanner", "baseline_file", baseline_file)
	config.set_value("scanner", "enable_experimental_unused_files", enable_experimental_unused_files)
	config.save(SETTINGS_FILE_PATH)

func _write_baseline(accepted_findings: Array) -> void:
	var file := FileAccess.open(BASELINE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify({"accepted_findings": accepted_findings}, "  "))

func _read_optional_text(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	return file.get_as_text()

func _restore_optional_text(path: String, content: Variant) -> void:
	if content == null:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(str(content))
	file.flush()
