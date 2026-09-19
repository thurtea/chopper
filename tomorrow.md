# Chopper Clicker — Session Handoff (2026-09-19)

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

### Not done

- **Prompt 2.2 — Basic chopping** (NEXT): tap does nothing yet
- Prompt 2.3 — queue generation
- Phase 3+: upgrades, elements, enchantments, juice, prestige, save/load, mobile export

---

## What is next

Implement **Prompt 2.2** from `mobile/readme.md` until tapping a tree is a satisfying, playable chop loop. Do not start 2.3 until 2.2 feels good in the Godot editor.

---

## Resume prompt (paste into Claude Code / Cursor)

```
Continue ChopperMobile, a Godot 4.3+ GDScript mobile clicker.

Repo: https://github.com/thurtea/chopper
Project: mobile/ChopperMobile (open in local Godot; not runnable in this environment).
Full design + prompt sequence: mobile/readme.md
Session history: tomorrow.md (this file) and mobile/tomorrow.md.

Done: project scaffold, wooden-themed main UI (top stats, tree area, upcoming-tree
preview strip), data models TreeData / ChopperData / EnchantmentData, GameState
autoload (chops, upgrades, prestige_level, chopper, current_tree, upcoming_trees,
active_enchantments). App icon is chopper-logo.jpg. UI is display-only — tapping
does not chop yet.

Do Prompt 2.2 from mobile/readme.md (Phase 2): implement manual chopping.
- Tap/click the tree or a dedicated button plays Chopper's axe-swing.
- Subtract axe damage from current tree health (apply elemental bonus/penalty
  if an element is active).
- Show floating damage numbers.
- On tree death: fall animation, award Chops, pull next tree from the upcoming
  queue, shift the preview forward.
- Screen shake + leaf/wood-chip particle burst on every hit; bigger burst on kill.

No swing spritesheet yet — use assets/sprites/chopper.png with a tween
(anticipate -> hit -> recover). Hit sounds are in assets/audio/. Keep changes
inside ChopperMobile. Do not start Prompt 2.3 until 2.2 is playable.
```
