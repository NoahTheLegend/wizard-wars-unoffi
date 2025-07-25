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
	const ::f32 HEALTH_COST_PER_1_MANA = 0.025f; // 0.2f is 1 HP, currently - 8 mana to 1 HP
	const ::f32 MANA_PER_1_DAMAGE = 2;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		Spell("bloodarrow_rain", "Blood Arrows", 122, "Consumes health instead of mana. Embodies many drops of blood into sharp daggers to launch.",
				SpellType::healthcost, 0.5f, 20, 0, 256.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HEALTHCOST}),
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
				SpellType::other, 8, 6, 0, 270.0f, true, false, array<int> = {SpellAttribute::SPELL_MOVEMENT}), 
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
				SpellType::other, 8, 10, 0, 64.0f, true),
			
		Spell("leech", "Leech", 25, "Fire a short-ranged arc of dark energy which steals the life-force from foes and revitalizes you.",
				SpellType::other, 20, 40, 3, 180.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_VAMPIRISM}),
		
		Spell("tomeblood", "Tome of Blood", 127, "Consumes health instead of mana. A swarm of blood arrows to summon beneath the position.",
				SpellType::healthcost, 2, 40, 3, 256.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HEALTHCOST}),

		Spell("warp_field", "Warp Field", 140, "Open a warp-shroud on map that breaks the laws of physics for living creatures. Teleporting inside will open a portal at random location. Can be despelled by anyone.",
				SpellType::other, 30, 50, 0, 256.0f, true, false, array<int> = {SpellAttribute::SPELL_MOVEMENT}),

		Spell("chronomantic_teleport", "Chronomantic Teleport", 141, "Teleports you to a random location on the map. When overcharged, teleports you to where you were at 5 seconds ago.",
				SpellType::other, 25, 30, 5, 16.0f, true, false, array<int> = {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_HEALTHCOST}),

		Spell("poisonsurge", "Poison Surge", 137, "Unleash a sphere of toxic energy that splits into smaller, non-poisoned spheres after a short delay.",
				SpellType::other, 1, 30, 0, 256.0f, false, false, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_POISON}),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("fear", "Fear", 0, "Curse nearby enemies with fear, causing them to run stoplessly",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("resetcooldowns", "Wipe Spell Cooldowns", 0, "Spend some of your health to reset all your spell cooldowns.",
				SpellType::healthcost, 1, 1, 0, 0.0f),

		Spell("", "", 0, "For the next 5 seconds the spells you cast will not consume health, however you take 10 damage in the end of the effect.",
				SpellType::other, 1, 1, 0, 0.0f),
		
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
		
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
		
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f)						
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