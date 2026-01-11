// inmu - Simple programming language interpreter
// ARM64 Assembly for macOS (Apple Silicon)

.global _main
.global print_keyword
.global let_keyword
.global if_keyword
.align 2

// Include functionality
.include "src/mac/arm64/include/print.s"
.include "src/mac/arm64/include/variables.s"
.include "src/mac/arm64/include/expression.s"
.include "src/mac/arm64/include/control.s"

// System call numbers for macOS ARM64
.equ SYS_EXIT,    1
.equ SYS_READ,    3
.equ SYS_WRITE,   4
.equ SYS_OPEN,    5
.equ SYS_CLOSE,   6

.equ STDIN,       0
.equ STDOUT,      1
.equ STDERR,      2

.equ O_RDONLY,    0

// Data section
.data
usage_msg:      .asciz "Usage: inmu <filename.inmu>\n"
usage_len = . - usage_msg

error_open:     .asciz "Error: Cannot open file\n"
error_open_len = . - error_open

hello_msg:       .asciz "Hello from INMU!\\n"
hello_len = . - hello_msg


print_keyword:   .asciz "print"
let_keyword:     .asciz "let"
if_keyword:      .asciz "if"

.bss
.align 3
file_buffer:    .skip 4096
filename_ptr:   .skip 8

// Text section (code)
.text

