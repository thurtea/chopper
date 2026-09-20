# Chopper Mobile: pickup notes

Canonical handoff for the whole Chopper repo (web + mobile) lives one level up:

`../tomorrow.md`  (also at repo root: `chopper/tomorrow.md`)

Godot project to open locally:

`ChopperMobile/project.godot`

Source of truth for the full prompt sequence: `readme.md` in this same `mobile/` folder.

---

## Snapshot (2026-09-20)

**Done:** Prompts 1.1 through 4.3. Phase 3 (core systems) and Phase 4
(juice / audio / UI polish) are feature-complete per `readme.md`.
Prompt 4.3 added real pressed and disabled StyleBoxes for upgrades,
prestige, and element buttons; unaffordable cost labels turn red (and
"Pick an element" / locked prestige greys out); the Prestige button
pulses while `can_prestige()` is true; the three upcoming-tree cards
idle-sway out of phase; and the UI margin plus inner wood frame inset
by `DisplayServer.window_get_safe_area()` so notches do not cover
buttons. Sky / ground / outer frame stay full-bleed.

`project.godot` and a batch of `.import`/`.uid` files appeared untracked
since an earlier session, with the feature tag bumped to Godot 4.7, meaning
the project has been opened in a real local editor at some point, but
whether any of Prompts 2.2 through 4.3 were actually played is not
recorded. Confirm before assuming a real playtest pass already happened.

**Next:** playtest Prompts 4.1–4.3 in a real Godot editor, then Phase 5
Prompt 5.1 (prestige UX). Do not start 5.1 until that playtest has
happened. No mute button was added in 4.3; AudioManager mute APIs from
4.2 are still there for a later control.

Paste the resume prompt from `../tomorrow.md` into Claude Code / Cursor.
