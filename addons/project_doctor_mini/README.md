# Godot Project Doctor Mini

Godot Project Doctor Mini is an editor-only Godot 4 plugin that scans the current project and writes Markdown and JSON diagnostic reports.

It helps catch common project hygiene issues before release:

- missing scripts,
- broken `res://` references,
- oversized textures,
- heavy scenes,
- empty folders,
- export preset readiness gaps,
- import settings issues.

## Install

1. Copy `addons/project_doctor_mini/` into your Godot project.
2. Open the project in Godot.
3. Go to `Project > Project Settings > Plugins`.
4. Enable `Godot Project Doctor Mini`.
5. Open the `Project Doctor` dock and run a scan.

## Reports

Each scan writes:

- `reports/project-doctor-report.md`
- `reports/project-doctor-report.json`

The Markdown report is designed to render cleanly on GitHub. The JSON report is stable enough for CI wrappers and PR summaries.

## Headless Scan

```text
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd
```

## License

MIT License. See `LICENSE`.
