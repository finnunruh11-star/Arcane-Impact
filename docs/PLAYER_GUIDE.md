# Arcane Impact Player Guide

## Starting the game

Double-click `Start_Arcane_Impact.bat` in the project folder. The launcher finds
Godot automatically and opens the roster. If Godot is missing, it displays the
WinGet installation command instead of closing silently.

On every start, the launcher briefly opens Godot in headless editor mode to
build or refresh `.godot/global_script_class_cache.cfg` and imported assets.
The `.godot` directory is machine-generated and excluded from Git, so this
step is required after a fresh clone and prevents `Identifier not declared`
parse errors in the roster. Do not run `godot --path .` first on a fresh clone;
use the launcher, or run these commands from the project directory:

```powershell
godot --headless --editor --path . --quit
godot --path .
```

On the roster, select Kat or Sniff with A/D, the arrow keys, mouse, number keys
1/2, the left stick, or the D-pad. Deploy with Enter, Space, F, a character
button, Xbox A, or Xbox X.

## Goal and encounter flow

Arcane Impact is currently an endless combat arena. Defeat every enemy in a
wave to begin the next one after a short pause. Wave 1 starts with three
enemies; later waves grow to a maximum of five. Enemy profiles rotate between:

- **Ashen Pursuer:** balanced speed, durability, and attack timing.
- **Iron Penitent:** slow, durable, and hard-hitting, with the longest windup.
- **Relic Stalker:** fast and fragile, with the shortest windup.

Red ground shapes show the exact area of an incoming enemy strike. Enemy health
is the red bar above the enemy; cyan is Resolve. Defeat reloads the selected
hero's encounter after 2.6 seconds.

Wave recovery depends on the hero:

- Kat heals 42 and gains 14 Vitality after clearing a wave.
- Sniff heals 30 and gains 2 Blessing after clearing a wave.

## Shared combat mechanics

### Movement and aim

Move with WASD or the left stick. Aim independently with the mouse or right
stick. Most directional abilities use the current aim direction; movement
abilities use held movement input when available and otherwise use aim.

### Health

Health reaches zero when the hero is defeated. Kat has 340 maximum health;
Sniff has 245. Sniff's ability health costs cannot reduce health below 1, but
enemy attacks still can.

### Resolve and stagger

Resolve is the cyan control-resistance bar. Attacks can deal health damage and
Resolve damage independently. When Resolve reaches zero, the target is
staggered and its attack is interrupted. Resolve partially refills on a break
and regenerates over time.

Kat has 210 maximum Resolve and regenerates 5 per second. Sniff has 138 and
regenerates 6.5 per second. Enemy variants have different Resolve totals.

### Collision and hit confirmation

Gameplay uses collision-backed hitboxes and hurtboxes. Visual effects do not
decide whether an attack connects. Stronger hits use longer hit-stop, more
camera trauma, stronger controller rumble, brighter effects, and heavier SFX.
Each attack activation can hit a target only once unless the move explicitly
pulses or chains.

Press Tab or D-pad Up to display the active player attack geometry.

### Input buffering

Primary attacks pressed during another action are buffered for 0.12 seconds.
Kat also buffers the next Gravebell strike during combo recovery.

## Kat: Vampiric Bulwark

Kat is a durable melee controller who turns enemy pressure and dealt damage
into healing, Ward, curses, and an ultimate resource.

### Resources

- **Health:** 340 maximum.
- **Resolve:** 210 maximum.
- **Ward:** up to 95 temporary damage absorption. Incoming damage removes Ward
  before health. Healing beyond maximum health becomes Ward.
- **Vitality / Tithe of Life:** 0-100. Kat begins with 35. Dealing damage,
  draining enemies, and guarding attacks builds it. Black Communion requires
  100 and spends all of it.
- **Curse:** enemies can hold up to five stacks. Curses deal periodic damage
  for their duration. Curse damage heals Kat and grants Vitality.

### Gravebell

**Input:** Left mouse / Right trigger

