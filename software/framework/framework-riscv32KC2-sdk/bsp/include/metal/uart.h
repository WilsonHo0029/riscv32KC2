#ifndef METAL_UART_HEADER
#define METAL_UART_HEADER

#include <stdint.h>
#include <stddef.h>
#include <sys/types.h>
#include <platform.h>

/* UART Register offsets (word-aligned for APB, byte addresses) */
#define UART_REG_TXBUF          0x00  // Transmit Buffer Register
#define UART_REG_CTRL           0x04  // Control and Status Register
#define UART_REG_RXBUF          0x08  // Receive Buffer Register
#define UART_REG_BAUD           0x0c  // Baud Rate Divisor Register

/* CTRL Register (UART_REG_CTRL) - Control and Status Register
 * Bit layout:
 *   [31:16]  Reserved
 *   [15]     TX_FIFO_FULL  - Transmit FIFO is full
 *   [14]     TX_BUSY       - Transmitter is busy
 *   [13]     TX_FIFO_EMPTY - Transmit FIFO is empty
 *   [12]     RX_FIFO_FULL  - Receive FIFO is full
 *   [11]     RX_BUSY       - Receiver is busy
 *   [10]     RX_FIFO_EMPTY - Receive FIFO is empty
 *   [9:2]    Reserved
 *   [1]      RX_EN         - Receive enable
 *   [0]      TX_EN         - Transmit enable
 */

/* CTRL register control bits (write) */
#define UART_CTRL_TX_EN         (1 << 0)   // Enable transmitter
#define UART_CTRL_RX_EN         (1 << 1)   // Enable receiver

/* CTRL register status bits (read) */
#define UART_CTRL_RX_FIFO_EMPTY (1 << 10)  // Receive FIFO is empty
#define UART_CTRL_RX_BUSY       (1 << 11)  // Receiver is busy
#define UART_CTRL_RX_FIFO_FULL  (1 << 12)  // Receive FIFO is full
#define UART_CTRL_TX_FIFO_EMPTY (1 << 13)  // Transmit FIFO is empty
#define UART_CTRL_TX_BUSY       (1 << 14)  // Transmitter is busy
#define UART_CTRL_TX_FIFO_FULL  (1 << 15)  // Transmit FIFO is full

/* TXBUF Register (UART_REG_TXBUF) - Transmit Buffer
 *   [7:0]   Data to transmit
 *   [31:8]  Reserved (read as 0)
 */

/* RXBUF Register (UART_REG_RXBUF) - Receive Buffer
 *   [7:0]   Received data
 *   [31:8]  Reserved (read as 0)
 */

/* BAUD Register (UART_REG_BAUD) - Baud Rate Divisor
 *   [15:0]  Baud count divisor (baud_cnt)
 *            Formula: baud_cnt = (CPU_FREQ / baud_rate) - 1
 *   [31:16] Reserved (read as 0)
 */

/*! @brief Initialize UART
 * @param baud_rate The baud rate of the UART device
 * @param bit No of data bits, range from 5 to 8 bits (currently not used, fixed at 8)
 * @param parity_en enable UART parity (currently not used, fixed at disabled)
 * @param parity_sel parity mode selection, 0 -> odd parity, 1 -> even parity (currently not used)
 * @param lin_en enable LIN protocol (currently not used, fixed at disabled)
 * @return 0 If no error.*/
int metal_uart_init(size_t baud_rate, size_t bit,
                    size_t parity_en, size_t parity_sel, size_t lin_en);

/*! @brief Write a character to UART
 * @param c The character to write
 * @return 0 on success, -1 on error */
int metal_uart_putc(int c);

/*! @brief Read a character from UART
 * @return The character read, or -1 on error */
int metal_uart_getc(void);

/*! @brief Read data from UART
 * @param ptr Pointer to buffer to store read data
 * @param len Number of bytes to read
 * @return Number of bytes read */
ssize_t metal_uart_read(void *ptr, size_t len);

/*! @brief UART0 Print string with newline
 * @param ptr The pointer to string
 * @param len The length of string
 * @return length of string If no error.*/
int metal_uart0_print(void *ptr, size_t len);

#endif /* METAL_UART_HEADER */
