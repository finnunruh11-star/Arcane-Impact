class_name SurvivorProgression
extends RefCounted


const ABILITY_SLOTS: Array[StringName] = [
	&"signature",
	&"ability_1",
	&"ability_2",
	&"evade",
	&"ultimate",
]
const TIER_LEVELS := [1, 5, 10, 15, 20]
const TIER_RANKS := [1, 5, 10, 15, 20]
const TIER_POWER := [0.58, 0.78, 1.0, 1.28, 1.62]
const TIER_COOLDOWN := [1.32, 1.15, 1.0, 0.88, 0.74]
const BASIC_ATTACK_POWER := [1.0, 1.20, 1.45, 1.75, 2.15]
const STAT_CATALOG: Array[Dictionary] = [
	{&"id": &"strength", &"title": "STRENGTH", &"description": "+12% Strength damage and +4% maximum Resolve"},
	{&"id": &"dexterity", &"title": "DEXTERITY", &"description": "+10% Dexterity damage and +3% movement speed"},
	{&"id": &"intelligence", &"title": "INTELLIGENCE", &"description": "+12% spell damage and +5% Arcane Essence"},
	{&"id": &"mana", &"title": "MANA", &"description": "+15% maximum Mana and +12% Mana regeneration"},
	{&"id": &"vitality", &"title": "VITALITY", &"description": "+10% maximum health and +1 health regenerated each second"},
	{&"id": &"luck", &"title": "LUCK", &"description": "+4% critical chance, +10% critical damage, +5% double-offer chance"},
]
static var HERO_ABILITIES: Array[Array] = [
	[
		_ability(&"signature", "AEGIS REBUKE", ["Brief guard; release a small shield strike", "Longer guard and heavier strike", "Full guard charge and crushing Shield Slam", "Perfect guards double-curse; Slam sends a shockwave", "Stored force erupts twice and grants Ward per enemy hit"]),
		_ability(&"ability_1", "LEECH CHOIR", ["Summon one short-lived Leech Mote", "Summon two Motes with stronger drain", "Command the full three-Mote choir", "A fourth Mote hunts cursed enemies", "Five Motes orbit Kat and share their healing as Ward"]),
		_ability(&"ability_2", "MOURNING HALO", ["A small aura drains nearby enemies", "The aura grows and applies Curse", "Full Mourning Halo duration and reach", "The Halo pulses outward and reinforces Ward", "Two concentric Halos drag enemies toward the reckoning"]),
		_ability(&"evade", "BASTION MARCH", ["A short armored shove", "March farther and damage enemies", "Full unstoppable Bastion March", "A second impact lands at the destination", "Chain a return March that leaves a damaging bulwark"]),
		_ability(&"ultimate", "BLACK COMMUNION", ["Consume Curse in a small radius", "Larger rite with improved healing", "Full arena-shaking Black Communion", "The rite leaves a draining sanctum", "Kat refuses death once and detonates every Curse twice"]),
	],
	[
		_ability(&"signature", "WAYWARD BOLT", ["Four violent lightning dashes with erratic turns", "Five faster segments bend toward nearby prey", "Full six-segment Wayward Bolt", "Eight rapid turns carve a longer chaotic route", "Ten blistering segments ricochet across the horde"]),
		_ability(&"ability_1", "TEMPEST COVENANT", ["Five-target chain storm; unlocks Voltaic Load", "Wider storm chains through seven targets", "Full Tempest Covenant chains through ten targets", "Fourteen targets erupt in secondary thunder bursts", "A 760-radius storm chains through every target in reach"]),
		_ability(&"ability_2", "CATACLYSM DISCHARGE", ["Consume every Load to scale a broad lightning burst", "Each Load expands a larger discharge", "Full crowd-wiping Load damage and radius scaling", "A vast discharge gains stronger tier power and recovery", "Maximum radius turns ten Load into an arena-clearing detonation"]),
		_ability(&"evade", "FLASHSTEP", ["Short invulnerable blink without damage", "Longer blink damages crossed enemies", "Full damaging and phasing Flashstep", "Long Flashstep detonates lightning on arrival", "Maximum distance and a stronger arrival detonation"]),
		_ability(&"ultimate", "WORLDSTORM", ["Unstable 600-radius storm chains through six targets", "Wider storm chains through ten targets", "Full arena-scale Worldstorm strikes every target", "A 1500-radius storm strikes each target twice", "A 2400-radius storm returns with a stronger aftershock"]),
	],
	[
		_ability(&"signature", "ELDRITCH MANTLE", ["Instant Mantle; tentacles execute enemies below 8% health", "Charged membrane; tentacles execute below 12%", "Full stable rift; tentacles execute below 18%", "Void prison tethers minds and executes below 24%", "Abyssal eye pulls prey and executes everything below 32%"]),
		_ability(&"ability_1", "TERRAIN ANCHOR", ["Plant one alien sigil and rupture it", "A second sigil grows watching eyes", "Full three-Anchor network opens linked void mouths", "Tentacles lash from each Anchor and bind crossings", "Five breaches join into living walls that repeatedly lock and crush prey"]),
		_ability(&"ability_2", "MENTAL CASCADE", ["A psychic whisper starts Arcane Recursion on hit", "The rift extends one lock and restores Mana over time", "Full Mental Cascade floods minds and fuels regeneration", "Tendrils spread a black web while Recursion runs", "One eldritch nervous system shares control and Mana recovery"]),
		_ability(&"evade", "FOLD SPACE", ["Slip through a hairline crack in space", "The crack briefly phases through bodies", "Full invulnerable Fold Space crosses the void", "Aim at an Anchor to emerge from its watching rift", "Departure and arrival become hungry maws that freeze prey and reopen on locked deaths"]),
		_ability(&"ultimate", "ARCANE CONDUIT", ["A distant presence briefly interrupts nearby minds", "Its shadow widens and deepens their focus", "Full Arcane Conduit manifests the watching void", "A cosmic eye suspends locked targets after the blast", "Transform into an eldritch being for 10 seconds; 90-second cooldown"]),
	],
	[
		_ability(&"signature", "FORM SIGNATURES", ["Quick, uncharged signature tools", "Partial charge and improved precision", "Full signatures for all four forms", "Charged signatures echo the previous form", "Every signature invokes all four forms in sequence"]),
		_ability(&"ability_1", "UTILITY BELT", ["Short Veil, one trap, or one basic potion", "Improved utility and two supply charges", "Full form-specific utility kit", "Unlock empowered brews and reinforced traps", "Carry five supplies; using one echoes a different form's utility"]),
		_ability(&"ability_2", "TACTICAL TOOLS", ["One limited offensive tool", "Two tools with faster recharge", "Full Lunge, Scatterbolt, Dagger, and Smoke kit", "Tools leave Pierce Marks and chain into form swaps", "Deploy two tools at once and replenish one on every marked takedown"]),
		_ability(&"evade", "UMBRAL STEP", ["Short evasive speed burst", "Longer Step with body phasing", "Full Umbral Step", "Crossed enemies gain Pierce Marks and Weakness", "A second Step can retrace the route and detonates every crossed Mark"]),
		_ability(&"ultimate", "MASTER OF FORMS", ["Cycle between Nightblade and Arbalest", "Unlock Huntsman and faster switching", "Full four-form control", "Swapping repeats the previous form's basic attack", "All forms overlap briefly, firing their basic attacks together"]),
	],
]

