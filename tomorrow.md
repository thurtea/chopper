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

### Not done

- **Playtest pass** (NEXT): none of Prompts 2.2 through 3.2 has been
  opened in a real Godot editor yet (Godot is not installed in this
  sandbox). Beyond the earlier checks, tap a Fire/Ice/Bolt/Earth/Wind
  button and confirm it visibly stays pressed and the others release,
  buy Element Power and confirm both new badges appear and read
  correctly, and check damage against a matching vs. an opposing tree
  element to confirm the "(Weak!)"/"(Resist)" tags line up with the
  actual damage dealt.
- Prompt 3.3: enchantment system
- Phase 4+: juice/audio polish, prestige UX, save/load, mobile export

---

## What is next

Open the project in a real Godot 4.3+ editor and playtest Prompts 2.2
through 3.2 together (see "Not done" above). Once that feels right, move
to **Prompt 3.3** from `mobile/readme.md`: the enchantment system
(Empowered, Elemental Surge, Gold Rush, Auto Boost), each with a chance
or milestone trigger after a tree falls, a popup/banner, and small active
icons.

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
(the four core upgrades, costs/values in scripts/upgrade_config.gd), and
Prompt 3.2 (the five element buttons are real single-select toggles wired to
GameState.select_element()/buy_element_power(), plus visual indicators: a new
ChopperElementBadge label and an enriched TreeElementBadge showing Weak!/Resist).
Also fixed a Prompt 2.2 bug along the way: TreeData.elemental_multiplier()
now treats a matching element as a bonus, not neutral, per the design doc's
own Prompt 3.2 wording. None of this has been playtested in a real Godot
editor yet (not installed in this sandbox). Do that first and fix anything
that feels off before moving on.

Do Prompt 3.3 from mobile/readme.md (Phase 3): the enchantment system.
EnchantmentData already exists (scripts/enchantment_data.gd) with its four
kinds (Empowered, Elemental Surge, Gold Rush, Auto Boost) and static
constructors, but nothing grants, applies, displays, or expires them yet.
Wire a chance/milestone trigger after a tree falls, apply each kind's real
effect, show a popup or banner plus small active-icons, and expire them
correctly (remaining_trees vs. remaining_seconds). Keep changes inside
ChopperMobile.
```
