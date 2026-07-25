import os
from PIL import Image, ImageDraw, ImageFont

# Define paths
BASE_DIR = r"D:\Coding\ASCOA\Trash_Monitoring_App\store_assets"
FONTS = [
    r"C:\Windows\Fonts\segoeuib.ttf",  # Segoe UI Bold
    r"C:\Windows\Fonts\arialbd.ttf",   # Arial Bold
]

# Select a working font
font_path = None
for f in FONTS:
    if os.path.exists(f):
        font_path = f
        break

# Captions mapping
CAPTIONS = {
    "1_dashboard.png": "Track cleanups in your community",
    "2_new_cleanup.png": "Log waste items by count",
    "3_stats_charts.png": "Visualize your impact with charts",
    "4_stats_map.png": "Map cleanup sites & hotspots",
    "5_profile.png": "Manage your volunteer profile"
}

# Configuration for devices
DEVICES = {
    "phone": {
        "width": 1080,
        "height": 1920,
        "screenshot_w": 820,
        "bezel": 18,
        "radius": 36,
        "font_size": 48,
        "y_offset": 320
    },
    "tablet_7": {
        "width": 1200,
        "height": 1920,
        "screenshot_w": 920,
        "bezel": 22,
        "radius": 40,
        "font_size": 52,
        "y_offset": 320
    },
    "tablet_10": {
        "width": 1600,
        "height": 2560,
        "screenshot_w": 1240,
        "bezel": 30,
        "radius": 50,
        "font_size": 72,
        "y_offset": 420
    }
}

def create_mockup(device_name, filename):
    print(f"Processing {device_name}/{filename}...")
    cfg = DEVICES[device_name]
    input_path = os.path.join(BASE_DIR, device_name, filename)
    output_filename = filename.replace(".png", "_playstore.png")
    output_path = os.path.join(BASE_DIR, device_name, output_filename)

    if not os.path.exists(input_path):
        print(f"File not found: {input_path}")
        return

    # Load screenshot
    screenshot = Image.open(input_path).convert("RGBA")
    
    # Scale screenshot to target width while preserving aspect ratio
    aspect = screenshot.height / screenshot.width
    ss_w = cfg["screenshot_w"]
    ss_h = int(ss_w * aspect)
    screenshot = screenshot.resize((ss_w, ss_h), Image.Resampling.LANCZOS)

    # Create canvas
    canvas_w, canvas_h = cfg["width"], cfg["height"]
    canvas = Image.new("RGBA", (canvas_w, canvas_h), "#FBFFF4") # Brand background light green
    draw = ImageDraw.Draw(canvas)

    # Paste screenshot with rounded corners and device frame
    # Frame dimensions
    bezel = cfg["bezel"]
    frame_w = ss_w + (bezel * 2)
    frame_h = ss_h + (bezel * 2)
    
    # Coordinates to center frame
    frame_x = (canvas_w - frame_w) // 2
    frame_y = cfg["y_offset"]
    
    # Draw device frame (dark slate #18333D)
    frame_radius = cfg["radius"]
    draw.rounded_rectangle(
        (frame_x, frame_y, frame_x + frame_w, frame_y + frame_h),
        radius=frame_radius,
        fill="#18333D"
    )

    # Paste screenshot inside the frame (crop screenshot with smaller radius)
    ss_x = frame_x + bezel
    ss_y = frame_y + bezel
    
    mask = Image.new("L", (ss_w, ss_h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        (0, 0, ss_w, ss_h),
        radius=frame_radius - bezel // 2,
        fill=255
    )
    
    canvas.paste(screenshot, (ss_x, ss_y), mask=mask)

    # Draw speaker slot & camera punch-hole on phone to look more realistic
    if device_name == "phone":
        # Camera punch-hole
        cam_size = 12
        cam_x = canvas_w // 2
        cam_y = frame_y + bezel // 2
        draw.ellipse((cam_x - cam_size//2, cam_y - cam_size//2, cam_x + cam_size//2, cam_y + cam_size//2), fill="#000000")
    
    # Draw text caption at the top
    caption = CAPTIONS.get(filename, "")
    if caption:
        # Load font
        if font_path:
            font = ImageFont.truetype(font_path, cfg["font_size"])
        else:
            font = ImageFont.load_default()

        # Wrap text if too long
        words = caption.split(" ")
        lines = []
        current_line = []
        for word in words:
            current_line.append(word)
            test_line = " ".join(current_line)
            # check width
            w = draw.textlength(test_line, font=font)
            if w > (canvas_w - 100):
                current_line.pop()
                lines.append(" ".join(current_line))
                current_line = [word]
        lines.append(" ".join(current_line))

        # Render text lines
        text_y = 100 if device_name != "tablet_10" else 150
        for line in lines:
            text_w = draw.textlength(line, font=font)
            text_x = (canvas_w - text_w) // 2
            draw.text((text_x, text_y), line, fill="#18333D", font=font)
            text_y += cfg["font_size"] + 12

    # Save output
    canvas.convert("RGB").save(output_path, "PNG")
    print(f"Saved: {output_path}")

# Run for all devices and screenshots
if __name__ == "__main__":
    for device in DEVICES.keys():
        for filename in CAPTIONS.keys():
            create_mockup(device, filename)
    print("Finished generating mockups!")
