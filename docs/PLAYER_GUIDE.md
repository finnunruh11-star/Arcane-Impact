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

On the roster, select Kat, Sniff, Nad, or Fin with A/D, the arrow keys, mouse,
number keys 1/2/3/4, the left stick, or the D-pad. Deploy with Enter, Space, F, a character
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
- Nad heals 28 and restores 34 Mana after clearing a wave.
- Fin heals 28, refills his tool supplies and Crossbow, and gains 22 Ward after
  clearing a wave.

## Shared combat mechanics

### Movement and aim

Move with WASD or the left stick. Aim independently with the mouse or right
stick. Most directional abilities use the current aim direction; movement
abilities use held movement input when available and otherwise use aim.

### Health

Health reaches zero when the hero is defeated. Kat has 340 maximum health,
Sniff and Fin have 245, and Nad has 220. Sniff's ability health costs cannot reduce
health below 1, but enemy attacks still can.

### Resolve and stagger

Resolve is the cyan control-resistance bar. Attacks can deal health damage and
Resolve damage independently. When Resolve reaches zero, the target is
staggered and its attack is interrupted. Resolve partially refills on a break
and regenerates over time.

Kat has 210 maximum Resolve and regenerates 5 per second. Sniff has 138 and
regenerates 6.5 per second. Nad has 160 and regenerates 5.8 per second. Fin has
175 and regenerates 5.5 per second. Enemy variants have different Resolve totals.

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

**Input:** Left mouse / Right trigger<br>

A three-hit melee combo. The first two strikes are quick; the third has more
reach, damage, Resolve damage, knockback, hit-stop, and camera impact. The
finisher applies one Curse stack. Successful strikes heal Kat for 13% of their
actual damage and build Vitality.

Base health damage by stage: 16 / 21 / 38.

### Greatshield guard and shield slam

**Input:** Hold and release Right mouse / Left trigger<br>

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

## Nad: Eldritch Tactician

Nad is a ranged control and zone mage. Her direct damage is modest without
preparation; she becomes dangerous by placing enemies under Mental Focus,
locking them out of actions, extending that control, and collapsing prepared
targets with Arcane Conduit.

### Resources and control

- **Health:** 220 maximum.
- **Resolve:** 160 maximum.
- **Mana:** 0-100 and regenerates at 13 per second. Every offensive ability
  spends Mana; Fold Space is free.
- **Mental Focus:** enemies can hold up to five stacks. Focus lasts until its
  current duration expires. A target under Eldritch Lock takes 12% more health
  damage per Focus stack, up to a 60% multiplier. Focus without an active Lock
  does not grant this multiplier.
- **Eldritch Lock:** cancels the target's current attack, freezes movement, and
  exposes its Focus vulnerability. Mental Cascade extends only an existing
  Lock; it does not create one on an uncontrolled target.

### Foresee

**Input:** Left mouse / Right trigger<br>
**Cost:** 7 Mana

Projects a narrow 242-pixel collision probe. The nearest enemy in the probe
gains one Mental Focus for 7 seconds and is locked for 0.24 seconds plus 0.05
seconds per Focus stack it already held. Foresee deals 11 base health damage
plus 1.5 per resulting Focus stack and 17 base Resolve damage plus 2 per stack.

Use repeated Foresee hits to prepare one priority target while conserving Mana.
Primary input pressed during another action is buffered for 0.12 seconds.

### Eldritch Mantle

**Input:** Hold and release Right mouse / Left trigger<br>
**Cost:** 32 Mana

Charge for up to 1.05 seconds while moving slowly. The remote field grows from
135 to 230 pixels in radius and moves from 185 to 265 pixels along Nad's aim.
Releasing it gives every enemy inside two Focus for 8 seconds and locks them
for 1.6 to 3.8 seconds based on charge. Health damage grows from 18 to 36;
Resolve damage grows from 26 to 54.

The visible circle is the gameplay collision radius. Use Mantle to interrupt
multiple windups or establish the long Lock window that Cascade can extend.

### Terrain Anchor

**Input:** Q / Right bumper<br>
**Cost:** 18 Mana per Anchor<br>
**Placement cooldown:** 0.75 seconds<br>
**Collapse cooldown:** 8 seconds

Places a persistent 132-pixel field 265 pixels along the aim direction. Each
Anchor lasts 12 seconds and slows enemies inside it to 52% movement speed. Nad
can maintain three. Once all three exist, the next Anchor command collapses
the complete lattice instead of spending Mana on a fourth.

Each collapsing field deals 26 health and 34 Resolve damage, applies one Focus
for 7 seconds, and locks targets for 0.65 seconds. Overlapping fields each have
their own authoritative circle, so deliberate overlap creates a stronger but
more concentrated collapse.

### Mental Cascade

**Input:** E / Left bumper<br>
**Cost:** 24 Mana<br>
**Cooldown:** 6.5 seconds

Projects a broad 324-pixel collision cone. Every target gains one Focus for 8
seconds and takes 24 health damage plus 4 per Focus stack it held before the
hit. If a target was already locked, Cascade extends that Lock by 0.55 seconds
plus 0.1 per previous Focus stack, up to 6 seconds remaining.

