#ifndef METAL_GPIO_HEADER
#define METAL_GPIO_HEADER

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* GPIO Base Address */
#define GPIO_BASE_ADDR                0x10002000

/* GPIO Register Offsets (word-aligned, byte address / 4) */
#define GPIO_REG_INPUT_VAL            0x00    // Read input values
#define GPIO_REG_INPUT_EN             0x04    // Input enable (gpio_ie)
#define GPIO_REG_OUTPUT_EN            0x08    // Output enable (gpio_oe)
#define GPIO_REG_OUTPUT_VAL           0x0C    // Output value (gpio_o)
#define GPIO_REG_PULLUP               0x10    // Pull-up enable
#define GPIO_REG_PULLDN               0x14    // Pull-down enable
#define GPIO_REG_DRIVE0               0x18    // Drive strength 0
#define GPIO_REG_DRIVE1               0x1C    // Drive strength 1
#define GPIO_REG_RISE_IE              0x20    // Rising edge interrupt enable
#define GPIO_REG_FALL_IE              0x24    // Falling edge interrupt enable
#define GPIO_REG_HIGH_IE              0x28    // High level interrupt enable
#define GPIO_REG_LOW_IE               0x2C    // Low level interrupt enable
#define GPIO_REG_INT_STATUS           0x38    // Interrupt status (read-only)
#define GPIO_REG_INT_CLEAR            0x3C    // Interrupt clear (write-only)
#define GPIO_REG_OUTPUT_SET           0x40    // Set output bits (write-only)
#define GPIO_REG_OUTPUT_CLEAR         0x44    // Clear output bits (write-only)
#define GPIO_REG_OUTPUT_TOGGLE        0x48    // Toggle output bits (write-only)

/* GPIO Pin Direction */
typedef enum {
    GPIO_DIR_INPUT = 0,
    GPIO_DIR_OUTPUT = 1
} gpio_direction_t;

/* GPIO Pin Pull Configuration */
typedef enum {
    GPIO_PULL_NONE = 0,
    GPIO_PULL_UP = 1,
    GPIO_PULL_DOWN = 2
} gpio_pull_t;

/* GPIO Interrupt Type */
typedef enum {
    GPIO_INT_RISING_EDGE = 0,
    GPIO_INT_FALLING_EDGE = 1,
    GPIO_INT_HIGH_LEVEL = 2,
    GPIO_INT_LOW_LEVEL = 3
} gpio_int_type_t;

/* GPIO Drive Strength */
typedef enum {
    GPIO_DRIVE_NORMAL = 0,   // ds0=0, ds1=0
    GPIO_DRIVE_STRONG = 1,   // ds0=1, ds1=0
    GPIO_DRIVE_STRONGER = 2, // ds0=0, ds1=1
    GPIO_DRIVE_MAX = 3       // ds0=1, ds1=1
} gpio_drive_t;

/* Function Prototypes */

/*! @brief Initialize GPIO peripheral
 * @return 0 if no error, -1 on error */
int metal_gpio_init(void);

/*! @brief Set GPIO pin direction
 * @param pin Pin number (0-31)
 * @param dir Direction (GPIO_DIR_INPUT or GPIO_DIR_OUTPUT)
 * @return 0 on success, -1 on error */
int metal_gpio_set_direction(uint8_t pin, gpio_direction_t dir);

/*! @brief Get GPIO pin direction
 * @param pin Pin number (0-31)
 * @param dir Pointer to store direction
 * @return 0 on success, -1 on error */
int metal_gpio_get_direction(uint8_t pin, gpio_direction_t *dir);

/*! @brief Set GPIO pin output value
 * @param pin Pin number (0-31)
 * @param value Output value (0 or 1)
 * @return 0 on success, -1 on error */
int metal_gpio_set_pin(uint8_t pin, bool value);

/*! @brief Get GPIO pin input value
 * @param pin Pin number (0-31)
 * @param value Pointer to store input value
 * @return 0 on success, -1 on error */
int metal_gpio_get_pin(uint8_t pin, bool *value);

/*! @brief Set multiple GPIO pins output value
 * @param mask Bit mask (1 = set, 0 = unchanged)
 * @param value Bit values to set
 * @return 0 on success, -1 on error */
int metal_gpio_set_output(uint32_t mask, uint32_t value);

/*! @brief Get all GPIO pins input value
 * @param value Pointer to store input values (bit mask)
 * @return 0 on success, -1 on error */
int metal_gpio_get_input(uint32_t *value);

/*! @brief Set GPIO pin pull configuration
 * @param pin Pin number (0-31)
 * @param pull Pull configuration (GPIO_PULL_NONE, GPIO_PULL_UP, GPIO_PULL_DOWN)
 * @return 0 on success, -1 on error */
int metal_gpio_set_pull(uint8_t pin, gpio_pull_t pull);

/*! @brief Set GPIO pin drive strength
 * @param pin Pin number (0-31)
 * @param drive Drive strength configuration
 * @return 0 on success, -1 on error */
int metal_gpio_set_drive(uint8_t pin, gpio_drive_t drive);

/*! @brief Enable GPIO pin interrupt
 * @param pin Pin number (0-31)
 * @param int_type Interrupt type
 * @return 0 on success, -1 on error */
int metal_gpio_enable_interrupt(uint8_t pin, gpio_int_type_t int_type);

/*! @brief Disable GPIO pin interrupt
 * @param pin Pin number (0-31)
 * @return 0 on success, -1 on error */
int metal_gpio_disable_interrupt(uint8_t pin);

/*! @brief Get GPIO interrupt status
 * @param status Pointer to store interrupt status (bit mask)
 * @return 0 on success, -1 on error */
int metal_gpio_get_interrupt_status(uint32_t *status);

/*! @brief Clear GPIO interrupt
 * @param mask Bit mask of interrupts to clear
 * @return 0 on success, -1 on error */
int metal_gpio_clear_interrupt(uint32_t mask);

/*! @brief Set GPIO output bits (atomic operation)
 * @param mask Bit mask of pins to set (1 = set, 0 = unchanged)
 * @return 0 on success, -1 on error */
int metal_gpio_output_set(uint32_t mask);

/*! @brief Clear GPIO output bits (atomic operation)
 * @param mask Bit mask of pins to clear (1 = clear, 0 = unchanged)
 * @return 0 on success, -1 on error */
int metal_gpio_output_clear(uint32_t mask);

/*! @brief Toggle GPIO output bits (atomic operation)
 * @param mask Bit mask of pins to toggle (1 = toggle, 0 = unchanged)
 * @return 0 on success, -1 on error */
int metal_gpio_output_toggle(uint32_t mask);

#endif /* METAL_GPIO_HEADER */

