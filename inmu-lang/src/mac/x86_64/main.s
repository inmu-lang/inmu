// inmu - Simple programming language interpreter
// x86_64 Assembly for macOS (Intel)

.global _main

// Include print functionality
.include "src/mac/x86_64/include/print.s"

// System call numbers for macOS x86_64
.equ SYS_EXIT,    0x2000001
.equ SYS_READ,    0x2000003
.equ SYS_WRITE,   0x2000004
.equ SYS_OPEN,    0x2000005
.equ SYS_CLOSE,   0x2000006

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
file_buffer:    .skip 4096
filename_ptr:   .skip 8

// Text section (code)
.text

_main:
    // Save frame pointer
    pushq   %rbp
    movq    %rsp, %rbp
    
    // Check if filename argument is provided
    // argc is in %rdi, argv is in %rsi
    cmpq    $2, %rdi
    jl      show_usage
    
    // Get filename from argv[1]
    movq    8(%rsi), %rax
    movq    %rax, filename_ptr(%rip)
    
    // Open file
    movq    $SYS_OPEN, %rax
    movq    filename_ptr(%rip), %rdi
    movq    $O_RDONLY, %rsi
    xorq    %rdx, %rdx
    syscall
    
    // Check if open succeeded (fd >= 0)
    cmpq    $0, %rax
    jl      error_open_file
    
    // Save file descriptor
    movq    %rax, %r12
    
    // Read file content
    movq    $SYS_READ, %rax
    movq    %r12, %rdi
    leaq    file_buffer(%rip), %rsi
    movq    $4096, %rdx
    syscall
    
    // Save bytes read
    movq    %rax, %r13
    
    // Close file
    movq    $SYS_CLOSE, %rax
    movq    %r12, %rdi
    syscall
    
    // Execute the inmu program
    leaq    file_buffer(%rip), %rdi
    movq    %r13, %rsi
    call    execute_inmu
    
    // Exit successfully
    xorq    %rax, %rax
    popq    %rbp
    ret

show_usage:
    // Write usage message to stderr
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    usage_msg(%rip), %rsi
    movq    $usage_len, %rdx
    syscall
    
    // Exit with error code
    movq    $1, %rax
    popq    %rbp
    ret

error_open_file:
    // Write error message to stderr
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    error_open(%rip), %rsi
    movq    $error_open_len, %rdx
    syscall
    
    // Exit with error code
    movq    $1, %rax
    popq    %rbp
    ret

// Execute INMU program
// %rdi = buffer pointer, %rsi = length
execute_inmu:
    pushq   %rbp
    movq    %rsp, %rbp
    
    movq    %rdi, %r12
    movq    %rsi, %r13
    
    // Check for "print" command
    call    parse_and_execute
    
    popq    %rbp
    ret

// Simple parser and executor
parse_and_execute:
    pushq   %rbp
    movq    %rsp, %rbp
    
    xorq    %r14, %r14          // Current search position
    
parse_loop:
    // Look for "print" keyword from current position
    leaq    (%r12,%r14), %rdi   // buffer + offset
    movq    %r13, %rax
    subq    %r14, %rax          // remaining length
    movq    %rax, %rsi
    cmpq    $0, %rsi
    jle     parse_done
    
    leaq    print_keyword(%rip), %rdx
    movq    $5, %rcx
    call    find_keyword
    
    cmpq    $0, %rax
    jl      parse_done          // No more print statements
    
    // Found print at relative position %rax
    addq    %r14, %rax          // Absolute position in buffer
    movq    %rax, %r15
    call    _handle_print
    
    // Move past this print statement
    leaq    1(%r15), %r14
    jmp     parse_loop
    
parse_done:
    popq    %rbp
    ret

// Find keyword in buffer
// %rdi = buffer, %rsi = buffer_len, %rdx = keyword, %rcx = keyword_len
// Returns: position in %rax or -1 if not found
find_keyword:
    pushq   %rbp
    movq    %rsp, %rbp
    
    xorq    %r8, %r8            // search position
    
find_loop:
    movq    %rsi, %rax
    subq    %r8, %rax
    cmpq    %rcx, %rax
    jl      not_found
    
    // Compare bytes
    xorq    %r9, %r9
compare_loop:
    cmpq    %rcx, %r9
    jge     found
    
    leaq    (%rdi,%r8), %r10
    movzbl  (%r10,%r9), %eax
    movzbl  (%rdx,%r9), %r11d
    cmpb    %r11b, %al
    jne     next_pos
    
    incq    %r9
    jmp     compare_loop
    
next_pos:
    incq    %r8
    jmp     find_loop
    
found:
    movq    %r8, %rax
    popq    %rbp
    ret
    
not_found:
    movq    $-1, %rax
    popq    %rbp
    ret
