# Raspberry Pi Installation Guide

AlwaysOnAudioPlayer is a Flutter-based media player optimized for Raspberry Pi with 5-inch touchscreens.

## Features
- **Local Music Library**: Play audio files from your Raspberry Pi storage
- **Internet Radio**: Browse and stream thousands of radio stations worldwide
- **Curated Radio Stations**: Hand-picked quality stations including Arctic Outpost AM1270, KXLU 88.9 FM, and KEXP 90.3 FM
- **Playlist Management**: Create and manage playlists
- **Touch-Optimized UI**: Designed for 800x480 touchscreens with automatic scaling

## Hardware Requirements
- Raspberry Pi 3B+ or newer (Pi 4 or 5 recommended)
- 5-inch touchscreen display (800x480 recommended)
- 16GB+ SD card (32GB+ recommended for music storage)
- Audio output (3.5mm jack, HDMI, or USB audio)
- Internet connection (WiFi or Ethernet for radio streaming)

## Software Setup

### 1. Install Raspberry Pi OS
```bash
# Use Raspberry Pi Imager to install Raspberry Pi OS (64-bit recommended)
# Enable SSH and configure WiFi during setup
```

### 2. Update System
```bash
sudo apt update
sudo apt upgrade -y
```

### 3. Install Flutter Dependencies
```bash
# Install required libraries
sudo apt install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly gstreamer1.0-libav \
  gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa \
  gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-pulseaudio
```

### 4. Install Flutter
```bash
# Download Flutter SDK
cd ~
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
flutter doctor

# Enable Linux desktop support
flutter config --enable-linux-desktop
```

### 5. Clone and Build the App
```bash
# Clone the repository
git clone https://github.com/MicroSwitchers/AlwaysOnAudioPlayer.git
cd AlwaysOnAudioPlayer

# Get dependencies
flutter pub get

# Build for Linux (Release mode for better performance)
flutter build linux --release

# The executable will be in: build/linux/arm64/release/bundle/
```

### 6. Run the App
```bash
# Navigate to build directory
cd build/linux/arm64/release/bundle/

# Run the application
./always_on_audio_player
```

Note: The executable name may vary. Check the bundle directory for the actual filename.

## Performance Optimization

### 1. Disable Desktop Environment (Optional)
For best performance on 5" screen, run in kiosk mode:

```bash
# Install minimal window manager
sudo apt install -y openbox

# Create autostart script
mkdir -p ~/.config/openbox
cat > ~/.config/openbox/autostart << 'EOF'
#!/bin/bash
# Hide cursor after 3 seconds of inactivity
unclutter -idle 3 &

# Start the app
cd ~/AlwaysOnAudioPlayer/build/linux/arm64/release/bundle/
./always_on_audio_player &
EOF

chmod +x ~/.config/openbox/autostart

# Configure to boot to Openbox
echo "exec openbox-session" > ~/.xinitrc
```

### 2. Auto-start on Boot
```bash
# Edit autostart
sudo nano /etc/xdg/lxsession/LXDE-pi/autostart

# Add this line (adjust path if needed):
@/home/pi/AlwaysOnAudioPlayer/build/linux/arm64/release/bundle/always_on_audio_player
```

### 3. Touch Screen Calibration
```bash
# Install calibration tool
sudo apt install -y xinput-calibrator

# Run calibration
xinput_calibrator

# Follow on-screen instructions
```

## Display Configuration

### For 5-inch 800x480 HDMI Display

Edit `/boot/config.txt`:
```bash
sudo nano /boot/config.txt

# Add these lines:
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=1
display_rotate=0
```

### For Official Raspberry Pi Touchscreen
No configuration needed - works out of the box!

## Audio Configuration

### Test Audio
```bash
# List audio devices
aplay -l

# Test audio output
speaker-test -c2
```

### Set Default Audio Device
```bash
# Edit ALSA config
sudo nano /etc/asound.conf

# Add (replace X with your card number from aplay -l):
defaults.pcm.card X
defaults.ctl.card X
```

