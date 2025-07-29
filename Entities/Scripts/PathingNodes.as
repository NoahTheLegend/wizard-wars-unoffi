// Helper function to check if a position is a critical "corner" for navigation.
bool isCorner(const bool[]@ solid_neighbors)
{
    // "Outer" corner: a path goes around a solid corner.
    const bool is_outer_corner =
        (solid_neighbors[1] && solid_neighbors[3] && !solid_neighbors[0]) || // Top-Left
        (solid_neighbors[1] && solid_neighbors[4] && !solid_neighbors[2]) || // Top-Right
        (solid_neighbors[3] && solid_neighbors[6] && !solid_neighbors[5]) || // Bottom-Left
        (solid_neighbors[4] && solid_neighbors[6] && !solid_neighbors[7]);   // Bottom-Right

    // "Inner" corner: a path goes into a concave corner.
    const bool is_inner_corner =
        (!solid_neighbors[1] && !solid_neighbors[3] && solid_neighbors[0]) || // Top-Left
        (!solid_neighbors[1] && !solid_neighbors[4] && solid_neighbors[2]) || // Top-Right
        (!solid_neighbors[3] && !solid_neighbors[6] && solid_neighbors[5]) || // Bottom-Left
        (!solid_neighbors[4] && !solid_neighbors[6] && solid_neighbors[7]);   // Bottom-Right
        
    return is_outer_corner || is_inner_corner;
}

// Helper function to check for adjacent solid ground.
bool isAdjacentToSolid(Vec2f pos, CMap@ map)
{
    const int tilesize = 8; 
    const Vec2f[] check_dirs_cardinal = {
        Vec2f(tilesize, 0), Vec2f(0, tilesize),
        Vec2f(-tilesize, 0), Vec2f(0, -tilesize),
		Vec2f(tilesize, tilesize), Vec2f(-tilesize, tilesize),
		Vec2f(tilesize, -tilesize), Vec2f(-tilesize, -tilesize)
    };
    for (uint i = 0; i < check_dirs_cardinal.length; i++) {
        if (map.isTileSolid(pos + check_dirs_cardinal[i]))
            return true;
    }
    return false;
}

