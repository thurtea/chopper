# Chopper Mobile — pickup notes

Canonical handoff for the whole Chopper repo (web + mobile) lives one level up:

`../tomorrow.md`  (also at repo root: `chopper/tomorrow.md`)

Godot project to open locally:

`ChopperMobile/project.godot`

Source of truth for the full prompt sequence: `readme.md` in this same `mobile/` folder.

---

## Snapshot (2026-09-20)

**Done:** Prompts 1.1, 1.2, 2.1, 2.2: scaffold, wooden UI, data models,
GameState, and manual chopping. Tapping the tree now deals damage, shows
floating numbers, shakes the screen, bursts particles, plays a hit sound,
and on kill plays a tree-fall animation, awards Chops, and pulls the next
tree from the queue. App icon = `chopper-logo.jpg`.

Not yet opened in the Godot editor to playtest (Godot is not installed in
this sandbox). Needs a real playtest pass before calling 2.2 done, per
`readme.md`'s own "test after each major prompt" rule.

**Next:** Prompt 2.3: weighted upcoming-tree queue generation (current
generation is a flat random pick, just enough to keep the queue full).

Paste the resume prompt from `../tomorrow.md` into Claude Code / Cursor.
