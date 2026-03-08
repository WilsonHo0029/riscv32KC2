/* See LICENSE of license details. */

#include <stdint.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <metal/uart.h>
#include "platform.h"
#include "stub.h"

ssize_t _read(int fd, void* ptr, size_t len)
{
    // The below code was copied from freedom-e-sdk, but seems it is definitely wrong, so just comment it out
    //   Need to implement this function in the future, otherwise cannot use the C scanf function
    //uint8_t * current = (uint8_t *) ptr;
    //  uint32_t * uart_rx = METAL_REG(uart0->base_adr, UART_REG_RXFIFO);
    //  uint8_t * uart_rx_cnt = (uint8_t *) ((METAL_REG(uart0->base_adr, UART_REG_RXCTRL) >> 16) & 0x07);
    
    //ssize_t result = 0;

    if (isatty(fd)) {
    //  for (current = (uint8_t *)ptr; (current < ((uint8_t *)ptr) + len) && (((METAL_REG(uart0->base_adr, UART_REG_RXCTRL) >> 16) & 0x07) > 0); current ++) {
    //      *current = METAL_REG(uart0->base_adr, UART_REG_RXFIFO);
    //      result++;
		//return metal_uart_read(uart0, ptr, len);
	}
    //  return result;
    //}

  return _stub(EBADF);
}
