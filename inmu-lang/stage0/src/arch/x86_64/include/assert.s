// assert.s - Assert statement handling for INMU language
// x86_64 Assembly for macOS (Intel)

.global _handle_assert
.global _handle_assert_ne

// External symbols
.equ STDOUT, 1
.equ STDERR, 2
.equ SYS_WRITE, 0x2000004
.equ SYS_EXIT, 0x2000001

.data
assert_fail_msg1: .asciz "Assertion failed: expected "
.set assert_fail_msg1_len, . - assert_fail_msg1 - 1

assert_fail_msg2: .asciz ", got "
.set assert_fail_msg2_len, . - assert_fail_msg2 - 1

assert_ne_fail_msg1: .asciz "Assertion failed: expected NOT "
.set assert_ne_fail_msg1_len, . - assert_ne_fail_msg1 - 1

assert_ne_fail_msg2: .asciz ", but got "
.set assert_ne_fail_msg2_len, . - assert_ne_fail_msg2 - 1

newline_assert: .asciz "\n"

.bss
assert_error_buffer: .skip 128
assert_number_buf1: .skip 32
assert_number_buf2: .skip 32

.text

// Handle assert statement
// %r12 = buffer base, %r13 = buffer length, %r15 = position of "assert"
// Returns: %rax = bytes consumed, or exits if assertion fails
_handle_assert:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r14
    
    // Skip "assert" keyword (6 bytes)
    leaq    6(%r15), %r14
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_assert
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     assert_parse_error
    
    // Check for opening parenthesis '('
    leaq    (%r12,%r14), %rax
    movzbl  (%rax), %eax
    cmpb    $'(', %al
    jne     assert_parse_error
    incq    %r14                // Skip '('
    
    // Skip whitespace after '('
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_assert
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     assert_parse_error
    
    // Parse actual value (expression)
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_expression_advanced
    
    // %rax = result value, %rdx = bytes consumed
    pushq   %rax                // Save actual value
    addq    %rdx, %r14          // Update position
    
    // Skip whitespace before comma
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_assert
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     assert_parse_error_pop
    
    // Check for comma ','
    leaq    (%r12,%r14), %rax
    movzbl  (%rax), %eax
    cmpb    $',', %al
    jne     assert_parse_error_pop
    incq    %r14                // Skip ','
    
    // Skip whitespace after comma
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_assert
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     assert_parse_error_pop
    
    // Parse expected value (expression)
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_expression_advanced
    
    // %rax = result value, %rdx = bytes consumed
    movq    %rax, %rbx          // Save expected value in rbx
    addq    %rdx, %r14          // Update position
    
    // Skip whitespace before closing parenthesis
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_assert
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     assert_parse_error_pop
    
    // Check for closing parenthesis ')'
    leaq    (%r12,%r14), %rax
    movzbl  (%rax), %eax
    cmpb    $')', %al
    jne     assert_parse_error_pop
    incq    %r14                // Skip ')'
    
    // Compare actual and expected
    popq    %rax                // Restore actual value
    cmpq    %rbx, %rax
    jne     assertion_failed
    
    // Assertion passed - return bytes consumed
    movq    %r14, %rax
    subq    %r15, %rax
    popq    %r14
    popq    %rbx
    popq    %rbp
    ret

assertion_failed:
    // Save actual and expected values
    pushq   %rax                // actual
    pushq   %rbx                // expected
    
    // Print error message: "Assertion failed: expected "
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    assert_fail_msg1(%rip), %rsi
    movq    $assert_fail_msg1_len, %rdx
    syscall
    
    // Convert expected value to string and print
    popq    %rdi                // expected value
    pushq   %rdi                // keep on stack
    leaq    assert_number_buf1(%rip), %rsi
    call    number_to_string_x86
    
    // Print expected number
    movq    %rax, %rdx          // length
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    assert_number_buf1(%rip), %rsi
    syscall
    
    // Print ", got "
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    assert_fail_msg2(%rip), %rsi
    movq    $assert_fail_msg2_len, %rdx
    syscall
    
    // Convert actual value to string and print
    popq    %rbx                // discard expected
    popq    %rdi                // actual value
    leaq    assert_number_buf2(%rip), %rsi
    call    number_to_string_x86
    
    // Print actual number
    movq    %rax, %rdx          // length
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    assert_number_buf2(%rip), %rsi
    syscall
    
    // Print newline
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    newline_assert(%rip), %rsi
    movq    $1, %rdx
    syscall
    
    // Exit with error code 1
    movq    $SYS_EXIT, %rax
    movq    $1, %rdi
    syscall

assert_parse_error_pop:
    popq    %rax                // Clean stack
assert_parse_error:
    // For now, just return 0 bytes consumed
    xorq    %rax, %rax
    popq    %r14
    popq    %rbx
    popq    %rbp
    ret

// Skip whitespace helper
// %rdi = buffer base, %rsi = buffer length, %rdx = current position
// Returns: new position in %rax
skip_whitespace_assert:
    movq    %rdx, %rax
skip_ws_assert_loop:
    cmpq    %rsi, %rax
    jge     skip_ws_assert_done
    
    leaq    (%rdi,%rax), %rcx
    movzbl  (%rcx), %ecx
    
    cmpb    $' ', %cl
    je      skip_ws_assert_char
    cmpb    $'\t', %cl
    je      skip_ws_assert_char
    jmp     skip_ws_assert_done
    
skip_ws_assert_char:
    incq    %rax
    jmp     skip_ws_assert_loop
    
skip_ws_assert_done:
    ret

