const string[] specialties_names = {
	"Fire - might ignite enemies","Water - extinguishes fire","Earth - physical damage","Air - high knockback","Nature - organic spells","Electricity - deals more damage to wet enemies",
	"Ice - might freeze or deal more damage to wet enemies","Holy - holy spells","Unholy - unholy spells","Poison - poisonous spells","","",
	"","","","","","",
	"Heal - restore health of allies and yourself","Support - wide variety of buffs","Summoner - create NPCs or sentries","AoE - Area of Effect spells","Control - some spells can control your enemies","Versatile - good at offense and defense",
	"Impacter - damage dealer",	"Agility - movement spells","Map control - deny large area on the map for short amount of time","Tank - great survivability","Life stealer - some spells might heal you on hit","Mana dependency - core spells require plenty of mana to cast",
	"Cheap spells - spamming those is not a bad decision","Life force - some spells might consume you health instead of mana",			"",			"",			"",	""
};

const u8[] specialties_wizard = {24, 0, 5, 6, 21, 22, 23, 29};
const u8[] specialties_necromancer = {20, 8, 21, 22, 26, 28};
const u8[] specialties_druid = {18, 2, 4, 19, 22, 26, 30};
const u8[] specialties_swordcaster = {25, 21, 22, 24, 30};
const u8[] specialties_entropist = {29, 3, 21, 23, 24, 25, 26};
const u8[] specialties_priest = {18, 0, 7, 19, 21, 22, 26};
const u8[] specialties_shaman = {0, 1, 2, 5, 6, 18, 20, 26};
const u8[] specialties_paladin = {27, 7, 19, 24, 29};
const u8[] specialties_jester = {23, 19, 21, 22, 25, 26};
const u8[] specialties_warlock = {24};

const string[] stats_labels =
{
	"", 							// center
	"D", 							// top
	"A", 							// top right
	"S", 							// right
	"H", 							// bottom right
	"D", 							// bottom
	"V", 							// bottom left
	"A", 							// left
	"M" 							// top left
};

const string[] stats_names =
{
	"Difficulty",
	"Damage",
	"Area of Effect",
	"Support",
	"Healing",
	"Defense",
	"Versatility",
	"Agility",
	"Mana"
};

const u8[][] STATS =
{
  // C D A S H D V A M
	{2,2,2,1,0,1,2,1,0}, 				// wizard
	{0,1,2,2,0,1,1,0,2}, 				// necromancer
	{0,0,1,1,2,2,0,1,2}, 				// druid
	{1,2,2,0,0,1,0,2,1}, 				// swordcaster
	{2,2,1,0,0,2,1,2,0}, 				// entropist
	{1,1,2,2,2,1,0,0,1}, 				// priest
	{0,1,1,1,1,1,1,1,1}, 				// shaman
	{1,1,0,2,1,2,2,0,1}, 				// paladin
	{2,2,1,1,0,1,2,1,0}, 				// jester
	{3,0,0,0,0,0,0,0,0}					// warlock
};

const string[] diff_levels =
{
	"EASY",
	"MEDIUM",
	"HARD",
	"COMPLEXLY HARD"
};

const Vec2f[] stat_labels_offsets =
{
	Vec2f(0,0), 					// center
	Vec2f(0,-26), 					// top
	Vec2f(20, -20), 				// top right
	Vec2f(26, 0), 					// right
	Vec2f(20, 20), 					// bottom right
	Vec2f(0, 26), 					// bottom
	Vec2f(-20, 20), 				// bottom left
	Vec2f(-26, 0), 					// left
	Vec2f(-21, -20) 				// top left
};

const SColor[] stats_middle_color =
{
	SColor(255, 55, 255, 55), 		// green
	SColor(255, 255, 255, 55), 		// yellow
	SColor(255, 255, 55, 55), 		// red
	SColor(255, 255, 125, 255)		// pink
};

const SColor[] stats_color =
{
	SColor(255, 255, 55, 55), 		// red
	SColor(255, 255, 155, 55), 		// orange
	SColor(255, 255, 255, 55), 		// yellow
	SColor(255, 55, 255, 55), 		// green
	SColor(255, 55, 255, 255), 		// cyan
	SColor(255, 55, 55, 255), 		// blue
	SColor(255, 255, 125, 255), 	// pink
	SColor(255, 185, 70, 225) 		// purple
};

