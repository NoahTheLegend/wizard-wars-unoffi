#include "MagicCommon.as";
#include "SpellUtils.as";
#include "WarlockCommon.as";

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
    if (hitBlob !is null && hitBlob.hasTag("player") && hitBlob.getTeamNum() != this.getTeamNum() && hitBlob !is this)
    {
        CPlayer@ damageOwner = this.getDamageOwnerPlayer();
        if (damageOwner is null) return;

        CBlob@ ownerBlob = damageOwner.getBlob();
        if (ownerBlob !is null)
        {
            ManaInfo@ manaInfo;
            if (ownerBlob.get("manaInfo", @manaInfo))
            {
                manaInfo.mana += damage * 10 * WarlockParams::MANA_PER_1_DAMAGE;
            }

            if (ownerBlob.get_u16("darkritual_effect_time") > 0)
            {
                Heal(ownerBlob, ownerBlob, damage * darkritual_lifesteal_mod, false, false, 0);
            }
        }
    }
}