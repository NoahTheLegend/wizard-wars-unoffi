const float ROPE_DEFAULT_SEGMENT_LENGTH = 1.0f;
const u8    ROPE_DEFAULT_ITERATIONS = 15;
const u8    ROPE_DEFAULT_COLLISIONS = 1;
const Vec2f ROPE_DEFAULT_GRAVITY = Vec2f(0, 9.81f);
const float ROPE_DEFAULT_DAMPING = 0.98f;
const float ROPE_DEFAULT_FRICTION = 0.1f;
const int   ROPE_DEFAULT_NODE_COUNT = 30;
const float debug_radius = 20.0f;
const float deltaTime = 1.0f / 30.0f;
const float epsilon = 0.01f;

void onInit(CBlob@ this)
{
    this.set_u32("rope_node_count", ROPE_DEFAULT_NODE_COUNT);
    this.set_f32("rope_segment_length", ROPE_DEFAULT_SEGMENT_LENGTH);
    this.set_u8("rope_iterations", ROPE_DEFAULT_ITERATIONS);
    this.set_Vec2f("rope_gravity", ROPE_DEFAULT_GRAVITY);
    this.set_f32("rope_damping", ROPE_DEFAULT_DAMPING);
    this.set_f32("rope_FRICTION", ROPE_DEFAULT_FRICTION);
    this.set("rope_initialized", false);
}

void onReload(CBlob@ this)
{
    Rope rope(
        this.getPosition(),
        ROPE_DEFAULT_NODE_COUNT,
        ROPE_DEFAULT_SEGMENT_LENGTH,
        ROPE_DEFAULT_ITERATIONS,
        ROPE_DEFAULT_GRAVITY,
        ROPE_DEFAULT_DAMPING,
        ROPE_DEFAULT_FRICTION
    );
    this.set("rope", @rope);
}

bool debug_lctrl = false;
bool debug_key_e = false;
bool debug_key_r = false;

void onTick(CBlob@ this)
{
    debug_lctrl = getControls().isKeyPressed(KEY_LCONTROL);
    debug_key_e = getControls().isKeyPressed(KEY_KEY_E);
    debug_key_r = getControls().isKeyPressed(KEY_KEY_R);

    Rope@ rope;
    if (!this.get("rope", @rope))
    {
        Rope newRope(
            this.getPosition(),
            this.get_u32("rope_node_count"),
            this.get_f32("rope_segment_length"),
            this.get_u8("rope_iterations"),
            this.get_Vec2f("rope_gravity"),
            this.get_f32("rope_damping"),
            this.get_f32("rope_FRICTION")
        );
        this.set("rope", @newRope);
        return;
    }

    if (debug_key_e) return;
    rope.tick();
}

void onRender(CSprite@ sprite)
{
    Rope@ rope;
    CBlob@ blob = sprite.getBlob();
    if (blob !is null && blob.get("rope", @rope))
    {
        rope.render();
    }
}

class RopeSegment
{
    Vec2f pos;
    Vec2f oldpos;

    Vec2f debug_tile_touching;
    Vec2f debug_tile_edgepos;
    Vec2f debug_tile_normal;

    RopeSegment(Vec2f position)
    {
        pos = position;
        oldpos = position;
    }

    void debug_render()
    {
        Driver@ driver = getDriver();
        Vec2f debug_tile_touching_2d = driver.getScreenPosFromWorldPos(debug_tile_touching);
        Vec2f debug_tile_edgepos_2d = driver.getScreenPosFromWorldPos(debug_tile_edgepos);
        Vec2f debug_tile_normal_2d = driver.getScreenPosFromWorldPos(debug_tile_normal);
        
        int seed = Maths::Pow(debug_tile_touching.x / 8, 2);
        SColor debug_color(255, seed%125+125, 250-seed%250, 0);
        SColor debug_color_normal(255, 0, 255, 0);
        SColor debug_color_edge(255, 0, 255, 255);

        f32 zoom = getCamera().targetDistance;
        if (debug_tile_touching != Vec2f_zero)
        {
            GUI::DrawRectangle(
            Vec2f(debug_tile_touching_2d.x - 8 * zoom, debug_tile_touching_2d.y - 8 * zoom),
            Vec2f(debug_tile_touching_2d.x + 8 * zoom, debug_tile_touching_2d.y + 8 * zoom),
            debug_color
            );
        }

        if (debug_tile_touching != Vec2f_zero && debug_tile_edgepos != Vec2f_zero)
        {
            GUI::DrawLine2D(
            debug_tile_touching_2d,
            debug_tile_edgepos_2d,
            debug_color_edge
            );
        }
    }
};

