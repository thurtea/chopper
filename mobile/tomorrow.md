# Chopper Mobile: pickup notes

Canonical handoff for the whole Chopper repo (web + mobile) lives one level up:

`../tomorrow.md`  (also at repo root: `chopper/tomorrow.md`)

Godot project to open locally:

`ChopperMobile/project.godot`

Source of truth for the full prompt sequence: `readme.md` in this same `mobile/` folder.

---

## Snapshot (2026-09-20)

**Done:** Prompts 1.1, 1.2, 2.1, 2.2, 2.3, 3.1, 3.2: scaffold, wooden UI,
data models, GameState, manual chopping, weighted queue generation, the
four core upgrades, and the elemental system. Tapping the tree deals
damage, shows floating numbers, shakes the screen, bursts particles, plays
a hit sound, and on kill plays a tree-fall animation, awards Chops, and
pulls the next tree from the queue. Better Axe, Auto Chopper, Element
Power, and Prestige Reset are all buyable, all costs/values live in
`scripts/upgrade_config.gd`, and their buttons disable when unaffordable.
The five Fire/Ice/Bolt/Earth/Wind buttons are now real single-select
toggles (`GameState.select_element()`) that decide what Element Power
activates, and two new visual indicators show it: a badge above Chopper,
and "(Weak!)"/"(Resist)" appended to the tree's own element badge. Also
fixed a bug found along the way: matching elements now correctly count as
a damage bonus, not neutral (`TreeData.elemental_multiplier()`).
App icon = `chopper-logo.jpg`.

None of Prompts 2.2 through 3.2 have been opened in the Godot editor to
playtest yet (Godot is not installed in this sandbox). Needs a real
playtest pass, including confirming the element buttons visibly toggle
and both new badges read correctly, before starting Prompt 3.3.

**Next:** playtest Phase 2 + Phase 3 so far, then Prompt 3.3 (Phase 3): the
enchantment system (Empowered, Elemental Surge, Gold Rush, Auto Boost).

Paste the resume prompt from `../tomorrow.md` into Claude Code / Cursor.
