@tool
extends RefCounted

const TEXTURE_SOURCE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]

func run(files: Array[String], large_texture_threshold: int) -> Array[Dictionary]:
    var findings: Array[Dictionary] = []

    for file_path in files:
        if file_path.get_extension().to_lower() != "import":
            continue

        findings.append_array(_check_import_file(file_path, large_texture_threshold))

    return findings

func _check_import_file(file_path: String, large_texture_threshold: int) -> Array[Dictionary]:
    var findings: Array[Dictionary] = []
    var config := ConfigFile.new()
    var load_error := config.load(file_path)
    if load_error != OK:
        findings.append(_make_finding(
            "import_settings_unreadable",
            file_path,
            "warning",
            "Import Settings Unreadable",
            "Project Doctor could not parse this .import file.",
            "Reimport the asset in Godot or repair the invalid .import file syntax."
        ))
        return findings

    var source_file := _normalize_resource_path(str(config.get_value("deps", "source_file", "")))
    var dest_files := _get_string_array_value(config.get_value("deps", "dest_files", []), false)
    var importer := str(config.get_value("remap", "importer", "")).strip_edges()

    if source_file == "":
        findings.append(_make_finding(
            "import_settings_missing_source_reference",
            file_path,
            "warning",
            "Import Settings Missing Source Reference",
            "The .import file does not define deps/source_file.",
            "Reimport the asset so Godot regenerates the source_file reference."
        ))
        return findings

    if not FileAccess.file_exists(source_file):
        findings.append(_make_finding(
            "import_settings_missing_source_file",
            file_path,
            "warning",
            "Import Settings Missing Source File",
            "The .import file references a missing source asset: %s" % source_file,
            "Restore the source asset or reimport it so the .import file points at a valid path."
        ))

    if dest_files.is_empty():
        findings.append(_make_finding(
            "import_settings_missing_dest_files",
            file_path,
            "warning",
            "Import Settings Missing Dest Files",
            "The .import file does not list any generated dest_files entries.",
            "Reimport the asset so Godot rewrites the generated import targets."
        ))

    if importer == "texture":
        findings.append_array(_check_texture_import_settings(file_path, source_file, config, large_texture_threshold))

    return findings

func _check_texture_import_settings(file_path: String, source_file: String, config: ConfigFile, large_texture_threshold: int) -> Array[Dictionary]:
    var findings: Array[Dictionary] = []
    if not _is_texture_source(source_file):
        return findings
    if not FileAccess.file_exists(source_file):
        return findings

    var compression_mode := int(config.get_value("params", "compress/mode", -1))
    if compression_mode != 0:
        return findings

    var image := Image.new()
    if image.load(source_file) != OK:
        return findings

    var width := image.get_width()
    var height := image.get_height()
    if width <= large_texture_threshold and height <= large_texture_threshold:
        return findings

    findings.append(_make_finding(
        "import_texture_large_uncompressed",
        file_path,
        "warning",
        "Large Texture Import Uses Raw Mode",
        "Texture source %s is %dx%d and its import settings use compress/mode=0." % [source_file, width, height],
        "Enable a texture compression/import mode or reduce the source size before export."
    ))
    return findings

func _get_string_array_value(raw_value: Variant, normalize_as_path: bool) -> Array[String]:
    var values: Array[String] = []

    if raw_value is PackedStringArray:
        for entry in raw_value:
            var normalized_entry := _normalize_value(str(entry), normalize_as_path)
            if normalized_entry != "":
                values.append(normalized_entry)
        return values

    if raw_value is Array:
        for entry in raw_value:
            var normalized_entry := _normalize_value(str(entry), normalize_as_path)
            if normalized_entry != "":
                values.append(normalized_entry)
        return values

    var normalized_value := _normalize_value(str(raw_value), normalize_as_path)
    if normalized_value != "":
        values.append(normalized_value)
    return values

func _normalize_value(value: String, normalize_as_path: bool) -> String:
    return _normalize_resource_path(value) if normalize_as_path else value.strip_edges()

func _normalize_resource_path(path: String) -> String:
    var trimmed_path := path.strip_edges()
    if trimmed_path == "":
        return ""
    if trimmed_path.begins_with("res://"):
        return trimmed_path.trim_suffix("/")
    return ("res://" + trimmed_path.trim_prefix("./")).trim_suffix("/")

func _is_texture_source(source_file: String) -> bool:
    return source_file.get_extension().to_lower() in TEXTURE_SOURCE_EXTENSIONS

func _make_finding(id: String, path: String, severity: String, title: String, message: String, recommendation: String) -> Dictionary:
    return {
        "id": id,
        "severity": severity,
        "title": title,
        "path": path,
        "message": message,
        "recommendation": recommendation
    }
