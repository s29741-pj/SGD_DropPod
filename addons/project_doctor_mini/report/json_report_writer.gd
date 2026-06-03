@tool
extends RefCounted

func write(report: Dictionary, output_path: String) -> bool:
    var file := FileAccess.open(output_path, FileAccess.WRITE)
    if file == null:
        push_error("Could not write JSON report: %s" % output_path)
        return false

    file.store_string(JSON.stringify(report, "  "))
    return true