class Rope
{
    Vec2f startPos;
    int nodeCount;
    float segmentLength;
    u8 iterations;
    Vec2f gravity;
    float dampingFactor;
    float friction;

    RopeSegment@[] nodes;

    Rope(Vec2f start, int maxnodes, float segLen, u8 iters, Vec2f grav, float damp, float frict)
    {
        startPos = start;
        nodeCount = maxnodes;
        segmentLength = segLen;
        iterations = iters;
        gravity = grav;
        dampingFactor = damp;
        friction = frict;

        for (int i = 0; i < nodeCount; i++)
        {
            Vec2f pos = startPos + Vec2f(0, i * segmentLength);
            RopeSegment@ node = RopeSegment(pos);
            nodes.push_back(@node);
        }
    }

    void tick()
    {
        CMap@ map = getMap();
        if (map is null) return;
        Step(map);

        for (int i = 0; i < iterations; i++)
        {
            ApplyConstraints();
        }

        u8[][]@ rope_map;
        if (!map.get("rope_map", @rope_map)) return;

        for (int i = 0; i < ROPE_DEFAULT_COLLISIONS; i++)
        {
            
        }
    }

    void Step(CMap@ map)
    {
        for (int i = 0; i < nodes.size(); i++)
        {
            RopeSegment@ node = nodes[i];
            if (node is null) continue;

            Vec2f vel = (node.pos - node.oldpos) * dampingFactor;
            Vec2f move_vec = vel + gravity * deltaTime;

            Vec2f move_dir = move_vec;
            float move_len = move_dir.Length();
            if (move_len > 0.001f)
            {
                move_dir /= move_len;
            }

            Vec2f perp_vec(-move_dir.y, move_dir.x);
            array<Vec2f> origins(3);
            origins[0] = node.pos;
            origins[1] = node.pos + perp_vec * epsilon;
            origins[2] = node.pos - perp_vec * epsilon;

            float min_dist_sq = -1.0f;
            Vec2f final_hitpos;
            Vec2f winning_ray_offset = Vec2f_zero;

            //for (int k = 0; k < 3; ++k)
            //{
            //    Vec2f hitpos;
            //    if (map.rayCastSolidNoBlobs(origins[k], origins[k] + move_vec, hitpos))
            //    {
            //        float dist_sq = (hitpos - origins[k]).LengthSquared();
            //        if (min_dist_sq < 0 || dist_sq < min_dist_sq)
            //        {
            //            min_dist_sq = dist_sq;
            //            final_hitpos = hitpos;
            //            winning_ray_offset = origins[k] - node.pos;
            //        }
            //    }
            //}

            node.oldpos = node.pos;

            if (min_dist_sq >= 0)
            {
                node.pos = final_hitpos - winning_ray_offset;

                Vec2f normal_check_pos = final_hitpos - move_dir * 0.01f;
                int tile_x = int(normal_check_pos.x / 8.0f);
                int tile_y = int(normal_check_pos.y / 8.0f);
                Vec2f tile_center(tile_x * 8.0f + 4.0f, tile_y * 8.0f + 4.0f);

                Vec2f normal = final_hitpos - tile_center;
                if (normal.LengthSquared() > 0)
                {
                    normal.Normalize();
                }

                Vec2f reflected_vel = Reflect(vel, normal) * (1.0f - friction);
                node.oldpos = node.pos - reflected_vel;
            }
            else
            {
                node.pos += move_vec;
            }
        }
    }

