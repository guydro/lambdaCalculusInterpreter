section .text
    default rel
    extern putchar
    extern printf
    global Interpret

Interpret:
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    push rbp
    mov rbp, rsp

    mov rax, variables
    mov qword [variables_end], rax

    .find_row:
    mov rdx, rcx
        .find_row_loop:
        cmp byte [rcx], 0x00
        je .end

        cmp byte [rcx], 0x0D
        jne .file_didnt_end

        mov al, [line_number]
        inc al
        mov [line_number], al

        call Interpret_line
        call Print_line
        inc rcx
        inc rcx
        mov rdx, rcx
        jmp .file_didnt_end



        .file_didnt_end:
        inc rcx
        jmp .find_row_loop


    .end:
    mov rsp, rbp
    pop rbp

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx

    ret

Print_line:
    push rcx
    push rbp
    mov rbp, rsp

    mov rsi, [return_variable_start]
    mov rdi, [return_variable_end]
    cmp byte [rsi], 'V'
    jne .print
    inc rsi

    .print:

    mov rcx, 'V'
    call putchar
    mov rcx, 'a'
    call putchar
    mov rcx, 'r'
    call putchar
    mov rcx, 'i'
    call putchar
    mov rcx, 'a'
    call putchar
    mov rcx, 'b'
    call putchar
    mov rcx, 'l'
    call putchar
    mov rcx, 'e'
    call putchar
    mov rcx, '-'
    call putchar

    .print_loop:
    cmp rsi, rdi
    je .end

    cmp byte [rsi], 'L'
    jne .check_space
    mov rcx, 'f'
    call putchar
    mov rcx, 'u'
    call putchar
    mov rcx, 'n'
    call putchar
    mov rcx, 'c'
    call putchar
    mov rcx, 't'
    call putchar
    mov rcx, 'i'
    call putchar
    mov rcx, 'o'
    call putchar
    mov rcx, 'n'
    call putchar
    mov rcx, '-'
    call putchar
    inc rsi
    jmp .print_loop

    .check_space:
    cmp byte [rsi], 0x0
    je .print_space
    xor rcx, rcx
    mov cl, [rsi]
    call putchar
    inc rsi
    jmp .print_loop

    .print_space:
    mov rcx, ' '
    call putchar
    inc rsi
    jmp .print_loop

    .end:
    mov rcx, 0x0d
    call putchar
    mov rcx, 0x0a
    call putchar

    mov rsp, rbp
    pop rbp
    pop rcx
    ret

Interpret_line: ;Interprets line that starts at rdx and ends at rcx

    .find_function_body:
    mov rbx, rcx

    .find_function_body_loop:
    cmp byte [rbx-1], '='
    jz .exit_find_function_body_loop
    cmp rbx, rdx
    jz .exit_find_function_body_loop
    dec rbx

    jmp .find_function_body_loop

    .exit_find_function_body_loop:

    ;rcx is end of line, rbx is start of body, rdx is start of line
    ;Check if data is Variable assignment
    mov rdi, [lambda_prefix]
    cmp edi, dword [rbx] ;See if the line is variable declaration (Lam:)
    je Add_new_variable

    mov rdi, [calc_prefix]
    cmp edi, dword [rbx] ;See if the line is variable declaration (Lam:)
    je Beta_reduce_variable

    call Error


Add_new_variable: ;Adds new variable that starts in rdx, body starts in rbx, and ends in rcx
    mov rax, [variables_end]

    mov byte [rax], 'V'
    inc rax

    mov [return_variable_start], rax ;save beginning of variable

    dec rbx
    .copy_variable_name_loop:
    cmp rdx, rbx
    je .exit_copy_variable_name_loop
    mov dil, [rdx]
    mov [rax], dil
    inc rax
    inc rdx
    jmp .copy_variable_name_loop
    .exit_copy_variable_name_loop:

    mov byte [rax], 0
    inc rax

    inc rbx
    mov edi, [rbx]
    cmp edi, [calc_prefix]
    jne .copy_body
    add rbx, 0x4

    .copy_body:
    cmp rbx, rcx
    je .end
    .check_lam:
    mov edi, dword [lambda_prefix]
    cmp dword [rbx], edi
    jne .check_comma
    mov byte [rax], 'L'
    inc rax
    add rbx, 0x4
    jmp .copy_body


    .check_comma:
    cmp byte [rbx], ','
    jne .check_colon
    mov byte [rax], 0x0
    inc rax
    inc rbx
    jmp .copy_body

    .check_colon:
    cmp byte [rbx], ':'
    jne .add_letter
    mov byte [rax], 0x0
    inc rax
    inc rbx
    jmp .copy_body

    .add_letter:
    mov dil, [rbx]
    mov [rax], dil
    inc rax
    inc rbx
    jmp .copy_body

    .end:
    mov [return_variable_end], rax ;save end of variable

    inc rax
    mov [variables_end], rax
    ret

