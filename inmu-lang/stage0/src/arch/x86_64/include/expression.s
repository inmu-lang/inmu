// expression.s - Expression evaluation for INMU interpreter
// x86_64 Assembly for macOS (Intel)
// Supports: +, -, *, / operators and parentheses with correct precedence

.global evaluate_expression
.global parse_expression_advanced

// External functions
.extern get_variable

.data
expr_debug_msg:     .asciz "Evaluating expression\n"

.text

// Expression parser with correct operator precedence
// Precedence: +/- (low) < */ (high) < primary (number/variable/parenthesis)
// %rdi = buffer pointer
// %rsi = buffer length
// Returns: %rax = value, %rdx = bytes consumed
parse_expression_advanced:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    
    movq    %rdi, %r12          // Save buffer
    movq    %rsi, %r13          // Save length
    xorq    %r14, %r14          // Bytes consumed = 0
    
    // Parse first multiplication/division level expression
    movq    %r12, %rdi
    movq    %r13, %rsi
    call    parse_mul_div
    
    // Check if parsing succeeded
    cmpq    $0, %rdx
    jle     expr_done_x86       // If no bytes consumed, return 0
    
    movq    %rax, %r15          // Result value
    addq    %rdx, %r14          // Update consumed
    
expr_loop_x86:
    // Check if we have more to parse
    cmpq    %r13, %r14
    jge     expr_done_x86
    
    // Skip whitespace
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    skip_whitespace_expr_x86
    addq    %rax, %r14
    
    // Check again if we have more to parse
    cmpq    %r13, %r14
    jge     expr_done_x86
    
    // Check for + or -
    leaq    (%r12,%r14), %rdi
    movzbl  (%rdi), %eax
    
    cmpb    $'+', %al
    je      found_plus_x86
    cmpb    $'-', %al
    je      found_minus_x86
    
    // Not + or -, done
    jmp     expr_done_x86
    
found_plus_x86:
    incq    %r14                // Skip '+'
    
    // Skip whitespace after operator
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    skip_whitespace_expr_x86
    addq    %rax, %r14
    
    // Check if we have more to parse
    cmpq    %r13, %r14
    jge     expr_done_x86
    
    // Parse next multiplication/division level
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_mul_div
    
    // Check if parsing succeeded
    cmpq    $0, %rdx
    jle     expr_done_x86
    
    addq    %rax, %r15          // Add to result
    addq    %rdx, %r14          // Update consumed
    jmp     expr_loop_x86
    
found_minus_x86:
    incq    %r14                // Skip '-'
    
    // Skip whitespace after operator
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    skip_whitespace_expr_x86
    addq    %rax, %r14
    
    // Check if we have more to parse
    cmpq    %r13, %r14
    jge     expr_done_x86
    
    // Parse next multiplication/division level
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_mul_div
    
    // Check if parsing succeeded
    cmpq    $0, %rdx
    jle     expr_done_x86
    
    subq    %rax, %r15          // Subtract from result
    addq    %rdx, %r14          // Update consumed
    jmp     expr_loop_x86
    
expr_done_x86:
    movq    %r15, %rax          // Return value
    movq    %r14, %rdx          // Return bytes consumed
    
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

// Parse multiplication and division level
// %rdi = buffer pointer
// %rsi = buffer length
// Returns: %rax = value, %rdx = bytes consumed
parse_mul_div:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    
    movq    %rdi, %r12          // Save buffer
    movq    %rsi, %r13          // Save length
    xorq    %r14, %r14          // Bytes consumed = 0
    
    // Parse first primary (number, variable, or parenthesized expression)
    movq    %r12, %rdi
    movq    %r13, %rsi
    call    parse_primary
    
    // Check if parsing succeeded
    cmpq    $0, %rdx
    jle     mul_div_done        // If no bytes consumed, return 0
    
    movq    %rax, %r15          // Result value
    addq    %rdx, %r14          // Update consumed
    
mul_div_loop:
    // Check if we have more to parse
    cmpq    %r13, %r14
    jge     mul_div_done
    
    // Skip whitespace
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    skip_whitespace_expr_x86
    addq    %rax, %r14
    
    // Check again if we have more to parse
    cmpq    %r13, %r14
    jge     mul_div_done
    
    // Check for * or /
    leaq    (%r12,%r14), %rdi
    movzbl  (%rdi), %eax
    
    cmpb    $'*', %al
    je      found_mult_md
    cmpb    $'/', %al
    je      found_div_md
    
    // Not * or /, done
    jmp     mul_div_done
    
