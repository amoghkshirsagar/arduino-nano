# Arduino Nano PlatformIO Projects

## Quick Start

### 1. Install PlatformIO

Install PlatformIO into your active Python environment:

```bash
# install PlatformIO
python -m pip install --upgrade platformio

# verify installation
python -m platformio --version
```

### 2. Manual Device Setup & Verification

Configure USB access permissions and verify device connection.

#### Step 1: Create udev Rules

```bash
# create minimal PlatformIO-friendly udev rules for USB serial devices
sudo tee /etc/udev/rules.d/99-platformio-udev.rules > /dev/null <<'EOF'
# Grant dialout group access to USB serial devices (ttyUSB and ttyACM)
SUBSYSTEM=="tty", KERNEL=="ttyUSB[0-9]*", MODE="0660", GROUP="dialout"
SUBSYSTEM=="tty", KERNEL=="ttyACM[0-9]*", MODE="0660", GROUP="dialout"
EOF

# reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

#### Step 2: Add User to dialout Group

```bash
# add your user to the dialout group (persistent)
sudo usermod -a -G dialout $USER

# apply group immediately to current shell (or log out/in)
newgrp dialout
```

#### Step 3: Verify Device Connection

Connect your Arduino Nano via USB, then verify:

```bash
# list available serial ports
ls -l /dev/tty{USB,ACM}*

# check with PlatformIO
python -m platformio device list

# verify you can read the device (should not require sudo)
cat /dev/ttyUSB0 &  # Ctrl+C to stop
```

### 3. Build and Upload Sketches

#### Option A: Using the Interactive Script (Recommended)

```bash
# make the script executable
chmod +x build-install.sh

# run the interactive menu
./build-install.sh
```

The script will:
1. Display available sketches/environments
2. Let you select a sketch to work with
3. Offer actions: Build, Upload, Monitor, Upload+Monitor, Clean
4. Handle port selection automatically
5. Include retry logic for upload failures

**Example workflow:**
```
./build-install.sh
# Select: 2 (upload)
# Select port: 1 (/dev/ttyUSB0)
# Monitor output as upload completes
```

#### Option B: Manual Commands

```bash
# build a sketch
pio run -d toggle-test-led-5s

# upload a sketch
pio run -d toggle-test-led-5s -t upload

# build and upload
pio run -d toggle-test-led-5s -t upload

# open serial monitor (115200 baud)
pio device monitor -p /dev/ttyUSB0 -b 115200

# clean build artifacts
pio run -d toggle-test-led-5s -t clean
```

### 4. Creating New Sketches

See [Creating New Sketches](.github/skills/create-sketch.md) for Copilot chat-based and manual project scaffolding instructions.

## Troubleshooting

### Upload Permission Denied
```bash
# verify udev rules are in place
ls -l /etc/udev/rules.d/99-platformio-udev.rules

# reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# re-apply group membership
newgrp dialout
```

### Device Not Found
```bash
# rescan USB devices
sudo udevadm trigger --subsystem-match=tty --action=add

# check dmesg for USB errors
dmesg | tail -20
```

### Upload Sync Errors (stk500_getsync)
- Disconnect and reconnect the USB cable
- Try a different USB port
- Use `./build-install.sh` option 7 for automatic retry with port re-selection

222