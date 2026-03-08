/* See LICENSE of license details. */

#include <stdint.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <metal/uart.h>
#include "platform.h"
#include "stub.h"

ssize_t _write(int fd, void* ptr, size_t len)
{
  if (isatty(fd)) {
    return metal_uart0_print(ptr, len);
  }

  return _stub(EBADF);
}
