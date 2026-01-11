// variables.s - Variable management for INMU language
// x86_64 Assembly for macOS (Intel)

.global parse_let_statement
.global set_variable
.global get_variable
.global parse_number_simple

// Constants
.equ MAX_VARIABLES, 26
.equ MAX_VAR_NAME, 32

.data
let_keyword: .asciz "let"

.bss
// Variable storage: name (32 bytes) + value (8 bytes) * 26 variables
variable_storage: .skip 1040  // 40 * 26 = 1040 bytes
variable_count: .skip 8

.text

// Parse let statement
// %r12 = buffer base, %r13 = buffer length, %r15 = position of "let"
// Returns: %rax = bytes consumed
parse_let_statement:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r14
    
    // Skip "let" keyword (3 bytes)
    leaq    3(%r15), %r14
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_var
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     let_done
    
    // Parse variable name
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_var_name
    
    cmpq    $0, %rax
    jle     let_done
    
    movq    %rax, %rbx          // name length
    leaq    (%r12,%r14), %r8    // name pointer
    addq    %rax, %r14
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_var
    movq    %rax, %r14
    
    // Check for '='
    cmpq    %r13, %r14
    jge     let_done
    leaq    (%r12,%r14), %rdi
    movzbl  (%rdi), %eax
    cmpb    $'=', %al
    jne     let_done
    incq    %r14
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_var
    movq    %rax, %r14
    
    // Use expression parser to evaluate the right-hand side
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_expression_advanced
    
    movq    %rax, %r9           // value
    movq    %rdx, %r10          // bytes consumed
    addq    %r10, %r14
    
    // Store variable
    movq    %r8, %rdi           // name pointer
    movq    %rbx, %rsi          // name length
    movq    %r9, %rdx           // value
    call    set_variable
    
let_done:
    movq    %r14, %rax
    subq    %r15, %rax
    popq    %r14
    popq    %rbx
    popq    %rbp
    ret

// Parse variable name
// %rdi = buffer, %rsi = length
// Returns: %rax = name length
parse_var_name:
    pushq   %rbp
    movq    %rsp, %rbp
    
    xorq    %rax, %rax
    
parse_var_loop:
    cmpq    %rsi, %rax
    jge     parse_var_done
    
    movzbl  (%rdi,%rax), %ecx
    
    // Check if alphanumeric or underscore
    cmpb    $'a', %cl
    jl      check_upper_var
    cmpb    $'z', %cl
    jle     var_char_ok
    
check_upper_var:
    cmpb    $'A', %cl
    jl      check_digit_var
    cmpb    $'Z', %cl
    jle     var_char_ok
    
check_digit_var:
    cmpb    $'0', %cl
    jl      check_underscore_var
    cmpb    $'9', %cl
    jle     var_char_ok
    
check_underscore_var:
    cmpb    $'_', %cl
    je      var_char_ok
    
    // Not a valid variable character
    jmp     parse_var_done
    
var_char_ok:
    incq    %rax
    jmp     parse_var_loop
    
parse_var_done:
    popq    %rbp
    ret

// Set variable
// %rdi = name pointer, %rsi = name length, %rdx = value
set_variable:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    
    movq    %rdi, %r12          // name pointer
    movq    %rsi, %r13          // name length
    movq    %rdx, %r14          // value
    
    // Check if name length is valid
    cmpq    $0, %r13
    jle     set_var_done
    cmpq    $MAX_VAR_NAME, %r13
    jg      set_var_done
    
    // Search for existing variable
    xorq    %r15, %r15          // index
    
search_var_loop:
    movq    variable_count(%rip), %rax
    cmpq    %rax, %r15
    jge     add_new_var
    
    // Compare name
    leaq    variable_storage(%rip), %rdi
    movq    $40, %rax
    mulq    %r15
    addq    %rax, %rdi
    
    movq    %rdi, %rsi
    movq    %r12, %rdi
    movq    %r13, %rdx
    call    compare_var_name
    
    cmpq    $1, %rax
    je      update_var
    
    incq    %r15
    jmp     search_var_loop
    
add_new_var:
    // Check if we have space
    movq    variable_count(%rip), %rax
    cmpq    $MAX_VARIABLES, %rax
    jge     set_var_done
    
    // Add new variable
    leaq    variable_storage(%rip), %rdi
    movq    $40, %rax
    mulq    variable_count(%rip)
    addq    %rax, %rdi
    
    // Copy name
    movq    %rdi, %rsi
    movq    %r12, %rdi
    movq    %r13, %rcx
    rep movsb
    
    // Store value
    leaq    variable_storage(%rip), %rdi
    movq    $40, %rax
    mulq    variable_count(%rip)
    addq    $32, %rax
    addq    %rax, %rdi
    movq    %r14, (%rdi)
    
    // Increment count
    incq    variable_count(%rip)
    jmp     set_var_done
    
