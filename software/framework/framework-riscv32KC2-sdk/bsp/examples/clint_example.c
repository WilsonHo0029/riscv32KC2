/* CLINT Example for AI RISC-V KC32 System
 *
 * This example demonstrates how to use the CLINT (Core Local Interruptor)
 * library to:
 * 1. Calculate CPU frequency
 * 2. Read and use the machine timer (MTIME)
 * 3. Set up timer interrupts
 * 4. Use software interrupts
 * 5. Measure time intervals
 */

#include "../include/metal/clint.h"
#include "../include/machine.h"
#include "../include/platform.h"
#include <stdio.h>
#include <stdint.h>

/* Example 1: Calculate CPU frequency */
void example_calculate_cpu_freq(void)
{
    uint64_t cpu_freq;
    const uint32_t rtc_freq = RTC_FREQ;  // 32768 Hz
    
    printf("\n=== Example 1: Calculate CPU Frequency ===\n");
    printf("RTC Frequency: %u Hz\n", rtc_freq);
    
    /* Calculate CPU frequency using fixed 0.1 second measurement period */
    printf("Measuring CPU frequency (this will take ~0.1 second)...\n");
    cpu_freq = metal_clint_calculate_cpu_freq();
    
    if (cpu_freq > 0) {
        printf("Calculated CPU Frequency: %llu Hz (%.2f MHz)\n", 
               (unsigned long long)cpu_freq, 
               (double)cpu_freq / 1000000.0);
    } else {
        printf("Failed to calculate CPU frequency\n");
    }
}

/* Example 2: Read and display MTIME */
void example_read_mtime(void)
{
    uint64_t mtime;
    uint64_t time_us;
    const uint64_t cpu_freq = CPU_FREQ;  // From platform.h
    
    printf("\n=== Example 2: Read Machine Timer (MTIME) ===\n");
    
    /* Read MTIME multiple times to show it incrementing */
    for (int i = 0; i < 5; i++) {
        mtime = metal_clint_read_mtime();
        time_us = metal_clint_get_time_us(cpu_freq);
        
        printf("MTIME: 0x%016llX (%llu ticks, %llu microseconds)\n",
               (unsigned long long)mtime,
               (unsigned long long)mtime,
               (unsigned long long)time_us);
        
        /* Simple delay loop */
        for (volatile int j = 0; j < 100000; j++);
    }
}

/* Example 3: Set up timer interrupt */
void example_timer_interrupt(void)
{
    uint32_t hart_id = 0;
    uint64_t current_time;
    uint64_t target_time;
    uint64_t timeout_us = 1000000;  // 1 second
    const uint64_t cpu_freq = CPU_FREQ;
    
    printf("\n=== Example 3: Timer Interrupt Setup ===\n");
    
    /* Read current MTIME */
    current_time = metal_clint_read_mtime();
    printf("Current MTIME: 0x%016llX\n", (unsigned long long)current_time);
    
    /* Set up timer interrupt for 1 second from now */
    if (metal_clint_set_timer(hart_id, timeout_us, cpu_freq) == 0) {
        printf("Timer interrupt set for %llu microseconds from now\n",
               (unsigned long long)timeout_us);
        
        /* Read MTIMECMP to verify */
        target_time = metal_clint_read_mtimecmp(hart_id);
        printf("MTIMECMP set to: 0x%016llX\n", (unsigned long long)target_time);
        printf("Expected MTIME when interrupt fires: 0x%016llX\n",
               (unsigned long long)target_time);
    } else {
        printf("Failed to set timer interrupt\n");
    }
    
    /* Disable timer interrupt */
    printf("\nDisabling timer interrupt...\n");
    metal_clint_disable_timer(hart_id);
    target_time = metal_clint_read_mtimecmp(hart_id);
    printf("MTIMECMP after disable: 0x%016llX (should be 0xFFFFFFFFFFFFFFFF)\n",
           (unsigned long long)target_time);
}

