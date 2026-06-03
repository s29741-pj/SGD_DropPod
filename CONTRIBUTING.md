# Contributing

Thanks for considering a contribution to Godot Project Doctor Mini.

This project is still an early MVP, so small focused changes are the easiest to review and merge.

## Good First Contributions

- Add or improve one scanner check.
- Reduce false positives in an existing check.
- Improve Markdown or JSON report formatting.
- Add a small sample project fixture for testing.
- Improve documentation, screenshots, or examples.

## Development Setup

1. Install Godot 4.6.x.
2. Open this repository in Godot.
3. Enable `Godot Project Doctor Mini` from `Project > Project Settings > Plugins`.
4. Use any code editor you prefer for GDScript files.

## Local Checks

Run these before opening a pull request:

```text
godot --headless --path . --quit
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_doctor_smoke_test.gd
```

The scanner currently reports a missing `export_presets.cfg` warning when no export presets exist. That warning is expected for the MVP repository.

## Pull Request Guidelines

- Keep PRs small and focused.
- Describe the user-visible behavior change.
- Mention any known limitations or false positives.
- Include before/after report output when changing scanner behavior.
- Do not remove existing checks unless the replacement is already implemented.

## Coding Style

- Keep the plugin GDScript-first.
- Prefer simple, readable code over clever abstractions.
- Keep report fields stable unless there is a clear migration reason.
- Treat `error`, `warning`, and `info` severities consistently.

## Reporting Issues

When reporting a scanner issue, include:

- Godot version
- operating system
- scan output summary
- the finding that looks wrong
- a minimal example if possible

Avoid sharing private project assets in issues. A small reproduction project or sanitized snippet is best.
