import os
from PIL import Image

width, height = 3300, 3300
square_size = 55

img = Image.new('RGB', (width, height))
pixels = img.load()
# Colorful but muted (eye-friendly)
color1 = (85, 55, 105)  # Soft mid-dark purple
color2 = (130, 90, 60)  # Soft terracotta orange

for y in range(height):
    for x in range(width):
        grid_x = x // square_size
        grid_y = y // square_size
        if (grid_x + grid_y) % 2 == 0:
            pixels[x, y] = color1
        else:
            pixels[x, y] = color2

img.save(r'c:\Users\avser\OneDrive\Desktop\Nimute\Assets\circus_bg2.png')
print("circus_bg2.png created.")
