#include "MagicCommon.as";

namespace PaladinParams
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
	const ::s32 MAX_MANA = 300;
	const ::s32 MANA_REGEN = 2;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};

	const ::Spell[] spells = 
	{
		Spell("templarhammer", "Templar Hammer", 92, "Throws a magic hammer that is affected by gravity.",
				SpellType::other, 7, 22, 0, 120.0f, true),

		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellType::other, 20, 8, 0, 160.0f, true),
			 
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellType::other, 25, 10, 3, 64.0f, true),
			 
		Spell("celestialcrush", "Heavenly Crush", 91, "Summons a heavy hammer to smash nearby area with a delay. Launches everything upwards.",
				SpellType::other, 15, 40, 2, 128.0f, true),

		Spell("dmg_connection", "Aura: Tau", 93, "Links an ally's health to yours. Linked target transfers 33% of damage to you if nearby and your health is more than 25%.",
				SpellType::other, 10, 30, 5, 256.0f, true),

		Spell("manatohealth", "Aura: Sigma", 94, "Transfers your mana regeneration into health regeneration.",
				SpellType::other, 0, 15, 5, 0, true),

		Spell("damagetomana", "Aura: Omega", 95, "Disables mana regeneration. Restores mana for 200% of received enemy damage and 100% of friendly damage.",
				SpellType::other, 0, 15, 5, 0, true),

		Spell("hallowedbarrier", "Hallowed Protection", 97, "Applies magic barriers that absorb 33% of next magical or physical damage taken. Overcharge adds more barriers and increases effect time.",
				SpellType::other, 30, 70, 10, 0.0f),
				
		Spell("healblocker", "Humility", 96, "Nullifies incoming heal for target.",
				SpellType::other, 12, 30, 0, 256.0f, true),

		Spell("majestyglyph", "Glyph of Majesty", 98, "Doubles spell recharge rate.",
				SpellType::other, 20, 50, 12, 96.0f, true),
				
		Spell("sealofwisdom", "Seal of Wisdom", 99, "Consumes 10 of your HP to restore 20 mana for an ally.",
				SpellType::other, 0, 30, 6, 256.0f, true),

		Spell("noblelance", "Noble Lance", 100, "Casts a piercing lance to move at chosen position. Goes back to caster position when stopped. Ignores tiles.",
				SpellType::other, 30, 50, 0, 298.0f, false),
							
		Spell("fury", "Fury", 101, "Summons a homing ring. Doesn't deal impact damage, instead launches small homing blades around itself. Lasts until despelled while has a target. Overcharge increases blades spawnrate.",
				SpellType::other, 50, 75, 14, 128.0f, true),	

		Spell("faithglaive", "Faith Glaive", 102, "",
				SpellType::other, 20, 45, 0, 0.0f),

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

class PaladinInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;
	u8 pulse_amount;

	PaladinInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
		pulse_amount = 3;
	}
}; 

