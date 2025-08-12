//Shaman Include

#include "MagicCommon.as";
#include "AttributeCommon.as";

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
		Spell("flameorb", "Flame Orb", 75, "Ignites enemies on impact.",
			SpellCategory::offensive, SpellType::other, 6, 20, 0, 256.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::FLAME_ORB]),

		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellCategory::special, SpellType::other, 20, 6, 0, 270.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::TELEPORT_SHAMAN]),
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellCategory::special, SpellType::other, 20, 10, 0, 64.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::COUNTER_SPELL_SHAMAN]),

		Spell("haste", "Haste", 20, "Give your allies some added speed and maneuverability. Fully charge to hasten yourself.",
			SpellCategory::support, SpellType::other, 10, 20, 0, 360.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::HASTE_SHAMAN]),

		Spell("waterbolt", "Water Bolt", 126, "A dense sphere of water. Speeds up and costs 1 mana less if water is covering the caster.",
			SpellCategory::offensive, SpellType::other, 5, 30, 0, 256.0f, false, 0, ShamanSpellAttributesCollection[ShamanSpells::WATER_BOLT]),

		Spell("fire_ward", "Fire Ward", 57, "Form a heat protection aura around yourself. Completely nullifies fire damage.",
			SpellCategory::support, SpellType::other, 15, 30, 0, 360.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::FIRE_WARD_SHAMAN]),

		Spell("chainlightning", "Chain Lightning", 84, "Send a lightning at the enemy which may hit a close target after a successful hit. Overcharge increases damage and the max amount of targets.",
			SpellCategory::offensive, SpellType::other, 25, 25, 0, 164.0f, false, 0, ShamanSpellAttributesCollection[ShamanSpells::CHAIN_LIGHTNING_SHAMAN]),

		Spell("firetotem", "Totem of Fire", 76, "Shoots flames at nearby enemies. Ignites everything in close range upon death. Overcharge increases lifetime and fire rate.",
			SpellCategory::summoning, SpellType::other, 30, 50, 2, 156.0f, true, 1, ShamanSpellAttributesCollection[ShamanSpells::TOTEM_OF_FIRE]),

		Spell("watertotem", "Totem of Water", 77, "Heals most damaged nearby ally. Only one totem can heal a target. Generates heal charges passively. Overchage increases durability and generation rate. Pushes everything away upon death.",
			SpellCategory::summoning, SpellType::other, 40, 90, 8, 128.0f, true, 1, ShamanSpellAttributesCollection[ShamanSpells::TOTEM_OF_WATER]),
		
		Spell("earthtotem", "Totem of Earth", 78, "Slows down enemies nearby. Overcharge increases effect distance and time. Releases different effects when removed.",
			SpellCategory::summoning, SpellType::other, 50, 75, 10, 224.0f, true, 1, ShamanSpellAttributesCollection[ShamanSpells::TOTEM_OF_EARTH]),
		
		Spell("massfreeze", "Mass Freeze", 79, "Freeze everyone nearby, including yourself. Overcharge slightly increases distance and duration for enemy and deacreases for yourself. The effect doesn't apply to a target if its burning.",
			SpellCategory::utility, SpellType::other, 40, 75, 25, 0.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::MASS_FREEZE]),
		
		Spell("lavashot", "Lava Shot", 80, "Throw a ball of lava. Periodically drops a bit of lava while moving. Overcharge increases the rate of dropping lava and amount from impact.",
			SpellCategory::offensive, SpellType::other, 40, 50, 3, 256.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::LAVA_SHOT]),
		
		Spell("arclightning", "Arc Lightning", 81, "Send a lightning arc that links to other arcs nearby. Amount of lightnings is limited to 5.",
			SpellCategory::offensive, SpellType::other, 18, 28, 0, 256.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::ARC_LIGHTNING]),
		
		Spell("iciclerain", "Magic Icicles", 82, "Materialize icicles to throw at the aim position. Overcharge fully to control aim position meanwhile icicles are being released.",
			SpellCategory::offensive, SpellType::other, 25, 30, 6, 512.0f, false, 0, ShamanSpellAttributesCollection[ShamanSpells::MAGIC_ICICLES]),

		Spell("waterbarrier", "Water Barrier", 83, "Cover yourself in a bubble of water, slowing down the enemies and spells. You are unable to use fire spells and receive more damage from electricity and ice while under the effect.",
			SpellCategory::defensive, SpellType::other, 15, 35, 0, 0.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::WATER_BARRIER]),

		Spell("frost_spirit", "Glacial Spirit", 107, "Summon a homing spirit of frost to freeze your foes.",
			SpellCategory::offensive, SpellType::other, 25, 60, 6, 360.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::GLACIAL_SPIRIT]),

		Spell("meteor_rain", "Volcano", 121, "Force a nearby volcano to rain hot magma over the area.",
			SpellCategory::offensive, SpellType::other, 65, 75, 10, 256.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::VOLCANO]),
		
		Spell("balllightning", "Lightning Ball", 123, "Creates an electrified and moving ball of pure lightning.",
			SpellCategory::offensive, SpellType::other, 35, 40, 4, 128.0f, true, 0, ShamanSpellAttributesCollection[ShamanSpells::LIGHTNING_BALL]),
		
		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, ShamanSpellAttributesCollection[ShamanSpells::EMPTY_SPELL_SHAMAN1]),
		
		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f, ShamanSpellAttributesCollection[ShamanSpells::EMPTY_SPELL_SHAMAN2])
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