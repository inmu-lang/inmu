// print_x86.s - Print statement handling for INMU language
// x86_64 Assembly for macOS (Intel)

.global _handle_print

// External symbols
.equ STDOUT, 1
.equ SYS_WRITE, 0x2000004

.data
newline_print: .asciz "\n"

.text

// Handle print statement
// %r12 = buffer base, %r13 = buffer length, %r15 = position of "print"
// Uses: %rax, %rbx, %rcx, %rdx, %rsi, %rdi, %r14
_handle_print:
    // Found "print" at absolute position %r15
    // Now find the opening quote
    pushq   %rbp
    movq    %rsp, %rbp
    
    // Skip past "print" keyword (5 bytes)
    leaq    5(%r15), %rax       // position after "print"
    
    // Find opening quote
    xorq    %rbx, %rbx          // counter
find_quote_loop:
    leaq    (%rax,%rbx), %rcx   // current search position
    cmpq    %r13, %rcx          // check bounds
    jge     print_done
    
    leaq    (%r12,%rcx), %rdx   // buffer address
    movzbl  (%rdx), %esi        // load byte
    cmpb    $34, %sil           // ASCII '"'
    je      found_quote
    
    incq    %rbx
    jmp     find_quote_loop

found_quote:
    // %rcx = position of opening quote
    leaq    1(%rcx), %r14       // start of string (after quote)
    
    // Find closing quote
    xorq    %rbx, %rbx          // counter
find_close_quote:
    leaq    (%r14,%rbx), %rcx   // current position
    cmpq    %r13, %rcx          // check bounds
    jge     print_done
    
    leaq    (%r12,%rcx), %rdx   // buffer address
    movzbl  (%rdx), %esi        // load byte
    cmpb    $34, %sil           // ASCII '"'
    je      found_close_quote
    
    incq    %rbx
    jmp     find_close_quote

found_close_quote:
    // %r14 = start of string, %rbx = length
    movq    $SYS_WRITE, %rax
    movq    $STDOUT, %rdi
    leaq    (%r12,%r14), %rsi   // string address
    movq    %rbx, %rdx          // length
    syscall
    
    // Print newline
    movq    $SYS_WRITE, %rax
    movq    $STDOUT, %rdi
    leaq    newline_print(%rip), %rsi
    movq    $1, %rdx
    syscall

print_done:
    popq    %rbp
    ret