var _hero_index := 0
var _run_level := 1
var _ranks: Dictionary = {}


static func _ability(slot: StringName, title: String, tiers: Array[String]) -> Dictionary:
	return {&"id": slot, &"title": title, &"tiers": tiers}


func configure(hero_index: int) -> void:
	_hero_index = clampi(hero_index, 0, HERO_ABILITIES.size() - 1)
	_run_level = 1
	_ranks.clear()
	_ranks[&"evade"] = 1


func set_run_level(level: int) -> void:
	_run_level = maxi(1, level)


func get_run_level() -> int:
	return _run_level


func get_tier() -> int:
	return tier_for_level(_run_level)


func get_basic_attack_tier() -> int:
	return tier_for_level(_run_level)


func get_basic_attack_power_multiplier() -> float:
	return float(BASIC_ATTACK_POWER[get_basic_attack_tier() - 1])


func get_ability_tier(slot: StringName) -> int:
	return tier_for_rank(get_rank(slot))


static func tier_for_level(level: int) -> int:
	if level >= TIER_LEVELS[4]:
		return 5
	if level >= TIER_LEVELS[3]:
		return 4
	if level >= TIER_LEVELS[2]:
		return 3
	if level >= TIER_LEVELS[1]:
		return 2
	return 1


static func tier_for_rank(rank: int) -> int:
	if rank >= TIER_RANKS[4]:
		return 5
	if rank >= TIER_RANKS[3]:
		return 4
	if rank >= TIER_RANKS[2]:
		return 3
	if rank >= TIER_RANKS[1]:
		return 2
	return 1


func get_rank(upgrade_id: StringName) -> int:
	return int(_ranks.get(upgrade_id, 0))


func is_unlocked(slot: StringName) -> bool:
	return slot in ABILITY_SLOTS and get_rank(slot) > 0


func get_ability_title(slot: StringName) -> String:
	for ability_data: Dictionary in HERO_ABILITIES[_hero_index]:
		if ability_data[&"id"] == slot:
			return String(ability_data[&"title"])
	return String(slot).to_upper()


func apply_pick(upgrade_id: StringName, amount := 1) -> Dictionary:
	_ranks[upgrade_id] = get_rank(upgrade_id) + maxi(1, amount)
	return get_state(upgrade_id)


