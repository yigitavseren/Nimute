import os
from PIL import Image

width, height = 3300, 3300
square_size = 55

img = Image.new('RGB', (width, height))
pixels = img.load()

# Darkened colors to reduce eye strain
color1 = (65, 20, 85)   # Deep Purple
color2 = (135, 75, 25)  # Dark Orange

for y in range(height):
    for x in range(width):
        grid_x = x // square_size
        grid_y = y // square_size
        if (grid_x + grid_y) % 2 == 0:
            pixels[x, y] = color1
        else:
            pixels[x, y] = color2

img.save(r'c:\Users\avser\OneDrive\Desktop\Nimute\Assets\circus_bg.png')
print("circus_bg.png updated with 55x55 squares and 3300x3300 size.")
