# Chopper Mobile: pickup notes

Canonical handoff for the whole Chopper repo (web + mobile) lives one level up:

`../tomorrow.md`  (also at repo root: `chopper/tomorrow.md`)

Godot project to open locally:

`ChopperMobile/project.godot`

Source of truth for the full prompt sequence: `readme.md` in this same `mobile/` folder.

---

## Snapshot (2026-09-20)

**Done:** Prompts 1.1, 1.2, 2.1, 2.2, 2.3, 3.1: scaffold, wooden UI, data
models, GameState, manual chopping, weighted queue generation, and the four
core upgrades. Tapping the tree deals damage, shows floating numbers, shakes
the screen, bursts particles, plays a hit sound, and on kill plays a
tree-fall animation, awards Chops, and pulls the next tree from the queue
(element weighted via `GameState._pick_weighted_element()`, NONE trees a
deliberate minority). Better Axe, Auto Chopper, Element Power, and Prestige
Reset are all buyable, all costs/values live in
`scripts/upgrade_config.gd`, and their buttons disable when unaffordable.
Auto Chopper actually ticks Chops in over time now (`GameState._process()`).
App icon = `chopper-logo.jpg`.

Known placeholder: `buy_element_power()` picks a random element rather than
reading player choice, since the five Fire/Ice/Bolt/Earth/Wind buttons are
not wired up yet. That is Prompt 3.2's job.

None of Prompts 2.2, 2.3, or 3.1 have been opened in the Godot editor to
playtest yet (Godot is not installed in this sandbox). Needs a real
playtest pass, including buying each upgrade and confirming Auto Chopper
and Prestige actually work as expected, before starting Prompt 3.2.

**Next:** playtest Phase 2 + Prompt 3.1, then Prompt 3.2 (Phase 3): wire the
five element buttons as the real Element Power selector, plus visual
indicators on Chopper and the current tree when an element is active.

Paste the resume prompt from `../tomorrow.md` into Claude Code / Cursor.
