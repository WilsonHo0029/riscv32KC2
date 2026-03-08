OUTPUT_ARCH( "riscv" )

ENTRY( _start )

MEMORY
{
  /* Instruction RAM - Read-only code section */
  IRAM (rxai!w) : ORIGIN = 0x80000000, LENGTH = 16K
  
  /* Data RAM - Read-write data section */
  DRAM (wxa!ri) : ORIGIN = 0x90000000, LENGTH = 16K
}

SECTIONS
{
  __stack_size = DEFINED(__stack_size) ? __stack_size : 8K;

  .init           :
  {
    KEEP (*(SORT_NONE(.init)))
  } >IRAM AT>IRAM 

  .ilalign         :
  {
    . = ALIGN(4);
    PROVIDE( _itcm_lma = . );
  } >IRAM AT>IRAM 

  .ialign         :
  {
    PROVIDE( _itcm = . );
  } >IRAM AT>IRAM 

  .text           :
  {
    *(.text.unlikely .text.unlikely.*)
    *(.text.startup .text.startup.*)
    *(.text .text.*)
    *(.gnu.linkonce.t.*)
  } >IRAM AT>IRAM 

  .fini           :
  {
    KEEP (*(SORT_NONE(.fini)))
  } >IRAM AT>IRAM 

  . = ALIGN(4);

  PROVIDE (__etext = .);
  PROVIDE (_etext = .);
  PROVIDE (etext = .);
  PROVIDE( _eitcm = . );

  .preinit_array  :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  } >IRAM AT>IRAM 

  .init_array     :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
    KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
    PROVIDE_HIDDEN (__init_array_end = .);
  } >IRAM AT>IRAM 

  .fini_array     :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
    KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
    PROVIDE_HIDDEN (__fini_array_end = .);
  } >IRAM AT>IRAM 

  .ctors          :
  {
    KEEP (*crtbegin.o(.ctors))
    KEEP (*crtbegin?.o(.ctors))
    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
  } >IRAM AT>IRAM 

  .dtors          :
  {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*crtbegin?.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  } >IRAM AT>IRAM 

    . = ALIGN(4);
    PROVIDE( _eitcm = . );

  .lalign         :
  {
    . = ALIGN(4);
    PROVIDE( _data_lma = . );
  } >IRAM AT>IRAM 

  .dalign         :
  {
    . = ALIGN(4);
    PROVIDE( _data = . );
  } >DRAM AT>IRAM 

  .data          :
  {
    *(.rdata)
    *(.rodata .rodata.*)
    *(.gnu.linkonce.r.*)
    *(.data .data.*)
    *(.gnu.linkonce.d.*)
    . = ALIGN(8);
    PROVIDE( __global_pointer$ = . + 0x800 );
    *(.sdata .sdata.*)
    *(.gnu.linkonce.s.*)
    . = ALIGN(8);
    *(.srodata.cst16)
    *(.srodata.cst8)
    *(.srodata.cst4)
    *(.srodata.cst2)
    *(.srodata .srodata.*)
  } >DRAM AT>IRAM 

  . = ALIGN(4);
  PROVIDE( _edata = . );
  PROVIDE( edata = . );

  PROVIDE( _fbss = . );
  PROVIDE( __bss_start = . );
  .bss            :
  {
    *(.sbss*)
    *(.gnu.linkonce.sb.*)
    *(.bss .bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN(4);
  } >DRAM AT>DRAM 

  . = ALIGN(8);
  PROVIDE( _end = . );
  PROVIDE( end = . );

  .stack ORIGIN(DRAM) + LENGTH(DRAM) - __stack_size : 
  {
    PROVIDE( _heap_end = . );
    . = __stack_size;
    PROVIDE( _sp = . );
  } >DRAM AT>DRAM 

}

