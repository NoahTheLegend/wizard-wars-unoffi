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

void SetupImage(string texture, SColor ImageColor, string test_name, bool is_fuzzy = false, bool override_tex = false)
{
	CFileImage@ image = CFileImage(texture);
	if (image is null)
	{
		warn("Failed to load image: " + texture);
		return;
	}

	if (Texture::exists(test_name) && !override_tex)
	{
		return;
	}

	ImageData@ data = TransformImageToImageData(image, ImageColor);
	if (!Texture::update(test_name, data))
	{
		warn("Failed to update texture: " + test_name);

		if (!Texture::createBySize(test_name, data.width(), data.height()))
		{
			warn("Failed to create texture for image data");
		}
	}
}

ImageData@ TransformImageToImageData(CFileImage@ image, SColor color)
{
	if (image is null)
		return null;

	ImageData@ data = @ImageData(image.getWidth(), image.getHeight());
	for (int x = 0; x < data.width() * data.height(); x++)
	{
		if (image.nextPixel())
		{
			int offset = image.getPixelOffset();
			int x = offset % data.width();
			int y = offset / data.width();

			SColor col = image.readPixel();
			col.setAlpha(Maths::Min(color.getAlpha(), col.getAlpha()));
			col.setRed(Maths::Min(color.getRed(), col.getRed()));
			col.setGreen(Maths::Min(color.getGreen(), col.getGreen()));
			col.setBlue(Maths::Min(color.getBlue(), col.getBlue()));
			data.put(x, y, col);
		}
	}

	return data;
}