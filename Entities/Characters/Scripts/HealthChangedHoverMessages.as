#include "HoverMessage.as";

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	return; // disabled, remake to server client sync
	if (!isClient()) return;
	if (!this.isMyPlayer()) return;
	if (!getRules().get_bool("hovermessages_enabled")) return;

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
	if (!getRules().get_bool("hovermessages_enabled")) return damage;
	if (hitterBlob.getTeamNum() == this.getTeamNum()) return damage;
	if (hitterBlob.isMyPlayer() || hitterBlob.getDamageOwnerPlayer() is getLocalPlayer())
	{
		add_message(DamageDealtMessage(damage));
	}
	return damage;
}