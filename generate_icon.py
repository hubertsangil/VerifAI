"""
Generate app icon for VerifAI
Creates a simple icon with a shield/verified badge design
"""
from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon():
    # Create 1024x1024 icon (standard size)
    size = 1024
    
    # Main icon (solid background with shield)
    img = Image.new('RGB', (size, size), '#1976D2')
    draw = ImageDraw.Draw(img)
    
    # Draw a white shield/badge shape
    shield_color = '#FFFFFF'
    center_x, center_y = size // 2, size // 2
    shield_size = size * 0.6
    
    # Shield points (simplified verified badge)
    margin = (size - shield_size) // 2
    points = [
        (center_x, margin + 50),  # Top
        (margin + shield_size - 100, margin + 150),  # Top right
        (margin + shield_size - 50, center_y),  # Right
        (margin + shield_size - 100, margin + shield_size - 100),  # Bottom right
        (center_x, margin + shield_size),  # Bottom
        (margin + 100, margin + shield_size - 100),  # Bottom left
        (margin + 50, center_y),  # Left
        (margin + 100, margin + 150),  # Top left
    ]
    
    draw.polygon(points, fill=shield_color)
    
    # Draw checkmark in the center
    check_color = '#1976D2'
    check_width = 60
    
    # Checkmark short line (going down-right)
    check_start_x = center_x - 120
    check_start_y = center_y + 20
    check_mid_x = center_x - 40
    check_mid_y = center_y + 120
    
    draw.line([(check_start_x, check_start_y), (check_mid_x, check_mid_y)], 
              fill=check_color, width=check_width)
    
    # Checkmark long line (going up-right)
    check_end_x = center_x + 150
    check_end_y = center_y - 100
    
    draw.line([(check_mid_x, check_mid_y), (check_end_x, check_end_y)], 
              fill=check_color, width=check_width)
    
    # Save main icon
    img.save('assets/icon/app_icon.png')
    print('✓ Created app_icon.png')
    
    # Create foreground icon for adaptive icon (transparent background)
    img_fg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw_fg = ImageDraw.Draw(img_fg)
    
    # Draw white shield on transparent background
    draw_fg.polygon(points, fill=(255, 255, 255, 255))
    
    # Draw checkmark
    draw_fg.line([(check_start_x, check_start_y), (check_mid_x, check_mid_y)], 
                 fill=(25, 118, 210, 255), width=check_width)
    draw_fg.line([(check_mid_x, check_mid_y), (check_end_x, check_end_y)], 
                 fill=(25, 118, 210, 255), width=check_width)
    
    img_fg.save('assets/icon/app_icon_foreground.png')
    print('✓ Created app_icon_foreground.png')
    print('\nIcons created successfully! Run: flutter pub get && flutter pub run flutter_launcher_icons')

if __name__ == '__main__':
    create_app_icon()
