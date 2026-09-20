# Chopper Mobile: pickup notes

Canonical handoff for the whole Chopper repo (web + mobile) lives one level up:

`../tomorrow.md`  (also at repo root: `chopper/tomorrow.md`)

Godot project to open locally:

`ChopperMobile/project.godot`

Source of truth for the full prompt sequence: `readme.md` in this same `mobile/` folder.

---

## Snapshot (2026-09-20)

**Done:** Prompts 1.1 through 4.2. Phase 3 (core systems) is feature-complete.
Prompt 4.1 replaced Prompt 2.2's rotation-only swing with a three-stage
anticipation/hit/recovery tween, added a per-hit tree shake, paired
leaf+chip particles, a smooth health bar, and floating "+X Chops". Prompt
4.2 added autoload `AudioManager` (`ChopperMobile/autoload/audio_manager.gd`):
every SFX goes through `play_*()` methods, Prompt 2.2's plain `HitSfx`
node is gone, a quiet looping pad starts with the game, and volumes/mute
save to `user://audio.cfg`. Tapping the tree plays swing+hit; a kill plays
tree-fall+collect; a granted enchantment plays a reveal; a successful
upgrade/prestige plays a purchase chime; element buttons play a UI click.

`project.godot` and a batch of `.import`/`.uid` files appeared untracked
since an earlier session, with the feature tag bumped to Godot 4.7, meaning
the project has been opened in a real local editor at some point, but
whether any of Prompts 2.2 through 4.2 were actually played is not
recorded. Confirm before assuming a real playtest pass already happened.

**Next:** playtest Prompt 4.1 juice and Prompt 4.2 audio in a real Godot
editor, then Prompt 4.3 (UI polish: pressed/disabled states, unaffordable
cost text, pulsing Prestige button, idle preview cards, safe-area
handling). Do not start Phase 5 yet.

Paste the resume prompt from `../tomorrow.md` into Claude Code / Cursor.