Beta_reduce_variable: ;Beta-Reduces and stores expression that starts at rdx, body starts at rbx and ends at rcx
    push rcx

    ;Copy line
    mov rdi, [variables_end]
    push rdi
    call Add_new_variable
    pop rdx
    mov rcx, [variables_end]
    dec rcx

    mov [return_variable_start], rdx ;save beginning of variable

    ;Find beginning of body
    mov rbx, rdx
    .find_body_loop:
    cmp rbx, rcx
    jne .continue_find_body
    call Error
    .continue_find_body:
    cmp byte [rbx], 0
    je .exit_find_body_loop
    inc rbx
    jmp .find_body_loop
    .exit_find_body_loop:

    call Beta_reduce_rec

    push rbp
    mov rbp, rsp
    call Check_if_reduced
    mov rsp, rbp
    pop rbp

    .end:
    mov [return_variable_end], rcx ;save end of variable
    pop rcx
    ret

Check_if_reduced:
    push rcx

    .make_rbx_true_start_loop:
    cmp byte [rbx], 0x0
    jne .exit_make_rbx_true_start_loop
    inc rbx
    jmp .make_rbx_true_start_loop
    .exit_make_rbx_true_start_loop:

    .make_rcx_true_end_loop:
    cmp byte [rcx-1], 0x0
    jne .exit_make_rcx_true_end_loop
    dec rcx
    jmp .make_rcx_true_end_loop
    .exit_make_rcx_true_end_loop:

    cmp byte [rbx], '('
    jne .end
    cmp byte [rcx-1], ')'
    jne .end

    mov r8, rbx
    lea r10, [rbx+1]

    .copy_shifted_loop:
    cmp r10, rcx
    je .exit_copy_shifted_loop
    mov r9b, [r10]
    mov [r8], r9b
    inc r8
    inc r10
    jmp .copy_shifted_loop
    .exit_copy_shifted_loop:

    pop rcx

    dec rcx
    dec rcx
    mov byte [rcx], 0x0

    call Beta_reduce_rec
    call Check_if_reduced

    ret

    .end:
    pop rcx
    ret

