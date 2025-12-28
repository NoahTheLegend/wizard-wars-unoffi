//Warlock Include
#include "MagicCommon.as";
#include "AttributeCommon.as";

const int positions_save_time_in_seconds = 15;
const u8 old_positions_save_threshold = 1;
const f32 darkritual_lifesteal_mod = 1.0f;

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
	const ::s32 MAX_MANA = 100;
	const ::s32 MANA_REGEN = 0;
	const ::f32 HEALTH_COST_PER_1_MANA = 0.02f; // 0.2f is 1 HP
	const ::f32 MANA_PER_1_DAMAGE = 3.5f;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		Spell("bloodbolt_rain", "Blood Bolts", 148, "Embodies blood into accelerating bolts to launch.",
				SpellCategory::offensive, SpellType::healthcost, 0.5f, 15, 3, 256.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::BLOOD_BOLTS]),
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
				SpellCategory::special, SpellType::other, 15, 6, 0, 270.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::TELEPORT_WARLOCK]), 
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures. You can not use health for this spell.",
				SpellCategory::special, SpellType::other, 10, 10, 0, 64.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::COUNTER_SPELL_WARLOCK]),
			
		Spell("leech", "Leech", 25, "Fire a short-ranged arc of dark energy which steals the life-force from foes and revitalizes you.",
				SpellCategory::offensive, SpellType::other, 25, 25, 8, 180.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::LEECH_WARLOCK]),
		
		Spell("tomeblood", "Tome of Blood", 127, "A swarm of blood arrows to summon beneath the position.",
				SpellCategory::offensive, SpellType::healthcost, 1, 40, 6, 256.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::TOME_OF_BLOOD]),

		Spell("warp_field", "Sigil of Warp", 140, "Open a shroud on map that shrinks the reality in an area. Teleporting inside will open a portal at random location. Can be dispelled by anyone.",
				SpellCategory::utility, SpellType::other, 40, 50, 15, 256.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::SIGIL_OF_WARP]),

		Spell("chronomantic_teleport", "Chronomantic Teleport", 141, "Teleports you to a random location on the map. When overcharged, teleports you to where you were at 5 seconds ago.",
				SpellCategory::utility, SpellType::healthcost, 3, 20, 10, 16.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::CHRONOMANTIC_TELEPORT]),

		Spell("poisonsurge", "Toxic Bolt", 137, "Unleash a bolt of toxic sludge that splits into smaller, non-poisoned spheres after a short delay.",
				SpellCategory::offensive, SpellType::other, 35, 40, 8, 256.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::TOXIC_BOLT]),

		Spell("corruptionshard", "Corruption Shard", 135, "Create a venomous shard releasing poison and fear aura periodically. After a short while, the shard will explode and restore some of your health and mana.",
				SpellCategory::summoning, SpellType::other, 10, 40, 8, 128.0f, true, 1, WarlockSpellAttributesCollection[WarlockSpells::CORRUPTION_SHARD]),

		Spell("plague", "Plague", 139, "Permanent poison. Poison damage period is twice longer. Enemies dealing you damage might get poisoned, as long as the Plague spirit exists. Cast again to disable the effect.",
				SpellCategory::debuff, SpellType::other, 5, 25, 2, 8.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::PLAGUE]),

		Spell("shadowburst", "Shadow Burst", 142, "Materialize several shadow orbs that shatter on impact. When colliding with an enemy, another projectile is created behind.",
				SpellCategory::offensive, SpellType::other, 15, 20, 6, 180.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::SHADOW_BURST]),

		Spell("shadowspear", "Shadow Spear", 147, "Create several consecutive shadow spears that follow the target. Only one spear can deal damage and steal some of the enemy's mana in the form of an orb. Counterspelling the mana orb will restore mana to the caster. Anyone but the orb owner will receive twice more mana.",
				SpellCategory::offensive, SpellType::other, 15, 35, 12, 256.0f, 64.0f, true, 2, WarlockSpellAttributesCollection[WarlockSpells::SHADOW_SPEAR]),

		Spell("carnage", "Carnage", 136, "Reset most of your spell cooldowns. Overcharge to make the next spell you cast have half the charge time and no cooldown.",
				SpellCategory::utility, SpellType::healthcost, 2.5, 20, 12, 8.0f, false, 0, WarlockSpellAttributesCollection[WarlockSpells::CARNAGE]),

		Spell("darkritual", "Dark Ritual", 133, "Your spells gain lifesteal for a few seconds. You take 10 damage in the end of the effect.",
				SpellCategory::utility, SpellType::other, 20, 30, 24, 8.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::DARK_RITUAL]),

		Spell("demonicpact", "Demonic Pact", 138, "Seal the soul of your fallen ally into a demon. They will restore health to you when killed, although not when dispelled. Taking damage improves them!",
				SpellCategory::support, SpellType::healthcost, 10, 40, 16, 256.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::DEMONIC_PACT]),

		Spell("fear", "Fear", 145, "Curse an enemy with fear, causing them to run stoplessly",
				SpellCategory::debuff, SpellType::other, 5, 8, 4, 360.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::FEAR]),

		Spell("silence", "Silence", 146, "Silence an enemy, preventing them from casting spells",
				SpellCategory::debuff, SpellType::other, 15, 20, 14, 360.0f, true, 0, WarlockSpellAttributesCollection[WarlockSpells::SILENCE]),

		//Spell("causticray", "Caustic Ray", 134, "Place a few pillars of corrosive energy that will poison enemies and set their spells on a delay.",
		//		SpellCategory::offensive, SpellType::other, 1, 15, 0, 16.0f),

		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, WarlockSpellAttributesCollection[WarlockSpells::EMPTY_SPELL_WARLOCK1]),
		
		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, WarlockSpellAttributesCollection[WarlockSpells::EMPTY_SPELL_WARLOCK2]),
		
		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, WarlockSpellAttributesCollection[WarlockSpells::EMPTY_SPELL_WARLOCK3]),

		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, WarlockSpellAttributesCollection[WarlockSpells::EMPTY_SPELL_WARLOCK4])
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