// control.s - Control flow structures for INMU interpreter
// ARM64 Assembly for macOS (Apple Silicon)
// Supports: if, else

.global parse_if_statement
.global compare_values

.data
else_keyword:    .asciz "else"
endif_keyword:   .asciz "endif"

.text

// Parse if statement
// x0 = buffer pointer (at "if"), x1 = remaining length
// Returns: bytes consumed in x0
parse_if_statement:
    stp     x29, x30, [sp, #-64]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]
    
    mov     x19, x0             // Save buffer
    mov     x20, x1             // Save length
    mov     x21, #2             // Skip "if" (2 chars)
    
    // Skip whitespace after "if"
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_ctrl
    add     x21, x21, x0
    
    // Parse condition (simple: number comparison)
    // For now: "var == number" or "number == number"
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      parse_expression_advanced
    mov     x22, x0             // Left value
    add     x21, x21, x1
    
    // Skip whitespace
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_ctrl
    add     x21, x21, x0
    
    // Check for comparison operator
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #'='
    b.ne    if_error
    add     x21, x21, #1
    ldrb    w1, [x0, #1]
    cmp     w1, #'='
    b.ne    if_error
    add     x21, x21, #1
    mov     x23, #0             // Comparison type: 0 = ==
    
parse_if_right:
    // Skip whitespace
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_ctrl
    add     x21, x21, x0
    
    // Parse right expression
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      parse_expression_advanced
    mov     x24, x0             // Right value
    add     x21, x21, x1
    
    // Compare values
    cmp     x22, x24
    cset    x25, eq             // 1 if equal, 0 if not
    
    // Skip whitespace and newline
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_and_newline_ctrl
    add     x21, x21, x0
    
    // If condition is true, execute the body
    cmp     x25, #1
    b.eq    execute_if_body
    
    // Condition is false, skip to else or endif
    b       skip_if_body
    
execute_if_body:
    // Find endif or else and execute statements
    mov     x22, x21            // Start of body
find_if_end_exec:
    cmp     x21, x20
    b.ge    if_done
    
    // Check for "else" or "endif"
    add     x0, x19, x21
    sub     x1, x20, x21
    adrp    x2, else_keyword@PAGE
    add     x2, x2, else_keyword@PAGEOFF
    mov     x3, #4
    bl      check_keyword_at_pos_ctrl
    cmp     x0, #1
    b.eq    found_else_exec
    
    add     x0, x19, x21
    sub     x1, x20, x21
    adrp    x2, endif_keyword@PAGE
    add     x2, x2, endif_keyword@PAGEOFF
    mov     x3, #5
    bl      check_keyword_at_pos_ctrl
    cmp     x0, #1
    b.eq    if_done
    
    // Execute current statement (print or let)
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      parse_and_execute_one_statement
    add     x21, x21, x0
    
    // Skip whitespace and newline
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_and_newline_ctrl
    add     x21, x21, x0
    
    b       find_if_end_exec
    
found_else_exec:
    // Skip to endif
    add     x21, x21, #4        // Skip "else"
    b       skip_else_body
    
skip_if_body:
    // Skip until else or endif
find_else_or_endif:
    cmp     x21, x20
    b.ge    if_done
    
    // Check for "else"
    add     x0, x19, x21
    sub     x1, x20, x21
    adrp    x2, else_keyword@PAGE
    add     x2, x2, else_keyword@PAGEOFF
    mov     x3, #4
    bl      check_keyword_at_pos_ctrl
    cmp     x0, #1
    b.eq    found_else_skip
    
    // Check for "endif"
    add     x0, x19, x21
    sub     x1, x20, x21
    adrp    x2, endif_keyword@PAGE
    add     x2, x2, endif_keyword@PAGEOFF
    mov     x3, #5
    bl      check_keyword_at_pos_ctrl
    cmp     x0, #1
    b.eq    if_done
    
    // Skip one character
    add     x21, x21, #1
    b       find_else_or_endif
    
found_else_skip:
    // Execute else body
    add     x21, x21, #4        // Skip "else"
    
    // Skip whitespace
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_and_newline_ctrl
    add     x21, x21, x0
    
execute_else_body:
    cmp     x21, x20
    b.ge    if_done
    
    // Check for "endif"
    add     x0, x19, x21
    sub     x1, x20, x21
    adrp    x2, endif_keyword@PAGE
    add     x2, x2, endif_keyword@PAGEOFF
    mov     x3, #5
    bl      check_keyword_at_pos_ctrl
    cmp     x0, #1
    b.eq    if_done
    
    // Execute statement
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      parse_and_execute_one_statement
    add     x21, x21, x0
    
    // Skip whitespace
    add     x0, x19, x21
    sub     x1, x20, x21
    bl      skip_whitespace_and_newline_ctrl
    add     x21, x21, x0
    
    b       execute_else_body
    
skip_else_body:
    // Skip to endif
find_endif_after_else:
    cmp     x21, x20
    b.ge    if_done
    
    // Check for "endif"
    add     x0, x19, x21
    sub     x1, x20, x21
    adrp    x2, endif_keyword@PAGE
    add     x2, x2, endif_keyword@PAGEOFF
    mov     x3, #5
    bl      check_keyword_at_pos_ctrl
    cmp     x0, #1
    b.eq    if_done
    
    add     x21, x21, #1
    b       find_endif_after_else
    
if_error:
    mov     x0, #0
    b       if_cleanup
    
if_done:
    // Skip "endif" keyword
    add     x21, x21, #5
    mov     x0, x21
    
if_cleanup:
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #64
    ret

// Parse and execute one statement (helper for if/else)
// x0 = buffer, x1 = length
// Returns: bytes consumed
parse_and_execute_one_statement:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    
    mov     x19, x0
    mov     x20, x1
    
    // Check for "print"
    mov     x0, x19
    mov     x1, x20
    adrp    x2, print_keyword@PAGE
    add     x2, x2, print_keyword@PAGEOFF
    mov     x3, #5
    bl      check_keyword_at_pos_ctrl
    cmp     x0, #1
    b.eq    exec_print
    
    // Check for "let"
    mov     x0, x19
    mov     x1, x20
    adrp    x2, let_keyword@PAGE
    add     x2, x2, let_keyword@PAGEOFF
    mov     x3, #3
    bl      check_keyword_at_pos_ctrl
    cmp     x0, #1
    b.eq    exec_let
    
    // Unknown statement - return 0
    mov     x0, #0
    b       exec_done
    
exec_print:
    mov     x0, x19
    mov     x1, x20
    bl      handle_print
    b       exec_done
    
exec_let:
    mov     x0, x19
    mov     x1, x20
    bl      parse_let_statement
    
exec_done:
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// Check keyword at position
// x0 = buffer, x1 = length, x2 = keyword, x3 = keyword_len
// Returns: 1 if match, 0 otherwise
check_keyword_at_pos_ctrl:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    cmp     x1, x3
    b.lt    no_match_ctrl
    
    mov     x4, #0
cmp_loop_ctrl:
    cmp     x4, x3
    b.ge    match_ctrl
    
    ldrb    w5, [x0, x4]
    ldrb    w6, [x2, x4]
    cmp     w5, w6
    b.ne    no_match_ctrl
    
    add     x4, x4, #1
    b       cmp_loop_ctrl
    
match_ctrl:
    mov     x0, #1
    ldp     x29, x30, [sp], #16
    ret
    
no_match_ctrl:
    mov     x0, #0
    ldp     x29, x30, [sp], #16
    ret

// Skip whitespace
skip_whitespace_ctrl:
    mov     x2, #0
skip_ws_loop_ctrl:
    cmp     x2, x1
    b.ge    skip_ws_done_ctrl
    
    ldrb    w3, [x0, x2]
    cmp     w3, #' '
    b.eq    skip_ws_char_ctrl
    cmp     w3, #'\t'
    b.eq    skip_ws_char_ctrl
    b       skip_ws_done_ctrl
    
skip_ws_char_ctrl:
    add     x2, x2, #1
    b       skip_ws_loop_ctrl
    
skip_ws_done_ctrl:
    mov     x0, x2
    ret

// Skip whitespace and newlines
skip_whitespace_and_newline_ctrl:
    mov     x2, #0
skip_wsnl_loop:
    cmp     x2, x1
    b.ge    skip_wsnl_done
    
    ldrb    w3, [x0, x2]
    cmp     w3, #' '
    b.eq    skip_wsnl_char
    cmp     w3, #'\t'
    b.eq    skip_wsnl_char
    cmp     w3, #'\n'
    b.eq    skip_wsnl_char
    cmp     w3, #'\r'
    b.eq    skip_wsnl_char
    b       skip_wsnl_done
    
skip_wsnl_char:
    add     x2, x2, #1
    b       skip_wsnl_loop
    
skip_wsnl_done:
    mov     x0, x2
    ret
