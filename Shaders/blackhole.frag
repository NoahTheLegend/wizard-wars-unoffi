// BlackHole Shader

uniform sampler2D baseMap;
uniform float screen_width;
uniform float screen_height;
uniform float count;
uniform float zoom;

struct blackhole
{
    float x;
    float y;
    float intensity;
};

uniform blackhole blackholes[15];

const float strength = 0.3;  //distortion power  

void main()
{
    vec2 uv = gl_FragCoord.xy / vec2(screen_width, screen_height);
    vec2 offset = vec2(0.0);

    float aspect = screen_width / screen_height;

    int count_int = int(count);
    for (int i = 0; i < 15 && i < count_int; i++)
    {
        vec2 center = vec2(blackholes[i].x, blackholes[i].y);
        float radius = blackholes[i].intensity * zoom;
        vec2 dir = uv - center;
        dir.x *= aspect;
        float dist = length(dir);

        if (dist < radius && dist > 0.0)
        {
            float falloff = (radius - dist) / radius;
            dir = normalize(dir);
            dir.x /= aspect;
            offset -= dir * falloff * strength;
        }
    }

    gl_FragColor = texture2D(baseMap, uv + offset);
}
