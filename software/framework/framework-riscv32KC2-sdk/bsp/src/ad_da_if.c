/* ADC/DAC Interface driver implementation for AI RISC-V KC32 System */

#include "../include/metal/ad_da_if.h"
#include "../include/platform.h"
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

int metal_ad_da_if_init(void)
{
    /* Disable ADC and DAC by default
     * AD_DA_PTR points to 0x10001000 as a word-aligned pointer (uint32_t *)
     * Register offsets are relative to base, divided by 4 for word indexing
     */
    /* Disable ADC (address: 0x10001100) */
    AD_DA_PTR[ADC_REG_CONTROL / 4] = 0x0;
    
    /* Reset ADC offset */
    AD_DA_PTR[ADC_REG_OFFSET / 4] = 0x0;
    
    /* Stop DAC */
    AD_DA_PTR[DAC_REG_CONTROL / 4] = 0x0;
    
    /* Clear DAC data */
    AD_DA_PTR[DAC_REG_DATA1 / 4] = 0x0;
    AD_DA_PTR[DAC_REG_DATA2 / 4] = 0x0;
    AD_DA_PTR[DAC_REG_DATA3 / 4] = 0x0;

    return 0;
}

int metal_adc_configure(const adc_config_t *config)
{
    if (!config) {
        return -1;
    }
    
    /* Read current control register */
    uint32_t ctrl = AD_DA_PTR[ADC_REG_CONTROL / 4];
    
    /* Clear and set sample rate (bits 2:1) */
    ctrl &= ~ADC_CTRL_SAMP_RATE_MASK;
    ctrl |= ((config->samp_rate & 0x3) << ADC_CTRL_SAMP_RATE_SHIFT);
    
    /* Clear and set wait time (bits 8:3) */
    ctrl &= ~ADC_CTRL_WAIT_TIME_MASK;
    ctrl |= ((config->wait_time & 0x3F) << ADC_CTRL_WAIT_TIME_SHIFT);
    
    /* Write control register (preserve enable bit) */
    AD_DA_PTR[ADC_REG_CONTROL / 4] = ctrl;
    
    /* Set offset */
    metal_adc_set_offset(config->offset);
    
    return 0;
}

int metal_adc_enable(bool enable)
{
    uint32_t ctrl = AD_DA_PTR[ADC_REG_CONTROL / 4];
    
    if (enable) {
        ctrl |= ADC_CTRL_EN;
    } else {
        ctrl &= ~ADC_CTRL_EN;
    }
    
    AD_DA_PTR[ADC_REG_CONTROL / 4] = ctrl;
    return 0;
}

int metal_adc_set_offset(uint16_t offset)
{
    if (offset > 0x1FFF) {
        return -1;  // Offset must be 13-bit (0-8191)
    }

    AD_DA_PTR[ADC_REG_OFFSET / 4] = (uint32_t)(offset & 0x1FFF);
    return 0;
}

int metal_adc_read(uint16_t *data)
{
    if (!data) {
        return -1;
    }

    uint32_t status = AD_DA_PTR[ADC_REG_STATUS / 4];
    
    *data = (uint16_t)(status & ADC_STATUS_DATA_MASK);
    return 0;
}

bool metal_adc_is_ready(void)
{
    uint32_t status = AD_DA_PTR[ADC_REG_STATUS / 4];
    
    return (status & ADC_STATUS_RDY_REQ) != 0;
}

int metal_adc_wait_ready(uint32_t timeout_ms)
{
    /* Simple polling wait - in a real implementation, you might want to use
     * interrupts or a more sophisticated delay mechanism */
    uint32_t count = 0;
    const uint32_t max_count = (timeout_ms > 0) ? (timeout_ms * 1000) : UINT32_MAX;
    
    while (count < max_count) {
        uint32_t status = AD_DA_PTR[ADC_REG_STATUS / 4];
        if (status & ADC_STATUS_RDY_REQ) {
            return 0;  // Ready
        }
        count++;
        /* Small delay - adjust based on CPU frequency */
        for (volatile int i = 0; i < 100; i++);
    }
    
    return -1;  // Timeout
}

