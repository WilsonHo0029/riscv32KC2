/* CLINT (Core Local Interruptor) driver implementation for AI RISC-V KC32 System */

#include "../include/metal/clint.h"
#include "../include/encoding.h"
#include "../include/platform.h"
#include <stdint.h>

struct metal_clint_mtimer this_mtimer;
/**
 * @brief Read Machine Software Interrupt Pending (MSIP) register
 */
uint32_t metal_clint_read_msip(uint32_t hart_id)
{
    return *CLINT_MSIP_PTR(hart_id);
}

/**
 * @brief Write Machine Software Interrupt Pending (MSIP) register
 */
void metal_clint_write_msip(uint32_t hart_id, uint32_t value)
{
    *CLINT_MSIP_PTR(hart_id) = value & 0x1;  // Only bit 0 is valid
}

/**
 * @brief Trigger software interrupt for a hart
 */
void metal_clint_set_soft_irq(uint32_t hart_id)
{
    *CLINT_MSIP_PTR(hart_id) = 0x1;
}

/**
 * @brief Clear software interrupt for a hart
 */
void metal_clint_clear_soft_irq(uint32_t hart_id)
{
    *CLINT_MSIP_PTR(hart_id) = 0x0;
}

/**
 * @brief Read Machine Timer Compare (MTIMECMP) register
 */
uint64_t metal_clint_read_mtimecmp(uint32_t hart_id)
{
    uint64_t low, high;
    
    // Read low word first, then high word
    low = *CLINT_MTIMECMP_LOW_PTR(hart_id);
    high = *CLINT_MTIMECMP_HIGH_PTR(hart_id);
    
    return ((uint64_t)high << 32) | low;
}

/**
 * @brief Write Machine Timer Compare (MTIMECMP) register
 */
void metal_clint_write_mtimecmp(uint32_t hart_id, uint64_t value)
{
    // Write high word first, then low word (to prevent spurious interrupts)
    // Set to maximum value first to disable timer
    *CLINT_MTIMECMP_HIGH_PTR(hart_id) = 0xFFFFFFFF;
    *CLINT_MTIMECMP_LOW_PTR(hart_id) = 0xFFFFFFFF;
    
    // Then write the actual value
    *CLINT_MTIMECMP_HIGH_PTR(hart_id) = (uint32_t)(value >> 32);
    *CLINT_MTIMECMP_LOW_PTR(hart_id) = (uint32_t)(value & 0xFFFFFFFF);
}

/**
 * @brief Read Machine Timer (MTIME) register
 */
uint64_t metal_clint_read_mtime(void)
{
    uint64_t low, high, low2;
    
    // Read MTIME with overflow protection
    // Read high word, then low word, then high word again
    // If high word changed, re-read low word
    do {
        high = *CLINT_MTIME_HIGH_PTR;
        low = *CLINT_MTIME_LOW_PTR;
        low2 = *CLINT_MTIME_LOW_PTR;
    } while (high != *CLINT_MTIME_HIGH_PTR || low != low2);
    
    return ((uint64_t)high << 32) | low;
}

/**
 * @brief Write Machine Timer (MTIME) register
 */
void metal_clint_write_mtime(uint64_t value)
{
    // Write high word first, then low word
    *CLINT_MTIME_HIGH_PTR = (uint32_t)(value >> 32);
    *CLINT_MTIME_LOW_PTR = (uint32_t)(value & 0xFFFFFFFF);
}

/**
 * @brief Set up timer interrupt for a hart
 */
int metal_clint_set_timer(uint32_t hart_id, uint64_t timeout_us, uint64_t cpu_freq)
{
    uint64_t current_time;
    uint64_t target_time;
    uint64_t timeout_cycles;
    
    if (cpu_freq == 0) {
        return -1;
    }
    
    // Calculate timeout in cycles
    // timeout_cycles = (timeout_us * cpu_freq) / 1000000
    timeout_cycles = (timeout_us * cpu_freq) / 1000000;
    
    // Read current time
    current_time = metal_clint_read_mtime();
    
    // Calculate target time
    target_time = current_time + timeout_cycles;
    
    // Set MTIMECMP
    metal_clint_write_mtimecmp(hart_id, target_time);
    
    return 0;
}

/**
 * @brief Disable timer interrupt for a hart
 */
void metal_clint_disable_timer(uint32_t hart_id)
{
    // Set MTIMECMP to maximum value to disable timer interrupt
    metal_clint_write_mtimecmp(hart_id, 0xFFFFFFFFFFFFFFFFULL);
}

/**
 * @brief Get current time in microseconds
 */
