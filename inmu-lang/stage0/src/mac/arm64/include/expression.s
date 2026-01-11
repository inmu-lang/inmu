// expression.s - Expression evaluation for INMU interpreter
// ARM64 Assembly for macOS (Apple Silicon)
// Supports: +, -, *, / operators and parentheses

.global evaluate_expression
.global parse_expression_advanced

.data
expr_debug_msg:     .asciz "Evaluating expression\n"

.text

// Advanced expression parser with operators
// x0 = buffer pointer
// x1 = buffer length
// Returns: x0 = value, x1 = bytes consumed
parse_expression_advanced:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    
    mov     x19, x0             // Save buffer
    mov     x20, x1             // Save length
    mov     x21, #0             // Bytes consumed
    
    // Parse first term (number or variable or parenthesis)
    mov     x0, x19
    mov     x1, x20
    bl      parse_term
    
    // Check if first term parsing succeeded
    cmp     x1, #0
    b.le    expr_done           // If no bytes consumed, return 0
    
    mov     x22, x0             // Result value
    add     x21, x21, x1        // Update consumed
    
expr_loop:
    // Skip whitespace
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_expr
    add     x21, x21, x0
    
    // Check if we have more to parse
    cmp     x21, x20
    b.ge    expr_done
    
    // Check for operator
    add     x0, x19, x21
    ldrb    w1, [x0]
    
    // Check for + - * /
    cmp     w1, #'+'
    b.eq    found_plus
    cmp     w1, #'-'
    b.eq    found_minus
    cmp     w1, #'*'
    b.eq    found_mult
    cmp     w1, #'/'
    b.eq    found_div
    
    // Not an operator, done
    b       expr_done
    
found_plus:
    add     x21, x21, #1        // Skip '+'
    
    // Check if we have more to parse
    cmp     x21, x20
    b.ge    expr_done
    
    // Skip whitespace after operator
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_expr
    add     x21, x21, x0
    
    // Check again after whitespace
    cmp     x21, x20
    b.ge    expr_done
    
    // Parse next term
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      parse_term
    
    // Check if term parsing succeeded (consumed > 0)
    cmp     x1, #0
    b.le    expr_done           // If no bytes consumed, stop
    
    add     x22, x22, x0        // Add to result
    add     x21, x21, x1        // Update consumed
    b       expr_loop
    
found_minus:
    add     x21, x21, #1        // Skip '-'
    
    // Check if we have more to parse
    cmp     x21, x20
    b.ge    expr_done
    
    // Skip whitespace
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_expr
    add     x21, x21, x0
    
    // Check again after whitespace
    cmp     x21, x20
    b.ge    expr_done
    
    // Parse next term
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      parse_term
    
    // Check if term parsing succeeded
    cmp     x1, #0
    b.le    expr_done
    
    sub     x22, x22, x0        // Subtract from result
    add     x21, x21, x1        // Update consumed
    b       expr_loop
    
found_mult:
    add     x21, x21, #1        // Skip '*'
    
    // Check if we have more to parse
    cmp     x21, x20
    b.ge    expr_done
    
    // Skip whitespace
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_expr
    add     x21, x21, x0
    
    // Check again after whitespace
    cmp     x21, x20
    b.ge    expr_done
    
    // Parse next term
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      parse_term
    
    // Check if term parsing succeeded
    cmp     x1, #0
    b.le    expr_done
    
    mul     x22, x22, x0        // Multiply result
    add     x21, x21, x1        // Update consumed
    b       expr_loop
    
found_div:
    add     x21, x21, #1        // Skip '/'
    
    // Check if we have more to parse
    cmp     x21, x20
    b.ge    expr_done
    
    // Skip whitespace
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_expr
    add     x21, x21, x0
    
    // Check again after whitespace
    cmp     x21, x20
    b.ge    expr_done
    
    // Parse next term
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      parse_term
    
    // Check if term parsing succeeded
    cmp     x1, #0
    b.le    expr_done
    
    // Check for division by zero
    cmp     x0, #0
    b.eq    div_by_zero
    
    udiv    x22, x22, x0        // Divide result
    add     x21, x21, x1        // Update consumed
    b       expr_loop
    
div_by_zero:
    // Return 0 on division by zero
    mov     x22, #0
    
expr_done:
    mov     x0, x22             // Return value
    mov     x1, x21             // Return bytes consumed
    
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

// Parse a term (number, variable, or parenthesized expression)
// x0 = buffer pointer
// x1 = buffer length
// Returns: x0 = value, x1 = bytes consumed
parse_term:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    
    mov     x19, x0
    mov     x20, x1
    
    // Check if buffer is empty
    cmp     x20, #0
    b.le    term_empty
    
    // Skip whitespace
    mov     x0, x19
    mov     x1, x20
    bl      skip_whitespace_expr
    mov     x21, x0             // Bytes consumed for whitespace
    add     x19, x19, x21
    sub     x20, x20, x21
    
    // Check again if buffer is now empty
    cmp     x20, #0
    b.le    term_empty
    
    // Check first character
    ldrb    w1, [x19]
    
    // Check for '('
    cmp     w1, #'('
    b.eq    parse_paren
    
    // Check if digit
    cmp     w1, #'0'
    b.lt    try_variable
    cmp     w1, #'9'
    b.le    parse_number_term
    
