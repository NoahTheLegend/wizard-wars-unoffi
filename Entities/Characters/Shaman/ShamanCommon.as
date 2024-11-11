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
	const ::s32 MAX_MANA = 125;
	const ::s32 MANA_REGEN = 4;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		//Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
		//	SpellType::other, 4, 35, 0, 360.0f),
		//					// 2 is the cost // 40 is the charge time //360.0f is the range //the 0 is the cooldown //6 is the icon it uses
		Spell("flameorb", "Flame Orb", 75, "Ignites enemies on impact.",
			SpellType::other, 6, 20, 0, 256.0f, true),

		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellType::other, 20, 6, 0, 270.0f, true), 
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellType::other, 20, 10, 0, 64.0f, true),

		Spell("haste", "Haste", 20, "Give your allies some added speed and maneuverability. Fully charge to hasten yourself.",
			SpellType::other, 10, 20, 0, 360.0f, true),

		Spell("airblast_shield", "Airblast Shield", 56, "Cover your team or yourself in a volatile wind barrier that blasts away nearby enemies whenever you take damage.",
			SpellType::other, 15, 30, 0, 360.0f, true),

		Spell("fire_ward", "Fire Ward", 57, "Form a heat protection aura around yourself. Completely nullifies fire damage.",
			SpellType::other, 15, 30, 0, 360.0f, true),

		Spell("chainlightning", "Chain Lightning", 84, "Sends a lightning at the enemy which may hit a close target after a successful hit. Overcharge increases damage and the max amount of targets.",
			SpellType::other, 25, 25, 0, 164.0f),

		Spell("firetotem", "Totem of Fire", 76, "Shoots flames at nearby enemies. Ignites everything in close range upon death. Overcharge increases lifetime and fire rate.",
			SpellType::other, 30, 50, 2, 156.0f, true, true),

		Spell("watertotem", "Totem of Water", 77, "Heals most damaged nearby ally. Only one totem can heal a target. Generates heal charges passively. Overchage increases durability and generation rate. Pushes everything away upon death.",
			SpellType::other, 40, 90, 8, 128.0f, true, true),
		
		Spell("earthtotem", "Totem of Earth", 78, "Slows down enemies nearby. Overcharge increases effect distance and time. Releases different effects when removed.",
			SpellType::other, 50, 75, 10, 224.0f, true, true),
		
		Spell("massfreeze", "Mass Freeze", 79, "Freezes everyone nearby, including yourself. Overcharge slightly increases distance and duration for enemy and deacreases for yourself. The effect doesn't apply to a target if its burning.",
			SpellType::other, 40, 75, 25, 0.0f, true),
		
		Spell("lavashot", "Lava Shot", 80, "Throws a ball of lava. Periodically drops a bit of lava while moving. Overcharge increases the rate of dropping lava and amount from impact.",
			SpellType::other, 40, 50, 3, 256.0f, true),
		
		Spell("spikeburst", "Spike Burst", 81, "Throws a bunch of spikes that die on touch.",
			SpellType::other, 10, 30, 0, 16.0f),
		
		Spell("iciclerain", "Magic Icicles", 82, "Materializes icicles above, then forwards them to your aim position. Overcharge increases amount of icicles and decreases their delay. Overcharge fully to control aim position while icicles are being released.",
			SpellType::other, 25, 30, 6, 512.0f),

		Spell("waterbarrier", "Water Barrier", 83, "Covers yourself in a bubble of water, which slows down the enemies and some of their spells, acts as Fire Protection. While under this effect, you are unable to use fire spells and receive more damage from electricity and ice.",
			SpellType::other, 10, 35, 0, 0.0f),

		Spell("frost_spirit", "Glacial Spirit", 107, "Summon a homing spirit of frost to freeze your foes.",
			SpellType::other, 25, 60, 6, 360.0f, true),

		Spell("meteor_rain", "Volcano", 121, "Makes a nearby volcano rain with hot magma.",
			SpellType::other, 65, 75, 10, 256.0f, true),
		
		Spell("balllightning", "Lightning Ball", 123, "Creates an electrified and moving ball of pure lightning.",
			SpellType::other, 35, 40, 4, 128.0f, true),
		
		Spell("waterbolt", "Water Bolt", 126, "A dense sphere of water. Speeds up and costs 1 mana less if water is covering the caster.",
			SpellType::other, 6, 30, 0, 256.0f),
		
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