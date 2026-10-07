# HeatFirm

HeatFirm game — Unity project (`unity/`) + Godot port (`godot/`).
Part of the calebhomwe arcade/game stable.

## Play / Test

- **Play in the browser:** https://calebhomwe.github.io/heat-firm/ (deployed by `.github/workflows/godot-web.yml` on every push to `main`; the `deploy` job enables Pages with Source = "GitHub Actions" on its first run — if repo policy blocks that, set it once under Settings → Pages). Each run also uploads the build as the `heat-firm-web` Actions artifact.
- **Play locally:** `godot --path godot` (Godot 4.7).
- **Test:** `godot --headless --path godot --script res://tests/run_tests.gd && godot --headless --path godot --script res://tests/test_sim_fixes.gd` (expects `PASS 70/70` and `PASS 81/81`).
- **Web export locally:** `godot --headless --path godot --export-release Web /tmp/heat-firm-web/index.html`.

`godot/` mirrors the maintained Godot project (`calebhomwe/heat-firm-godot`); see [godot/README.md](godot/README.md) for gameplay and controls. `unity/` is only the empty URP project shell (settings + sample scene, no scripts).
