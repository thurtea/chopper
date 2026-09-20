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
- Queue replenishment (`GameState._generate_tree()`) is a flat random
  element/difficulty pick, just enough to keep the preview queue at 3 trees.
  This is intentionally not the weighted generation Prompt 2.3 asks for.

### Not done

- **Playtest pass** (NEXT): none of the above has been opened in a real
  Godot editor yet (Godot is not installed in this sandbox). Open
  `mobile/ChopperMobile/project.godot` in Godot 4.3+, tap the tree, and
  check the swing/fall/shake/particle timing and the floating-number
  position feel right. `TreeSprite`/`ChopperSprite` `pivot_offset` values
  in `scenes/main.tscn` are my best guess at their rendered size and may
  need nudging once you can see them.
- Prompt 2.3: weighted queue generation
- Phase 3+: upgrades, elements, enchantments, juice, prestige, save/load, mobile export

---

## What is next

Open the project in a real Godot 4.3+ editor and playtest Prompt 2.2 (see
"Not done" above). Once the chop loop feels good, move to **Prompt 2.3**
from `mobile/readme.md`: replace `GameState._generate_tree()`'s flat random
pick with weighted generation so the player regularly sees both matching
and mismatched elements.

---

## Resume prompt (paste into Claude Code / Cursor)

```
Continue ChopperMobile, a Godot 4.3+ GDScript mobile clicker.

Repo: https://github.com/thurtea/chopper
Project: mobile/ChopperMobile (open in local Godot; not runnable in this environment).
Full design + prompt sequence: mobile/readme.md
Session history: tomorrow.md (this file) and mobile/tomorrow.md.

Done: project scaffold, wooden-themed main UI, data models, GameState autoload,
and Prompt 2.2 (manual chopping: tap the tree to deal damage, floating numbers,
axe-swing and tree-fall tweens, screen shake, particle burst, hit sound, queue
advance on kill). None of Prompt 2.2 has been playtested in a real Godot editor
yet (not installed in this sandbox). Do that first and fix anything that
feels off before moving on.

Do Prompt 2.3 from mobile/readme.md (Phase 2): replace
GameState._generate_tree()'s current flat random element/difficulty pick with
real weighted generation, so the player regularly sees both matching and
mismatched elements relative to whatever Element Power they might buy.
Meaningful decisions is the explicit goal. Keep changes inside ChopperMobile.
```
