// This file is part of: bait programming language
// Copyright (c) 2022 Lukas Neubert
// Use of this code is governed by an MIT License (see LICENSE.md).
module c

const c_includes = '#include <stdio.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
'

const c_builtin_types = 'typedef uint8_t byte;
typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;
'

const c_helpers = '#define SLIT(s) ((string){.str = (byte*)("" s), .len=(sizeof(s) - 1)})'
