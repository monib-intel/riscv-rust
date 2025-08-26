MEMORY
{
  /* PicoRV32 memory layout */
  RAM : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
  /* .text section containing code */
  .text :
  {
    *(.text.entry)   /* Entry point */
    *(.text*)        /* All other code sections */
    . = ALIGN(4);
  } > RAM

  /* .rodata section containing constants */
  .rodata :
  {
    *(.rodata*)      /* Read-only data */
    . = ALIGN(4);
  } > RAM

  /* .data section containing initialized variables */
  .data :
  {
    *(.data*)        /* Initialized data */
    . = ALIGN(4);
  } > RAM

  /* .bss section containing uninitialized variables */
  .bss (NOLOAD) :
  {
    _bss_start = .;
    *(.bss*)         /* Uninitialized data */
    *(COMMON)        /* Common block */
    . = ALIGN(4);
    _bss_end = .;
  } > RAM

  /* Stack grows downward from the end of RAM */
  /* The stack starts at the end of the RAM */
  _stack_start = ORIGIN(RAM) + LENGTH(RAM);
}
