//Warlock Include
#include "MagicCommon.as";
#include "AttributeCommon.as";

const int positions_save_time_in_seconds = 15;
const u8 old_positions_save_threshold = 1;

namespace WarlockParams
{
	enum Aim 
		{
			not_aiming = 0,
			charging,
			cast_1,
			cast_2,
			cast_3,
			extra_ready,
		}

	const ::f32 shoot_max_vel = 8.0f;
	const ::f32 MAX_ATTACK_DIST = 500.0f;
	const ::s32 MAX_MANA = 50;
	const ::s32 MANA_REGEN = 0;
	const ::f32 HEALTH_COST_PER_1_MANA = 0.04f; // 0.2f is 1 HP
	const ::f32 MANA_PER_1_DAMAGE = 2;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		Spell("bloodarrow_rain", "Blood Arrows", 122, "Consumes health instead of mana. Embodies many drops of blood into sharp daggers to launch.",
				SpellCategory::offensive, SpellType::healthcost, 0.5f, 20, 0, 256.0f, true, 0, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HEALTHCOST}),
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
				SpellCategory::special, SpellType::other, 10, 6, 0, 270.0f, true, 0, array<int> = {SpellAttribute::SPELL_MOVEMENT}), 
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
				SpellCategory::special, SpellType::other, 8, 10, 0, 64.0f, true),
			
		Spell("leech", "Leech", 25, "Fire a short-ranged arc of dark energy which steals the life-force from foes and revitalizes you.",
				SpellCategory::offensive, SpellType::healthcost, 4, 40, 3, 180.0f, true, 0, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_VAMPIRISM}),
		
		Spell("tomeblood", "Tome of Blood", 127, "Consumes health instead of mana. A swarm of blood arrows to summon beneath the position.",
				SpellCategory::offensive, SpellType::healthcost, 2, 40, 3, 256.0f, true, 0, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HEALTHCOST}),

		Spell("warp_field", "Sigil of Warp", 140, "Open a shroud on map that shrinks the reality in an area. Teleporting inside will open a portal at random location. Can be despelled by anyone.",
				SpellCategory::utility, SpellType::other, 30, 50, 0, 256.0f, true, 0, array<int> = {SpellAttribute::SPELL_MOVEMENT}),

		Spell("chronomantic_teleport", "Chronomantic Teleport", 141, "Consumes health instead of mana. Teleports you to a random location on the map. When overcharged, teleports you to where you were at 5 seconds ago.",
				SpellCategory::utility, SpellType::healthcost, 4, 15, 10, 16.0f, true, 0, array<int> = {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_HEALTHCOST}),

		Spell("poisonsurge", "Toxic Bolt", 137, "Unleash a bolt of toxic sludge that splits into smaller, non-poisoned spheres after a short delay.",
				SpellCategory::offensive, SpellType::other, 25, 40, 0, 256.0f, false, 0, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_POISON}),

		Spell("causticray", "Caustic Ray", 134, "Place a few pillars of corrosive energy that will poison enemies and set their spells on a delay.",
				SpellCategory::offensive, SpellType::other, 1, 15, 0, 16.0f),

		Spell("corruptionshard", "Corruption Shard", 135, "Create a venomous shard releasing poison and fear aura periodically. After a short while, the shard will explode and restore some of your health and mana.",
				SpellCategory::summoning, SpellType::other, 1, 15, 0, 128.0f, false, 1),

		Spell("plague", "Plague", 139, "Permanent poison. Poison damage period is twice longer. Enemies dealing you damage might get poisoned, as long as the Plague spirit exists. Cast again to disable the effect.",
				SpellCategory::debuff, SpellType::other, 5, 40, 2, 16.0f, true, 0, array<int> = {SpellAttribute::SPELL_POISON, SpellAttribute::SPELL_SHIFT, SpellAttribute::SPELL_CASTEREFFECT}),

		Spell("shadowburst", "Shadow Burst", 142, "Materialize a few shadow orbs that shatter on impact.",
				SpellCategory::offensive, SpellType::other, 10, 15, 0, 180.0f, true, 0),

		Spell("shadowspear", "Shadow Spear", 147, "Create a a few subsequent shadow spears following the target. Only one spear can deal damage and steal some of enemy mana in a form of an orb. Counterspelling the mana orb will give mana to caster.",
				SpellCategory::offensive, SpellType::other, 20, 15, 0, array<f32> = {256.0f, 64.0f}, true, 2),

		Spell("darkritual", "Dark Ritual", 133, "For the next 5 seconds the spells that cost health will restore it instead of consuming. You take 5 damage in the end of the effect.",
				SpellCategory::utility, SpellType::other, 1, 15, 0, 16.0f),

		Spell("demonicpact", "Demonic Pact", 138, "Consumes health instead of mana. Resurrect one of your allies into a demon. The demon will restore health to its master when killed, although not when despelled.",
				SpellCategory::support, SpellType::healthcost, 1, 15, 0, 256.0f),

		Spell("fear", "Fear", 145, "Curse an enemy with fear, causing them to run stoplessly",
				SpellCategory::debuff, SpellType::other, 5, 10, 1, 360.0f),

		Spell("silence", "Silence", 146, "Silence an enemy, preventing them from casting spells, except teleport.",
				SpellCategory::debuff, SpellType::other, 15, 20, 4, 360.0f),

		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f),
		
		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f)
	};
}

class WarlockInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;

	WarlockInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
	}
}; 