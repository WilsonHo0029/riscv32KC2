/* Copyright 2024-present AI RISC-V KC32 */
/* SPDX-License-Identifier: Apache-2.0 */

#include <stdint.h>
#include <stdio.h>
#include <unistd.h>

#include <metal/uart.h>
#include <metal/clint.h>
#include <encoding.h>
#include "platform.h"

extern int main(int argc, char** argv);
extern void trap_entry();
#ifdef USE_PLIC
extern void handle_m_ext_interrupt();
#endif

#ifdef USE_M_TIME
extern void handle_m_time_interrupt(void);
#endif

uintptr_t handle_trap(uintptr_t mcause, uintptr_t epc)
{
  if (0){
#ifdef USE_PLIC
    // External Machine-Level interrupt from PLIC
  } else if ((mcause & MCAUSE_INT) && ((mcause & MCAUSE_CAUSE) == IRQ_M_EXT)) {
    handle_m_ext_interrupt();
#endif
#ifdef USE_M_TIME
    // External Machine-Level interrupt from PLIC
  } else if ((mcause & MCAUSE_INT) && ((mcause & MCAUSE_CAUSE) == IRQ_M_TIMER)){
    handle_m_time_interrupt();
#endif
  }
  else {
    write(1, "trap\n", 5);
    _exit(1 + mcause);
  }
  return epc;
}
void _init()
{
  #ifndef NO_INIT

  //// If not define METAL_DEBUG, UART0 would not be defined and printf will be disabled.
  #ifdef METAL_DEBUG
   metal_uart_init(115200, 8, 0, 0, 0);
  #endif

  write_csr(mtvec, &trap_entry); 

  #endif
}

void _fini()
{
}

