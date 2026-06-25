# Arduino Nano Pin Layout Reference

> Board: **Arduino Nano** (ATmega328P)  
> Use this file as context instead of the pin diagram image.

---

## Pin Map Overview

### Left Side (Top → Bottom)

| Physical Pin | Arduino Label | Port  | Alternate Functions          | Notes                        |
|--------------|---------------|-------|------------------------------|------------------------------|
| 13           | D13           | PB5   | SCK (SPI Clock)              | Built-in LED                 |
| —            | 3V3           | —     | 3.3V output                  | 50mA max from USB regulator  |
| —            | AREF          | —     | Analog Reference             | External voltage ref for ADC |
| 14 / A0      | D14 / A0      | PC0   | ADC0                         | Analog or digital            |
| 15 / A1      | D15 / A1      | PC1   | ADC1                         | Analog or digital            |
| 16 / A2      | D16 / A2      | PC2   | ADC2                         | Analog or digital            |
| 17 / A3      | D17 / A3      | PC3   | ADC3                         | Analog or digital            |
| 18 / A4      | D18 / A4      | PC4   | ADC4, SDA (I2C)              | I2C Data                     |
| 19 / A5      | D19 / A5      | PC5   | ADC5, SCL (I2C)              | I2C Clock                    |
| 20           | A6            | —     | ADC6                         | **Analog input ONLY**        |
| 21           | A7            | —     | ADC7                         | **Analog input ONLY**        |
| —            | 5V            | —     | 5V output                    | From USB or VIN regulator    |
| —            | RST           | PC6   | Reset                        | Active LOW                   |
| —            | GND           | —     | Ground                       |                              |
| —            | VIN           | —     | 7–12V input                  | Powers onboard regulator     |

### Right Side (Top → Bottom)

| Physical Pin | Arduino Label | Port  | Alternate Functions          | Notes                        |
|--------------|---------------|-------|------------------------------|------------------------------|
| 12           | D12           | PB4   | MISO (SPI)                   |                              |
| 11           | D11           | PB3   | MOSI (SPI), OC2A (PWM)       | **PWM capable**              |
| 10           | D10           | PB2   | SS (SPI), OC1B (PWM)         | **PWM capable**              |
| 9            | D9            | PB1   | OC1A (PWM)                   | **PWM capable**              |
| 8            | D8            | PB0   | CLK/CP1                      |                              |
| 7            | D7            | PD7   | AIN_1                        |                              |
| 6            | D6            | PD6   | AIN_0, OC0A (PWM)            | **PWM capable**              |
| 5            | D5            | PD5   | OC0B/T1 (PWM)                | **PWM capable**              |
| 4            | D4            | PD4   | T0/XCK                       |                              |
| 3            | D3            | PD3   | OC2B (PWM), INT1             | **PWM capable**, ext interrupt |
| 2            | D2            | PD2   | INT0                         | External interrupt           |
| 1            | D1            | PD1   | TXD (UART)                   | Serial TX                    |
| 0            | D0            | PD0   | RXD (UART)                   | Serial RX                    |
| —            | RST           | PC6   | Reset                        | Active LOW                   |
| —            | GND           | —     | Ground                       |                              |
| —            | 5V            | —     | 5V output                    |                              |

---

## Digital Pins

All pins D0–D13 are digital I/O (3.3V logic tolerant, 5V output).

```cpp
pinMode(7, OUTPUT);
digitalWrite(7, HIGH);

pinMode(2, INPUT_PULLUP);   // Enable internal pull-up (~20–50kΩ)
int val = digitalRead(2);
```

- **Input modes:** `INPUT`, `INPUT_PULLUP`
- **Output mode:** `OUTPUT`
- Max current per pin: **40mA**, max total across all pins: **200mA**

---

## PWM Pins

Only 6 pins support `analogWrite()` (8-bit, 0–255):

| Pin  | Timer   | Frequency (default) | Notes                              |
|------|---------|---------------------|------------------------------------|
| D3   | Timer2B | ~490 Hz             | Shares timer with D11              |
| D5   | Timer0B | ~980 Hz             | Shares timer with D6; Timer0 used by `millis()`/`delay()` |
| D6   | Timer0A | ~980 Hz             | Shares timer with D5               |
| D9   | Timer1A | ~490 Hz             | Shares timer with D10              |
| D10  | Timer1B | ~490 Hz             | Shares timer with D9               |
| D11  | Timer2A | ~490 Hz             | Shares timer with D3               |