    void ApplyConstraints()
    {
        if (nodes.empty()) return;

        RopeSegment@ firstNode = nodes[0];
        RopeSegment@ lastNode = nodes[nodes.size() - 1];
        if (firstNode is null || lastNode is null) return;
        firstNode.pos = getControls().getMouseWorldPos();

        bool lastPinned = false;
        CBlob@ blob = getPlayer(0).getBlob();
        if (blob !is null && !blob.isKeyPressed(key_action1))
        {
            lastNode.pos = blob.getPosition();
            lastPinned = true;
        }

        for (int i = 0; i < nodes.size() - 1; i++)
        {
            RopeSegment@ nodeA = nodes[i];
            RopeSegment@ nodeB = nodes[i + 1];
            if (nodeA is null || nodeB is null) continue;

            Vec2f delta = nodeB.pos - nodeA.pos;
            float dist = delta.Length();
            float diff = dist - segmentLength;

            if (dist == 0) continue;
            delta /= dist;

            if (i == 0)
            {
                nodeB.pos -= delta * diff;
            }
            else if (lastPinned && i + 1 == nodes.size() - 1)
            {
                nodeA.pos += delta * diff;
            }
            else
            {
                nodeA.pos += delta * (diff * 0.5f);
                nodeB.pos -= delta * (diff * 0.5f);
            }
        }
    }
    
    for (int i = 0; i <= segmentCount; i++)
    {
    	Vec2f prev1 = prevPoints[i];
    	Vec2f curr1 = points[i];
    	Vec2f prev2 = prevPoints[i + 1];
    	Vec2f curr2 = points[i + 1];

    	Vec2f motion1 = curr1 - prev1;
    	Vec2f motion2 = curr2 - prev2;
    	Vec2f segStart = prev2 - prev1;
    	Vec2f segEnd = curr2 - curr1;
    	float segLength = segStart.Length();
    	if (segLength == 0) continue;

    	int samples = Maths::Max(2, Maths::Ceil(Maths::Max(motion1.Length(), motion2.Length()) / (tileSize * 0.5f)));
    	float earliestTOY = 1.0f;
    	Vec2f hitPoint, hitNormal;
    	bool hit = false;

    	for (int s = 0; s <= samples; s++)
    	{
    		float t = float(s) / float(samples);
    		Vec2f p1 = prev1 + motion1 * t;
    		Vec2f p2 = prev2 + motion2 * t;
    		Vec2f seg = p2 - p1;
    		int segSamples = Maths::Max(2, Maths::Ceil(seg.Length() / (tileSize * 0.5f)));

    		for (int u = 0; u <= segSamples; u++)
    		{
    			float uT = float(u) / float(segSamples);
    			Vec2f p = p1 + seg * uT;
    			if (map.isTileSolid(p))
    			{
    				// collided
    				if (t < earliestTOY)
    				{
    					earliestTOY = t;
    					hitPoint = p;
    					hitNormal = GetMapNormalAtPoint(p, prev1 + seg * uT);
    					hit = true;
    				}
    				break;
    			}
    		}
    	}

    	if (hit)
    	{
    		// set positions at time of impact
    		Vec2f newPos1 = prev1 + motion1 * earliestTOY;
    		Vec2f newPos2 = prev2 + motion2 * earliestTOY;

    		Vec2f vel1 = motion1 / dt;
    		Vec2f vel2 = motion2 / dt;

    		// sliding
    		float dot1 = vel1.x * hitNormal.x + vel1.y * hitNormal.y;
    		float dot2 = vel2.x * hitNormal.x + vel2.y * hitNormal.y;
    		Vec2f normalVel1 = hitNormal * dot1;
    		Vec2f normalVel2 = hitNormal * dot2;
    		Vec2f tangentVel1 = vel1 - normalVel1;
    		Vec2f tangentVel2 = vel2 - normalVel2;

    		//friction
    		tangentVel1 *= (1.0f - friction);
    		tangentVel2 *= (1.0f - friction);

    		Vec2f newVel1 = tangentVel1 - normalVel1 * 0.5f;
    		Vec2f newVel2 = tangentVel2 - normalVel2 * 0.5f;

    		points[i] = newPos1 + newVel1 * dt * (1.0f - earliestTOY);
    		points[i + 1] = newPos2 + newVel2 * dt * (1.0f - earliestTOY);

    		points[i] += hitNormal * radius * (1.0f - float(i) / float(segmentCount));
    		points[i + 1] += hitNormal * radius * (float(i) / float(segmentCount));
    	}

    	// static capsule penetration
    	Vec2f seg = points[i + 1] - points[i];
    	int overlapSamples = Maths::Max(2, Maths::Ceil(seg.Length() / (tileSize * 0.5f)));
    	for (int s = 0; s <= overlapSamples; s++)
    	{
    		float t = float(s) / float(overlapSamples);
    		Vec2f p = points[i] + seg * t;
    		if (map.isTileSolid(p))
    		{
    			Vec2f normal = GetMapNormalAtPoint(p, prevPoints[i] + (prevPoints[i + 1] - prevPoints[i]) * t);
    			points[i] += normal * radius * (1.0f - t);
    			points[i + 1] += normal * radius * t;
    			break;
    		}
    	}
    }

