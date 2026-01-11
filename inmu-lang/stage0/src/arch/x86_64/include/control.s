// control.s - Control flow structures for INMU language
// x86_64 Assembly for macOS (Intel)

.global parse_if_statement
.global parse_and_execute_one_statement

// External functions
.extern _handle_print
.extern parse_let_statement
.extern get_variable

.data
if_keyword:     .asciz "if"
else_keyword:   .asciz "else"
endif_keyword:  .asciz "endif"
let_keyword_ctrl: .asciz "let"
print_keyword_ctrl: .asciz "print"

.text

// Parse if statement
// %r12 = buffer base, %r13 = buffer length, %r15 = position of "if"
// Returns: %rax = bytes consumed
parse_if_statement:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r14
    subq    $64, %rsp           // Local stack space
    
    // Skip "if" keyword (2 bytes)
    leaq    2(%r15), %r14
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_ctrl
    movq    %rax, %r14
    
    // Parse condition (var == number)
    // Parse variable name
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_var_name_ctrl
    
    cmpq    $0, %rax
    jle     if_done
    
    movq    %rax, %rbx          // var name length
    leaq    (%r12,%r14), %r8    // var name pointer
    movq    %r8, -8(%rbp)       // save on stack
    movq    %rbx, -16(%rbp)     // save on stack
    addq    %rax, %r14
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_ctrl
    movq    %rax, %r14
    
    // Check for "=="
    cmpq    %r13, %r14
    jge     if_done
    leaq    (%r12,%r14), %rdi
    movzbl  (%rdi), %eax
    cmpb    $'=', %al
    jne     if_done
    incq    %r14
    
    cmpq    %r13, %r14
    jge     if_done
    leaq    (%r12,%r14), %rdi
    movzbl  (%rdi), %eax
    cmpb    $'=', %al
    jne     if_done
    incq    %r14
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_ctrl
    movq    %rax, %r14
    
    // Parse comparison value
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_number_simple_ctrl
    
    movq    %rax, %r9           // comparison value
    movq    %rdx, %r10          // bytes consumed
    addq    %r10, %r14
    movq    %r9, -24(%rbp)      // save on stack
    
    // Get variable value
    movq    -8(%rbp), %rdi
    movq    -16(%rbp), %rsi
    call    get_variable
    
    // %rax = var value, %rdx = found flag
    cmpq    $0, %rdx
    je      if_done
    
    movq    -24(%rbp), %r9      // comparison value
    
    // Compare
    cmpq    %r9, %rax
    je      if_true
    
if_false:
    // Find else or endif
    movq    %r14, %rdi
    movq    $0, %rsi            // looking for else
    call    find_else_or_endif
    
    cmpq    $0, %rax
    jl      if_done
    
    movq    %rax, %r14
    
    // Check if we found else
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    leaq    else_keyword(%rip), %rcx
    movq    $4, %r8
    call    check_keyword_at_pos_ctrl
    
    cmpq    $1, %rax
    jne     if_skip_to_endif
    
    // Execute else block
    addq    $4, %r14            // skip "else"
    
    movq    %r14, %rdi
    call    execute_until_endif
    
    movq    %rax, %r14
    jmp     if_done
    
if_skip_to_endif:
    // Already at endif, skip it
    addq    $5, %r14
    jmp     if_done
    
if_true:
    // Execute if block until else or endif
    movq    %r14, %rdi
    call    execute_until_else_or_endif
    
    movq    %rax, %r14
    
    // Check if we're at else
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    leaq    else_keyword(%rip), %rcx
    movq    $4, %r8
    call    check_keyword_at_pos_ctrl
    
    cmpq    $1, %rax
    jne     if_check_endif
    
    // Skip else block
    addq    $4, %r14
    movq    %r14, %rdi
    movq    $1, %rsi            // looking for endif
    call    find_else_or_endif
    
    movq    %rax, %r14
    addq    $5, %r14            // skip "endif"
    jmp     if_done
    
if_check_endif:
    // Should be at endif
    addq    $5, %r14
    
if_done:
    movq    %r14, %rax
    subq    %r15, %rax
    addq    $64, %rsp
    popq    %r14
    popq    %rbx
    popq    %rbp
    ret

// Find else or endif
// %rdi = start position, %rsi = 0 for else, 1 for endif only
// Returns: %rax = position or -1
find_else_or_endif:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    
    movq    %rdi, %rbx          // current position
    movq    %rsi, %r10          // search mode
    
