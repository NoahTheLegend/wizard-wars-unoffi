#define CLIENT_ONLY

#include "ShadersCommon.as";

void onInit(CRules@ this)
{
	Driver@ driver = getDriver();
	driver.ForceStartShaders();
    driver.SetShader("hq2x", false);
	driver.AddShader("blackhole", 5.0f);
	driver.SetShader("blackhole", false);
	
	BlackHole@[] blackholes;
	this.set("blackholes", blackholes);
}

void onTick(CRules@ this)
{
	Driver@ driver = getDriver();
	if (!driver.ShaderState()) 
	{
		driver.ForceStartShaders();
	}

    if (v_fastrender) return;

    this.clear("blackholes");

    // Find blobs and add positions to array
    CBlob@[] bhBlobs;
	getBlobsByName("black_hole", @bhBlobs);
    for (uint i = 0; i < bhBlobs.length; i++)
    {
        BlackHole bHole(bhBlobs[i].getPosition(), 0.1f);  // position, intensity(radius)
        this.push("blackholes", @bHole);
    }
    CBlob@[] bhbBlobs;
	getBlobsByName("black_hole_big", @bhbBlobs);
    for (uint i = 0; i < bhbBlobs.length; i++)
    {
        BlackHole bHole(bhbBlobs[i].getPosition(), 0.25f);
        this.push("blackholes", @bHole);
    }
}
void onRender(CRules@ this)
{
    Driver@ driver = getDriver();
	if (v_fastrender) {
        driver.SetShader("blackhole", false);
		return;
    }

	BlackHole@[]@ blackholes;
	if (!this.get("blackholes", @blackholes)) return;
	
	if (blackholes.length == 0)
	{
		driver.SetShader("blackhole", false);
		return;
	}
	
	Vec2f screen = driver.getScreenDimensions();
	driver.SetShader("blackhole", true);
	driver.SetShaderFloat("blackhole", "screen_width", screen.x);
	driver.SetShaderFloat("blackhole", "screen_height", screen.y);
    driver.SetShaderFloat("blackhole", "zoom", getCamera().targetDistance);

    for (int i = 0; i < blackholes.length; i++)
	{
		BlackHole@ blackhole = blackholes[i];
		
		Vec2f screen_pos = driver.getScreenPosFromWorldPos(blackhole.world_pos);
		Vec2f screen_uv(screen_pos.x / screen.x, 1.0f - (screen_pos.y / screen.y));

		driver.SetShaderFloat("blackhole", "blackholes["+i+"].x", screen_uv.x);
		driver.SetShaderFloat("blackhole", "blackholes["+i+"].y", screen_uv.y);
        driver.SetShaderFloat("blackhole", "blackholes["+i+"].intensity", blackhole.intensity);
	}

    driver.SetShaderFloat("blackhole", "count", blackholes.length);
}