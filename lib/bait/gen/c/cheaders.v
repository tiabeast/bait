module c

const c_includes = '#include <stdio.h>
#include <inttypes.h>
'

const c_builtin_types = 'typedef uint8_t byte;
'

const c_helpers = '#define SLIT(s) ((string){.str = (byte*)("" s), .len=(sizeof(s) - 1)})'
