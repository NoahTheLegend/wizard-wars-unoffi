#include "MagicCommon.as";
#include "SpellUtils.as";

const f32 follow_distance = 48.0f;
const f32 deceleration_distance = follow_distance * 2;
const f32 circle_distance = 40.0f;
const f32 acceleration = 0.025f;
const f32 deceleration = 0.01f;
const f32 max_speed = 8.0f;

void onTick(CBlob@ this)
{
    if (!this.get_bool("plague")) return;
    
    u16 plague_follow_id;
    CBlob@ plague = null;

    if (!this.exists("plague_follower"))
        @plague = @createPlagueBlob(this);
    else
        @plague = getBlobByNetworkID(this.get_u16("plague_follower"));

    if (plague is null && (!this.exists("plague_delay") || this.get_u32("plague_delay") < getGameTime()))
        @plague = @createPlagueBlob(this);

    if (plague is null) return;
    
    Vec2f aimDir = this.getAimPos() - this.getPosition();
    Vec2f circledArea = this.getPosition() + Vec2f(circle_distance, 0).RotateBy(-aimDir.Angle());

    bool shifting = this.get_bool("shifting");
    f32 shift_mod = shifting ? 0.0f : 1.0f;

    Vec2f pos = shifting ? circledArea : this.getPosition();
    Vec2f plague_pos = plague.getPosition();

    Vec2f dir = pos - plague_pos;
    f32 dist = dir.Length();

    dir.Normalize();
    f32 plag_accel = plague.get_f32("acceleration");
    f32 last_angle_diff = plague.get_f32("last_angle_diff");

    Vec2f plag_vel = plague.getVelocity();
    f32 vel_length = plag_vel.Length();

    Vec2f velNorm = plag_vel;
    velNorm.Normalize();

    if (plague.get_u32("next_random_offset") < getGameTime())
    {
        plague.set_u32("next_random_offset", getGameTime() + 10 + XORRandom(10));
        plague.set_Vec2f("rnd_offset", Vec2f(XORRandom(8)+2, 0).RotateBy(XORRandom(360)));
    }

    f32 angle_diff = 0.0f;
    if (plag_vel.Length() > 0.01f)
    {
        f32 dot = velNorm.x * dir.x + velNorm.y * dir.y;
        angle_diff = Maths::Lerp(last_angle_diff,(1.0f - dot) / 2.0f, 0.25f);
    }

    f32 force_factor = 1.0f + angle_diff * 1.0f;
    if (dist < deceleration_distance * shift_mod)
    {
        plag_accel = Maths::Clamp(plag_accel - deceleration, 0.0f, 1.0f);
        Vec2f target_vel = dir * plag_accel * force_factor;
        Vec2f new_vel = Vec2f_lerp(plag_vel, target_vel, 0.05f);
        plague.setVelocity(new_vel);

        if (plag_accel == 0)
        {
            Vec2f cur_pos = plague.get_Vec2f("cur_pos");
            Vec2f vel_dir = cur_pos - plague.getPosition();
            f32 vel_dist = vel_dir.Length();
            if (vel_dist > 0.01f)
            vel_dir.Normalize();
            else
            vel_dir = Vec2f_zero;

            f32 float_strength = 0.2f;
            f32 float_speed = 0.15f;
            f32 time = getGameTime() + plague.getNetworkID();
            Vec2f float_offset = Vec2f(Maths::Sin(time * float_speed), Maths::Cos(time * float_speed)) * float_strength;

            plague.setVelocity(vel_dir * Maths::Clamp(vel_dist, 0.0f, 1.0f) * 0.08f + float_offset);
        }
        else if (new_vel.Length() > 1.0f)
        {
            this.set_Vec2f("cur_pos", plague.getPosition());
        }
    }
    else
    {
        plague.set_Vec2f("cur_pos", plague.getPosition());
        plag_accel = Maths::Clamp(plag_accel + acceleration * (1.5f - shift_mod), 0.0f, 1.0f);

        Vec2f vel = plag_vel * (1.0f - angle_diff * plag_accel) + dir * plag_accel * force_factor;
        if (vel.Length() > max_speed)
        {
            vel.Normalize();
            vel *= max_speed;
        }
        
        plague.setVelocity(vel);
    }

    plague.server_SetTimeToDie(1);
    plague.set_f32("acceleration", plag_accel);
    plague.set_f32("last_angle_diff", angle_diff);
    this.set_u16("plague_follower", plague.getNetworkID());

    if (this.isKeyJustPressed(key_down))
    {
        this.getShape().checkCollisionsAgain = true;
    }
}

CBlob@ createPlagueBlob(CBlob@ this)
{
    if (!isServer()) return null;

    CBlob@ blob = server_CreateBlob("plagueblob", this.getTeamNum(), this.getPosition() + Vec2f(follow_distance / 4 + XORRandom(follow_distance/2), 0).RotateBy(XORRandom(360)));
    if (blob !is null)
    {
        blob.set_u16("plague_owner", this.getNetworkID());
        blob.SetDamageOwnerPlayer(this.getPlayer());
    }
    
    return blob;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    CBlob@ blob;
    if (hitterBlob is null) return damage;

    @blob = hitterBlob.hasTag("player") ? @hitterBlob : hitterBlob.getDamageOwnerPlayer() !is null ? hitterBlob.getDamageOwnerPlayer().getBlob() : null;
    if (blob is null) return damage;

    if (blob !is null && this.get_bool("plague") && blob.getTeamNum() != this.getTeamNum() && blob.hasScript("StatusEffects.as"))
    {
        CBlob@ plague = getBlobByNetworkID(this.get_u16("plague_follower"));
        if (plague !is null)
            Poison(blob, defaultPoisonTime, this, 0.5f);
    }

    return damage;
}