#include "MagicCommon.as";

const f32 aura_omega_radius = 64.0f;
const f32 aura_omega_returned_damage_ratio = 0.5f;
f32 aura_omega_dmg_to_mana_ratio = 1.5f; // 1.0f is 200% of damage, 2.0f is 300% of damage (1.0f + 2.0f) 
f32 aura_omega_friendly_damage_factor = 0.5f;
const f32 aura_sigma_damage_mod_self = 1.5f; // 150% intake damage
const f32 health_per_regen = 1.0f;
const f32 connection_dist = 256.0f;
const f32 connection_dmg_reduction = 0.5f;
const f32 connection_dmg_transfer = 0.25f;
const f32 min_connection_health_ratio = 0.25f;
const f32 barrier_dmg_decrease = 0.5f;
const f32 mana_to_health_ratio = 0.0f;
const f32 glyph_cooldown_reduction = 0.34f; // 66% cooldown reduction

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
	const ::s32 MAX_MANA = 250;
	const ::s32 MANA_REGEN = 3;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};

	const ::Spell[] spells = 
	{
		Spell("templarhammer", "Templar Hammer", 92, "Throws a magic hammer that is affected by gravity.",
				SpellType::other, 4, 25, 0, 120.0f),

		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellType::other, 25, 8, 0, 270.0f, true),
			 
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellType::other, 20, 10, 0, 64.0f, true),
			 
		Spell("celestialcrush", "Heavenly Crush", 91, "Summons a heavy hammer to smash nearby area with a delay. Launches everything upwards. Weaker near cliffs.",
				SpellType::other, 10, 40, 3, 256.0f, true, true),

		Spell("dmg_connection", "Aura: Tau", 93, "Links an ally's health to yours. Linked target receives "+(connection_dmg_reduction*100)+"% less damage but transfers "+(connection_dmg_transfer*100)+"% back to you when nearby and if your health is more than "+(min_connection_health_ratio*100)+"%.",
				SpellType::other, 20, 45, 4, 256.0f, true),

		Spell("manatohealth", "Aura: Sigma", 94, "Enables health regeneration and disables mana regeneration. Disables replenishing mana at obelisks. Increases damage taken by "+((aura_sigma_damage_mod_self-1.0f)*100)+"%",
				SpellType::other, 0, 15, 3, 0, true),

		Spell("damagetomana", "Aura: Omega", 95, "Disables mana regeneration. Restores mana for "+(((1.0f+aura_omega_dmg_to_mana_ratio)*100)+"% of received enemy damage and "+((1.0f+aura_omega_dmg_to_mana_ratio)*aura_omega_friendly_damage_factor)*100)+"% of self damage. Returns "+((aura_omega_returned_damage_ratio)*100)+"% of taken damage split to enemies in radius.",
				SpellType::other, 0, 15, 6, 0, true),

		Spell("hallowedbarrier", "Hallowed Protection", 97, "Applies several magic barriers that absorb "+(barrier_dmg_decrease*100)+"% of next physical damage taken. Overcharge adds more barriers and increases effect time.",
				SpellType::other, 20, 45, 10, 0.0f),
				
		Spell("healblocker", "Humility", 96, "Nullifies target healing.",
				SpellType::other, 10, 20, 0, 256.0f, true),

		Spell("majestyglyph", "Glyph of Majesty", 98, "Decreases spell cooldown by "+((1.0f-glyph_cooldown_reduction)*100)+"%.",
				SpellType::other, 15, 30, 8, 96.0f, true),
				
		Spell("sealofwisdom", "Seal of Wisdom", 99, "Applies an effect to wipe any other debuff.",
				SpellType::other, 20, 40, 6, 256.0f, true),

		Spell("noblelance", "Noble Lance", 100, "Casts a piercing lance to move at aim position. Goes back to caster position after reaching destination.",
				SpellType::other, 25, 45, 0, 298.0f, false),
							
		Spell("smite", "Smite", 104, "Summons hammers from the sky.",
				SpellType::other, 30, 45, 6, 198.0f, true),

		Spell("faithglaive", "Faith Glaive", 102, "Releases a short-range glaive to slash in front of you. The spell disables teleport and awaits some time before attack.",
				SpellType::other, 18, 30, 0, 0.0f),

		Spell("blesscircle", "Circle of Bless", 103, "Sets mana regeneration to maximum (+1) for everyone inside. Enemies also claim this effect. Doesnt stack. Can be despelled by anyone.",
				SpellType::other, 10, 60, 18, 198.0f, true),
							
		Spell("knight_revive", "Revive", 106, "Summon a noble warrior back from the dead with aiming a reviving missile at their gravestone.",
				SpellType::other, 70, 60, 25, 360.0f, true),

		Spell("fury", "Fury", 101, "Cast a homing disk releasing sharp flame blades to anyone nearby. Overcharge increases spell damage and fire rate.",
				SpellType::other, 55, 80, 16, 64.0f, true),

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

