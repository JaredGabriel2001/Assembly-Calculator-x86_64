; Montagem/Linkagem (exemplo com NASM e GCC):
;     nasm -f elf64 calc.asm -o calc.o
;     gcc calc.o -o calc
;---------------------------------------------------------------

section .data
    filename    db "saida.txt", 0
    modo        db "a", 0
    uso         db "Uso: ./calc <operando1> <operador> <operando2>", 10, 0
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
    ; Salva o operador (char) de edi em r10d
    mov r10d, edi
    ; Para chamar fprintf, o 1º argumento (file) deve ser em rdi:
    mov rdi, r8
    ; 2º argumento: endereço do formato
    lea rsi, [rel fmt_ok]
    ; Converte op1 (em xmm0) de float para double
    cvtss2sd xmm0, xmm0
    ; 3º argumento: (double) op1 -> mover para rdx
    movq rdx, xmm0
    ; 4º argumento: operador (char), passado como inteiro em rcx
    mov ecx, r10d
    ; Converte op2 (em xmm1) para double e passa como 5º argumento em r8
    cvtss2sd xmm1, xmm1
    movq r8, xmm1
    ; Converte resposta (em xmm2) para double e passa como 6º argumento em r9
    cvtss2sd xmm2, xmm2
    movq r9, xmm2
    ; Chama fprintf(file, fmt_ok, op1, op, op2, resposta)
    call fprintf
    ret

escrevesolucaoNOTOK:
    mov r10d, edi           ; salva o operador
    mov rdi, r8             ; file -> rdi
    lea rsi, [rel fmt_notok] ; formato
    cvtss2sd xmm0, xmm0     ; converte op1 para double
    movq rdx, xmm0          ; 3º argumento: op1
    mov ecx, r10d           ; 4º argumento: operador
    cvtss2sd xmm1, xmm1     ; converte op2 para double
    movq r8, xmm1           ; 5º argumento: op2
    call fprintf
    ret

main:
    ; Prologo
    push rbp
    mov rbp, rsp
    ; (Considerando que o stack já está alinhado em 16 bytes)

    ; Verifica se argc == 4
    mov eax, edi          ; argc está em edi
    cmp eax, 4
    je .args_ok
    ; Se não, imprime mensagem de uso e retorna 1
    lea rdi, [rel uso    ]
    call printf
    mov eax, 1
    jmp .exit_main

.args_ok:
    ;--- Processa operando1 ---
    ; argv[1] está em [rsi+8]
    mov rax, [rsi+8]
    mov rdi, rax          ; argumento para atof
    call atof             ; atof retorna double em xmm0
    ; Converte double para float e armazena em xmm3 (op1)
    cvtsd2ss xmm3, xmm0

    ;--- Processa operador ---
    ; argv[2] está em [rsi+16]
    mov rax, [rsi+16]
    ; Carrega o 1º caractere do operador em r10b
    movzx r10d, byte [rax]

    ;--- Processa operando2 ---
    ; argv[3] está em [rsi+24]
    mov rax, [rsi+24]
    mov rdi, rax
    call atof
    cvtsd2ss xmm4, xmm0     ; armazena op2 em xmm4

    ;--- Abre o arquivo ---
    lea rdi, [rel filename]
    lea rsi, [rel modo]
    call fopen             ; retorna FILE* em rax
    mov r8, rax            ; guarda o file pointer em r8

    ;--- Seleciona a operação com base no operador ---
    cmp r10b, 'a'
    je .op_adicao
    cmp r10b, 's'
    je .op_subtracao
    cmp r10b, 'm'
    je .op_multiplicacao
    cmp r10b, 'd'
    je .op_divisao
    ; Se nenhum operador válido, imprime erro e sai.
    lea rdi, [rel err_op]
    call printf
    mov eax, 1
    jmp .close_file

.op_adicao:
    ; Prepara os argumentos para adição:
    ; Coloca op1 (xmm3) em xmm0 e op2 (xmm4) em xmm1
    movaps xmm0, xmm3
    movaps xmm1, xmm4
    call adicao           ; resultado em xmm0
    ; Salva o resultado em xmm2 e restaura op1 em xmm0 para escrita
    movaps xmm2, xmm0      ; resultado
    movaps xmm0, xmm3      ; op1
    ; Passa o operador (em r10d já) via edi
    mov edi, r10d
    movaps xmm1, xmm4      ; op2
    call escrevesolucaoOK
    jmp .close_file

.op_subtracao:
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
    ; Verifica se op2 (xmm4) é zero.
    xorps xmm5, xmm5       ; xmm5 = 0.0
    ucomiss xmm4, xmm5
    je .div_zero
    ; Se não for zero, realiza a divisão.
    movaps xmm0, xmm3
    movaps xmm1, xmm4
    call divisao
    movaps xmm2, xmm0       ; resultado
    movaps xmm0, xmm3       ; op1
    mov edi, r10d
    movaps xmm1, xmm4
    call escrevesolucaoOK
    jmp .close_file

.div_zero:
    ; Chama escrevesolucaoNOTOK para divisão por zero.
    movaps xmm0, xmm3
    mov edi, r10d
    movaps xmm1, xmm4
    call escrevesolucaoNOTOK

.close_file:
    ; Fecha o arquivo
    mov rdi, r8
    call fclose
    mov eax, 0

.exit_main:
    ; Epilogo
    mov rsp, rbp
    pop rbp
    ret
