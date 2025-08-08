//Jester Include

#include "MagicCommon.as";
#include "AttributeCommon.as";

namespace JesterParams
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
	const ::s32 MAX_MANA = 150;
	const ::s32 MANA_REGEN = 3;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		Spell("jestergas", "Rejoicing Gas", 108, "In misty shroud, foes gasp and wheeze, as dense gas spreads with sinister ease.",
			SpellCategory::offensive, SpellType::other, 3, 18, 0, 360.0f, false, 0, array<int> = {SpellAttribute::SPELL_PROJECTILE}),
				
		Spell("teleport", "Teleport to Target", 40, "A swift command, a gesture fair, to unseen realms, teleport with flair.",
			SpellCategory::special, SpellType::other, 20, 6, 0, 250.0f, true, 0, array<int> = {SpellAttribute::SPELL_MOVEMENT}),
			
		Spell("counter_spell", "Counter Spell", 16, "With arcane might, spells break and tear, summoned beasts tremble, in fear they stare.",
			SpellCategory::special, SpellType::other, 20, 10, 0, 64.0f, true),

		Spell("flowerpad", "Flower Pad", 109, "From earth's embrace, a bloom does rise, bouncing softly, under clear skies.",
			SpellCategory::utility, SpellType::other, 5, 30, 0, 128.0f, false, 1, array<int> = {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_GROUNDED}),

		Spell("mitten", "Enchanted Mitten", 110, "A mitten alive, fingers strong and bold, casting bullet hell, its power untold.",
			SpellCategory::offensive, SpellType::other, 20, 20, 1, 256.0f, true, 0, array<int> = {SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_SHIFT}),

		Spell("bobomb", "BOB-omb", 120, "Bob, the walking bomb, with a heart so warm, explodes with love.",
			SpellCategory::summoning, SpellType::other, 35, 45, 8, 128.0f, true, 1, array<int> = {SpellAttribute::SPELL_SUMMON}),

		Spell("bouncybomb", "Gummy Bomb", 113, "This gum bomb bounces to and from, explodes on impact, a foe's woe.",
			SpellCategory::offensive, SpellType::other, 15, 20, 0, 32.0f, false, 0, array<int> = {SpellAttribute::SPELL_PROJECTILE}),

		Spell("carddeck", "Jester Deck", 114, "Six cards of magic in the air, overcharge sends them spinning near.",
			SpellCategory::offensive, SpellType::other, 20, 30, 10, 180.0f, true, 0, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_SHIFT, SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_CONTROL, SpellAttribute::SPELL_CASTEREFFECT}),

		Spell("airhorn", "Air Horn", 115, "A gusty blast, foes feel the strain, soon will none remain.",
			SpellCategory::utility, SpellType::other, 10, 25, 0, 64.0f, true, 0, array<int> = {SpellAttribute::SPELL_KNOCKBACK}),

		Spell("baseballbat", "Bat", 116, "Spinning bat of Jester's grace, erases foes without a trace.",
			SpellCategory::offensive, SpellType::other, 35, 45, 8, 256.0f, true, 0, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_KNOCKBACK}),
		
		Spell("tophat", "Possessed Tophat", 117, "Possessed tophat with mystic deals, dropping bombs and giving heals.",
			SpellCategory::summoning, SpellType::other, 65, 60, 20, 312.0f, true, 0, array<int> = {SpellAttribute::SPELL_SUMMON, SpellAttribute::SPELL_HEAL}),
			
		Spell("bashster", "Bashster", 119, "Knocking blast, a foe's overthrow, hold to charge, let it grow.",
			SpellCategory::offensive, SpellType::other, 30, 45, 6, 256.0f, true, 0, array<int> = {SpellAttribute::SPELL_PROJECTILE}),
			
		Spell("haste", "Haste", 20, "Boost your friends with added speed, or overcharge for self, if you need.",
			SpellCategory::support, SpellType::other, 12, 20, 0, 360.0f, true, 0, array<int> = {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}),

		Spell("shapeshift", "Shape Shift", 132, "Once per game, your form shall shift, your health and mana, none shall drift. Cast with a boost - a fateful clash, and you and foe shall swap in flash.",
			SpellCategory::utility, SpellType::other, 85, 120, 60, 8.0f, true, 0, array<int> = {SpellAttribute::SPELL_CASTEREFFECT}),

		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f),		
				
		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f),

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

class JesterInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;

	JesterInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
	}
};