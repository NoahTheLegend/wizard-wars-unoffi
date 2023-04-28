//Orb trail animation
const f32 initialSize = 1.0f;
const f32 scaleFactor = 0.5f;
const u8 maxScale = 12;

void onInit( CSprite@ this )
{
	this.SetZ( 500.0f );
    CSpriteLayer@ trail = this.addSpriteLayer( "trail", "FlameOrbTrail.png", 11, 7 );
	if (trail !is null)
    {
		Animation@ anim = trail.addAnimation( "default", 3, true );
		anim.AddFrame(0);
		anim.AddFrame(1);
		anim.AddFrame(2);
		trail.ScaleBy( Vec2f( initialSize, initialSize ) );
		trail.SetRelativeZ( -1.0f );
		trail.SetAnimation(anim);
    }
}

void onTick( CSprite@ this )
{
	CBlob@ blob = this.getBlob();
	Vec2f vel = blob.getVelocity();
	vel.y *= -1;
	f32 velLength = vel.getLength();
	
	CSpriteLayer@ trail = this.getSpriteLayer( "trail" );
	
	if ( trail is null )	return;

	f32 trailOffset = Maths::Min( maxScale, initialSize + velLength*scaleFactor ) + 2.0f;
	//print( "trailOffset: " + trailOffset );

	trail.ResetTransform();
	trail.SetOffset( Vec2f( trailOffset, -0.5f ) );
	trail.RotateBy( vel.Angle(), Vec2f( -trailOffset, 0 ) );	
	trail.SetVisible( true );
}