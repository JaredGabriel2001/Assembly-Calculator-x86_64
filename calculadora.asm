; nasm -f elf64 calculadora.asm ; gcc -m64 -no-pie calculadora.o -o calculadora.x

section .data
    solok : db "%.2lf %c %.2lf = %.2lf", 10, 0
    solnotok : db "%.2lf %c %.2lf = funcionalidade não disponível", 10, 0
    file : db "saida.txt", 0
    openmode : db "a+"
    vone : dd 1.0
    vzero : dd 0.0
    controle : db "X", 0

section .bss
    op : resb 1
    op1 : resd 1
    op2 : resd 1
    signaturefile : resd 1

section .text
    extern printf
    extern fprintf
    extern fopen
    extern fclose
    extern sscanf
    global main

main:
    push rbp
    mov rbp, rsp

    ; Abre o arquivo de saída
    mov rdi, file
    mov rsi, openmode
    call fopen
    mov [signaturefile], rax

    ; Prepara os parâmetros para leitura da linha de comando
    mov rdi, rdx          ; argv[1]
    mov rsi, r8           ; argv[2]
    mov rdx, r9           ; argv[3]

    ; Converte os parâmetros
    lea rax, [op1]
    lea rcx, [op]
    lea rdx, [op2]
    call sscanf

    ; Passa os operandos para os registradores de parâmetros
    movss xmm0, dword [op1]
    movss xmm1, dword [op2]

    ; Move o operador para r8b
    mov r8b, [op]

    ; Seleciona a instrução a ser usada com base no operador
    cmp r8b, 'a'
    je callsoma

    cmp r8b, 's'
    je callmenos

    cmp r8b, 'm'
    je callmult

    cmp r8b, 'd'
    je calldivide

    ; Se o operador não for reconhecido, encerra o programa
    jmp end

callsoma:
    mov r8b, "+"
    call adicao

callmenos:
    mov r8b, "-"
    call subtracao

callmult:
    mov r8b, "*"
    call multiplicacao

calldivide:
    mov r8b, "/"
    call divisao

adicao:
    push rbp
    mov rbp, rsp

    addss xmm0, xmm1
    jmp solucaook

    mov rsp, rbp
    pop rbp

    ret

subtracao:
    push rbp
    mov rbp, rsp

    subss xmm0, xmm1
    jmp solucaook

    mov rsp, rbp
    pop rbp

    ret

multiplicacao:
    push rbp
    mov rbp, rsp

    mulss xmm0, xmm1
    jmp solucaook

    mov rsp, rbp
    pop rbp

    ret

divisao:
    push rbp
    mov rbp, rsp

    cvtss2si r9, xmm1

    mov r11, 0
    cmp r9, r11
    je indisponivel1

    divss xmm0, xmm1
    jmp solucaook

    mov rsp, rbp
    pop rbp

    ret

indisponivel1:
    jmp solucaonotok
    mov rsp, rbp
    pop rbp

    ret

solucaook:
    call escrevesolucaook
    jmp end

solucaonotok:
    call escrevesolucaonotok
    jmp end    

escrevesolucaook:
    push rbp
    mov rbp, rsp

    mov rax, 2
    mov rdi, qword [signaturefile]
    mov rsi, solok
    cvtss2sd xmm2, xmm0
    cvtss2sd xmm1, [op2]
    mov rdx, r8
    cvtss2sd xmm0, [op1]
    call fprintf

    mov rsp, rbp
    pop rbp
    ret

escrevesolucaonotok:
    push rbp
    mov rbp, rsp

    mov rax, 2
    mov rdi, qword [signaturefile]
    mov rsi, solnotok
    cvtss2sd xmm1, [op2]
    mov rdx, r8
    cvtss2sd xmm0, [op1]
    call fprintf

    movss xmm0, dword [controle]
    mov rsp, rbp
    pop rbp
    ret

end:
    mov rdi, qword [signaturefile]
    call fclose

    mov rsp, rbp
    pop rbp

    mov rax, 60
    mov rdi, 0
    syscall