Beta_reduce_rec: ;Reduces body, rbx is start and rcx is end of body
    .loop:

    .clear_cc: ;quick fix for a random bug, clears 0xcc
    lea rdx, [rbx-1]
    .clear_cc_loop:
    inc rdx
    cmp rdx, rcx
    jge .exit_clear_cc_loop
    cmp byte [rdx], 0xcc
    jne .clear_cc_loop
    mov byte [rdx], 0x0
    jmp .clear_cc_loop
    .exit_clear_cc_loop:

    .move_back: ;quick fix for a not-so-random bug, clears double 0x0
    lea rdx, [rbx-1]
    .move_back_main_loop:
    inc rdx
    cmp rdx, rcx
    jge .exit_move_back
    cmp word [rdx], 0x0
    je .needs_moving
    cmp word [rdx], 0x0+(4*')')
    je .needs_moving
    jmp .move_back_main_loop
    .needs_moving:
    lea r8, [rdx]
    lea r10, [rdx-1]
    .move_back_loop:
    inc r8
    inc r10
    cmp r8, rcx
    jge .exit_move_back_loop
    mov r9b, [r8]
    mov [r10], r9b
    jmp .move_back_loop
    .exit_move_back_loop:
    dec rdx
    dec rcx
    mov byte [rcx], 0x0
    jmp .move_back_main_loop
    .exit_move_back:

    mov byte [rcx], 0x0
    inc rcx
    mov [variables_end], rcx
    dec rcx

    push rcx
    push rbx


    ;Find first two functions
    xor rax, rax
    xor rsi, rsi
    mov rdx, rbx
    cmp byte [rdx], 0x0
    jne .no_inc_rdx
    inc rdx
    .no_inc_rdx:

    inc rcx
    .find_last_two_functions_loop: ;rcx is end+1, rdx starts at beginning of body
    cmp rdx, rcx
    je .one_argument
    cmp byte [rdx], 0x0
    jne .didnt_find_argument
    cmp rsi, 0x0
    jne .didnt_find_argument
    cmp rax, 0x1
    je .exit_find_last_two_functions_loop
    inc rax
    mov rdi, rdx

    .didnt_find_argument:
    cmp byte [rdx], '('
    jne .not_open_brackets
    inc rsi
    .not_open_brackets:
    cmp byte [rdx], ')'
    jne .not_close_brackets
    dec rsi
    .not_close_brackets:

    inc rdx
    jmp .find_last_two_functions_loop
    .exit_find_last_two_functions_loop:
    mov rcx, rdx
    mov rdx, rbx

    cmp byte [rdx], 0x0
    je .substitute_functions
    cmp byte [rdx-1], 0x0
    je .continue_before_substitute
    call Error
    .continue_before_substitute:
    dec rdx

    .substitute_functions: ;rdx:rdi is first function, rdi:rcx is second function
    mov rbx, rdi
    mov r15, rcx
    mov r12, rdx ;r12 is beginning of original body, r11 is beginning of body after first 2 parameters
    cmp byte [rdx], 'L'
    je .end
    cmp byte [rdx+1], 'L'
    je .end

    .rec_apply_to_function_with_paranthesis:
    cmp byte [rdx+1], '('
    jne .applied_rec
    cmp byte [rdx+2], 'L'
    jne .dont_copy_inside
    inc rdx
    dec rbx
    lea rsi, [rdx+1]
    mov rax, [variables_end]
    push rax
    .copy_function_loop:
    cmp rsi, rbx
    je .exit_copy_function_loop
    mov r9b, [rsi]
    mov [rax], r9b
    inc rax
    inc rsi
    jmp .copy_function_loop
    .exit_copy_function_loop:
    pop rdx
    dec rdx
    lea rbx, [rax-1]
    cmp byte [rbx], ')'
    jne .inced_rbx
    inc rbx
    .inced_rbx:
    mov byte [rax], 0x0
    inc rax
    mov byte [rax], 'V'
    inc rax
    mov byte [rax], 0x0
    inc rax
    mov [variables_end], rax
    jmp .applied_rec

    .dont_copy_inside:
    inc rdx
    inc rdx
    dec rbx

    mov rax, [variables_end]
    push rax
    .copy_parameter_loop:
    cmp rbx, rdx
    je .exit_copy_parameter_loop
    mov r9b, [rdx]
    mov [rax], r9b
    inc rdx
    inc rax
    jmp .copy_parameter_loop
    .exit_copy_parameter_loop:

    mov [variables_end], rax
    pop rdx
    mov rbx, rax

    push rcx
    push rbx
    push rdx
    push rdi

    mov rcx, rbx
    mov rbx, rdx
    dec rbx
    push r11
    push r12
    push r15

    .make_rcx_true_end_loop:
    cmp byte [rcx-1], 0x0
    jne .exit_make_rcx_true_end_loop
    dec rcx
    jmp .make_rcx_true_end_loop
    .exit_make_rcx_true_end_loop:

    call Beta_reduce_rec

    mov r13, rcx
    mov r10, rbx

    pop r15
    pop r12
    pop r11

    pop rdi
    pop rdx
    pop rbx
    pop rcx

    mov rbx, r13
    mov rdx, r10

    .applied_rec: ;rdx:rbx is first argument, rdi:rcx is second argument, and exactly after OG first argument
    ;Check if function is parameter
    lea rax, [rdx+1]
    cmp byte [rax], 'L'
    je .copy_beta_reduced
    cmp byte [rax+1], 'L'
    jne .continue_checks
    mov rax, [variables_end]
    push rax
    mov r8, rdx
    .copy_function_applied_rec_loop:
    cmp r8, rbx
    je .exit_copy_function_applied_rec_loop
    mov r9b, [r8]
    mov [rax], r9b
    inc r8
    inc rax
    jmp .copy_function_applied_rec_loop
    .exit_copy_function_applied_rec_loop:
    pop rdx

    .make_rdx_function_start_loop:
    cmp byte [rdx], 'L'
    je .exit_make_rdx_function_start_loop
    inc rdx
    jmp .make_rdx_function_start_loop
    .exit_make_rdx_function_start_loop:

    mov rbx, rax
    dec rbx
    mov byte [rbx], 0x0

    mov byte [rax], 0x0
    inc rax
    mov byte [rax], 'V'
    inc rax
    mov byte [rax], 0x0
    inc rax
    mov [variables_end], rax
    jmp .copy_beta_reduced
    .continue_checks:
    ;check if function is in paranthesis
    cmp byte [rax], '('
    jne .no_opening_paranthesis
    inc rax
    .no_opening_paranthesis:

    cmp byte [rbx], ')'
    jne .no_closing_paranthesis
    dec rbx
    mov byte [rbx], 0x0
    .no_closing_paranthesis:
    ;Search for function's origin
    mov rsi, variables
    .find_origin_loop:
    cmp rsi, [variables_end]
    jne .continue_find_origin
    call Error
    .continue_find_origin:
    cmp byte [rsi], 'V'
    jne .didnt_find_origin
        lea r8, [rsi+1]
        lea r9, [rdx+1]
        .check_if_origin_loop:
        cmp r9, rbx
        je .found_origin
        mov r10b, [r8]
        cmp [r9], r10b
        jne .didnt_find_origin
        inc r8
        inc r9
        jmp .check_if_origin_loop
    .didnt_find_origin:
    inc rsi
    jmp .find_origin_loop

    .found_origin: ;rsi is beginning of origin
    mov rax, rsi
    .find_body:
    inc rax
    cmp byte [rax], 0x0
    jne .find_body
    inc rax

    mov rdx, rax

    .copy_beta_reduced:
    inc rdx ;rdx at beginning of original function's parameter, rdi at beginning of parameter, rcx at end of parameter
    cmp byte [rdx], 'L'
    jne .no_inc
    inc rdx
    .no_inc:
    mov rbx, rdx

    .find_parameter_name_loop:
    cmp byte [rdx], 0x0
    je .exit_find_parameter_name_loop
    inc rdx
    jmp .find_parameter_name_loop
    .exit_find_parameter_name_loop:

    mov rsi, rdx
    inc rdx

    ;rbx:rsi is parameter's name, rdx is beginning of function
    .copy_beta_reduced_original_function:
    mov rax, [variables_end]
    push rax
    .copy_beta_reduced_original_function_loop:
    cmp byte [rdx], 'V'
    je .exit_copy_beta_reduced_original_function_loop

    ;check if word is parameter: ;r11 is parenthesis
    xor r11, r11
    mov r8, rdx
    mov r10, rbx
    cmp byte [r8-1], 0x0
    je .check_if_parameter_loop
    cmp byte [r8-1], '('
    je .add_parenthesis_check_if_parameter_loop
    jmp .isnt_parameter

    .add_parenthesis_check_if_parameter_loop:
    ;or r11, 0b01 ;0b01 is add parenthesis
    .check_if_parameter_loop:
    cmp r10, rsi
    jne .continue_search
    cmp byte [r8], 0x0
    je .is_parameter
    cmp byte [r8], ')'
    jz .add_parenthesis_and_is_parameter
    jmp .isnt_parameter
    .continue_search:
    mov r9b, [r8]
    cmp r9b, [r10]
    jne .isnt_parameter
    inc r8
    inc r10
    jmp .check_if_parameter_loop

    .add_parenthesis_and_is_parameter:
    or r11, 0b10
    .is_parameter:
    test r11, 0b01
    jz .added_start_parenthesis
    mov byte [rax], '('
    inc rax
    .added_start_parenthesis:
    lea rdx, [r8+1]
    lea r8, [rdi+1]

    .copy_parameter_content_loop:
    cmp r8, rcx
    je .exit_copy_parameter_content_loop
    mov r9b, [r8]
    mov [rax], r9b
    inc rax
    inc r8
    jmp .copy_parameter_content_loop
    .exit_copy_parameter_content_loop:
    cmp byte [rax-1], 0x0
    jne .needs_0x0
    test r11, 0b10
    jz .no_parenthesis_no_0x0
    mov byte [rax-1], ')'
    .no_parenthesis_no_0x0:
    mov byte [rax], 0x0
    inc rax
    .needs_0x0:
    test r11, 0b10
    jz .no_parenthesis_yes_0x0
    mov byte [rax], ')'
    inc rax
    .no_parenthesis_yes_0x0:
    mov byte [rax], 0x0
    inc rax
    jmp .copy_beta_reduced_original_function_loop

    .isnt_parameter:
    mov r9b, [rdx]
    mov [rax], r9b
    inc rax
    inc rdx
    jmp .copy_beta_reduced_original_function_loop

    .exit_copy_beta_reduced_original_function_loop:
    mov byte [rax], 0x0
    inc rax
    mov byte [rax], 'V'
    inc rax
    mov byte [rax], 0x0
    inc rax
    mov [variables_end], rax

    pop rsi

    push rcx
    push rbx

    lea rcx, [rax-3]
    mov rbx, rsi
    push r11
    push r12
    push r15

    .make_rcx_true_end_loop2:
    cmp byte [rcx-1], 0x0
    jne .exit_make_rcx_true_end_loop2
    dec rcx
    jmp .make_rcx_true_end_loop2
    .exit_make_rcx_true_end_loop2:

    call Beta_reduce_rec

    pop r15
    pop r12
    pop r11

    mov r13, rbx
    mov r14, rcx

    .make_r14_true_end_loop:
    cmp byte [r14], 0x0
    jne .exit_make_r14_true_end_loop
    dec r14
    jmp .make_r14_true_end_loop
    .exit_make_r14_true_end_loop:
    inc r14

    pop rbx
    pop rcx


    .copy_reduced_form:
    pop rbx
    pop rcx

    ;r12 is beginning of original body, r15 is beginning of body after first 2 parameters
    ;rcx is end of body

    ;r13 is beginning of reduced parameter
    ;r14 is end of reduced parameter

    mov rax, [variables_end]
    mov rdx, rax

    cmp byte [r13], 'L'
    jne .after_start_paranthesis
    mov byte [rax], '('
    inc rax
    .after_start_paranthesis:

    mov r8, r13
    .copy_reduced_to_end_loop:
    cmp r8, r14
    je .exit_copy_reduced_to_end_loop
    mov r9b, [r8]
    mov [rax], r9b
    inc rax
    inc r8
    jmp .copy_reduced_to_end_loop
    .exit_copy_reduced_to_end_loop:

    cmp byte [r13], 'L'
    jne .after_end_paranthesis
    mov byte [rax], ')'
    inc rax
    .after_end_paranthesis:

    cmp byte [rdx], '('
    jne .removed_paranthesis
    cmp byte [rdx+1], '('
    jne .removed_paranthesis
    cmp byte [rax-1], ')'
    jne .removed_paranthesis
    cmp byte [rax-2], ')'
    jne .removed_paranthesis
    dec rax
    mov byte [rax], 0x0
    mov byte [rdx], 0x0
    inc rdx

    .removed_paranthesis:
    mov r8, r15
    .copy_OG_body_to_end_loop:
    cmp r8, rcx
    jge .exit_copy_OG_body_to_end_loop
    mov r9b, [r8]
    mov [rax], r9b
    inc rax
    inc r8
    jmp .copy_OG_body_to_end_loop
    .exit_copy_OG_body_to_end_loop:

    mov byte [rax], 0x0
    inc rax
    mov byte [rax], 'V'
    inc rax
    mov byte [rax], 0x0
    inc rax
    mov [variables_end], rax
    dec rax

    ;rdx is beginning of copied line, rax is (one more than) end

    mov r8, r12
    inc r8
    mov r10, rdx
    .copy_new_line_loop:
    cmp r10, rax
    je .exit_copy_new_line_loop
    mov r9b, [r10]
    mov [r8], r9b
    inc r8
    inc r10
    jmp .copy_new_line_loop
    .exit_copy_new_line_loop:

    mov rcx, r8
    sub rcx, 0x2

    .loop_end:
    jmp .loop

    .end:
    pop rbx
    pop rcx
    ret

    .one_argument:
    pop rbx
    pop rcx

    cmp byte [rbx], 'L'
    je .one_argument_end
    cmp byte [rbx+1], 'L'
    je .one_argument_end
    cmp byte [rbx], '('
    je .shift_back
    cmp byte [rbx+2], 'L'
    je .one_argument_end
    cmp byte [rbx+1], '('
    jne .one_argument_end
    lea r8, [rbx+1]
    lea r10, [rbx+2]
    jmp .shift_back_loop

    .shift_back:
    lea r8, [rbx]
    lea r10, [rbx+1]

    .shift_back_loop:
    cmp r10, rcx
    je .exit_shift_back_loop
    mov r9b, [r10]
    mov [r8], r9b
    inc r8
    inc r10
    jmp .shift_back_loop
    .exit_shift_back_loop:
    lea rcx, [r8-1]
    mov byte [rcx], 0x0
    jmp .loop

    .one_argument_end:
    ret


Error:
    mov rcx, error_message
    mov rdx, [line_number]
    call printf

    mov rax, 1
    jmp Interpret.end


section .bss
    variables: resb 0x100000 ;Arbitrary number, should be larger for bigger programs
    variables_end: resq 0x1
    return_variable_start: resq 0x1
    return_variable_end: resq 0x1
    line_number: resq 0x1

section .data
    lambda_prefix: db "lam-"
    calc_prefix: db "clc:"
    error_message: db "Error on row number %d", 0xd, 0xa, 0xd, 0xa
