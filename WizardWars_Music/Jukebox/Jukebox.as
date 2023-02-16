// Jukebox logic

uint trackNum = 0;
uint maxTracks = 11;

void onInit( CBlob@ this )
{

	if (getMixer() is null)
		return;
	else
	{
		getMixer().FadeOutAll(0.0f, 6.0f );
		getMixer().ResetMixer();
		getMixer().AddTrack("../Mods/SSBG_Music/Corneria.ogg", 0);
		getMixer().AddTrack("../Mods/SSBG_Music/Demolished.ogg", 0);
		getMixer().AddTrack("../Mods/SSBG_Music/Cornered.ogg", 0);
		getMixer().AddTrack("../Mods/SSBG_Music/Highway.ogg", 0);
		getMixer().AddTrack("../Mods/SSBG_Music/Guile2.ogg", 0);
		getMixer().AddTrack("../Mods/SSBG_Music/KingDedede.ogg", 0);
		getMixer().AddTrack("../Mods/SSBG_Music/MetaKnight.ogg", 0);
		getMixer().AddTrack("../Mods/SSBG_Music/MuteCity.ogg", 0);
		getMixer().AddTrack("../Mods/SSBG_Music/Pokemon.ogg", 0);
		getMixer().AddTrack("../Mods/SSBG_Music/Targets.ogg", 0);
		getMixer().AddTrack("../Mods/SSBG_Music/FireField.ogg", 0);
		getMixer().PlayRandom(0);
	}
	
	
	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ( 251.0f );
    this.getShape().SetOffset( Vec2f(0.0f, 4.0f) );
    this.Tag("no falldamage");
	this.getShape().SetRotationsAllowed( false );
	this.server_SetTimeToDie( 30 );
}