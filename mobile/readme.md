prototype for public testing chopper clicker game

Part 1: Refined Concept

Core Fantasy
You are little Chopper. You swing your axe and chop down trees. Trees have health and elemental weaknesses. You can see the next few trees coming, so you must decide whether to spend resources on elemental power now or push forward and grab an enchantment that will make the upcoming trees much easier. The game rewards planning, satisfying feedback, and short “one more tree” sessions.

Main Loop

Current tree is on screen with a visible health bar and elemental affinity (or none).
Tap / hold to swing the axe (satisfying animation + particles + sound).
When the tree falls you gain currency (“Chops”) and sometimes an enchantment.
The next 2–3 trees are previewed at the side or bottom so you can plan.
Spend Chops on permanent upgrades or temporary elemental power.
Prestige at higher levels for permanent multipliers.
Key Systems

Axe & Chopping
Manual swings + optional Auto Chopper. Better Axe increases damage. Critical hits and perfect timing windows feel good.
Elemental Axes / Power
Fire, Ice, Bolt, Earth, Wind.
Each element does bonus damage to matching trees and reduced damage to opposing ones.
“Element Power” is a temporary buff you can buy or earn that applies the chosen element for a limited number of trees.
Upcoming Tree Preview
Always show the next 2–3 trees (icon + element + rough difficulty).
This is the strategic heart of the game: “Do I buy Fire Power now because the next three trees are Fire-weak, or do I keep chopping and hope for an enchantment?”
Enchantments
Random or milestone rewards that appear after a tree falls.
Examples: “Next 5 trees take +50% damage”, “All Fire trees explode for bonus Chops”, “Auto Chopper speed doubled for 30 seconds”, etc.
Enchantments are the main “should I push or prepare?” decision point.
Upgrades (visible in the bottom panel)
Better Axe (damage)
Auto Chopper (passive chops per second)
Element Power (buy a temporary elemental buff)
Prestige Reset (unlocks at a high Chop threshold, grants permanent multiplier)
Prestige
Classic idle/clicker prestige. Reset progress for a permanent “Prestige Level” multiplier. Keep it simple for 1.0.
Visual Style
Cute little Chopper character with a clear axe-swing animation.
Trees are distinct, readable silhouettes with elemental colour accents.
Heavy juice: screen shake, leaf particles, wood chips, satisfying “thud” and “crack” sounds, floating Chop numbers.
Monetization Options (choose one before release)

Paid $0.99 up front, no ads, no IAP.
or Free with a single optional “Remove Ads + Starter Pack” IAP.
No energy systems, no forced waiting, no dark patterns.
Platform & Engine
Godot 4 (GDScript).
Export to Android and iOS.
You already have Godot assets, so we will build around them.

Accessibility

Large, clear touch targets.
Colour is never the only indicator (element icons + text labels).
Support system font scaling where possible.
Simple colour-blind friendly palette.

Part 2: Complete Prompt Sequence

Copy everything below into a file named PROMPTS.md. Work through the prompts in order with your coding assistant. Test after each major prompt on both desktop and a mobile device/emulator.

Project Target
Godot 4 project (GDScript) for a polished 2D mobile clicker. Player controls little Chopper who swings an axe to chop down trees. The player can always see the next 2–3 trees, buy elemental power, receive enchantments, and prestige. Heavy emphasis on satisfying animations, clear strategic decisions, and juice. Target platforms: Android + iOS.


Phase 1: Project Setup & Core Scene

Prompt 1.1 – Create the Godot project
Create a new Godot 4 project called ChopperMobile.
Use the mobile renderer.
Set up a clean folder structure:

res://
  scenes/
  scripts/
  assets/
    sprites/
    audio/
    fonts/
  autoload/
Create an autoload singleton named GameState (or Global) that will hold currency, upgrades, prestige level, and current run data.
Create a main scene Main.tscn with a basic UI layout matching the spirit of the reference image: top stats bar, large central tree area, bottom upgrade panel.
Add a simple placeholder Chopper sprite and a placeholder tree sprite so something is visible immediately.

Prompt 1.2 – Basic scene structure and theme
Build the main UI skeleton:

Top bar: Total Chops, Chops Per Second, Tree Level (or current stage).
Central play area: current tree with health bar and level label, Chopper character below or beside it.
Side or bottom preview strip showing the next 2–3 upcoming trees (icon + element).
Bottom panel: Elemental Axe buttons (Fire, Ice, Bolt, Earth, Wind) + upgrade buttons (Better Axe, Auto Chopper, Element Power, Prestige).
Use a warm, slightly cartoony colour palette (browns, greens, soft blues). Make sure every button is large enough for thumbs.
Add a simple dark-brown wooden frame aesthetic that feels consistent.


Phase 2: Core Chopping Loop

Prompt 2.1 – Tree and Chopper data models
Create these scripts:

TreeData – health, max health, element type (none/fire/ice/bolt/earth/wind), chop reward, any special flags.
ChopperData – current axe damage, auto-chop rate, active element, prestige multiplier.
EnchantmentData – type, duration or remaining trees, description.
Store the current tree, the queue of upcoming trees, and all player stats inside the GameState autoload.

Prompt 2.2 – Basic chopping
Implement manual chopping:

