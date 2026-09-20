# Chopper Clicker: Session Handoff (2026-09-20, updated)

Repo: https://github.com/thurtea/chopper
Local: `/Users/thurtea/Work/chopper`
Godot project: `mobile/ChopperMobile/`
Design + prompt sequence: `mobile/readme.md`

Godot is not installed in the Claude/Cursor sandbox. Edit files here, then open
`mobile/ChopperMobile/project.godot` in a local Godot 4.3+ editor to playtest.

Since the last session, `project.godot` and a batch of `.import`/`.uid` files
showed up untracked in the working tree, bumping the project's feature tag to
"4.7". That means the project has been opened in a real local Godot 4.7
editor at some point. Whether Prompts 2.2 through 3.2 were actually
playtested there, or the editor was just opened once, is not recorded here;
confirm before assuming the "Not done: playtest pass" items below are
already covered.

---

## Progress

### Done

**Web toolkit** (`index.html`, `main.js`, `main.css`, staff tools): separate from the mobile game.

**ChopperMobile Phase 1 + 2.1**

- Godot 4 project, mobile renderer, portrait `720×1280`
- Folders: `scenes/`, `scripts/`, `assets/sprites|audio|fonts|themes/`, `autoload/`
- Autoload `GameState`
- Main UI skeleton with wooden theme (`chopper_theme.tres`): top stats, tree area, Chopper sprite, upcoming-tree preview strip, bottom upgrade panel
- Data models: `TreeData`, `ChopperData`, `EnchantmentData`
- `GameState` holds chops, upgrade levels, prestige, chopper, current_tree, upcoming_trees, active_enchantments
- App icon wired to `chopper-logo.jpg` (default `icon.svg` removed)
- Hit SFX present: `assets/audio/axe-impact.mp3`, `axe-slash.mp3`
- Concept art / favicons committed under `mobile/` and `favicon_io-chopper/`

**ChopperMobile Prompt 2.2: Basic chopping**

- `TreeSprite` now has a `gui_input` handler (`scripts/main.gd`): tap/click
  triggers `GameState.chop_current_tree()` (`autoload/game_state.gd`), which
  subtracts axe damage (applying `TreeData.elemental_multiplier()` if an
  element is active), awards Chops and advances the queue on kill.
- New `TreeData.elemental_multiplier()`: a five-element wheel (Fire > Ice >
  Bolt > Earth > Wind > Fire) for bonus/penalty damage. Currently dormant in
  play since there is no way yet to buy/activate Element Power (Prompt 3.1);
  the code path is ready for when 3.1/3.2 wire that up.
- Floating damage numbers, axe-swing tween on `chopper.png` (anticipate ->
  hit -> recover), tree-fall tween + pop-in for the next tree, screen shake,
  and a leaf/wood-chip `CPUParticles2D` burst (bigger on kill) are all live.
  Hit sound (`assets/audio/axe-impact.mp3`) originally played via a plain
  `AudioStreamPlayer` node; Prompt 4.2 replaced that call site with
  `AudioManager.play_hit()` / `play_swing()`.

**ChopperMobile Prompt 2.3: Upcoming tree queue & preview**

- `GameState._generate_tree()`'s element pick is now weighted
  (`_pick_weighted_element()`), not the flat uniform pick Prompt 2.2 shipped
  as a placeholder. See "How the weighting works" below.
  Difficulty (stars) is still a plain uniform 1-3 roll, and the five-element
  wheel itself (`TreeData.elemental_multiplier()`) is unchanged, both on
  purpose.
- Queue pop/append mechanics (`_advance_tree()`, `_next_queue_level()`) are
  unchanged from Prompt 2.2.

**ChopperMobile Prompt 3.1: Upgrade system**

- New `scripts/upgrade_config.gd` (`class_name UpgradeConfig`): the one
  tunable place for every upgrade cost/value. See "How costs/values are
  tuned" below.
- `GameState.buy_better_axe()` / `buy_auto_chopper()` / `buy_element_power()`
  / `prestige_reset()` (plus `can_prestige()`): each checks affordability,
  spends Chops, and applies its real effect. None of them do anything if
  the player cannot afford it.