f32 classDescriptionOpenTimer = 0; // counts the time of being active
const f32 classDescriptionFadeFactor = 0.25f;

f32 classDescriptionFade = 0;
bool showClassDescription = false;

const Vec2f descriptionButtonOffset = Vec2f(0, 8);
const Vec2f descriptionButtonOffsetOut = Vec2f(0, -128);
const Vec2f descriptionButtonSize = Vec2f(510, 54);
const Vec2f descriptionButtonSizeExtra = Vec2f(0, 32);

const string[] classTitles = {
	"Wizard",
	"Necromancer",
	"Druid",
	"Swordcaster",
	"Entropist",
	"Priest",
	"Shaman",
	"Paladin",
	"Jester",
	"Warlock"
};

const string[] classSubtitles = {
	"Master of the Knowledge",
	"Dark Lord",
	"The Nature's Guardian",
	"Grand Duelist",
	"Exiled Renegade",
	"Divine Inquisitor",
	"Ancestors Oracle",
	"Fateful Templar",
	"Deft Trickster",
	"Emissary of the Forbidden"
};

const string[] classDescriptions = {
	" Wizards' history has proven them to be formidable opponents.\nYears spent studying obscure magic have granted them a wide range of powerful spells, though most still avoid focusing too deeply on any one school — unsure whether the power they unlock might destroy THEM first.",
    " Necromancers have a habit of learning spells no one else wants to deal with.\nAfter enough time with rituals and curses, most stop pretending it's about knowledge and start calling it \"the willing\". It works well enough — though keeping things under control is more of a hope than a plan.",
    " Druids trust nature more than people, and it usually pays off.\nWhile living in harmony with the world around them, they adjust to the flow of natural energies, allowing them to use the environment to their advantage, and if their magic isn't flashy, it's certainly persistent and reliable.",
    " Swordcasters don't fuss over complex magic — they turn raw force into blunt instruments and let physics do the rest.\n\n Their spells are straightforward, built for impact and contact rather than finesse. It's not subtle, but it gets the job done.",
    " Entropists play with unstable forces, bending reality in ways that rarely follow the rules.\n\n Whatsoever, they are really willing to do so, as they often consume themselves into excitement of being overpowered.",
    " Priests dedicate themselves to the divine, channeling holy energy to heal team and smite foes.\n\n They wield slow, but impactful spells, but their true strength lies in exhorating allies — a beacon in the darkest battles.",
    " Shamans command totems and elemental forces through channels to nature's spirits and their ancestors.\n\n Versatile in both offense and defense, bound to the elements of earth, fire and water, they adapt fluidly to any situation.",
    " Paladins embody noble strength, standing as steadfast tanks and shining symbols of hope.\nTheir holy damage burns through darkness, while their protective auras bolster allies and their souls.\nThey are the shield of the team, and their presence is a rallying point for all.",
    " Jesters use misdirection and spectacle to control the battlefield in unconventional ways.\nTheir kind blends utility and offense through volatile spells, unpredictable movement and conjured constructs. What others call distraction, they refine into precision — forcing enemies to react on their terms.",
    " Warlocks pursue forbidden paths, accepting the cost to wield destructive to their health forces.\nBlood, decay and time itself are tools as much as elements of their craft. While some warlocks borrow power through demonic pacts, others reshape the flow of battle with their life force."
};

bool[] classesSeen = {false, false, false, false, false, false, false, false, false, false};
const string[] classesCachedProperties = {
	"seen_wizard_description",
	"seen_necromancer_description",
	"seen_druid_description",
	"seen_swordcaster_description",
	"seen_entropist_description",
	"seen_priest_description",
	"seen_shaman_description",
	"seen_paladin_description",
	"seen_jester_description",
	"seen_warlock_description"
};

