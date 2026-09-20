# Chopper Mobile: pickup notes

Canonical handoff for the whole Chopper repo (web + mobile) lives one level up:

`../tomorrow.md`  (also at repo root: `chopper/tomorrow.md`)

Godot project to open locally:

`ChopperMobile/project.godot`

Source of truth for the full prompt sequence: `readme.md` in this same `mobile/` folder.

---

## Snapshot (2026-09-20)

**Done:** Prompts 1.1 through 5.3 — all of Phase 5 is now implemented.
Phase 3 (core systems) and Phase 4
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

Prompt 5.2 changes (also done without a playtest, at the user's explicit
request to continue straight through): the old tree scaling
(`max_health = 80 + level*20*difficulty`, `chop_reward = 5*level*difficulty`)
made the very first tree take 50-70 taps for only 5-15 Chops, badly
undercutting the design doc's "early game feels fast." New
`UpgradeConfig.tree_max_health()` / `tree_chop_reward()`
(`TREE_HEALTH_BASE = 6`, `TREE_HEALTH_PER_LEVEL = 5`, `TREE_REWARD_BASE
= 2`, `TREE_REWARD_PER_LEVEL = 2.5`) get the first kill down to roughly
5-10 taps. The prestige multiplier (`chopper.prestige_multiplier`)
boosts both damage and reward, so the old flat 1000-Chop threshold would
have made every later prestige cycle collapse toward near-instant;
`UpgradeConfig.prestige_threshold_for_level()` now grows the threshold
1.3x per level (and `PRESTIGE_MULTIPLIER_PER_LEVEL` moved from `0.1` to
`0.18`) to hold cycles in a simulated ~6.5-9 minute band across 8
prestiges, inside the doc's 5-15 minute target. Every other balance
number that was still hardcoded elsewhere — `TreeData.elemental_multiplier()`'s
1.5/0.65, and each `EnchantmentData` static constructor's magnitude and
duration, plus the enchantment grant chance/milestone interval — moved
into `UpgradeConfig` too (values unchanged except where noted above),
per the design doc's explicit "expose all key constants in one place."
Full formulas and reasoning: `../tomorrow.md`.

Prompt 5.3 changes (save/load, also done without a playtest, at the
user's explicit request to continue straight through): `GameState`
(`autoload/game_state.gd`) gained `_save_game()` / `_load_game()`,
writing the whole run as JSON to `user://save.json` — total Chops, the
three upgrade levels, prestige level, the full `ChopperData` (damage,
auto-chop rate, active/selected element, prestige multiplier, Element
Power trees left), the current tree and entire upcoming queue, every
active enchantment, and two internal counters (enchantment-milestone
kill count, the fractional Auto Chopper accumulator) so those survive a
restart exactly rather than just approximately. `_ready()` now tries
`_load_game()` first and only falls back to the original hardcoded
starting queue if there is no valid save (missing file, bad JSON, or a
version mismatch via the new `version: 1` field). Saves fire after
every tree kill and after every successful Better Axe / Auto Chopper /
Element Power / Prestige purchase — never on a plain non-killing hit or
a failed/unaffordable buy. Audio settings are deliberately NOT in this
file: `AudioManager` has saved/loaded those independently to
`user://audio.cfg` since Prompt 4.2 and still does, so that checklist
item was already covered going in. `main.gd` needed no changes; it
already reads everything through `GameState`'s public vars. Full
reasoning: `../tomorrow.md`.

`project.godot` and a batch of `.import`/`.uid` files appeared untracked
since an earlier session, with the feature tag bumped to Godot 4.7, meaning
the project has been opened in a real local editor at some point, but
whether any of Prompts 2.2 through 5.3 were actually played is not
recorded. Confirm before assuming a real playtest pass already happened.

**Next:** playtest Prompts 4.1–5.3 together in a real Godot editor
(nothing in this repo confirms any of it has run in a real Godot window
yet), specifically checking: the confirm dialog's text and buttons read
correctly and the wood theme applies to it, canceling changes nothing,
confirming actually resets and shows the centered prestige banner, the
not-ready `PrestigeHint` text (now e.g. "x1.0 -> x1.18 at 1000") does
not clip inside the button at that font size, whether the faster early
trees and the prestige cadence from 5.2 actually feel right in practice,
and — new for 5.3 — whether `user://save.json` actually round-trips
across a real app quit and relaunch (Chops, upgrades, prestige, current
tree, queue, and enchantments should all match where the session left
off), plus that a fresh install with no save file still starts clean.
Then Phase 6 (mobile polish/release). No mute button was added in 4.3;
AudioManager mute APIs from 4.2 are still there for a later control.

Paste the resume prompt from `../tomorrow.md` into Claude Code / Cursor.