On tap/click anywhere on the tree or a dedicated chop button, play Chopper’s axe-swing animation.
Subtract axe damage from the current tree’s health (apply elemental bonus/penalty if an element is active).
Show floating damage numbers.
When health reaches zero: play a tree-fall animation, award Chops, generate the next tree from the upcoming queue, and shift the preview forward.
Add a short screen shake and particle burst (leaves + wood chips) on every hit and a bigger effect on tree kill.
Prompt 2.3 – Upcoming tree queue & preview
Maintain a queue of the next 3 trees at all times.
When a tree is chopped down, the first upcoming tree becomes current and a new tree is generated and added to the end of the queue.
The preview UI must always show the next 2–3 trees with clear elemental icons and a rough difficulty indicator (colour or small stars).
Tree generation should be weighted so the player regularly sees both matching and mismatched elements, creating meaningful decisions.


Phase 3: Upgrades, Elements & Enchantments

Prompt 3.1 – Upgrade system
Implement the four core upgrades:

Better Axe – increases base damage. Cost scales.
Auto Chopper – adds passive chops per second. Cost scales.
Element Power – spends Chops to activate a chosen element for the next N trees (or a short time).
Prestige Reset – becomes available after a high Chop threshold. Resets current run progress but increases a permanent prestige multiplier.
All upgrade costs and values must live in one easy-to-tune dictionary or resource.
Buttons must show current cost and disable themselves when the player cannot afford them.

Prompt 3.2 – Elemental system
When Element Power is active, the chosen element is applied to Chopper’s attacks.
Matching element = bonus damage.
Opposing element = reduced damage.
Neutral = normal damage.

Show a clear visual indicator on Chopper and on the current tree when an element is active.
The five elemental buttons in the bottom panel select which element will be used when the player buys Element Power.

Prompt 3.3 – Enchantment system
After a tree is chopped there is a chance (or guaranteed at certain milestones) to receive an enchantment.
Examples to implement first:

“Empowered” – next 5 trees take +40% damage.
“Elemental Surge” – free Element Power of a random element.
“Gold Rush” – next tree gives 3× Chops.
“Auto Boost” – Auto Chopper works 50% faster for 20 seconds.
Enchantments appear as a clear popup or banner the player can read and then dismiss.
Active enchantments are shown as small icons near the top or on Chopper.


Phase 4: Juice, Audio & Feel

Prompt 4.1 – Animation and particles
Make chopping feel excellent:

Chopper has a proper multi-frame axe swing (anticipation → hit → recovery).
Tree shakes on every hit and has a distinct fall animation.
Leaf and wood-chip particles on hit. Bigger burst + screen shake on kill.
Floating “+X Chops” text that arcs upward and fades.
Smooth health bar animation.
Prompt 4.2 – Audio
Add an AudioManager autoload.
Implement:

Axe swing / hit sounds (several variations).
Tree crack and fall sounds.
Currency collect sound.
Upgrade purchase sound.
Enchantment reveal sound.
Soft looping background music that can be muted.
All volumes and mute states are saved locally.

Prompt 4.3 – Polish pass on UI

Buttons have pressed and disabled states.
Cost text turns red or greys out when unaffordable.
Prestige button pulses when it becomes available.
Upcoming tree previews have a subtle idle animation so they feel alive.
Safe area handling for notched phones.

Phase 5: Prestige, Balance & Content

Prompt 5.1 – Prestige system
When the player reaches the prestige threshold:

Show a clear “Prestige Available” state.
On prestige: reset current chops, upgrades (except prestige level), and tree progress.
Increase prestige level by 1 and apply a permanent multiplier to all chop gains and damage.
Keep the prestige level and its multiplier across sessions.
Prompt 5.2 – Balance and progression curve
Tune the numbers so that:

Early game feels fast and rewarding.
Mid game introduces real decisions about when to buy Element Power versus pushing for enchantments.
Prestige feels meaningful but not mandatory every five minutes.
A normal session lasts 5–15 minutes before the player naturally wants to prestige or stop.
Expose all key constants (damage scaling, cost scaling, enchantment chances, elemental multipliers) in one place.

Prompt 5.3 – Save / Load
Implement robust local saving of:

Total chops
All upgrade levels
Prestige level and multiplier
Current tree and upcoming queue
Active enchantments and element
Audio settings
Use Godot’s ConfigFile or a simple JSON save. Auto-save after every tree kill and after every upgrade purchase.


Phase 6: Mobile Polish & Release

Prompt 6.1 – Mobile-specific polish

Confirm the game runs at a stable 60 fps on mid-range Android devices.
Handle different aspect ratios cleanly (portrait primary).
Large touch targets everywhere.
Pause when the app goes to background and resume cleanly.
First-run tutorial that teaches: tapping to chop, reading the upcoming trees, buying Element Power, and what enchantments do. Keep it to 4 short steps maximum.
Prompt 6.2 – Release preparation
Prepare the project for store submission:

Final game name, short description, and icon.
Splash screen / logo scene.
Version number and build settings for Android (AAB) and iOS.
Privacy note stating that only local save data is stored.
Clear export instructions for both platforms.
A simple credits screen.

How to Use This Document

Save the entire content as PROMPTS.md.
Open Godot 4 and create the project.
Start a new conversation with your coding assistant and paste Prompt 1.1.
After each prompt, run the game and test on both desktop and a phone/emulator.
When something feels weak (especially the axe swing or the upcoming-tree decision), describe exactly what you want improved before continuing.
By the end of Phase 3 you will have a fully playable core loop with strategy. Phase 4 makes it feel great. Phase 5 adds the long-term hook.
