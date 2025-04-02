void makeSineSparks(Vec2f pos, uint amount, f32 width, f32 height, SColor color,
	f32 narrow_top = 1.0f, f32 narrow_bottom = 1.0f, f32 narrow_center = 1.0f,
	f32 spin_speed_factor = 1.0f, f32 damp = 1.0f, f32 lifetime = 3,
    u8 style = SineStyle::linear, u32 seed = 0, Vec2f lean_pos = Vec2f_zero, f32 max_distance_to_lean = 156.0f)
{
	uint gt = getGameTime();

	f32 baseAngle = getGameTime() * 0.1f * spin_speed_factor;
	f32 heightFactor = (2.0f - narrow_center);

	for (int i = 0; i < (v_fastrender ? amount / 3 : amount); i++)
	{
		f32 angle = baseAngle + i * ((gt * 0.001f) % 45 + (seed % 45) + (seed % 270)) * 0.1f * spin_speed_factor;

		f32 yOffset = Maths::Cos(i * 0.4f) * height * 0.5f;
		f32 heightRatio = (2.0f * yOffset / height);

		f32 widthAtHeight;
		if (heightRatio < 0.0f)
		{
			widthAtHeight = width * Maths::Lerp(narrow_center, narrow_top, -heightRatio * heightFactor);
		}
		else
		{
			widthAtHeight = width * Maths::Lerp(narrow_center, narrow_bottom, heightRatio * heightFactor);
		}

		switch (style)
		{
			case SineStyle::easeinout:
				widthAtHeight *= 0.5f + 0.5f * (1.0f - EaseInOut(Maths::Abs(heightRatio)));
				break;
			case SineStyle::easein:
            {
                if (heightRatio < 0.0f)
		        {
		        	widthAtHeight = width * Maths::Lerp(narrow_center, narrow_top / 16, -heightRatio * heightFactor);
		        }
		        else
		        {
		        	widthAtHeight = width * Maths::Lerp(narrow_center, narrow_bottom / 16, heightRatio * heightFactor);
		        }
				widthAtHeight *= 0.5f + 2.0f * EaseIn(Maths::Abs(heightRatio));
				break;
            }
			case SineStyle::easeout:
				widthAtHeight *= 0.5f + 0.5f * EaseOut(Maths::Abs(heightRatio));
				break;
			default: // linear
				break;
		}

		f32 xOffset = widthAtHeight / heightFactor * Maths::Cos(angle);
		f32 zOffset = 10000 * Maths::Sin(angle);

		Vec2f offset = Vec2f(xOffset, yOffset);
		Vec2f pVel = Vec2f(0, 0).RotateByDegrees(angle);
        
        Vec2f extra_offset = Vec2f(0, 0);
        if (lean_pos != Vec2f_zero && (lean_pos - (pos + offset)).Length() < max_distance_to_lean)
        {
            Vec2f dir = lean_pos - pos;
            f32 distance = dir.Length();
            Vec2f rel_dir = offset;
            rel_dir.Normalize();

            f32 mod = 0.01f * Maths::Clamp(dir.Length()/58.0f, 0.0f, 1.0f);

            if ((lean_pos - (pos + offset)).Length() < distance && (dir.x * rel_dir.x + dir.y * rel_dir.y) > 0)
            {
                dir.Normalize();
                f32 edgeFactor = Maths::Clamp(offset.Length() / distance, 0.0f, 1.0f);
                f32 forceFactor = Maths::Clamp(1.0f - (offset.Length() / distance), 0.0f, 1.0f);

                Vec2f particleDir = offset;
                particleDir.Normalize();
                f32 angleDiff = Maths::Abs(Maths::ACos(particleDir * dir) / Maths::Pi);
                f32 angleFactor = 1.0f - Maths::Clamp(angleDiff, 0.0f, 1.0f);

                extra_offset = dir * mod * edgeFactor * forceFactor * Maths::Pow((angleFactor * 4), 6.0f + (Maths::Sin(Maths::Cos(gt * 0.1f)) + 1.0f) * 0.5f);
			}
        }

		CParticle@ p = ParticlePixelUnlimited(pos + offset + extra_offset, pVel, color, true);
		if (p !is null)
		{
			p.gravity = Vec2f(0, 0);
			p.timeout = lifetime;
			p.Z = -100 + zOffset;
			p.collides = false;
			p.bounce = 0.0f;
			p.fastcollision = true;
			p.damping = damp;
		}
	}
}

f32 EaseIn(f32 t)
{
	return 1.0f - Maths::Sqrt(1.0f - t * t);
}

f32 EaseOut(f32 t)
{
	return t * (2.0f - t);
}

f32 EaseInOut(f32 t)
{
	return t < 0.5f ? 2.0f * t * t : -1.0f + (4.0f - 2.0f * t) * t;
}

uint getSineSeed(uint id)
{
	return (id * 0x5DEECE66D) & ((1 << 48) - 1);
}

namespace SineStyle
{
	enum Style
	{
		linear,
		easeinout,
		easein,
		easeout
	};
}