Cast Cascade after Mantle or an Anchor collapse. Casting it first builds Focus
and damage but deliberately provides no free lockdown.

### Fold Space

**Input:** Space / Xbox A<br>
**Cooldown:** 2.8 seconds

Phases 168 pixels in the movement direction, or aim direction when no movement
input is held. Nad ignores damage for 0.22 seconds and passes through enemy
bodies during the fold. Fold Space deals no damage and spends no Mana; it is a
positioning tool for lining up fields and escaping during resource recovery.

### Arcane Conduit

**Input:** R / Xbox Y<br>
**Cost:** 50 Mana<br>
**Cooldown:** 22 seconds

After a 0.64-second cast, Conduit strikes every enemy within 600 pixels. Nad is
invulnerable for 1.8 seconds from cast start. Unlocked targets take 34 base
health and 42 Resolve damage and receive a short 0.75-second Lock. Targets that
were already locked take 64 base health and 74 Resolve damage instead, receive
a longer Lock, and produce maximum impact feedback. Both versions add 8 health
damage and 5 Resolve damage per previous Focus stack, then add one Focus.

The best Conduit is not an opener. Prepare several targets with Mantle,
Anchors, and Cascade, then cash out before their Locks expire.

### Nad combat loop

1. Build Focus on priority enemies with Foresee.
2. Place Anchors where enemies must chase or where their paths overlap.
3. Charge Mantle into a group to interrupt attacks and establish a long Lock.
4. Extend that Lock with Mental Cascade while adding another Focus stack.
5. Collapse three Anchors when enemies occupy their fields.
6. Cast Arcane Conduit while several focused targets are still locked.
7. Use Fold Space to reposition while Mana regenerates.

## Fin: Shadow Artificer

Fin is an evasive assassin and Objects-class combat artificer. His ultimate
input changes his complete loadout instead of casting a conventional ultimate.
Every form has a different range, movement commitment, and preparation rhythm,
but all four interact with Pierce Marks.

Fin uses no Legendary items. His equipment is Dagger, Crossbow, Bow, Throwing
Dagger, Potions, Smoke Bombs, and the Unreal item Mutivarg's Rod.

### Resources and form switching

- **Health:** 245 maximum.
- **Resolve:** 175 maximum and regenerates at 5.5 per second.
- **Ward:** up to 52 temporary damage absorption. It is spent before health
  and slowly fades. Wave recovery grants 22 Ward.
- **Pierce Marks:** each enemy can hold up to five for 8 seconds. Fast attacks,
  traps, fields, and parries prepare Marks; Mind Pierce and Crossbow bolts
  consume them for damage or control.
- **Supplies:** three Throwing Daggers, three Potions, and two Smoke Bombs.
  Charges regenerate one at a time even while their form is stowed.
- **Crossbow reload:** continues while Fin uses any other form.

**Form input:** Tap R / Xbox Y to cycle Nightblade, Arbalest, Huntsman, then
Artificer. Hold for 0.24 seconds and select Up for Nightblade, Right for
Arbalest, Down for Huntsman, or Left for Artificer. Fin moves slowly while the
selector is open. Switching away from Nightblade ends Umbral Veil; reloads,
cooldowns, and supplies otherwise persist.

### Masterful Parry

**Input:** Space / Xbox A

Masterful Parry is shared by every form and covers a 156-degree frontal arc.
A hit during the first 0.18 seconds is perfect. Starting the parry while a
nearby enemy is visibly winding up reads that authoritative intent and keeps
the perfect response valid through the complete 0.32-second stance.

A perfect parry negates health damage, restores Resolve, cancels and locks the
attacker for 0.68 seconds, applies two Pierce Marks, and steps Fin behind the
attacker. A late frontal parry takes 22% health damage and applies one Mark.
Rear attacks bypass the parry.

### Nightblade

Nightblade moves 10% faster than Fin's base speed and rewards attacking from
behind or from concealment.

**Twin Daggers - Left mouse / Right trigger:** A buffered three-hit combo with
13 / 17 / 29 base damage. Normal hits apply one Pierce Mark. The finisher and
backstabs apply two. Backstabs deal 48% more damage; the first strike from
Umbral Veil gains a separate 42% multiplier and then reveals Fin.

**Mind Pierce - Hold/release Right mouse / Left trigger:** Charge for up to
0.82 seconds, then thrust through a narrow melee hitbox. It consumes up to five
Marks and gains 17% damage per Mark. A backstab gains another 32%. Three Marks
or a backstab also briefly locks the target.

**Umbral Veil - Q / Right bumper:** Conceals Fin for 3.4 seconds, grants a 16%
movement bonus and 0.26 seconds of initial invulnerability, and empowers the
next strike. Cooldown: 8 seconds.

**Shadow Lunge - E / Left bumper:** Phases 245 pixels through enemies in 0.16
seconds, damaging and marking each crossed target once. A concealed or rear
hit applies two Marks. Cooldown: 4.2 seconds.