try_variable:
    // Check if valid variable start (letter or underscore)
    cmp     w1, #'_'
    b.eq    parse_as_variable
    cmp     w1, #'a'
    b.lt    check_upper_var
    cmp     w1, #'z'
    b.le    parse_as_variable
check_upper_var:
    cmp     w1, #'A'
    b.lt    term_empty          // Not a valid start, return 0
    cmp     w1, #'Z'
    b.gt    term_empty          // Not a valid start, return 0
    
parse_as_variable:
    // Try to parse as variable
    mov     x0, x19
    mov     x1, x20
    bl      parse_variable_ref
    add     x1, x1, x21         // Add whitespace bytes
    
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
    
parse_number_term:
    // Parse as number
    mov     x0, x19
    mov     x1, x20
    bl      parse_number_simple
    add     x1, x1, x21         // Add whitespace bytes
    
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
    
parse_paren:
    // Skip '('
    add     x19, x19, #1
    sub     x20, x20, #1
    add     x21, x21, #1
    
    // Parse expression recursively
    mov     x0, x19
    mov     x1, x20
    bl      parse_expression_advanced
    mov     x22, x0             // Save result
    add     x21, x21, x1        // Add consumed bytes
    add     x19, x19, x1
    sub     x20, x20, x1
    
    // Skip whitespace
    mov     x0, x19
    mov     x1, x20
    bl      skip_whitespace_expr
    add     x21, x21, x0
    add     x19, x19, x0
    
    // Expect ')'
    ldrb    w1, [x19]
    cmp     w1, #')'
    b.ne    paren_done          // If no closing paren, just continue
    
    add     x21, x21, #1        // Skip ')'
    
paren_done:
    mov     x0, x22             // Return value
    mov     x1, x21             // Return bytes consumed
    
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

term_empty:
    mov     x0, #0              // Return 0
    mov     x1, #0              // 0 bytes consumed
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// Parse variable reference
// x0 = buffer pointer
// x1 = buffer length
// Returns: x0 = value, x1 = bytes consumed
parse_variable_ref:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    
    mov     x19, x0
    mov     x20, x1
    
    sub     sp, sp, #64         // Space for variable name
    mov     x21, sp
    
    // Extract variable name
    mov     x22, #0             // Counter
extract_var_name:
    cmp     x22, #63
    b.ge    var_name_done
    cmp     x22, x20
    b.ge    var_name_done
    
    ldrb    w1, [x19, x22]
    
    // Check if alphanumeric or underscore
    cmp     w1, #'_'
    b.eq    valid_var_char
    cmp     w1, #'a'
    b.lt    check_upper_expr
    cmp     w1, #'z'
    b.le    valid_var_char
check_upper_expr:
    cmp     w1, #'A'
    b.lt    check_digit_expr
    cmp     w1, #'Z'
    b.le    valid_var_char
check_digit_expr:
    // First character cannot be a digit (if x22 == 0)
    cmp     x22, #0
    b.eq    var_name_done       // Invalid first char
    
    cmp     w1, #'0'
    b.lt    var_name_done
    cmp     w1, #'9'
    b.gt    var_name_done
    
valid_var_char:
    strb    w1, [x21, x22]
    add     x22, x22, #1
    b       extract_var_name
    
var_name_done:
    // Null terminate
    strb    wzr, [x21, x22]
    
    // Get variable value
    mov     x0, x21
    bl      get_variable
    mov     x23, x0             // Save value
    
    // Clean up stack
    add     sp, sp, #64
    
    mov     x0, x23             // Return value
    mov     x1, x22             // Return bytes consumed
    
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

// Skip whitespace
// x0 = buffer pointer
// x1 = buffer length
// Returns: x0 = bytes skipped
skip_whitespace_expr:
    mov     x2, #0
skip_ws_loop_expr:
    cmp     x2, x1
    b.ge    skip_ws_done_expr
    
    ldrb    w3, [x0, x2]
    cmp     w3, #' '
    b.eq    skip_ws_char_expr
    cmp     w3, #'\t'
    b.eq    skip_ws_char_expr
    cmp     w3, #'\n'
    b.eq    skip_ws_char_expr
    cmp     w3, #'\r'
    b.eq    skip_ws_char_expr
    
    // Not whitespace
    b       skip_ws_done_expr
    
skip_ws_char_expr:
    add     x2, x2, #1
    b       skip_ws_loop_expr
    
skip_ws_done_expr:
    mov     x0, x2
    ret

// Main evaluate_expression function (for compatibility)
// x0 = buffer pointer
// x1 = buffer length
// Returns: x0 = value, x1 = bytes consumed
evaluate_expression:
    b       parse_expression_advanced
