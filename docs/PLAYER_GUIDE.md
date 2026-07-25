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
button, Xbox A, or Xbox X. Each hero card also has a `TRAIN WITH` button that
opens the Shattered Reliquary training lab with that hero.

## Training mode

Training mode contains five stationary test dummies. They support the same
damage, Resolve, curse, Mental Focus, control, Pierce Mark, pull, and chain
targeting interactions as live enemies, then reset automatically after defeat.

The top-right panel can set level 1, 5, 10, 15, or 20 instantly. The + and -
buttons, or Page Up and Page Down, adjust one level at a time. Changing level
sets the basic attack and all five active abilities to that rank and tier, so
the complete kit is available immediately. Press F or `RESET` to restore every
dummy, and Escape or `ROSTER` to leave training.

## Goal and encounter flow

Deploying a hero begins a ten-minute run in the Shattered Reliquary. The arena
is a scrolling 2560-by-1560 battlefield with solid ruined structures. The camera
follows the hero and clamps at the world edges. Enemies and heroes collide with
the ruins; enemy pursuit steers around blocked approaches.

Every hero starts with their manually triggered basic attack and a rank-1
defensive escape. Aim with the mouse or right stick and press the attack input
to fire or swing; idle heroes do not attack. Movement remains under direct
control. Other active skills become usable after they are selected during a
level-up.

Enemies enter continuously from clear positions along all four arena edges.
The ritual opens with one opponent and advances through six encounter phases.
Each phase has both a body cap and a threat budget, so durable, ranged, and
support roles consume more of the encounter than a basic Raider. The target
responds to kills from the last 30 seconds: clearing quickly can add pressure
and shorten the next refill delay, but only up to the current phase's hard cap.
Slower clearing never causes the director to spawn past the base target.

| Phase | Starts | Base / hard cap | Ranged / support cap | Encounter intent |
| --- | ---: | ---: | ---: | --- |
| Duel | 00:00 | 1 / 2 | 0 / 0 | One readable melee opponent; a fast clear can add one more |
| Skirmish | 00:55 | 2 / 3 | 1 / 0 | Introduces Bulwarks and the first Arcanist |
| Formation | 02:10 | 3 / 5 | 1 / 0 | Adds Deadeyes while preserving a single ranged slot |
| Pressure | 04:00 | 5 / 8 | 2 / 1 | Unlocks Warcallers and mixed-role formations |
| Onslaught | 06:00 | 7 / 12 | 3 / 1 | Sustained pressure with stricter threat accounting |
| Climax | 08:00 | 10 / 18 | 4 / 2 | Full roster, still bounded by role and threat budgets |

Enemy health, Resolve, and damage rise on smooth linear-plus-curve scaling
throughout the ritual; movement speed gains are capped at 16% so late enemies
remain readable. Duplicate-role weighting discourages repetitive formations,
and the director unlocks roles gradually instead of cycling through all six at
the start. Enemy profiles are:

- **Ashen Raider:** balanced melee pressure with a short rectangular swing.
- **Iron Bulwark:** the slowest and toughest enemy; winds up a large circular
  ground slam.
- **Bloodrunner:** a fragile rushdown attacker that marks a long lane before
  charging through it.
- **Bone Arcanist:** approaches to a medium engagement band, launches a slow
  homing blue orb, then relocates before its next cast.
- **Warcaller:** a support enemy whose green pulse heals and empowers nearby
  enemies instead of damaging the hero.
- **Grave Deadeye:** approaches to a longer engagement band, locks a narrow aim
  line, fires a fast straight projectile, then changes position.

Ranged enemies claim different orbital positions, repel other ranged enemies
before their sprites overlap, and move during part of their recovery instead of
acting as stationary turrets. Their simultaneous population is also limited by
the phase table above.

