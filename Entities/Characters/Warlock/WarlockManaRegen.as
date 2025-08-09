#include "MagicCommon.as";
#include "WarlockCommon.as"

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
    if (hitBlob !is null && hitBlob.hasTag("player"))
    {
        ManaInfo@ manaInfo;
        if (hitBlob.get("manaInfo", @manaInfo))
        {
            manaInfo.mana += (damage / 5.0f) * MANA_PER_1_DAMAGE;
        }
    }
}