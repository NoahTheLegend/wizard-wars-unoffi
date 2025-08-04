//Priest Include

#include "MagicCommon.as";
#include "AttributeCommon.as";

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
	const ::s32 MANA_REGEN = 4;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};

	const ::Spell[] spells = 
	{
		Spell("epicorbmain", "Orbiting Orbs", 74, "Summons magic orbs rotating around its center. Amount of orbs scales with charge.",
			SpellCategory::offensive, SpellType::other, 8, 30, 0, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE}),
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellCategory::special, SpellType::other, 20, 6, 0, 270.0f, true, false, array<int> = {SpellAttribute::SPELL_MOVEMENT}),

		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellCategory::special, SpellType::other, 20, 10, 0, 64.0f, true),

		Spell("haste", "Haste", 20, "Give your allies some added speed and maneuverability. Fully charge to hasten yourself.",
			SpellCategory::support, SpellType::other, 10, 15, 0, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}),
			 
		Spell("revive", "Revive", 15, "Fully bring trusty allies back from the dead by aiming a reviving missile at their gravestone.",
			SpellCategory::support, SpellType::other, 90, 60, 15, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_REVIVE}),

		Spell("slow", "Slow", 19, "Deprive a player of his speed and ability to teleport for a few moments.",
			SpellCategory::debuff, SpellType::other, 20, 20, 0, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_CONTROL}), 

		Spell("mana_transfer", "Mana Transfer", 48, "Transfers mana equivalent to the target's regen. Generates 1 extra mana if overcharged.",
			SpellCategory::support, SpellType::other, 7, 15, 0, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_ALLYEFFECT}),

		Spell("regen", "Regeneration", 70, "Applies a slight healing, that lasts some time.",
			SpellCategory::heal, SpellType::other, 25, 45, 0, 360.0f, false, false, array<int> = {SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}),

		Spell("holystrike", "Holy Strike", 65, "Summons a piercing shard, which shatters into smaller shards after time.",
			SpellCategory::offensive, SpellType::other, 30, 60, 6, 270.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE}),
						
		Spell("divineshield", "Divine Shield", 66, "Covers a moderate area with reflecting and powerful barrier. Some spells can phase through it. Lifetime scales with charge.",
			SpellCategory::defensive, SpellType::other, 75, 120, 30, 96.0f, true, false, array<int> = {SpellAttribute::SPELL_BARRIER}),
			
		Spell("beam", "Divine Beam", 67, "Continuously damages enemies or heals teammates in beam area. Hold LMB after casting to keep firing. Pushes enemies when overcharged. Merges into a bigger beam when second is cast.",
			SpellCategory::offensive, SpellType::other, 5, 15, 2, 128.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HEAL}),
						
		Spell("fireorbs", "Sacrilege Fire", 68, "Summons a smiting ball to spin around you. Press [SHIFT] to launch it at the aim position.",
			SpellCategory::offensive, SpellType::other, 30, 30, 0, 32.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HOMING_CURSOR}),	

		Spell("singularity", "Singularity", 69, "Summons an essence of stars, which explodes with colossal power after some time. Takes less time to explode if overchaged. Can not be denied. Does not pierce blocks.",
			SpellCategory::offensive, SpellType::other, 60, 45, 15, 360.0f, true),

		Spell("fiery_star", "Fiery Stars", 58, "Launch a several concetrated fire elements at your enemies. Overcharge to store them at aim position.",
			SpellCategory::offensive, SpellType::other, 25, 35, 1, 256.0f, false, false, array<int> = {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_SHIFT}),
						
		Spell("emergencyteleport", "Emergency Teleport", 71, "Teleports you to the most damaged teammate and heals both. Heal scales with target's lost HP. If there is no such target, heals yourself.",
			SpellCategory::heal, SpellType::other, 40, 60, 18, 16.0f, true, false, array<int> = {SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_MOVEMENT}),

		Spell("damageaura", "Damage Aura", 72, "Improves spells of nearby allies, at cost of making you slower.\nCast again to disable the spell.",
			SpellCategory::support, SpellType::other, 10, 30, 5, 16.0f, true, false, array<int> = {SpellAttribute::SPELL_ALLYEFFECT}),

		Spell("manaburn", "Mana Burn", 73, "Slowly burns enemy mana and disables their mana regeneration.",
			SpellCategory::debuff, SpellType::other, 30, 65, 10, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_CONTROL}),

		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f)
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