Red lanes and ground shapes show damaging melee, charge, slam, and projectile
paths. An amber sweep around the attacker shows windup progress; blue or purple
charge effects and endpoint reticles identify the incoming projectile. Green
circles are beneficial enemy support and do not damage the hero. Enemies use
run, anticipation, attack, recoil, stagger, and collapse poses around their
authored sprite animations. The framed indicator above each enemy shows health
in red, Resolve in cyan, and a small role-colored diamond.
Defeated enemies grant Arcane Essence immediately; no pickup or retrieval is
required. The first level needs 3 Essence, and each later threshold adds only
2 more: 3, 5, 7, 9, and so on. Filling the Essence bar
pauses combat and presents six unique choices: three random stats and three
random abilities from the selected hero. Keyboard choices use 1 through 6.
On controller, move focus with the D-pad or left stick and press Xbox A to
confirm and select the focused boon.

Every hero's defensive escape begins at rank 1. The first pick of any other
active ability unlocks its rank 1. Further picks add 12% power per rank, improve
that skill's cooldown, and move only that skill toward its next behavior tier:

| Skill rank | Active tier | Role |
| --- | --- | --- |
| 1-4 | Tier 1 | Small or limited opening version |
| 5-9 | Tier 2 | Improved reach, duration, or utility |
| 10-14 | Tier 3 | Original full-strength skill |
| 15-19 | Tier 4 | New chaining, control, sustain, or form mechanic |
| 20+ | Tier 5 | Identity-defining capstone behavior |

The basic attack is independent. Run level raises its damage and behavior tier
even when the level-up boon is spent on a stat or active ability:

| Run level | Basic tier | Power multiplier |
| --- | --- | ---: |
| 1-4 | Tier 1 | 1.00 |
| 5-9 | Tier 2 | 1.20 |
| 10-14 | Tier 3 | 1.45 |
| 15-19 | Tier 4 | 1.75 |
| 20+ | Tier 5 | 2.15 |

Each hero's basic attack also changes mechanically:

- **Kat:** swings become wider and recover faster; tier 4 adds a ranged combo
  finisher wave, and tier 5 enlarges it and applies two Curse stacks.
- **Sniff:** darts start and recover faster. Guaranteed secondary chains grow
  from one at tier 2 to two, three, and five at tiers 3-5; tier-5 forks burst.
- **Nad:** Foresee grows wider and longer and probes 1, 1, 2, 3, then 5 minds.
  Tiers 4-5 apply two Focus at once.
- **Fin:** every form attacks faster. Tier 4 echoes the previous form's basic;
  tier 5 invokes the other three forms after every primary attack.

The six repeatable attributes are:

- **Strength:** adds 12% Strength attack damage and 4% maximum Resolve.
- **Dexterity:** adds 10% Dexterity attack damage and 3% movement speed.
- **Intelligence:** adds 12% spell damage and 5% Arcane Essence gain.
- **Mana:** adds 15% maximum Mana and 12% Mana regeneration.
- **Vitality:** adds 10% maximum health and 1 health regeneration per second.
  Every hero already regenerates 1.5 health per second before Vitality ranks.
- **Luck:** adds 4% critical chance, 10% critical damage, and 5 percentage
  points to the double-upgrade chance.

Swords, shields, and other heavy weapons scale with Strength. Bows and daggers
scale with Dexterity. Spells, summons, auras, lightning, mental attacks, and
magical objects scale with Intelligence. Critical hits begin at 150% damage;
Luck increases both their chance and multiplier.

Every offered boon independently has a 15% base chance to display as `DOUBLE`.
A double boon grants two stat or ability ranks when selected. Luck raises this
chance, and double ability picks can unlock rank 2 immediately.

Upgrades stack for the duration of the run. Combat HUD slots show `LOCKED`
before the first pick and `Tn Rm` afterward; the escape starts at `T1 R1`.
The detailed ability values below describe active tier 3, which intentionally
preserves the original full hero skills. Lower tiers are constrained versions;
tiers 4 and 5 apply the behavior written on that skill's level-up cards.

Survive until 10:00 to complete the
ritual. Defeat opens a summary with retry and roster actions. Escape or the
controller Menu button returns to the roster at any time.

