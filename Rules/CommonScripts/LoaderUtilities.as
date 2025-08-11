// LoaderUtilities.as

#include "DummyCommon.as";

// use this script only in pair with LoaderUtilities.as
bool rope_map_updated = false;
u8[][] MAP_TILES;

enum MapTileType
{
    MAP_TILE_NONE = 0,
    MAP_TILE_SOLID = 1,
    MAP_TILE_SOLID_BLOB_0 = 2,
    MAP_TILE_SOLID_BLOB_1 = 3,
    MAP_TILE_SOLID_BLOB_2 = 4,
    MAP_TILE_SOLID_BLOB_3 = 5,
    MAP_TILE_SOLID_BLOB_4 = 6,
    MAP_TILE_SOLID_BLOB_5 = 7,
    MAP_TILE_SOLID_BLOB_6 = 8,
    MAP_TILE_SOLID_BLOB_N = 9,
};

void ResetRopeMap(CMap@ map)
{
    int width = map.tilemapwidth;
    int height = map.tilemapheight;

    u8[][] new_MAP_TILES(width, u8[](height, MapTileType::MAP_TILE_NONE));
    MAP_TILES = new_MAP_TILES;

    error("Resetting rope map with size x("+width+") y("+height+")\narr_x("+new_MAP_TILES.length+") arr_y("+new_MAP_TILES[0].length+")");
    SaveMap(map);
}

void UpdateMap(CMap@ map, int offset, u16 tileType)
{
    if (MAP_TILES.size() == 0 || MAP_TILES[0].size() == 0)
    {
        ResetRopeMap(map);
    }
    
    int width = map.tilemapwidth;
    int height = map.tilemapheight;

    int x = offset % width;
    int y = offset / width;

    if (x < 0 || x >= width || y < 0 || y >= height)
    {
        return;
    }
    
    u8 type = map.isTileSolid(tileType) ? MapTileType::MAP_TILE_SOLID : MapTileType::MAP_TILE_NONE;
    MAP_TILES[x][y] = type;

    map.Tag("rope_map_updated");
}

void SaveMap(CMap@ map)
{
    map.set("rope_map", MAP_TILES);
}

void onTick(CMap@ map)
{
	if (getGameTime() != 0 && map.hasTag("rope_map_updated"))
	{
		map.Untag("rope_map_updated");
		SaveMap(getMap());
	}
}

bool onMapTileCollapse(CMap@ map, u32 offset)
{
	int x = offset % map.tilemapwidth;
	int y = offset / map.tilemapwidth;

	if (!(x < 0 || x >= map.tilemapwidth || y < 0 || y >= map.tilemapheight))
	{
		if (MAP_TILES.size() > 0 && MAP_TILES[0].size() > 0)
		{
			if (x < MAP_TILES.length && y < MAP_TILES[0].length)
			{
				MAP_TILES[x][y] = MapTileType::MAP_TILE_NONE;
			}
		}
		
		map.Tag("rope_map_updated");
	}

	if (isDummyTile(map.getTile(offset).type))
	{
		CBlob@ blob = getBlobByNetworkID(server_getDummyGridNetworkID(offset));

		if (blob !is null)
		{
			blob.server_Die();
		}
	}
	
	return true;
}

void onSetTile(CMap@ map, u32 index, TileType tile_new, TileType tile_old)
{
    UpdateMap(map, index, tile_new);

	if(isDummyTile(tile_new))
	{
		map.SetTileSupport(index, 10);

		switch(tile_new)
		{
			case Dummy::SOLID:
			case Dummy::OBSTRUCTOR:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				break;
			case Dummy::BACKGROUND:
			case Dummy::OBSTRUCTOR_BACKGROUND:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::WATER_PASSES);
				break;
			case Dummy::LADDER:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::LADDER | Tile::WATER_PASSES);
				break;
			case Dummy::PLATFORM:
				map.AddTileFlag(index, Tile::PLATFORM);
				break;
		}
	}
}