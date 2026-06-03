@tool
extends RefCounted

const DEFAULT_EXPORT_PRESETS_PATH := "res://export_presets.cfg"

func run(export_presets_path: String = DEFAULT_EXPORT_PRESETS_PATH) -> Array[Dictionary]:
    var findings: Array[Dictionary] = []

    if not FileAccess.file_exists(export_presets_path):
        findings.append(_make_finding(
            "export_presets_missing",
            export_presets_path,
            "warning",
            "Export Presets Missing",
            "Export presets are missing.",
            "Create export presets before release builds."
        ))
        return findings

    var config := ConfigFile.new()
    var load_error := config.load(export_presets_path)
    if load_error != OK:
        findings.append(_make_finding(
            "export_presets_unreadable",
            export_presets_path,
            "warning",
            "Export Presets Unreadable",
            "Project Doctor could not parse export_presets.cfg.",
            "Open export_presets.cfg in Godot or a text editor and fix the invalid preset syntax."
        ))
        return findings

    var preset_sections := _get_preset_sections(config)
    if preset_sections.is_empty():
        findings.append(_make_finding(
            "export_presets_empty",
            export_presets_path,
            "warning",
            "Export Presets Empty",
            "export_presets.cfg exists but does not define any export presets.",
            "Add at least one export preset before using Project Doctor for release readiness."
        ))
        return findings

    for preset_section in preset_sections:
        var platform := str(config.get_value(preset_section, "platform", "")).strip_edges()
        var preset_name := str(config.get_value(preset_section, "name", "")).strip_edges()
        var export_path := str(config.get_value(preset_section, "export_path", "")).strip_edges()
        var preset_label := _describe_preset(preset_section, platform, preset_name)

        if platform == "":
            findings.append(_make_finding(
                "export_preset_missing_platform",
                export_presets_path,
                "warning",
                "Export Preset Missing Platform",
                "%s is missing its platform value." % preset_label,
                "Open the preset in Godot and choose the intended export platform."
            ))

        if preset_name == "":
            findings.append(_make_finding(
                "export_preset_missing_name",
                export_presets_path,
                "warning",
                "Export Preset Missing Name",
                "%s is missing its display name." % preset_label,
                "Give the preset a clear name so release/export automation can identify it."
            ))

        if export_path == "":
            findings.append(_make_finding(
                "export_preset_missing_export_path",
                export_presets_path,
                "warning",
                "Export Preset Missing Export Path",
                "%s does not define an export path." % preset_label,
                "Set an export path for %s before relying on it in release automation." % preset_label
            ))

    return findings

func _get_preset_sections(config: ConfigFile) -> Array[String]:
    var preset_sections: Array[String] = []
    for section in config.get_sections():
        var section_name := str(section)
        if section_name.begins_with("preset.") and not section_name.contains(".options"):
            preset_sections.append(section_name)

    preset_sections.sort()
    return preset_sections

func _describe_preset(section_name: String, platform: String, preset_name: String) -> String:
    var details: Array[String] = []
    if platform != "":
        details.append(platform)
    if preset_name != "":
        details.append(preset_name)

    if details.is_empty():
        return "Export preset %s" % section_name

    return "Export preset %s (%s)" % [section_name, " / ".join(details)]

func _make_finding(id: String, path: String, severity: String, title: String, message: String, recommendation: String) -> Dictionary:
    return {
        "id": id,
        "severity": severity,
        "title": title,
        "path": path,
        "message": message,
        "recommendation": recommendation
    }
