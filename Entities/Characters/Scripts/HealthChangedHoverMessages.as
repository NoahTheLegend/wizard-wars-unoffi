#include "HoverMessage.as";

void onHealthChange(CBlob@ this, f32 oldHealth)
{
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
