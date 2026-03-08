/* GPIO driver implementation for AI RISC-V KC32 System */

#include "../include/metal/gpio.h"
#include "../include/platform.h"
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#define GPIO_NUM_PINS                  32

int metal_gpio_init(void)
{
    /* Initialize all GPIO pins to input, no pull, no interrupts */
    GPIO_PTR[GPIO_REG_INPUT_EN / 4] = 0x0;        // Disable input enable
    GPIO_PTR[GPIO_REG_OUTPUT_EN / 4] = 0x0;       // Disable output enable
    GPIO_PTR[GPIO_REG_OUTPUT_VAL / 4] = 0x0;      // Clear output values
    GPIO_PTR[GPIO_REG_PULLUP / 4] = 0x0;          // Disable pull-up
    GPIO_PTR[GPIO_REG_PULLDN / 4] = 0x0;          // Disable pull-down
    GPIO_PTR[GPIO_REG_DRIVE0 / 4] = 0x0;          // Normal drive strength
    GPIO_PTR[GPIO_REG_DRIVE1 / 4] = 0x0;          // Normal drive strength
    GPIO_PTR[GPIO_REG_RISE_IE / 4] = 0x0;         // Disable rising edge interrupt
    GPIO_PTR[GPIO_REG_FALL_IE / 4] = 0x0;         // Disable falling edge interrupt
    GPIO_PTR[GPIO_REG_HIGH_IE / 4] = 0x0;         // Disable high level interrupt
    GPIO_PTR[GPIO_REG_LOW_IE / 4] = 0x0;          // Disable low level interrupt
    GPIO_PTR[GPIO_REG_INT_CLEAR / 4] = 0xFFFFFFFF; // Clear all interrupts

    return 0;
}

int metal_gpio_set_direction(uint8_t pin, gpio_direction_t dir)
{
    if (pin >= GPIO_NUM_PINS) {
        return -1;
    }

    uint32_t mask = (1UL << pin);
    uint32_t reg_val;

    if (dir == GPIO_DIR_OUTPUT) {
        /* Enable output */
        reg_val = GPIO_PTR[GPIO_REG_OUTPUT_EN / 4];
        GPIO_PTR[GPIO_REG_OUTPUT_EN / 4] = reg_val | mask;
        
        /* Disable input */
        reg_val = GPIO_PTR[GPIO_REG_INPUT_EN / 4];
        GPIO_PTR[GPIO_REG_INPUT_EN / 4] = reg_val & ~mask;
    } else {
        /* Enable input */
        reg_val = GPIO_PTR[GPIO_REG_INPUT_EN / 4];
        GPIO_PTR[GPIO_REG_INPUT_EN / 4] = reg_val | mask;
        
        /* Disable output */
        reg_val = GPIO_PTR[GPIO_REG_OUTPUT_EN / 4];
        GPIO_PTR[GPIO_REG_OUTPUT_EN / 4] = reg_val & ~mask;
    }

    return 0;
}

int metal_gpio_get_direction(uint8_t pin, gpio_direction_t *dir)
{
    if (pin >= GPIO_NUM_PINS || !dir) {
        return -1;
    }

    uint32_t mask = (1UL << pin);
    uint32_t oe_val = GPIO_PTR[GPIO_REG_OUTPUT_EN / 4];

    *dir = (oe_val & mask) ? GPIO_DIR_OUTPUT : GPIO_DIR_INPUT;
    return 0;
}

int metal_gpio_set_pin(uint8_t pin, bool value)
{
    if (pin >= GPIO_NUM_PINS) {
        return -1;
    }

    uint32_t mask = (1UL << pin);
    uint32_t reg_val = GPIO_PTR[GPIO_REG_OUTPUT_VAL / 4];

    if (value) {
        GPIO_PTR[GPIO_REG_OUTPUT_VAL / 4] = reg_val | mask;
    } else {
        GPIO_PTR[GPIO_REG_OUTPUT_VAL / 4] = reg_val & ~mask;
    }

    return 0;
}

