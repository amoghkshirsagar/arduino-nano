# Skill: Create Modular Arduino Sketches

Scaffolds new PlatformIO project environments with modular, reusable C++ code architecture. Generates standardized directory structures, `platformio.ini` configuration, and organized source code across multiple files by functionality.

## Core Capabilities

* **Standardized project scaffolding** — Creates consistent folder structure for new sketches
* **PlatformIO configuration** — Generates `platformio.ini` with board/framework settings
* **Modular code architecture** — Organizes code into multiple `.cpp`/`.h` files by function
* **Reusable components** — Separates concerns (LED control, motor control, serial communication, etc.)
* **Workspace integration** — Registers new environment in root `platformio.ini`

---

## Workflow: Creating a New Sketch

### Step 1: Use Copilot Chat to Scaffold

1. Open Copilot Chat (`Ctrl+Shift+I` or `Cmd+Shift+I`)
2. Use this prompt pattern:

```text
Create a new PlatformIO sketch called "[sketch-name]" that [describes functionality].

Requirements:
- Use modular code structure with separate .cpp files for different functions
- Include header files (.h) for each module
- Create platformio.ini with Arduino Nano configuration
- Generate a well-structured src/main.cpp that initializes and calls modules
```

**Example prompts:**

- `Create a new PlatformIO sketch called "motor-speed-control" that controls motor speed via PWM with a potentiometer input. Use modular code structure.`
- `Create a sketch called "multi-sensor-logger" that reads temperature, humidity, and light sensors, logs to serial with timestamps. Separate each sensor into its own module.`

### Step 2: Directory Structure Created

Copilot will generate the following structure:

```
[sketch-name]/
├── platformio.ini
├── include/
│   ├── config.h          # Constants and definitions
│   ├── module1.h         # Module-specific declarations
│   └── module2.h
├── src/
│   ├── main.cpp          # Entry point
│   ├── module1.cpp       # Implementation (e.g., LED control)
│   ├── module2.cpp       # Implementation (e.g., Serial communication)
│   └── config.cpp        # Shared configuration
└── README.md             # Sketch documentation
```

### Step 3: Key Files Generated

#### `platformio.ini` (Sketch-specific)
```ini
[env:nano]
platform = atmelavr
board = nanoatmega328new
framework = arduino
monitor_speed = 115200
build_flags = -DSKETCH_VERSION=\"1.0.0\"
lib_deps =
  # Add library dependencies here if needed
```

#### `include/config.h` (Constants & Configuration)
```cpp
#pragma once

// Hardware Pins
#define PIN_LED 13
#define PIN_BUTTON 2
#define PIN_PWM_MOTOR 9

// Timing
#define BAUD_RATE 115200
#define LOOP_INTERVAL_MS 100

// Feature flags
#define ENABLE_DEBUG_SERIAL 1
```

#### `include/led_control.h` (Module Declaration)
```cpp
#pragma once

namespace LED {
  void init();
  void turnOn();
  void turnOff();
  void toggle();
  bool isOn();
}
```

#### `src/led_control.cpp` (Module Implementation)
```cpp
#include <Arduino.h>
#include "../include/config.h"
#include "../include/led_control.h"

static bool led_state = false;

void LED::init() {
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_LED, LOW);
}

void LED::turnOn() {
  digitalWrite(PIN_LED, HIGH);
  led_state = true;
}

void LED::turnOff() {
  digitalWrite(PIN_LED, LOW);
  led_state = false;
}

void LED::toggle() {
  led_state ? turnOff() : turnOn();
}

bool LED::isOn() {
  return led_state;
}
```

#### `src/main.cpp` (Entry Point)
```cpp
#include <Arduino.h>
#include "../include/config.h"
#include "../include/led_control.h"
#include "../include/serial_comm.h"

unsigned long last_loop_ms = 0;

void setup() {
  Serial.begin(BAUD_RATE);
  
  // Initialize all modules
  LED::init();
  SerialComm::init();
  
  if (ENABLE_DEBUG_SERIAL) {
    Serial.println("System initialized");
  }
}

void loop() {
  unsigned long now = millis();
  
  if (now - last_loop_ms >= LOOP_INTERVAL_MS) {
    last_loop_ms = now;
    
    // Execute module logic
    SerialComm::handleInput();
    // ... other module calls
  }
}
```

---

## Code Organization Principles

### 1. Namespace Organization
Use C++ namespaces to group related functions:

```cpp
namespace LED { ... }
namespace Motor { ... }
namespace Sensor { ... }
```

### 2. Separation of Concerns
Each module handles one responsibility:
- **config.h** — Hardware pins, constants
- **led_control.cpp** — LED logic only
- **motor_control.cpp** — Motor PWM/direction
- **serial_comm.cpp** — Serial I/O

### 3. Header Guards
Always include guards in `.h` files:

```cpp
#pragma once
// or
#ifndef LED_CONTROL_H
#define LED_CONTROL_H
// ... declarations
#endif
```

### 4. Reusable Patterns
Write modules that can be copied to other sketches:

```cpp
// Generic LED module (copy-paste ready)
namespace LED {
  void init(int pin);
  void setPin(int pin);
  void blink(int count, int delay_ms);
}
```

---

## Integration with Root platformio.ini

After Copilot creates the sketch, add it to the root `platformio.ini`:

```ini
[env:sketch-name]
extends = nanoatmega328new
src_dir = sketch-name/src
include_dir = sketch-name/include
```

Then use the interactive script:
```bash
./build-install.sh
# Select your new sketch from the menu
```

---

## Testing & Validation Checklist

After creation:
- [ ] Directory structure matches expected layout
- [ ] `platformio.ini` specifies correct board (`nanoatmega328new`)
- [ ] All modules have corresponding `.h` and `.cpp` files
- [ ] `src/main.cpp` initializes all modules in `setup()`
- [ ] Code compiles: `pio run -d sketch-name`
- [ ] Code uploads: `pio run -d sketch-name -t upload`
- [ ] Serial monitor shows initialization messages

---

## Extending a Sketch with New Modules

To add functionality to an existing sketch:

1. **Create new module files:**
   ```bash
   touch [sketch-name]/include/new_module.h
   touch [sketch-name]/src/new_module.cpp
   ```

2. **Declare interface in `.h`:**
   ```cpp
   namespace NewModule {
     void init();
     void update();
   }
   ```

3. **Implement in `.cpp`:**
   ```cpp
   #include <Arduino.h>
   #include "../include/config.h"
   #include "../include/new_module.h"
   
   void NewModule::init() { /* ... */ }
   void NewModule::update() { /* ... */ }
   ```

4. **Call from `main.cpp`:**
   ```cpp
   #include "../include/new_module.h"
   
   void setup() {
     NewModule::init();
   }
   
   void loop() {
     NewModule::update();
   }
   ```

---

## Example Prompts to Try

```
Create a sketch called "temperature-monitor" that reads a DHT22 sensor, displays on LCD, and logs to serial. Use modular code with separate files for sensor reading, display management, and data logging.
```

```
Build a sketch called "smart-light-controller" with PIR motion detection, light level sensor, and LED brightness control via PWM. Organize code into motion, light, and LED modules.
```

```
Generate a sketch called "multi-button-menu" that implements a menu system with 3 buttons and serial command interface. Separate UI logic from command processing in different modules.
```

---

## Related Documentation

See [Creating New Sketches](./../create-sketch.md) for manual scaffolding steps and [Build & Upload](./../../readme.md#3-build-and-upload-sketches) for deployment instructions.