update_var:
    // Update existing variable
    leaq    variable_storage(%rip), %rdi
    movq    $40, %rax
    mulq    %r15
    addq    $32, %rax
    addq    %rax, %rdi
    movq    %r14, (%rdi)
    
set_var_done:
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

// Compare variable name
// %rdi = name1, %rsi = storage slot, %rdx = name1 length
// Returns: %rax = 1 if match, 0 if not
compare_var_name:
    pushq   %rbp
    movq    %rsp, %rbp
    
    xorq    %rcx, %rcx
    
compare_var_loop:
    cmpq    %rdx, %rcx
    jge     compare_var_match
    
    movzbl  (%rdi,%rcx), %eax
    movzbl  (%rsi,%rcx), %r8d
    
    cmpb    %r8b, %al
    jne     compare_var_no_match
    
    incq    %rcx
    jmp     compare_var_loop
    
compare_var_match:
    // Check if storage name ends here (null byte)
    movzbl  (%rsi,%rcx), %eax
    cmpb    $0, %al
    jne     compare_var_no_match
    
    movq    $1, %rax
    popq    %rbp
    ret
    
compare_var_no_match:
    xorq    %rax, %rax
    popq    %rbp
    ret

// Get variable value
// %rdi = name pointer, %rsi = name length
// Returns: %rax = value, %rdx = 1 if found, 0 if not
get_variable:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    
    movq    %rdi, %r12
    movq    %rsi, %r13
    
    xorq    %rbx, %rbx          // index
    
get_var_loop:
    movq    variable_count(%rip), %rax
    cmpq    %rax, %rbx
    jge     get_var_not_found
    
    // Compare name
    leaq    variable_storage(%rip), %rdi
    movq    $40, %rax
    mulq    %rbx
    addq    %rax, %rdi
    
    movq    %rdi, %rsi
    movq    %r12, %rdi
    movq    %r13, %rdx
    call    compare_var_name
    
    cmpq    $1, %rax
    je      get_var_found
    
    incq    %rbx
    jmp     get_var_loop
    
get_var_found:
    leaq    variable_storage(%rip), %rdi
    movq    $40, %rax
    mulq    %rbx
    addq    $32, %rax
    addq    %rax, %rdi
    movq    (%rdi), %rax
    movq    $1, %rdx
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret
    
get_var_not_found:
    xorq    %rax, %rax
    xorq    %rdx, %rdx
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

// Skip whitespace
// %rdi = buffer, %rsi = length, %rdx = position
// Returns: %rax = new position
skip_whitespace_var:
    pushq   %rbp
    movq    %rsp, %rbp
    
    movq    %rdx, %rax
    
skip_ws_loop:
    cmpq    %rsi, %rax
    jge     skip_ws_done
    
    leaq    (%rdi,%rax), %rcx
    movzbl  (%rcx), %ecx
    
    cmpb    $' ', %cl
    je      skip_ws_char
    cmpb    $'\t', %cl
    je      skip_ws_char
    cmpb    $'\r', %cl
    je      skip_ws_char
    cmpb    $'\n', %cl
    je      skip_ws_char
    
    jmp     skip_ws_done
    
skip_ws_char:
    incq    %rax
    jmp     skip_ws_loop
    
skip_ws_done:
    popq    %rbp
    ret

// Parse simple number (no expressions)
// %rdi = buffer, %rsi = length
// Returns: %rax = value, %rdx = bytes consumed
parse_number_simple:
    pushq   %rbp
    movq    %rsp, %rbp
    
    xorq    %rax, %rax          // result
    xorq    %rdx, %rdx          // bytes consumed
    xorq    %r8, %r8            // negative flag
    movq    %rsi, %r9           // save buffer length
    
    // Check for negative sign
    cmpq    $0, %r9
    jle     parse_num_done
    
    movzbl  (%rdi), %ecx
    cmpb    $'-', %cl
    jne     parse_num_digits
    
    movq    $1, %r8
    incq    %rdx
    
parse_num_digits:
    // Check buffer length
    cmpq    %r9, %rdx
    jge     parse_num_done
    
    movzbl  (%rdi,%rdx), %ecx
    cmpb    $'0', %cl
    jl      parse_num_done
    cmpb    $'9', %cl
    jg      parse_num_done
    
    // %rax = %rax * 10 + (%rcx - '0')
    imulq   $10, %rax
    subq    $'0', %rcx
    addq    %rcx, %rax
    
    incq    %rdx
    jmp     parse_num_digits
    
parse_num_done:
    // Apply negative if needed
    cmpq    $1, %r8
    jne     parse_num_return
    negq    %rax
    
parse_num_return:
    popq    %rbp
    ret