found_mult_md:
    incq    %r14                // Skip '*'
    
    // Skip whitespace after operator
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    skip_whitespace_expr_x86
    addq    %rax, %r14
    
    // Check if we have more to parse
    cmpq    %r13, %r14
    jge     mul_div_done
    
    // Parse next primary
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_primary
    
    // Check if parsing succeeded
    cmpq    $0, %rdx
    jle     mul_div_done
    
    imulq   %rax, %r15          // Multiply result
    addq    %rdx, %r14          // Update consumed
    jmp     mul_div_loop
    
found_div_md:
    incq    %r14                // Skip '/'
    
    // Skip whitespace after operator
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    skip_whitespace_expr_x86
    addq    %rax, %r14
    
    // Check if we have more to parse
    cmpq    %r13, %r14
    jge     mul_div_done
    
    // Parse next primary
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_primary
    
    // Check if parsing succeeded
    cmpq    $0, %rdx
    jle     mul_div_done
    
    // Check for division by zero
    cmpq    $0, %rax
    je      div_by_zero_md
    
    // Save bytes consumed from parse_primary
    pushq   %rdx
    
    // Divide: %r15 / %rax
    movq    %r15, %rcx
    movq    %rax, %rbx
    movq    %rcx, %rax
    xorq    %rdx, %rdx
    divq    %rbx
    movq    %rax, %r15          // Store quotient in result
    
    // Restore and update bytes consumed
    popq    %rdx
    addq    %rdx, %r14          // Update consumed
    jmp     mul_div_loop
    
div_by_zero_md:
    // Just continue with current result on division by zero
    jmp     mul_div_loop
    
mul_div_done:
    movq    %r15, %rax          // Return value
    movq    %r14, %rdx          // Return bytes consumed
    
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

// Parse a primary (number, variable, or parenthesized expression)
// %rdi = buffer pointer
// %rsi = buffer length
// Returns: %rax = value, %rdx = bytes consumed
parse_primary:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    
    movq    %rdi, %r12
    movq    %rsi, %r13
    
    // Check if buffer is empty
    cmpq    $0, %r13
    jle     primary_empty_x86
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    call    skip_whitespace_expr_x86
    movq    %rax, %r14          // Bytes consumed for whitespace
    addq    %rax, %r12
    subq    %rax, %r13
    
    // Check again if buffer is now empty
    cmpq    $0, %r13
    jle     primary_empty_x86
    
    // Check first character
    movzbl  (%r12), %eax
    
    // Check for '('
    cmpb    $'(', %al
    je      parse_paren_x86
    
    // Check if digit
    cmpb    $'0', %al
    jl      try_variable_x86
    cmpb    $'9', %al
    jle     parse_number_primary_x86
    
try_variable_x86:
    // Check if valid variable start (letter or underscore)
    cmpb    $'_', %al
    je      parse_as_variable_x86
    cmpb    $'a', %al
    jl      check_upper_var_x86
    cmpb    $'z', %al
    jle     parse_as_variable_x86
check_upper_var_x86:
    cmpb    $'A', %al
    jl      primary_empty_x86   // Not a valid start, return 0
    cmpb    $'Z', %al
    jg      primary_empty_x86   // Not a valid start, return 0
    
parse_as_variable_x86:
    // Try to parse as variable
    movq    %r12, %rdi
    movq    %r13, %rsi
    call    parse_variable_ref_x86
    addq    %r14, %rdx          // Add whitespace bytes
    
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret
    
parse_number_primary_x86:
    // Parse as number
    movq    %r12, %rdi
    movq    %r13, %rsi
    call    parse_number_simple_expr
    addq    %r14, %rdx          // Add whitespace bytes
    
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret
    
parse_paren_x86:
    // Skip '('
    incq    %r12
    decq    %r13
    incq    %r14
    
    // Parse expression recursively
    movq    %r12, %rdi
    movq    %r13, %rsi
    call    parse_expression_advanced
    movq    %rax, %r15          // Save result
    addq    %rdx, %r14          // Add consumed bytes
    addq    %rdx, %r12
    subq    %rdx, %r13
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    call    skip_whitespace_expr_x86
    addq    %rax, %r14
    addq    %rax, %r12
    subq    %rax, %r13
    
    // Check if we still have characters
    cmpq    $0, %r13
    jle     paren_done_x86
    
    // Expect ')'
    movzbl  (%r12), %eax
    cmpb    $')', %al
    jne     paren_done_x86      // If no closing paren, just continue
    
    incq    %r14                // Skip ')'
    
paren_done_x86:
    movq    %r15, %rax          // Return value
    movq    %r14, %rdx          // Return bytes consumed
    
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

primary_empty_x86:
    xorq    %rax, %rax          // Return 0
    xorq    %rdx, %rdx          // 0 bytes consumed
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

