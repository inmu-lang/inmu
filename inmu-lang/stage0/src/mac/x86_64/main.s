// inmu - Simple programming language interpreter
// x86_64 Assembly for macOS (Intel)

.global _main

// Include functionality
.include "src/mac/x86_64/include/print.s"
.include "src/mac/x86_64/include/variables.s"
.include "src/mac/x86_64/include/control.s"
.include "src/mac/x86_64/include/expression.s"

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

print_keyword:  .asciz "print"
let_keyword_main: .asciz "let"
if_keyword_main:  .asciz "if"

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
    
    xorq    %r14, %r14          // Current position
    
parse_loop:
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_main
    movq    %rax, %r14
    
    // Check if we're done
    cmpq    %r13, %r14
    jge     parse_done
    
    // Save current position
    movq    %r14, %r15
    
    // TODO: IF statement implementation has issues - disabled for now
    // // Check for "if"
    // leaq    (%r12,%r14), %rdi
    // leaq    if_keyword_main(%rip), %rsi
    // movq    $2, %rdx
    // call    check_keyword_main
    // 
    // cmpq    $1, %rax
    // jne     check_let
    // 
    // call    parse_if_statement
    // addq    %rax, %r14
    // jmp     parse_loop
    
check_let:
    // Check for "let"
    leaq    (%r12,%r14), %rdi
    leaq    let_keyword_main(%rip), %rsi
    movq    $3, %rdx
    call    check_keyword_main
    
    cmpq    $1, %rax
    jne     check_print
    
    call    parse_let_statement
    addq    %rax, %r14
    jmp     parse_loop
    
check_print:
    // Check for "print"
    leaq    (%r12,%r14), %rdi
    leaq    print_keyword(%rip), %rsi
    movq    $5, %rdx
    call    check_keyword_main
    
    cmpq    $1, %rax
    jne     skip_unknown
    
    call    _handle_print
    addq    %rax, %r14
    jmp     parse_loop
    
skip_unknown:
    // Skip this character
    incq    %r14
    jmp     parse_loop
    
parse_done:
    popq    %rbp
    ret

// Check if keyword matches at position
// %rdi = buffer position, %rsi = keyword, %rdx = keyword length
// Returns: %rax = 1 if match, 0 if not
check_keyword_main:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    
    xorq    %rbx, %rbx
    
check_kw_main_loop:
    cmpq    %rdx, %rbx
    jge     check_kw_main_match
    
    movzbl  (%rdi,%rbx), %eax
    movzbl  (%rsi,%rbx), %ecx
    
    cmpb    %cl, %al
    jne     check_kw_main_no_match
    
    incq    %rbx
    jmp     check_kw_main_loop
    
check_kw_main_match:
    movq    $1, %rax
    popq    %rbx
    popq    %rbp
    ret
    
check_kw_main_no_match:
    xorq    %rax, %rax
    popq    %rbx
    popq    %rbp
    ret

// Skip whitespace and comments
// %rdi = buffer, %rsi = length, %rdx = position
// Returns: %rax = new position
skip_whitespace_main:
    pushq   %rbp
    movq    %rsp, %rbp
    
    movq    %rdx, %rax
    
skip_ws_main_loop:
    cmpq    %rsi, %rax
    jge     skip_ws_main_done
    
    leaq    (%rdi,%rax), %rcx
    movzbl  (%rcx), %ecx
    
    cmpb    $' ', %cl
    je      skip_ws_main_char
    cmpb    $'\t', %cl
    je      skip_ws_main_char
    cmpb    $'\r', %cl
    je      skip_ws_main_char
    cmpb    $'\n', %cl
    je      skip_ws_main_char
    cmpb    $'#', %cl
    je      skip_comment_main
    
    jmp     skip_ws_main_done
    
skip_ws_main_char:
    incq    %rax
    jmp     skip_ws_main_loop

skip_comment_main:
    // Skip until newline
    incq    %rax
    cmpq    %rsi, %rax
    jge     skip_ws_main_done
    
    leaq    (%rdi,%rax), %rcx
    movzbl  (%rcx), %ecx
    cmpb    $'\n', %cl
    jne     skip_comment_main
    
    incq    %rax                // Skip the newline too
    jmp     skip_ws_main_loop
    
skip_ws_main_done:
    popq    %rbp
    ret
