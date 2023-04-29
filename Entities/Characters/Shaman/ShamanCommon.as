//Shaman Include

#include "MagicCommon.as";

namespace ShamanParams
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
		Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
			SpellType::other, 3, 40, 0, 360.0f),
							// 2 is the cost // 40 is the charge time //360.0f is the range //the 0 is the cooldown //6 is the icon it uses
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellType::other, 25, 6, 0, 270.0f, true), 
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellType::other, 25, 10, 0, 64.0f, true),

		Spell("haste", "Haste", 20, "Give your allies some added speed and maneuverability. Fully charge to hasten yourself.",
			SpellType::other, 20, 20, 0, 360.0f, true),

		Spell("airblast_shield", "Airblast Shield", 56, "Cover your team or yourself in a volatile wind barrier that blasts away nearby enemies whenever you take damage.",
			SpellType::other, 20, 30, 0, 360.0f, true),

		Spell("fire_ward", "Fire Ward", 57, "Form a heat protection aura around yourself. Completely nullifies fire damage.",
			SpellType::other, 20, 30, 0, 360.0f, true),

		Spell("flameorb", "Flame Orb", 75, "Ignites enemies on impact",
			SpellType::other, 15, 40, 0, 256.0f),

		Spell("firetotem", "Totem of Fire", 76, "Shoots flames in nearby enemies. Ignites enemies in close range upon death. Overcharge increases lifetime and fire rate.",
			SpellType::other, 30, 45, 2, 156.0f),

		Spell("watertotem", "Totem of Water", 77, "Heals most damaged nearby ally. Only one totem can heal a target. Generates heal charges passively. Overchage increases durability and generation rate. Pushes enemies away upon death.",
			SpellType::other, 50, 105, 8, 128.0f),
		
		Spell("earthtotem", "Totem of Earth", 78, "Slows nearby enemies down. Overcharge increases effect distance and durability. Releases different buffs upon death.",
			SpellType::other, 50, 60, 10, 224.0f),
		
		Spell("massfreeze", "Mass Freeze", 79, "Freezes everyone nearby, including yourself. Overcharge slightly increases distance and duration for enemy and deacreases for yourself. The effect doesn't apply to a target if its burning.",
			SpellType::other, 20, 80, 12, 0.0f),
		
		Spell("lavashot", "Lava Shot", 80, "Launches a slowly-moving sphere, which shatters into many drops of lava on impact. Periodically drops a bit of lava while flying. Overcharge increases the rate of dropping lava and amount from impact.",
			SpellType::other, 25, 60, 2, 256.0f),
		
		Spell("spikeburst", "Spike Burst", 81, "Throws a bunch of spikes that die on touch, around the player. Overcharge increases amount of spikes",
			SpellType::other, 20, 45, 0, 16.0f),
		
		Spell("iciclerain", "Magic Icicles", 82, "Launches icicles above with a big deviation, then forwards them to your aim position. Overcharge increases amount of icicles and decreases their delay.\nFull overcharge allows to control aim position while icicles are being released.",
			SpellType::other, 40, 60, 6, 512.0f),

		Spell("", "", 0, "Empty spell.",
			SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
			SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
			SpellType::other, 1, 1, 0, 0.0f)
	};
}

class ShamanInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;

	ShamanInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
	}
}; 