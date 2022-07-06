# Bait Documentation
> Not all features described in this document may be implemented yet.

## Hello World
```
package main

fun main(){
  println('hello world')
}
```

## Comments
```
// This is a single line comment.
/*
  And this a multi line or block comment.
  /* They can be nested. */
*/
```

However they shall not be used inline!
```
if x == 0 /* or x == 1 */ {
}
```

## Functions
```
  fun add(x i32, y i32) i32 {
    return x + y
  }
```
<!-- TODO multiple returns -->
<!-- TODO link to methods section -->

## Variables
Variables are declared using `:=` and must have an initial value.
The type is inferred from the value.
```
item_name := 'Screw'
amount := 7
```
<!-- TODO mutability -->
<!-- TODO init vs assign -->
<!-- TODO shadowing -->

## Basic Types
```
bool

i8   i16   i32   i64
u8   u16   u32   u64

f32 f64

string
```

### Numbers
```
n := 123
```
The default inferred type is `i32`.

Additionally binary, octal and hex notations are supported via prefixes:
```
b := 0b11010110
o := 0o173
h := 0xFF
```

Floating point numbers use the double-precision 64-bit variant by default.
```
f := 3.14
```
<!-- TODO scientific notation (power of 10) -->

To increase readability, all numbers can include `_` as separator:
```
1_000_000
0b0110_1101
4_576.33
```

### Strings
String literals are enclosed in single quotes.
Double quotes are still allowed to prevent escaping single quotes.<br>
Special characters are escaped with a backslash.
```
'This is a normal string.'
"That's without escaped single quotes."
'C:\\Windows\\notepad.exe'
```
<!-- TODO string interpolation -->

### Characters
Character literals are enclosed in backticks:
```
`\n`
`c`
```

### Arrays
Arrays are zero-indexed collections of data elements of the same type.
Elements are separated with commas and the whole array is surrounded by square brackets:
```
[1, 2, 3]

[
  'multiline has',
  'trailing comma',
]
```

### Maps
```
m := {
  'key': 'value
}

m2 := map[string]i32
m2['one'] = 1
m2['two'] = 2
```

## Constants
```
const MAGIC_NUMBER := 42
```

## Operators
### Arithmetic
```
+ // addition
- // subtraction
* // multiplication
/ // division
% // remainder
```
The `+` operator can also be used for string concatenation.

#### Assignment
Arithmetic operators can be combined with an equal sign to apply and assign the operation
to the current value.
For example `n += 7` <=> `n = n + 7`

### Comparison
```
<  // less than
>  // greater than
<= // less or equal to
>= // greater or equal to
== // equal to
!= // not equal
```

### Logical
```
and
or
not
```

## If Statements
```
if a < 10 {
  println('below 10')
} else if a > 10 {
  println('above 10')
} else {
  println('equal to ten')
}
```

It's also allowed to use `if` as an expression:
```
abs_num := if num > 0 { num } else { -num }
```

## Match **Statements**
```
num := 2
match num {
  1 {println('one')}
  2 {println('two')}
  else {println('other')}
}
```

## For loops
The only loop keyword is `for`. However several forms exist.

### Conditioned `for`
This form acts as a while loop known from other languages.
```
mut i := 0
for i < 100 {
  i += 1
}

// infinite loop
for true {
}
```

### Classic `for`
```
for i := 0; i < 10; i += 1 {
}
```

<!-- TODO range for loop -->

### break and continue
`break` and `continue` apply to the innermost loop.
```
for i := 0; i < 10; i += 1 {
  // don't print 3
  if i == 3 {
    continue
  }
  println(i)
}

for true {
  if input == 'yes' {
    break
  }
}
```

<!-- TODO labeled break and continue -->

## Structs
```
struct Point{
  x i32
  y i32
}

p := Point{
  x: 15
  y: 20
}
```

## Enums
```
enum Language {
  english
  german
  french
}
```

## Package Imports
For details on creating a package, see [Packages](#packages).

```
import os

fun main(){
  os.write_file('file.txt', 'hello world')
}
```

## Packages
All files in the root of a directory are part of one single package.
The default package name is `main`.

When creating reusable packages, the directory and package name should match.

## Symbol visibility
By default all symbols are private.
Should they be accessible by other packages, prepend the keyword `pub`.
```
pub fun exported_function(){
}

fun private_function(){
}
```

## Advanced Types
### Type Aliases
```
type Byte = u8
```

### Function Types
```
type CallbackFun = fun (int, int) bool
```

<!-- TODO generics -->
<!-- TODO concurrency -->