// Main Corrected Function
void InitializeNodeMap(CRules@ this)
{
    HighLevelNode@[] nodeMap;
    this.set("node_map", @nodeMap);
    
    CMap@ map = getMap();
    const Vec2f dim = map.getMapDimensions();
    const int tilesize = 8; 

    const int flat_spacing = 3;
    const int max_link_dist = 8 + Maths::Max(flat_spacing - 1, 0) * tilesize; // Maximum distance to link nodes
    const int RESET_POS = -99999; // Default value to reset spacing trackers

    dictionary potential_nodes;
    dictionary last_node_in_row;
    dictionary last_node_in_col;

    // --- PASS 1: NODE IDENTIFICATION ---
    for (int y = 0; y < dim.y; y += tilesize)
    {
        for (int x = 0; x < dim.x; x += tilesize)
        {
            Vec2f current_pos(x, y);
            if (map.isTileSolid(current_pos) || !isAdjacentToSolid(current_pos, map))
            {
                continue;
            }

            bool[] solid_neighbors(8);
            const Vec2f[] offsets = {
                Vec2f(-tilesize, -tilesize), Vec2f(0, -tilesize), Vec2f(tilesize, -tilesize),
                Vec2f(-tilesize, 0),                         Vec2f(tilesize, 0),
                Vec2f(-tilesize, tilesize),  Vec2f(0, tilesize),  Vec2f(tilesize, tilesize)
            };
            for (int n = 0; n < 8; ++n) {
                solid_neighbors[n] = map.isTileSolid(current_pos + offsets[n]);
            }

            bool should_create_node = false;

            // RULE 1: Always create a node at a corner.
            if (isCorner(solid_neighbors))
            {
                should_create_node = true;
            }
            // RULE 2: If not a corner, check for spaced surfaces.
            else 
            {
                // -- Horizontal surface check (Floors and Ceilings) --
                bool is_on_floor   = solid_neighbors[6] && !solid_neighbors[1];
                bool is_on_ceiling = solid_neighbors[1] && !solid_neighbors[6];
                
                if (is_on_floor || is_on_ceiling)
                {
                    int last_x = RESET_POS;
                    last_node_in_row.get("" + y, last_x);
                    if (x - last_x >= flat_spacing * tilesize) {
                        should_create_node = true;
                    }
                }
                
                // -- Vertical surface check (Walls) --
                bool is_on_left_wall  = solid_neighbors[3] && !solid_neighbors[4];
                bool is_on_right_wall = solid_neighbors[4] && !solid_neighbors[3];

                if (is_on_left_wall || is_on_right_wall)
                {
                    int last_y = RESET_POS;
                    last_node_in_col.get("" + x, last_y);
                    if (y - last_y >= flat_spacing * tilesize) {
                        should_create_node = true;
                    }
                }
            }

            // After deciding, create the node and update trackers
            if (should_create_node)
            {
                string node_key = x + "," + y;
                potential_nodes.set(node_key, true);
                
                last_node_in_row.set("" + y, x);
                last_node_in_col.set("" + x, y);
            }
            
            // **THE FIX**: If the current tile is NOT a surface, reset the trackers.
            // This prevents positions from old platforms affecting new ones after a gap.
            if (!solid_neighbors[6] && !solid_neighbors[1]) { // Not a floor or ceiling
                 last_node_in_row.set("" + y, RESET_POS);
            }
            if (!solid_neighbors[3] && !solid_neighbors[4]) { // Not a left or right wall
                 last_node_in_col.set("" + x, RESET_POS);
            }
        }
    }

    // --- PASS 2 & 3: NODE CREATION & CONNECTION (No changes here) ---
    string[] node_keys = potential_nodes.getKeys();
    for (uint i = 0; i < node_keys.length; i++) {
        string[] parts = node_keys[i].split(",");
        Vec2f nodepos(parseFloat(parts[0]), parseFloat(parts[1]));
        nodeMap.push_back(HighLevelNode(nodepos));
    }

    const Vec2f[] directions = {
        Vec2f(tilesize, 0), Vec2f(-tilesize, 0), Vec2f(0, tilesize), Vec2f(0, -tilesize),
        Vec2f(tilesize, tilesize), Vec2f(-tilesize, tilesize), Vec2f(tilesize, -tilesize), Vec2f(-tilesize, -tilesize)
    };
    
    for (uint i = 0; i < nodeMap.length; i++) {
        HighLevelNode@ node = nodeMap[i];
        for (uint d = 0; d < directions.length; d++) {
            Vec2f dir = directions[d];
            bool is_diagonal = (dir.x != 0 && dir.y != 0);
            for (int s = 1; s * tilesize <= max_link_dist; s++) {
                Vec2f search_pos = node.original_position + dir * s;
                if (search_pos.x < 0 || search_pos.x >= dim.x || search_pos.y < 0 || search_pos.y >= dim.y) break;
                if (map.isTileSolid(search_pos)) break; 
                if (is_diagonal) {
                    Vec2f corner1(search_pos.x - dir.x, search_pos.y);
                    Vec2f corner2(search_pos.x, search_pos.y - dir.y);
                    if (map.isTileSolid(corner1) || map.isTileSolid(corner2)) break;
                }
                string search_key = search_pos.x + "," + search_pos.y;
                if (potential_nodes.exists(search_key)) {
                    for (uint j = 0; j < nodeMap.length; j++) {
                        if (nodeMap[j].original_position == search_pos) {
                            node.connections.push_back(nodeMap[j]);
                            break; 
                        }
                    }
                    break;
                }
            }
        }
    }
    
    // --- PASS 4: MAKE CONNECTIONS BIDIRECTIONAL (No changes here) ---
    for(uint i=0; i < nodeMap.length; i++) {
        HighLevelNode@ node = nodeMap[i];
        for(uint k=0; k < node.connections.length; k++) {
            HighLevelNode@ neighbor = node.connections[k];
            bool connection_exists = false;
            for(uint j = 0; j < neighbor.connections.length; j++) {
                if (neighbor.connections[j] is node) {
                    connection_exists = true;
                    break;
                }
            }
            if (!connection_exists) {
                neighbor.connections.push_back(node);
            }
        }
        node.original_connections = node.connections;
    }
    
    HighLevelNode@[] node_update = nodeMap;
    this.push("queued_node_updates", node_update);
}

