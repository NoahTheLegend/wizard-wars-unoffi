//Entropist Include

#include "MagicCommon.as";

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
			SpellType::other, 3, 25, 0, 360.0f),
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellType::other, 15, 6, 0, 270.0f, true),
			
		Spell("haste", "Haste", 20, "Give your allies some added speed and maneuverability. Fully charge to hasten yourself.",
			SpellType::other, 5, 15, 0, 360.0f, true),
			 
		Spell("disruption_wave", "Disruption Wave", 51, "Unleash a destructive burst of warping energy, tearing apart anything in its path.",
				SpellType::other, 30, 30, 2, 128.0f, true),
			 
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellType::other, 10, 10, 0, 64.0f, true),
			 
		Spell("sidewind", "Sidewind", 53, "Temporarily accelerate your own time by transporting yourself to another dimension for a few moments. Harder to damage while in this dimension.",
				SpellType::other, 5, 2, 3, 1.0f, true),
			 
		Spell("voltage_field", "Voltage Field", 54, "Releases a bubble of electricity that knocks away projectiles and enemies that collide with it. Cannot cast spells while active.",
				SpellType::other, 25, 60, 6, 1.0f, true),
			
		Spell("nova", "Nova", 55, "Releases a homing, concentrated energy star. Explodes on contact.",
				SpellType::other, 30, 45, 25, 100.0f, true),
			
		Spell("burn", "Burn", 60, "Ignite your mana reserves and fuel your magic with blinding heat. Reduces mana generation by 1.",
				SpellType::other, 20, 60, 45, 0.0f, true),
			
		Spell("negentropy", "Negentropy", 59, "Cause Negentropy. Gain 1 extra mana generation.",
				SpellType::other, 150, 150, 45, 0.0f, true),
				
		Spell("crystallize", "Crystallize", 61, "Create a new shard.",
				SpellType::other, 20, 20, 0, 0.0f, true),
							
		Spell("dematerialize", "Dematerialize", 62, "Converts a shard back into mana.",
				SpellType::other, 0, 15, 0, 0.0f, true),
				
		Spell("polarity", "Shards Polarity", 63, "Switch between attack and defense mode.",
				SpellType::other, 5, 30, 3, 0.0f, true),
				
		Spell("dmine", "Disruption Mine", 87, "Places an invisible to enemies mine on the ground. They still can see it within 3 blocks radius. Overcharge increases duration.",
				SpellType::other, 20, 30, 0, 64.0f, true, true),
							
		Spell("magicarrows", "Magic Arrows", 88, "Launches magic arrows, which slightly home at closest enemy if the angle is not too step. Overcharge increases arrows amount and decreases launch delay.",
				SpellType::other, 14, 45, 4, 128.0f),
				
		Spell("polarityfield", "Polarity Breaker", 90, "Summons a massive sphere that summons explosive projectiles to orbit around.\nOvercharge changes rotation side for each second level.",
				SpellType::other, 70, 105, 25, 256.0f, true),
							
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

