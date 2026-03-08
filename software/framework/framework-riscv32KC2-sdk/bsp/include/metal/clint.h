/* CLINT (Core Local Interruptor) driver header for AI RISC-V KC32 System */

#ifndef METAL_CLINT_H
#define METAL_CLINT_H

#include <stdint.h>
#include <stddef.h>
#include "../platform.h"
#include <metal/interrupt.h>
/* CLINT Register Offsets */
#define CLINT_MSIP_OFFSET(hart_id)     (0x0000 + (hart_id) * 4)
#define CLINT_MTIMECMP_OFFSET(hart_id) (0x4000 + (hart_id) * 8)
#define CLINT_MTIME_OFFSET             0xBFF8

/* CLINT Register Pointers */
#define CLINT_MSIP_PTR(hart_id)        ((volatile uint32_t *)((uintptr_t)CLINT_PTR + CLINT_MSIP_OFFSET(hart_id)))
#define CLINT_MTIMECMP_LOW_PTR(hart_id) ((volatile uint32_t *)((uintptr_t)CLINT_PTR + CLINT_MTIMECMP_OFFSET(hart_id)))
#define CLINT_MTIMECMP_HIGH_PTR(hart_id) ((volatile uint32_t *)((uintptr_t)CLINT_PTR + CLINT_MTIMECMP_OFFSET(hart_id) + 4))
#define CLINT_MTIME_LOW_PTR            ((volatile uint32_t *)((uintptr_t)CLINT_PTR + CLINT_MTIME_OFFSET))
#define CLINT_MTIME_HIGH_PTR           ((volatile uint32_t *)((uintptr_t)CLINT_PTR + CLINT_MTIME_OFFSET + 4))
struct metal_clint_mtimer {    function_ptr_t handler;
                        uint64_t time;
};

/* Function Prototypes */

/**
 * @brief Read Machine Software Interrupt Pending (MSIP) register
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @return MSIP value (bit 0 = software interrupt pending)
 */
uint32_t metal_clint_read_msip(uint32_t hart_id);

/**
 * @brief Write Machine Software Interrupt Pending (MSIP) register
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param value MSIP value (bit 0 = software interrupt pending)
 */
void metal_clint_write_msip(uint32_t hart_id, uint32_t value);

/**
 * @brief Trigger software interrupt for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 */
void metal_clint_set_soft_irq(uint32_t hart_id);

/**
 * @brief Clear software interrupt for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 */
void metal_clint_clear_soft_irq(uint32_t hart_id);

/**
 * @brief Read Machine Timer Compare (MTIMECMP) register
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @return 64-bit MTIMECMP value
 */
uint64_t metal_clint_read_mtimecmp(uint32_t hart_id);

/**
 * @brief Write Machine Timer Compare (MTIMECMP) register
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param value 64-bit MTIMECMP value
 */
void metal_clint_write_mtimecmp(uint32_t hart_id, uint64_t value);

/**
 * @brief Read Machine Timer (MTIME) register
 * @return 64-bit MTIME value
 */
uint64_t metal_clint_read_mtime(void);

/**
 * @brief Write Machine Timer (MTIME) register
 * @param value 64-bit MTIME value
 */
void metal_clint_write_mtime(uint64_t value);

/**
 * @brief Set up timer interrupt for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param timeout_us Timeout in microseconds
 * @param cpu_freq CPU frequency in Hz
 * @return 0 on success, -1 on error
 */
int metal_clint_set_timer(uint32_t hart_id, uint64_t timeout_us, uint64_t cpu_freq);

/**
 * @brief Disable timer interrupt for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 */
void metal_clint_disable_timer(uint32_t hart_id);

/**
 * @brief Get current time in microseconds
 * @param cpu_freq CPU frequency in Hz
 * @return Current time in microseconds
 */
uint64_t metal_clint_get_time_us(uint64_t cpu_freq);

/**
 * @brief Calculate CPU frequency using CLINT timer and mcycle CSR
 * 
 * Uses RTC_FREQ from platform.h (typically 32768 Hz).
 * Measurement time is fixed at 0.1 second (RTC_FREQ/10) to avoid mcycle wraparound.
 * 
 * @return Calculated CPU frequency in Hz, or 0 on error
 */
uint64_t metal_clint_calculate_cpu_freq(void);
void handle_m_time_interrupt(void);
void metal_mtimer_isr_config(uint64_t time, function_ptr_t handler);
void metal_mtimer_isr_config_us(uint32_t time_us, function_ptr_t handler);
void metal_mtimer_isr_config_ms(uint32_t time_ms, function_ptr_t handler);
#endif /* METAL_CLINT_H */

