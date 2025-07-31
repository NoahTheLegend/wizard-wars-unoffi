void Setup(SColor ImageColor, string test_name, bool is_fuzzy, bool override_tex = false)
{
	//ensure texture for our use exists
	if(!Texture::exists(test_name))
	{
		if(!Texture::createBySize(test_name, 8, 8))
		{
			warn("texture creation failed");
		}
		else
		{
			ImageData@ edit = Texture::data(test_name);

			for(int i = 0; i < edit.size(); i++)
			{
				edit[i] = ImageColor;
				
				if(is_fuzzy)
				{
					if(i / edit.width() == 0)//Top 
						edit[i].setAlpha(100);
					else if(i % edit.height() == 0)// Left 
						edit[i].setAlpha(100);
					else if(i % edit.width() == 0)//Right 
						edit[i].setAlpha(100);					
					else if(i >= edit.width() * edit.height() - edit.width())//Bottom 
						edit[i].setAlpha(100);
					
					else if(i / edit.width() == 1)//Top
						edit[i].setAlpha(160);
					else if(i % edit.height() == 1)//???? 
						edit[i].setAlpha(160);
					else if(i % edit.width() == 1)//Right?
						edit[i].setAlpha(160);					
					else if(i >= edit.width() * edit.height() - edit.width() - edit.width())//Bottom 
						edit[i].setAlpha(160);
				}
			}

			if(!Texture::update(test_name, edit))
			{
				warn("texture update failed");
			}
		}
	}

	if (override_tex)
	{
		ImageData@ edit = Texture::data(test_name);
		
		for(int i = 0; i < edit.size(); i++)
		{
			edit[i] = ImageColor;
		}

		Texture::update(test_name, edit);
	}
}

void SetupImage(string texture, SColor ImageColor, string test_name, bool is_fuzzy = false, bool override_tex = false, Vec2f framePos = Vec2f_zero, Vec2f frameSize = Vec2f_zero)
{
	CFileImage@ image = CFileImage(texture);
	if (image is null)
	{
		warn("Failed to load image: " + texture);
		return;
	}

	bool tex_exists = Texture::exists(test_name);
	if (!override_tex && tex_exists)
	{
		return;
	}
	
	if (frameSize == Vec2f_zero)
	{
		frameSize = Vec2f(image.getWidth(), image.getHeight());
	}
	
	ImageData@ data = TransformImageToImageData(image, ImageColor, framePos, frameSize);
	if (!Texture::createBySize(test_name, data.width(), data.height()))
	{
		warn("Failed to create texture for image data");
	}
	else
	{
		if (!Texture::update(test_name, data))
		{
			warn("Failed to update texture: " + test_name);
		}
	}
}

ImageData@ TransformImageToImageData(CFileImage@ image, SColor color, Vec2f framePos = Vec2f_zero, Vec2f frameSize = Vec2f_zero)
{
	if (image is null)
	{
		warn("Image is null");
		return null;
	}
	
	if (frameSize == Vec2f_zero)
	{
		frameSize = Vec2f(image.getWidth(), image.getHeight());
	}

	int frameWidth = int(frameSize.x);
	int frameHeight = int(frameSize.y);
	ImageData@ data = @ImageData(frameWidth, frameHeight);
	
	int frameX = int(framePos.x);
	int frameY = int(framePos.y);
	
	while (image.nextPixel())
	{
		int offset = image.getPixelOffset();
		int x = offset % image.getWidth();
		int y = offset / image.getWidth();
		
		if (x >= frameX && x < frameX + frameWidth && 
			y >= frameY && y < frameY + frameHeight)
		{
			SColor col = image.readPixel();
			col.setAlpha(Maths::Min(color.getAlpha(), col.getAlpha()));
			col.setRed(Maths::Min(color.getRed(), col.getRed()));
			col.setGreen(Maths::Min(color.getGreen(), col.getGreen()));
			col.setBlue(Maths::Min(color.getBlue(), col.getBlue()));
			
			int frameRelativeX = x - frameX;
			int frameRelativeY = y - frameY;
			
			data.put(frameRelativeX, frameRelativeY, col);
		}
	}

	return data;
}