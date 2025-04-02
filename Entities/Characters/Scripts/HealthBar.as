// draws a health bar on mouse hover
#include "TeamColour.as";
#include "MagicCommon.as";
#include "HoverMessage.as";

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 4.0f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	
	if ( getLocalPlayerBlob() !is blob )
	{
		
		//show health
		if (mouseOnBlob || getLocalPlayerBlob() is null)
		{
			Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 20);
			Vec2f dim = Vec2f(24, 8);
			const f32 y = blob.getHeight() * 0.8f;
			
			//VV right here VV
			const f32 health = blob.getHealth();
			const f32 initialHealth = Maths::Max(health, blob.getInitialHealth());
			if (initialHealth > 0.0f)
			{
				const f32 perc = health / initialHealth;
				if (perc >= 0.0f)
				{
					GUI::DrawRectangle(Vec2f(pos2d.x - dim.x, pos2d.y + y), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 6), SColor(100, 255, 255, 255));
					GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x, pos2d.y + y + dim.y + 4), 
						SColor(150, (perc < 0.5f ? 255 : 255 - 255*(perc-0.5f)*2), (perc < 0.5f ? 230*perc*2 : 230), 0));
					GUI::DrawTextCentered(""+Maths::Round(health*10)+" / "+Maths::Round(initialHealth*10), Vec2f(pos2d.x - dim.x + 22, pos2d.y + y + 5), SColor(255, 255, 255, 255));
				}
			}
		}

		ManaInfo@ info;
		if(blob.get("manaInfo",@info))
		{
			//show mana
			if( (mouseOnBlob || getLocalPlayerBlob() is null) && ((getLocalPlayer() !is null && blob.getTeamNum() == getLocalPlayer().getTeamNum()) || getLocalPlayer().getTeamNum() == getRules().getSpectatorTeamNum()))
			{
				Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 40);
				Vec2f dim = Vec2f(24, 8);
				const f32 y = blob.getHeight() * 0.8f;
				
				//VV right here VV
				const f32 maxMana = info.maxMana;
				const f32 mana = info.mana;
				if (maxMana > 0.0f)
				{
					const f32 perc = mana / maxMana;
					if (perc >= 0.0f)
					{
						GUI::DrawRectangle(Vec2f(pos2d.x - dim.x, pos2d.y + y), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 6), SColor(100, 255, 255, 255));
						GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x, pos2d.y + y + dim.y + 4), 
							SColor(150, (perc < 0.5f ? 127 : 127 - 127*(perc-0.5f)*2), 0, (perc < 0.5f ? 230*perc*2 : 230)));
						GUI::DrawTextCentered(""+Maths::Round(mana)+" / "+Maths::Round(maxMana), Vec2f(pos2d.x - dim.x + 22, pos2d.y + y + 5), SColor(255, 255, 255, 255));
					}
				}
			}
		}
		
		//show username
		CPlayer@ mousePlayer = blob.getPlayer();
		if ( mousePlayer !is null )
		{
			Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 20);
			Vec2f dim = Vec2f(24, 8);
			const f32 y = -blob.getHeight() * 3.5f;
		
			Vec2f nameScreenPos = Vec2f(pos2d.x - dim.x + 4, pos2d.y + y + 48);
			string playerName = mousePlayer.getCharacterName();
			
			Vec2f textSize;
			GUI::GetTextDimensions("" + playerName, textSize);
			GUI::DrawRectangle(nameScreenPos + Vec2f(-12.5f, 2.0f), nameScreenPos + Vec2f(textSize.x, textSize.y) + Vec2f(-8.0f, 0.0f), SColor(100, 0, 0, 0)); 
			GUI::DrawText(playerName, nameScreenPos + Vec2f( -12.5f, 0.0f ), getTeamColor( blob.getTeamNum() ));  
		}
		
	}
}

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