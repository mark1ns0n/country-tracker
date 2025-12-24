from PIL import Image, ImageDraw
import math

size = 1024
img = Image.new('RGBA', (size, size), (20, 105, 180, 255))  # blue background

draw = ImageDraw.Draw(img)
# draw simple globe: white circle and latitude/longitude lines
margin = 80
cx, cy, r = size//2, size//2, size//2 - margin

draw.ellipse((cx-r, cy-r, cx+r, cy+r), outline=(255,255,255,255), width=24)
# latitude lines
for k in [-0.6, -0.3, 0.0, 0.3, 0.6]:
    y = cy + int(r * k)
    rx = int(r * (1 - (k*k)))
    draw.ellipse((cx-rx, y-40, cx+rx, y+40), outline=(255,255,255,200), width=10)
# longitude lines
for k in range(0, 6):
    angle = k * (math.pi/6)
    sx = int(r * 0.95 * math.sin(angle))
    draw.line((cx-sx, cy-r, cx+sx, cy+r), fill=(255,255,255,200), width=10)

out = '/Users/mark1ns0n/projects/m/country-tracker/CountryDaysTracker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png'
img.save(out, format='PNG')
print('Saved', out)
