// print.s - Print statement handling for INMU language
// ARM64 Assembly for macOS (Apple Silicon)

.global handle_print

// External symbols
.equ STDOUT, 1
.equ SYS_WRITE, 4

.data
newline_print: .asciz "\n"

.text

// Handle print statement
// x19 = buffer base, x20 = buffer length, x24 = position of "print"
// Uses: x0-x6, x22, x23
handle_print:
    // Found "print" at absolute position x24
    // Now find the opening quote
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Skip past "print" keyword (5 bytes)
    add     x0, x24, #5         // position after "print"
    
    // Find opening quote
    mov     x2, #0              // counter
find_quote_loop:
    add     x3, x0, x2          // current search position
    cmp     x3, x20             // check bounds
    b.ge    print_done
    
    add     x4, x19, x3         // buffer address
    ldrb    w5, [x4]            // load byte
    cmp     w5, #34             // ASCII '"'
    b.eq    found_quote
    
    add     x2, x2, #1
    b       find_quote_loop

found_quote:
    // x3 = position of opening quote
    add     x22, x3, #1         // start of string (after quote)
    
    // Find closing quote
    mov     x2, #0              // counter
find_close_quote:
    add     x4, x22, x2         // current position
    cmp     x4, x20             // check bounds
    b.ge    print_done
    
    add     x5, x19, x4         // buffer address
    ldrb    w6, [x5]            // load byte
    cmp     w6, #34             // ASCII '"'
    b.eq    found_close_quote
    
    add     x2, x2, #1
    b       find_close_quote

found_close_quote:
    // x22 = start of string, x2 = length
    mov     x0, #STDOUT
    add     x1, x19, x22        // string address
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Print newline
    mov     x0, #STDOUT
    adrp    x1, newline_print@PAGE
    add     x1, x1, newline_print@PAGEOFF
    mov     x2, #1
    mov     x16, #SYS_WRITE
    svc     #0x80

print_done:
    ldp     x29, x30, [sp], #16
    ret