### Arbalest

Arbalest is Fin's slowest form. Its Crossbow has real recoil and one loaded
round; firing starts a reload that can be left running while Fin changes form.

**Hand Crossbow - Left mouse / Right trigger:** Fires a fast heavy bolt,
consumes up to two Pierce Marks on impact, recoils Fin backward, and starts a
2.15-second reload.

**Breach Bolt - Hold/release Right mouse / Left trigger:** Brace and charge for
up to 1.18 seconds. The bolt pierces several targets, consumes up to five Marks
per target, and scales damage, Resolve damage, knockback, hit-stop, recoil, and
reload time with charge.

**Quick Crank - Q / Right bumper:** If unloaded, reduces the current reload to
0.38 seconds. If already loaded, grants a 3.2-second Steady Brace that reduces
the next shot's recoil to 34%. Cooldown: 5.8 seconds.

**Scatterbolt - E / Left bumper:** Fires three bolts in a shallow spread,
applies recoil, and starts a 2.75-second reload. Requires a loaded Crossbow.
Cooldown: 5.4 seconds.

### Huntsman

Huntsman keeps distance, routes pursuit through traps, and builds Marks without
committing to Arbalest's reload.

**Hunter Bow - Left mouse / Right trigger:** Fires a quick arrow that applies
one Mark. Arrow damage gains up to 36% based on distance traveled.

**Power Draw - Hold/release Right mouse / Left trigger:** Charge for up to 0.96
seconds. The faster arrow applies two Marks, pierces one extra target, and
briefly locks its target at high charge. It retains the long-range damage bonus.

**Shadow Bind - Q / Right bumper:** Places an 82-pixel collision trap 235
pixels along aim. The first enemy entering it is locked for 1.35 seconds and
gains two Marks. Fin can maintain two traps; each expires after 8 seconds.
Placement cooldown: 0.72 seconds.

**Throwing Dagger - E / Left bumper:** Throws a fast short-lived Dagger that
applies one Mark. Fin carries three; one regenerates every 3.4 seconds.

### Artificer

Artificer is a control and sustain toolkit centered on Mutivarg's Rod,
direction-selected Potions, and persistent alchemical smoke.

**Mutivarg's Rod - Left mouse / Right trigger:** Fires an object bolt that
applies one Mark. Its Resolve damage gains 20% of the target's current Resolve,
making it strongest before a break.

**Mutivarg Field - Hold/release Right mouse / Left trigger:** Charge for up to
1.02 seconds, then deploy a 120-205 pixel compression field at range. Enemies
gain one Mark on entry, are briefly locked, are slowed to 42-24% speed based on
charge, and take repeated health and Resolve pulses. Charge also increases
field duration and cooldown, up to 3.8 and 8 seconds.

**Potions - Q / Right bumper:** Uses one of three regenerating supplies. Hold a
movement direction while pressing the ability to select:

- Up: Mending Draught restores 54 health.
- Right: Quicksilver Tonic grants 22% movement speed for 5.2 seconds and
  restores 24 Resolve.
- Left: Shade Tonic grants 2.8 seconds of concealment and brief invulnerability.
- Down: Volatile Phial flies forward and creates a damaging alchemical field.

With no direction held, Fin chooses Mending below 68% health and Quicksilver
otherwise. One Potion regenerates every 11 seconds.

**Smoke Bomb - E / Left bumper:** Creates a 138-pixel smoke field for 4.4
seconds. Smoke conceals Fin, slows and marks enemies that enter, and deals low
periodic alchemical damage. Concealment interrupts enemy windups, prevents new
attack acquisition, reduces pursuit speed to 34%, and reduces the first
incoming hit before revealing Fin. Fin carries two Smoke Bombs; one regenerates
every 10 seconds.

### Fin combat loop

1. Use Huntsman arrows, traps, Throwing Daggers, or Artificer fields to prepare
  several Pierce Marks without overcommitting.
2. Read a telegraph with Masterful Parry to cancel intent, add two Marks, and
  appear behind the attacker.
3. Enter Nightblade under Veil and cash out with a backstabbed Mind Pierce, or
  draw Arbalest and spend Marks on a loaded Crossbow shot.
4. Stow Arbalest during reload and use another complete form instead of waiting.
5. Use Potions and Smoke Bombs deliberately; supplies regenerate, but spending
  every charge removes Fin's escape and sustain options.
6. Shape enemy routes with Shadow Bind and Mutivarg fields, then exploit the
  opening with the form whose commitment matches the situation.

## HUD reference

The upper-left panel shows the selected hero's health, Resolve, state, and
hero-specific resources. Kat also shows Ward over health and a Vitality bar;
Sniff shows ten discrete Blessing pips. Nad shows Mana, total active Mental
Focus, locked-enemy count, and three Anchor pips. Fin shows his current form,
total active Pierce Marks, Ward, concealment, Crossbow reload, traps, and tool
supplies. The bottom slots show keyboard
or Xbox glyphs automatically, cooldown progress, readiness, resource
requirements, and Sniff's health prices.

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