A three-hit melee combo. The first two strikes are quick; the third has more
reach, damage, Resolve damage, knockback, hit-stop, and camera impact. The
finisher applies one Curse stack. Successful strikes heal Kat for 13% of their
actual damage and build Vitality.

Base health damage by stage: 16 / 21 / 38.

### Greatshield guard and shield slam

**Input:** Hold and release Right mouse / Left trigger

While held, Kat guards a 144-degree frontal arc and moves slowly. Attacks from
behind bypass the guard. A frontal hit during the first 0.19 seconds is a
perfect guard: it deals no health damage, grants more Vitality, and reflects
two Curse stacks to the attacker. Later frontal blocks take only 12% of the
incoming health damage.

Release the guard to slam. Slam power grows from both hold time and damage
absorbed while guarding. A stronger slam has greater range, width, damage,
Resolve damage, and knockback. The slam applies two Curse stacks and heals Kat
for 24% of actual damage.

### Leech Choir

**Input:** Q / Right bumper  
**Cooldown:** 9.5 seconds when motes are summoned

Summons two autonomous Leech Motes, up to a total cap of three. Motes orbit Kat,
seek living enemies within 460 pixels, and strongly prefer cursed targets.
Each strike deals 9 damage, then the mote returns to orbit. A successful mote
strike heals Kat for 58% of actual damage and grants 6 Vitality.

Using the ability at the three-mote cap triggers only a short 2-second retry
cooldown.

### Mourning Halo

**Input:** E / Left bumper  
**Cooldown:** 11.5 seconds

Creates a mobile 188-pixel aura around Kat for 5.2 seconds. It pulses every
0.58 seconds, dealing 6 health and 7 Resolve damage and applying one Curse
stack for 4.5 seconds. Halo damage heals Kat for 38% of total damage dealt per
pulse and grants 2.4 Vitality for each enemy hit.

Recasting replaces the existing Halo.

### Bastion March

**Input:** Space / Xbox A  
**Cooldown:** 3.6 seconds

Kat surges 650 pixels per second in the movement direction, or aim direction
when no movement input is held. March carries the frontal guard, damages each
crossed enemy once, applies one Curse stack, deals heavy Resolve damage and
knockback, heals for 10% of actual damage, and builds Vitality.

### Black Communion

**Input:** R / Xbox Y  
**Requirement:** 100 Vitality

After a 0.62-second invocation, Kat affects every cursed enemy and every
uncursed enemy within 390 pixels. Targets are pulled inward and struck.
Damage scales per Curse stack: 42 base health damage plus 11 per stack, and 62
base Resolve damage plus 8 per stack.

Kat heals for 22% of the ultimate's total actual damage, gains 16 Ward per
affected enemy up to the Ward cap, and spends all Vitality.

### Kat combat loop

1. Use Gravebell, Halo, March, and perfect guards to spread Curse and gain
   Vitality.
2. Keep Leech Motes active; cursed targets attract them first.
3. Guard dangerous windups and release a powered shield slam into groups.
4. Cast Black Communion at 100 Vitality when several targets are cursed.
5. Convert damage into healing and excess healing into Ward to stay in combat.

## Sniff: Voltaic Gambler

Sniff is a fast ranged damage dealer who builds Blessing through successful
hits, then wagers health and stacks for mobility and explosive area damage.

### Resources

- **Health:** 245 maximum. Ability costs are nonlethal.
- **Resolve:** 138 maximum.
- **Blessing of Roaring Thunder:** 0-10 stacks. Lightning Dart and Thunder Dash
  hits build stacks. Damage from several abilities scales with current or spent
  Blessing. Reaching 10 displays **Thunder Crowned**.
- **Overcharge:** Roaring Blessing guarantees Lightning Dart chains for 3.8
  seconds.

### Lightning Dart

**Input:** Left mouse / Right trigger

Fires a fast collision-backed projectile. A direct hit builds one Blessing and
has a 30% chance to chain to a second enemy within 265 pixels. Overcharge makes
the chain guaranteed. At seven or more Blessing when fired, the chain can jump
to two nearby enemies instead of one. Every successful chain hit also grants
one Blessing.