## Shared combat mechanics

### Movement and targeting

Move with WASD or the left stick. The run controller tracks the closest living
enemy for spawning and encounter logic, but it does not attack or aim for the
player. Aim with the mouse or right stick. Directional movement abilities prefer
held movement input when available and otherwise use the current aim direction.

### Health

Health reaches zero when the hero is defeated. Kat has 340 maximum health,
Sniff and Fin have 245, and Nad has 220. Sniff's Voltaic overload and spell
feedback are real self-damage and can defeat him.

### Resolve and stagger

Resolve is the cyan control-resistance bar. Attacks can deal health damage and
Resolve damage independently. When Resolve reaches zero, the target is
staggered and its attack is interrupted. Resolve partially refills on a break
and regenerates over time.

Kat has 210 maximum Resolve and regenerates 5 per second. Sniff has 138 and
regenerates 6.5 per second. Nad has 160 and regenerates 5.8 per second. Fin has
175 and regenerates 5.5 per second. Strength increases these maximum values.
Enemy variants have different Resolve totals.

### Mana

All four heroes have Mana, and the Mana attribute increases both capacity and
regeneration. Kat's physical weapons and Fin's physical or alchemical tools do
not spend Mana. Kat's supernatural rites, Sniff's lightning, Nad's mental
spells, and Fin's shadow or Rod magic do. Each combat HUD shows current and
maximum Mana plus action costs.

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
- **Mana:** 120 maximum and regenerates 10 per second before sustained drains.
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
**Activation cooldown:** 9.5 seconds
**Drain:** 16 Mana per second while active

Toggles the full tier-appropriate Leech Choir on or off. At tier 3 it summons
three autonomous Leech Motes. Motes orbit Kat,
seek living enemies within 460 pixels, and strongly prefer cursed targets.
Each strike deals 9 damage, then the mote returns to orbit. A successful mote
strike heals Kat for 58% of actual damage and grants 6 Vitality.

Press the input again to dismiss the Choir even while the activation cooldown
is running. The drain is charged once by Kat, not once per mote. The Choir
automatically dismisses itself when Mana reaches zero.

### Mourning Halo

**Input:** E / Left bumper  
**Activation cooldown:** 11.5 seconds
**Drain:** 22 Mana per second while active

Toggles a persistent mobile 188-pixel aura around Kat. It pulses every
0.58 seconds, dealing 6 health and 7 Resolve damage and applying one Curse
stack for 4.5 seconds. Halo damage heals Kat for 38% of total damage dealt per
pulse and grants 2.4 Vitality for each enemy hit.

Press the input again to remove the Halo even during cooldown. It has no fixed
duration and shuts off automatically at zero Mana.

Kat's current Mana regeneration offsets the combined raw drain before Mana is
removed. The HUD reports this net balance. Choir is neutral at 16 regeneration
per second, Halo at 22, and both can remain active indefinitely once total Mana
regeneration reaches their combined 38 per second.

### Bastion March

**Input:** Space / Xbox A
**Cooldown:** 3.6 seconds

Kat surges 650 pixels per second in the movement direction, or aim direction
when no movement input is held. March carries the frontal guard, damages each
crossed enemy once, applies one Curse stack, deals heavy Resolve damage and
knockback, heals for 10% of actual damage, and builds Vitality.

### Black Communion

**Input:** R / Xbox Y  
**Requirement:** 100 Vitality and 55 Mana

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

## Sniff: Storm Catastrophist

Sniff is a fast ranged storm mage built around enormous, chaining lightning
spells. His grand spells cover huge areas and can feed their power back into
him, so every cast balances crowd destruction against Mana and lethal risk.

### Resources

- **Health:** 245 maximum. Overload and spell backfires can reduce it to zero.
- **Resolve:** 138 maximum.
- **Mana:** 130 maximum and regenerates 8.5 per second. Each grand spell costs
  more than half of base Mana. Stored charges do not waive Mana or Load costs.
