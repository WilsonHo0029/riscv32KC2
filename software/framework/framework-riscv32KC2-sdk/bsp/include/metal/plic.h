/* PLIC (Platform-Level Interrupt Controller) driver header for AI RISC-V KC32 System */

#ifndef METAL_PLIC_H
#define METAL_PLIC_H

#include <stdint.h>
#include <stddef.h>
#include "../platform.h"

/* PLIC Configuration */
#define PLIC_NUM_SOURCES       32      // Number of interrupt sources
#define PLIC_MAX_PRIORITY      7       // Maximum priority (3-bit: 0-7)
#define PLIC_HART_NUM          1       // Number of harts (single-hart system)
#define PLIC_PRIO_WIDTH        3        // Priority width in bits

/* PLIC Register Offsets (from base address) */
#define PLIC_PRIORITY_OFFSET(irq_id)          ((irq_id) * 4)                    // Priority register for interrupt ID
#define PLIC_PENDING_OFFSET(word_index)       (0x1000 + (word_index) * 4)       // Pending bits
#define PLIC_ENABLE_OFFSET(hart_id, word_idx) (0x2000 + (hart_id) * 0x80 + (word_idx) * 4)  // Enable bits
#define PLIC_THRESHOLD_OFFSET(hart_id)        (0x200000 + (hart_id) * 0x1000)  // Threshold register
#define PLIC_CLAIM_OFFSET(hart_id)            (0x200004 + (hart_id) * 0x1000)  // Claim/Complete register

/* PLIC Register Pointers */
#define PLIC_PTR               ((volatile uint32_t *)(uintptr_t)PLIC_BASE)
#define PLIC_PRIORITY_PTR(irq_id)             ((volatile uint32_t *)((uintptr_t)PLIC_PTR + PLIC_PRIORITY_OFFSET(irq_id)))
#define PLIC_PENDING_PTR(word_index)          ((volatile uint32_t *)((uintptr_t)PLIC_PTR + PLIC_PENDING_OFFSET(word_index)))
#define PLIC_ENABLE_PTR(hart_id, word_idx)    ((volatile uint32_t *)((uintptr_t)PLIC_PTR + PLIC_ENABLE_OFFSET(hart_id, word_idx)))
#define PLIC_THRESHOLD_PTR(hart_id)            ((volatile uint32_t *)((uintptr_t)PLIC_PTR + PLIC_THRESHOLD_OFFSET(hart_id)))
#define PLIC_CLAIM_PTR(hart_id)                ((volatile uint32_t *)((uintptr_t)PLIC_PTR + PLIC_CLAIM_OFFSET(hart_id)))

/* Function Prototypes */

/**
 * @brief Initialize PLIC
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @return 0 on success, -1 on error
 */
int metal_plic_init(uint32_t hart_id);

/**
 * @brief Set interrupt priority
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1, interrupt 0 is unused)
 * @param priority Priority value (0-7, where 0 = disabled, 7 = highest)
 * @return 0 on success, -1 on error
 */
int metal_plic_set_priority(uint32_t irq_id, uint32_t priority);

/**
 * @brief Get interrupt priority
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return Priority value (0-7), or 0 on error
 */
uint32_t metal_plic_get_priority(uint32_t irq_id);

/**
 * @brief Enable interrupt for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return 0 on success, -1 on error
 */
int metal_plic_enable_irq(uint32_t hart_id, uint32_t irq_id);

/**
 * @brief Disable interrupt for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return 0 on success, -1 on error
 */
int metal_plic_disable_irq(uint32_t hart_id, uint32_t irq_id);

/**
 * @brief Check if interrupt is enabled for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return 1 if enabled, 0 if disabled, -1 on error
 */
int metal_plic_is_irq_enabled(uint32_t hart_id, uint32_t irq_id);

/**
 * @brief Set interrupt threshold for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param threshold Threshold value (0-7, interrupts with priority > threshold are enabled)
 * @return 0 on success, -1 on error
 */
int metal_plic_set_threshold(uint32_t hart_id, uint32_t threshold);

/**
 * @brief Get interrupt threshold for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @return Threshold value (0-7), or 0 on error
 */
uint32_t metal_plic_get_threshold(uint32_t hart_id);

/**
 * @brief Check if interrupt is pending
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return 1 if pending, 0 if not pending, -1 on error
 */
int metal_plic_is_irq_pending(uint32_t irq_id);

/**
 * @brief Claim an interrupt (read interrupt ID and clear pending)
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @return Interrupt ID (1 to PLIC_NUM_SOURCES-1), or 0 if no interrupt pending
 */
uint32_t metal_plic_claim(uint32_t hart_id);

/**
 * @brief Complete an interrupt (acknowledge interrupt completion)
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return 0 on success, -1 on error
 */
int metal_plic_complete(uint32_t hart_id, uint32_t irq_id);

/**
 * @brief Get pending interrupt bits for a word
 * @param word_index Word index (0 for first 32 interrupts)
 * @return 32-bit pending bits word
 */
uint32_t metal_plic_get_pending(uint32_t word_index);

/**
 * @brief Get enabled interrupt bits for a hart and word
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param word_index Word index (0 for first 32 interrupts)
 * @return 32-bit enable bits word
 */
uint32_t metal_plic_get_enable(uint32_t hart_id, uint32_t word_index);

void handle_m_ext_interrupt(void);

#endif /* METAL_PLIC_H */