// Convert number to string
// %rdi = number, %rsi = buffer pointer
// Returns: length in %rax
number_to_string_x86:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    
    movq    %rsi, %r12          // Save buffer pointer
    movq    %rdi, %r13          // Number to convert
    
    // Handle zero specially
    testq   %r13, %r13
    jnz     convert_nonzero_x86
    
    movb    $'0', (%r12)
    movq    $1, %rax
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret
    
convert_nonzero_x86:
    // Handle negative numbers
    xorq    %rbx, %rbx          // Length counter
    testq   %r13, %r13
    jns     convert_positive_x86
    
    // Negative number - add minus sign
    movb    $'-', (%r12)
    incq    %r12
    incq    %rbx
    negq    %r13                // Make positive
    
convert_positive_x86:
    // Count digits
    movq    %r13, %rax          // Copy number
    xorq    %rcx, %rcx          // Digit count
count_digits_x86:
    testq   %rax, %rax
    jz      convert_digits_x86
    
    xorq    %rdx, %rdx
    movq    $10, %r8
    divq    %r8
    incq    %rcx
    jmp     count_digits_x86
    
convert_digits_x86:
    // rcx = number of digits
    addq    %rcx, %rbx          // Total length
    addq    %rcx, %r12          // Move to end of buffer
    
    // Convert digits from right to left
convert_loop_x86:
    testq   %rcx, %rcx
    jz      convert_done_x86
    
    movq    %r13, %rax
    xorq    %rdx, %rdx
    movq    $10, %r8
    divq    %r8
    
    addb    $'0', %dl           // Convert remainder to ASCII
    decq    %r12
    movb    %dl, (%r12)
    
    movq    %rax, %r13          // number = number / 10
    decq    %rcx
    jmp     convert_loop_x86
    
convert_done_x86:
    movq    %rbx, %rax          // Return length
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

// Handle assert_ne (not equal) statement
// %r12 = buffer base, %r13 = buffer length, %r15 = position of "assert_ne"
// Returns: %rax = bytes consumed, or exits if assertion fails (values are equal)
_handle_assert_ne:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r14
    
    // Skip "assert_ne" keyword (9 bytes)
    leaq    9(%r15), %r14
    
    // Skip whitespace
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_assert
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     assert_ne_parse_error
    
    // Check for opening parenthesis '('
    leaq    (%r12,%r14), %rax
    movzbl  (%rax), %eax
    cmpb    $'(', %al
    jne     assert_ne_parse_error
    incq    %r14                // Skip '('
    
    // Skip whitespace after '('
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_assert
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     assert_ne_parse_error
    
    // Parse actual value (expression)
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_expression_advanced
    
    // %rax = result value, %rdx = bytes consumed
    pushq   %rax                // Save actual value
    addq    %rdx, %r14          // Update position
    
    // Skip whitespace before comma
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_assert
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     assert_ne_parse_error_pop
    
    // Check for comma ','
    leaq    (%r12,%r14), %rax
    movzbl  (%rax), %eax
    cmpb    $',', %al
    jne     assert_ne_parse_error_pop
    incq    %r14                // Skip ','
    
    // Skip whitespace after comma
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_assert
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     assert_ne_parse_error_pop
    
    // Parse not-expected value (expression)
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_expression_advanced
    
    // %rax = result value, %rdx = bytes consumed
    movq    %rax, %rbx          // Save not-expected value in rbx
    addq    %rdx, %r14          // Update position
    
    // Skip whitespace before closing parenthesis
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_assert
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     assert_ne_parse_error_pop
    
    // Check for closing parenthesis ')'
    leaq    (%r12,%r14), %rax
    movzbl  (%rax), %eax
    cmpb    $')', %al
    jne     assert_ne_parse_error_pop
    incq    %r14                // Skip ')'
    
    // Compare actual and not-expected (should be different)
    popq    %rax                // Restore actual value
    cmpq    %rbx, %rax
    je      assertion_ne_failed
    
    // Assertion passed (values are different) - return bytes consumed
    movq    %r14, %rax
    subq    %r15, %rax
    popq    %r14
    popq    %rbx
    popq    %rbp
    ret

assertion_ne_failed:
    // Save actual and not-expected values
    pushq   %rax                // actual
    pushq   %rbx                // not-expected
    
    // Print error message: "Assertion failed: expected NOT "
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    assert_ne_fail_msg1(%rip), %rsi
    movq    $assert_ne_fail_msg1_len, %rdx
    syscall
    
    // Convert not-expected value to string and print
    popq    %rdi                // not-expected value
    pushq   %rdi                // keep on stack
    leaq    assert_number_buf1(%rip), %rsi
    call    number_to_string_x86
    
    // Print not-expected number
    movq    %rax, %rdx          // length
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    assert_number_buf1(%rip), %rsi
    syscall
    
    // Print ", but got "
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    assert_ne_fail_msg2(%rip), %rsi
    movq    $assert_ne_fail_msg2_len, %rdx
    syscall
    
    // Convert actual value to string and print
    popq    %rbx                // discard not-expected
    popq    %rdi                // actual value
    leaq    assert_number_buf2(%rip), %rsi
    call    number_to_string_x86
    
    // Print actual number
    movq    %rax, %rdx          // length
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    assert_number_buf2(%rip), %rsi
    syscall
    
    // Print newline
    movq    $SYS_WRITE, %rax
    movq    $STDERR, %rdi
    leaq    newline_assert(%rip), %rsi
    movq    $1, %rdx
    syscall
    
    // Exit with error code 1
    movq    $SYS_EXIT, %rax
    movq    $1, %rdi
    syscall

assert_ne_parse_error_pop:
    popq    %rax                // Clean stack
assert_ne_parse_error:
    // For now, just return 0 bytes consumed
    xorq    %rax, %rax
    popq    %r14
    popq    %rbx
    popq    %rbp
    ret
