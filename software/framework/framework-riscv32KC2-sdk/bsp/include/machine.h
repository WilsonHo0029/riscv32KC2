#ifndef METAL_MACHINE_HEADER
#define METAL_MACHINE_HEADER

#include <stdio.h>
#include <stdint.h>
#include "const.h"

// Some things missing from the official encoding.h
#define MCAUSE_INT         0x80000000
#define MCAUSE_CAUSE       0x7FFFFFFF

/****************************************************************************
 * Platform definitions
 *****************************************************************************/

#define TRAPVEC_TABLE_CTRL_ADDR _AC(0x00001010,UL)
#define CLINT_CTRL_ADDR         _AC(0x02000000,UL)
#define PLIC_CTRL_ADDR          _AC(0x0C000000,UL)
#define AON_CTRL_ADDR           _AC(0x10000000,UL)
#define SYS_CTRL_ADDR           _AC(0x10000200,UL)  
#define HCLK_CTRL_ADDR          _AC(0x10008000,UL) 
#define OTP_CTRL_ADDR           _AC(0x10010000,UL) 
#define GPIO_CTRL_ADDR          _AC(0x10012000,UL)
#define UART0_CTRL_ADDR         _AC(0x10013000,UL)
#define SPI0_CTRL_ADDR          _AC(0x10014000,UL)
#define PWM0_CTRL_ADDR          _AC(0x10015000,UL)
#define UART1_CTRL_ADDR         _AC(0x10023000,UL)
#define SPI1_CTRL_ADDR          _AC(0x10024000,UL)
#define PWM1_CTRL_ADDR          _AC(0x10025000,UL)
#define SPI2_CTRL_ADDR          _AC(0x10034000,UL)
#define DA0_CTRL_ADDR           _AC(0x10035000,UL)
#define AD0_CTRL_ADDR           _AC(0x10040000,UL)  
#define CAN_CTRL_ADDR           _AC(0x10041000,UL)          
#define I2C_CTRL_ADDR           _AC(0x10042000,UL)
#define ABZ_CTRL_ADDR           _AC(0x10043000,UL)    
#define MTP_CTRL_ADDR           _AC(0x10044000,UL) 
#define TMR_CTRL_ADDR           _AC(0x10045000,UL)     
#define SPI0_MMAP_ADDR          _AC(0x20000000,UL)
#define MEM_CTRL_ADDR           _AC(0x80000000,UL)

// IOF Mappings
#define IOF0_SPI1_MASK          _AC(0x0000FF80,UL)
#define SPI11_NUM_SS     (4)
#define IOF_SPI1_SS0          (12u)
#define IOF_SPI1_SS1          (11u)
#define IOF_SPI1_SS2          (10u)
#define IOF_SPI1_SS3          (9u)
#define IOF_SPI1_MOSI         (13u)
#define IOF_SPI1_MISO         (14u)
#define IOF_SPI1_SCK          (15u)
#define IOF_SPI1_DQ0          (13u)
#define IOF_SPI1_DQ1          (14u)
#define IOF_SPI1_DQ2          (8u)
#define IOF_SPI1_DQ3          (7u)

#define IOF0_SPI2_MASK          _AC(0xFC000000,UL)
#define SPI2_NUM_SS       (1)
#define IOF_SPI2_SS0          (26u)
#define IOF_SPI2_MOSI         (27u)
#define IOF_SPI2_MISO         (28u)
#define IOF_SPI2_SCK          (29u)
#define IOF_SPI2_DQ0          (27u)
#define IOF_SPI2_DQ1          (28u)
#define IOF_SPI2_DQ2          (30u)
#define IOF_SPI2_DQ3          (31u)

#define IOF0_UART0_MASK         _AC(0x00030000, UL)
#define IOF_UART0_RX   (16u)
#define IOF_UART0_TX   (17u)

#define IOF0_UART1_MASK         _AC(0x03000000, UL)
#define IOF_UART1_RX (24u)
#define IOF_UART1_TX (25u)

