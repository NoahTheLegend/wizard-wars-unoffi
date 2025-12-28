//SwordCaster Include

#include "MagicCommon.as";
#include "AttributeCommon.as";

namespace SwordCasterParams
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
	const ::f32 MAX_ATTACK_DIST = 400.0f;
	const ::s32 MAX_MANA = 100;
	const ::s32 MANA_REGEN = 3;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		Spell("impaler", "Impaler", 45, "Sharpen your enemies and use them as a weapon against themselves.",
				SpellCategory::offensive, SpellType::other, 8, 15, 0, 360.0f, true, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::IMPALER]),
				
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
				SpellCategory::special, SpellType::other, 20, 6, 0, 250.0f, true, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::TELEPORT_SWORDCASTER]), 
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
				SpellCategory::special, SpellType::other, 25, 10, 0, 64.0f, true, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::COUNTER_SPELL_SWORDCASTER]),
			
		Spell("executioner", "Executioner", 43, "The Executioner was a sword used, as the name implies, in execution by decapitation. Today, it serves another purpose. Press SHIFT to launch them in the direction of your mouse.",
				SpellCategory::offensive, SpellType::other, 35, 45, 3, 360.0f, true, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::EXECUTIONER]),
			
		Spell("crusader", "Crusader", 42, "This spell materializes three big swords to block the enemy advancement.",
				SpellCategory::offensive, SpellType::other, 25, 40, 0, 360.0f, true, 1, SwordCasterSpellAttributesCollection[SwordCasterSpells::CRUSADER]),
			
		Spell("sword_cast", "Expunger", 41, "Conjure your vast arsenal of magical daggers to attack the enemy.",
				SpellCategory::offensive, SpellType::other, 15, 30, 0, 360.0f, true, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::EXPUNGER]),
			 
		Spell("bladed_shell", "Bladed Shell", 44, "A circle of shear death... Or at least it would be if you used the edge. This spell makes you weak against some magic barriers.",
				SpellCategory::offensive, SpellType::other, 35, 75, 0, 0.0f, true, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::BLADED_SHELL]),
			 
		Spell("hook", "Hook", 86, "Throws a sticky knife which pulls enemies or yourself to a wall. press [USE (E)] button to cut the rope off. Disables teleporting while active. Overcharge increases throw distance.",
				SpellCategory::utility, SpellType::other, 8, 12, 0, 256.0f, true, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::HOOK]),
			 
		Spell("parry", "Parry", 46, "Reflect enemy attacks.",
				SpellCategory::defensive, SpellType::other, 10, 10, 0, 20.0f, true, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::PARRY]),
			 
		Spell("vectorial_dash", "Vectorial Dash", 47, "Cheap movement spell for specific situations. Has a long cooldown.",
				SpellCategory::utility, SpellType::other, 0, 5, 8, 180.0f, true, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::VECTORIAL_DASH]),
			 
		Spell("flame_slash", "Flame Slash", 64, "Forward slash that incinerates your enemies.",
				SpellCategory::offensive, SpellType::other, 10, 25, 1, 70.0f, true, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::FLAME_SLASH]),
			
		Spell("nemesis", "Nemesis", 85, "Summons a row of falling swords from the sky. Overcharge increases the amount of swords and decreases the delay between load and launch.",
				SpellCategory::offensive, SpellType::other, 30, 30, 3, 384.0f, false, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::NEMESIS]),
			 
		Spell("lynch", "Lynch", 125, "Pulls the enemy inside and casts a several execution swords with a delay. Teleporting outside will harm the trapped. Requires 2 dispells to break.",
				SpellCategory::offensive, SpellType::other, 45, 55, 12, 156.0f, true, 0, SwordCasterSpellAttributesCollection[SwordCasterSpells::LYNCH]),
			
		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, SwordCasterSpellAttributesCollection[SwordCasterSpells::EMPTY_SPELL_SWORDCASTER1]),

		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, SwordCasterSpellAttributesCollection[SwordCasterSpells::EMPTY_SPELL_SWORDCASTER2]),			

		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, SwordCasterSpellAttributesCollection[SwordCasterSpells::EMPTY_SPELL_SWORDCASTER3]),

		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, SwordCasterSpellAttributesCollection[SwordCasterSpells::EMPTY_SPELL_SWORDCASTER4]),

		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, SwordCasterSpellAttributesCollection[SwordCasterSpells::EMPTY_SPELL_SWORDCASTER5]),

		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, SwordCasterSpellAttributesCollection[SwordCasterSpells::EMPTY_SPELL_SWORDCASTER6]),

		Spell("", "", 0, "Empty spell.",
				SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, SwordCasterSpellAttributesCollection[SwordCasterSpells::EMPTY_SPELL_SWORDCASTER7])
	};
}

class SwordCasterInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;

	SwordCasterInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
	}
};