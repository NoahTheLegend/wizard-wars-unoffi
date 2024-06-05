//Dash v1.0 by Strathos
 
#include "MakeDustParticle.as";
 
const u16 DASH_COOLDOWN = 15;//seconds * 30
const f32 BASE_DASH_FORCE = 375.0f;//force applied
 
void onInit( CBlob@ this )
{
    this.set_u8( "dashCoolDown", 0 );
    this.set_bool( "disable_dash", false );
    this.getCurrentScript().removeIfTag = "dead";

    f32 new_force = BASE_DASH_FORCE;
    //if (this.getName() == "paladin")
    //{
    //    new_force *= 0.85f;
    //}
    this.set_f32("dash_force", new_force);
}
 
void onTick( CBlob@ this )
{
    const f32 DASH_FORCE = this.get_f32("dash_force");
    bool dashing = this.get_bool( "disable_dash" );
     
    Vec2f vel = this.getVelocity();
    const bool onground = this.isOnGround() || this.isOnLadder();

    bool left		= this.isKeyPressed(key_left);
	bool right		= this.isKeyPressed(key_right);

	if (this.exists("confused") && this.get_u16("confused") > 0)
	{
		bool temp = left;
		left = right;
		right = temp;
	}
    
    const bool down = this.isKeyPressed( key_down );
 
    if ( !dashing )
    {
        if ( down && ( left || right ) )
        {
            this.set_bool( "disable_dash", true );
            this.set_u8( "dashCoolDown", 0 );
			
			if (getNet().isClient())
			{		
				CParticle@ p = ParticleAnimated( "MediumSteam2.png",
								this.getPosition(),
								-vel*0.5f,
								1.0f, 1.0f, 
								3, 
								0.0f, true );
				if (p !is null)
				{
                    p.bounce = 0;
                    p.fastcollision = true;
					p.collides = true;
				}
			}
			
            this.getSprite().PlaySound("Dash" + (XORRandom(3)+1) + ".ogg", 0.3f, 1.0f + XORRandom(3)/10.0f);
            f32 xCompensate;
            if ( left )
            {
                xCompensate = 50.0f * ( vel.x > 0.0f ? vel.x : vel.x * 1.5f );
                this.AddForce( Vec2f( -DASH_FORCE, 10.0f ) - Vec2f( xCompensate, 0.0f ) );
            }
            else if ( right )
            {
                xCompensate = 50.0f * ( vel.x < 0.0f ? vel.x : vel.x * 1.5f );
                this.AddForce( Vec2f( DASH_FORCE, 10.0f ) - Vec2f( xCompensate, 0.0f ) );
            }
        }
    }
    else
    {
        u8 dashCoolDown = this.get_u8( "dashCoolDown" );
        this.set_u8( "dashCoolDown", ( dashCoolDown + 1 ) );
        if ( ( onground && ( !down || ( !left && !right ) ) && dashCoolDown > DASH_COOLDOWN ) || dashCoolDown > DASH_COOLDOWN * 3 )
            this.set_bool( "disable_dash", false );
    }
}