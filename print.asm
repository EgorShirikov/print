%define hex_digit      [esp + 36 + 4*2]
%define out_buffer     [esp + 36]
%define string_format  [esp + 36 + 4]

section .data
	outbuf: DB 40 DUP(0)
	buf:  DB 16 DUP(0)
	ten: dd 10
	flag: DB 0,0,0,0
	force_sign: DB 0

global print
section .text
print:
    pushad
    MOV esi, hex_digit
    xor ecx, ecx
    xor edx, edx
    xor ebx, ebx
    xor edi, edi
    xor ebp, ebp
    cmp byte [esi], 0
    je  check_sign1
    cmp byte [esi], '-'
    jne read_hex
    mov ebp, 1
    mov byte[force_sign], 1 
    inc esi
    cmp byte [esi], 0
    je  check_sign1
read_hex:
    shld ebx, ecx, 4
    shld ecx, edx, 4
    shld edx, edi, 4
    shl edi, 4
    call num
    or edi, eax
    inc esi
    cmp byte [esi], 0
    jne read_hex
    jmp check_sign1
num:
    xor eax, eax
    mov al, byte[esi]
    cmp al, 'A'
    jl  digit
    cmp al, 'a'
    jl  upper_case
    jmp lower_case
digit:
    sub al, '0'
    ret
upper_case:
    sub al, 'A'
    add al, 10
    ret
lower_case:
    sub al, 'a'
    add al, 10
    ret
check_sign1:
    cmp ebp, 1
    jne check_sign2
    call negate
check_sign2:
    xor ebp, ebp
    mov byte[force_sign], 0
    test ebx, 0x80000000
    jz  pre_to_decimal
    mov ebp, 1
    mov byte[force_sign], 1
    call negate
    jmp pre_to_decimal
negate:
    not ebx
    not ecx
    not edx
    not edi
    clc
    adc edi, 1
    adc edx, 0
    adc ecx, 0
    adc ebx, 0
    ret
pre_to_decimal:
    mov dword [buf], ebx
    mov dword [buf + 4], ecx
    mov dword [buf + 4*2], edx
    mov dword [buf + 4*3], edi
    mov esi, ebp
    mov edi, out_buffer
    mov ebp, string_format
    xor ecx, ecx
    mov ebx, 10
    jmp to_decimal_loop
to_decimal:
	cmp dword [buf], 0
    jne to_decimal_loop
    cmp dword [buf+4], 0
    jne to_decimal_loop
    cmp dword [buf+8], 0
    jne to_decimal_loop
    cmp dword [buf+12], 0
    jne to_decimal_loop
    mov ebx, esi
    jmp read_format
to_decimal_loop:
	call to_d
	add dl, 48
    mov byte[outbuf + ecx], dl
    inc ecx
    jmp to_decimal
read_format:
    cmp byte [ebp], 0
    je  check_format
    cmp byte [ebp], '0'
    je  zero
    cmp byte [ebp], '+'
    je  plus
    cmp byte [ebp], '-'
    je  minus
    cmp byte [ebp], ' '
    je  space
    cmp byte [ebp], '9'
    jna width
space:
    or bh, 1000b
    mov byte[flag+3], 1
    inc ebp
    jmp read_format
zero:
    or bh, 1b
    mov byte[flag], 1
    inc ebp
    jmp read_format
plus:
    or bh, 10b
    mov byte[flag+1], 1
    inc ebp
    jmp read_format
minus:
    or bh, 100b
    mov byte[flag+2], 1
    inc ebp
    jmp read_format
width:
    mov edx, 10
    mul edx
    mov dl, byte [ebp]
    sub dl, 48
    add eax, edx
    inc ebp
    cmp byte [ebp], 0
    jne width
    mov esi, eax
check_format:
    test byte[force_sign], 1b
    jnz sign_set
    test bh, 10b
    jnz plus_setting
    test bh, 1000b
    jnz space_setting
    jmp sign_set
sign_set:
    test bl, 111b
    jz no_sign
    inc ecx
    xor eax, eax
    cmp esi, ecx
    jae pre_left_alligment
    mov esi, ecx
    jmp pre_left_alligment
no_sign:
    cmp esi, ecx
    jae check_left_alligment
    mov esi, ecx
    jmp check_left_alligment
plus_setting:
    or bl, 10b
    jmp sign_set
space_setting:
    or bl, 100b
    jmp sign_set
pre_left_alligment:
    dec ecx
    jmp check_left_alligment
check_left_alligment:
    test bh, 100b
    jz pre_print_without_left_alligment
    call print_sign
print_with_left_alligment:
    mov al, byte[outbuf + ecx - 1]
    mov [edi], al
    dec ecx
    dec esi
    inc edi
    cmp ecx, 0
    jnz print_with_left_alligment
printing_alligment_spaces:
    test esi, esi
    jz end
    mov byte [edi], ' '
    inc edi
    dec esi
    jmp printing_alligment_spaces
pre_print_without_left_alligment:
    xor edx, edx
    mov ebp, esi
    dec ebp
print_without_left_alligment:
    mov al, [outbuf + edx]
    mov [edi + ebp], al
    inc edx
    dec ebp
    cmp edx, ecx
    jb print_without_left_alligment
print_leading_zeroes:    
    test bh, 1b
    jnz pre_leading_zeros
    mov edx, edi
    add ebp, edi
print_leading_sign:
    test bl, 111b
    jz pre_leading_spaces
    mov edi, ebp
    call print_sign
print_leading_spaces:
    inc esi
    mov edi, edx
    jmp leading_spaces
pre_leading_spaces:
    inc ebp
leading_spaces:
    cmp edx, ebp
    je end
    mov byte [edx], ' '
    inc edx
    jmp leading_spaces
pre_leading_zeros:
    call print_sign
    sub esi, ecx
leading_zeroes:
    test esi, esi
    jz pre_end_print
    mov byte [edi], '0'
    inc edi
    dec esi
    jmp leading_zeroes
pre_end_print:
    add edi, ecx
end:
    add edi, esi
    mov byte [edi], 0
    popad
    ret
to_d:
    xor edx, edx
    mov eax, [buf]
    div ebx
    mov dword [buf], eax
    mov eax, dword[buf + 4]
    div ebx
    mov dword[buf + 4], eax
    mov eax, dword[buf + 4*2]
    div ebx
    mov dword[buf + 8], eax
    mov eax, dword[buf + 4*3]
    div ebx
    mov dword[buf + 4*3], eax
    ret
print_sign:
	test bl, 111b
	jz already_placed
    test bl, 1b
    jnz minus_placing
    test bl, 10b
    jnz plus_placing
    test bl, 100b
    jnz space_placing
minus_placing:
    mov byte [edi], '-'
    inc edi
    dec esi
    ret
plus_placing:
    mov byte [edi], '+'
    inc edi
    dec esi
    ret
already_placed:
	ret
space_placing:
    mov byte [edi], ' '
    inc edi
    dec esi
    ret
