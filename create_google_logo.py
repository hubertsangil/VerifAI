from PIL import Image, ImageDraw, ImageFont

# Create a 512x512 image with white background
img = Image.new('RGB', (512, 512), 'white')
draw = ImageDraw.Draw(img)

# Draw the Google "G" logo colors (simplified version)
# This is a simplified representation - the actual Google logo is more complex

# Create a simple "G" using arcs and shapes
# Background circle
center = (256, 256)
radius = 180

# Draw the "G" shape with Google colors
# Blue arc (top-right)
draw.pieslice([center[0]-radius, center[1]-radius, center[0]+radius, center[1]+radius], 
               -50, 130, fill='#4285F4', outline='#4285F4', width=40)

# Red arc (top-left)
draw.pieslice([center[0]-radius, center[1]-radius, center[0]+radius, center[1]+radius], 
               130, 220, fill='#EA4335', outline='#EA4335', width=40)

# Yellow arc (bottom-left)
draw.pieslice([center[0]-radius, center[1]-radius, center[0]+radius, center[1]+radius], 
               220, 310, fill='#FBBC05', outline='#FBBC05', width=40)

# Green arc (bottom-right)
draw.pieslice([center[0]-radius, center[1]-radius, center[0]+radius, center[1]+radius], 
               310, 400, fill='#34A853', outline='#34A853', width=40)

# Draw white circle in center to create ring effect
inner_radius = 140
draw.ellipse([center[0]-inner_radius, center[1]-inner_radius, 
              center[0]+inner_radius, center[1]+inner_radius], 
             fill='white', outline='white')

# Draw the horizontal bar of the "G" on the right side
bar_width = 100
bar_height = 40
bar_x = center[0]
bar_y = center[1] - bar_height // 2
draw.rectangle([bar_x, bar_y, bar_x + bar_width, bar_y + bar_height], 
               fill='#4285F4', outline='#4285F4')

# Draw vertical bar on right
vert_bar_width = 40
vert_bar_height = 100
vert_x = center[0] + bar_width - vert_bar_width
vert_y = center[1] - vert_bar_height // 2
draw.rectangle([vert_x, vert_y, vert_x + vert_bar_width, vert_y + vert_bar_height], 
               fill='#4285F4', outline='#4285F4')

# Save the image
img.save('assets/images/google_logo.png', 'PNG')
print("Google logo created successfully at assets/images/google_logo.png")
