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

### Not done

- **Playtest pass** (NEXT): none of Prompt 2.2 or 2.3 has been opened in a
  real Godot editor yet (Godot is not installed in this sandbox). Open
  `mobile/ChopperMobile/project.godot` in Godot 4.3+, tap the tree, and
  check the swing/fall/shake/particle timing, the floating-number position,
  and that the upcoming-tree preview strip actually reads as a varied mix
  of elements rather than repeats. `TreeSprite`/`ChopperSprite`
  `pivot_offset` values in `scenes/main.tscn` are my best guess at their
  rendered size and may need nudging once you can see them.
- Phase 3+: upgrades, elements, enchantments, juice, prestige, save/load, mobile export

---

## What is next

Open the project in a real Godot 4.3+ editor and playtest Prompts 2.2 and
2.3 together (see "Not done" above): confirm the chop loop feels good and
that the preview strip shows a genuine mix of elements over a few kills,
not long same-element runs. By the design doc's own account, Phase 3 is
where the real upgrade/element/enchantment systems begin
(`mobile/readme.md`), but that is explicitly not started yet.

---

## Resume prompt (paste into Claude Code / Cursor)

```
Continue ChopperMobile, a Godot 4.3+ GDScript mobile clicker.

Repo: https://github.com/thurtea/chopper
Project: mobile/ChopperMobile (open in local Godot; not runnable in this environment).
Full design + prompt sequence: mobile/readme.md
Session history: tomorrow.md (this file) and mobile/tomorrow.md.

Done: project scaffold, wooden-themed main UI, data models, GameState autoload,
Prompt 2.2 (manual chopping: tap the tree to deal damage, floating numbers,
axe-swing and tree-fall tweens, screen shake, particle burst, hit sound, queue
advance on kill), and Prompt 2.3 (GameState._pick_weighted_element() weights
tree generation against the currently visible current_tree + upcoming_trees
window, so the same element cannot easily dominate and NONE trees are a
deliberate minority). None of this has been playtested in a real Godot editor
yet (not installed in this sandbox). Do that first and fix anything that
feels off before moving on, especially whether the preview strip's element
mix actually feels varied and decision-worthy in practice.

Phase 2 (the core loop) is now feature-complete per mobile/readme.md. Do not
start Phase 3 (upgrades, elemental system, enchantments) until the Phase 2
playtest pass above is done and anything that feels off is fixed. When ready,
Phase 3 starts with Prompt 3.1: the four core upgrades (Better Axe, Auto
Chopper, Element Power, Prestige Reset), costs/values in one tunable place,
buttons that disable when unaffordable. Keep changes inside ChopperMobile.
```
