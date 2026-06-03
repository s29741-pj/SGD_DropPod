@tool
extends SceneTree

const ProjectScanner = preload("res://addons/project_doctor_mini/scanner/project_scanner.gd")
const MarkdownReportWriter = preload("res://addons/project_doctor_mini/report/markdown_report_writer.gd")
const JsonReportWriter = preload("res://addons/project_doctor_mini/report/json_report_writer.gd")
const REPORTS_DIR := "res://reports"
const MARKDOWN_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.md"
const JSON_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.json"

func _init() -> void:
    var scanner := ProjectScanner.new()
    var report: Dictionary = scanner.scan()
    var failures: Array[String] = []

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

    var summary: Dictionary = report.get("summary", {})
    print("Project Doctor scan complete: %d errors, %d warnings, %d info" % [
        summary.get("errors", 0),
        summary.get("warnings", 0),
        summary.get("info", 0)
    ])

    if failures.is_empty():
        quit(0)
        return

    for failure in failures:
        printerr(failure)
    quit(1)
