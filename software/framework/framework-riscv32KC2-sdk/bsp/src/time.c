/* Time functions for AI RISC-V KC32 System */

#include "../include/metal/time.h"
#include "../include/metal/clint.h"

/**
 * @brief Get time in seconds
 * @return Time in seconds since system start (based on RTC ticks)
 */
time_t metal_time(void)
{
    uint64_t mtime;
    
    // Read MTIME register (increments at RTC_FREQ)
    mtime = metal_clint_read_mtime();
    
    // Convert RTC ticks to seconds
    return mtime / RTC_FREQ;
}

/**
 * @brief Get time in microseconds
 * @return Time in microseconds since system start (based on RTC ticks)
 */
suseconds_t metal_time_us(void)
{
    uint64_t mtime;
    uint64_t time_us;
    
    // Read MTIME register (increments at RTC_FREQ)
    mtime = metal_clint_read_mtime();
    
    // Convert RTC ticks to microseconds
    // time_us = (mtime * 1000000) / RTC_FREQ
    time_us = (mtime * 1000000ULL) / RTC_FREQ;
    
    return time_us;
}

/**
 * @brief Get time in milliseconds
 * @return Time in milliseconds since system start (based on RTC ticks)
 */
suseconds_t metal_time_ms(void)
{
    uint64_t mtime;
    uint64_t time_ms;
    
    // Read MTIME register (increments at RTC_FREQ)
    mtime = metal_clint_read_mtime();
    
    // Convert RTC ticks to milliseconds
    // time_ms = (mtime * 1000) / RTC_FREQ
    time_ms = (mtime * 1000ULL) / RTC_FREQ;
    
    return time_ms;
}

/**
 * @brief Wait for specified time in microseconds
 * @param wait_time Time to wait in microseconds
 */
void metal_time_wait_for_us(size_t wait_time)
{
    size_t timeout;
    
    timeout = metal_time_us() + wait_time;
    
    // Wait until timeout is reached
    // Handle wraparound by checking if difference is reasonable
    while (timeout > (int32_t)metal_time_us()) {
        if ((timeout - metal_time_us()) > wait_time) {
            // Wraparound detected, break
            break;
        }
    }
}

/**
 * @brief Wait for specified time in milliseconds
 * @param wait_time Time to wait in milliseconds
 */
void metal_time_wait_for_ms(size_t wait_time)
{
    size_t timeout;
    
    timeout = metal_time_ms() + wait_time;
    
    // Wait until timeout is reached
    // Handle wraparound by checking if difference is reasonable
    while (timeout > (int32_t)metal_time_ms()) {
        if ((timeout - metal_time_ms()) > wait_time) {
            // Wraparound detected, break
            break;
        }
    }
}

/**
 * @brief Wait for specified time in seconds
 * @param wait_time Time to wait in seconds
 */
void metal_time_wait_for_s(size_t wait_time)
{
    time_t timeout;
    
    timeout = metal_time() + wait_time;
    
    // Wait until timeout is reached
    while (timeout > metal_time()) {
        if ((timeout - metal_time()) > wait_time) {
            // Wraparound detected, break
            break;
        }
    }
}