int metal_gpio_get_pin(uint8_t pin, bool *value)
{
    if (pin >= GPIO_NUM_PINS || !value) {
        return -1;
    }

    uint32_t input_val = GPIO_PTR[GPIO_REG_INPUT_VAL / 4];
    uint32_t mask = (1UL << pin);

    *value = (input_val & mask) ? true : false;
    return 0;
}

int metal_gpio_set_output(uint32_t mask, uint32_t value)
{
    uint32_t reg_val = GPIO_PTR[GPIO_REG_OUTPUT_VAL / 4];

    /* Clear masked bits, then set new values */
    reg_val = (reg_val & ~mask) | (value & mask);
    GPIO_PTR[GPIO_REG_OUTPUT_VAL / 4] = reg_val;

    return 0;
}

int metal_gpio_get_input(uint32_t *value)
{
    if (!value) {
        return -1;
    }

    *value = GPIO_PTR[GPIO_REG_INPUT_VAL / 4];
    return 0;
}

int metal_gpio_set_pull(uint8_t pin, gpio_pull_t pull)
{
    if (pin >= GPIO_NUM_PINS) {
        return -1;
    }

    uint32_t mask = (1UL << pin);
    uint32_t pullup_val = GPIO_PTR[GPIO_REG_PULLUP / 4];
    uint32_t pulldown_val = GPIO_PTR[GPIO_REG_PULLDN / 4];

    switch (pull) {
        case GPIO_PULL_UP:
            GPIO_PTR[GPIO_REG_PULLUP / 4] = pullup_val | mask;
            GPIO_PTR[GPIO_REG_PULLDN / 4] = pulldown_val & ~mask;
            break;
        case GPIO_PULL_DOWN:
            GPIO_PTR[GPIO_REG_PULLUP / 4] = pullup_val & ~mask;
            GPIO_PTR[GPIO_REG_PULLDN / 4] = pulldown_val | mask;
            break;
        case GPIO_PULL_NONE:
        default:
            GPIO_PTR[GPIO_REG_PULLUP / 4] = pullup_val & ~mask;
            GPIO_PTR[GPIO_REG_PULLDN / 4] = pulldown_val & ~mask;
            break;
    }

    return 0;
}

int metal_gpio_set_drive(uint8_t pin, gpio_drive_t drive)
{
    if (pin >= GPIO_NUM_PINS) {
        return -1;
    }

    uint32_t mask = (1UL << pin);
    uint32_t ds0_val = GPIO_PTR[GPIO_REG_DRIVE0 / 4];
    uint32_t ds1_val = GPIO_PTR[GPIO_REG_DRIVE1 / 4];

    switch (drive) {
        case GPIO_DRIVE_NORMAL:
            GPIO_PTR[GPIO_REG_DRIVE0 / 4] = ds0_val & ~mask;
            GPIO_PTR[GPIO_REG_DRIVE1 / 4] = ds1_val & ~mask;
            break;
        case GPIO_DRIVE_STRONG:
            GPIO_PTR[GPIO_REG_DRIVE0 / 4] = ds0_val | mask;
            GPIO_PTR[GPIO_REG_DRIVE1 / 4] = ds1_val & ~mask;
            break;
        case GPIO_DRIVE_STRONGER:
            GPIO_PTR[GPIO_REG_DRIVE0 / 4] = ds0_val & ~mask;
            GPIO_PTR[GPIO_REG_DRIVE1 / 4] = ds1_val | mask;
            break;
        case GPIO_DRIVE_MAX:
            GPIO_PTR[GPIO_REG_DRIVE0 / 4] = ds0_val | mask;
            GPIO_PTR[GPIO_REG_DRIVE1 / 4] = ds1_val | mask;
            break;
        default:
            return -1;
    }

    return 0;
}

