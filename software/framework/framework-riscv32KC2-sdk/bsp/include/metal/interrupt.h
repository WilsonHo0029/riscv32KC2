/*! @file interrupt.h
 *  @brief API for registering and manipulating interrupts
 */

#ifndef METAL_INTERRUPT_HEADER
#define METAL_INTERRUPT_HEADER

#include <stddef.h>

#define METAL_TIMER_INT       1
#define METAL_EXTERNAL_INT    2
#define METAL_SOFTWARE_INT    3
#define METAL_ALL_INT         4
#define METAL_GENERAL_INT     5

/*! @brief Wait for Interrupt */
inline void metal_interrupt_wfi(void) {

    __asm__ volatile ("wfi");
}

/*! @brief Enable an interrupt
 * @param id The interrupt ID to enable 
 * METAL_TIMER_INT, EXTERNAL_INT, SOFTWARE_INT, ALL_INT, GENERAL_INT*/
void metal_interrupt_enable(int id);

/*! @brief Disable an interrupt
 * @param id The interrupt ID to enable
 * METAL_TIMER_INT, EXTERNAL_INT, SOFTWARE_INT, ALL_INT, GENERAL_INT*/
void metal_interrupt_disable(int id);

#endif