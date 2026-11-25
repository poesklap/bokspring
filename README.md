# Bokspring

An Afrikaans learning game: a 5-lane veld runner. Tap the right answer and the springbok runs into its lane; obstacles fill every wrong lane.

Play: https://poesklap.github.io/bokspring/ (on iPhone: Safari → Share → Add to Home Screen, then it works offline).

## Layout

- `src/engine/`: learning engine (Leitner spaced repetition, scheduler, distractors, placement test, XP/streak). No UI code.
- `src/content/`: loader and validator for `content/*.json`.
- `src/skins/skin_base.gd`: the interface a game skin implements. `src/skins/bokspring/` is the runner.
- `src/ui/`: start menu, placement test, settings, theme. `src/speech/`: device Afrikaans voice. `src/storage/`: save, export and import.
- `content/`: word decks, placement questions, tips, `UNVERIFIED.md`, `REVIEW.md`.
- `assets/`, `audio/`: original art and sound (see `assets/STYLE_GUIDE.md`, `audio/README.md`).

## Commands

```bash
./tools/build.sh      # validate content, run tests, export web build, secret scan
./tools/deploy.sh     # build + publish to GitHub Pages (gh-pages branch)
godot --headless --path . -s res://tests/run_tests.gd   # tests only
```

Needs Godot 4.7.2 with web export templates.