## Troubleshooting

### App doesn't start
```bash
# Check dependencies
ldd build/linux/arm64/release/bundle/always_on_audio_player

# Run with verbose output
flutter run -v -d linux

# Check for missing libraries
flutter doctor -v
```

### Touch not working
```bash
# Check input devices
xinput list

# Ensure touchscreen is detected
```

### Performance issues
```bash
# Reduce animations in lib/main.dart
# Set MaterialApp's debugShowCheckedModeBanner: false
# Use release build instead of debug

# Check CPU usage
htop

# Ensure GPU acceleration is enabled
sudo raspi-config
# Advanced Options -> GL Driver -> GL (Full KMS)
```

### Audio crackling
```bash
# Increase audio buffer size
sudo nano /boot/config.txt
# Add: audio_pwm_mode=2

# Or use USB audio interface for better quality
```

## Network Configuration

### For Radio Streaming
Ensure stable internet connection:
```bash
# Test network speed
sudo apt install speedtest-cli
speedtest-cli

# Minimum 2 Mbps recommended for streaming
```

## Screen Rotation
```bash
# For HDMI displays, edit /boot/config.txt:
sudo nano /boot/config.txt

# Add one of:
display_rotate=0  # Normal
display_rotate=1  # 90 degrees
display_rotate=2  # 180 degrees
display_rotate=3  # 270 degrees

# For touchscreen, also rotate touch input:
sudo nano /usr/share/X11/xorg.conf.d/40-libinput.conf

# Add to InputClass section:
Option "CalibrationMatrix" "0 1 0 -1 0 1 0 0 1"  # For 90° rotation
```

## System Service (Run as daemon)

Create systemd service:
```bash
sudo nano /etc/systemd/system/always-on-audio.service
```

Add:
```ini
[Unit]
Description=AlwaysOnAudioPlayer
After=graphical.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi/AlwaysOnAudioPlayer/build/linux/arm64/release/bundle
ExecStart=/home/pi/AlwaysOnAudioPlayer/build/linux/arm64/release/bundle/always_on_audio_player
Restart=always

[Install]
WantedBy=graphical.target
```

Enable and start:
```bash
sudo systemctl enable always-on-audio
sudo systemctl start always-on-audio

# Check status
sudo systemctl status always-on-audio

# View logs
sudo journalctl -u always-on-audio -f
```

## UI Optimizations for 5" Screen

The app automatically detects small screens and:
- Reduces padding and margins
- Scales down fonts slightly (90%)
- Optimizes button sizes for touch
- Uses compact navigation layout
- Adjusts icon sizes appropriately

Default navigation position: **BOTTOM** for best space usage on 5" screens.
Consider **LEFT** or **RIGHT** sidebar for landscape orientation.

## Power Management

### Disable Screen Blanking
```bash
# Edit lightdm config
sudo nano /etc/lightdm/lightdm.conf

# Add under [Seat:*]:
xserver-command=X -s 0 -dpms

# Or use xset
nano ~/.xinitrc
# Add:
xset s off
xset -dpms
xset s noblank
```

## Additional Tips

1. **Use Ethernet** for more stable radio streaming
2. **Heat Management**: Ensure proper ventilation or add heatsinks/fan
3. **SD Card**: Use high-quality SD card (Class 10 or better)
4. **Power Supply**: Use official Raspberry Pi power supply (5V 3A for Pi 4)
5. **Backup**: Create SD card image after successful setup

## Updating the App

```bash
cd ~/AlwaysOnAudioPlayer
git pull
flutter pub get
flutter build linux --release

# If running as service:
sudo systemctl restart always-on-audio

# Or restart manually if not using service
```

## Support

For issues specific to Raspberry Pi deployment, check:
- Flutter Linux embedding: https://github.com/flutter/flutter/wiki/Desktop-shells
- Raspberry Pi forums: https://forums.raspberrypi.com/
