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
    // Use the advanced expression parser with proper operator precedence
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      parse_expression_advanced
    mov     x22, x0             // Save result value
    add     x21, x21, x1        // Update consumed bytes
    
print_the_number:
    // Print the number
    mov     x0, x22
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
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #64
    ret

print_zero_value:
    // Print 0 when no valid input found
    mov     x22, #0
    b       print_the_number

// Skip whitespace
// x0 = buffer pointer, x1 = buffer length
// Returns: x0 = bytes skipped
skip_whitespace_print:
    mov     x2, #0
skip_ws_loop_print:
    cmp     x2, x1
    b.ge    skip_ws_done_print
    
    ldrb    w3, [x0, x2]
    cmp     w3, #' '
    b.eq    skip_ws_char_print
    cmp     w3, #'\t'
    b.eq    skip_ws_char_print
    
    // Not whitespace
    b       skip_ws_done_print
    
skip_ws_char_print:
    add     x2, x2, #1
    b       skip_ws_loop_print
    
skip_ws_done_print:
    mov     x0, x2
    ret

// Skip whitespace and newlines
// x0 = buffer pointer, x1 = buffer length
// Returns: x0 = bytes skipped
skip_whitespace_and_newline_print:
    mov     x2, #0
skip_wsnl_loop_print:
    cmp     x2, x1
    b.ge    skip_wsnl_done_print
    
    ldrb    w3, [x0, x2]
    cmp     w3, #' '
    b.eq    skip_wsnl_char_print
    cmp     w3, #'\t'
    b.eq    skip_wsnl_char_print
    cmp     w3, #'\n'
    b.eq    skip_wsnl_char_print
    cmp     w3, #'\r'
    b.eq    skip_wsnl_char_print
    
    // Not whitespace or newline
    b       skip_wsnl_done_print
    
skip_wsnl_char_print:
    add     x2, x2, #1
    b       skip_wsnl_loop_print
    
skip_wsnl_done_print:
    mov     x0, x2
    ret

// Parse a term (number or variable)
// x0 = buffer pointer, x1 = buffer length
// Returns: x0 = value, x1 = bytes consumed
parse_term_value:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    
    mov     x19, x0
    mov     x20, x1
    
    // Check if empty
    cmp     x20, #0
    b.le    term_val_zero
    
    // Check first character
    ldrb    w1, [x19]
    
    // Check if digit
    cmp     w1, #'0'
    b.lt    try_var_term
    cmp     w1, #'9'
    b.le    parse_num_term
    
try_var_term:
    // Check if letter or underscore
    cmp     w1, #'_'
    b.eq    parse_var_term
    cmp     w1, #'a'
    b.lt    check_upper_term
    cmp     w1, #'z'
    b.le    parse_var_term
check_upper_term:
    cmp     w1, #'A'
    b.lt    term_val_zero
    cmp     w1, #'Z'
    b.gt    term_val_zero
    
parse_var_term:
    // Extract variable name
    sub     sp, sp, #64
    mov     x2, sp
    mov     x3, #0
    
extract_vname:
    cmp     x3, #31
    b.ge    vname_done
    cmp     x3, x20
    b.ge    vname_done
    
    ldrb    w4, [x19, x3]
    
    // Check if valid variable character
    cmp     w4, #'_'
    b.eq    valid_vchar
    cmp     w4, #'a'
    b.lt    check_vupper
    cmp     w4, #'z'
    b.le    valid_vchar
check_vupper:
    cmp     w4, #'A'
    b.lt    check_vdigit
    cmp     w4, #'Z'
    b.le    valid_vchar
check_vdigit:
    cmp     w4, #'0'
    b.lt    vname_done
    cmp     w4, #'9'
    b.gt    vname_done
    
valid_vchar:
    strb    w4, [x2, x3]
    add     x3, x3, #1
    b       extract_vname
    
vname_done:
    strb    wzr, [x2, x3]
    
    // Get variable value
    mov     x0, x2
    bl      get_variable
    mov     x1, x3              // Bytes consumed
    
    add     sp, sp, #64
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
    
parse_num_term:
    mov     x0, x19
    mov     x1, x20
    bl      parse_number_simple
    
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
    
term_val_zero:
    mov     x0, #0
    mov     x1, #0
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
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
