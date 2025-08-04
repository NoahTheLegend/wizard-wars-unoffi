//Entropist Include

#include "MagicCommon.as";
#include "AttributeCommon.as";

namespace EntropistParams
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
	const ::s32 MAX_MANA = 200;
	const ::s32 MANA_REGEN = 2;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};

	const ::Spell[] spells = 
	{
		Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
			SpellCategory::offensive, SpellType::other, 3, 25, 0, 360.0f, false, false, array<int> = {SpellAttribute::SPELL_PROJECTILE}),
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellCategory::special, SpellType::other, 12, 6, 0, 270.0f, true, false, array<int> = {SpellAttribute::SPELL_MOVEMENT}),
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellCategory::special, SpellType::other, 10, 10, 0, 64.0f, true),
			 
		Spell("disruption_wave", "Disruption Wave", 51, "Unleash a destructive burst of warping energy, tearing apart anything in its path.",
			SpellCategory::offensive, SpellType::other, 30, 30, 2, 128.0f, true, false, array<int> = {SpellAttribute::SPELL_MELEE}),
			 
		Spell("haste", "Haste", 20, "Give your allies some added speed and maneuverability. Fully charge to hasten yourself.",
			SpellCategory::support, SpellType::other, 5, 15, 0, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}),
			 
		Spell("sidewind", "Sidewind", 53, "Temporarily accelerate your own time by transporting yourself to another dimension for a few moments. Harder to damage while in this dimension.",
			SpellCategory::utility, SpellType::other, 5, 1, 3, 1.0f, true, false, array<int> = {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT}),
			 
		Spell("voltage_field", "Voltage Field", 54, "Releases a bubble of electricity that knocks away projectiles and enemies that collide with it. Cannot cast spells while active.",
			SpellCategory::offensive, SpellType::other, 20, 45, 6, 1.0f, true, false, array<int> = {SpellAttribute::SPELL_BARRIER, SpellAttribute::SPELL_CASTEREFFECT}),
			
		Spell("nova", "Nova", 55, "Release a homing, short-living concentrated energy star. Explodes on contact.",
			SpellCategory::offensive, SpellType::other, 30, 45, 25, 100.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HOMING_CURSOR}),
			
		Spell("burn", "Burn", 60, "Ignite your mana reserves and fuel your magic with blinding heat. Reduces mana generation by 1.",
			SpellCategory::utility, SpellType::other, 10, 60, 45, 0.0f, true, false, array<int> = {SpellAttribute::SPELL_CASTEREFFECT}),
			
		Spell("negentropy", "Negentropy", 59, "Gain 1 extra mana generation.",
			SpellCategory::utility, SpellType::other, 180, 150, 45, 0.0f, true, false, array<int> = {SpellAttribute::SPELL_CASTEREFFECT}),
				
		Spell("crystallize", "Crystallize", 61, "Create a mana draining shard.",
			SpellCategory::utility, SpellType::other, 20, 5, 0, 0.0f, true, false, array<int> = {SpellAttribute::SPELL_BARRIER, SpellAttribute::SPELL_CASTEREFFECT}),
							
		Spell("dematerialize", "Dematerialize", 62, "Convert a shard back into mana.",
			SpellCategory::utility, SpellType::other, 0, 5, 0, 0.0f, true, false, array<int> = {SpellAttribute::SPELL_CASTEREFFECT}),
				
		Spell("polarity", "Shards Polarity", 63, "Switch between attack and defense mode.",
			SpellCategory::utility, SpellType::other, 5, 30, 1, 0.0f, true, false, array<int> = {SpellAttribute::SPELL_CASTEREFFECT}),
				
		Spell("dmine", "Disruption Mine", 87, "Place an invisible to enemies mine on the ground. They still can see it within 3 blocks radius. Overcharge increases duration.",
			SpellCategory::offensive, SpellType::other, 20, 30, 0, 64.0f, true, true, array<int> = {SpellAttribute::SPELL_GROUNDED}),
							
		Spell("magicarrows", "Magic Arrows", 88, "Launche magic arrows, which slightly home at closest enemy if the angle is not too step. Overcharge increases arrows amount and decreases launch delay.",
			SpellCategory::offensive, SpellType::other, 14, 45, 4, 128.0f, false, false, array<int> = {SpellAttribute::SPELL_PROJECTILE}),
				
		Spell("polarityfield", "Polarity Breaker", 90, "Summon a massive sphere that summons explosive projectiles to orbit around.\nOvercharge changes rotation side for each second level.",
			SpellCategory::offensive, SpellType::other, 70, 105, 25, 256.0f, true),
							
		Spell("stellarcollapse", "Stellar Collapse", 149, "Summon several celestial bodies to fall from the sky, dealing massive damage to enemies.",
			SpellCategory::offensive, SpellType::other, 60, 60, 18, 312.0f, true, false, array<int> = {SpellAttribute::SPELL_RAIN}),

		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f),	
							
		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f),		

		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f)
	};
}

class EntropistInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;
	u8 pulse_amount;

	EntropistInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
		pulse_amount = 3;
	}
}; 