func get_state(upgrade_id: StringName) -> Dictionary:
	return {
		&"id": upgrade_id,
		&"kind": &"ability" if upgrade_id in ABILITY_SLOTS else &"stat",
		&"rank": get_rank(upgrade_id),
		&"tier": get_ability_tier(upgrade_id) if upgrade_id in ABILITY_SLOTS else 0,
	}


func get_ability_power_multiplier(slot: StringName) -> float:
	if not is_unlocked(slot):
		return 0.0
	var tier_index := get_ability_tier(slot) - 1
	return float(TIER_POWER[tier_index]) * (1.0 + 0.12 * float(get_rank(slot) - 1))


func get_ability_cooldown_multiplier(slot: StringName) -> float:
	if not is_unlocked(slot):
		return INF
	var tier_index := get_ability_tier(slot) - 1
	return maxf(0.42, float(TIER_COOLDOWN[tier_index]) * pow(0.94, float(get_rank(slot) - 1)))


func _set_ability_option_preview(option: Dictionary, amount: int) -> void:
	var rank := int(option[&"rank"])
	var preview_rank := rank + maxi(1, amount)
	var current_tier := get_ability_tier(option[&"id"] as StringName)
	var preview_tier := tier_for_rank(preview_rank)
	var tiers := option[&"tiers"] as Array
	var prefix := "RANK %d > %d" % [rank, preview_rank]
	if rank == 0:
		prefix = "UNLOCK RANK %d" % preview_rank
	elif preview_tier > current_tier:
		prefix = "EVOLVE TO TIER %d"
		prefix = prefix % preview_tier
	option[&"tier"] = preview_tier
	option[&"tier_description"] = String(tiers[preview_tier - 1])
	option[&"description"] = "%s  -  %s" % [prefix, option[&"tier_description"]]


func get_double_upgrade_chance() -> float:
	return minf(1.0, 0.15 + 0.05 * float(get_rank(&"luck")))


func roll_options(rng: RandomNumberGenerator, count := 6) -> Array[Dictionary]:
	var stat_pool: Array[Dictionary] = []
	for stat: Dictionary in STAT_CATALOG:
		var option := stat.duplicate(true)
		option[&"kind"] = &"stat"
		option[&"rank"] = get_rank(option[&"id"] as StringName)
		stat_pool.append(option)
	var ability_pool: Array[Dictionary] = []
	for ability_data: Dictionary in HERO_ABILITIES[_hero_index]:
		var slot := ability_data[&"id"] as StringName
		var rank := get_rank(slot)
		var tiers := ability_data[&"tiers"] as Array
		var option := {
			&"id": slot,
			&"kind": &"ability",
			&"title": ability_data[&"title"],
			&"rank": rank,
			&"tiers": tiers,
		}
		_set_ability_option_preview(option, 1)
		ability_pool.append(option)
	var option_count := mini(maxi(0, count), stat_pool.size() + ability_pool.size())
	var options: Array[Dictionary] = []
	if option_count == 1:
		var combined_pool := stat_pool + ability_pool
		options.append(combined_pool[rng.randi_range(0, combined_pool.size() - 1)])
		return options
	var ability_count := mini(ability_pool.size(), maxi(1, floori(float(option_count) * 0.5)))
	var stat_count := mini(stat_pool.size(), maxi(1, option_count - ability_count))
	for _index: int in ability_count:
		options.append(ability_pool.pop_at(rng.randi_range(0, ability_pool.size() - 1)))
	for _index: int in stat_count:
		options.append(stat_pool.pop_at(rng.randi_range(0, stat_pool.size() - 1)))
	var remainder_pool := stat_pool + ability_pool
	while options.size() < option_count:
		options.append(remainder_pool.pop_at(rng.randi_range(0, remainder_pool.size() - 1)))
	for index: int in range(options.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var swap_option: Dictionary = options[index]
		options[index] = options[swap_index]
		options[swap_index] = swap_option
	var double_chance := get_double_upgrade_chance()
	for option: Dictionary in options:
		var amount := 2 if rng.randf() < double_chance else 1
		option[&"amount"] = amount
		if option[&"kind"] == &"ability":
			_set_ability_option_preview(option, amount)
		if amount < 2:
			continue
		option[&"title"] = "DOUBLE %s" % String(option[&"title"])
		if option[&"kind"] == &"ability":
			option[&"description"] = "DOUBLE: %s" % String(option[&"description"])
		else:
			option[&"description"] = "DOUBLE: %s" % String(option[&"description"])
	return options


func get_summary() -> String:
	var parts: PackedStringArray = []
	for upgrade_id: Variant in _ranks:
		parts.append("%s %d" % [String(upgrade_id).to_upper(), int(_ranks[upgrade_id])])
	return "  /  ".join(parts)