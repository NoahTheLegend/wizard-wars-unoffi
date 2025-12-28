#include "HoverMessage.as";

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	return; // disabled currently, needs a proper rework with current hp sync hack

	CRules@ rules = getRules();
	if (rules is null) return;

	if (!isClient()) return;
	if (!this.isMyPlayer()) return;
	if (!rules.get_bool("hovermessages_enabled")) return;

	f32 hp = this.getHealth();
	f32 diff = oldHealth - hp;
	if (Maths::Abs(diff) < 0.01f) return;

	if (hp < oldHealth)
	{
		add_message(DamageTakenMessage(diff));
	}
	else
	{
		add_message(HealTakenMessage(Maths::Abs(diff)));
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	CRules@ rules = getRules();
	if (rules is null) return damage;

	if (!rules.get_bool("hovermessages_enabled")) return damage;
	if (hitterBlob.getTeamNum() == this.getTeamNum()) return damage;
	if (hitterBlob.isMyPlayer() || hitterBlob.getDamageOwnerPlayer() is getLocalPlayer())
	{
		add_message(DamageDealtMessage(damage));
	}
	return damage;
}