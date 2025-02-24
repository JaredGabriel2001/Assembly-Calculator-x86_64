; Montagem/Linkagem (exemplo com NASM e GCC):
;     nasm -f elf64 calc.asm -o calc.o
;     gcc calc.o -o calc
;---------------------------------------------------------------

section .data
    filename    db "saida.txt", 0
    mode        db "a", 0
    usage       db "Uso: ./calc <operando1> <operador> <operando2>", 10, 0
    err_op      db "Operador invalido. Use a (adicao), s (subtracao), m (multiplicacao) ou d (divisao).", 10, 0

section .rodata
    fmt_ok      db "%lf %c %lf = %lf\n", 0
    fmt_notok   db "%lf %c %lf = funcionalidade não disponível\n", 0

section .text
    global main
    extern atof
    extern fopen
    extern fclose
    extern fprintf
    extern printf

adicao:
    addss xmm0, xmm1
    ret

subtracao:
    subss xmm0, xmm1
    ret

multiplicacao:
    mulss xmm0, xmm1
    ret

divisao:
    divss xmm0, xmm1
    ret

escrevesolucaoOK:
    mov r10d, edi            ; salva o operador (char) recebido em edi
    mov rdi, r8              ; file -> rdi (1º argumento para fprintf)
    lea rsi, [rel fmt_ok]    ; 2º argumento: formato
    cvtss2sd xmm0, xmm0      ; converte op1 (float) para double
    movq rdx, xmm0           ; 3º argumento: (double) op1
    mov ecx, r10d            ; 4º argumento: operador (já convertido)
    cvtss2sd xmm1, xmm1      ; converte op2 para double
    movq r8, xmm1            ; 5º argumento: (double) op2
    cvtss2sd xmm2, xmm2      ; converte resposta para double
    movq r9, xmm2            ; 6º argumento: (double) resposta
    call fprintf
    ret

escrevesolucaoNOTOK:
    mov r10d, edi            ; salva o operador
    mov rdi, r8              ; file -> rdi
    lea rsi, [rel fmt_notok] ; formato
    cvtss2sd xmm0, xmm0      ; converte op1 para double
    movq rdx, xmm0           ; 3º argumento: op1 (double)
    mov ecx, r10d            ; 4º argumento: operador
    cvtss2sd xmm1, xmm1      ; converte op2 para double
    movq r8, xmm1            ; 5º argumento: op2 (double)
    call fprintf
    ret

main:
    ; Prologo
    push rbp
    mov rbp, rsp

    ; Verifica se argc == 4
    mov eax, edi          ; argc está em edi
    cmp eax, 4
    je .args_ok
    lea rdi, [rel usage]
    call printf
    mov eax, 1
    jmp .exit_main

.args_ok:
    ;--- Processa operando1 ---
    mov rax, [rsi+8]      ; argv[1]
    mov rdi, rax
    call atof             ; atof retorna double em xmm0
    cvtsd2ss xmm3, xmm0    ; armazena op1 em xmm3

    ;--- Processa operador ---
    mov rax, [rsi+16]     ; argv[2]
    movzx r10d, byte [rax] ; carrega o primeiro caractere em r10d

    ;--- Processa operando2 ---
    mov rax, [rsi+24]     ; argv[3]
    mov rdi, rax
    call atof
    cvtsd2ss xmm4, xmm0    ; armazena op2 em xmm4

    ;--- Abre o arquivo em modo append ---
    lea rdi, [rel filename]
    lea rsi, [rel mode]
    call fopen             ; retorna FILE* em rax
    mov r8, rax            ; guarda file pointer em r8

    ;--- Seleciona a operação com base no operador ---
    cmp r10b, 'a'
    je .op_adicao
    cmp r10b, 's'
    je .op_subtracao
    cmp r10b, 'm'
    je .op_multiplicacao
    cmp r10b, 'd'
    je .op_divisao
    lea rdi, [rel err_op]
    call printf
    mov eax, 1
    jmp .close_file

.op_adicao:
    ; Converte operador de entrada 'a' para '+' (ASCII 0x2B)
    mov r10b, '+'
    movaps xmm0, xmm3      ; op1
    movaps xmm1, xmm4      ; op2
    call adicao           ; resultado em xmm0
    movaps xmm2, xmm0      ; salva resultado em xmm2
    movaps xmm0, xmm3      ; reusa op1 para escrita
    mov edi, r10d         ; operador já convertido para '+'
    movaps xmm1, xmm4      ; op2
    call escrevesolucaoOK
    jmp .close_file

.op_subtracao:
    ; Converte operador de entrada 's' para '-' (ASCII 0x2D)
    mov r10b, '-'
    movaps xmm0, xmm3
    movaps xmm1, xmm4
    call subtracao
    movaps xmm2, xmm0
    movaps xmm0, xmm3
    mov edi, r10d
    movaps xmm1, xmm4
    call escrevesolucaoOK
    jmp .close_file

.op_multiplicacao:
    ; Converte operador de entrada 'm' para '*' (ASCII 0x2A)
    mov r10b, '*'
    movaps xmm0, xmm3
    movaps xmm1, xmm4
    call multiplicacao
    movaps xmm2, xmm0
    movaps xmm0, xmm3
    mov edi, r10d
    movaps xmm1, xmm4
    call escrevesolucaoOK
    jmp .close_file

.op_divisao:
    ; Converte operador de entrada 'd' para '/' (ASCII 0x2F)
    mov r10b, '/'
    xorps xmm5, xmm5       ; xmm5 = 0.0
    ucomiss xmm4, xmm5     ; compara op2 com zero
    je .div_zero
    movaps xmm0, xmm3
    movaps xmm1, xmm4
    call divisao
    movaps xmm2, xmm0      ; resultado
    movaps xmm0, xmm3
    mov edi, r10d
    movaps xmm1, xmm4
    call escrevesolucaoOK
    jmp .close_file

.div_zero:
    ; Chama escrevesolucaoNOTOK para divisão por zero
    movaps xmm0, xmm3
    mov edi, r10d
    movaps xmm1, xmm4
    call escrevesolucaoNOTOK

.close_file:
    mov rdi, r8
    call fclose
    mov eax, 0

.exit_main:
    mov rsp, rbp
    pop rbp
    ret
