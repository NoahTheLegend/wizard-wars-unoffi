shared class BlackHole
{
	Vec2f world_pos;
    f32 intensity;
	
	BlackHole(Vec2f&in world_pos, const f32&in intensity)
	{
		this.world_pos = world_pos;
        this.intensity = intensity;
	}
}
