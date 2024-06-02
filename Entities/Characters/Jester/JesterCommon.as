//Jester Include

#include "MagicCommon.as";

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
		//Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
		//	SpellType::other, 3, 40, 0, 360.0f),
		//					// 2 is the cost // 40 is the charge time //360.0f is the range //the 0 is the cooldown //6 is the icon it uses
		Spell("jestergas", "Rejoicing Gas", 108, "In misty shroud, foes gasp and wheeze, as dense gas spreads with sinister ease.",
				SpellType::other, 4, 25, 0, 360.0f),
				
		Spell("teleport", "Teleport", 40, "A swift command, a gesture fair, to unseen realms, teleport with flair.",
				SpellType::other, 20, 6, 0, 250.0f, true),
			
		Spell("counter_spell", "Counter Spell", 16, "With arcane might, spells break and tear, summoned beasts tremble, in fear they stare.",
				SpellType::other, 20, 10, 0, 64.0f, true),

		Spell("flowerpad", "Flower Pad", 109, "From earth's embrace, a bloom does rise, bouncing softly, under clear skies.",
				SpellType::other, 10, 30, 0, 128.0f),

		Spell("mitten", "Enchanted Mitten", 110, "A mitten alive, fingers strong and bold, casting bullet hell, its power untold.",
				SpellType::other, 20, 40, 3, 256.0f, true),

		Spell("pogostick", "Pogo Stick", 111, "A spring, a bounce, a leap so high, on pogo stick, touch the sky.",
				SpellType::other, 20, 30, 6, 0.0f, true),

		Spell("bouncybomb", "Gummy Bomb", 113, "This gum bomb bounces to and fro, explodes on impact, a foe's woe.",
				SpellType::other, 20, 30, 0, 32.0f),

		Spell("carddeck", "Jester Deck", 114, "Six cards of magic in the air, overcharge sends them spinning near.",
				SpellType::other, 15, 50, 5, 180.0f, true),

		Spell("airhorn", "Air Horn", 115, "A gusty blast, foes feel the strain, soon will none remain.",
				SpellType::other, 15, 25, 0, 64.0f, true),

		Spell("baseballbat", "Bat", 116, "Spinning bat of Jester's grace, erases foes without a trace.",
				SpellType::other, 35, 55, 0, 256.0f, true),
		
		Spell("tophat", "Obsessed Tophat", 117, "Obsessed tophat with mystic deals, dropping bombs and giving heals.",
				SpellType::other, 40, 60, 10, 416.0f, true),
			 
		Spell("kogun", "K.O. GUN!", 118, "A powerful glove, K.O. delight, box their face, end the fight!",
				SpellType::other, 6, 10, 0, 80.0f),
			
		Spell("bashster", "Bashster", 119, "Knocking blast, a foe's overthrow, hold to charge, let it grow.",
				SpellType::other, 25, 45, 1, 256.0f, true),
			 
		Spell("bobomb", "BOB-omb", 120, "Bob, the walking bomb, with a heart so warm, explodes with love.",
				SpellType::other, 22, 45, 6, 128.0f, true),
			
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