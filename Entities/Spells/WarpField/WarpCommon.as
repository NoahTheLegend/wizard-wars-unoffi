
Vec2f getRandomFloorLocationOnMap(Vec2f from_pos)
{
    CMap@ map = getMap();
    if (map is null) return Vec2f_zero;

    f32 x = map.tilemapwidth * map.tilesize - 32;
    f32 y = map.tilemapheight * map.tilesize - 16;

    Vec2f pos;
    for (int i = 0; i < 255; i++)
    {
        pos = Vec2f(XORRandom(x) + 16, XORRandom(y) + 8);
        if ((from_pos - pos).Length() < 32.0f)
            continue;
        
        Vec2f floor = pos;
        if (map.rayCastSolid(pos, pos + Vec2f(0, map.tilesize * 0.1f), floor))
        {
            return floor - Vec2f(0, 8);
        }
    }

    return pos;
}

void createWarpPortal(Vec2f position)
{
    CMap@ map = getMap();
    if (map is null) return;

    CBlob@ portal = server_CreateBlob("warp_portal", -1, position);
    if (portal !is null)
    {
        portal.setPosition(position);
        portal.setVelocity(Vec2f(0, 0));
        portal.set_Vec2f("next_warp_portal_pos", getRandomFloorLocationOnMap(position));
    }
}