int metal_gpio_enable_interrupt(uint8_t pin, gpio_int_type_t int_type)
{
    if (pin >= GPIO_NUM_PINS) {
        return -1;
    }

    uint32_t mask = (1UL << pin);
    uint32_t reg_val;

    /* Disable all interrupt types for this pin first */
    reg_val = GPIO_PTR[GPIO_REG_RISE_IE / 4];
    GPIO_PTR[GPIO_REG_RISE_IE / 4] = reg_val & ~mask;
    reg_val = GPIO_PTR[GPIO_REG_FALL_IE / 4];
    GPIO_PTR[GPIO_REG_FALL_IE / 4] = reg_val & ~mask;
    reg_val = GPIO_PTR[GPIO_REG_HIGH_IE / 4];
    GPIO_PTR[GPIO_REG_HIGH_IE / 4] = reg_val & ~mask;
    reg_val = GPIO_PTR[GPIO_REG_LOW_IE / 4];
    GPIO_PTR[GPIO_REG_LOW_IE / 4] = reg_val & ~mask;

    /* Enable the selected interrupt type */
    switch (int_type) {
        case GPIO_INT_RISING_EDGE:
            reg_val = GPIO_PTR[GPIO_REG_RISE_IE / 4];
            GPIO_PTR[GPIO_REG_RISE_IE / 4] = reg_val | mask;
            break;
        case GPIO_INT_FALLING_EDGE:
            reg_val = GPIO_PTR[GPIO_REG_FALL_IE / 4];
            GPIO_PTR[GPIO_REG_FALL_IE / 4] = reg_val | mask;
            break;
        case GPIO_INT_HIGH_LEVEL:
            reg_val = GPIO_PTR[GPIO_REG_HIGH_IE / 4];
            GPIO_PTR[GPIO_REG_HIGH_IE / 4] = reg_val | mask;
            break;
        case GPIO_INT_LOW_LEVEL:
            reg_val = GPIO_PTR[GPIO_REG_LOW_IE / 4];
            GPIO_PTR[GPIO_REG_LOW_IE / 4] = reg_val | mask;
            break;
        default:
            return -1;
    }

    return 0;
}

int metal_gpio_disable_interrupt(uint8_t pin)
{
    if (pin >= GPIO_NUM_PINS) {
        return -1;
    }

    uint32_t mask = (1UL << pin);
    uint32_t reg_val;

    /* Disable all interrupt types */
    reg_val = GPIO_PTR[GPIO_REG_RISE_IE / 4];
    GPIO_PTR[GPIO_REG_RISE_IE / 4] = reg_val & ~mask;
    reg_val = GPIO_PTR[GPIO_REG_FALL_IE / 4];
    GPIO_PTR[GPIO_REG_FALL_IE / 4] = reg_val & ~mask;
    reg_val = GPIO_PTR[GPIO_REG_HIGH_IE / 4];
    GPIO_PTR[GPIO_REG_HIGH_IE / 4] = reg_val & ~mask;
    reg_val = GPIO_PTR[GPIO_REG_LOW_IE / 4];
    GPIO_PTR[GPIO_REG_LOW_IE / 4] = reg_val & ~mask;

    return 0;
}

int metal_gpio_get_interrupt_status(uint32_t *status)
{
    if (!status) {
        return -1;
    }

    *status = GPIO_PTR[GPIO_REG_INT_STATUS / 4];
    return 0;
}

int metal_gpio_clear_interrupt(uint32_t mask)
{
    GPIO_PTR[GPIO_REG_INT_CLEAR / 4] = mask;
    return 0;
}

int metal_gpio_output_set(uint32_t mask)
{
    GPIO_PTR[GPIO_REG_OUTPUT_SET / 4] = mask;
    return 0;
}

int metal_gpio_output_clear(uint32_t mask)
{
    GPIO_PTR[GPIO_REG_OUTPUT_CLEAR / 4] = mask;
    return 0;
}

int metal_gpio_output_toggle(uint32_t mask)
{
    GPIO_PTR[GPIO_REG_OUTPUT_TOGGLE / 4] = mask;
    return 0;
}
