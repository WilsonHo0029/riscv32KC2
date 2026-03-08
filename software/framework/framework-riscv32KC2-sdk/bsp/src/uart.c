
#include "../include/metal/uart.h"
#include <stdint.h>
#include <stddef.h>
#include <unistd.h>
#include "platform.h"

int metal_uart_init(size_t baud_rate, size_t bit,
                    size_t parity_en, size_t parity_sel, size_t lin_en)
{
    // 1. Set baud rate divisor
    // In this module, baud_cnt is used directly for bit timing.
    // Formula: baud_cnt = (CPU_FREQ / baud_rate) - 1
    uint32_t div = (CPU_FREQ / baud_rate);
    UART0_PTR[UART_REG_BAUD / 4] = div - 1;
    
    // 2. Enable Transmitter (Set tx_en bit)
    UART0_PTR[UART_REG_CTRL / 4] = UART_CTRL_TX_EN;
    
    return 0;
}

int metal_uart_putc(int c)
{
    // Wait for Transmitter to be ready (FIFO not full / not busy)
    // Note: The hardware exposes tx_busy (bit 14), which indicates
    // the FIFO is non-empty or the shifter is active.
    while (UART0_PTR[UART_REG_CTRL / 4] & UART_CTRL_TX_FIFO_FULL);
    
    // Write character to Transmit Buffer
    UART0_PTR[UART_REG_TXBUF / 4] = (uint32_t)(c & 0xFF);
    
    return 0;
}

int metal_uart_getc(void)
{
    // Read from Receiver Buffer Register
    return (int)(UART0_PTR[UART_REG_RXBUF / 4] & 0xFF);
}

ssize_t metal_uart_read(void *ptr, size_t len)
{
    uint8_t *current = (uint8_t *)ptr;
    size_t i;
    
    for (i = 0; i < len; i++) {
        // Wait for data available (RX buffer not empty)
        // Note: This is a simple implementation - you may need to add
        // proper status checking based on your UART hardware
        current[i] = (uint8_t)(UART0_PTR[UART_REG_RXBUF / 4] & 0xFF);
    }
    
    return (ssize_t)i;
}

int metal_uart0_print(void *ptr, size_t len)
{
    uint8_t *current = (uint8_t *)ptr;
    
    for (size_t i = 0; i < len; i++) {
        while (UART0_PTR[UART_REG_CTRL / 4] & UART_CTRL_TX_FIFO_FULL);
        UART0_PTR[UART_REG_TXBUF / 4] = current[i];
        
        if (current[i] == '\n') {
            while (UART0_PTR[UART_REG_CTRL / 4] & UART_CTRL_TX_FIFO_FULL);
            UART0_PTR[UART_REG_TXBUF / 4] = '\r';
        }
    }
    
    return len;
}
