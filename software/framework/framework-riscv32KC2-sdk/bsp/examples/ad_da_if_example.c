/* Example usage of ADC/DAC interface library */

#include "../include/metal/ad_da_if.h"

void ad_da_example(void)
{
    /* Get ADC/DAC interface */
    struct metal_ad_da_if *ad_da = metal_get_ad_da_if(0);
    if (!ad_da) {
        return;
    }

    /* Initialize */
    metal_ad_da_if_init(ad_da);

    /* Configure ADC */
    adc_config_t adc_cfg = {
        .samp_rate = ADC_SAMP_RATE_1,
        .wait_time = 10,
        .offset = 0
    };
    metal_adc_configure(ad_da, &adc_cfg);
    metal_adc_enable(ad_da, true);

    /* Wait for ADC data and read */
    if (metal_adc_wait_ready(ad_da, 100) == 0) {
        uint16_t adc_value;
        metal_adc_read(ad_da, &adc_value);
        /* Process adc_value */
    }

    /* Configure DAC */
    metal_dac_configure(50);  // clk_cnt = 50

    /* Set DAC data for all channels */
    metal_dac_set_data(ad_da, 0x1000, 0x2000, 0x3000);

    /* Start DAC conversion */
    metal_dac_start(ad_da);

    /* Wait for completion */
    metal_dac_wait_complete(ad_da, 1000);
}