- Better Axe raises `chopper.axe_damage`; Auto Chopper raises
  `chopper.auto_chop_rate`, which a new `GameState._process(delta)` now
  actually converts into Chops over time (a small float accumulator handles
  fractional rates without losing them). Element Power activates
  `chopper.active_element` for `UpgradeConfig.ELEMENT_POWER_TREES` kills
  (counted down in `_advance_tree()`), applying the existing
  `TreeData.elemental_multiplier()` from Prompt 2.2 for real damage
  bonus/penalty. Prestige Reset resets the run and raises
  `chopper.prestige_multiplier`, which now multiplies both chop damage and
  Chop rewards (kill and passive) in `chop_current_tree()`/`_process()`.
- `scripts/main.gd`'s four upgrade buttons are wired to those functions and
  disable themselves (`Button.disabled`) whenever the player cannot afford
  them; cost/status labels (`AxeCost`, `AutoCost`, `ElementCost`,
  `PrestigeHint`) show live values instead of Prompt 1.2's static text.
- Was a placeholder as of Prompt 3.1: which element Element Power activates
  was a random pick, and the five Fire/Ice/Bolt/Earth/Wind buttons did
  nothing. Both resolved in Prompt 3.2, see below.

**ChopperMobile Prompt 3.2: Elemental system**

- `GameState.select_element()` (new): the five Fire/Ice/Bolt/Earth/Wind
  buttons now call this on press, setting `chopper.selected_element`.
  `buy_element_power()` uses that real selection instead of Prompt 3.1's
  random placeholder, and now fails (like an unaffordable purchase) if
  nothing is selected yet.
- The five buttons are real single-select toggles now (`toggle_mode` +
  a shared `ButtonGroup` in `scenes/main.tscn`), so whichever element is
  selected stays visibly pressed in its own color (the per-element
  pressed StyleBoxFlat resources already existed from Phase 1.2, unused
  until now). `main.gd`'s `_refresh_element_buttons()` keeps this in sync
  with `chopper.selected_element`, including resetting the buttons after
  a Prestige Reset clears the selection.
- **Bug fix surfaced while wiring this up:** `TreeData.elemental_multiplier()`
  (Prompt 2.2) treated attacking with the *same* element the tree has as
  neutral. The design doc's own Prompt 3.2 wording ("Matching element =
  bonus damage") makes clear that is wrong: matching now correctly
  returns the bonus multiplier. Opposing/neutral logic (the five-element
  wheel) is unchanged.
