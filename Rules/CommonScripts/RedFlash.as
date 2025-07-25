
//Does the good old "red screen flash" when hit - put just before your script that actually does the hitting
#include "Hitters.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    CRules@ rules = getRules();
    if (rules !is null && rules.exists("spell_health_consume_screen_flash")
        && !rules.get_bool("spell_health_consume_screen_flash")
        && customData == Hitters::fall && this is hitterBlob)
    {
        return damage;
    }

    if (this.isMyPlayer() && damage > 0)
    {
        SetScreenFlash( 50, 120, 0, 0 );
        ShakeScreen( 9, 2, this.getPosition() );
    }

    return damage;
}