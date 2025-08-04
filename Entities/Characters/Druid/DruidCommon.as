//Druid Include

#include "MagicCommon.as";
#include "AttributeCommon.as";

namespace DruidParams
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
		Spell("sporeshot", "Spore Shot", 31, "A foul fungus that is painful to the touch, lighter than air",
			SpellCategory::offensive, SpellType::other, 3, 7, 0, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE}),	

		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellCategory::special, SpellType::other, 20, 6, 0, 270.0f, true, false, array<int> = {SpellAttribute::SPELL_MOVEMENT}), 
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellCategory::special, SpellType::other, 20, 10, 0, 64.0f, true),
			 
		Spell("revive", "Revive", 15, "Fully bring trusty allies back from the dead by aiming a reviving missile at their gravestone.",
			SpellCategory::support, SpellType::other, 90, 60, 15, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_REVIVE}),
			
		Spell("nature's helpers", "Nature's Helpers", 29, "Fires a swarm of bees. Can heal friends or attack foes.",
			SpellCategory::heal, SpellType::other, 35, 75, 12, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_SUMMON}),	
										
		Spell("spikeorb", "Spike Nut", 30, "The spike nut is natures punishment to those that tread her woods unwelcomed",
			SpellCategory::offensive, SpellType::other, 2, 6, 0, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE}),			
			
		Spell("vinewaver", "Vine Waver", 105, "Creates a sharp homing vine.",
			SpellCategory::offensive, SpellType::other, 35, 30, 5, 128.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE}),
				
		Spell("rock_wall", "Rock Wall", 36, "Create a wall of ordinary rock in front of you that blocks most things both ways. Its not exactly durable though.",
			SpellCategory::defensive, SpellType::other, 15, 15, 0, 30.0f, false, false, array<int> = {SpellAttribute::SPELL_BARRIER}),
				
		Spell("healing_plant", "Nature's Remedy", 37, "This blessing from nature will seal your wounds. Despelling this may heal everyone inside, along with the enemy.",
			SpellCategory::heal, SpellType::other, 35, 30, 5, 128.0f, true, true, array<int> = {SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_GROUNDED}),

		// keep it at 9th index
		Spell("mushroom", "Dancing Shroom", 34, "A happy mushroom that will create it's own cloud of spores for you.",
			SpellCategory::summoning, SpellType::other, 12, 20, 0, 96.0f, true, true, array<int> = {SpellAttribute::SPELL_SENTRY, SpellAttribute::SPELL_GROUNDED}),
		
		Spell("boulder_throw", "Rock Throw", 35, "Throws a heavy rock that is highly affected by gravity.",
			SpellCategory::offensive, SpellType::other, 25, 35, 2, 16.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE}),
				
		Spell("slow", "Slow", 19, "Deprive a player of his speed and ability to teleport for a few moments.",
			SpellCategory::debuff, SpellType::other, 20, 20, 0, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_CONTROL}), 
			 
		Spell("haste", "Haste", 20, "Give your allies some added speed and maneuverability. Fully charge to hasten yourself.",
			SpellCategory::support, SpellType::other, 15, 20, 0, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}),

		Spell("stone_spikes", "Stone Spikes", 38, "Creates a line of dangerous sharp rocks.",
			SpellCategory::offensive, SpellType::other, 30, 25, 8, 180.0f, true, true, array<int> = {SpellAttribute::SPELL_GROUNDED}),

		Spell("airblast_shield", "Airblast Shield", 56, "Cover your ally or yourself in a volatile wind barrier that blasts away nearby enemies whenever you take damage.",
			SpellCategory::support, SpellType::other, 15, 20, 0, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_KNOCKBACK, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}),

		Spell("fire_ward", "Fire Ward", 57, "Form a heat protection aura around your ally or yourself. Completely nullifies fire damage.",
			SpellCategory::support, SpellType::other, 20, 25, 0, 360.0f, true, false, array<int> = {SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}),

		Spell("vinetrap", "Vine Embrace", 89, "Plant sharp vines that will stop enemies passing through it.",
			SpellCategory::debuff, SpellType::other, 25, 45, 5, 128.0f, false, true, array<int> = {SpellAttribute::SPELL_CONTROL, SpellAttribute::SPELL_GROUNDED}),

		Spell("foresttunerain", "Forest Tune", 143, "Scatter and forward sharp foliage in the air towards the targets.",
			SpellCategory::offensive, SpellType::other, 32, 45, 6, 180.0f, true, false, array<int> = {SpellAttribute::SPELL_PROJECTILE}),

		Spell("moss", "Mossy Veil", 144, "Grow spreading moss on the ground that decreases fall damage when you land on it. The flowers growing nearby will increase your speed and decrease for enemy. Spores might help the flowers to grow faster.",
			SpellCategory::utility, SpellType::other, 24, 60, 25, 180.0f, true, true, array<int> = {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_GROUNDED, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT, SpellAttribute::SPELL_CONTROL}),
		
		Spell("", "", 0, "Empty spell.",
			SpellCategory::other, SpellType::other, 1, 1, 0, 0.0f)
	};
}

class DruidInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;

	DruidInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
	}
}; 