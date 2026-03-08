#ifndef METAL_TIME_HEADER
#define METAL_TIME_HEADER

#include <stdint.h>
#include <stddef.h>
#include "../platform.h"

/*!
 * @file time.h
 * @brief API for dealing with time
 */

/* Include sys/types.h to get standard time_t and suseconds_t if available */
#include <sys/types.h>

/* Use standard library types - they are already defined by sys/types.h */
/* No need to redefine time_t and suseconds_t as they come from standard library */

/*! @brief Get time in second
 * @return time in second */
time_t metal_time(void);

/*! @brief Get time in us
 * @return time in us */
suseconds_t metal_time_us(void);

/*! @brief Get time in ms
 * @return time in ms */
suseconds_t metal_time_ms(void);

/*! @brief Wait time in us
 * @param wait_time Time to wait in microseconds */
void metal_time_wait_for_us(size_t wait_time);

/*! @brief Wait time in ms
 * @param wait_time Time to wait in milliseconds */
void metal_time_wait_for_ms(size_t wait_time);

/*! @brief Wait time in s
 * @param wait_time Time to wait in seconds */
void metal_time_wait_for_s(size_t wait_time);

#endif /* METAL_TIME_HEADER */