void setCachedClassesSeen(bool hide = true)
{
    bool joinedBefore = playerClassButtons.getBool("descriptionsInit", "WizardWars");
    if (!joinedBefore || !hide)
    {
        playerClassButtons.saveBool("descriptionsInit", true, "WizardWars");
        
        for (u8 i = 0; i < classesSeen.length; i++)
        {
            playerClassButtons.saveBool(classesCachedProperties[i], false, "WizardWars");
            classesSeen[i] = false;
            //print("debug: set " + classesCachedProperties[i] + " to false");
        }

        return;
    }

	for (u8 i = 0; i < classesSeen.length; i++)
	{
		classesSeen[i] = playerClassButtons.getBool(classesCachedProperties[i], "WizardWars");
        //print("debug: set " + classesCachedProperties[i] + " to " + classesSeen[i]);
	}
}

bool canShowClassDescription(u8 id)
{
	return id < classesSeen.length && id >= 0 && !classesSeen[id];
}

void setCachedClassSeen(int id, bool seen)
{
	if (id < classesSeen.length && id >= 0)
	{
		classesSeen[id] = seen;
		playerClassButtons.saveBool(classesCachedProperties[id], seen, "WizardWars");
	}
}

void ClassDescriptionButtonHandler(int x, int y, int button, IGUIItem@ item)
{ 
    if (item is null) return;

	Button@ sender = cast<Button>(item);
	if (sender is null) return;
    if (sender.color.getAlpha() != 255) return; // inactive

	Sound::Play("MenuSelect2.ogg");	
	int customData = sender._customData;
	setCachedClassSeen(customData, true);

	showClassDescription = false;
	classDescriptionFade = 0;
	classDescriptionOpenTimer = 0;
}

