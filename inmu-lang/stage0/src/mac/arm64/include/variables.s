// variables.s - Variable management for INMU interpreter
// ARM64 Assembly for macOS (Apple Silicon)

.global init_variables
.global set_variable
.global get_variable
.global parse_let_statement
.global parse_expression
.global evaluate_expression
.global parse_number_simple

// Constants
.equ MAX_VARIABLES, 256
.equ VAR_NAME_SIZE, 32
.equ VAR_VALUE_SIZE, 8

.data
debug_set_var:      .asciz "Setting variable: "
debug_get_var:      .asciz "Getting variable: "
debug_value:        .asciz " = "
debug_newline:      .asciz "\n"

.bss
.align 3
// Variable storage: array of structs
// Each entry: [32 bytes name][8 bytes value][8 bytes type]
variable_table:     .skip 12288        // 256 * 48 bytes
variable_count:     .skip 8            // Number of variables

.text

// Initialize variable system
init_variables:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Set variable count to 0
    adrp    x0, variable_count@PAGE
    add     x0, x0, variable_count@PAGEOFF
    mov     x1, #0
    str     x1, [x0]
    
    ldp     x29, x30, [sp], #16
    ret

// Set variable value
// x0 = variable name (null-terminated string)
// x1 = value
// Returns: 0 on success, -1 on error
set_variable:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    
    mov     x19, x0             // Save name pointer
    mov     x20, x1             // Save value
    
    // First, try to find if variable already exists
    mov     x0, x19
    bl      find_variable
    cmp     x0, #0
    b.ge    update_existing
    
    // Variable doesn't exist, create new one
    adrp    x0, variable_count@PAGE
    add     x0, x0, variable_count@PAGEOFF
    ldr     x21, [x0]           // Load current count
    
    // Check if we have space
    cmp     x21, #MAX_VARIABLES
    b.ge    set_var_error
    
    // Calculate offset: index * 48
    mov     x22, #48
    mul     x22, x21, x22
    
    adrp    x0, variable_table@PAGE
    add     x0, x0, variable_table@PAGEOFF
    add     x0, x0, x22         // Entry address
    
    // Copy name (max 31 chars + null)
    mov     x2, x0              // Destination
    mov     x3, x19             // Source (name)
    mov     x4, #0              // Counter
copy_name_loop:
    cmp     x4, #31
    b.ge    copy_name_done
    ldrb    w5, [x3, x4]
    strb    w5, [x2, x4]
    cmp     w5, #0              // Check for null terminator
    b.eq    copy_name_done
    add     x4, x4, #1
    b       copy_name_loop

copy_name_done:
    // Null-terminate
    strb    wzr, [x2, x4]
    
    // Store value at offset 32
    add     x0, x0, #32
    str     x20, [x0]
    
    // Increment variable count
    add     x21, x21, #1
    adrp    x0, variable_count@PAGE
    add     x0, x0, variable_count@PAGEOFF
    str     x21, [x0]
    
    mov     x0, #0              // Success
    b       set_var_done

update_existing:
    // x0 contains the index
    mov     x21, #48
    mul     x22, x0, x21
    
    adrp    x0, variable_table@PAGE
    add     x0, x0, variable_table@PAGEOFF
    add     x0, x0, x22
    add     x0, x0, #32         // Value offset
    str     x20, [x0]
    
    mov     x0, #0              // Success
    b       set_var_done

set_var_error:
    mov     x0, #-1             // Error

set_var_done:
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// Get variable value
// x0 = variable name (null-terminated string)
// Returns: value in x0, or 0 if not found
get_variable:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    
    mov     x19, x0             // Save name pointer
    
    bl      find_variable
    cmp     x0, #0
    b.lt    get_var_notfound
    
    // x0 contains the index
    mov     x20, #48
    mul     x1, x0, x20
    
    adrp    x0, variable_table@PAGE
    add     x0, x0, variable_table@PAGEOFF
    add     x0, x0, x1
    add     x0, x0, #32         // Value offset
    ldr     x0, [x0]            // Load value
    
    b       get_var_done

get_var_notfound:
    mov     x0, #0              // Return 0 if not found

get_var_done:
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// Find variable by name
// x0 = variable name
// Returns: index in x0, or -1 if not found
find_variable:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    
    mov     x19, x0             // Save name pointer
    
    adrp    x0, variable_count@PAGE
    add     x0, x0, variable_count@PAGEOFF
    ldr     x20, [x0]           // Load count
    
    mov     x21, #0             // Index counter

find_var_loop:
    cmp     x21, x20
    b.ge    find_var_notfound
    
    // Calculate entry address
    mov     x22, #48
    mul     x1, x21, x22
    adrp    x0, variable_table@PAGE
    add     x0, x0, variable_table@PAGEOFF
    add     x0, x0, x1
    
    // Compare names
    mov     x2, x19             // Search name
    bl      strcmp_simple
    cmp     x0, #0
    b.eq    find_var_found
    
    add     x21, x21, #1
    b       find_var_loop

