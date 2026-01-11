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
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    subq    $64, %rsp           // Allocate 64 bytes for variable name buffer
    
    // %r12 = buffer pointer (preserved)
    // %r13 = buffer length (preserved)
    // %r14 = current position
    // %r15 = saved original position for return value
    
    movq    %r15, %rbx          // Save original position
    
    // Skip "let" keyword (3 bytes)
    leaq    3(%r15), %r14
    
    // Skip whitespace after "let"
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_var
    movq    %rax, %r14
    
    // Check bounds
    cmpq    %r13, %r14
    jge     let_parse_error
    
    // Extract variable name to stack buffer
    leaq    -64(%rbp), %r15     // r15 = name buffer on stack
    xorq    %rcx, %rcx          // rcx = name length counter
    
extract_var_name_let:
    cmpq    %r13, %r14
    jge     var_name_extracted
    cmpq    $31, %rcx           // Max name length
    jge     var_name_extracted
    
    movzbl  (%r12,%r14), %eax
    
    // Check if alphanumeric or underscore
    cmpb    $'_', %al
    je      valid_var_char_let
    cmpb    $'a', %al
    jl      check_upper_let
    cmpb    $'z', %al
    jle     valid_var_char_let
    
check_upper_let:
    cmpb    $'A', %al
    jl      check_digit_let
    cmpb    $'Z', %al
    jle     valid_var_char_let
    
check_digit_let:
    cmpb    $'0', %al
    jl      var_name_extracted
    cmpb    $'9', %al
    jg      var_name_extracted
    
valid_var_char_let:
    movb    %al, (%r15,%rcx)
    incq    %rcx
    incq    %r14
    jmp     extract_var_name_let
    
var_name_extracted:
    // Null-terminate
    movb    $0, (%r15,%rcx)
    
    // Check if we got a name
    cmpq    $0, %rcx
    je      let_parse_error
    
    // Skip whitespace before '='
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_var
    movq    %rax, %r14
    
    // Check for '='
    cmpq    %r13, %r14
    jge     let_parse_error
    movzbl  (%r12,%r14), %eax
    cmpb    $'=', %al
    jne     let_parse_error
    incq    %r14
    
    // Skip whitespace after '='
    movq    %r12, %rdi
    movq    %r13, %rsi
    movq    %r14, %rdx
    call    skip_whitespace_var
    movq    %rax, %r14
    
    // Parse expression
    leaq    (%r12,%r14), %rdi
    movq    %r13, %rsi
    subq    %r14, %rsi
    call    parse_expression_advanced
    
    // rax = value, rdx = bytes consumed
    pushq   %rax                // Save value
    addq    %rdx, %r14          // Update position
    
    // Set variable: name pointer in r15, value in stack
    movq    %r15, %rdi          // name pointer (null-terminated)
    popq    %rsi                // value (in rsi, not rdx)
    call    set_variable
    
    // Calculate bytes consumed
    movq    %r14, %rax
    subq    %rbx, %rax
    
    addq    $64, %rsp           // Clean up name buffer
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret
    
let_parse_error:
    xorq    %rax, %rax          // Return 0 bytes consumed
    addq    $64, %rsp
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
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
// %rdi = name pointer (null-terminated string)
// %rsi = value
set_variable:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    
    movq    %rdi, %r12          // name pointer
    movq    %rsi, %r14          // value
    
    // Get name length
    xorq    %r13, %r13
get_name_len:
    movzbl  (%r12,%r13), %eax
    cmpb    $0, %al
    je      name_len_done
    incq    %r13
    jmp     get_name_len
name_len_done:
    
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
    
    // Calculate storage offset: variable_count * 40
    movq    variable_count(%rip), %rax
    movq    $40, %rcx
    mulq    %rcx                // Result in rax
    leaq    variable_storage(%rip), %rdi
    addq    %rax, %rdi          // %rdi = dest (storage location)
    
    // Copy name byte by byte (max 31 chars + null)
    xorq    %rcx, %rcx          // Counter
copy_name_byte_loop:
    cmpq    $31, %rcx
    jge     copy_name_byte_done
    movzbl  (%r12,%rcx), %eax
    movb    %al, (%rdi,%rcx)
    cmpb    $0, %al             // Check for null terminator
    je      copy_name_byte_done
    incq    %rcx
    jmp     copy_name_byte_loop
    
copy_name_byte_done:
    // Null-terminate
    movb    $0, (%rdi,%rcx)
    
    // Store value at offset 32
    movq    %r14, 32(%rdi)
    
    // Increment count
    incq    variable_count(%rip)
    jmp     set_var_done
    
update_var:
    // Update existing variable at index r15
    movq    %r15, %rax
    movq    $40, %rcx
    mulq    %rcx                // offset = index * 40
    leaq    variable_storage(%rip), %rdi
    addq    %rax, %rdi
    movq    %r14, 32(%rdi)      // Store value at offset 32
    jmp     set_var_done
    
set_var_done:
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

// Compare variable name
// %rdi = name1 (null-terminated), %rsi = storage slot
// Returns: %rax = 1 if match, 0 if not
compare_var_name:
    pushq   %rbp
    movq    %rsp, %rbp
    
    xorq    %rcx, %rcx
    
compare_var_loop:
    movzbl  (%rdi,%rcx), %eax
    movzbl  (%rsi,%rcx), %r8d
    
    // Check for null terminator in name1
    cmpb    $0, %al
    je      compare_var_check_end
    
    cmpb    %r8b, %al
    jne     compare_var_no_match
    
    incq    %rcx
    jmp     compare_var_loop
    
compare_var_check_end:
    // Both should end here
    cmpb    $0, %r8b
    jne     compare_var_no_match
    movq    $1, %rax
    popq    %rbp
    ret
    
compare_var_no_match:
    xorq    %rax, %rax
    popq    %rbp
    ret

// Get variable value
// %rdi = name pointer (null-terminated string)
// Returns: %rax = value (0 if not found)
get_variable:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    
    movq    %rdi, %r12
    
    // Get name length
    xorq    %r13, %r13
get_var_name_len:
    movzbl  (%r12,%r13), %eax
    cmpb    $0, %al
    je      get_var_name_len_done
    incq    %r13
    jmp     get_var_name_len
get_var_name_len_done:
    
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
    movq    (%rdi), %rax        // Return value
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret
    
get_var_not_found:
    xorq    %rax, %rax          // Return 0
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

// Debug helper: print string
print_string_debug:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    
    movq    %rdi, %r12
    xorq    %rbx, %rbx
psd_len_loop:
    movzbl  (%r12,%rbx), %eax
    cmpb    $0, %al
    je      psd_len_done
    incq    %rbx
    jmp     psd_len_loop
psd_len_done:
    movq    $0x2000004, %rax    // SYS_WRITE
    movq    $1, %rdi            // STDOUT
    movq    %r12, %rsi
    movq    %rbx, %rdx
    syscall
    
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

// Debug helper: print number
print_number_debug:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $32, %rsp
    pushq   %rbx
    pushq   %r12
    
    movq    %rdi, %rax
    leaq    -32(%rbp), %r12
    addq    $20, %r12
    movb    $0, (%r12)
    
pnd_loop:
    xorq    %rdx, %rdx
    movq    $10, %rcx
    divq    %rcx
    addb    $'0', %dl
    decq    %r12
    movb    %dl, (%r12)
    cmpq    $0, %rax
    jne     pnd_loop
    
    movq    %r12, %rdi
    call    print_string_debug
    
    popq    %r12
    popq    %rbx
    addq    $32, %rsp
    popq    %rbp
    ret