```cpp
analogWrite(9, 128);   // 50% duty cycle on D9
```

> **Timer sharing caveat:** Changing frequency on one pin of a shared timer pair affects the other pin. E.g., changing D9's frequency also changes D10.

> **`millis()` / `delay()` caveat:** Timer0 drives `millis()`, `micros()`, and `delay()`. Modifying Timer0 (D5, D6) breaks time tracking.

---

## Analog Input Pins

ADC is 10-bit (0–1023), reference defaults to VCC (5V).

| Arduino Label | Port | ADC Channel | Digital Use? |
|---------------|------|-------------|--------------|
| A0 (D14)      | PC0  | ADC0        | Yes          |
| A1 (D15)      | PC1  | ADC1        | Yes          |
| A2 (D16)      | PC2  | ADC2        | Yes          |
| A3 (D17)      | PC3  | ADC3        | Yes          |
| A4 (D18)      | PC4  | ADC4 / SDA  | Yes          |
| A5 (D19)      | PC5  | ADC5 / SCL  | Yes          |
| A6            | —    | ADC6        | **NO** — analog only, no digital I/O |
| A7            | —    | ADC7        | **NO** — analog only, no digital I/O |

```cpp
int val = analogRead(A0);           // 0–1023
analogReference(EXTERNAL);          // Use AREF pin as reference voltage
analogReference(INTERNAL);          // 1.1V internal reference
analogReference(DEFAULT);           // VCC (5V)
```

> ⚠️ Never apply voltage to AREF and call `analogReference(DEFAULT)` simultaneously — it short-circuits the internal reference and may damage the chip.

---

## Communication Interfaces

### UART (Serial)

| Pin | Function |
|-----|----------|
| D0  | RX (receive) |
| D1  | TX (transmit) |

```cpp
Serial.begin(9600);
Serial.println("hello");
```

> ⚠️ **Upload conflict:** D0/D1 are shared with the USB-to-serial chip (CH340/FT232). Any device connected to D0/D1 **must be disconnected** during sketch upload, or upload will fail.

### SPI

| Pin  | Function |
|------|----------|
| D13  | SCK (clock) |
| D12  | MISO (master in, slave out) |
| D11  | MOSI (master out, slave in) |
| D10  | SS (slave select, software-controlled) |

```cpp
#include <SPI.h>
SPI.begin();
SPI.transfer(0xAB);
```

### I2C (Wire)

| Pin  | Function |
|------|----------|
| A4 (D18) | SDA (data) |
| A5 (D19) | SCL (clock) |

```cpp
#include <Wire.h>
Wire.begin();           // Master mode
Wire.begin(0x08);       // Slave mode at address 0x08
```

> Requires external pull-up resistors (typically 4.7kΩ to 5V) unless your peripheral board includes them.

---

## External Interrupts

| Pin | Interrupt | Trigger Modes                        |
|-----|-----------|--------------------------------------|
| D2  | INT0      | LOW, CHANGE, RISING, FALLING         |
| D3  | INT1      | LOW, CHANGE, RISING, FALLING         |

```cpp
attachInterrupt(digitalPinToInterrupt(2), myISR, FALLING);
```

> All digital pins support **Pin Change Interrupts** (PCINT) via the `PinChangeInterrupt` library, but only D2 and D3 support the faster dedicated external interrupts.

---

## Power Pins

| Pin  | Description                                             |
|------|---------------------------------------------------------|
| VIN  | 7–12V unregulated input (goes through onboard 5V reg)  |
| 5V   | Regulated 5V output (from USB or VIN regulator)        |
| 3V3  | 3.3V output (~50mA max, from USB regulator chip)        |
| GND  | Ground (multiple pins)                                  |
| AREF | External analog reference for ADC                       |
| RST  | Pull LOW to reset the MCU                               |

---

## Upload / Bootloader Pin Conflict Issues

These pin states **at boot time** can interfere with sketch uploading:

