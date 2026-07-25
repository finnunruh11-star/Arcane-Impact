# Arcane Impact

Arcane Impact is a clean-room Godot 4.7.1 prototype for a controller-first,
arena-survival action roguelite. It shares no source code or assets with PVP_DIMIR.

## Current milestone

The current playable build opens on a four-hero roster and sends the selected
hero into a ten-minute run in the Shattered Reliquary. Enemies enter
continuously from every edge, grow stronger over time, and automatically grant
Arcane Essence when defeated.
Each roster card also opens a training lab for that hero, with five resetting
test dummies and instant level controls from 1 through 20.
Each hero starts with their manually aimed basic attack and a rank-1 defensive
escape. Level thresholds follow an easier 3, 5, 7, 9 Essence curve. Filling the
bar pauses the horde and presents six random upgrades: three stats and three
hero abilities. The first pick of any other
ability unlocks rank 1; repeat picks improve its power and cooldown. Each active
ability evolves independently at ranks 5, 10, 15, and 20, while the basic attack
evolves with run level at the same milestones.
Every offered boon has a 15% chance to become a double upgrade, increased by
Luck. Strength, Dexterity, and Intelligence scale their matching attacks while
Mana, Vitality, and Luck improve resource, survival, and critical-hit systems.
Survive the full ritual to win.

Kat, the Vampiric Bulwark, features:

- a buffered three-hit Gravebell combo;
- directional Greatshield guarding, perfect guards, and absorbed-force slams;
- mana-draining toggle versions of Leech Choir and Mourning Halo;
- health, Mana, Ward, Resolve, curse stacks, lifesteal, and Vitality.

Sniff, the Storm Catastrophist, features:

- fast collision-backed Lightning Darts with nearby-target chaining;
- Wayward Bolt, a fast phasing dash that violently rerolls its direction;
- three enormous chain-lightning spells that each consume more than half of base Mana;
- two stored charges for every non-basic ability with continuous sequential recharge;
- Voltaic Load from successful offensive ability casts, increasing speed and spell power;
- Cataclysm Discharge, which consumes Load to scale into a crowd wipe;
- overload damage and spell backfires that can genuinely kill their caster;
- retained Lightning Darts and a fast, invulnerable Flashstep that grant no Load.

Nad, the Eldritch Tactician, features:

- Foresee probes that build Mental Focus and briefly lock one target;
- charged remote Eldritch Mantle fields with collision-matched lockdown zones;
- three persistent Terrain Anchors that slow enemies and collapse together;
- low direct damage, Mental Cascade lock extension, and a prepared Arcane Conduit;
- 120 Mana, hit refunds, and a strong five-second Arcane Recursion window;
- Mantle tentacle executions and a rank-20, ten-second Eldritch Form capstone.

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
- six state-animated enemy roles spanning melee, tank, rushdown, ranged, and support;
- a six-phase, threat-budgeted horde that opens with individual duels and rises
    to a hard cap of 18, with adaptive refills and separate ranged/support caps;
- tactical ranged engagement bands, post-shot relocation, formation spacing,
    and collision-matched slam, charge, projectile-lane, and support telegraphs;
- automatically credited Arcane Essence, six-choice levels, ranked abilities, five behavior tiers,
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
| Begin training | Click `TRAIN WITH` on a hero card | Select the button and press A |

### Training

Training uses the selected hero's real combat kit against five self-resetting
dummies. Level presets immediately set the basic attack and every active
ability to the matching rank and behavior tier. The stat panel applies real
Strength, Dexterity, Intelligence, Mana, Vitality, and Luck upgrades in +1 or
+5 increments; these ranks persist while changing training level.

| Action | Keyboard and mouse |
| --- | --- |
| Set level | Click 1, 5, 10, 15, or 20 |
| Adjust one level | Page Up / Page Down or click + / - |
| Choose stat pick size | Click `PICK +1` / `PICK +5` |
| Add stat upgrades | Click STR, DEX, INT, MANA, VIT, or LUCK |
| Reset all dummies | F or click `RESET` |
| Return to roster | Escape or click `ROSTER` |

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
right-stick aim. Each hero's defensive escape is available immediately at rank
1; other active inputs become available after that ability is selected from a
level-up offer. Combat HUD slots show `LOCKED`, then the current tier and rank
after unlocking.

### Run progression

- **Active ability tiers:** each skill reaches tier 1 at rank 1, tier 2 at rank
    5, tier 3 at rank 10, tier 4 at rank 15, and tier 5 at rank 20. Skills evolve
    independently, and the defensive escape starts at rank 1.
- **Basic attack tiers:** the primary reaches tiers 1-5 at run levels 1, 5, 10,
    15, and 20. Its power multiplier rises to 1.00, 1.20, 1.45, 1.75, and 2.15,
    with hero-specific range, speed, chaining, or echo mechanics.
- **Ability ranks:** the first pick of a locked skill unlocks rank 1. Every repeat
    pick adds 12% ability power, improves its cooldown, and advances that skill
    toward its next evolution.
- **Attack scaling:** swords and heavy weapons use Strength; bows and daggers
    use Dexterity; spells use Intelligence.
- **Attributes:** Strength adds Strength damage and maximum Resolve; Dexterity
    adds Dexterity damage and movement speed; Intelligence adds spell damage
    and Essence gain; Mana adds capacity and regeneration; Vitality adds health
    and health regeneration on top of every hero's base 1.5 health per second;
    Luck adds critical chance, critical damage, and double-upgrade chance.
- **Double boons:** every displayed option independently has a base 15% chance
    to grant two ranks. Each Luck rank adds 5 percentage points.
- **Tier 3:** preserves the original full hero kits. Tiers 1-2 are deliberately
    constrained versions; tiers 4-5 add new mechanics and stronger identity
    payoffs to the specific skill or basic attack that reached the milestone.

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
| Wayward Bolt | Right mouse | Left trigger |
| Tempest Covenant | Q | Right bumper |
| Cataclysm Discharge | E | Left bumper |
| Flashstep | Space | A |
| Worldstorm | R | Y |

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
godot --headless --path . --script res://tests/test_training_mode.gd
godot --path . --script res://tests/capture_survivor_progression.gd
godot --path . --script res://tests/capture_training_mode.gd
```

This prototype is not currently licensed for redistribution.

Third-party enemy sprites and visual effects are credited in `THIRD_PARTY_NOTICES.md` and
tracked individually in `docs/asset-provenance.md`.