// Parse variable reference
// %rdi = buffer pointer
// %rsi = buffer length
// Returns: %rax = value, %rdx = bytes consumed
parse_variable_ref_x86:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    
    movq    %rdi, %r12
    movq    %rsi, %r13
    
    subq    $64, %rsp           // Space for variable name
    movq    %rsp, %r14
    
    // Extract variable name
    xorq    %r15, %r15          // Counter
extract_var_name_x86:
    cmpq    $63, %r15
    jge     var_name_done_x86
    cmpq    %r13, %r15
    jge     var_name_done_x86
    
    movzbl  (%r12,%r15), %eax
    
    // Check if alphanumeric or underscore
    cmpb    $'_', %al
    je      valid_var_char_x86
    cmpb    $'a', %al
    jl      check_upper_expr_x86
    cmpb    $'z', %al
    jle     valid_var_char_x86
check_upper_expr_x86:
    cmpb    $'A', %al
    jl      check_digit_expr_x86
    cmpb    $'Z', %al
    jle     valid_var_char_x86
check_digit_expr_x86:
    // First character cannot be a digit (if %r15 == 0)
    cmpq    $0, %r15
    je      var_name_done_x86   // Invalid first char
    
    cmpb    $'0', %al
    jl      var_name_done_x86
    cmpb    $'9', %al
    jg      var_name_done_x86
    
valid_var_char_x86:
    movb    %al, (%r14,%r15)
    incq    %r15
    jmp     extract_var_name_x86
    
var_name_done_x86:
    // Null terminate
    movb    $0, (%r14,%r15)
    
    // Get variable value (only name pointer needed)
    movq    %r14, %rdi
    call    get_variable
    
    movq    %rax, %rbx          // Save value
    
    // Clean up stack
    addq    $64, %rsp
    
    movq    %rbx, %rax          // Return value
    movq    %r15, %rdx          // Return bytes consumed
    
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

// Skip whitespace
// %rdi = buffer pointer
// %rsi = buffer length
// Returns: %rax = bytes skipped
skip_whitespace_expr_x86:
    pushq   %rbp
    movq    %rsp, %rbp
    
    // Check if buffer length is 0 or negative (as unsigned, very large)
    testq   %rsi, %rsi
    jz      skip_ws_done_expr_x86
    movq    $0x7FFFFFFFFFFFFFFF, %rcx
    cmpq    %rcx, %rsi
    ja      skip_ws_done_expr_x86
    
    xorq    %rax, %rax
skip_ws_loop_expr_x86:
    cmpq    %rsi, %rax
    jge     skip_ws_done_expr_x86
    
    movzbl  (%rdi,%rax), %ecx
    cmpb    $' ', %cl
    je      skip_ws_char_expr_x86
    cmpb    $'\t', %cl
    je      skip_ws_char_expr_x86
    cmpb    $'\n', %cl
    je      skip_ws_char_expr_x86
    cmpb    $'\r', %cl
    je      skip_ws_char_expr_x86
    
    // Not whitespace
    jmp     skip_ws_done_expr_x86
    
skip_ws_char_expr_x86:
    incq    %rax
    jmp     skip_ws_loop_expr_x86
    
skip_ws_done_expr_x86:
    popq    %rbp
    ret

// Parse simple number
// %rdi = buffer, %rsi = length
// Returns: %rax = value, %rdx = bytes consumed
parse_number_simple_expr:
    pushq   %rbp
    movq    %rsp, %rbp
    
    xorq    %rax, %rax          // result
    xorq    %rdx, %rdx          // bytes consumed
    xorq    %r8, %r8            // negative flag
    
    // Check for negative sign
    cmpq    $0, %rsi
    jle     parse_num_expr_done
    
    movzbl  (%rdi), %ecx
    cmpb    $'-', %cl
    jne     parse_num_expr_digits
    
    movq    $1, %r8
    incq    %rdx
    
parse_num_expr_digits:
    cmpq    %rsi, %rdx
    jge     parse_num_expr_done
    
    movzbl  (%rdi,%rdx), %ecx
    cmpb    $'0', %cl
    jl      parse_num_expr_done
    cmpb    $'9', %cl
    jg      parse_num_expr_done
    
    // %rax = %rax * 10 + (%rcx - '0')
    imulq   $10, %rax
    subq    $'0', %rcx
    addq    %rcx, %rax
    
    incq    %rdx
    jmp     parse_num_expr_digits
    
parse_num_expr_done:
    // Apply negative if needed
    cmpq    $1, %r8
    jne     parse_num_expr_return
    negq    %rax
    
parse_num_expr_return:
    popq    %rbp
    ret

// Main evaluate_expression function (for compatibility)
// %rdi = buffer pointer
// %rsi = buffer length
// Returns: %rax = value, %rdx = bytes consumed
evaluate_expression:
    jmp     parse_expression_advanced
