# ðŸŸ¢ GPIO Controller

This directory contains the 32-bit General Purpose Input/Output (GPIO) controller for the RISC-V 32KC2 SoC. It provides flexible pin configuration, atomic bit manipulation, and comprehensive interrupt support.

---

## ðŸ—ï¸ Architecture & Modules

The GPIO peripheral consists of:

1.  **`gpio.v`**: The core logic handling pin direction, output values, pull-up/down resistors, drive strength, and interrupt generation.
2.  **`apb_gpio.v`**: An APB slave wrapper that provides standardized bus access to the core registers.

---

## ðŸ—ºï¸ Register Map (Base: `0x1000_2000`)

| Offset | Register | Description |
| :--- | :--- | :--- |
| `0x00` | **GPIO_INPUT_VAL** | Read synchronized input values. |
| `0x04` | **GPIO_INPUT_EN** | Input enable (1 = Input). |
| `0x08` | **GPIO_OUTPUT_EN**| Output enable (1 = Output). |
| `0x0C` | **GPIO_OUTPUT_VAL**| Manual output value control. |
| `0x10` | **GPIO_PULLUP** | Internal pull-up enable. |
| `0x14` | **GPIO_PULLDN** | Internal pull-down enable. |
| `0x18` | **GPIO_DRIVE0** | Drive strength control bit 0. |
| `0x1C` | **GPIO_DRIVE1** | Drive strength control bit 1. |
| `0x20` | **GPIO_RISE_IE** | Rising edge interrupt enable. |
| `0x24` | **GPIO_FALL_IE** | Falling edge interrupt enable. |
| `0x28` | **GPIO_HIGH_IE** | High level interrupt enable. |
| `0x2C` | **GPIO_LOW_IE** | Low level interrupt enable. |
| `0x38` | **GPIO_INT_STATUS**| Pending interrupt status (R). |
| `0x3C` | **GPIO_INT_CLEAR** | Clear pending interrupts (W). |
| `0x40` | **GPIO_OUTPUT_SET**| **Atomic** Bit Set (W). |
| `0x44` | **GPIO_OUTPUT_CLR**| **Atomic** Bit Clear (W). |
| `0x48` | **GPIO_OUTPUT_TOG**| **Atomic** Bit Toggle (W). |

---

## âš¡ Key Features

- **3-Stage Synchronization:** All inputs are passed through a 3-stage synchronizer to prevent metastability.
- **Configurable Drive Strength:** 4 levels of drive strength per pin.
- **Atomic Operations:** Dedicated registers for Set, Clear, and Toggle allow for thread-safe bit manipulation without Read-Modify-Write cycles.
- **Interrupts:** Supports rising edge, falling edge, high level, and low level triggers per pin.

---

## 📜 Related Documents
- [**Peripheral Subsystem README**](../README.md)
- [**Main Project README**](../../../README.md)
- [**Memory Map**](../../../Memory_Map.txt)

