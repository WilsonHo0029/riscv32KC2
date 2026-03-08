/**
 * Main program for RISC-V 32KC2 System
 * Architecture: RV32IMC_Zicsr_Zifencei
 */
#include <stdio.h>
#include <metal/uart.h>
#include <metal/gpio.h>
#include <metal/clint.h>
#include <metal/time.h>
uint8_t irq_set;
void mtimer_isr(){
//	printf("mtimer_irq_triggered\n");
	irq_set = 1;
};

int main(void) {
    // Initialize UART (if available)
    // Adjust UART number based on your system configuration
    uint64_t cpu_freq;
	metal_gpio_set_direction(0, GPIO_DIR_OUTPUT);
	metal_gpio_set_direction(1, GPIO_DIR_OUTPUT);
	metal_gpio_set_direction(2, GPIO_DIR_INPUT);
	cpu_freq = metal_clint_calculate_cpu_freq(); 	
    metal_uart_init(115200, 8, 0, 0, 0);  // baud_rate=115200, bit=8, parity_en=0, parity_sel=0, lin_en=0
    /* Configure ADC */
    adc_config_t adc_cfg = {
        .samp_rate = ADC_SAMP_RATE_1,
        .wait_time = 10,
        .offset = 0
    };
    irq_set = 0;
	metal_mtimer_isr_config_ms(1000, &mtimer_isr);
	metal_interrupt_enable(METAL_GENERAL_INT);
	printf("Hello 123144~~~~~~~~~~~\n");
    printf("Calculated CPU Frequency: %lu Hz \n", (uint32_t)cpu_freq);
    while(1) {
		
		if(irq_set){
			printf("mtimer_irq_triggered\n");
			irq_set = 0;
		}
		
        // Simple delay loop
        metal_time_wait_for_ms(200);
		printf("124545\n");
		metal_gpio_output_toggle(1 << 0);
		metal_gpio_output_toggle(1 << 1);
		metal_adc_re_sample();
    }
    
    return 0;
}