const string[][] symbol_lines = {
	// A
	{
		"     AAAA     ",
		"    AA  AA    ",
		"   AA    AA   ",
		"  AA      AA  ",
		" AAAAAA      ",
		" AA        AA ",
		" AA        AA ",
		" AA        AA ",
		" AA        AA ",
		" AA        AA "
	},

	// B
	{
		" BBBBB       ",
		" BB       BB  ",
		" BB       BB  ",
		" BB      BB  ",
		" BBBBB       ",
		" BB      BB  ",
		" BB       BB  ",
		" BB       BB  ",
		" BB      BB  ",
		" BBBBB       "
	},

	// C
	{
		"   CCCCCCC   ",
		" CC             CC",
		" CC          ",
		" CC          ",
		" CC          ",
		" CC          ",
		" CC             CC",
		"   CCCCCCC   "
	},

	// D
	{
		" DDDDD       ",
		" DD     DD   ",
		" DD      DD  ",
		" DD      DD  ",
		" DD      DD  ",
		" DD      DD  ",
		" DD      DD  ",
		" DD     DD   ",
		" DDDDD       "
	},

	// E
	{
		" EEEEEEEE    ",
		" EE          ",
		" EE          ",
		" EEEEEE      ",
		" EE          ",
		" EE          ",
		" EE          ",
		" EEEEEEEE    "
	},

	// F
	{
		" FFFFFFFF    ",
		" FF          ",
		" FF          ",
		" FFFFFF      ",
		" FF          ",
		" FF          ",
		" FF          "
	},

	// G
	{
		"   GGGGGGG   ",
		" GG                GG ",
		" GG          ",
		" GG   GGGGG  ",
		" GG               GG  ",
		" GG               GG  ",
		" GG             GG   ",
		"   GGGGGG    "
	},

	// H
	{
		" HH      HH  ",
		" HH      HH  ",
		" HH      HH  ",
		" HHHHHH  ",
		" HH      HH  ",
		" HH      HH  ",
		" HH      HH  "
	},

	// I
	{
		" IIIIIIII   ",
		"    II      ",
		"    II      ",
		"    II      ",
		"    II      ",
		"    II      ",
		" IIIIIIII   "
	},

	// J
	{
		" JJJJJJJJJ   ",
		"           JJ     ",
		"           JJ     ",
		"           JJ     ",
		"           JJ     ",
		" JJ   JJ     ",
		"  JJJJ       "
	},

	// K
	{
		" KK      KK   ",
		" KK    KK     ",
		" KK  KK       ",
		" KKKK        ",
		" KK  KK       ",
		" KK    KK     ",
		" KK      KK   "
	},

	// L
	{
		" LL          ",
		" LL          ",
		" LL          ",
		" LL          ",
		" LL          ",
		" LL          ",
		" LLLLLLL     "
	},

	// M
	{
		" MM                    MM  ",
		" MMM                MM  ",
		" MMMM    MMMM  ",
		" MM    MMM    MM   ",
		" MM       M         MM   ",
		" MM                    MM  ",
		" MM                    MM  "
	},

	// N
	{
		" NN               NN  ",
		" NNN            NN  ",
		" NNNN         NN  ",
		" NN   NN      NN  ",
		" NN     NN    NN  ",
		" NN       NN  NN  ",
		" NN         NNNN  ",
		" NN            NNN  ",
		" NN               NN  "
	},

	// O
	{
		"   OOOOOO    ",
		" OO            OO    ",
		" OO            OO    ",
		" OO            OO    ",
		" OO            OO    ",
		" OO            OO    ",
		"   OOOOOO    "
	},

	// P
	{
		" PPPPPP      ",
		" PP        PP    ",
		" PP        PP    ",
		" PPPPPP      ",
		" PP          ",
		" PP          ",
		" PP          "
	},

	// Q
	{
		"  QQQQQQ     ",
		" QQ            QQ    ",
		" QQ            QQ    ",
		" QQ            QQ    ",
		" QQ   Q      QQ    ",
		" QQ    Q    QQ     ",
		"  QQQQQ Q    "
	},

	// R
	{
		" RRRRRR      ",
		" RR        RR    ",
		" RR        RR    ",
		" RRRRRR      ",
		" RR   RR      ",
		" RR      RR     ",
		" RR         RR    "
	},

	// S
	{
		"  SSSSSS     ",
		" SS          SS    ",
		" SS          ",
		"  SSSSSS     ",
		"                SS     ",
		" SS         SS    ",
		"  SSSSSS     "
	},

	// T
	{
		" TTTTTTTT     ",
		"         TT       ",
		"         TT       ",
		"         TT       ",
		"         TT       ",
		"         TT       ",
		"         TT       "
	},

	// U
	{
		" UU      UU    ",
		" UU      UU    ",
		" UU      UU    ",
		" UU      UU    ",
		" UU      UU    ",
		" UU      UU    ",
		"   UUUUU     "
	},

	// V
	{
		" VV    VV    ",
		" VV    VV    ",
		" VV    VV    ",
		" VV    VV    ",
		"  VV  VV     ",
		"   VVVV      ",
		"      VV       "
	},

	// W
	{
		" WW                    WW  ",
		" WW                    WW  ",
		" WW       W       WW   ",
		" WW    WW    WW   ",
		" WWW        WWW  ",
		" WW                   WW  ",
		" WW                    WW  "
	},

	// X
	{
		" XX    XX    ",
		"  XX  XX     ",
		"   XXXX      ",
		"      XX       ",
		"   XXXX      ",
		"  XX  XX     ",
		" XX    XX    "
	},

	// Y
	{
		" YY     YY    ",
		" YY     YY    ",
		"  YY   YY     ",
		"   YYYY      ",
		"      YY       ",
		"      YY       ",
		"      YY       "
	},

	// Z
	{
		" ZZZZZZ     ",
		"           ZZ     ",
		"         ZZ      ",
		"       ZZ       ",
		"     ZZ        ",
		"   ZZ         ",
		" ZZZZZZ     "
	}
};

string CombineSymbols(const u8[] symbol_indices, const u8[] offsets)
{
	string result = "";

	for (u8 i = 0; i < symbol_indices.length; i++)
	{
		u8 idx = symbol_indices[i];
		u8 left_offset = offsets.length > i ? offsets[i] : 0;
		if (idx < symbol_lines.length)
		{
			for (u8 line = 0; line < symbol_lines[idx].length; line++)
			{
				for (u8 s = 0; s < left_offset; s++)
				{
					result += " ";
				}
				result += symbol_lines[idx][line] + "\n";
			}
			result += "\n";
		}
	}

	return result;
}
