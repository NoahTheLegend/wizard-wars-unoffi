//Priest Include

#include "MagicCommon.as";

namespace PriestParams
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
	const ::s32 MAX_MANA = 150;
	const ::s32 MANA_REGEN = 3;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};

	const ::Spell[] spells = 
	{
		Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
			SpellType::other, 3, 30, 0, 360.0f),
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellType::other, 25, 6, 0, 270.0f, true),
			
		Spell("haste", "Haste", 20, "Give your allies some added speed and maneuverability. Fully charge to hasten yourself.",
			SpellType::other, 15, 15, 0, 360.0f, true),
			 
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellType::other, 20, 10, 0, 64.0f, true),
			 
		Spell("revive", "Revive", 15, "Fully bring trusty allies back from the dead by aiming a reviving missile at their gravestone.",
			SpellType::other, 60, 60, 30, 360.0f, true),

		Spell("slow", "Slow", 19, "Deprive a player of his speed and ability to teleport for a few moments.",
			SpellType::other, 20, 25, 0, 360.0f, true), 

		Spell("mana_transfer", "Mana Transfer", 48, "Transfers mana equivalent to the target's regen. Generates 1 extra mana if overcharged.",
			SpellType::other, 8, 15, 0, 360.0f, true),

		Spell("regen", "Regenerate", 70, "Applies a slight healing, that lasts some time.",
				SpellType::other, 18, 25, 0, 360.0f, true), 	

		Spell("holystrike", "Holy Strike", 65, "Summons a piercing shard, which shatters into smaller shards after time.",
				SpellType::other, 35, 60, 6, 270.0f),
							
		Spell("divineshield", "Divine Shield", 66, "Covers a moderate area with reflecting and powerful barrier. Lifetime scales with charge.",
				SpellType::other, 80, 180, 15, 92.0f),
				
		Spell("beam", "Divine Beam", 67, "Continuously damages enemies or heals teammates in beam area. Pushes enemies when overcharged fully. Also continuously takes mana and keeps firing after activation if held left click.",
				SpellType::other, 15, 20, 1, 96.0f),
							
		Spell("fireorbs", "Sacrilege Fire", 68, "A ball of light and smite, will target an enemy when nearby. Has a moderate chance to ignite.",
				SpellType::other, 25, 30, 1, 32.0f),	

		Spell("singularity", "Singularity", 69, "Summons an essence of stars, which explodes with colossal power after some time. Takes less time to explode if overchaged. Can not be denied. Does not pierce blocks.",
				SpellType::other, 100, 60, 15, 360.0f),	

		Spell("epicorbmain", "Orbiting Orbs", 74, "Summons magic orbs rotating around its center. Amount of orbs scales with charge.",
				SpellType::other, 8, 45, 0, 360.0f),
							
		Spell("emergencyteleport", "Emergency Teleport", 71, "Teleports you to the most damaged teammate and heals both. Heal scales with target's lost HP. If there is no such target, heals yourself.",
				SpellType::other, 30, 60, 20, 16.0f),

		Spell("damageaura", "Damage Aura", 72, "Improves spells of nearby allies for a short time, however disables your dash ability and slows down.",
				SpellType::other, 15, 30, 0, 16.0f),

		Spell("manaburn", "Mana Burn", 73, "Slightly burns enemy mana, if effect was applied.",
				SpellType::other, 25, 45, 0, 360.0f),


		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f)				
	};
}

class PriestInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;
	u8 pulse_amount;

	PriestInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
		pulse_amount = 3;
	}
}; 