    Vec2f GetMapNormalAtPoint(Vec2f pos, Vec2f prevPos, u8[][]@ rope_map)
    {
        int x = int(pos.x / 8.0f);
        int y = int(pos.y / 8.0f);

        if (x < 0 || y < 0 || x >= rope_map.length || y >= rope_map[0].length)
            return Vec2f(0, 0);

    	Vec2f tilePos = rope_map[x][y] * 8.0f;
    	Vec2f tileMin = tilePos;
    	Vec2f tileMax = tilePos + Vec2f(tileSize, tileSize);
    	Vec2f tileCenter = tileMin + Vec2f(tileSize * 0.5f, tileSize * 0.5f);
    	Vec2f dir = prevPos - tileCenter;

    	if (Maths::Abs(dir.x) > Maths::Abs(dir.y))
    		return dir.x > 0 ? Vec2f(1, 0) : Vec2f(-1, 0);
    	else
    		return dir.y > 0 ? Vec2f(0, 1) : Vec2f(0, -1);
    }

    void render()
    {
        string textureName = "RopeSegment.png";
        Vec2f textureSize(40, 3);

        Vertex[] verts;
        float interp = getInterpolationFactor();

        for (int i = 0; i < nodes.size() - 1; i++)
        {
            RopeSegment@ segA = nodes[i];
            RopeSegment@ segB = nodes[i + 1];
            if (segA is null || segB is null) continue;
            segA.debug_render();

            Vec2f p1 = Vec2f_lerp(segA.oldpos, segA.pos, interp);
            Vec2f p2 = Vec2f_lerp(segB.oldpos, segB.pos, interp);
            Vec2f dir = p2 - p1;
            float length = dir.Length();
            if (length < 0.01f) continue;
            dir /= length;
            Vec2f perp(-dir.y, dir.x);
            Vec2f v1 = p1 + perp * (textureSize.y / 2.0f);
            Vec2f v2 = p1 - perp * (textureSize.y / 2.0f);
            Vec2f v3 = p2 - perp * (textureSize.y / 2.0f);
            Vec2f v4 = p2 + perp * (textureSize.y / 2.0f);
            verts.push_back(Vertex(v1.x, v1.y, 0, 0.0f, 0.0f, SColor(255, 255, 255, 255)));
            verts.push_back(Vertex(v2.x, v2.y, 0, 0.0f, 1.0f, SColor(255, 255, 255, 255)));
            verts.push_back(Vertex(v3.x, v3.y, 0, length / textureSize.x, 1.0f, SColor(255, 255, 255, 255)));
            verts.push_back(Vertex(v4.x, v4.y, 0, length / textureSize.x, 0.0f, SColor(255, 255, 255, 255)));

            GUI::DrawCircle(getDriver().getScreenPosFromWorldPos(p1), debug_radius, SColor(128, 255, 0, 0));
        }

        if (verts.size() > 0)
            Render::RawQuads(textureName, verts);
    }
};

Vec2f Reflect(Vec2f direction, Vec2f  normal)
{
    float dot = direction.x * normal.x + direction.y * normal.y;
    Vec2f scaledNormal = normal * (2.0f * dot);
    return direction - scaledNormal;
}