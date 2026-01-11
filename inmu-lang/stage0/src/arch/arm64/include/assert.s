// assert.s - Assert statement handling for INMU language
// ARM64 Assembly for macOS (Apple Silicon)

.global handle_assert
.global handle_assert_ne

// External symbols
.equ STDOUT, 1
.equ STDERR, 2
.equ SYS_WRITE, 4
.equ SYS_EXIT, 1

.data
assert_fail_msg1: .asciz "Assertion failed: expected "
assert_fail_msg1_len = . - assert_fail_msg1 - 1

assert_fail_msg2: .asciz ", got "
assert_fail_msg2_len = . - assert_fail_msg2 - 1

assert_ne_fail_msg1: .asciz "Assertion failed: expected NOT "
assert_ne_fail_msg1_len = . - assert_ne_fail_msg1 - 1

assert_ne_fail_msg2: .asciz ", but got "
assert_ne_fail_msg2_len = . - assert_ne_fail_msg2 - 1

newline_assert: .byte 10

.bss
.align 3
assert_error_buffer: .skip 128
assert_number_buf1: .skip 32
assert_number_buf2: .skip 32

.text

// Handle assert statement
// x0 = buffer pointer (at "assert"), x1 = remaining length
// Returns: bytes consumed in x0, or exits if assertion fails
handle_assert:
    stp     x29, x30, [sp, #-80]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]
    stp     x25, x26, [sp, #64]
    
    mov     x19, x0             // Save buffer pointer
    mov     x20, x1             // Save remaining length
    
    // Skip past "assert" keyword (6 bytes)
    mov     x21, #6
    
    // Skip whitespace
skip_assert_ws1:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    assert_parse_error
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_assert_char1
    cmp     w1, #'\t'
    b.eq    skip_assert_char1
    b       check_assert_open_paren
skip_assert_char1:
    add     x21, x21, #1
    b       skip_assert_ws1

check_assert_open_paren:
    // Check for opening parenthesis '('
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #'('
    b.ne    assert_parse_error
    add     x21, x21, #1        // Skip '('
    
    // Skip whitespace after '('
skip_assert_ws_after_paren:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    assert_parse_error
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_assert_char_after_paren
    cmp     w1, #'\t'
    b.eq    skip_assert_char_after_paren
    b       parse_assert_actual
skip_assert_char_after_paren:
    add     x21, x21, #1
    b       skip_assert_ws_after_paren
    
parse_assert_actual:
    // Parse the actual value (expression)
    add     x0, x19, x21        // buffer at expression
    sub     x1, x20, x21        // remaining length
    
    // Save position before calling evaluate_expression
    mov     x24, x21
    
    // Call evaluate_expression
    bl      evaluate_expression
    
    // x0 = result value, x1 = bytes consumed
    mov     x22, x0             // Save actual value
    add     x21, x24, x1        // Update position
    
    // Skip whitespace before comma
skip_assert_ws2:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    assert_parse_error
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_assert_char2
    cmp     w1, #'\t'
    b.eq    skip_assert_char2
    b       check_assert_comma
skip_assert_char2:
    add     x21, x21, #1
    b       skip_assert_ws2

check_assert_comma:
    // Check for comma ','
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #','
    b.ne    assert_parse_error
    add     x21, x21, #1        // Skip ','
    
    // Skip whitespace after comma
skip_assert_ws_after_comma:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    assert_parse_error
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_assert_char_after_comma
    cmp     w1, #'\t'
    b.eq    skip_assert_char_after_comma
    b       parse_assert_expected
skip_assert_char_after_comma:
    add     x21, x21, #1
    b       skip_assert_ws_after_comma
    
parse_assert_expected:
    // Parse the expected value (expression)
    add     x0, x19, x21        // buffer at expression
    sub     x1, x20, x21        // remaining length
    
    // Save position before calling evaluate_expression
    mov     x24, x21
    
    // Call evaluate_expression
    bl      evaluate_expression
    
    // x0 = result value, x1 = bytes consumed
    mov     x23, x0             // Save expected value
    add     x21, x24, x1        // Update position
    
    // Skip whitespace before closing parenthesis
skip_assert_ws_before_close:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    assert_parse_error
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_assert_char_before_close
    cmp     w1, #'\t'
    b.eq    skip_assert_char_before_close
    b       check_assert_close_paren
skip_assert_char_before_close:
    add     x21, x21, #1
    b       skip_assert_ws_before_close

check_assert_close_paren:
    // Check for closing parenthesis ')'
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #')'
    b.ne    assert_parse_error
    add     x21, x21, #1        // Skip ')'
    
    // Compare actual and expected
    cmp     x22, x23
    b.ne    assertion_failed
    
    // Assertion passed - return bytes consumed
    mov     x0, x21
    ldp     x25, x26, [sp, #64]
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #80
    ret

assertion_failed:
    // Print error message: "Assertion failed: expected "
    mov     x0, #STDERR
    adrp    x1, assert_fail_msg1@PAGE
    add     x1, x1, assert_fail_msg1@PAGEOFF
    mov     x2, #assert_fail_msg1_len
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Convert expected value to string and print
    mov     x0, x23             // expected value
    adrp    x1, assert_number_buf1@PAGE
    add     x1, x1, assert_number_buf1@PAGEOFF
    bl      number_to_string
    
    // Print expected number
    mov     x25, x0             // Save length
    mov     x0, #STDERR
    adrp    x1, assert_number_buf1@PAGE
    add     x1, x1, assert_number_buf1@PAGEOFF
    mov     x2, x25
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Print ", got "
    mov     x0, #STDERR
    adrp    x1, assert_fail_msg2@PAGE
    add     x1, x1, assert_fail_msg2@PAGEOFF
    mov     x2, #assert_fail_msg2_len
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Convert actual value to string and print
    mov     x0, x22             // actual value
    adrp    x1, assert_number_buf2@PAGE
    add     x1, x1, assert_number_buf2@PAGEOFF
    bl      number_to_string
    
    // Print actual number
    mov     x25, x0             // Save length
    mov     x0, #STDERR
    adrp    x1, assert_number_buf2@PAGE
    add     x1, x1, assert_number_buf2@PAGEOFF
    mov     x2, x25
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Print newline
    mov     x0, #STDERR
    adrp    x1, newline_assert@PAGE
    add     x1, x1, newline_assert@PAGEOFF
    mov     x2, #1
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Exit with error code 1
    mov     x0, #1
    mov     x16, #SYS_EXIT
    svc     #0x80
    
assert_parse_error:
    // For now, just return 0 bytes consumed
    mov     x0, #0
    ldp     x25, x26, [sp, #64]
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #80
    ret

// Convert number to string
// x0 = number, x1 = buffer pointer
// Returns: length in x0
number_to_string:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    
    mov     x19, x1             // Save buffer pointer
    mov     x20, x0             // Number to convert
    
    // Handle zero specially
    cmp     x20, #0
    b.ne    convert_nonzero_assert
    
    mov     w0, #'0'
    strb    w0, [x19]
    mov     x0, #1
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
    
convert_nonzero_assert:
    // Handle negative numbers
    mov     x21, #0             // Length counter
    cmp     x20, #0
    b.ge    convert_positive_assert
    
    // Negative number - add minus sign
    mov     w0, #'-'
    strb    w0, [x19]
    add     x19, x19, #1
    add     x21, x21, #1
    neg     x20, x20            // Make positive
    
convert_positive_assert:
    // Count digits
    mov     x22, x20            // Copy number
    mov     x2, #0              // Digit count
count_digits_assert:
    cmp     x22, #0
    b.eq    convert_digits_assert
    mov     x3, #10
    udiv    x22, x22, x3
    add     x2, x2, #1
    b       count_digits_assert
    
convert_digits_assert:
    // x2 = number of digits
    add     x21, x21, x2        // Total length
    add     x19, x19, x2        // Move to end of buffer
    
    // Convert digits from right to left
convert_loop_assert:
    cmp     x2, #0
    b.eq    convert_done_assert
    
    mov     x3, #10
    udiv    x4, x20, x3         // x4 = number / 10
    msub    x5, x4, x3, x20     // x5 = number % 10
    
    add     w5, w5, #'0'        // Convert to ASCII
    sub     x19, x19, #1
    strb    w5, [x19]
    
    mov     x20, x4             // number = number / 10
    sub     x2, x2, #1
    b       convert_loop_assert
    
convert_done_assert:
    mov     x0, x21             // Return length
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

// Handle assert_ne (not equal) statement
// x0 = buffer pointer (at "assert_ne"), x1 = remaining length
// Returns: bytes consumed in x0, or exits if assertion fails (values are equal)
handle_assert_ne:
    stp     x29, x30, [sp, #-80]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]
    stp     x25, x26, [sp, #64]
    
    mov     x19, x0             // Save buffer pointer
    mov     x20, x1             // Save remaining length
    
    // Skip past "assert_ne" keyword (9 bytes)
    mov     x21, #9
    
    // Skip whitespace
skip_assert_ne_ws1:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    assert_ne_parse_error
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_assert_ne_char1
    cmp     w1, #'\t'
    b.eq    skip_assert_ne_char1
    b       check_assert_ne_open_paren
skip_assert_ne_char1:
    add     x21, x21, #1
    b       skip_assert_ne_ws1

check_assert_ne_open_paren:
    // Check for opening parenthesis '('
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #'('
    b.ne    assert_ne_parse_error
    add     x21, x21, #1        // Skip '('
    
    // Skip whitespace after '('
skip_assert_ne_ws_after_paren:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    assert_ne_parse_error
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_assert_ne_char_after_paren
    cmp     w1, #'\t'
    b.eq    skip_assert_ne_char_after_paren
    b       parse_assert_ne_actual
skip_assert_ne_char_after_paren:
    add     x21, x21, #1
    b       skip_assert_ne_ws_after_paren
    
parse_assert_ne_actual:
    // Parse the actual value (expression)
    add     x0, x19, x21        // buffer at expression
    sub     x1, x20, x21        // remaining length
    
    // Save position before calling evaluate_expression
    mov     x24, x21
    
    // Call evaluate_expression
    bl      evaluate_expression
    
    // x0 = result value, x1 = bytes consumed
    mov     x22, x0             // Save actual value
    add     x21, x24, x1        // Update position
    
    // Skip whitespace before comma
skip_assert_ne_ws2:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    assert_ne_parse_error
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_assert_ne_char2
    cmp     w1, #'\t'
    b.eq    skip_assert_ne_char2
    b       check_assert_ne_comma
skip_assert_ne_char2:
    add     x21, x21, #1
    b       skip_assert_ne_ws2

check_assert_ne_comma:
    // Check for comma ','
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #','
    b.ne    assert_ne_parse_error
    add     x21, x21, #1        // Skip ','
    
    // Skip whitespace after comma
skip_assert_ne_ws_after_comma:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    assert_ne_parse_error
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_assert_ne_char_after_comma
    cmp     w1, #'\t'
    b.eq    skip_assert_ne_char_after_comma
    b       parse_assert_ne_expected
skip_assert_ne_char_after_comma:
    add     x21, x21, #1
    b       skip_assert_ne_ws_after_comma
    
parse_assert_ne_expected:
    // Parse the not-expected value (expression)
    add     x0, x19, x21        // buffer at expression
    sub     x1, x20, x21        // remaining length
    
    // Save position before calling evaluate_expression
    mov     x24, x21
    
    // Call evaluate_expression
    bl      evaluate_expression
    
    // x0 = result value, x1 = bytes consumed
    mov     x23, x0             // Save not-expected value
    add     x21, x24, x1        // Update position
    
    // Skip whitespace before closing parenthesis
skip_assert_ne_ws_before_close:
    sub     x0, x20, x21
    cmp     x0, #0
    b.le    assert_ne_parse_error
    
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_assert_ne_char_before_close
    cmp     w1, #'\t'
    b.eq    skip_assert_ne_char_before_close
    b       check_assert_ne_close_paren
skip_assert_ne_char_before_close:
    add     x21, x21, #1
    b       skip_assert_ne_ws_before_close

check_assert_ne_close_paren:
    // Check for closing parenthesis ')'
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #')'
    b.ne    assert_ne_parse_error
    add     x21, x21, #1        // Skip ')'
    
    // Compare actual and not-expected (should be different)
    cmp     x22, x23
    b.eq    assertion_ne_failed
    
    // Assertion passed (values are different) - return bytes consumed
    mov     x0, x21
    ldp     x25, x26, [sp, #64]
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #80
    ret

assertion_ne_failed:
    // Print error message: "Assertion failed: expected NOT "
    mov     x0, #STDERR
    adrp    x1, assert_ne_fail_msg1@PAGE
    add     x1, x1, assert_ne_fail_msg1@PAGEOFF
    mov     x2, #assert_ne_fail_msg1_len
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Convert not-expected value to string and print
    mov     x0, x23             // not-expected value
    adrp    x1, assert_number_buf1@PAGE
    add     x1, x1, assert_number_buf1@PAGEOFF
    bl      number_to_string
    
    // Print not-expected number
    mov     x25, x0             // Save length
    mov     x0, #STDERR
    adrp    x1, assert_number_buf1@PAGE
    add     x1, x1, assert_number_buf1@PAGEOFF
    mov     x2, x25
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Print ", but got "
    mov     x0, #STDERR
    adrp    x1, assert_ne_fail_msg2@PAGE
    add     x1, x1, assert_ne_fail_msg2@PAGEOFF
    mov     x2, #assert_ne_fail_msg2_len
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Convert actual value to string and print
    mov     x0, x22             // actual value
    adrp    x1, assert_number_buf2@PAGE
    add     x1, x1, assert_number_buf2@PAGEOFF
    bl      number_to_string
    
    // Print actual number
    mov     x25, x0             // Save length
    mov     x0, #STDERR
    adrp    x1, assert_number_buf2@PAGE
    add     x1, x1, assert_number_buf2@PAGEOFF
    mov     x2, x25
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Print newline
    mov     x0, #STDERR
    adrp    x1, newline_assert@PAGE
    add     x1, x1, newline_assert@PAGEOFF
    mov     x2, #1
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Exit with error code 1
    mov     x0, #1
    mov     x16, #SYS_EXIT
    svc     #0x80
    
assert_ne_parse_error:
    // For now, just return 0 bytes consumed
    mov     x0, #0
    ldp     x25, x26, [sp, #64]
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #80
    ret

