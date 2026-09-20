# Chopper Mobile: pickup notes

Canonical handoff for the whole Chopper repo (web + mobile) lives one level up:

`../tomorrow.md`  (also at repo root: `chopper/tomorrow.md`)

Godot project to open locally:

`ChopperMobile/project.godot`

Source of truth for the full prompt sequence: `readme.md` in this same `mobile/` folder.

---

## Snapshot (2026-09-20)

**Done:** Prompts 1.1, 1.2, 2.1, 2.2, 2.3: scaffold, wooden UI, data models,
GameState, manual chopping, and weighted queue generation. Tapping the tree
deals damage, shows floating numbers, shakes the screen, bursts particles,
plays a hit sound, and on kill plays a tree-fall animation, awards Chops,
and pulls the next tree from the queue. That next tree's element is now
picked by `GameState._pick_weighted_element()`, weighted against the
current_tree + upcoming_trees window so the player sees a real mix rather
than long same-element runs, and NONE trees stay a deliberate minority.
App icon = `chopper-logo.jpg`.

Phase 2 (the core chopping loop) is feature-complete per `readme.md`, but
none of it has been opened in the Godot editor to playtest yet (Godot is
not installed in this sandbox). Needs a real playtest pass, including
watching the preview strip over several kills to confirm the element mix
actually feels varied, before starting Phase 3.

**Next:** playtest Phase 2, then Prompt 3.1 (Phase 3): the four core
upgrades (Better Axe, Auto Chopper, Element Power, Prestige Reset).

Paste the resume prompt from `../tomorrow.md` into Claude Code / Cursor.
