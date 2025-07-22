
Vec2f getRandomFloorLocationOnMap(uint seed, Vec2f from_pos)
{
    CMap@ map = getMap();
    if (map is null) return Vec2f_zero;

    f32 x = map.tilemapwidth * map.tilesize - 32;
    f32 y = map.tilemapheight * map.tilesize - 16;

    Random r(seed);
    Vec2f pos;
    for (int i = 0; i < 255; i++)
    {
        pos = Vec2f(f32(r.NextRanged(x)) - 16.0f, f32(r.NextRanged(y)) - 8.0f);
        if ((from_pos - pos).Length() < 128.0f)
            continue;
        
        if (map.isTileSolid(map.getTile(pos)))
            continue;
        
        Vec2f floor = pos;
        if (map.rayCastSolid(pos, pos + Vec2f(0, map.tilesize * 0.5f), floor))
        {
            return floor - Vec2f(0, 16.0f);
        }
    }

    return pos;
}

CBlob@ createWarpPortal(uint seed, Vec2f position, Vec2f at = getRandomFloorLocationOnMap(seed, position))
{
    CMap@ map = getMap();
    if (map is null) return null;

    CBlob@ portal = server_CreateBlob("p_warp_field", 3, at);
    if (portal !is null)
    {
        int seed = at.x * at.y;
        portal.setPosition(at);
        portal.set_Vec2f("next_warp_portal_pos", getRandomFloorLocationOnMap(seed, at));
    }

    return portal;
}