/* Example 4: Software interrupt */
void example_software_interrupt(void)
{
    uint32_t hart_id = 0;
    uint32_t msip_value;
    
    printf("\n=== Example 4: Software Interrupt (MSIP) ===\n");
    
    /* Read current MSIP value */
    msip_value = metal_clint_read_msip(hart_id);
    printf("Initial MSIP value: 0x%08X\n", msip_value);
    
    /* Trigger software interrupt */
    printf("Triggering software interrupt...\n");
    metal_clint_set_soft_irq(hart_id);
    msip_value = metal_clint_read_msip(hart_id);
    printf("MSIP after set: 0x%08X (bit 0 should be 1)\n", msip_value);
    
    /* Clear software interrupt */
    printf("Clearing software interrupt...\n");
    metal_clint_clear_soft_irq(hart_id);
    msip_value = metal_clint_read_msip(hart_id);
    printf("MSIP after clear: 0x%08X (bit 0 should be 0)\n", msip_value);
    
    /* Write MSIP directly */
    printf("Writing MSIP directly...\n");
    metal_clint_write_msip(hart_id, 1);
    msip_value = metal_clint_read_msip(hart_id);
    printf("MSIP after direct write: 0x%08X\n", msip_value);
    
    metal_clint_write_msip(hart_id, 0);
    msip_value = metal_clint_read_msip(hart_id);
    printf("MSIP after clearing: 0x%08X\n", msip_value);
}

/* Example 5: Time measurement */
void example_time_measurement(void)
{
    uint64_t start_time, end_time, elapsed_time;
    uint64_t start_us, end_us, elapsed_us;
    const uint64_t cpu_freq = CPU_FREQ;
    volatile int i;
    
    printf("\n=== Example 5: Time Measurement ===\n");
    
    /* Measure time using MTIME */
    start_time = metal_clint_read_mtime();
    start_us = metal_clint_get_time_us(cpu_freq);
    
    printf("Start time: %llu ticks, %llu microseconds\n",
           (unsigned long long)start_time,
           (unsigned long long)start_us);
    
    /* Perform some work (delay loop) */
    printf("Performing delay loop...\n");
    for (i = 0; i < 1000000; i++);
    
    end_time = metal_clint_read_mtime();
    end_us = metal_clint_get_time_us(cpu_freq);
    
    printf("End time: %llu ticks, %llu microseconds\n",
           (unsigned long long)end_time,
           (unsigned long long)end_us);
    
    /* Calculate elapsed time */
    elapsed_time = end_time - start_time;
    elapsed_us = end_us - start_us;
    
    printf("Elapsed: %llu ticks, %llu microseconds (%.3f ms)\n",
           (unsigned long long)elapsed_time,
           (unsigned long long)elapsed_us,
           (double)elapsed_us / 1000.0);
}

/* Example 6: Periodic timer */
void example_periodic_timer(void)
{
    uint32_t hart_id = 0;
    uint64_t period_us = 500000;  // 0.5 seconds
    const uint64_t cpu_freq = CPU_FREQ;
    uint64_t last_time, current_time;
    int count = 0;
    
    printf("\n=== Example 6: Periodic Timer ===\n");
    printf("Setting up periodic timer with %llu microsecond period\n",
           (unsigned long long)period_us);
    
    /* Set up initial timer */
    metal_clint_set_timer(hart_id, period_us, cpu_freq);
    last_time = metal_clint_read_mtime();
    
    printf("Timer set. Waiting for interrupts (simulated by polling)...\n");
    printf("Note: In a real system, this would be handled by interrupt handler\n");
    
    /* Simulate periodic timer by polling (in real system, use interrupt handler) */
    for (int i = 0; i < 3; i++) {
        /* Wait for timer to expire */
        do {
            current_time = metal_clint_read_mtime();
        } while (current_time < (last_time + (period_us * cpu_freq / 1000000)));
        
        count++;
        printf("Timer expired #%d at MTIME: 0x%016llX\n",
               count, (unsigned long long)current_time);
        
        /* Set up next timer period */
        metal_clint_set_timer(hart_id, period_us, cpu_freq);
        last_time = current_time;
    }
    
    /* Disable timer */
    metal_clint_disable_timer(hart_id);
    printf("Periodic timer disabled\n");
}

int main(void)
{
    printf("\n");
    printf("========================================\n");
    printf("CLINT Library Example Program\n");
    printf("AI RISC-V KC32 System\n");
    printf("========================================\n");
    
    /* Run all examples */
    example_calculate_cpu_freq();
    example_read_mtime();
    example_timer_interrupt();
    example_software_interrupt();
    example_time_measurement();
    example_periodic_timer();
    
    printf("\n");
    printf("========================================\n");
    printf("All examples completed!\n");
    printf("========================================\n");
    
    return 0;
}

