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

const float strength = 0.3;
const float core_fraction = 0.5;
const float fade_fraction = 0.2;

void main()
{
    vec2 uv = gl_FragCoord.xy / vec2(screen_width, screen_height);
    vec4 baseColor = texture2D(baseMap, uv);
    vec2 offset = vec2(0.0);

    float aspect = screen_width / screen_height;
    int count_int = int(count);

    float blackFactor = 0.0;

    for (int i = 0; i < 15 && i < count_int; i++)
    {
        vec2 center = vec2(blackholes[i].x, blackholes[i].y);
        
        float radius = blackholes[i].intensity * zoom;

        vec2 dir = uv - center;
        dir.x *= aspect;
        float dist = length(dir);

        float fadeStart = radius * core_fraction;
        float fadeEnd   = radius * (core_fraction + fade_fraction);

        if (dist < fadeStart)
        {
            blackFactor = 1.0;
        }

        else if (dist < fadeEnd)
        {
            float t = (dist - fadeStart) / (fadeEnd - fadeStart);
            blackFactor = max(blackFactor, 1.0 - t);
        }

        if (dist < radius && dist > 0.0)
        {
            float falloff = (radius - dist) / radius;
            dir = normalize(dir);
            dir.x /= aspect;
            offset -= dir * falloff * strength;
        }
    }

    vec4 distortedColor = texture2D(baseMap, uv + offset);
    gl_FragColor = mix(distortedColor, vec4(0.0, 0.0, 0.0, 1.0), blackFactor);
}