// Gingerbeard @ January 16th, 2025
// Edited by NoahTheLegend

#define SERVER_ONLY
#include "PathingNodesCommon.as";

void onInit(CRules@ this)
{
	onRestart(this);
}

void onReload(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	HighLevelNode@[][] queued_node_updates;
	this.set("queued_node_updates", @queued_node_updates);

	InitializeNodeMap(this);
	
	CMap@ map = getMap();
	if (!map.hasScript(getCurrentScriptName()))
	{
		map.AddScript(getCurrentScriptName());
	}
}

dictionary visited_nodes;

void onSetTile(CMap@ map, u32 index, TileType newtile, TileType oldtile)
{
	if (map.isTileSolid(newtile) && map.isTileSolid(oldtile)) return;

	onMapTileCollapse(map, index);
}

void onMapFloodLayerUpdate(CMap@ map, s32 index) //STAGING ONLY as of march 6th, 2025
{
	onMapTileCollapse(map, index);
}

bool onMapTileCollapse(CMap@ map, u32 index)
{
	HighLevelNode@[]@ nodeMap;
	CRules@ rules = getRules();
	if (!rules.get("node_map", @nodeMap)) return true;

	Vec2f position = map.getTileWorldPosition(index);
	HighLevelNode@[] node_updates;
	HighLevelNode@[] nodes = getNodesInRadius(position, node_distance * 1.7f, nodeMap); //2.25f
	for (int i = 0; i < nodes.length; i++)
	{
		HighLevelNode@ node = nodes[i];
		const string node_key = node.original_position.toString();
		if (visited_nodes.exists(node_key)) continue;
		
		visited_nodes.set(node_key, true);
		node_updates.push_back(node);
	}

	if (node_updates.length != 0)
	{
		rules.push("queued_node_updates", node_updates);
	}
	
	return true;
}

void onTick(CRules@ this)
{
	HighLevelNode@[][]@ queued_node_updates;
	if (!this.get("queued_node_updates", @queued_node_updates)) return;

	if (queued_node_updates.length == 0) return;
	
	visited_nodes.deleteAll();
	
	const int index = queued_node_updates.length - 1;
	HighLevelNode@[] node_update = queued_node_updates[index];

	CMap@ map = getMap();
	for (int i = 0; i < node_update.length; i++)
	{
		UpdateNodePosition(node_update[i], map);
	}

	for (int i = 0; i < node_update.length; i++)
	{
		UpdateNodeConnections(node_update[i], map);
	}

	queued_node_updates.erase(index);
}

void UpdateNodeConnections(HighLevelNode@ node, CMap@ map)
{
	node.connections = node.original_connections;
	for (int i = node.connections.length - 1; i >= 0; i--)
	{
		HighLevelNode@ neighbor = node.connections[i];
		if (neighbor.hasFlag(Path::DISABLED) || !canNodesConnect(node, neighbor, map))
		{
			node.connections.erase(i);

			for (int n = neighbor.connections.length - 1; n >= 0; n--)
			{
				if (neighbor.connections[n] !is node) continue;

				neighbor.connections.erase(n);
				break;
			}
		}
	}
}

