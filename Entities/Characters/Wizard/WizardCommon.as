//Wizard Include

#include "MagicCommon.as";
#include "AttributeCommon.as";

namespace WizardParams
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
	const ::s32 MAX_MANA = 150;
	const ::s32 MANA_REGEN = 3;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
			SpellCategory::offensive, SpellType::other, 2, 35, 0, 360.0f, false, 0, WizardSpellAttributesCollection[WizardSpellAttributes::ORB]),						
		
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellCategory::special, SpellType::other, 15, 6, 0, 270.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::TELEPORT]), 			
		
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellCategory::special, SpellType::other, 10, 10, 0, 64.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::COUNTER_SPELL]),			
		
		Spell("frost_ball", "Ball of Frost", 13, "Send forth a slow travelling ball of pure cold essence to freeze your enemies in place and deal a small amount of damage. Freeze duration increases as your own health declines.",
			SpellCategory::offensive, SpellType::other, 15, 30, 3, 360.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::FROST_BALL]),			
		
		Spell("heal", "Lesser Heal", 14, "Salves the least of your allies' wounds to restore a moderate portion of their health. Fully charge in order to heal yourself with less efficiency.",
			SpellCategory::heal, SpellType::other, 18, 35, 0, 360.0f, false, 0, WizardSpellAttributesCollection[WizardSpellAttributes::HEAL]), 			 
		
		Spell("firebomb", "Fireball", 11, "Throw a high velocity condensed ball of flames that explodes on contact with enemies, igniting them. Has a minimum engagement distance of about 4 blocks.",
			SpellCategory::offensive, SpellType::other, 30, 40, 0, 360.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::FIREBOMB]), 			 
		
		Spell("fire_sprite", "Nebula Shard", 12, "Creates a nebula shard to follow your cursor.",
			SpellCategory::offensive, SpellType::other, 25, 35, 0, 360.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::FIRE_SPRITE]),	
			 
		Spell("meteor_strike", "Meteor Strike", 9, "Bring flaming meteors crashing down wherever you desire.",
			SpellCategory::offensive, SpellType::other, 40, 45, 0, 360.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::METEOR_STRIKE]),			 
		
		Spell("revive", "Revive", 15, "Fully bring trusty allies back from the dead by aiming a reviving missile at their gravestone.",
			SpellCategory::support, SpellType::other, 75, 40, 15, 256.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::REVIVE]),			 
		
		Spell("magic_barrier", "Magic Barrier", 21, "Create a wall of pure magical energy in front of you that blocks most small projectiles.",
			SpellCategory::defensive, SpellType::other, 12, 7, 0, 32.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::MAGIC_BARRIER]),			
		
		Spell("slow", "Slow", 19, "Deprive a player of his speed and ability to teleport for a few moments.",
			SpellCategory::debuff, SpellType::other, 15, 10, 0, 360.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::SLOW]), 			 
		
		Spell("haste", "Haste", 20, "Give your allies some added speed and maneuverability. Fully charge to hasten yourself.",
			SpellCategory::support, SpellType::other, 8, 15, 0, 360.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::HASTE]),			
		
		Spell("lightning", "Lightning", 26, "Call down the blazing wrath of heaven upon the heads of those who oppose you.",
			SpellCategory::offensive, SpellType::other, 30, 30, 0, 180.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::LIGHTNING]),
		
		Spell("mana_drain_circle", "Circle of Disenchant", 33, "Those who stand inside this circle lose their mana and are slowed to a crawl",
			SpellCategory::utility, SpellType::other, 35, 60, 20, 312, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::MANA_DRAIN_CIRCLE]),
		
		//Spell("mana_transfer", "Mana Transfer", 48, "Transfers mana equivalent to the target's regen. Generates 1 extra mana if overcharged.",
		//	SpellCategory::support, SpellType::other, 8, 10, 0, 360.0f, true, 0, array<int>(SpellAttribute::SPELL_ALLYEFFECT)),		
		
		Spell("magicplatform", "Magic Platform", 131, "Create a steady platform mid-air.",
			SpellCategory::utility, SpellType::other, 18, 30, 10, 256.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::MAGICPLATFORM]),
		
		Spell("negatisphere", "Negation Spheres", 50, "Moving magic field that negates other counterable spells. Press SHIFT to launch them in the direction of your aim.",
			SpellCategory::defensive, SpellType::other, 20, 45, 1, 360.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::NEGATISPHERE]),				
		
		Spell("plasma_shot", "Plasma Shot", 17, "Fire a slowly moving plasma that explodes on impact or after reaching its destination.",
			SpellCategory::offensive, SpellType::other, 25, 20, 0, 500.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::PLASMA_SHOT]),
		
		Spell("chainlightning", "Chain Lightning", 84, "Send a lightning at the enemy which might hit a close target after a successful hit. Overcharge increases damage and the max amount of targets.",
			SpellCategory::offensive, SpellType::other, 20, 30, 1, 164.0f, false, 0, WizardSpellAttributesCollection[WizardSpellAttributes::CHAINLIGHTNING]),
		
		Spell("flamecircle", "Circle of Flames", 124, "A hellfire area that will incinerate any enemies inside.",
			SpellCategory::offensive, SpellType::other, 50, 60, 25, 312.0f, true, 0, WizardSpellAttributesCollection[WizardSpellAttributes::FLAMECIRCLE]),	
		
		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, WizardSpellAttributesCollection[WizardSpellAttributes::EMPTY_SPELL])						
	};
}

class WizardInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;

	WizardInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
	}
};