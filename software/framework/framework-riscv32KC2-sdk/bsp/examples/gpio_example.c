/* GPIO Example for AI RISC-V KC32 System */

#include <metal/gpio.h>
#include <stdio.h>

int main(void)
{
    struct metal_gpio *gpio0;
    bool pin_value;
    uint32_t input_val;
    uint32_t int_status;

    /* Get GPIO device handle */
    gpio0 = metal_get_gpio(0);
    if (!gpio0) {
        printf("Failed to get GPIO device\n");
        return -1;
    }

    /* Initialize GPIO */
    if (metal_gpio_init(gpio0) != 0) {
        printf("Failed to initialize GPIO\n");
        return -1;
    }

    /* Configure pin 0 as output */
    metal_gpio_set_direction(gpio0, 0, GPIO_DIR_OUTPUT);
    metal_gpio_set_pull(gpio0, 0, GPIO_PULL_NONE);
    metal_gpio_set_drive(gpio0, 0, GPIO_DRIVE_NORMAL);

    /* Set pin 0 high */
    metal_gpio_set_pin(gpio0, 0, true);

    /* Configure pin 1 as input with pull-up */
    metal_gpio_set_direction(gpio0, 1, GPIO_DIR_INPUT);
    metal_gpio_set_pull(gpio0, 1, GPIO_PULL_UP);

    /* Enable interrupt on pin 1 for rising edge */
    metal_gpio_enable_interrupt(gpio0, 1, GPIO_INT_RISING_EDGE);

    /* Read pin 1 value */
    metal_gpio_get_pin(gpio0, 1, &pin_value);
    printf("Pin 1 value: %d\n", pin_value);

    /* Read all input pins */
    metal_gpio_get_input(gpio0, &input_val);
    printf("All GPIO inputs: 0x%08X\n", input_val);

    /* Toggle pin 0 using atomic operation */
    metal_gpio_output_toggle(gpio0, (1 << 0));

    /* Check interrupt status */
    metal_gpio_get_interrupt_status(gpio0, &int_status);
    if (int_status != 0) {
        printf("GPIO interrupt detected: 0x%08X\n", int_status);
        /* Clear interrupts */
        metal_gpio_clear_interrupt(gpio0, int_status);
    }

    /* Blink LED on pin 0 */
    while (1) {
        metal_gpio_set_pin(gpio0, 0, true);
        for (volatile int i = 0; i < 100000; i++); // Delay
        metal_gpio_set_pin(gpio0, 0, false);
        for (volatile int i = 0; i < 100000; i++); // Delay
    }

    return 0;
}