- **Ability charges:** Wayward Bolt, Tempest Covenant, Cataclysm Discharge,
  Flashstep, and Worldstorm each store up to two charges. Recharges occur one
  at a time. If one charge is ready, the timer continues filling the second;
  spending the ready charge does not reset that in-progress timer.
- **Voltaic Load:** 0-10 stacks, unlocked by learning Tempest Covenant. A
  Wayward Bolt, Tempest Covenant, Cataclysm Discharge, or Worldstorm that damages
  at least one enemy grants exactly one Load, regardless of target count.
  Lightning Dart and Flashstep never grant Load.
- **Load bonuses:** each stack grants 2.5% movement speed and 5.5% spell power.
- **Overload:** at seven Load, Sniff takes storm feedback every 0.8 seconds.
  The first tick deals 2 damage; each stack above seven adds 1.25 damage.
- **Backfire:** every grand spell has a feedback chance that rises with its
  Load snapshot, up to 58%. Backfire deals real, potentially lethal self-damage.

### Lightning Dart

**Input:** Left mouse / Right trigger
**Cost:** 6 Mana

Fires a fast collision-backed projectile. A direct hit has a 30% chain chance
at tier 1; tier 2 and above always chain when another
target is in range. At full tier 3, the bolt can jump through two additional
targets within 320 pixels. Lightning Dart preserves Sniff's quick ranged
pressure but never generates Voltaic Load.

The direct hit starts at 18 damage and gains 8.5% damage per Load snapshot.
Each chain step deals 72% of the previous depth's damage.

### Wayward Bolt

**Input:** Right mouse / Left trigger<br>
**Cost:** 72 Mana<br>
**Cooldown:** 8 seconds

Sniff becomes a phasing lightning bolt and tears through six rapid dash segments
at full tier 3. After every segment, the heading violently turns by roughly
41-112 degrees and may bend partway toward a random enemy within 620 pixels.
The route is deliberately difficult to predict or steer after its first burst.
Sniff is invulnerable during the route and each crossed enemy is hit once.

Each hit deals 46 base health and 54 base Resolve damage, plus 3.5 health and
2.5 Resolve damage per snapshotted Load. The complete dash grants exactly one
Load if it hits anything. Its base backfire chance is 11%, plus 2.5 percentage
points per snapshotted Load. Tiers 1-5 use 4, 5, 6, 8, and 10 segments and gain
speed at every tier.

### Tempest Covenant

**Input:** Q / Right bumper<br>
**Cooldown:** 12 seconds<br>
**Cost:** 76 Mana

Learning this ability unlocks Voltaic Load. After a 0.82-second cast, it creates
a 520-pixel storm 430 pixels along aim and chains through up to 10 enemies.
The first target takes 58 base health and 48 base Resolve damage, plus Load
scaling; each later link retains 91% of the previous link's damage.

A successful Covenant grants one Load. Its base backfire chance is 10%, plus
2.5 percentage points per snapshotted Load.

### Cataclysm Discharge

**Input:** E / Left bumper<br>
**Cooldown:** 14 seconds<br>
**Cost:** 84 Mana and at least one Voltaic Load

Consumes every current Load and snapshots it for an expanding detonation around
Sniff after a 0.82-second cast. At full tier 3, its radius is 390 pixels plus
52 per Load. It deals 42 base health damage plus 14 per Load and 55 base Resolve
damage plus 9 per Load, reaching a 910-pixel radius and 182 base health damage
at 10 Load before spell-power scaling.

If Discharge damages at least one target, it seeds the next cycle with one new
Load. Its backfire chance rises faster than the other spells as stored power
increases, and its feedback damage also scales sharply with the consumed Load.

### Flashstep

**Input:** Space / Xbox A  
**Cooldown:** 0.75 seconds
**Cost:** 16 Mana

