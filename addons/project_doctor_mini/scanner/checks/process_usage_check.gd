@tool
extends RefCounted

func run(files: Array[String], read_text_file: Callable) -> Array[Dictionary]:
    var findings: Array[Dictionary] = []

    for file_path in files:
        if file_path.get_extension().to_lower() != "gd":
            continue

        var text := str(read_text_file.call(file_path))
        if text == "":
            continue

        for line in text.split("\n"):
            if line.strip_edges().begins_with("func _process("):
                findings.append({
                    "id": "process_usage",
                    "severity": "info",
                    "title": "Process Usage",
                    "path": file_path,
                    "message": "Script implements _process().",
                    "recommendation": "Confirm per-frame work is necessary and lightweight."
                })
                break

    return findings
