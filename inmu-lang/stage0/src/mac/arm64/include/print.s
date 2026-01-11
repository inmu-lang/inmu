// print.s - Print statement handling for INMU language
// ARM64 Assembly for macOS (Apple Silicon)

.global handle_print
.global print_number

// External symbols
.equ STDOUT, 1
.equ SYS_WRITE, 4

.data
newline_print: .byte 10


.bss
.align 3
number_buffer: .skip 32

.text

// Handle print statement
// x0 = buffer pointer (at "print"), x1 = remaining length
// Returns: bytes consumed in x0
handle_print:
    stp     x29, x30, [sp, #-64]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]
    
    mov     x19, x0             // Save buffer pointer
    mov     x20, x1             // Save remaining length
    
    // Skip past "print" keyword (5 bytes)
    mov     x21, #5
    
    
    // Skip whitespace
skip_print_ws:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    check_print_type
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_print_char
    cmp     w1, #'\t'
    b.eq    skip_print_char
    b       check_print_type
skip_print_char:
    add     x21, x21, #1
    b       skip_print_ws
    
check_print_type:
    add     x0, x19, x21
    ldrb    w1, [x0]
    
    // Check if it's a string (starts with ")
    cmp     w1, #34             // ASCII '"'
    b.eq    print_string
    
    // Otherwise, try to parse as variable or number
    b       print_variable_or_number

print_string:
    // Find opening quote
    add     x22, x21, #1        // start of string (after quote)
    
    // Find closing quote
    mov     x2, #0              // counter
find_close_quote:
    add     x4, x22, x2         // current position from start
    
    add     x0, x19, x4         // buffer address
    ldrb    w1, [x0]            // load byte
    cmp     w1, #34             // ASCII '"'
    b.eq    found_close_quote
    
    add     x2, x2, #1
    b       find_close_quote

found_close_quote:
    // x22 = start of string (relative), x2 = length
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
    
    // Calculate bytes consumed: up to closing quote + 1
    add     x21, x22, x2
    add     x21, x21, #1        // Include closing quote
    
    // Return bytes consumed
    mov     x0, x21
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #64
    ret

print_variable_or_number:
    // Extract variable name or number
    sub     sp, sp, #64
    mov     x22, sp
    mov     x23, #0
    
    // Check if first character is a digit
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    token_done
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #'0'
    b.lt    extract_variable
    cmp     w1, #'9'
    b.gt    extract_variable
    
    // It's a number - extract digits only
extract_number:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    token_done
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    
    // Check if it's a digit
    cmp     w1, #'0'
    b.lt    token_done
    cmp     w1, #'9'
    b.gt    token_done
    
    strb    w1, [x22, x23]
    add     x23, x23, #1
    add     x21, x21, #1
    cmp     x23, #63
    b.lt    extract_number
    b       token_done

extract_variable:
    // Extract variable name (alphanumeric and underscore)
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    token_done
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    
    // Check if end of token (space, newline, etc.)
    cmp     w1, #' '
    b.eq    token_done
    cmp     w1, #'\t'
    b.eq    token_done
    cmp     w1, #'\n'
    b.eq    token_done
    cmp     w1, #'\r'
    b.eq    token_done
    cmp     w1, #0
    b.eq    token_done
    
    strb    w1, [x22, x23]
    add     x23, x23, #1
    add     x21, x21, #1
    cmp     x23, #63
    b.lt    extract_variable

token_done:
    strb    wzr, [x22, x23]     // Null terminate
    
    // Check if token is a number (first char is a digit)
    ldrb    w0, [x22]
    cmp     w0, #'0'
    b.lt    try_variable
    cmp     w0, #'9'
    b.gt    try_variable
    
    // It's a number - parse it
    mov     x0, x22
    bl      parse_number_simple
    b       print_the_number
    
try_variable:
    // Try to get as variable
    mov     x0, x22
    bl      get_variable
    
print_the_number:
    // Print the number
    bl      print_number
    
    // Print newline
    mov     x0, #STDOUT
    adrp    x1, newline_print@PAGE
    add     x1, x1, newline_print@PAGEOFF
    mov     x2, #1
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Return bytes consumed
    mov     x0, x21
    
    // Clean up: buffer (64) + frame (64) = 128 total
    add     sp, sp, #64           // Remove buffer
    ldp     x23, x24, [sp, #48]  
    ldp     x21, x22, [sp, #32]  
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #64
    ret

// Print number in x0
print_number:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    
    mov     x19, x0             // Save number
    
    // Convert number to string
    adrp    x20, number_buffer@PAGE
    add     x20, x20, number_buffer@PAGEOFF
    
    // Handle zero special case
    cmp     x19, #0
    b.ne    convert_loop_setup
    mov     w0, #'0'
    strb    w0, [x20]
    mov     x1, #1
    b       print_converted

convert_loop_setup:
    mov     x1, #0              // Digit counter
    mov     x2, x20             // Buffer pointer
    add     x2, x2, #31         // Start from end
    strb    wzr, [x2]           // Null terminate
    
convert_loop:
    cmp     x19, #0
    b.eq    reverse_string
    
    // Get last digit
    mov     x3, #10
    udiv    x4, x19, x3         // quotient
    msub    x5, x4, x3, x19     // remainder = n - (q * 10)
    
    // Convert to ASCII
    add     w5, w5, #'0'
    sub     x2, x2, #1
    strb    w5, [x2]
    add     x1, x1, #1
    
    mov     x19, x4             // n = quotient
    b       convert_loop

reverse_string:
    mov     x20, x2             // Start of number string
    
print_converted:
    mov     x0, #STDOUT
    mov     x2, x1              // Length
    mov     x1, x20             // String
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret
