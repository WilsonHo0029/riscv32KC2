/* PLIC (Platform-Level Interrupt Controller) driver implementation for AI RISC-V KC32 System */

#include "../include/metal/plic.h"
#include <stdint.h>

/**
 * @brief Initialize PLIC
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @return 0 on success, -1 on error
 */
int metal_plic_init(uint32_t hart_id)
{
    if (hart_id >= PLIC_HART_NUM) {
        return -1;
    }
    
    // Set threshold to 0 (enable all interrupts with priority > 0)
    metal_plic_set_threshold(hart_id, 0);
    
    // Disable all interrupts by default
    for (uint32_t i = 1; i < PLIC_NUM_SOURCES; i++) {
        metal_plic_disable_irq(hart_id, i);
        metal_plic_set_priority(i, 0);
    }
    
    return 0;
}

/**
 * @brief Set interrupt priority
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1, interrupt 0 is unused)
 * @param priority Priority value (0-7, where 0 = disabled, 7 = highest)
 * @return 0 on success, -1 on error
 */
int metal_plic_set_priority(uint32_t irq_id, uint32_t priority)
{
    if (irq_id == 0 || irq_id >= PLIC_NUM_SOURCES) {
        return -1;
    }
    
    if (priority > PLIC_MAX_PRIORITY) {
        return -1;
    }
    
    // Priority register for interrupt ID (interrupt 0 is unused, so irq_id is the index)
    *PLIC_PRIORITY_PTR(irq_id) = priority & PLIC_MAX_PRIORITY;
    
    return 0;
}

/**
 * @brief Get interrupt priority
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return Priority value (0-7), or 0 on error
 */
uint32_t metal_plic_get_priority(uint32_t irq_id)
{
    if (irq_id == 0 || irq_id >= PLIC_NUM_SOURCES) {
        return 0;
    }
    
    return *PLIC_PRIORITY_PTR(irq_id) & PLIC_MAX_PRIORITY;
}

/**
 * @brief Enable interrupt for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return 0 on success, -1 on error
 */
int metal_plic_enable_irq(uint32_t hart_id, uint32_t irq_id)
{
    if (hart_id >= PLIC_HART_NUM) {
        return -1;
    }
    
    if (irq_id == 0 || irq_id >= PLIC_NUM_SOURCES) {
        return -1;
    }
    
    // Calculate word index and bit position
    uint32_t word_index = irq_id / 32;
    uint32_t bit_pos = irq_id % 32;
    
    // Read current enable word, set bit, write back
    volatile uint32_t *enable_ptr = PLIC_ENABLE_PTR(hart_id, word_index);
    uint32_t enable_word = *enable_ptr;
    enable_word |= (1U << bit_pos);
    *enable_ptr = enable_word;
    
    return 0;
}

/**
 * @brief Disable interrupt for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return 0 on success, -1 on error
 */
int metal_plic_disable_irq(uint32_t hart_id, uint32_t irq_id)
{
    if (hart_id >= PLIC_HART_NUM) {
        return -1;
    }
    
    if (irq_id == 0 || irq_id >= PLIC_NUM_SOURCES) {
        return -1;
    }
    
    // Calculate word index and bit position
    uint32_t word_index = irq_id / 32;
    uint32_t bit_pos = irq_id % 32;
    
    // Read current enable word, clear bit, write back
    volatile uint32_t *enable_ptr = PLIC_ENABLE_PTR(hart_id, word_index);
    uint32_t enable_word = *enable_ptr;
    enable_word &= ~(1U << bit_pos);
    *enable_ptr = enable_word;
    
    return 0;
}

/**
 * @brief Check if interrupt is enabled for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return 1 if enabled, 0 if disabled, -1 on error
 */
int metal_plic_is_irq_enabled(uint32_t hart_id, uint32_t irq_id)
{
    if (hart_id >= PLIC_HART_NUM) {
        return -1;
    }
    
    if (irq_id == 0 || irq_id >= PLIC_NUM_SOURCES) {
        return -1;
    }
    
    // Calculate word index and bit position
    uint32_t word_index = irq_id / 32;
    uint32_t bit_pos = irq_id % 32;
    
    // Read enable word and check bit
    volatile uint32_t *enable_ptr = PLIC_ENABLE_PTR(hart_id, word_index);
    uint32_t enable_word = *enable_ptr;
    
    return (enable_word >> bit_pos) & 1;
}

/**
 * @brief Set interrupt threshold for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param threshold Threshold value (0-7, interrupts with priority > threshold are enabled)
 * @return 0 on success, -1 on error
 */
int metal_plic_set_threshold(uint32_t hart_id, uint32_t threshold)
{
    if (hart_id >= PLIC_HART_NUM) {
        return -1;
    }
    
    if (threshold > PLIC_MAX_PRIORITY) {
        return -1;
    }
    
    *PLIC_THRESHOLD_PTR(hart_id) = threshold & PLIC_MAX_PRIORITY;
    
    return 0;
}

/**
 * @brief Get interrupt threshold for a hart
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @return Threshold value (0-7), or 0 on error
 */
uint32_t metal_plic_get_threshold(uint32_t hart_id)
{
    if (hart_id >= PLIC_HART_NUM) {
        return 0;
    }
    
    return *PLIC_THRESHOLD_PTR(hart_id) & PLIC_MAX_PRIORITY;
}

/**
 * @brief Check if interrupt is pending
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return 1 if pending, 0 if not pending, -1 on error
 */
int metal_plic_is_irq_pending(uint32_t irq_id)
{
    if (irq_id == 0 || irq_id >= PLIC_NUM_SOURCES) {
        return -1;
    }
    
    // Calculate word index and bit position
    uint32_t word_index = irq_id / 32;
    uint32_t bit_pos = irq_id % 32;
    
    // Read pending word and check bit
    volatile uint32_t *pending_ptr = PLIC_PENDING_PTR(word_index);
    uint32_t pending_word = *pending_ptr;
    
    return (pending_word >> bit_pos) & 1;
}

/**
 * @brief Claim an interrupt (read interrupt ID and clear pending)
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @return Interrupt ID (1 to PLIC_NUM_SOURCES-1), or 0 if no interrupt pending
 */
uint32_t metal_plic_claim(uint32_t hart_id)
{
    if (hart_id >= PLIC_HART_NUM) {
        return 0;
    }
    
    // Reading the claim register returns the interrupt ID and clears the pending bit
    uint32_t irq_id = *PLIC_CLAIM_PTR(hart_id);
    
    // Return 0 if no interrupt (interrupt 0 is unused)
    if (irq_id == 0 || irq_id >= PLIC_NUM_SOURCES) {
        return 0;
    }
    
    return irq_id;
}

/**
 * @brief Complete an interrupt (acknowledge interrupt completion)
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param irq_id Interrupt ID (1 to PLIC_NUM_SOURCES-1)
 * @return 0 on success, -1 on error
 */
int metal_plic_complete(uint32_t hart_id, uint32_t irq_id)
{
    if (hart_id >= PLIC_HART_NUM) {
        return -1;
    }
    
    if (irq_id == 0 || irq_id >= PLIC_NUM_SOURCES) {
        return -1;
    }
    
    // Writing the interrupt ID to the claim/complete register completes the interrupt
    *PLIC_CLAIM_PTR(hart_id) = irq_id;
    
    return 0;
}

/**
 * @brief Get pending interrupt bits for a word
 * @param word_index Word index (0 for first 32 interrupts)
 * @return 32-bit pending bits word
 */
uint32_t metal_plic_get_pending(uint32_t word_index)
{
    // For 32 interrupts, we only need word_index 0
    if (word_index > 0) {
        return 0;
    }
    
    return *PLIC_PENDING_PTR(word_index);
}

/**
 * @brief Get enabled interrupt bits for a hart and word
 * @param hart_id Hart ID (typically 0 for single-hart systems)
 * @param word_index Word index (0 for first 32 interrupts)
 * @return 32-bit enable bits word
 */
uint32_t metal_plic_get_enable(uint32_t hart_id, uint32_t word_index)
{
    if (hart_id >= PLIC_HART_NUM) {
        return 0;
    }
    
    // For 32 interrupts, we only need word_index 0
    if (word_index > 0) {
        return 0;
    }
    
    return *PLIC_ENABLE_PTR(hart_id, word_index);
}