#define IOF1_I2C_MASK           _AC(0xC0000000, UL)
#define IOF_I2C_SDA             (30u)
#define IOF_I2C_SCL             (31u)

#define IOF1_PWM0_MASK          _AC(0x00000FFF, UL)
#define IOF1_PWM1_MASK          _AC(0x0000F000, UL)

#define IOF0_DA0_MASK           _AC(0x007C0000, UL)              

// Interrupt Numbers
#define INT_RESERVED    0
#define INT_WDOGCMP     1
#define INT_RTCCMP      2
#define INT_OT150C      3
#define INT_UART0_BASE  4
#define INT_UART1_BASE  5
#define INT_SPI0_BASE   6
#define INT_SPI1_BASE   7
#define INT_SPI2_BASE   8
#define INT_GPIO_BASE   9
#define INT_PWM0_BASE   41
#define INT_PWM1_BASE   42
#define INT_AD0_BASE    46
#define INT_I2C_BASE    47
#define INT_CAN_BASE    48
#define INT_ABZ_BASE    49
#define INT_TMR0_BASE   50
#define INT_TMR1_BASE   51

// Helper functions
#define _REG8(p, i)             (*(volatile uint8_t *) ((p) + (i)))
#define _REG32(p, i)            (*(volatile uint32_t *) ((p) + (i)))
#define _REG32P(p, i)           ((volatile uint32_t *) ((p) + (i)))
#define AON_REG(offset)         _REG32(AON_CTRL_ADDR, offset)
#define SYS_REG(offset)         _REG32(SYS_CTRL_ADDR, offset)
#define HCLK_REG(offset)        _REG32(HCLK_CTRL_ADDR, offset)
#define CLINT_REG(offset)       _REG32(CLINT_CTRL_ADDR, offset)
#define OTP_REG(offset)         _REG32(OTP_CTRL_ADDR, offset)
#define GPIO_REG(offset)        _REG32(GPIO_CTRL_ADDR, offset)
#define OTP_REG(offset)         _REG32(OTP_CTRL_ADDR, offset)
#define PLIC_REG(offset)        _REG32(PLIC_CTRL_ADDR, offset)
#define PRCI_REG(offset)        _REG32(PRCI_CTRL_ADDR, offset)
#define PWM0_REG(offset)        _REG32(PWM0_CTRL_ADDR, offset)
#define PWM1_REG(offset)        _REG32(PWM1_CTRL_ADDR, offset)
#define PWM2_REG(offset)        _REG32(PWM2_CTRL_ADDR, offset)
#define DA0_REG(offset)         _REG32(DA0_CTRL_ADDR, offset)
#define AD0_REG(offset)         _REG32(AD0_CTRL_ADDR, offset)
#define UART0_REG(offset)       _REG32(UART0_CTRL_ADDR, offset)
#define UART1_REG(offset)       _REG32(UART1_CTRL_ADDR, offset)
#define CAN_REG(offset)         _REG8(CAN_CTRL_ADDR, offset) 
#define I2C_REG(offset)         _REG8(I2C_CTRL_ADDR, offset)
#define ABZ_REG(offset)         _REG32(ABZ_CTRL_ADDR, offset)
#define MTP_REG(offset)         _REG32(MTP_CTRL_ADDR, offset)
#define TMR_REG(offset)         _REG32(TMR_CTRL_ADDR, offset)

#define METAL_REG(base, offset) _REG32(base, offset)
#define _BIT(n)					(1<<n)
#define _SBF(n, v)				(v<<n)
#define _CMPB(x, n)			    ((x & _BIT(n)) >> n)
// Misc

#define NUM_GPIO 32

#define PLIC_NUM_INTERRUPTS 52
#define PLIC_NUM_PRIORITIES 7
#define RTC_FREQ 32768
//#define PERIP_FREQ 16000000
#define PERIP_FREQ 16000000
#define PWM_FREQ 20000000
typedef void (*function_ptr_t) (void);

#endif