Phases 158 pixels in the movement or aim direction. Sniff is invulnerable for
0.23 seconds, passes through enemy bodies, and damages every crossed enemy once.
Flashstep damage increases slightly with current Load but does not spend or
build it.

### Worldstorm

**Input:** R / Xbox Y<br>
**Cooldown:** 28 seconds<br>
**Cost:** 96 Mana

After a 1.1-second cast, strikes every living enemy within 1050 pixels and
chains visible lightning through the entire group. It deals 105 base health
damage plus 8 per snapshotted Load and 112 base Resolve damage plus 7 per Load,
with maximum hit-stop, shake, flash, and rumble.

Worldstorm does not consume existing Load and grants one more if it hits. Its
base backfire chance is 14%, plus 2.5 percentage points per snapshotted Load,
making a fully loaded cast both devastating and dangerous.

### Sniff combat loop

1. Use Lightning Darts for cheap pressure while Mana recovers; they do not add Load.
2. Land Tempest Covenant to unlock and begin the Voltaic Load cycle.
3. Spend Wayward Bolt to ricochet through a packed formation, then use its
   second stored charge for an escape or another unpredictable pass.
4. Alternate successful grand spells to gain speed and power one stack at a time.
5. Decide whether to Discharge before seven Load or accept overload damage for
  a larger crowd wipe.
6. Use Worldstorm on a spread-out horde, but respect its rising feedback chance.
7. Flashstep through attacks without changing the Load prepared for Discharge.

## Nad: Eldritch Tactician

Nad is a ranged control and zone mage. Her direct damage is modest without
preparation; she becomes dangerous by placing enemies under Mental Focus,
locking them out of actions, extending that control, and collapsing prepared
targets with Arcane Conduit.

### Resources and control

- **Health:** 220 maximum.
- **Resolve:** 160 maximum.
- **Mana:** 0-120 with 5 passive regeneration per second. The Mana
  attribute increases capacity and regeneration. Every spell spends Mana,
  including Fold Space.
- **Mental Focus:** enemies can hold up to five stacks. Focus lasts until its
  current duration expires. A target under Eldritch Lock takes 12% more health
  damage per Focus stack, up to a 60% multiplier. Focus without an active Lock
  does not grant this multiplier.
- **Eldritch Lock:** cancels the target's current attack, freezes movement, and
  exposes its Focus vulnerability. Mental Cascade extends only an existing
  Lock; it does not create one on an uncontrolled target.
- **Arcane Recursion:** a successful Mental Cascade restores 10 Mana immediately
  and grants 11 additional Mana regeneration per second for 5 seconds. A
  successful Foresee refunds 2 Mana; other spells do not directly refund Mana.

Nad's visuals and mechanics become progressively more eldritch as each skill's
own rank raises its tier. Tier 3 preserves the original complete skill; tier 4
adds void prisons, webs, tethers, and cosmic eyes; tier 5 adds tentacle breaches,
living walls, shared mental systems, hungry rifts, and an abyssal transformation.

### Foresee

**Input:** Left mouse / Right trigger<br>
**Cost:** 5 Mana

Projects a narrow 242-pixel collision probe. The nearest enemy in the probe
gains one Mental Focus for 7 seconds and is locked for 0.24 seconds plus 0.05
seconds per Focus stack it already held. Foresee deals 7 base health damage
plus 1 per resulting Focus stack and 17 base Resolve damage plus 2 per stack.

Use repeated Foresee hits to prepare one priority target while conserving Mana.
A successful hit refunds 2 Mana. Primary input pressed during another action
is buffered for 0.12 seconds.

### Eldritch Mantle

**Input:** Hold and release Right mouse / Left trigger<br>
**Cost:** 28 Mana

Charge for up to 1.05 seconds while moving slowly. The remote field grows from
135 to 230 pixels in radius and moves from 185 to 265 pixels along Nad's aim.
Releasing it gives every enemy inside two Focus for 8 seconds and locks them
for 1.6 to 3.8 seconds based on charge. Health damage grows from 11 to 22;
Resolve damage grows from 26 to 54.

