@tool
extends SceneTree

const ProjectScanner = preload("res://addons/project_doctor_mini/scanner/project_scanner.gd")
const ExportPresetsCheck = preload("res://addons/project_doctor_mini/scanner/checks/export_presets_check.gd")
const ImportSettingsCheck = preload("res://addons/project_doctor_mini/scanner/checks/import_settings_check.gd")
const SETTINGS_FILE_PATH := "res://project_doctor_settings.cfg"
const BASELINE_FILE_PATH := "res://project_doctor_baseline.json"
const DEFAULT_IGNORED_PATH_PATTERNS := ["res://reports", "res://sandbox_screenshot", "res://docs/examples", "res://examples/demo_project/**", "res://tests/fixtures/**"]
const ACTIVE_FIXTURE_SCAN_PATTERNS := ["res://reports", "res://sandbox_screenshot", "res://docs/examples", "res://examples/demo_project/**"]
const BROKEN_RESOURCE_FIXTURE := "res://tests/fixtures/scanner/broken_resource_reference.gd"
const BROKEN_RESOURCE_PATH := "res://tests/fixtures/scanner/missing_fixture_asset.png"
const MALFORMED_IMPORT_FIXTURE := "res://tests/fixtures/scanner/imports/malformed_texture.png.import"
const MISSING_SOURCE_IMPORT_FIXTURE := "res://tests/fixtures/scanner/imports/missing_source_texture.png.import"
const EXPECTED_UNUSED_FIXTURE_RESOURCE := "res://tests/fixtures/scanner/unused_probe.tres"
const EXPECTED_IGNORED_FIXTURE_FINDING_PATH := "res://tests/fixtures/scanner/ignored_area/broken_scene.tscn"
const INCOMPLETE_EXPORT_PRESET_FIXTURE := "res://tests/fixtures/scanner/export/incomplete_export_presets.cfg"
const VALID_EXPORT_PRESET_FIXTURE := "res://tests/fixtures/scanner/export/valid_export_presets.cfg"

func _init() -> void:
	var failures: Array[String] = []
	var original_settings := _read_optional_text(SETTINGS_FILE_PATH)
	var original_baseline := _read_optional_text(BASELINE_FILE_PATH)

	_validate_baseline_and_ignores(failures)
	_validate_broken_resource_paths(failures)
	_validate_export_and_import_modules(failures)
	_validate_experimental_unused_behavior(failures)

	_restore_optional_text(SETTINGS_FILE_PATH, original_settings)
	_restore_optional_text(BASELINE_FILE_PATH, original_baseline)

	if failures.is_empty():
		print("Project Doctor scanner test passed.")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)

func _validate_baseline_and_ignores(failures: Array[String]) -> void:
	var ignored_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS + ["res://tests/fixtures/scanner/ignored_area/**"], [], "", false)
	if _has_finding(ignored_report.get("findings", []), "missing_script", EXPECTED_IGNORED_FIXTURE_FINDING_PATH):
		failures.append("Ignored path pattern did not suppress missing_script for ignored_area fixture.")

	var ignored_id_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, ["broken_resource_path"], "", false)
	if _has_finding(ignored_id_report.get("findings", []), "broken_resource_path", BROKEN_RESOURCE_PATH):
		failures.append("Ignored finding ID did not suppress broken_resource_path for fixture resource.")

	var baseline_entries := [
		{
			"id": "import_settings_unreadable",
			"path": MALFORMED_IMPORT_FIXTURE
		}
	]
	var baseline_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], BASELINE_FILE_PATH, false, baseline_entries)
	if _has_finding(baseline_report.get("findings", []), "import_settings_unreadable", MALFORMED_IMPORT_FIXTURE):
		failures.append("Baseline did not suppress import_settings_unreadable for malformed fixture.")

func _validate_broken_resource_paths(failures: Array[String]) -> void:
	var report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], "", false)
	if not _has_finding(report.get("findings", []), "broken_resource_path", BROKEN_RESOURCE_PATH):
		failures.append("Broken resource fixture did not produce broken_resource_path for missing fixture asset.")

func _validate_export_and_import_modules(failures: Array[String]) -> void:
	var export_findings := ExportPresetsCheck.new().run(INCOMPLETE_EXPORT_PRESET_FIXTURE)
	if not _has_finding(export_findings, "export_preset_missing_export_path", INCOMPLETE_EXPORT_PRESET_FIXTURE):
		failures.append("Incomplete export preset fixture did not produce export_preset_missing_export_path.")

	var valid_export_findings := ExportPresetsCheck.new().run(VALID_EXPORT_PRESET_FIXTURE)
	if not valid_export_findings.is_empty():
		failures.append("Valid export preset fixture produced findings in scanner test.")

	var malformed_import_findings := ImportSettingsCheck.new().run([MALFORMED_IMPORT_FIXTURE], 2048)
	if not _has_finding(malformed_import_findings, "import_settings_unreadable", MALFORMED_IMPORT_FIXTURE):
		failures.append("Malformed import fixture did not produce import_settings_unreadable.")

	var missing_source_findings := ImportSettingsCheck.new().run([MISSING_SOURCE_IMPORT_FIXTURE], 2048)
	if not _has_finding(missing_source_findings, "import_settings_missing_source_file", MISSING_SOURCE_IMPORT_FIXTURE):
		failures.append("Missing-source import fixture did not produce import_settings_missing_source_file.")

func _validate_experimental_unused_behavior(failures: Array[String]) -> void:
	var default_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], "", false)
	if _has_finding(default_report.get("findings", []), "possibly_unused_file", EXPECTED_UNUSED_FIXTURE_RESOURCE):
		failures.append("Experimental unused-file finding appeared while disabled.")

	var enabled_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], "", true)
	if not _has_finding(enabled_report.get("findings", []), "possibly_unused_file", EXPECTED_UNUSED_FIXTURE_RESOURCE):
		failures.append("Experimental unused-file finding did not appear when enabled.")

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

func _has_finding(findings: Array, finding_id: String, path: String) -> bool:
	for finding_variant in findings:
		if typeof(finding_variant) != TYPE_DICTIONARY:
			continue

		var finding: Dictionary = finding_variant
		if str(finding.get("id", "")) == finding_id and str(finding.get("path", "")) == path:
			return true

	return false
