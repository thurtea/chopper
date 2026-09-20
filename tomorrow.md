# Chopper Clicker: Session Handoff (2026-09-20)

Repo: https://github.com/thurtea/chopper
Local: `/Users/thurtea/Work/chopper`
Godot project: `mobile/ChopperMobile/`
Design + prompt sequence: `mobile/readme.md`

Godot is not installed in the Claude/Cursor sandbox. Edit files here, then open
`mobile/ChopperMobile/project.godot` in a local Godot 4.3+ editor to playtest.

---

## Progress

### Done

**Web toolkit** (`index.html`, `main.js`, `main.css`, staff tools) — separate from the mobile game.

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
  Hit sound (`assets/audio/axe-impact.mp3`) plays via a plain
  `AudioStreamPlayer` node. Prompt 4.2's dedicated AudioManager autoload can
  replace this call site later without touching the chop logic itself.

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
- **Placeholder, flagged for Prompt 3.2:** which element Element Power
  activates is a random pick (`buy_element_power()`). The five
  Fire/Ice/Bolt/Earth/Wind buttons in the bottom panel still do nothing;
  wiring them up as the real selector is explicitly Prompt 3.2's own task
  ("The five elemental buttons ... select which element will be used when
  the player buys Element Power").

### Not done

- **Playtest pass** (NEXT): none of Prompts 2.2, 2.3, or 3.1 has been
  opened in a real Godot editor yet (Godot is not installed in this
  sandbox). Beyond the Phase 2 checks already noted, buy each of the four
  upgrades a few times and confirm: costs rise as expected, buttons grey
  out at zero Chops, Auto Chopper actually ticks Chops up over time,
  Element Power visibly changes damage against a matching/opposing tree,
  and Prestige Reset (grind to 1000 Chops, or edit `chops` in the debugger
  to test faster) resets the run and raises the multiplier shown in
  `PrestigeHint`.
- Prompt 3.2: elemental system (the five element buttons actually select
  Element Power's element; visual indicators on Chopper/tree)
- Prompt 3.3: enchantment system
- Phase 4+: juice/audio polish, prestige UX, save/load, mobile export

---

## What is next

Open the project in a real Godot 4.3+ editor and playtest Prompts 2.2, 2.3,
and 3.1 together (see "Not done" above). Once that feels right, move to
**Prompt 3.2** from `mobile/readme.md`: wire the five Fire/Ice/Bolt/Earth/
Wind buttons as the real Element Power selector (replacing
`buy_element_power()`'s current random pick), and add the visual indicators
on Chopper and the current tree the design doc asks for.

---

## Resume prompt (paste into Claude Code / Cursor)

```
Continue ChopperMobile, a Godot 4.3+ GDScript mobile clicker.

Repo: https://github.com/thurtea/chopper
Project: mobile/ChopperMobile (open in local Godot; not runnable in this environment).
Full design + prompt sequence: mobile/readme.md
Session history: tomorrow.md (this file) and mobile/tomorrow.md.

Done: project scaffold, wooden-themed main UI, data models, GameState autoload,
Prompt 2.2 (manual chopping), Prompt 2.3 (weighted tree generation), and
Prompt 3.1 (the four core upgrades: Better Axe, Auto Chopper, Element Power,
Prestige Reset, all costs/values in scripts/upgrade_config.gd, buttons that
disable when unaffordable). None of this has been playtested in a real Godot
editor yet (not installed in this sandbox). Do that first and fix anything
that feels off before moving on.

One known placeholder from Prompt 3.1: buy_element_power() (autoload/
game_state.gd) picks a random element instead of reading player choice,
since the five Fire/Ice/Bolt/Earth/Wind buttons are not wired up yet.

Do Prompt 3.2 from mobile/readme.md (Phase 3): wire those five buttons as
the real Element Power selector, and add a clear visual indicator on Chopper
and on the current tree when an element is active. Keep changes inside
ChopperMobile.
```
