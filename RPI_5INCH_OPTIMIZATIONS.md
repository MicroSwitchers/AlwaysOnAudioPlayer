# Raspberry Pi 5" Screen Optimizations

## Automatic Optimizations Implemented

### Layout Adjustments
✅ **Screen Detection**: Automatically detects screens < 500px as extra compact (5" displays)
✅ **Reduced Padding**: 8px horizontal, 6px vertical (vs 12px/8px on larger screens)
✅ **Navigation Height**: 56px (vs 60px normal, 80px desktop)
✅ **Icon Sizes**: 20px in rail mode (vs 24px normal)
✅ **Font Sizes**: 9px labels in compact mode (vs 10px/11px)
✅ **Text Scaling**: 90% scale factor for better fit
✅ **Touch Targets**: Minimum 44px for reliable touch interaction

### Navigation Optimizations
- **Vertical Rail**: 70px width (vs 90px on larger screens)
- **Border Radius**: 20px (vs 28px normal) for tighter fit
- **Icon Spacing**: Reduced padding for more content space
- **Label Wrapping**: Ellipsis overflow protection

### Performance Settings
✅ **Release Build**: Use `flutter build linux --release` for optimal performance
✅ **Text Cache**: Optimized text rendering
✅ **Disabled Overlays**: No performance debugging overlays in production
✅ **GPU Acceleration**: Relies on hardware acceleration

## Recommended Screen Positions for 5" Display

### Landscape (800x480)
1. **BOTTOM** (Default) - Best for single-handed use
2. **TOP** - Alternative for desk mounting
3. **LEFT** - Good for vertical content (playlists, tracks)
4. **RIGHT** - Alternative sidebar placement

### Portrait (480x800) 
1. **BOTTOM** - Maximum content space
2. **TOP** - When mounting above eye level

## Touch Optimization Tips

### Minimum Sizes
- Navigation buttons: 44x44px minimum
- List items: 48px height minimum  
- Control buttons: 56px diameter (compact mode)
- Icons: 20-24px for visibility

### Spacing
- Between buttons: 8px minimum
- Edge margins: 8px on 5" screens
- List item padding: 6px vertical

## Display Recommendations

### 5-inch Displays Tested
- **Official RPi Touch Display**: 800x480, works perfectly
- **Waveshare 5" HDMI**: 800x480, good touch response
- **Elecrow 5" HDMI**: 800x480, requires calibration

### Optimal Resolution
- **Recommended**: 800x480 @ 60Hz
- **Minimum**: 640x480
- **Maximum**: 1024x600

## Raspberry Pi Models

### Performance Rankings
1. **Raspberry Pi 5** (Best) - Smooth 60fps
2. **Raspberry Pi 4 (4GB+)** - Good performance
3. **Raspberry Pi 4 (2GB)** - Acceptable
4. **Raspberry Pi 3B+** - Minimal, may have lag

### Memory Recommendations
- **Minimum**: 2GB RAM
- **Recommended**: 4GB+ RAM
- **Optimal**: 8GB RAM (for radio streaming + local library)

## Build Commands

### Development
```bash
flutter run -d linux
```

### Production (Recommended for Pi)
```bash
flutter build linux --release
```

### With Optimizations
```bash
flutter build linux --release \
  --dart-define=FLUTTER_WEB_USE_SKIA=false \
  --dart-define=FLUTTER_WEB_AUTO_DETECT=false
```

## File System Optimization

### SD Card Performance
```bash
# Use ext4 with noatime for better performance
sudo nano /etc/fstab
# Change: defaults to defaults,noatime
```

### Reduce Writes
```bash
# Disable swap to reduce SD card wear
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo systemctl disable dphys-swapfile
```

## Audio Configuration for Pi

### Best Audio Options
1. **USB Audio DAC** - Best quality, no noise
2. **HDMI Audio** - Good for displays with speakers
3. **3.5mm Jack** - Works but may have background noise

### ALSA Configuration
```bash
# Set buffer size for smooth playback
sudo nano /etc/asound.conf

defaults.pcm.!card 0
defaults.pcm.!device 0
defaults.pcm.dmix.rate 48000
defaults.pcm.dmix.format S16_LE
```

## Thermal Management

### Temperature Monitoring
```bash
# Check CPU temperature
vcgencmd measure_temp

# Recommended: < 70°C under load
```

### Cooling Solutions
- **Passive**: Heatsinks (minimum)
- **Active**: Small fan (recommended for 24/7 operation)
- **Case**: Flirc case (excellent passive cooling)

## Network for Streaming

### WiFi
- **Minimum**: 802.11n (2.4GHz)
- **Recommended**: 802.11ac (5GHz)
- **Placement**: Near router, < 10 meters

### Ethernet (Preferred)
- Lower latency
- More stable for radio streaming
- No WiFi interference

## Battery Operation

### Power Banks
- **Minimum**: 5V 2.5A
- **Recommended**: 5V 3A (official Pi power supply specs)
- **Capacity**: 10,000mAh = ~4-6 hours playback

### Power Consumption
- **Idle**: ~3W (600mA @ 5V)
- **Playing**: ~4-5W (800-1000mA @ 5V)
- **Peak**: ~7W (1400mA @ 5V) with WiFi + streaming

## Storage Requirements

### SD Card
- **Minimum**: 8GB
- **Recommended**: 16GB+
- **For Music Library**: 32GB+ (depending on collection)

### USB Storage
- Can mount external drives for large music libraries
- Lower wear than SD card
- Recommended for 1000+ tracks

## Kiosk Mode Setup

### Minimal Boot
```bash
# Install minimal X server
sudo apt install --no-install-recommends xserver-xorg x11-xserver-utils xinit openbox

# Auto-login
sudo raspi-config
# System Options -> Boot / Auto Login -> Console Autologin

# Create startup script
echo "startx" >> ~/.bash_profile
```

### Hide Mouse Cursor
```bash
sudo apt install unclutter
# Add to openbox autostart:
unclutter -idle 3 &
```

## Testing Checklist

- [ ] Touch response < 100ms
- [ ] All buttons reachable with thumb
- [ ] Text readable from 30cm
- [ ] No frame drops during scrolling
- [ ] Radio streams without buffering
- [ ] Volume controls responsive
- [ ] Screen doesn't blank during playback
- [ ] Temperature stays under 70°C
- [ ] Audio plays without crackling

## Common Issues & Fixes

### Touch Not Responsive
```bash
# Increase touch sensitivity
sudo nano /boot/config.txt
# Add: touch_sensitivity=2
```

### App Crashes on Start
```bash
# Increase GPU memory
sudo raspi-config
# Performance Options -> GPU Memory -> 256
```

### Choppy UI
```bash
# Disable compositor
# In openbox/autostart, remove any compositors
# Use release build, not debug
```

### No Audio
```bash
# Force audio output
sudo raspi-config
# System Options -> Audio -> Select device
```

## Benchmark Targets (800x480 @ 60Hz)

- **Frame Time**: < 16.67ms (60 FPS)
- **Touch Latency**: < 100ms
- **Cold Start**: < 3s
- **Warm Start**: < 1s
- **Screen Transition**: < 300ms
- **Radio Stream Start**: < 2s (network dependent)

## Production Checklist

- [ ] Built with `--release` flag
- [ ] GPU memory set to 256MB+
- [ ] Audio output configured
- [ ] Touch calibrated
- [ ] Screen orientation correct
- [ ] Auto-start configured
- [ ] Power management disabled
- [ ] Network configured (WiFi or Ethernet)
- [ ] Backup image created

## Quick Command Reference

```bash
# Build release
flutter build linux --release

# Check temperature
vcgencmd measure_temp

# Monitor performance
htop

# Check audio devices
aplay -l

# Test touch
evtest

# View logs
journalctl -u media-interface.service -f

# Restart app
sudo systemctl restart media-interface

# Check display info
xrandr
```

## Support Resources

- Raspberry Pi Forums: https://forums.raspberrypi.com/
- Flutter Linux: https://github.com/flutter/flutter/wiki/Desktop-shells
- Issue Tracker: https://github.com/MicroSwitchers/AlwaysOnAudioPlayer/issues
