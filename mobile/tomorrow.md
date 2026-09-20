# Chopper Mobile: pickup notes

Canonical handoff for the whole Chopper repo (web + mobile) lives one level up:

`../tomorrow.md`  (also at repo root: `chopper/tomorrow.md`)

Godot project to open locally:

`ChopperMobile/project.godot`

Source of truth for the full prompt sequence: `readme.md` in this same `mobile/` folder.

---

## Snapshot (2026-09-20)

**Done:** Prompts 1.1 through 5.1. Phase 3 (core systems) and Phase 4
(juice / audio / UI polish) are feature-complete per `readme.md`.
Prompt 4.3 added real pressed and disabled StyleBoxes for upgrades,
prestige, and element buttons; unaffordable cost labels turn red (and
"Pick an element" / locked prestige greys out); the Prestige button
pulses while `can_prestige()` is true; the three upcoming-tree cards
idle-sway out of phase; and the UI margin plus inner wood frame inset
by `DisplayServer.window_get_safe_area()` so notches do not cover
buttons. Sky / ground / outer frame stay full-bleed.

Prompt 5.1 (prestige UX) was done **without the Phase 4 playtest this
file previously called for** — the user explicitly chose to skip that
gate rather than pause. Prompts 2.2 through 4.3 (and now 5.1) still have
no confirmed real-editor playtest recorded anywhere in this repo.

Prompt 5.1 changes: the top-left `PrestigeBadge` now shows the current
multiplier too ("Prestige 2 - x1.2"), not just the level. The bottom
`PrestigeHint` label always previews the next multiplier, even long
before the player can afford it ("x1.0 -> x1.1 at 1000"), not just once
ready. Pressing the Prestige button no longer resets instantly: it opens
a new `PrestigeConfirmDialog` (`ConfirmationDialog`, scene root) spelling
out exactly what resets (Chops, Better Axe, Auto Chopper, Element Power,
current tree, active enchantments) and the permanent multiplier payoff;
only its `confirmed` signal actually calls `GameState.prestige_reset()`.
`GameState` gained a `prestiged(new_level, new_multiplier,
previous_multiplier)` signal, emitted at the end of `prestige_reset()`;
`main.gd`'s `_on_prestiged()` uses it to show a new centered
`PrestigeBanner` (gold-bordered `PrestigeBanner` theme type variation in
`chopper_theme.tres`, distinct from the small corner
`EnchantmentBanner`) that fades in, holds ~3s, and fades out with the
level and multiplier change spelled out.

`project.godot` and a batch of `.import`/`.uid` files appeared untracked
since an earlier session, with the feature tag bumped to Godot 4.7, meaning
the project has been opened in a real local editor at some point, but
whether any of Prompts 2.2 through 5.1 were actually played is not
recorded. Confirm before assuming a real playtest pass already happened.

**Next:** playtest Prompts 4.1–5.1 together in a real Godot editor
(nothing in this repo confirms any of it has run in a real Godot window
yet), specifically checking: the confirm dialog's text and buttons read
correctly and the wood theme applies to it, canceling changes nothing,
confirming actually resets and shows the centered prestige banner, and
the not-ready `PrestigeHint` text ("x1.0 -> x1.1 at 1000") does not clip
inside the button at that font size. Then Prompt 5.2 (balance and
progression curve). No mute button was added in 4.3; AudioManager mute
APIs from 4.2 are still there for a later control.

Paste the resume prompt from `../tomorrow.md` into Claude Code / Cursor.