- New visual indicators, both in `main.gd`'s `_refresh_ui()`:
  - **Chopper**: new `ChopperElementBadge` label above Chopper (new
    `ChopperColumn` wrapper in `scenes/main.tscn`, mirroring
    `TreeColumn`'s existing label-above-sprite layout). Shows
    "`<Element> Power (N left)`" in that element's color while active,
    empty otherwise.
  - **Tree**: the existing `TreeElementBadge` (already showing the
    tree's own element since Phase 1.2) now also appends "(Weak!)" in
    gold or "(Resist)" in grey when Element Power is active and the
    matchup is favourable or unfavourable, so the player can read the
    actual strategic payoff at a glance.

**ChopperMobile Prompt 3.3: Enchantment system**

- Granting: `GameState._maybe_grant_enchantment()` runs once per kill
  (inside `chop_current_tree()`, after `_advance_tree()`). Guaranteed
  every `EnchantmentData.MILESTONE_INTERVAL` kills (10), otherwise a flat
  `EnchantmentData.GRANT_CHANCE` chance (18%) per kill. Both constants
  live on `EnchantmentData` itself, the natural home next to the four
  static constructors they gate. The chosen kind is uniform-random among
  all four.
- Applying: Empowered and Gold Rush stay in `GameState.active_enchantments`
  and are read as multipliers (`_empowered_multiplier()` on every hit's
  damage, `_gold_rush_multiplier()` on a kill's reward) via the same
  sequential-multiplier pattern the prestige multiplier already used.
  Auto Boost is read the same way (`_auto_boost_multiplier()`) inside
  the new `GameState.effective_auto_chop_rate()`, which both `_process()`
  and the UI's CPS display now call, so the number on screen can never
  drift from what actually gets paid out. Elemental Surge does not sit
  in `active_enchantments` at all: granting it directly activates
  Element Power (`chopper.active_element`/`element_trees_remaining`),
  reusing the real Prompt 3.1/3.2 mechanism instead of building a
  parallel one for "free Element Power."
- Displaying: a new auto-dismissing `EnchantmentBanner` panel (fades in,
  holds ~2.5s, fades out) shows the granted enchantment's own
  `description` text on every grant. A new `EnchantmentIcons` row at the
  top-right of the play area shows one small colored tag per entry in
  `active_enchantments` (Elemental Surge never appears there, since it
  already shows through the existing Chopper element badge from Prompt 3.2).
- Expiring: `_tick_enchantments_by_tree()` (called on every kill) counts
  down `remaining_trees`; `_tick_enchantments_by_time()` (called every
  frame from `_process()`) counts down `remaining_seconds`. Both remove
  an entry once `EnchantmentData.is_expired()` is true, which already
  only cares about whichever one counter a given kind actually uses
  (the other stays permanently 0), so no per-kind branching was needed
  for expiry itself.
- Prestige Reset now also clears `active_enchantments` and the internal
  kill counter, alongside everything else it already reset.

**ChopperMobile Prompt 4.1: Animation and particles**

- Chopper's axe swing is now a three-stage tween (anticipation lean/wind-up
  -> sharp hit squash -> overshoot recovery), replacing Prompt 2.2's
  rotation-only placeholder. Still tween-only: there is no usable
  swing spritesheet on disk (`chopper-axe.png` is a full illustration).
  Rotation and scale only, because `chopper_sprite` is a container child
  and animating `.position` would fight layout.
- Tree shakes on a non-killing hit (`_shake_tree()`), distinct from the
  existing tree-fall tween (kill) and the whole-screen `_shake()`.
- Hit and kill each fire a matched pair of `CPUParticles2D`: brown
  wood chips plus green drifting leaves, instead of Prompt 2.2's single
  flat-color burst.
- Floating "+X Chops" text on a kill (already had damage numbers;
  Prompt 4.1's own reward text).
- Health bar tweens down on further damage to the same tree, and snaps
  to full when `current_tree` is a new Resource after a kill.

**ChopperMobile Prompt 4.2: Audio**

- New autoload `AudioManager` (`autoload/audio_manager.gd`), registered
  next to `GameState` in `project.godot`. Owns every sound: an 8-player
  SFX pool on an `SFX` bus (so rapid taps can overlap) and a dedicated
  looping music player on a `Music` bus.
- Removes Prompt 2.2's plain `HitSfx` `AudioStreamPlayer` from
  `scenes/main.tscn`. `scripts/main.gd` now calls `AudioManager.play_*()`
  instead of playing a node directly.
- Recorded clips: `axe-impact.mp3` (hit / pitched-down fall) and
  `axe-slash.mp3` (swing), both with random pitch variation. Everything
  else (tree crack, collect, upgrade, enchantment, UI click, and a soft
  looping pad used as BGM) is a short procedural `AudioStreamWAV`
  generated at startup, so every `play_*()` has something to play
  before dedicated files exist. Swap the stream assignments later;
  the method names stay put.
- Volumes and mute flags save to `user://audio.cfg` (ConfigFile) on
  every change, independent of Prompt 5.3's full run save. Mute APIs are
  live; there is still no mute button in the UI (Prompt 4.3's list did
  not include one).
- Wired call sites: swing+hit on every chop, tree-fall+collect on kill,
  enchantment reveal when granted, upgrade chime on a successful
  `buy_*()` / prestige, UI click on the five element buttons. Auto
  Chopper's passive CPS does not play collect, on purpose.

**ChopperMobile Prompt 4.3: UI polish**

- Pressed and disabled StyleBoxes for `UpgradeButton` and `PrestigeButton`
  in `assets/themes/chopper_theme.tres` (pressed is a darker inset;
  disabled is a desaturated grey-brown / grey-purple). Prestige no
  longer reuses one style for hover/normal/pressed. Element buttons
  keep their existing per-element pressed styles and now also have a
  shared disabled StyleBox.
- Cost labels go red when the player cannot afford the upgrade, stay
  cream when they can, grey out for "Pick an element" / locked Prestige
  hint, and turn gold for "Active: N left" and "Ready!" prestige text.
- Prestige button pulses (scale 1.0 <-> 1.07 plus a slight modulate
  breathe) only while `GameState.can_prestige()` is true. The tween is
  not restarted on every stats refresh, and it uses scale (not
  position) because the button is a GridContainer child.
- Upcoming preview cards idle-animate their tree icon (slow sway +
  breathe), staggered by sibling index so the three cards are out of
  phase. `set_preview()` does not restart the loop, which would hitch
  on every chop.
- Safe-area insets: `DisplayServer.window_get_safe_area()` is mapped
  into viewport pixels and added on top of the designed 24/24/24/18
  margins on `%Margin`, and onto `%WoodFrameInner`'s 14px offsets.
  Sky/ground/outer wood frame stay full-bleed. Desktop (safe area ==
  window) adds zero extra pad. Reapplied on viewport resize and app
  resume.

**ChopperMobile Prompt 5.1: Prestige UX**

- Done at the user's explicit request to skip the "Not done" playtest
  gate this file previously carried (see below) rather than pause for it.
  The underlying prestige mechanics (`GameState.can_prestige()` /
  `prestige_reset()`) already existed from Prompt 3.1; 5.1 is the UX
  layer on top.
- **Clear currency display + multiplier preview**: `main.gd`'s
  `PrestigeBadge` (top-left of the play area) now reads "Prestige N -
  x1.2" instead of just the level. The bottom-panel `PrestigeHint` label
  now always shows a "current -> next" multiplier preview
  ("x1.0 -> x1.1 at 1000"), even long before the player can afford it,
  instead of only showing a number once already at the threshold
  (`_refresh_upgrade_buttons()` in `scripts/main.gd`).
- **Confirmation before resetting**: the Prestige button no longer fires
  the reset on press. It opens a new `PrestigeConfirmDialog`
  (`ConfirmationDialog`, a top-level child of the `Main` scene root,
  themed with `chopper_theme.tres`) whose text spells out exactly what
  resets (Chops, Better Axe, Auto Chopper, Element Power, current tree,
  active enchantments) and the permanent multiplier the player is about
  to lock in. Only the dialog's `confirmed` signal calls
  `GameState.prestige_reset()`; canceling changes nothing.
- **Post-prestige feedback**: `GameState` gained a new
  `prestiged(new_level, new_multiplier, previous_multiplier)` signal,
  emitted at the end of `prestige_reset()` (after the reset has already
  applied, so the UI reads the *new* state plus the multiplier it just
  came from). `main.gd`'s `_on_prestiged()` uses it to show a new
  centered `PrestigeBanner` — gold-bordered (`prestige_banner` StyleBox
  + `PrestigeBanner` theme type variation, both new in
  `assets/themes/chopper_theme.tres`), distinct from the small corner
  `EnchantmentBanner` reused for enchantment grants — that fades in,
  holds ~3s, and fades out, stating the level reached and the multiplier
  change plainly.
- Out of scope on purpose: persisting prestige level/multiplier to disk
  across app restarts is Prompt 5.3 (Save/Load), not started here. It
  already survives within a running session since `GameState` is an
  autoload singleton.

**ChopperMobile Prompt 5.2: Balance and progression curve**

- Done at the user's explicit request to continue immediately from 5.1,
  again skipping the "playtest before continuing" gate this file has
  carried since Phase 4 (see "Not done" below, still outstanding).
- **The core problem found:** `TreeData.make()` set `max_health = 80 +
  (level * 20) * difficulty` and `chop_reward = 5 * level * difficulty`
  (no base). At level 1, that is 100-140 health for only 5-15 Chops —
  with starting `axe_damage = 1`, the very first tree took 50-70 taps
  (tapping continuously) just to earn enough for the 10-Chop Better Axe.
  That directly contradicts the design doc's "early game feels fast and
  rewarding." A python simulation (greedy-upgrade-buying, ~2.2 taps/sec)
  confirmed this and was used to find replacement constants: see below.
- **New tree scaling** (`scripts/upgrade_config.gd`): `TREE_HEALTH_BASE
  = 6`, `TREE_HEALTH_PER_LEVEL = 5`, `TREE_REWARD_BASE = 2`,
  `TREE_REWARD_PER_LEVEL = 2.5`, read by new `UpgradeConfig.tree_max_health()`
  / `tree_chop_reward()`. `TreeData.make()` (`scripts/tree_data.gd`) now
  calls those instead of doing its own arithmetic. Effect: the first
  tree now dies in roughly 5-10 taps for 5-10 Chops (was 50-70 taps for
  5-15 Chops), so Better Axe's first level or two is reachable within
  the first ~20 seconds of play.
- **Prestige now scales per cycle, not just per level**
  (`autoload/game_state.gd`'s `can_prestige()` / `prestige_reset()`,
  `scripts/main.gd`'s prestige hint text): the prestige multiplier
  applies to *both* chop damage and Chop rewards, so a flat 1000-Chop
  threshold forever (Prompt 3.1/5.1's version) meant each successive
  prestige cycle would get roughly quadratically faster and collapse
  toward "prestige every few seconds," which contradicts "not mandatory
  every five minutes." New `UpgradeConfig.prestige_threshold_for_level()`
  grows the threshold itself (`PRESTIGE_BASE_THRESHOLD = 1000`,
  `PRESTIGE_THRESHOLD_GROWTH = 1.3` per level) to counteract that, and
  `PRESTIGE_MULTIPLIER_PER_LEVEL` moved from `0.1` to `0.18` (still
  linear: `1.0 + level * 0.18`). Simulated across 8 prestige cycles with
  greedy upgrade-buying: cycle times landed in a stable ~385-535 second
  band (~6.5-9 minutes), inside the doc's 5-15 minute target, instead of
  drifting anywhere near instant.
- **Every remaining hardcoded balance number centralized into
  `UpgradeConfig`**, per the design doc's own Prompt 5.2 line ("Expose
  all key constants — damage scaling, cost scaling, enchantment chances,
  elemental multipliers — in one place"), which `UpgradeConfig` had only
  partly done since Prompt 3.1:
  - `TreeData.elemental_multiplier()` (`scripts/tree_data.gd`) now reads
    `UpgradeConfig.ELEMENT_MATCH_MULTIPLIER` (1.5) / `ELEMENT_RESIST_MULTIPLIER`
    (0.65) instead of inline `1.5`/`0.65` literals. Values unchanged,
    only centralized.
  - `EnchantmentData`'s four static constructors (`scripts/enchantment_data.gd`)
    now read `UpgradeConfig.EMPOWERED_TREES`/`EMPOWERED_MULTIPLIER`,
    `GOLD_RUSH_TREES`/`GOLD_RUSH_MULTIPLIER`, `AUTO_BOOST_SECONDS`/
    `AUTO_BOOST_MULTIPLIER` instead of inline literals (values unchanged:
    5 trees at +40%, next tree at 3x, 20s at +50%). Their description
    text is now generated from those same constants instead of a
    separately hand-written number, so the two can never drift apart.
  - `EnchantmentData.GRANT_CHANCE` / `MILESTONE_INTERVAL` moved to
    `UpgradeConfig.ENCHANTMENT_GRANT_CHANCE` / `ENCHANTMENT_MILESTONE_INTERVAL`
    (values unchanged: 18% flat, guaranteed every 10th kill).
    `GameState._maybe_grant_enchantment()` updated to match.
  - Left deliberately unchanged (already reasonable, no evidence they
    were the problem): `BETTER_AXE_*`, `AUTO_CHOPPER_*`,
    `ELEMENT_POWER_COST`/`ELEMENT_POWER_TREES`.
- Out of scope on purpose: this was tuning only, no new upgrade types,
  enchantment kinds, or UI. `scripts/main.gd` needed one small change
  (the not-ready `PrestigeHint` text now calls
  `UpgradeConfig.prestige_threshold_for_level(GameState.prestige_level)`
  instead of a flat constant, so it still shows the right number now
  that the threshold scales).

**ChopperMobile Prompt 5.3: Save/Load**

- Done at the user's explicit request to continue immediately from 5.2,
  again without the standing playtest gate (see "Not done" below).
- New persistent save in `autoload/game_state.gd`: `_save_game()` /
  `_load_game()`, writing plain JSON (`JSON.stringify()` /
  `JSON.parse_string()`) to `user://save.json` via `FileAccess`. Chosen
  over `ConfigFile` because the queue and enchantment list are arrays of
  structured records (each tree/enchantment is several fields), which
  JSON represents directly as nested arrays of dictionaries; ConfigFile
  is a better fit for flat key/value settings, which is exactly what
  `AudioManager` already uses it for.
- **What's persisted**: total Chops, all three upgrade levels (Better
  Axe/Auto Chopper/Element Power), prestige level, the full `ChopperData`
  (axe damage, auto-chop rate, active/selected element, prestige
  multiplier, Element Power trees remaining), the current tree and the
  entire upcoming queue (every field on each `TreeData`), every active
  `EnchantmentData` (kind, remaining trees/seconds, description,
  magnitude), plus two internal-only counters (`_trees_chopped_total`,
  the fractional Auto Chopper accumulator) so the enchantment milestone
  countdown and passive-Chop fractions survive a restart exactly, not
  just approximately. A `version` field (currently `1`) is written and
  checked on load so a future format change can detect and discard an
  incompatible old save instead of misreading it.
- **What's NOT in this file, on purpose**: audio settings. `AudioManager`
  has saved/loaded volumes and mute flags to its own `user://audio.cfg`
  independently since Prompt 4.2, and still does — the design doc's
  Prompt 5.3 checklist item "Audio settings" was already satisfied
  before this prompt started, so nothing needed to change there.
- **When it saves**: after every tree kill (inside
  `GameState.chop_current_tree()`, only when `fell` is true — not on
  every non-killing hit) and after every successful `buy_better_axe()` /
  `buy_auto_chopper()` / `buy_element_power()` / `prestige_reset()` call
  (never on a failed/unaffordable attempt, since those already return
  early without changing state). This matches the design doc's "auto-save
  after every tree kill and after every upgrade purchase" instruction;
  prestige was folded into "upgrade purchase" here since it is the same
  kind of state-changing action and skipping it would risk losing a
  fresh prestige on an app close.
- **When it loads**: `GameState._ready()` now tries `_load_game()`
  first, and only falls back to the original hardcoded starting queue
  (three fresh trees) if there is no valid save — missing file,
  unreadable file, wrong `version`, or a JSON payload that isn't even a
  Dictionary all count as "no valid save" and fall back safely rather
  than crashing or leaving partially-applied state. `main.gd` needed no
  changes: it already reads everything through `GameState`'s public vars
  and connects to `stats_changed` in its own `_ready()`, which runs after
  the `GameState` autoload's `_ready()` per normal Godot autoload
  ordering, so the loaded state is already in place before the UI's
  first `_refresh_ui()` call.
- Out of scope on purpose: no in-game "New Game" / delete-save control,
  no cloud save, no save slots. The design doc's Prompt 5.3 asked only
  for "robust local saving" of a single ongoing run.

### Not done

- **Playtest pass** (NEXT, still outstanding): none of Prompts 2.2
  through 5.1 has a confirmed playtest recorded here (see the
  untracked-editor-files note near the top of this file). This file
  previously said not to start Prompt 5.1 before this playtest; the user
  explicitly chose to skip that gate for this session, so 5.1 shipped
  without it. For 4.3: confirm unaffordable upgrade costs turn red and
  the button uses the grey disabled style; buy until Prestige unlocks
  and watch it pulse; check the three upcoming cards swaying out of
  phase; on a notched-phone emulator (or after shrinking the desktop
  window, which will not itself simulate a notch) confirm the header
  and bottom buttons still sit inside the safe rectangle. For 5.1
  specifically: confirm the `PrestigeConfirmDialog` text is accurate and
  legible against the theme, canceling truly changes nothing, confirming
  resets the run and shows the centered `PrestigeBanner`, and the
  not-ready `PrestigeHint` text ("x1.0 -> x1.1 at 1000") does not clip
  at its 12px font size inside the button's width.
- Phase 6+: mobile export and everything under it. A mute control that
  calls AudioManager.set_music_muted still has no UI home; it can land
  with 6.1 mobile polish without changing 4.2.
- Prompt 5.2's new constants (tree scaling, prestige threshold growth)
  are simulation-validated (python, greedy-upgrade-buying model), not
  confirmed by an actual playtest in Godot. The simulation cannot see
  "does this feel good," only the numeric pacing — the playtest pass
  below should specifically sanity-check that the new fast opening and
  the prestige cadence feel right, not just that they hit the target
  seconds.
- Prompt 5.3's save/load has not been exercised in a real Godot process
  either: nothing in this repo confirms `user://save.json` has actually
  been written and re-read across a real app restart, only that the
  serialize/deserialize code reads back its own field names correctly
  by inspection. The playtest pass below should specifically: play a
  bit, quit the app (not just close the window if that does not trigger
  the same shutdown path), relaunch, and confirm Chops/upgrades/prestige/
  current tree/queue/enchantments all match where the session left off;
  also confirm a first-ever launch (no save file yet) still starts a
  fresh run instead of erroring.

---

## What is next

Phase 4 (juice, audio, UI polish) and all of Phase 5 (Prompt 5.1 prestige
UX, Prompt 5.2 balance/progression, Prompt 5.3 save/load) are now
implemented per `mobile/readme.md`, but **none of Prompts 4.1 through 5.3
has been playtested in a real Godot editor yet** (see "Not done" above)
— that gate was explicitly skipped for 5.1, 5.2, and 5.3 in a row, not
satisfied. Open the project in a real Godot editor and playtest all of
it together before starting Phase 6 (mobile polish/release) — especially
the new tree/prestige pacing from 5.2, and 5.3's save/load across an
actual app restart, since neither has run in a real Godot process yet.

---

## Resume prompt (paste into Claude Code / Cursor)

```
Continue ChopperMobile, a Godot 4.3+ GDScript mobile clicker.

Repo: https://github.com/thurtea/chopper
Project: mobile/ChopperMobile (open in local Godot; not runnable in this environment).
Full design + prompt sequence: mobile/readme.md
Session history: tomorrow.md (this file) and mobile/tomorrow.md.

Done: project scaffold, wooden-themed main UI, data models, GameState autoload,
Prompt 2.2 (manual chopping), Prompt 2.3 (weighted tree generation), Prompt 3.1
(the four core upgrades), Prompt 3.2 (elemental selector buttons + visual
indicators), Prompt 3.3 (the enchantment system), Prompt 4.1 (multi-stage
axe-swing tween, tree shake, paired leaf/chip particles, smooth health bar,
floating "+X Chops"), Prompt 4.2 (AudioManager autoload), Prompt 4.3
(pressed/disabled button styles, unaffordable cost text, pulsing Prestige
button, idle preview cards, safe-area insets), Prompt 5.1 (prestige
UX: currency/multiplier display, always-on multiplier preview, a
confirmation dialog before resetting, and a post-prestige summary
banner), Prompt 5.2 (balance and progression curve: faster/cheaper
early trees, a per-cycle-growing prestige threshold so cycles don't
collapse toward instant, and every remaining balance constant —
elemental multipliers, enchantment chances/magnitudes — centralized
into UpgradeConfig), and Prompt 5.3 (save/load: total Chops, all
upgrade levels, prestige level/multiplier, current tree, upcoming
queue, and active enchantments all persist to user://save.json as JSON,
auto-saved after every tree kill and every successful upgrade/prestige
purchase; audio settings already persisted separately via AudioManager
since Prompt 4.2). None of Prompts 2.2 through 5.3 has been confirmed
playtested in a real Godot editor session. Prompts 5.1, 5.2, and 5.3
were all done at the user's explicit request to skip that playtest gate
rather than wait for it. Playtest 4.1–5.3 together (disabled upgrade
look + red costs, Prestige pulse on unlock, staggered preview idle,
notches not covering UI, the PrestigeConfirmDialog + PrestigeBanner
flow, whether the new faster tree pacing and prestige cadence from 5.2
actually feel good, and specifically for 5.3: play, fully quit the app,
relaunch, and confirm the run picks up exactly where it left off, plus
that a first-ever launch with no save file still starts clean) and fix
anything that feels off before moving on.

Do not start Phase 6 (mobile polish/release) until that playtest pass is
done. Keep any changes inside ChopperMobile.
```
