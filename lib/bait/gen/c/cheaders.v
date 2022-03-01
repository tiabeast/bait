module c

const c_includes = '#include <stdio.h>
#include <inttypes.h>
'

const c_builtin_types = 'typedef uint8_t byte;
typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;
'

const c_helpers = '#define SLIT(s) ((string){.str = (byte*)("" s), .len=(sizeof(s) - 1)})'