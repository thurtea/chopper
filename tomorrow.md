# Chopper Clicker: Session Handoff (2026-09-20)

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
  every change, independent of Prompt 5.3's full run save. There is no
  mute button in the UI yet (that is Prompt 4.3 / later); the mute
  APIs are live and persist across restarts.
- Wired call sites: swing+hit on every chop, tree-fall+collect on kill,
  enchantment reveal when granted, upgrade chime on a successful
  `buy_*()` / prestige, UI click on the five element buttons. Auto
  Chopper's passive CPS does not play collect, on purpose.

### Not done

- **Playtest pass** (NEXT): none of Prompts 2.2 through 4.2 has a
  confirmed playtest recorded here (see the untracked-editor-files note
  near the top of this file). For 4.2 specifically: tap the tree and
  confirm swing+hit overlap without cutting off, fell a tree and hear
  the heavier fall plus collect chime, buy an upgrade, tap an element
  button, and grant an enchantment (or lower
  `EnchantmentData.MILESTONE_INTERVAL` temporarily) to hear the reveal.
  Confirm the quiet looping pad starts with the game and does not drown
  the axe. If the procedural UI/collect/BGM tones feel cheap, that is
  expected: they are stand-ins for recorded clips.
- Prompt 4.3 (UI polish): pressed/disabled button states, unaffordable
  cost text, pulsing Prestige button, idle preview-card animation,
  safe-area handling. A mute control would naturally land here too,
  calling the AudioManager mute APIs Prompt 4.2 already exposes.
- Phase 5+: prestige UX, balance, save/load, mobile export

---

## What is next

Prompts 4.1 (animation/particles) and 4.2 (AudioManager) are in. Open
the project in a real Godot editor and playtest the juice plus the new
audio (see "Not done" above) before starting anything else. Once that
feels right, **Prompt 4.3** is the rest of Phase 4: UI polish
(pressed/disabled states, unaffordable cost text, pulsing Prestige
button, idle preview-card animation, safe-area handling). Do not start
Phase 5 until 4.3 is done.

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
floating "+X Chops"), and Prompt 4.2 (AudioManager autoload: play_swing /
play_hit / play_tree_crack / play_tree_fall / play_collect / play_upgrade /
play_enchantment / play_ui_click, looping mute-able BGM, volumes and mute
saved to user://audio.cfg; HitSfx node from Prompt 2.2 is gone). This has
not been confirmed playtested in a real Godot editor session. Playtest the
4.1 juice and 4.2 audio (overlapping hits, tree-fall+collect, upgrade chime,
element click, enchantment reveal, quiet looping pad) and fix anything that
feels off before moving on.

Do Prompt 4.3 from mobile/readme.md (Phase 4): polish pass on UI. Buttons
have pressed and disabled states; cost text turns red or greys out when
unaffordable; Prestige button pulses when it becomes available; upcoming
tree previews have a subtle idle animation; safe area handling for notched
phones. A mute control that calls AudioManager.set_music_muted /
toggle_music_mute would fit here if you add one. Keep changes inside
ChopperMobile. Do not start Phase 5.
```
