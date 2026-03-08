#ifndef METAL_AD_DA_IF_HEADER
#define METAL_AD_DA_IF_HEADER

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* ADC/DAC Interface Base Address */
#define AD_DA_IF_BASE_ADDR           0x10001000

/* ADC Register Offsets (relative to base) */
#define ADC_REG_CONTROL              0x0100  // ADC Control Register
#define ADC_REG_OFFSET               0x0104  // ADC Offset Register
#define ADC_REG_STATUS               0x0108  // ADC Status/Data Register (Read-only)

/* DAC Register Offsets (relative to base) */
#define DAC_REG_CONTROL              0x0200  // DAC Control Register
#define DAC_REG_DATA1                0x0204  // DAC Data 1
#define DAC_REG_DATA2                0x0208  // DAC Data 2
#define DAC_REG_DATA3                0x020C  // DAC Data 3
#define DAC_REG_STATUS               0x0210  // DAC Status Register (Read-only)

/* ADC Control Register Bit Fields */
#define ADC_CTRL_EN                  (1 << 0)        // ADC Enable
#define ADC_CTRL_SAMP_RATE_MASK      (0x3 << 1)      // Sample Rate Mask (bits 2:1)
#define ADC_CTRL_SAMP_RATE_SHIFT     1
#define ADC_CTRL_WAIT_TIME_MASK      (0x3F << 3)     // Wait Time Mask (bits 8:3)
#define ADC_CTRL_WAIT_TIME_SHIFT     3

/* ADC Sample Rate Values */
#define ADC_SAMP_RATE_0              0x0
#define ADC_SAMP_RATE_1              0x1
#define ADC_SAMP_RATE_2              0x2
#define ADC_SAMP_RATE_3              0x3

/* ADC Status Register Bit Fields */
#define ADC_STATUS_DATA_MASK         (0xFFF)         // ADC Data (bits 11:0)
#define ADC_STATUS_RDY_REQ           (1 << 12)       // ADC Ready Request
#define ADC_STATUS_OFF_REQ           (1 << 13)       // ADC Offset Request

/* DAC Control Register Bit Fields */
#define DAC_CTRL_START               (1 << 0)        // DAC Start
#define DAC_CTRL_CLK_CNT_MASK        (0xFF << 1)     // Clock Count Mask (bits 8:1)
#define DAC_CTRL_CLK_CNT_SHIFT       1

/* DAC Status Register Bit Fields */
#define DAC_STATUS_ENABLE            (1 << 0)        // DAC Enable Status

/* ADC Configuration Structure */
typedef struct {
    uint8_t samp_rate;       // Sample rate (0-3)
    uint8_t wait_time;       // Wait time (0-63)
    uint16_t offset;         // Offset value (13-bit, 0-8191)
} adc_config_t;

/* DAC Configuration Structure */
typedef struct {
    uint8_t clk_cnt;         // Clock count (0-255)
} dac_config_t;

/* Function Prototypes */

/*! @brief Initialize ADC/DAC interface
 * @return 0 if no error, -1 on error */
int metal_ad_da_if_init(void);

/*! @brief Configure ADC
 * @param config Pointer to ADC configuration structure
 * @return 0 on success, -1 on error */
int metal_adc_configure(const adc_config_t *config);

/*! @brief Enable ADC
 * @param enable true to enable, false to disable
 * @return 0 on success, -1 on error */
int metal_adc_enable(bool enable);

/*! @brief Set ADC offset
 * @param offset Offset value (0-8191, 13-bit)
 * @return 0 on success, -1 on error */
int metal_adc_set_offset(uint16_t offset);

/*! @brief Read ADC data
 * @param data Pointer to store the ADC data (12-bit)
 * @return 0 on success, -1 on error */
int metal_adc_read(uint16_t *data);

/*! @brief Check if ADC data is ready
 * @return true if ready, false otherwise */
bool metal_adc_is_ready(void);

/*! @brief Wait for ADC data ready
 * @param timeout_ms Timeout in milliseconds (0 for infinite wait)
 * @return 0 on success, -1 on timeout */
int metal_adc_wait_ready(uint32_t timeout_ms);

/*! @brief Clear ADC ready signal and trigger re-sample
 * @return 0 on success, -1 on error */
int metal_adc_re_sample(void);

/*! @brief Configure DAC
 * @param clk_cnt Clock count value (0-255)
 * @return 0 on success, -1 on error */
int metal_dac_configure(uint8_t clk_cnt);

/*! @brief Set DAC data for all channels
 * @param data1 Data for DAC channel 1 (16-bit)
 * @param data2 Data for DAC channel 2 (16-bit)
 * @param data3 Data for DAC channel 3 (16-bit)
 * @return 0 on success, -1 on error */
int metal_dac_set_data(uint16_t data1, uint16_t data2, uint16_t data3);

/*! @brief Set DAC data for a specific channel
 * @param channel Channel number (1, 2, or 3)
 * @param data Data value (16-bit)
 * @return 0 on success, -1 on error */
int metal_dac_set_channel(uint8_t channel, uint16_t data);

/*! @brief Output DAC data to a specific channel
 * @param channel Channel number (1, 2, or 3)
 * @param data Data value (16-bit)
 * @return 0 on success, -1 on error */
int metal_dac_out_data(uint8_t channel, uint16_t data);

/*! @brief Start DAC conversion
 * @return 0 on success, -1 on error */
int metal_dac_start(void);

/*! @brief Stop DAC conversion
 * @return 0 on success, -1 on error */
int metal_dac_stop(void);

/*! @brief Check if DAC is enabled/busy
 * @return true if enabled, false otherwise */
bool metal_dac_is_enabled(void);

/*! @brief Wait for DAC to complete
 * @param timeout_ms Timeout in milliseconds (0 for infinite wait)
 * @return 0 on success, -1 on timeout */
int metal_dac_wait_complete(uint32_t timeout_ms);

#endif /* METAL_AD_DA_IF_HEADER */