find_ee_loop:
    cmpq    %r13, %rbx
    jge     find_ee_not_found
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %rbx, %rdx
    call    skip_whitespace_ctrl
    movq    %rax, %rbx
    
    cmpq    %r13, %rbx
    jge     find_ee_not_found
    
    // Check for endif
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %rbx, %rdx
    leaq    endif_keyword(%rip), %rcx
    movq    $5, %r8
    call    check_keyword_at_pos_ctrl
    
    cmpq    $1, %rax
    je      find_ee_found
    
    // Check for else if not looking for endif only
    cmpq    $1, %r10
    je      find_ee_next
    
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %rbx, %rdx
    leaq    else_keyword(%rip), %rcx
    movq    $4, %r8
    call    check_keyword_at_pos_ctrl
    
    cmpq    $1, %rax
    je      find_ee_found
    
find_ee_next:
    incq    %rbx
    jmp     find_ee_loop
    
find_ee_found:
    movq    %rbx, %rax
    popq    %rbx
    popq    %rbp
    ret
    
find_ee_not_found:
    movq    $-1, %rax
    popq    %rbx
    popq    %rbp
    ret

// Execute statements until else or endif
// %rdi = start position
// Returns: %rax = position of else/endif
execute_until_else_or_endif:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    
    movq    %rdi, %rbx
    
exec_ee_loop:
    cmpq    %r13, %rbx
    jge     exec_ee_done
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %rbx, %rdx
    call    skip_whitespace_ctrl
    movq    %rax, %rbx
    
    // Check for else
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %rbx, %rdx
    leaq    else_keyword(%rip), %rcx
    movq    $4, %r8
    call    check_keyword_at_pos_ctrl
    
    cmpq    $1, %rax
    je      exec_ee_done
    
    // Check for endif
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %rbx, %rdx
    leaq    endif_keyword(%rip), %rcx
    movq    $5, %r8
    call    check_keyword_at_pos_ctrl
    
    cmpq    $1, %rax
    je      exec_ee_done
    
    // Execute one statement
    movq    %rbx, %r15
    call    parse_and_execute_one_statement
    
    addq    %rax, %rbx
    
    cmpq    $0, %rax
    jle     exec_ee_next
    
    jmp     exec_ee_loop
    
exec_ee_next:
    incq    %rbx
    jmp     exec_ee_loop
    
exec_ee_done:
    movq    %rbx, %rax
    popq    %rbx
    popq    %rbp
    ret

// Execute statements until endif
// %rdi = start position
// Returns: %rax = position of endif
execute_until_endif:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    
    movq    %rdi, %rbx
    
exec_endif_loop:
    cmpq    %r13, %rbx
    jge     exec_endif_done
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %rbx, %rdx
    call    skip_whitespace_ctrl
    movq    %rax, %rbx
    
    // Check for endif
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %rbx, %rdx
    leaq    endif_keyword(%rip), %rcx
    movq    $5, %r8
    call    check_keyword_at_pos_ctrl
    
    cmpq    $1, %rax
    je      exec_endif_done
    
    // Execute one statement
    movq    %rbx, %r15
    call    parse_and_execute_one_statement
    
    addq    %rax, %rbx
    
    cmpq    $0, %rax
    jle     exec_endif_next
    
    jmp     exec_endif_loop
    
exec_endif_next:
    incq    %rbx
    jmp     exec_endif_loop
    
exec_endif_done:
    movq    %rbx, %rax
    popq    %rbx
    popq    %rbp
    ret

// Parse and execute one statement
// %r15 = position
// Returns: %rax = bytes consumed
parse_and_execute_one_statement:
    pushq   %rbp
    movq    %rsp, %rbp
    
    // Check for print
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r15, %rdx
    leaq    print_keyword_ctrl(%rip), %rcx
    movq    $5, %r8
    call    check_keyword_at_pos_ctrl
    
    cmpq    $1, %rax
    jne     check_let_stmt
    
    call    _handle_print
    movq    %rax, %r8
    jmp     stmt_done
    
check_let_stmt:
    // Check for let
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r15, %rdx
    leaq    let_keyword_ctrl(%rip), %rcx
    movq    $3, %r8
    call    check_keyword_at_pos_ctrl
    
    cmpq    $1, %rax
    jne     stmt_unknown
    
    call    parse_let_statement
    movq    %rax, %r8
    jmp     stmt_done
    
stmt_unknown:
    xorq    %r8, %r8
    
stmt_done:
    movq    %r8, %rax
    popq    %rbp
    ret