void UpdateNodePosition(HighLevelNode@ node, CMap@ map)
{
	node.position = node.original_position;
	node.flags = 0;

	// If the tile at the node's original position is no longer solid, disable the node
	if (map.isTileSolid(node.original_position))
	{
		node.flags = Path::DISABLED;
		return;
	}

	// Look for the nearest passable area in a small radius
	Vec2f dim = map.getMapDimensions();
	const u8 searchRadius = 4;
	Vec2f closestPos = node.original_position;
	f32 closestDistance = 999999.0f;

	for (int y = -searchRadius; y <= searchRadius; y++)
	{
		for (int x = -searchRadius; x <= searchRadius; x++)
		{
			if (x == 0 && y == 0) continue;

			Vec2f neighborPos = node.original_position + Vec2f(halfsize, halfsize);
			if (isInMap(neighborPos, dim))
			{
				const f32 distance = (neighborPos - node.original_position).LengthSquared();
				if (distance < closestDistance)
				{
					closestDistance = distance;
					closestPos = neighborPos;
				}
			}
		}
	}

	// If no passable area is found, mark the node as disabled
	if (closestDistance == 999999.0f)
	{
		node.flags = Path::DISABLED;
		return;
	}

	node.position = closestPos;
	node.flags |= Path::GROUND;
}

bool isSupported(Vec2f&in tilePos, CMap@ map)
{
	Vec2f dim = map.getMapDimensions();
	for (u8 i = 0; i < 4; i++)
	{
		// Are we adjacent to solid tiles
		Vec2f checkPos = tilePos + cardinalDirections[i] * 1.5;
		if (checkPos.x < dim.x && map.isTileSolid(checkPos)) return true;
	}

	if (map.isInWater(tilePos + Vec2f(0, tilesize))) return true;

	CBlob@[] blobs;
	Vec2f tile(halfsize, halfsize);
	if (map.getBlobsInBox(tilePos - tile, tilePos + tile, @blobs))
	{
		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			CShape@ shape = b.getShape();
			if (!shape.isStatic()) continue;

			if (shape.getVars().isladder) return true;

			// Check for adjacent tile-blobs
			if (shape.getConsts().collidable && (b.getPosition() - tilePos).Length() < 13.0f)
			{
				if (b.getName() == "lantern" || b.getName() == "mounted_bow") continue;

				if (b.isPlatform())
				{
					ShapePlatformDirection@ plat = b.getShape().getPlatformDirection(0);
					Vec2f dir = plat.direction;
					if (!plat.ignore_rotations) dir.RotateBy(b.getAngleDegrees());
					if (Maths::Abs(dir.AngleWith(b.getPosition() - tilePos)) > plat.angleLimit)
					{
						return true;
					}
					continue;
				}

				return true;
			}
		}
	}

	return false;
}

bool isInMap(Vec2f&in tilePos, Vec2f&in dim)
{
	return tilePos.x > 0 && tilePos.y > 0 && tilePos.x < dim.x && tilePos.y < dim.y;
}

void onRender(CRules@ this)
{
	if ((!render_paths && g_debug == 0) || g_debug == 5) return;
	
	HighLevelNode@[]@ nodeMap;
	if (!this.get("node_map", @nodeMap)) return;

	SColor nodeColor(255, 0, 255, 0);
	SColor connectionColor(255, 255, 0, 0);
	SColor airColor(255, 160, 160, 160);
	Driver@ driver = getDriver();
	Vec2f center = driver.getScreenCenterPos();
	Vec2f screen_dim = driver.getScreenDimensions();
	
	const u8 render_blacklist = Path::DISABLED | Path::AERIAL; //stops these types of path from rendering

	for (u32 i = 0; i < nodeMap.length; i++)
	{
		HighLevelNode@ node = nodeMap[i];
		if (node is null || node.hasFlag(render_blacklist)) continue;

		Vec2f pos = driver.getScreenPosFromWorldPos(node.position);
		if ((pos - center).Length() > screen_dim.x) continue;

		GUI::DrawCircle(pos, 4.0f, node.hasFlag(Path::AERIAL) ? airColor : nodeColor);

		for (u32 j = 0; j < node.connections.length; j++)
		{
			HighLevelNode@ neighbor = node.connections[j];
			if (neighbor is null || neighbor.hasFlag(render_blacklist)) continue;
			
			Vec2f neighborpos = driver.getScreenPosFromWorldPos(neighbor.position);
			GUI::DrawLine2D(pos, neighborpos, neighbor.hasFlag(Path::AERIAL) || node.hasFlag(Path::AERIAL) ? airColor :connectionColor);
		}
	}
}