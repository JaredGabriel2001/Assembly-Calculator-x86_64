; nasm -f elf64 calculadora.asm && gcc -m64 -no-pie calculadora.o -o calculadora.x

section .data
    solok     : db "%.2lf + %.2lf = %.2lf", 10, 0  ; Formato de saída
    file      : db "saida.txt", 0                 ; Nome do arquivo
    openmode  : db "w", 0                         ; Modo de abertura do arquivo
    fmt_float : db "%f", 0                        ; Formato para sscanf

section .bss
    op1      : resd 1       ; primeiro operando (float)
    op2      : resd 1       ; segundo operando (float)
    fileptr  : resq 1       ; ponteiro para o arquivo (FILE *)

section .text
    extern fopen
    extern fclose
    extern fprintf
    extern sscanf
    global main

main:
    push rbp
    mov  rbp, rsp
    push rbx          ; preservar rbx
    push r12          ; preservar r12
    push r13          ; preservar r13

    ; main(int argc, char **argv):
    ;   rdi = argc
    ;   rsi = argv
    mov  r12, rdi     ; r12 <- argc
    mov  r13, rsi     ; r13 <- argv

    ; Verifica se existem ao menos 3 argumentos: argv[0], argv[1], argv[2]
    cmp  r12, 3
    jl   fim

    ; Abre o arquivo de saída
    mov  rdi, file
    mov  rsi, openmode
    call fopen
    mov  [fileptr], rax

    ; rbx apontará para o vetor argv preservado em r13
    mov  rbx, r13

    ; Converte argv[1] para float e armazena em op1
    mov  rdi, [rbx+8]    ; argv[1]
    mov  rsi, fmt_float
    lea  rdx, [op1]
    call sscanf

    ; Converte argv[2] para float e armazena em op2
    mov  rdi, [rbx+16]   ; argv[2]
    mov  rsi, fmt_float
    lea  rdx, [op2]
    call sscanf

    ; Realiza a soma em ponto flutuante (float)
    movss xmm0, [op1]     ; xmm0 = op1 (float)
    movss xmm1, [op2]     ; xmm1 = op2 (float)
    addss xmm0, xmm1      ; xmm0 = op1 + op2 (float) -> resultado

    ; -- Agora precisamos dos valores em double --
    ; Convertemos op1, op2 e o resultado para double
    movss xmm2, [op1]     ; xmm2 = op1 (float)
    cvtss2sd xmm2, xmm2   ; xmm2 = (double) op1

    movss xmm3, [op2]     ; xmm3 = op2 (float)
    cvtss2sd xmm3, xmm3   ; xmm3 = (double) op2

    cvtss2sd xmm0, xmm0   ; xmm0 = (double) resultado

    ; Precisamos chamar fprintf(FILE*, const char*, double, double, double)
    ; Para função variádica:
    ;   - rdi = FILE*
    ;   - rsi = ponteiro para o formato
    ;   - xmm0 = 1º double
    ;   - xmm1 = 2º double
    ;   - xmm2 = 3º double
    ;   - AL = número de valores flutuantes passados via XMM
    ;
    ; Queremos imprimir: op1, op2, resultado
    ; op1 (double) está em xmm2, op2 (double) em xmm3, resultado em xmm0
    ; Precisamos reordernar para XMM0, XMM1, XMM2 na ordem op1, op2, resultado

    ; Salva o resultado temporariamente
    movapd xmm4, xmm0    ; xmm4 = resultado

    ; XMM0 <- op1
    movapd xmm0, xmm2

    ; XMM1 <- op2
    movapd xmm1, xmm3

    ; XMM2 <- resultado
    movapd xmm2, xmm4

    ; Agora setamos AL = 3 (pois temos 3 doubles em XMM0..XMM2)
    mov  rdi, [fileptr]   ; FILE*
    mov  rsi, solok       ; formato
    mov  al, 3
    call fprintf

    ; Fecha o arquivo
    mov  rdi, [fileptr]
    call fclose

fim:
    ; Restaura registradores e finaliza
    pop  r13
    pop  r12
    pop  rbx
    mov  rsp, rbp
    pop  rbp

    mov  rax, 60
    xor  rdi, rdi
    syscall
