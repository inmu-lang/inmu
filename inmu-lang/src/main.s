// inmu - Simple programming language interpreter
// ARM64 Assembly for macOS (Apple Silicon)

.global _main
.align 2

// Include print functionality
.include "src/include/print.s"

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

hello_msg:      .asciz "Hello from INMU!\n"
hello_len = . - hello_msg

print_keyword:  .asciz "print"

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
    
    // Close file
    mov     x0, x19
    mov     x16, #SYS_CLOSE
    svc     #0x80
    
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
    
    // Check for "print" command
    bl      parse_and_execute
    
    ldp     x29, x30, [sp], #16
    ret

// Simple parser and executor
parse_and_execute:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x23, #0             // Current search position
    
parse_loop:
    // Look for "print" keyword from current position
    add     x0, x19, x23        // buffer + offset
    sub     x1, x20, x23        // remaining length
    cmp     x1, #0
    b.le    parse_done
    
    adrp    x2, print_keyword@PAGE
    add     x2, x2, print_keyword@PAGEOFF
    mov     x3, #5
    bl      find_keyword
    
    cmp     x0, #0
    b.lt    parse_done          // No more print statements
    
    // Found print at relative position x0
    add     x24, x23, x0        // Absolute position in buffer
    bl      handle_print
    
    // Move past this print statement
    add     x23, x24, #1
    b       parse_loop
    
parse_done:
    ldp     x29, x30, [sp], #16
    ret

// Find keyword in buffer
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