_main:
    // Save frame pointer
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Check if filename argument is provided
    // argc is in x0, argv is in x1
    cmp     x0, #2
    b.lt    show_usage
    
    // Get filename from argv[1]
    ldr     x0, [x1, #8]
    adrp    x1, filename_ptr@PAGE
    add     x1, x1, filename_ptr@PAGEOFF
    str     x0, [x1]
    
    // Open file
    mov     x16, #SYS_OPEN
    mov     x1, #O_RDONLY
    mov     x2, #0
    svc     #0x80
    
    // Check if open succeeded (fd >= 0)
    cmp     x0, #0
    b.lt    error_open_file
    
    // Save file descriptor
    mov     x19, x0
    
    // Read file content
    mov     x0, x19
    adrp    x1, file_buffer@PAGE
    add     x1, x1, file_buffer@PAGEOFF
    mov     x2, #4096
    mov     x16, #SYS_READ
    svc     #0x80
    
    // Save bytes read
    mov     x20, x0
    
    // Debug: print bytes read
    // (Commented out for now)
    
    // Close file
    mov     x0, x19
    mov     x16, #SYS_CLOSE
    svc     #0x80
    
    // Initialize variable system
    bl      init_variables
    
    // Execute the inmu program
    adrp    x0, file_buffer@PAGE
    add     x0, x0, file_buffer@PAGEOFF
    mov     x1, x20
    bl      execute_inmu
    
    // Exit successfully
    mov     x0, #0
    ldp     x29, x30, [sp], #16
    ret

show_usage:
    // Write usage message to stderr
    mov     x0, #STDERR
    adrp    x1, usage_msg@PAGE
    add     x1, x1, usage_msg@PAGEOFF
    mov     x2, #usage_len
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Exit with error code
    mov     x0, #1
    ldp     x29, x30, [sp], #16
    ret

error_open_file:
    // Write error message to stderr
    mov     x0, #STDERR
    adrp    x1, error_open@PAGE
    add     x1, x1, error_open@PAGEOFF
    mov     x2, #error_open_len
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Exit with error code
    mov     x0, #1
    ldp     x29, x30, [sp], #16
    ret

// Execute INMU program
// x0 = buffer pointer, x1 = length
execute_inmu:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x19, x0
    mov     x20, x1
    
    // Initialize variable system
    bl      init_variables
    
    // Parse and execute the program
    bl      parse_and_execute
    
    ldp     x29, x30, [sp], #16
    ret

// Simple parser and executor
parse_and_execute:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x23, #0             // Current search position
    
parse_loop:
    // Skip whitespace and comments
skip_ws_and_comments:
    cmp     x23, x20
    b.ge    parse_done
    
    add     x0, x19, x23
    ldrb    w1, [x0]
    
    // Check for whitespace
    cmp     w1, #' '
    b.eq    skip_char
    cmp     w1, #'\t'
    b.eq    skip_char
    cmp     w1, #'\n'
    b.eq    skip_char
    cmp     w1, #'\r'
    b.eq    skip_char
    
    // Check for comment (#)
    cmp     w1, #'#'
    b.eq    skip_comment
    
    // Non-whitespace, non-comment character found
    b       check_keywords
    
skip_char:
    add     x23, x23, #1
    b       skip_ws_and_comments
    
skip_comment:
    // Skip until newline
    add     x23, x23, #1
    cmp     x23, x20
    b.ge    parse_done
    add     x0, x19, x23
    ldrb    w1, [x0]
    cmp     w1, #'\n'
    b.ne    skip_comment
    add     x23, x23, #1        // Skip the newline too
    b       skip_ws_and_comments

check_keywords:
    // TEMP: Skip if check for debugging
    // // Check if current position starts with "if" keyword
    // add     x0, x19, x23
    // sub     x1, x20, x23
    // adrp    x2, if_keyword@PAGE
    // add     x2, x2, if_keyword@PAGEOFF
    // mov     x3, #2
    // bl      check_keyword_at_position
    // 
    // cmp     x0, #1
    // b.eq    found_if
    
    // Check if current position starts with "let" keyword
    add     x0, x19, x23
    sub     x1, x20, x23
    adrp    x2, let_keyword@PAGE
    add     x2, x2, let_keyword@PAGEOFF
    mov     x3, #3
    bl      check_keyword_at_position
    
    cmp     x0, #1
    b.eq    found_let
    
    // Check for "print" keyword
    add     x0, x19, x23
    sub     x1, x20, x23
    adrp    x2, print_keyword@PAGE
    add     x2, x2, print_keyword@PAGEOFF
    mov     x3, #5
    bl      check_keyword_at_position
    
    cmp     x0, #1
    b.eq    found_print
    
    // Unknown token - skip one char and continue
    add     x23, x23, #1
    b       parse_loop

found_if:
    // Parse the if statement
    add     x0, x19, x23
    sub     x1, x20, x23
    bl      parse_if_statement
    
    // x0 contains bytes consumed
    add     x23, x23, x0
    b       parse_loop

found_print:
    // Call handle_print
    add     x0, x19, x23
    sub     x1, x20, x23
    bl      handle_print
    
    // x0 contains bytes consumed
    add     x23, x23, x0
    b       parse_loop

found_let:
    // Parse the let statement
    add     x0, x19, x23
    sub     x1, x20, x23
    bl      parse_let_statement
    
    // x0 contains bytes consumed
    add     x23, x23, x0
    b       parse_loop
    
parse_done:
    ldp     x29, x30, [sp], #16
    ret

// Check if keyword matches at current position
// x0 = buffer, x1 = buffer_len, x2 = keyword, x3 = keyword_len
// Returns: 1 if match, 0 if no match
check_keyword_at_position:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Check if we have enough bytes
    cmp     x1, x3
    b.lt    no_match
    
    // Compare bytes
    mov     x4, #0
compare_kw_loop:
    cmp     x4, x3
    b.ge    match_found
    
    ldrb    w5, [x0, x4]
    ldrb    w6, [x2, x4]
    cmp     w5, w6
    b.ne    no_match
    
    add     x4, x4, #1
    b       compare_kw_loop
    
match_found:
    mov     x0, #1
    ldp     x29, x30, [sp], #16
    ret
    
no_match:
    mov     x0, #0
    ldp     x29, x30, [sp], #16
    ret

// Find keyword in buffer (old version - kept for compatibility)
// x0 = buffer, x1 = buffer_len, x2 = keyword, x3 = keyword_len
// Returns: position or -1 if not found
find_keyword:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x4, #0
    
find_loop:
    sub     x5, x1, x4
    cmp     x5, x3
    b.lt    not_found
    
    // Compare bytes
    mov     x6, #0
compare_loop:
    cmp     x6, x3
    b.ge    found
    
    add     x7, x0, x4
    ldrb    w8, [x7, x6]
    ldrb    w9, [x2, x6]
    cmp     w8, w9
    b.ne    next_pos
    
    add     x6, x6, #1
    b       compare_loop
    
next_pos:
    add     x4, x4, #1
    b       find_loop
    
found:
    mov     x0, x4
    ldp     x29, x30, [sp], #16
    ret
    
not_found:
    mov     x0, #-1
    ldp     x29, x30, [sp], #16
    ret