Every Mantle tier also summons execution tentacles after the field resolves.
They kill enemies below 8%, 12%, 18%, 24%, or 32% maximum health at tiers 1-5.
The execute reach grows with the field, and tier 5 pulls prey toward its abyssal
eye before the tentacles check their health.

The visible circle is the gameplay collision radius. Use Mantle to interrupt
multiple windups or establish the long Lock window that Cascade can extend.

### Terrain Anchor

**Input:** Q / Right bumper<br>
**Cost:** 15 Mana per Anchor<br>
**Placement cooldown:** 0.75 seconds<br>
**Collapse cooldown:** 8 seconds

Places a persistent 132-pixel field 265 pixels along the aim direction. Each
Anchor lasts 12 seconds and slows enemies inside it to 52% movement speed. Nad
can maintain three. Once all three exist, the next Anchor command collapses
the complete lattice instead of spending Mana on a fourth.

Each collapsing field deals 15 health and 34 Resolve damage, applies one Focus
for 7 seconds, and locks targets for 0.65 seconds. Overlapping fields each have
their own authoritative circle, so deliberate overlap creates a stronger but
more concentrated collapse.

### Mental Cascade

**Input:** E / Left bumper<br>
**Cost:** 22 Mana<br>
**Cooldown:** 6.5 seconds

Projects a broad 324-pixel collision cone. Every target gains one Focus for 8
seconds and takes 14 health damage plus 2.5 per Focus stack it held before the
hit. If a target was already locked, Cascade extends that Lock by 0.55 seconds
plus 0.1 per previous Focus stack, up to 6 seconds remaining. Hitting at least
one enemy restores 10 Mana immediately and starts Arcane Recursion: +11 Mana
regeneration per second for 5 seconds on top of Nad's passive regeneration.

Cast Cascade after Mantle or an Anchor collapse. Casting it first builds Focus
and damage but deliberately provides no free lockdown.

### Fold Space

**Input:** Space / Xbox A<br>
**Cooldown:** 2.8 seconds<br>
**Cost:** 10 Mana

Phases 168 pixels in the movement direction, or aim direction when no movement
input is held. Nad ignores damage for 0.22 seconds and passes through enemy
bodies during the fold. Fold Space deals no damage; it is a positioning tool
for lining up fields while Arcane Recursion rebuilds Mana.

### Arcane Conduit

**Input:** R / Xbox Y<br>
**Cost:** 48 Mana<br>
**Cooldown:** 22 seconds

After a 0.64-second cast, Conduit strikes every enemy within 600 pixels. Nad is
invulnerable for 1.8 seconds from cast start. Unlocked targets take 22 base
health and 42 Resolve damage and receive a short 0.75-second Lock. Targets that
were already locked take 44 base health and 74 Resolve damage instead, receive
a longer Lock, and produce maximum impact feedback. Both versions add 5 health
damage and 5 Resolve damage per previous Focus stack, then add one Focus.

The best Conduit is not an opener. Prepare several targets with Mantle,
Anchors, and Cascade, then cash out before their Locks expire.

At Arcane Conduit rank 20, tier 5 replaces the blast with **Eldritch Form**.
Nad transforms for 10 seconds and the ultimate enters a 90-second cooldown.
During the form, spells cost no Mana, incoming health and Resolve damage are
reduced by 55%, and a 300-pixel pulse fires every 0.75 seconds. Each pulse adds
Focus, briefly locks nearby enemies, deals damage, and executes targets below
32% health with tentacles. The HUD replaces the cooldown text with the remaining
form duration until Nad returns to normal.

### Nad combat loop

1. Build Focus on priority enemies with Foresee.
2. Place Anchors where enemies must chase or where their paths overlap.
3. Charge Mantle into a group to interrupt attacks and establish a long Lock.
4. Land Mental Cascade to extend that Lock and trigger five seconds of Arcane
  Recursion.
5. Collapse three Anchors when enemies occupy their fields.
6. Cast Arcane Conduit while several focused targets are still locked.
7. Spend the Recursion window on another setup spell or Fold Space, using
  Foresee hit refunds to bridge the gaps between larger casts.

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
- **Mana:** 100 maximum and regenerates 10 per second. Physical weapons,
  traps, Potions, and Smoke Bombs are free; shadow magic and Mutivarg's Rod
  spend Mana.
- **Ward:** up to 52 temporary damage absorption. It is spent before health
  and slowly fades.
- **Pierce Marks:** each enemy can hold up to five for 8 seconds. Fast attacks,
  traps, and fields prepare Marks; Mind Pierce and Crossbow bolts
  consume them for damage or control.
- **Supplies:** three Throwing Daggers, three Potions, and two Smoke Bombs.
  Charges regenerate one at a time even while their form is stowed.
- **Crossbow reload:** continues while Fin uses any other form.

**Form input:** Tap R / Xbox Y to cycle Nightblade, Arbalest, Huntsman, then
Artificer. Hold for 0.24 seconds and select Up for Nightblade, Right for
Arbalest, Down for Huntsman, or Left for Artificer. Fin moves slowly while the
selector is open. Switching away from Nightblade ends Umbral Veil; reloads,
cooldowns, and supplies otherwise persist.

### Umbral Step

**Input:** Space / Xbox A
**Cooldown:** 4 seconds
**Cost:** 18 Mana

Umbral Step is Fin's shared defensive escape in every form. For 1.25 seconds,
Fin becomes unseen, moves at 190% of base speed under full directional control,
and passes through enemy bodies. Activation includes 0.16 seconds of protection
so Fin can break away from immediate contact. Enemies lose active windups,
cannot acquire new attacks, and pursue much more slowly while Fin is unseen.

Umbral Step disables Fin's attack sensor for the entire escape. It deals no
damage, applies no Pierce Marks or control, and cannot be used as an offensive
traversal attack.

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

**Umbral Veil - Q / Right bumper:** Costs 20 Mana, conceals Fin for 3.4 seconds, grants a 16%
movement bonus and 0.26 seconds of initial invulnerability, and empowers the
next strike. Cooldown: 8 seconds.

**Shadow Lunge - E / Left bumper:** Costs 16 Mana and phases 245 pixels through enemies in 0.16
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

**Mutivarg's Rod - Left mouse / Right trigger:** Spends 6 Mana and fires an object bolt that
applies one Mark. Its Resolve damage gains 20% of the target's current Resolve,
making it strongest before a break.

**Mutivarg Field - Hold/release Right mouse / Left trigger:** Spends 26 Mana, then charges for up to
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
2. Use Umbral Step to become unseen and run through enemies when pressure closes
  off a safe route; it is strictly an escape and creates no Marks.
3. Enter Nightblade under Veil and cash out with a backstabbed Mind Pierce, or
  draw Arbalest and spend Marks on a loaded Crossbow shot.
4. Stow Arbalest during reload and use another complete form instead of waiting.
5. Use Potions and Smoke Bombs deliberately; supplies regenerate, but spending
  every charge removes Fin's escape and sustain options.
6. Shape enemy routes with Shadow Bind and Mutivarg fields, then exploit the
  opening with the form whose commitment matches the situation.

## HUD reference

The upper-left panel shows the selected hero's health, Mana, Resolve, state,
and hero-specific resources. Kat also shows Ward over health, a Vitality bar,
and active Choir/Halo drains; Sniff shows ten Voltaic Load pips, flags the
seven-stack overload threshold, and shows each non-basic ability's stored
charges while the next charge refills. Nad shows
total active Mental Focus, locked-enemy count, and tier-dependent Anchor pips.
Fin shows his current form, total active Pierce Marks, Ward, concealment,
Crossbow reload, traps, and tool supplies. The bottom slots show keyboard
or Xbox glyphs automatically, cooldown progress, readiness, resource
requirements, and Sniff's high Mana prices.

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
