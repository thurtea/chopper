# Chopper Mobile — pickup notes

Godot 4.3+ project (mobile renderer). Open this file locally:

`domains/thurtea.com/public_html/chopper/mobile/ChopperMobile/project.godot`

Source of truth for the full prompt sequence: `readme.md` in this same `mobile/` folder.

Godot is **not** installed on the server. Edit files here, then open the project in local Godot to play/test.

---

## Done

### Prompt 1.1 — Project setup
- New project `ChopperMobile`, mobile renderer, portrait `720×1280`
- Folders: `scenes/`, `scripts/`, `assets/sprites|audio|fonts/`, `autoload/`
- Autoload `GameState`
- `scenes/main.tscn` with top stats, play area, bottom upgrades
- Chopper sprite is `assets/sprites/chopper.png` (front-facing concept art)
- Placeholder tree at `assets/sprites/tree.png`
- Audio copied: `axe-impact.mp3`, `axe-slash.mp3`

### Prompt 1.2 — UI skeleton and theme
- `assets/themes/chopper_theme.tres` — dark-brown wooden frames, cream panels, gold headers
- Outer wood bezel around the screen
- Chopper stands beside the current tree
- **Next Trees** strip: 3 preview cards (icon + element name/color + star difficulty)
- Thumb-sized buttons (72px elements, 80px upgrades)

### Prompt 2.1 — Data models (just finished)
Scripts with `class_name`:

| Script | Holds |
|---|---|
| `scripts/tree_data.gd` | health, max health, `Element` enum, chop reward, level, difficulty, boss/enchanted flags |
| `scripts/chopper_data.gd` | axe damage, auto-chop rate, active/selected element, prestige multiplier |
| `scripts/enchantment_data.gd` | kind, remaining trees/seconds, description; factories for Empowered / Surge / Gold Rush / Auto Boost |

`GameState` now stores:

- `chops`, upgrade levels, `prestige_level`
- `chopper: ChopperData`
- `current_tree: TreeData`
- `upcoming_trees: Array[TreeData]` (placeholder Fire / Ice / Earth)
- `active_enchantments: Array[EnchantmentData]`

Main UI and preview cards read from those models. **Tapping does not chop yet.**

---

## Not done yet

Next prompt in `readme.md` is **2.2 Basic chopping**, then **2.3 queue generation**. After that: upgrades, elements, enchantments, juice, prestige, save/load, mobile polish.

---

## Useful paths

```
chopper/mobile/ChopperMobile/
  project.godot
  autoload/game_state.gd
  scripts/main.gd
  scripts/tree_data.gd
  scripts/chopper_data.gd
  scripts/enchantment_data.gd
  scripts/tree_preview_card.gd
  scenes/main.tscn
  scenes/tree_preview_card.tscn
  assets/themes/chopper_theme.tres
  assets/sprites/chopper.png
  assets/sprites/tree.png
  assets/audio/axe-impact.mp3
  assets/audio/axe-slash.mp3
```

Concept art / extra assets still live in `chopper/mobile/` (logo, side-axe Chopper, original HTML prototype `mobile.html`).

---

## Resume prompt (paste into a new chat)

```
Continue ChopperMobile, a Godot 4.3+ GDScript mobile clicker.

Project (Godot is local, not on this server):
/home/thurtea/domains/thurtea.com/public_html/chopper/mobile/ChopperMobile

Full prompt list:
/home/thurtea/domains/thurtea.com/public_html/chopper/mobile/readme.md

Yesterday we finished Prompts 1.1, 1.2, and 2.1.
- Project + Main.tscn UI + wooden theme + upcoming-tree preview strip exist.
- Data models exist: TreeData, ChopperData, EnchantmentData.
- GameState autoload holds chops, upgrade levels, prestige_level, chopper, current_tree, upcoming_trees, active_enchantments.
- Preview strip shows 3 placeholder trees. UI is display-only. No chopping yet.

Do Prompt 2.2 from readme.md lines 107–114:

Implement manual chopping:
- On tap/click anywhere on the tree or a dedicated chop button, play Chopper’s axe-swing animation.
- Subtract axe damage from the current tree’s health (apply elemental bonus/penalty if an element is active).
- Show floating damage numbers.
- When health reaches zero: play a tree-fall animation, award Chops, generate the next tree from the upcoming queue, and shift the preview forward.
- Add a short screen shake and particle burst (leaves + wood chips) on every hit and a bigger effect on tree kill.

Use the existing TreeData.take_damage / is_fallen helpers and GameState models. There is no swing animation sheet yet — use the front-facing chopper sprite (assets/sprites/chopper.png) with a simple tween (anticipate → hit → recover) until we have frames. Hit sounds are already in assets/audio/. Keep changes inside the ChopperMobile Godot project. Do not start Prompt 2.3 until 2.2 is playable.
```
