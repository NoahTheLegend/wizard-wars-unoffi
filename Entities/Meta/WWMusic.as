// Game Music

#define CLIENT_ONLY

enum GameMusicTags
{
	world_intro,
	world_home,
	world_calm,
	world_battle,
	world_battle_2,
	world_outro,
	world_quick_out,
};

void onInit(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	this.set_bool("initialized game", false);
}

void onTick(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	if (s_gamemusic && s_musicvolume > 0.0f)
	{
		if (!this.get_bool("initialized game"))
		{
			AddGameMusic(this, mixer);
		}

		GameMusicLogic(this, mixer);
	}
	else
	{
		mixer.FadeOutAll(0.0f, 2.0f);
	}
}

//sound references with tag
void AddGameMusic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	this.set_bool("initialized game", true);
	mixer.ResetMixer();

	array<string> trackNames = {
		"CBoyarde.ogg",
		"BruteBlaster.ogg",
		"MarioKart.ogg",
		"LogHorizon1.ogg",
		"LogHorizon2.ogg",
		"Corneria.ogg",
		"Cornered.ogg",
		"Guile.ogg",
		"KingDedede.ogg",
		"MetaKnight.ogg",
		"MuteCity.ogg",
		"Targets.ogg",
		"DeathMinor.ogg",
		"DecisiveBattle.ogg",
		"OneWhoGetsInOurWay.ogg",
		"Battle.ogg",
		"CastleBoss.ogg",
		"CourtoomLobby.ogg",
		"Lake.ogg",
		"League.ogg",
		"Objection.ogg",
		"SteelSamurai.ogg",
		"Trainer.ogg",
		"GoldenCountry.ogg"
	};

	array<bool> addedTracks(trackNames.length(), false);

	for (uint i = 0; i < trackNames.length(); ++i)
	{
		uint randomIndex = XORRandom(trackNames.length() - i) + i;
		mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/" + trackNames[randomIndex], world_home);
		trackNames.erase(randomIndex);
	}
}

uint timer = 0;

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	//warmup
	CRules @rules = getRules();

	if (rules.isWarmup() || rules.isMatchRunning())
	{
		if (mixer.getPlayingCount() == 0)
		{
			mixer.FadeInRandom(world_home , 0.0f);
		}
	}
	else
	{
		mixer.FadeOutAll(0.0f, 1.0f);
	}
}