| Pin | Issue | Explanation |
|-----|-------|-------------|
| **D0 (RX)** | Upload fails if driven LOW externally | USB-serial uses this; external device holding it LOW blocks bootloader comms |
| **D1 (TX)** | Upload fails if driven LOW externally | Same as D0; shared with USB-serial chip |
| **D13** | Glitches HIGH briefly on reset | The bootloader blinks D13 (built-in LED) during boot. Don't use D13 to drive relays or mosfets that should be LOW on power-up |
| **RST** | Must pulse LOW to enter bootloader | If RST is held LOW (e.g., stuck button), the board stays in reset and can't be programmed |
| **D10 (SS)** | If set as INPUT (floating) during SPI use | Must be kept HIGH or set as OUTPUT to avoid SPI entering slave mode unintentionally |

### Bootloader Entry Sequence
1. Host pulses DTR → RST goes LOW briefly → ATmega resets
2. Bootloader runs for ~2 seconds
3. Bootloader listens on D0/D1 (via USB-serial chip) for STK500 protocol
4. If no valid upload starts, bootloader jumps to the user sketch

**Rule of thumb:** Disconnect anything driving D0 or D1 before uploading. If using a module (GPS, Bluetooth, etc.) on D0/D1, use `SoftwareSerial` on other pins instead.

---

## Pin Configuration Quick Reference

```cpp
// Digital output
pinMode(13, OUTPUT);
digitalWrite(13, HIGH);

// Digital input with pull-up
pinMode(2, INPUT_PULLUP);
int btn = digitalRead(2);

// PWM output
pinMode(9, OUTPUT);
analogWrite(9, 200);          // ~78% duty cycle

// Analog read
int raw = analogRead(A0);     // 0–1023
float volts = raw * (5.0 / 1023.0);

// I2C
#include <Wire.h>
Wire.begin();
Wire.beginTransmission(0x68);
Wire.write(0x01);
Wire.endTransmission();

// SPI
#include <SPI.h>
digitalWrite(10, LOW);         // Select slave
SPI.transfer(data);
digitalWrite(10, HIGH);        // Deselect slave

// External interrupt
attachInterrupt(digitalPinToInterrupt(3), isr_fn, RISING);
```

---

## A6 / A7 Gotcha

A6 and A7 are **analog-only** channels connected directly to the ADC multiplexer. They have **no digital I/O capability** and **no internal pull-up**. You cannot use them with `pinMode()`, `digitalWrite()`, or `digitalRead()`.

```cpp
// VALID
int v = analogRead(A6);

// INVALID — will silently fail or misbehave
pinMode(A6, INPUT_PULLUP);   // ❌ No effect
digitalRead(A6);             // ❌ Undefined behavior
```

---

## Summary: Pin Capabilities at a Glance

| Pin  | Digital | Analog In | PWM | SPI  | I2C | UART | Interrupt |
|------|---------|-----------|-----|------|-----|------|-----------|
| D0   | ✓       |           |     |      |     | RX   |           |
| D1   | ✓       |           |     |      |     | TX   |           |
| D2   | ✓       |           |     |      |     |      | INT0      |
| D3   | ✓       |           | ✓   |      |     |      | INT1      |
| D4   | ✓       |           |     |      |     |      |           |
| D5   | ✓       |           | ✓   |      |     |      |           |
| D6   | ✓       |           | ✓   |      |     |      |           |
| D7   | ✓       |           |     |      |     |      |           |
| D8   | ✓       |           |     |      |     |      |           |
| D9   | ✓       |           | ✓   |      |     |      |           |
| D10  | ✓       |           | ✓   | SS   |     |      |           |
| D11  | ✓       |           | ✓   | MOSI |     |      |           |
| D12  | ✓       |           |     | MISO |     |      |           |
| D13  | ✓       |           |     | SCK  |     |      |           |
| A0   | ✓       | ✓         |     |      |     |      |           |
| A1   | ✓       | ✓         |     |      |     |      |           |
| A2   | ✓       | ✓         |     |      |     |      |           |
| A3   | ✓       | ✓         |     |      |     |      |           |
| A4   | ✓       | ✓         |     |      | SDA |      |           |
| A5   | ✓       | ✓         |     |      | SCL |      |           |
| A6   |         | ✓         |     |      |     |      |           |
| A7   |         | ✓         |     |      |     |      |           |