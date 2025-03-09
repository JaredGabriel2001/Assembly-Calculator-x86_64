; nasm -f elf64 calculadora.asm && gcc -no-pie calculadora.o -o calculadora.x
; nasm -f elf64 -g -F dwarf calculadora.asm ; gcc -m64 -no-pie -g calculadora.o -o calculadora.x

section .data
    solok : db "%.2lf %c %.2lf = %.2lf", 10, 0
    solnotok : db "%.2lf %c %.2lf = funcionalidade não disponível", 10, 0
    scanctl : db "%f %c %f", 0
    file_name db "saida.txt", 0
    file_mode db "a+", 0
    erro_argumentos_msg db "Erro: Numero incorreto de argumentos", 10, 0
    controle : db "X", 0

section .bss
    operando1 resd 1
    operador resb 1
    operando2 resd 1
    signaturefile : resd 1

section .text
    extern printf, fprintf, fopen, fclose, atof, scanf
    global main

main:
    push rbp
    mov rbp, rsp

    ; Salva o ponteiro de argv em r12, estou usando rsi para fopen e anteriormente tive problemas ao usar para ler o primeiro operando
    mov r12, rsi

    mov rdi, file_name
    mov rsi, file_mode
    call fopen
    mov [signaturefile], rax

    ; le argv[1] e chama atof (retorna double em xmm0)
    mov r8, [r12 + 8]
    mov rdi, r8
    call atof
    ; converte double -> float (gambiarra)
    cvtsd2ss xmm0, xmm0
    ; armazena float em [operando1]
    movss [operando1], xmm0

    ; 2) Lê argv[2] e armazena o operador
    mov r9, [r12 + 16]
    mov rdi, r9
    mov al, [rdi]
    mov [operador], al

    ; 3) Lê argv[3] e chama atof (retorna double em xmm0)
    mov r10, [r12 + 24]
    mov rdi, r10
    call atof
    ; converte double -> float 
    cvtsd2ss xmm0, xmm0
    ; armazena float em [operando2]
    movss [operando2], xmm0

    ; Agora sim, ao carregar de [operando1] e [operando2], temos os valores corretos :D
    movss xmm0, dword [operando1]
    movss xmm1, dword [operando2]

    ;comparador para escolher qual instrução usar
    ;move o char para r8b 
    mov r8b, [operador]
    
    cmp r8b, 'a'
    je callAdicao
    
    cmp r8b, 's' 
    je callSubtracao 

    cmp r8b, 'm'
    je callMultiplicacao 

    cmp r8b, 'd'
    je callDivisao 

    jmp solucaonotok ; Operador inválido

end:
    mov rdi, qword[signaturefile]
    call fclose

    mov rsp, rbp   
    pop rbp

    mov rax, 60
    mov rdi, 0
    syscall
callAdicao:
    mov r8b, "+"
    call adicao

callSubtracao:
    mov r8b, "-"
    call subtracao

callMultiplicacao:
    mov r8b, "*"
    call multiplicacao

callDivisao:
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
    mov rdi, qword[signaturefile]
    mov rsi, solok
    cvtss2sd xmm2, xmm0
    cvtss2sd xmm1, [operando2]
    mov rdx, r8
    cvtss2sd xmm0, [operando1]
    call fprintf

    mov rsp, rbp
    pop rbp
    ret
    
escrevesolucaonotok:
    push rbp
    mov rbp, rsp

    mov rax, 2
    mov rdi, qword[signaturefile]
    mov rsi, solnotok
    cvtss2sd xmm1, [operando2]
    mov rdx, r8
    cvtss2sd xmm0, [operando1]
    call fprintf

    movss xmm0, dword[controle]
    mov rsp, rbp
    pop rbp
    ret