The direct hit starts at 18 damage and gains 8.5% damage per Blessing snapshot.
Each chain step deals 72% of the previous depth's damage.

### Thunder Dash

**Input:** Hold and release Right mouse / Left trigger

Charge for up to 0.82 seconds. Charge controls travel distance from 185 to 445
pixels and increases damage, Resolve damage, knockback, feedback, and partial
invulnerability time. The dash uses movement direction when held, otherwise
it follows aim.

On release, it spends up to three Blessing. Each spent stack adds 16% damage.
Sniff phases through enemy bodies while the attack sensor damages every crossed
enemy once. Each successful Dash hit rebuilds one Blessing.

### Roaring Blessing

**Input:** Q / Right bumper  
**Cooldown:** 8 seconds  
**Cost:** 8% of maximum health

Immediately grants four Blessing and Overcharge for 3.8 seconds. Use it to
force Dart chains, reach Thunder Crowned quickly, or prepare a large Surge.
The health cost cannot defeat Sniff by itself.

### Explosive Surge

**Input:** E / Left bumper  
**Cooldown:** 7.5 seconds  
**Cost:** 10% of maximum health plus all current Blessing

Consumes every Blessing stack and detonates a circular hitbox around Sniff
after 0.27 seconds. Its radius is 148 pixels plus 8 per stack spent. It deals
31 base health damage plus 7 per stack, 34 base Resolve damage plus 4.5 per
stack, and increasingly strong knockback and impact feedback.

A zero-stack Surge is legal but much weaker. The health cost is nonlethal.

### Flashstep

**Input:** Space / Xbox A  
**Cooldown:** 2.2 seconds

Phases 158 pixels in the movement or aim direction. Sniff is invulnerable for
0.23 seconds, passes through enemy bodies, and damages every crossed enemy once.
Flashstep damage increases slightly with current Blessing but does not spend or
build stacks.

### Divine Annihilation

**Input:** R / Xbox Y  
**Cooldown:** 20 seconds  
**Cost:** 15% of maximum health plus all current Blessing

After a 0.68-second cast, strikes every living enemy within 560 pixels and
chains a visible lightning arc through the affected group. It deals 68 base
health damage plus 9 per Blessing spent, and 82 base Resolve damage plus 6 per
stack, with maximum hit-stop, shake, flash, and rumble.

Casting at 10 Blessing is **crowned** and grants 1.72 seconds of invulnerability,
covering the cast and its immediate recovery. The health cost is nonlethal.

### Sniff combat loop

1. Land Lightning Darts to build Blessing safely.
2. Use Roaring Blessing to trade health for four stacks and guaranteed chains.
3. Dash through lines of enemies, spending up to three stacks and rebuilding
   them on successful hits.
4. Spend a large stack count on Explosive Surge when enemies surround you.
5. Reach 10 Blessing before Divine Annihilation for maximum damage and crowned
   invulnerability.
6. Use Flashstep to cross attacks, reposition, and preserve health for wagers.

## HUD reference

The upper-left panel shows the selected hero's health, Resolve, state, and
hero-specific resources. Kat also shows Ward over health and a Vitality bar;
Sniff shows ten discrete Blessing pips. The bottom slots show keyboard or Xbox
glyphs automatically, cooldown progress, readiness, resource requirements,
and Sniff's health prices.

The upper-center panel shows the wave and number of living enemies. Large
center announcements identify waves, resource milestones, and ultimate casts.
Floating numbers report health damage dealt.

## Feedback and accessibility notes

- Enemy telegraphs and optional debug geometry represent gameplay collision;
  sprite effects are presentation only.
- Hit-stop pauses combat simulation while UI, VFX, and audio continue.
- Camera shake, flashes, procedural SFX, floating damage, and controller rumble
  reinforce impact intensity.
- Keyboard/mouse and Xbox-style controls can be switched during play; HUD
  glyphs update automatically.
