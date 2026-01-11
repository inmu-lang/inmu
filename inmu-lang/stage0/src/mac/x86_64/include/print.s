// print.s - Print statement handling for INMU language
// x86_64 Assembly for macOS (Intel)

.global _handle_print

// External functions
.extern get_variable
.extern parse_number_simple

// External symbols
.equ STDOUT, 1
.equ SYS_WRITE, 0x2000004

.data
newline_print: .asciz "\n"

.bss
print_num_buffer: .skip 32

.text

// Handle print statement
// %r12 = buffer base, %r13 = buffer length, %r15 = position of "print"
// Returns: %rax = bytes consumed
_handle_print:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r14
    
    // Skip "print" keyword (5 bytes)
    leaq    5(%r15), %r14
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_print
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     print_done
    
    // Check what we're printing
    leaq    (%r12,%r14), %rdi
    movzbl  (%rdi), %eax
    
    // Check for string (quote)
    cmpb    $'"', %al
    je      print_string
    
    // Otherwise, try variable or number
    jmp     print_variable_or_number
    
print_string:
    // Skip opening quote
    incq    %r14
    
    // Find closing quote
    movq    %r14, %rbx
find_close_quote:
    cmpq    %r13, %rbx
    jge     print_done
    
    leaq    (%r12,%rbx), %rdi
    movzbl  (%rdi), %eax
    cmpb    $'"', %al
    je      found_close_quote
    
    incq    %rbx
    jmp     find_close_quote
    
found_close_quote:
    // Print string from %r14 to %rbx
    movq    $SYS_WRITE, %rax
    movq    $STDOUT, %rdi
    leaq    (%r12,%r14), %rsi
    movq    %rbx, %rdx
    subq    %r14, %rdx
    syscall
    
    // Move past closing quote
    leaq    1(%rbx), %r14
    
    // Print newline
    movq    $SYS_WRITE, %rax
    movq    $STDOUT, %rdi
    leaq    newline_print(%rip), %rsi
    movq    $1, %rdx
    syscall
    
    jmp     print_done
    
print_variable_or_number:
    // Check if it's a variable (starts with letter or underscore)
    leaq    (%r12,%r14), %rdi
    movzbl  (%rdi), %eax
    
    // Check for letter
    cmpb    $'a', %al
    jge     check_letter_upper_print
    jmp     check_number_sign_print
    
check_letter_upper_print:
    cmpb    $'z', %cl
    jle     is_variable
    cmpb    $'A', %cl
    jl      check_underscore_print_var
    cmpb    $'Z', %cl
    jle     is_variable
    
check_underscore_print_var:
    cmpb    $'_', %al
    je      is_variable
    
check_number_sign_print:
    // Must be a number
    jmp     is_number
    
is_variable:
    // Parse variable name
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_var_name_print
    
    cmpq    $0, %rax
    jle     print_done
    
    movq    %rax, %rbx          // name length
    leaq    (%r12,%r14), %r8    // name pointer
    addq    %rax, %r14
    
    // Get variable value
    movq    %r8, %rdi
    movq    %rbx, %rsi
    call    get_variable
    
    // %rax = value, %rdx = found flag
    cmpq    $0, %rdx
    je      print_done
    
    // Convert to string and print
    movq    %rax, %rdi
    call    print_number
    
    jmp     print_done
    
is_number:
    // Parse number
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_number_simple
    
    // %rax = value, %rdx = bytes consumed
    addq    %rdx, %r14
    
    // Print number
    movq    %rax, %rdi
    call    print_number
    
print_done:
    movq    %r14, %rax
    subq    %r15, %rax
    popq    %r14
    popq    %rbx
    popq    %rbp
    ret

// Print number
// %rdi = number to print
print_number:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    
    movq    %rdi, %r12          // number
    leaq    print_num_buffer(%rip), %r13
    movq    $31, %r14           // buffer position (start from end)
    
    // Handle zero specially
    cmpq    $0, %r12
    jne     check_negative
    
    movb    $'0', (%r13,%r14)
    decq    %r14
    jmp     print_num_output
    
check_negative:
    xorq    %rbx, %rbx          // negative flag
    cmpq    $0, %r12
    jge     convert_digits
    
    movq    $1, %rbx
    negq    %r12
    
convert_digits:
    cmpq    $0, %r12
    jle     add_sign
    
    movq    %r12, %rax
    xorq    %rdx, %rdx
    movq    $10, %rcx
    divq    %rcx
    
    addb    $'0', %dl
    movb    %dl, (%r13,%r14)
    decq    %r14
    
    movq    %rax, %r12
    jmp     convert_digits
    
add_sign:
    cmpq    $1, %rbx
    jne     print_num_output
    
    movb    $'-', (%r13,%r14)
    decq    %r14
    
print_num_output:
    incq    %r14
    
    // Calculate length
    movq    $32, %rdx
    subq    %r14, %rdx
    
    // Print
    movq    $SYS_WRITE, %rax
    movq    $STDOUT, %rdi
    leaq    (%r13,%r14), %rsi
    syscall
    
    // Print newline
    movq    $SYS_WRITE, %rax
    movq    $STDOUT, %rdi
    leaq    newline_print(%rip), %rsi
    movq    $1, %rdx
    syscall
    
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

// Skip whitespace
// %rdi = buffer, %rsi = length, %rdx = position
// Returns: %rax = new position
skip_whitespace_print:
    pushq   %rbp
    movq    %rsp, %rbp
    
    movq    %rdx, %rax
    
skip_ws_print_loop:
    cmpq    %rsi, %rax
    jge     skip_ws_print_done
    
    leaq    (%rdi,%rax), %rcx
    movzbl  (%rcx), %ecx
    
    cmpb    $' ', %cl
    je      skip_ws_print_char
    cmpb    $'\t', %cl
    je      skip_ws_print_char
    cmpb    $'\r', %cl
    je      skip_ws_print_char
    cmpb    $'\n', %cl
    je      skip_ws_print_char
    
    jmp     skip_ws_print_done
    
skip_ws_print_char:
    incq    %rax
    jmp     skip_ws_print_loop
    
skip_ws_print_done:
    popq    %rbp
    ret

// Parse variable name
// %rdi = buffer, %rsi = length
// Returns: %rax = name length
parse_var_name_print:
    pushq   %rbp
    movq    %rsp, %rbp
    
    xorq    %rax, %rax
    
parse_var_print_loop:
    cmpq    %rsi, %rax
    jge     parse_var_print_done
    
    movzbl  (%rdi,%rax), %ecx
    
    cmpb    $'a', %cl
    jl      check_upper_print
    cmpb    $'z', %cl
    jle     var_char_print_ok
    
check_upper_print:
    cmpb    $'A', %cl
    jl      check_digit_print
    cmpb    $'Z', %cl
    jle     var_char_print_ok
    
check_digit_print:
    cmpb    $'0', %cl
    jl      check_underscore_print
    cmpb    $'9', %cl
    jle     var_char_print_ok
    
check_underscore_print:
    cmpb    $'_', %cl
    je      var_char_print_ok
    
    jmp     parse_var_print_done
    
var_char_print_ok:
    incq    %rax
    jmp     parse_var_print_loop
    
parse_var_print_done:
    popq    %rbp
    ret
