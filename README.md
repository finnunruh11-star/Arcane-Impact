# Arcane Impact

Arcane Impact is a clean-room Godot 4.7.1 prototype for a controller-first,
arena-survival action roguelite. It shares no source code or assets with PVP_DIMIR.

## Current milestone

The current playable build opens on a four-hero roster and sends the selected
hero into a ten-minute run in the Shattered Reliquary. Enemies enter
continuously from every edge, grow stronger over time, and drop Arcane Essence.
Each hero starts with only their manually aimed basic attack. Collect enough Essence
to pause the horde and choose one of six random upgrades: three stats and three
hero abilities. The first ability pick unlocks rank 1; repeat picks improve its
power and cooldown. Ability behavior advances at run levels 5, 10, 15, and 20.
Every offered boon has a 15% chance to become a double upgrade, increased by
Luck. Strength, Dexterity, and Intelligence scale their matching attacks while
Mana, Vitality, and Luck improve resource, survival, and critical-hit systems.
Survive the full ritual to win.

Kat, the Vampiric Bulwark, features:

- a buffered three-hit Gravebell combo;
- directional Greatshield guarding, perfect guards, and absorbed-force slams;
- mana-draining toggle versions of Leech Choir and Mourning Halo;
- health, Mana, Ward, Resolve, curse stacks, lifesteal, and Vitality.

Sniff, the Voltaic Gambler, features:

- fast collision-backed Lightning Darts with nearby-target chaining;
- a charged, enemy-phasing Thunder Dash that spends and rebuilds Blessing;
- Roaring Blessing and Explosive Surge health wagers;
- an invulnerable damaging Flashstep and crowned Divine Annihilation;
- a deliberately hungry Mana economy layered over ten-stack Blessing wagers.

Nad, the Eldritch Tactician, features:

- Foresee probes that build Mental Focus and briefly lock one target;
- charged remote Eldritch Mantle fields with collision-matched lockdown zones;
- three persistent Terrain Anchors that slow enemies and collapse together;
- Mental Cascade lock extension, Fold Space, and a prepared Arcane Conduit;
- Mana restored by fresh locks, extensions, and prepared control cash-outs;
- upgrades that escalate into void webs, tentacles, rifts, and abyssal eyes.

Fin, the Shadow Artificer, features:

- tap-cycle and held directional switching among Nightblade, Arbalest,
  Huntsman, and Artificer forms;
- a shared five-stack Pierce Mark preparation and finisher economy;
- concealment, backstabs, and an escape-only Umbral Step;
- Crossbow, Bow, Dagger, Throwing Dagger, Shadow Bind, Potions, Smoke Bombs,
  and Mutivarg's Rod, with no Legendary items;
- free physical and alchemical tools, with Mana reserved for shadow and Rod magic;
- persistent reloads and finite supplies that continue recovering across forms.

All four slices include:

- manually aimed primary attacks and player-controlled active skills;
- a scrolling 2560-by-1560 arena with solid reliquary ruins and camera follow;
- three continuously spawning enemy profiles with readable collision-matched telegraphs;
- Arcane Essence pickups, six-choice levels, ranked abilities, five behavior tiers,
    six stacking attributes, critical hits, double boons, a run timer, and kill count;
- sprite-sheet VFX, layered synthesized SFX, hit-stop, camera trauma, flash,
  floating damage, and Xbox rumble;
- controller-aware HUD glyphs and a retry/roster run summary.

## Controls

### Roster

| Action | Keyboard and mouse | Xbox controller |
| --- | --- | --- |
| Select hero | A/D, arrows, mouse, or 1/2/3/4 | Left stick or D-pad |
| Begin run | Enter, Space, F, or button click | A or X |

### Shared combat

| Action | Keyboard and mouse | Xbox controller |
| --- | --- | --- |
| Move | WASD | Left stick |
| Aim | Mouse | Right stick |
| Basic attack | Left mouse | Right trigger |
| Choose level boon | 1/2/3/4/5/6 or mouse | D-pad / left stick and A |
| Return to roster | Escape | Menu |
| Collision debug | Tab | D-pad up |

Primary attacks happen only when their input is pressed and use mouse or
right-stick aim. Active inputs become available after that ability is selected
from a level-up offer. Combat HUD slots show `LOCKED`, then the current tier
and rank after unlocking.

