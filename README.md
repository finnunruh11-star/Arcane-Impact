# Arcane Impact

Arcane Impact is a clean-room Godot 4.7.1 prototype for a controller-first,
top-down action roguelite. It shares no source code or assets with PVP_DIMIR.

## Current milestone

The current playable build opens on a two-hero roster and sends the selected
hero into escalating waves in the Shattered Reliquary.

Kat, the Vampiric Bulwark, features:

- a buffered three-hit Gravebell combo;
- directional Greatshield guarding, perfect guards, and absorbed-force slams;
- Bastion March, Leech Choir summons, Mourning Halo, and Black Communion;
- health, ward, Resolve, curse stacks, lifesteal, and Vitality.

Sniff, the Voltaic Gambler, features:

- fast collision-backed Lightning Darts with nearby-target chaining;
- a charged, enemy-phasing Thunder Dash that spends and rebuilds Blessing;
- Roaring Blessing and Explosive Surge health wagers;
- an invulnerable damaging Flashstep and crowned Divine Annihilation;
- a ten-stack Blessing economy with visible cash-out timing.

Both slices include:

- three active enemy profiles with readable collision-matched telegraphs;
- sprite-sheet VFX, layered synthesized SFX, hit-stop, camera trauma, flash,
  floating damage, and Xbox rumble;
- controller-aware HUD glyphs and escalating wave recovery.

## Controls

### Roster

| Action | Keyboard and mouse | Xbox controller |
| --- | --- | --- |
| Select hero | A/D, arrows, mouse, or 1/2 | Left stick or D-pad |
| Deploy | Enter, Space, F, or button click | A or X |

### Shared combat

| Action | Keyboard and mouse | Xbox controller |
| --- | --- | --- |
| Move / aim | WASD / mouse | Left stick / right stick |
| Collision debug | Tab | D-pad up |

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

## Run locally

On Windows, double-click [Start_Arcane_Impact.bat](Start_Arcane_Impact.bat). It finds Godot on `PATH`,
in the project folder, or in the standard WinGet package directory and starts
the correct project automatically.

You can also open [project.godot](project.godot) in Godot 4.7.1 and press F5
to run the project.

## Player guide

See [docs/PLAYER_GUIDE.md](docs/PLAYER_GUIDE.md) for the complete encounter rules, HUD reference,
resources, controls, ability behavior, cooldowns, health costs, and recommended
combat loops for Kat and Sniff.

If `godot` is available on `PATH`, the command-line equivalent is:

```powershell
godot --path .
```

Run headless checks with:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/soak_kat_slice.gd
godot --headless --path . --script res://tests/soak_sniff_slice.gd
```

This prototype is not currently licensed for redistribution.

Third-party visual effects are credited in `THIRD_PARTY_NOTICES.md` and
tracked individually in `docs/asset-provenance.md`.