uint64_t metal_clint_get_time_us(uint64_t cpu_freq)
{
    uint64_t mtime;
    uint64_t time_us;
    
    if (cpu_freq == 0) {
        return 0;
    }
    
    mtime = metal_clint_read_mtime();
    
    // Convert cycles to microseconds
    // time_us = (mtime * 1000000) / cpu_freq
    time_us = (mtime * 1000000ULL) / cpu_freq;
    
    return time_us;
}

/**
 * @brief Calculate CPU frequency using CLINT timer and mcycle CSR (32-bit only)
 * 
 * This function measures CPU cycles (using 32-bit mcycle CSR) over a known
 * period of RTC ticks (using CLINT MTIME, which increments at RTC_FREQ).
 * 
 * Note: This version uses only the 32-bit mcycle register. At 40MHz,
 * mcycle wraps every ~107 seconds, so measurement periods should be
 * kept under ~100 seconds to avoid wraparound issues. Uses fixed 0.1 second period.
 * 
 * Uses RTC_FREQ from platform.h (typically 32768 Hz).
 * Measurement time is fixed at 0.1 second (RTC_FREQ/10) to avoid mcycle wraparound.
 * 
 * @return Calculated CPU frequency in Hz, or 0 on error
 */
uint64_t metal_clint_calculate_cpu_freq(void)
{
    uint32_t mcycle_start, mcycle_end;
    uint64_t mtime_start, mtime_end;
    uint64_t mcycle_delta, mtime_delta;
    uint64_t cpu_freq;
    uint64_t measurement_time_rtc_ticks;
    
    // Use fixed measurement time (0.1 second at RTC_FREQ)
    // Shorter period reduces wraparound risk and improves accuracy
    measurement_time_rtc_ticks = RTC_FREQ / 10;  // 0.1 second
    
    // Read initial values using read_csr from encoding.h
    mcycle_start = (uint32_t)read_csr(mcycle);
    mtime_start = metal_clint_read_mtime();
    
    // Wait for MTIME to increment by the desired number of RTC ticks
    do {
        mtime_end = metal_clint_read_mtime();
    } while ((mtime_end - mtime_start) < measurement_time_rtc_ticks);
    
    // Read final mcycle value using read_csr from encoding.h
    mcycle_end = (uint32_t)read_csr(mcycle);
    
    // Calculate delta, handling potential wraparound
    if (mcycle_end >= mcycle_start) {
        // No wraparound occurred
        mcycle_delta = mcycle_end - mcycle_start;
    } else {
        // Wraparound occurred (mcycle wrapped from 0xFFFFFFFF to 0x00000000)
        // Calculate: (max_value - start) + end + 1
        mcycle_delta = ((uint64_t)0xFFFFFFFF - mcycle_start) + mcycle_end + 1;
    }
    
    mtime_delta = mtime_end - mtime_start;
    
    // Avoid division by zero
    if (mtime_delta == 0) {
        return 0;
    }
    
    // Calculate CPU frequency:
    // cpu_freq = (mcycle_delta * RTC_FREQ) / mtime_delta
    // Since mtime_delta is in RTC ticks and RTC_FREQ is RTC frequency,
    // this gives us CPU cycles per second (Hz)
    cpu_freq = ((uint64_t)mcycle_delta * (uint64_t)RTC_FREQ) / mtime_delta;
    
    return cpu_freq;
}

void handle_m_time_interrupt(void){
    metal_interrupt_disable(METAL_TIMER_INT);                           // Disable Timer Interrupt
    metal_clint_write_mtimecmp(0, metal_clint_read_mtime() + this_mtimer.time);        // Set the new timer interrupt timer
    this_mtimer.handler();                                                   // Run Timer Interrupt Handle 
    metal_interrupt_enable(METAL_TIMER_INT);                            // Enable Timer Interrupt	
}void metal_mtimer_isr_config(uint64_t time, function_ptr_t handler){
	this_mtimer.handler = handler;
	this_mtimer.time   = time;
	metal_clint_write_mtimecmp(0, metal_clint_read_mtime() + time);
	metal_interrupt_enable(METAL_TIMER_INT);
}

void metal_mtimer_isr_config_us(uint32_t time_us, function_ptr_t handler){
	uint32_t time;
	time = time_us * RTC_FREQ / 1000000;
	this_mtimer.handler = handler;
	this_mtimer.time   = time;
	metal_clint_write_mtimecmp(0, metal_clint_read_mtime() + time);
	metal_interrupt_enable(METAL_TIMER_INT);
}void metal_mtimer_isr_config_ms(uint32_t time_ms, function_ptr_t handler){
	uint32_t time;
	time = time_ms * RTC_FREQ / 1000;
	this_mtimer.handler = handler;
	this_mtimer.time   = time;
	metal_clint_write_mtimecmp(0, metal_clint_read_mtime() + time);
	metal_interrupt_enable(METAL_TIMER_INT);
}