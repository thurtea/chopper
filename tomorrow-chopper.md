# Chopper: Session Handoff (2026-09-22)

Repo: https://github.com/thurtea/chopper
Godot project: `mobile/ChopperMobile/`
Godot CLI (headless only, no display): `~/development/godot/Godot_v4.7.2-stable_linux.x86_64`
Full status: `status-today.md` and `tomorrow.md` (this session's entries are at the top of each).

## Resume prompt (paste into Claude Code)

```
Continue ChopperMobile, a Godot 4.3+ GDScript mobile clicker.

Read status-today.md and tomorrow.md first for full context. Summary:
code-complete through Phase 5 of mobile/readme.md's design doc. A
headless Godot CLI (~/development/godot, installed 2026-09-22, no
display) confirms the project boots with zero script/parse errors and,
from the prior session, that GameState/AudioManager's core logic
(chopping, buying upgrades, save/load round-trip) is correct. The
mobile.html standalone demo's Firefox event-object bug is fixed and
staged.

What headless verification cannot do, and what has been the standing
blocker for four sessions running: the actual visual/interactive
playtest. Open mobile/ChopperMobile/project.godot in a real Godot 4.7
editor (or on a device - this environment has no display, so this step
needs to happen somewhere that does) and play it. Specifically confirm:
disabled/red-cost upgrade button styling, the Prestige pulse + confirm
dialog + post-prestige banner flow, the three upcoming-tree preview
cards swaying out of phase, safe-area/notch padding on a notched-phone
emulator, and whether the 5.2 balance numbers (tree health/reward
scaling, prestige threshold growth) actually feel right by ear/eye, not
just by the numbers a headless run can check.

Do not start Phase 6 (mobile export/release prep) until that visual
playtest pass is done and anything it surfaces is fixed.
```