int metal_adc_re_sample(void)
{
    /* Write to ADC status register with bit 16 cleared to clear the ready flag
     * This clears the ready flag and allows the ADC to start a new sample
     * The hardware clears r_adc_rdy when writing to status register (reg_addr 4'h2)
     * with bit 16 of pwdata = 0 (see apb_ad_da_if.v line 112-113)
     */
    uint32_t status = AD_DA_PTR[ADC_REG_STATUS / 4];
    
    /* Clear bit 16 to clear the ready flag (hardware expects bit 16 = 0 to clear) */
    status &= ~(1 << 16);
    
    /* Write back to clear the ready flag and trigger new sample */
    AD_DA_PTR[ADC_REG_STATUS / 4] = status;
    
    return 0;
}

int metal_dac_configure(uint8_t clk_cnt)
{
    uint32_t ctrl = AD_DA_PTR[DAC_REG_CONTROL / 4];
    
    /* Clear and set clock count (bits 8:1) */
    ctrl &= ~DAC_CTRL_CLK_CNT_MASK;
    ctrl |= ((clk_cnt & 0xFF) << DAC_CTRL_CLK_CNT_SHIFT);
    
    /* Write control register (preserve start bit) */
    AD_DA_PTR[DAC_REG_CONTROL / 4] = ctrl;
    
    return 0;
}

int metal_dac_set_data(uint16_t data1, uint16_t data2, uint16_t data3)
{
    AD_DA_PTR[DAC_REG_DATA1 / 4] = (uint32_t)data1;
    AD_DA_PTR[DAC_REG_DATA2 / 4] = (uint32_t)data2;
    AD_DA_PTR[DAC_REG_DATA3 / 4] = (uint32_t)data3;
    
    return 0;
}

int metal_dac_set_channel(uint8_t channel, uint16_t data)
{
    if (channel < 1 || channel > 3) {
        return -1;
    }
    
    switch (channel) {
        case 1:
            AD_DA_PTR[DAC_REG_DATA1 / 4] = (uint32_t)data;
            break;
        case 2:
            AD_DA_PTR[DAC_REG_DATA2 / 4] = (uint32_t)data;
            break;
        case 3:
            AD_DA_PTR[DAC_REG_DATA3 / 4] = (uint32_t)data;
            break;
        default:
            return -1;
    }
    
    return 0;
}

int metal_dac_start(void)
{
    uint32_t ctrl = AD_DA_PTR[DAC_REG_CONTROL / 4];
    
    ctrl |= DAC_CTRL_START;
    AD_DA_PTR[DAC_REG_CONTROL / 4] = ctrl;
    
    return 0;
}

int metal_dac_stop(void)
{
    uint32_t ctrl = AD_DA_PTR[DAC_REG_CONTROL / 4];
    
    ctrl &= ~DAC_CTRL_START;
    AD_DA_PTR[DAC_REG_CONTROL / 4] = ctrl;
    
    return 0;
}

bool metal_dac_is_enabled(void)
{
    uint32_t status = AD_DA_PTR[DAC_REG_STATUS / 4];
    
    return (status & DAC_STATUS_ENABLE) != 0;
}

int metal_dac_wait_complete(uint32_t timeout_ms)
{
    uint32_t count = 0;
    const uint32_t max_count = (timeout_ms > 0) ? (timeout_ms * 1000) : UINT32_MAX;
    
    while (count < max_count) {
        uint32_t status = AD_DA_PTR[DAC_REG_STATUS / 4];
        if (!(status & DAC_STATUS_ENABLE)) {
            return 0;  // DAC completed
        }
        count++;
        /* Small delay - adjust based on CPU frequency */
        for (volatile int i = 0; i < 100; i++);
    }
    
    return -1;  // Timeout
}

int metal_dac_out_data(uint8_t channel, uint16_t data)
{
	metal_dac_set_channel(channel, data);
	metal_dac_start();
    return 0;
}