// Check keyword at position
// %rdi = buffer, %rsi = length, %rdx = position, %rcx = keyword, %r8 = keyword length
// Returns: %rax = 1 if match, 0 if not
check_keyword_at_pos_ctrl:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    
    // Check bounds
    movq    %rsi, %rax
    subq    %rdx, %rax
    cmpq    %r8, %rax
    jl      check_kw_no_match
    
    // Compare bytes
    xorq    %rbx, %rbx
    
check_kw_loop:
    cmpq    %r8, %rbx
    jge     check_kw_match
    
    leaq    (%rdx,%rbx), %r9
    leaq    (%rdi,%r9), %r10
    movzbl  (%r10), %eax
    movzbl  (%rcx,%rbx), %r11d
    
    cmpb    %r11b, %al
    jne     check_kw_no_match
    
    incq    %rbx
    jmp     check_kw_loop
    
check_kw_match:
    movq    $1, %rax
    popq    %rbx
    popq    %rbp
    ret
    
check_kw_no_match:
    xorq    %rax, %rax
    popq    %rbx
    popq    %rbp
    ret

// Skip whitespace
// %rdi = buffer, %rsi = length, %rdx = position
// Returns: %rax = new position
skip_whitespace_ctrl:
    pushq   %rbp
    movq    %rsp, %rbp
    
    movq    %rdx, %rax
    
skip_ws_ctrl_loop:
    cmpq    %rsi, %rax
    jge     skip_ws_ctrl_done
    
    leaq    (%rdi,%rax), %rcx
    movzbl  (%rcx), %ecx
    
    cmpb    $' ', %cl
    je      skip_ws_ctrl_char
    cmpb    $'\t', %cl
    je      skip_ws_ctrl_char
    cmpb    $'\r', %cl
    je      skip_ws_ctrl_char
    cmpb    $'\n', %cl
    je      skip_ws_ctrl_char
    
    jmp     skip_ws_ctrl_done
    
skip_ws_ctrl_char:
    incq    %rax
    jmp     skip_ws_ctrl_loop
    
skip_ws_ctrl_done:
    popq    %rbp
    ret

// Parse variable name
// %rdi = buffer, %rsi = length
// Returns: %rax = name length
parse_var_name_ctrl:
    pushq   %rbp
    movq    %rsp, %rbp
    
    xorq    %rax, %rax
    
parse_var_ctrl_loop:
    cmpq    %rsi, %rax
    jge     parse_var_ctrl_done
    
    movzbl  (%rdi,%rax), %ecx
    
    cmpb    $'a', %cl
    jl      check_upper_ctrl
    cmpb    $'z', %cl
    jle     var_char_ctrl_ok
    
check_upper_ctrl:
    cmpb    $'A', %cl
    jl      check_digit_ctrl
    cmpb    $'Z', %cl
    jle     var_char_ctrl_ok
    
check_digit_ctrl:
    cmpb    $'0', %cl
    jl      check_underscore_ctrl
    cmpb    $'9', %cl
    jle     var_char_ctrl_ok
    
check_underscore_ctrl:
    cmpb    $'_', %cl
    je      var_char_ctrl_ok
    
    jmp     parse_var_ctrl_done
    
var_char_ctrl_ok:
    incq    %rax
    jmp     parse_var_ctrl_loop
    
parse_var_ctrl_done:
    popq    %rbp
    ret

// Parse simple number
// %rdi = buffer, %rsi = length
// Returns: %rax = value, %rdx = bytes consumed
parse_number_simple_ctrl:
    pushq   %rbp
    movq    %rsp, %rbp
    
    xorq    %rax, %rax
    xorq    %rdx, %rdx
    xorq    %r8, %r8
    
    cmpq    $0, %rsi
    jle     parse_num_ctrl_done
    
    movzbl  (%rdi), %ecx
    cmpb    $'-', %cl
    jne     parse_num_ctrl_digits
    
    movq    $1, %r8
    incq    %rdx
    
parse_num_ctrl_digits:
    cmpq    %rsi, %rdx
    jge     parse_num_ctrl_done
    
    movzbl  (%rdi,%rdx), %ecx
    cmpb    $'0', %cl
    jl      parse_num_ctrl_done
    cmpb    $'9', %cl
    jg      parse_num_ctrl_done
    
    imulq   $10, %rax
    subq    $'0', %rcx
    addq    %rcx, %rax
    
    incq    %rdx
    jmp     parse_num_ctrl_digits
    
parse_num_ctrl_done:
    cmpq    $1, %r8
    jne     parse_num_ctrl_return
    negq    %rax
    
parse_num_ctrl_return:
    popq    %rbp
    ret
