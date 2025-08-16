//Necromancer Include

#include "MagicCommon.as";
#include "AttributeCommon.as";

namespace NecromancerParams
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
	const ::f32 MAX_ATTACK_DIST = 360.0f;
	const ::s32 MAX_MANA = 100;
	const ::s32 MANA_REGEN = 4;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};

	const ::Spell[] spells = 
	{
		Spell("poisonarrow_rain", "Poison Arrows", 128, "Solidifies many drops of poison into sharp daggers to launch.",
			SpellCategory::offensive, SpellType::other, 4, 25, 0, 256.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::POISON_ARROW_RAIN]),
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellCategory::special, SpellType::other, 20, 6, 0, 270.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::TELEPORT_NECROMANCER]),
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellCategory::special, SpellType::other, 25, 10, 0, 64.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::COUNTER_SPELL_NECROMANCER]),
			 
		Spell("slow", "Slow", 19, "Deprive a player of his speed and ability to teleport for a few moments.",
			SpellCategory::debuff, SpellType::other, 12, 30, 0, 360.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::SLOW_NECROMANCER]), 
			 
		Spell("zombie", "Summon a Zombie", 2, "Summon an undead minion to fight by your side.",
			SpellCategory::summoning, SpellType::summoning, 20, 15, 0, 64.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::ZOMBIE]),
			 
		Spell("black_hole", "Black Hole", 18, "Open a portal into outer space, pulling your enemies into the void. Drains the mana of enemies in the area.",
			SpellCategory::utility, SpellType::other, 55, 120, 4, 180.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::BLACK_HOLE]),
 
		Spell("zombieknight", "Summon a Zombie knight", 5, "Summon a very strong zombie to your side. Very effective for blocking in tight corridors.",
			SpellCategory::summoning, SpellType::summoning, 55, 15, 0, 64.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::ZOMBIE_KNIGHT]),
			
		Spell("skeleton_rain", "Skeleton Rain", 10, "Summon a hailstorm of skeletons to swarm a nearby opponent.",
			SpellCategory::summoning, SpellType::other, 40, 45, 15, 256.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::SKELETON_RAIN]),
			
		Spell("arrow_rain", "Arrow Rain", 22, "Cause a long volley of randomly assorted arrows to fall upon thy foe. Great for area denial, and possibly overpowered!",
			SpellCategory::offensive, SpellType::other, 55, 55, 10, 360.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::ARROW_RAIN]),
			
		Spell("recall_undead", "Recall Undead", 23, "Instantly bring all summoned minions, along with the unfortunate victims they may be carrying, to your location. ",
			SpellCategory::utility, SpellType::other, 5, 10, 10, 8.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::RECALL_UNDEAD]),
				
		Spell("unholy_resurrection", "Unholy Resurrection", 24, "Inexpensively resurrect fallen allies... Though they may not find themselves completely restored to their former glory.",
			SpellCategory::support, SpellType::other, 20, 30, 5, 256.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::UNHOLY_RESURRECTION]),
							
		Spell("leech_g", "Leech", 130, "Fire a short-ranged arc of dark energy which steals the life-force from foes and revitalizes you.",
			SpellCategory::offensive, SpellType::other, 20, 38, 3, 180.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::LEECH]),
				
		Spell("force_of_nature", "Force of Nature", 27, "By invoking this spell, you call into being an orb of ghastly green light which destroys anything foolish enough to cross its path, including you!",
			SpellCategory::offensive, SpellType::other, 30, 30, 3, 360.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::FORCE_OF_NATURE]),
				
		Spell("arcane_circle","Arcane Circle", 32,"Summon an unholy circle that will drain the life force of your foes",
			SpellCategory::support, SpellType::other, 50, 60, 10, 360, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::ARCANE_CIRCLE]),
							
		Spell("bunker_buster", "Bunker Buster", 39, "Anti-Barrier spell.",
			SpellCategory::utility, SpellType::other, 15, 40, 0, 360.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::BUNKER_BUSTER]),
				
		Spell("no_teleport_barrier", "Teleport Blocker", 49, "Prevents enemies from teleporting past this barrier.",
			SpellCategory::utility, SpellType::other, 8, 10, 0, 100.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::NO_TELEPORT_BARRIER]),
							
		Spell("manaburn", "Mana Burn", 73, "Slowly burns enemy mana and disables their mana regeneration.",
			SpellCategory::debuff, SpellType::other, 30, 75, 10, 360.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::MANA_BURN_NECROMANCER]),

		Spell("tomepoison", "Tome of Poison", 129, "A swarm of poison arrows to summon beneath the position.",
			SpellCategory::offensive, SpellType::other, 16, 40, 3, 256.0f, true, 0, NecromancerSpellAttributesCollection[NecromancerSpells::TOME_OF_POISON]),
							
		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, NecromancerSpellAttributesCollection[NecromancerSpells::EMPTY_SPELL_NECROMANCER1]),
				
		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, NecromancerSpellAttributesCollection[NecromancerSpells::EMPTY_SPELL_NECROMANCER2])				
	};
}

class NecromancerInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;

	NecromancerInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
	}
};

