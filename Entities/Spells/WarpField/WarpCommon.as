Vec2f getRandomFloorLocationOnMap(uint seed, Vec2f from_pos)
{
    CMap@ map = getMap();
    if (map is null) return Vec2f_zero;

    f32 x = map.tilemapwidth * map.tilesize - 64;
    f32 y = map.tilemapheight * map.tilesize - 32;

    Random r(seed);
    Vec2f pos;
    for (int i = 0; i < 55; i++)
    {
        pos = Vec2f(f32(r.NextRanged(x)) + 32.0f, f32(r.NextRanged(y)) + 16.0f);
        if ((from_pos - pos).Length() < 128.0f)
        {
            continue;
        }
        if (map.isTileSolid(map.getTile(pos)) || map.isTileSolid(map.getTile(pos + Vec2f(0, 8))) || map.isTileSolid(map.getTile(pos + Vec2f(0, -8))))
        {
            continue;
        }

        Vec2f floor = pos;
        if (map.rayCastSolid(pos, pos + Vec2f(0, map.tilemapheight * 0.25f), floor))
        {
            Vec2f nearestEmptySpace = findClosestEmptySpace(map, floor, 8);
            if (nearestEmptySpace == Vec2f_zero) return floor - Vec2f(0, 16);
            
            return nearestEmptySpace - Vec2f(0, 16);
        }
    }

    return pos;
}

Vec2f findClosestEmptySpace(CMap@ map, Vec2f pos, int radius)
{
    const float tile_size = 8.0f;

    if (!map.isTileSolid(map.getTile(pos)))
    {
        return pos;
    }

    for (int r = 1; r <= radius; r++)
    {
        for (int i = 0; i < r; i++)
        {
            Vec2f[] tile_offsets = {
                Vec2f(i,  r - i),
                Vec2f(-(r - i),  i),
                Vec2f(-i, -(r - i)),
                Vec2f(r - i, -i)
            };

            for (u8 j = 0; j < 4; j++)
            {
                Vec2f check_pos = pos + tile_offsets[j] * tile_size;
                if (!map.isTileSolid(map.getTile(check_pos)))
                {
                    return check_pos;
                }
            }
        }
    }

    return Vec2f_zero;
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