//default actor hud
// a bar with hearts in the bottom left, bottom right free for actor specific stuff

void renderBackBar( Vec2f origin, f32 width, f32 scale)
{
    for (f32 step = 0.0f; step < width/scale - 64; step += 64.0f * scale)
    {
        GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64,32), origin+Vec2f(step*scale,0), scale);
    }

    GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64,32), origin+Vec2f(width - 128*scale,0), scale);
}

void renderFrontStone( Vec2f farside, f32 width, f32 scale)
{
    for (f32 step = 0.0f; step < width/scale - 16.0f*scale*2; step += 16.0f*scale*2)
    {
        GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16,32), farside+Vec2f(-step*scale - 32*scale,0), scale);
    }

    if (width > 16) {
        GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16,32), farside+Vec2f(-width, 0), scale);
    }

    GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16,32), farside+Vec2f(-width - 32*scale, 0), scale);
    GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16,32), farside, scale);
}

void renderHPBar( CBlob@ blob, Vec2f origin)
{
    string heartFile = "GUI/HPbar.png"; // "GUI/HeartNBubble.png"
	int barLength = 4;
    int segmentWidth = 24; // 32
    GUI::DrawIcon("GUI/jends.png", 0, Vec2f(8,16), origin+Vec2f(-8,0)); // ("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16,32), origin+Vec2f(-segmentWidth,0));
	f32 blobHealth = blob.getHealth();
	f32 blobInitHealth = blob.getInitialHealth();
	f32 healthPerSegment = blobInitHealth/barLength;
	
	f32 fourthHPSeg = healthPerSegment*(1.0f/4.0f);
	f32 halfHPSeg = healthPerSegment*(1.0f/2.0f);
	f32 threeFourthsHPSeg = healthPerSegment*(3.0f/4.0f);
    
    SColor col = SColor(255, 255, 75, 75);
    if (blob.get_u16("healblock") > 0) col = SColor(255, 155, 155, 155);

    int HPs = 0;
    for (int step = 0; step < barLength; step += 1)
    {	
        GUI::DrawIcon("GUI/HPback.png", 0, Vec2f(12,16), origin+Vec2f(segmentWidth*HPs,0)); // ("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(16,32), origin+Vec2f(segmentWidth*HPs,0));
        f32 thisHP = blobHealth - step*healthPerSegment;
        if (thisHP > 0)
        {
            // Vec2f heartoffset = (Vec2f(2,10) * 2);
            Vec2f heartpos = origin+Vec2f(segmentWidth*HPs-1,0); // origin+Vec2f(segmentWidth*HPs,0)+heartoffset;
			if (thisHP <= fourthHPSeg) { GUI::DrawIcon(heartFile, 4, Vec2f(16,16), heartpos, 1, col); } // Vec2f(12,12)
            else if (thisHP <= halfHPSeg) { GUI::DrawIcon(heartFile, 3, Vec2f(16,16), heartpos, 1, col); } // Vec2f(12,12)
            else if (thisHP <= threeFourthsHPSeg) { GUI::DrawIcon(heartFile, 2, Vec2f(16,16), heartpos, 1, col); } // Vec2f(12,12)
			else if (thisHP > threeFourthsHPSeg) { GUI::DrawIcon(heartFile, 1, Vec2f(16,16), heartpos, 1, col); } // else { GUI::DrawIcon(heartFile, 1, Vec2f(12,12), heartpos); }
            else { GUI::DrawIcon(heartFile, 0, Vec2f(16,16), heartpos, 1, col); }
        }
        HPs++;
    }
    GUI::DrawIcon("GUI/jends.png", 1, Vec2f(8,16), origin+Vec2f(segmentWidth*HPs,0)); // ("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16,32), origin+Vec2f(32*HPs,0));
	GUI::DrawText(""+Maths::Round(blobHealth*10)+"/"+blobInitHealth*10, origin+Vec2f(-42,8), color_white );
}

const string[] font_names = {
    "Wizardry_12",
    "Wizardry_14",
    "Wizardry_16",
    "Wizardry_18",
    "Wizardry_20",
    "Wizardry_22",
    "Wizardry_24",
	"Wizardry_32",

    "KingThingsPetrockLight_12",
    "KingThingsPetrockLight_14",
    "KingThingsPetrockLight_18",
    "KingThingsPetrockLight_20",
    "KingThingsPetrockLight_22",
    "KingThingsPetrockLight_24",
    "KingThingsPetrockLight_32",
    "KingThingsPetrockLight_36",
    "KingThingsPetrockLight_40",
    "KingThingsPetrockLight_44",
    "KingThingsPetrockLight_48",
    "KingThingsPetrockLight_52",
    "KingThingsPetrockLight_56",
    "KingThingsPetrockLight_60",
    "KingThingsPetrockLight_64",
    
    "DragonFire_12",
    "DragonFire_14",
    "DragonFire_15",
    "DragonFire_16",
    "DragonFire_17",
    "DragonFire_18",
	"DragonFire_24",
	"DragonFire_32",
    "DragonFire_40",
    "DragonFire_48",
    "DragonFire_56",
    "DragonFire_64"
};

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";

    for (u8 i = 0; i < font_names.length; i++)
	{
		string[] parts = font_names[i].split("_");
		if (parts.length == 2)
		{
			string full_font_name = font_names[i];
			string font_name = parts[0];
			string font_size = parts[1];
			
			if (!GUI::isFontLoaded(full_font_name))
			{
				string font_path = CFileMatcher(full_font_name + ".ttf").getFirst();
				GUI::LoadFont(full_font_name, font_path, parseInt(font_size), true);
			}
		}
	}
}

void onRender( CSprite@ this )
{
	if (g_videorecording)
		return;

    GUI::SetFont("default");
    CBlob@ blob = this.getBlob();

    f32 height = 10;
    #ifdef STAGING
        height += 20;
    #endif
    Vec2f topleft(52,height);
	GUI::DrawIcon("GUI/jslot.png", 1, Vec2f(32,32), Vec2f(2,height-8));
	renderHPBar(blob, topleft); // ( blob, ul);
}
