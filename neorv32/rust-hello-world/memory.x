MEMORY
{
  /* NEORV32 memory layout */
  IMEM  : ORIGIN = 0x00000000, LENGTH = 64K    /* Internal IMEM for code */
  DMEM  : ORIGIN = 0x80000000, LENGTH = 64K    /* Internal DMEM for data and stack */
}

REGION_ALIAS("REGION_TEXT", IMEM);
REGION_ALIAS("REGION_RODATA", IMEM);
REGION_ALIAS("REGION_DATA", DMEM);
REGION_ALIAS("REGION_BSS", DMEM);
REGION_ALIAS("REGION_HEAP", DMEM);
REGION_ALIAS("REGION_STACK", DMEM);

/* Define the entry point symbol */
ENTRY(_start)

/* Initial stack pointer value */
_stack_start = ORIGIN(DMEM) + LENGTH(DMEM);
