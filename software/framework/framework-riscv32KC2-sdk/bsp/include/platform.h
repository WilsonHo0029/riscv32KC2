/* Platform configuration for AI RISC-V KC32 System */

#ifndef PLATFORM_H
#define PLATFORM_H

#define METAL_DEBUG
#define USE_UART
#define USE_M_TIME


#define CPU_FREQ    50000000  // Assuming 50MHz system clock
#define RTC_FREQ    32768	  // 32768 Hz clock
#define UART0_BASE  0x10000000
#define AD_DA_BASE  0x10001000
#define GPIO_BASE   0x10002000
#define CLINT_BASE  0x02000000
#define PLIC_BASE   0x0C000000
#define UART0_PTR   ((volatile uint32_t *)UART0_BASE)
#define AD_DA_PTR   ((volatile uint32_t *)AD_DA_BASE)
#define GPIO_PTR    ((volatile uint32_t *)GPIO_BASE)
#define CLINT_PTR   ((volatile uint32_t *)CLINT_BASE)
#define PLIC_PTR    ((volatile uint32_t *)PLIC_BASE)
#define NOP         asm volatile("addi x0, x0, 0")

/* Driver console logging */
#ifdef METAL_DEBUG
    #define METAL_LOG(x) printf(x)
#else
    #define METAL_LOG(x)
#endif

typedef void (*function_ptr_t) (void);

#endif /* PLATFORM_H */

