# Chopper: Status (2026-09-22, updated)

**Update, same day:** Godot 4.7.2 (headless CLI build) is now installed
on this machine (`~/development/godot`), where no Godot binary of any
kind existed before. `godot --headless --path mobile/ChopperMobile
--quit-after 5` boots the real project cleanly (zero script/parse
errors, only a benign "2 ObjectDB instances leaked at exit" headless-
teardown warning), independently reconfirming with a fresh install that
the two load-blocking bugs below are genuinely fixed and nothing has
regressed since. The pending `mobile.html` fix is now staged. A CLI
build has no display, so the actual visual/interactive playtest this
file has flagged for three sessions running is still not done — this
Godot install does not remove that requirement, it only re-confirms the
logic layer on top of what the previous session already established.

## Completion: ~70-75% toward a shippable MVP

**Code-complete through 5 of the design doc's 6 phases** (`mobile/readme.md`):
setup, core chop loop, upgrades/elements/enchantments, juice/audio/UI
polish, and prestige/balance/save-load. All implemented and, as of this
session, **actually verified to run** — not just written.

### What changed this session
Found and fixed two hard bugs that meant the Godot game did not load at
all until now:
- `main.gd` called `DisplayServer.window_get_safe_area()`, which never
  existed in any released Godot (real 4.7 name: `get_display_safe_area()`,
  and it needed a real coordinate-space fix, not just a rename).
- `enchantment_data.gd` used `%g`, not a valid GDScript format specifier.

With both fixed, a headless run through the real `GameState`/
`AudioManager` autoloads confirmed chopping, buying upgrades, and the
full save/reload round-trip all work correctly (committed: `9e12b20`).

Also found and fixed a real cross-browser bug in the separate standalone
`mobile/mobile.html` demo page: `selectElement()` relied on the implicit
global `event` object, which Firefox has never supported (Chrome/Safari
only) — element selection would silently break there. Fixed to find the
clicked button by its own CSS class instead. **This fix is still
uncommitted** (`git diff mobile/mobile.html`).

### What's NOT verified
The entire visual/interactive layer — every animation, particle effect,
button state, the prestige confirm dialog, audio pacing, notch handling
from Prompts 4.1-5.3 — has never been seen by a human or a real display.
Headless verification proves the logic is correct; it says nothing about
whether it *feels* right, which is most of what a clicker game actually
is. This is the real gap between "code complete" and "MVP."

### Not started
Phase 6 (mobile export, store builds, release prep) — nothing here yet.

## Next logical step

1. Commit the pending `mobile.html` fix (staged this session).
2. **The actual visual playtest** — open `mobile/ChopperMobile/project.godot`
   in a real Godot 4.7 editor (or on a device) and play it: confirm the
   disabled/red-cost button styling, the Prestige pulse + confirm dialog
   + banner flow, the three preview cards' staggered idle sway, notch
   padding, and whether the 5.2 balance numbers actually feel right by
   ear/eye. This has been the standing blocker for three sessions running
   and is the single highest-value next action — everything else is
   downstream of it.
3. Only after that: Phase 6 (mobile export/release prep).