find_var_found:
    mov     x0, x21             // Return index
    b       find_var_done

find_var_notfound:
    mov     x0, #-1             // Not found

find_var_done:
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// Simple string comparison
// x0 = string1, x2 = string2
// Returns: 0 if equal, 1 if different
strcmp_simple:
    mov     x3, #0              // Counter
strcmp_loop:
    ldrb    w4, [x0, x3]
    ldrb    w5, [x2, x3]
    cmp     w4, w5
    b.ne    strcmp_diff
    cmp     w4, #0              // Check for null
    b.eq    strcmp_equal
    add     x3, x3, #1
    b       strcmp_loop

strcmp_equal:
    mov     x0, #0
    ret

strcmp_diff:
    mov     x0, #1
    ret

// Parse let statement
// x0 = buffer pointer (at "let"), x1 = remaining length
// Returns: bytes consumed in x0
parse_let_statement:
    stp     x29, x30, [sp, #-64]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]
    
    mov     x19, x0             // Save buffer pointer
    mov     x20, x1             // Save length
    
    // Skip "let" keyword (3 chars)
    mov     x21, #3
    
    // Skip whitespace
    add     x0, x19, x21
    bl      skip_whitespace_simple
    sub     x21, x0, x19        // Update position
    
    // Extract variable name
    sub     sp, sp, #64         // Space for name buffer
    mov     x22, sp
    
    mov     x0, #0              // Name length counter
extract_name_loop:
    add     x1, x19, x21
    ldrb    w2, [x1]
    
    // Check if alphanumeric or underscore
    cmp     w2, #'_'
    b.eq    valid_name_char
    cmp     w2, #'a'
    b.lt    check_upper
    cmp     w2, #'z'
    b.le    valid_name_char
    
check_upper:
    cmp     w2, #'A'
    b.lt    check_digit
    cmp     w2, #'Z'
    b.le    valid_name_char
    
check_digit:
    cmp     w2, #'0'
    b.lt    name_done
    cmp     w2, #'9'
    b.gt    name_done
    
valid_name_char:
    strb    w2, [x22, x0]
    add     x0, x0, #1
    add     x21, x21, #1
    cmp     x0, #31             // Max name length
    b.lt    extract_name_loop

name_done:
    // Null-terminate name
    strb    wzr, [x22, x0]
    
    // Check if we got a name (length > 0)
    cmp     x0, #0
    b.eq    let_error
    
    add     x0, x19, x21
    bl      skip_whitespace_simple
    sub     x21, x0, x19
    
    // Check for '='
    add     x0, x19, x21
    ldrb    w1, [x0]
    cmp     w1, #'='
    b.ne    let_error
    add     x21, x21, #1
    
    // Skip whitespace after '='
    add     x0, x19, x21
    bl      skip_whitespace_simple
    sub     x21, x0, x19
    
    // Parse expression (for now, just handle numbers)
    add     x0, x19, x21
    bl      parse_number_simple
    mov     x23, x0             // Save value
    mov     x24, x1             // Save consumed bytes
    
    // Set the variable
    mov     x0, x22             // Variable name
    mov     x1, x23             // Value
    bl      set_variable
    
    // Calculate total bytes consumed
    add     x21, x21, x24       // Add number bytes
    
    add     sp, sp, #64         // Clean up name buffer
    mov     x0, x21             // Return bytes consumed
    b       let_done

let_error:
    add     sp, sp, #64
    mov     x0, #0              // Return 0 bytes consumed on error

let_done:
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #64
    ret

// Skip whitespace (simple version)
// x0 = buffer pointer
// Returns: new pointer in x0
skip_whitespace_simple:
skip_ws_loop:
    ldrb    w1, [x0]
    cmp     w1, #' '
    b.eq    skip_ws_char
    cmp     w1, #'\t'
    b.eq    skip_ws_char
    cmp     w1, #'\n'
    b.eq    skip_ws_char
    cmp     w1, #'\r'
    b.eq    skip_ws_char
    ret

skip_ws_char:
    add     x0, x0, #1
    b       skip_ws_loop

// Parse number from buffer
// x0 = buffer pointer
// Returns: number in x0, bytes consumed in x1
parse_number_simple:
    mov     x2, #0              // Result
    mov     x1, #0              // Bytes consumed
parse_num_loop:
    ldrb    w3, [x0, x1]
    cmp     w3, #'0'
    b.lt    parse_num_done
    cmp     w3, #'9'
    b.gt    parse_num_done
    
    // result = result * 10 + (digit - '0')
    mov     x4, #10
    mul     x2, x2, x4
    sub     w3, w3, #'0'
    add     x2, x2, x3
    
    add     x1, x1, #1
    b       parse_num_loop

parse_num_done:
    mov     x0, x2              // Return value in x0
    // x1 already contains bytes consumed
    ret