### Run progression

- **Ability tiers:** tier 1 at level 1, tier 2 at level 5, tier 3 at level 10,
    tier 4 at level 15, and tier 5 at level 20.
- **Ability ranks:** the first pick unlocks rank 1. Every repeat pick adds 12%
    ability power and improves its cooldown independently of tier milestones.
- **Attack scaling:** swords and heavy weapons use Strength; bows and daggers
    use Dexterity; spells use Intelligence.
- **Attributes:** Strength adds Strength damage and maximum Resolve; Dexterity
    adds Dexterity damage and movement speed; Intelligence adds spell damage
    and Essence gain; Mana adds capacity and regeneration; Vitality adds health
    and health regeneration; Luck adds critical chance, critical damage, and
    double-upgrade chance.
- **Double boons:** every displayed option independently has a base 15% chance
    to grant two ranks. Each Luck rank adds 5 percentage points.
- **Tier 3:** preserves the original full hero kits. Tiers 1-2 are deliberately
    weaker versions; tiers 4-5 add new mechanics and stronger identity payoffs.

### Kat

| Action | Keyboard and mouse | Xbox controller |
| --- | --- | --- |
| Gravebell combo | Left mouse | Right trigger |
| Greatshield guard and slam | Hold/release right mouse | Hold/release left trigger |
| Leech Choir | Q | Right bumper |
| Mourning Halo | E | Left bumper |
| Bastion March | Space | A |
| Black Communion | R | Y |

### Sniff

| Action | Keyboard and mouse | Xbox controller |
| --- | --- | --- |
| Lightning Dart | Left mouse | Right trigger |
| Thunder Dash | Hold/release right mouse | Hold/release left trigger |
| Roaring Blessing | Q | Right bumper |
| Explosive Surge | E | Left bumper |
| Flashstep | Space | A |
| Divine Annihilation | R | Y |

### Nad

| Action | Keyboard and mouse | Xbox controller |
| --- | --- | --- |
| Foresee | Left mouse | Right trigger |
| Eldritch Mantle | Hold/release right mouse | Hold/release left trigger |
| Terrain Anchor / collapse | Q | Right bumper |
| Mental Cascade | E | Left bumper |
| Fold Space | Space | A |
| Arcane Conduit | R | Y |

### Fin

| Action | Keyboard and mouse | Xbox controller |
| --- | --- | --- |
| Form primary | Left mouse | Right trigger |
| Form signature / charge | Hold/release right mouse | Hold/release left trigger |
| Form tool 1 | Q | Right bumper |
| Form tool 2 | E | Left bumper |
| Umbral Step | Space | A |
| Cycle / directional form select | Tap / hold R | Tap / hold Y |

## Run locally

On Windows, double-click [Start_Arcane_Impact.bat](Start_Arcane_Impact.bat). It finds Godot on `PATH`,
in the project folder, or in the standard WinGet package directory and starts
the correct project automatically. The launcher first refreshes Godot's local
script-class cache and imported assets, which are intentionally not stored in
Git. This makes the first run after cloning or pulling work on a new device.

You can also open [project.godot](project.godot) in Godot 4.7.1 and press F5
to run the project.

## Player guide

See [docs/PLAYER_GUIDE.md](docs/PLAYER_GUIDE.md) for the complete encounter rules, HUD reference,
resources, controls, ability behavior, cooldowns, costs, and recommended combat
loops for Kat, Sniff, Nad, and Fin.

If `godot` is available on `PATH`, the command-line equivalent is:

```powershell
godot --headless --editor --path . --quit
godot --path .
```

Run headless checks with:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/soak_kat_slice.gd
godot --headless --path . --script res://tests/soak_sniff_slice.gd
godot --headless --path . --script res://tests/soak_nad_slice.gd
godot --headless --path . --script res://tests/soak_fin_slice.gd
godot --headless --path . --script res://tests/test_roster_navigation.gd
godot --headless --path . --script res://tests/test_survivor_run.gd
godot --path . --script res://tests/capture_survivor_progression.gd
```

This prototype is not currently licensed for redistribution.

Third-party visual effects are credited in `THIRD_PARTY_NOTICES.md` and
tracked individually in `docs/asset-provenance.md`.