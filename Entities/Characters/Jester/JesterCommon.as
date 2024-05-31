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
	const ::s32 MAX_MANA = 175;
	const ::s32 MANA_REGEN = 3;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		//Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
		//	SpellType::other, 3, 40, 0, 360.0f),
		//					// 2 is the cost // 40 is the charge time //360.0f is the range //the 0 is the cooldown //6 is the icon it uses
		Spell("jestergas", "Rejoicing Gas", 108, "In misty shroud, foes gasp and wheeze, as dense gas spreads with sinister ease.",
				SpellType::other, 0, 15, 0, 360.0f),
				
		Spell("teleport", "Teleport", 40, "A swift command, a gesture fair, to unseen realms, teleport with flair.",
				SpellType::other, 0, 6, 0, 250.0f, true),
			
		Spell("counter_spell", "Counter Spell", 16, "With arcane might, spells break and tear, summoned beasts tremble, in fear they stare.",
				SpellType::other, 0, 10, 0, 64.0f, true),

		Spell("flowerpad", "Flower Pad", 109, "From earth's embrace, a bloom does rise, bouncing softly, under clear skies.",
				SpellType::other, 0, 30, 0, 128.0f),

		Spell("mitten", "Enchanted Mitten", 110, "A mitten alive, fingers strong and bold, casting bullet hell, its power untold.",
				SpellType::other, 0, 30, 0, 256.0f, true),

		Spell("pogostick", "Pogo Stick", 111, "A spring, a bounce, a leap so high, on pogo stick, touch the sky.",
				SpellType::other, 0, 15, 0, 0.0f, true),

		Spell("bouncybomb", "Gum Bomb", 113, "Very bouncy gum bomb which will explode on impact with foe",
				SpellType::other, 0, 15, 0, 32.0f),

		Spell("carddeck", "Jester Deck", 114, "Six cards with different effects, overcharge will force them to orbit around caster",
				SpellType::other, 0, 15, 0, 180.0f, true),

		Spell("airhorn", "Air Horn", 115, "A huge blow of air dealing moderate damage to enemies in front.",
				SpellType::other, 0, 15, 0, 64.0f, true),

		Spell("baseballbat", "Bat", 116, "Bozo eraser.",
				SpellType::other, 0, 15, 0, 256.0f),
		
		Spell("tophat", "Obsessed Tophat", 117, "Obsessed magic tophat that drops bombs and heals",
				SpellType::other, 0, 15, 0, 416.0f, true),
			 
		Spell("kogun", "K.O. GUN!", 118, "Box their face with your K.O. gun glove!",
				SpellType::other, 0, 15, 0, 96.0f),
			
		Spell("blaster", "Bashster", 119, "Shoot a knocking blast, holding the trigger after cast will charge the spell",
				SpellType::other, 0, 15, 0, 256.0f),
			 
		Spell("bobomb", "BOB-omb", 120, "Wholesome walking bomb, and his name is Bob",
				SpellType::other, 0, 1, 0, 64.0f, true),
			
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