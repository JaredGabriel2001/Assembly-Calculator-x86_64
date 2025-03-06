; nasm -f elf64 calculadora.asm -o calculadora.o
; gcc -m64 -no-pie calculadora.o -o calculadora.x

section .data
    solok       db "%.2lf + %.2lf = %.2lf", 10, 0
    solnotok    db "Erro: operação não suportada", 10, 0
    usage       db "Uso: ./calculadora.x <op1> a <op2>", 10, 0
    file        db "saida.txt", 0
    openmode    db "a+", 0
    vzero       dd 0.0

section .bss
    op1             resd 1          ; primeiro operando (float)
    op2             resd 1          ; segundo operando (float)
    signaturefile   resq 1          ; ponteiro FILE* (8 bytes)

section .text
    extern printf
    extern fprintf
    extern fopen
    extern fclose
    extern atof
    global main

;============================
; Função de soma
;============================
adicao:
    push rbp
    mov rbp, rsp
    addss xmm0, xmm1          ; soma op1 (xmm0) + op2 (xmm1)
    pop rbp
    ret

;============================
; Função de escrita
;============================
escreve_solucao:
    push rbp
    mov rbp, rsp
    ; Chama fprintf(signaturefile, solok, op1, op2, resultado)
    mov rdi, qword [signaturefile]  ; ponteiro do arquivo
    lea rsi, [solok]                ; formato "%.2lf + %.2lf = %.2lf"
    ; Converte op1 (float) para double e passa para rdx
    movss xmm2, dword [op1]
    cvtss2sd xmm2, xmm2
    movq rdx, xmm2
    ; Converte op2 (float) para double e passa para r8
    movss xmm3, dword [op2]
    cvtss2sd xmm3, xmm3
    movq r8, xmm3
    ; Converte o resultado (xmm0) para double e passa para r9
    cvtss2sd xmm0, xmm0
    movq r9, xmm0
    ; Chama fprintf
    call fprintf
    pop rbp
    ret

;============================
; Função main
;============================
main:
    push rbp
    mov rbp, rsp
    sub rsp, 8                     ; Alinha a pilha a 16 bytes

    ; Preserva argv (que está em rsi) em r10
    mov r10, rsi                   ; r10 = argv

    ; Verifica se argc (rdi) >= 4
    cmp rdi, 4
    jl usage_label

    ; Abre o arquivo de saída ("saida.txt" em modo "a+")
    lea rdi, [file]
    lea rsi, [openmode]
    call fopen
    mov [signaturefile], rax       ; Salva o ponteiro FILE*

    ; Converte argv[1] -> op1 (float)
    mov rax, [r10 + 8]             ; argv[1]
    mov rdi, rax
    call atof
    cvtsd2ss xmm0, xmm0
    movss dword [op1], xmm0

    ; Lê o operador de argv[2]
    mov rax, [r10 + 16]            ; argv[2]
    mov al, [rax]
    cmp al, 'a'
    jne error_label                ; Se não for 'a', erro

    ; Converte argv[3] -> op2 (float)
    mov rax, [r10 + 24]            ; argv[3]
    mov rdi, rax
    call atof
    cvtsd2ss xmm0, xmm0
    movss dword [op2], xmm0

    ; Carrega operandos para a soma
    movss xmm0, dword [op1]
    movss xmm1, dword [op2]
    ; Chama a função de soma
    call adicao
    ; Chama a função de escrita com o resultado
    call escreve_solucao
    jmp exit_label

;============================
; Rótulos de erro e saída
;============================
error_label:
    ; Exibe mensagem de erro
    lea rdi, [solnotok]
    call printf
    jmp exit_label

usage_label:
    ; Exibe mensagem de uso
    lea rdi, [usage]
    call printf
    jmp exit_label

exit_label:
    ; Fecha o arquivo
    mov rdi, qword [signaturefile]
    call fclose
    ; Restaura pilha e finaliza
    add rsp, 8
    mov rsp, rbp
    pop rbp
    mov rax, 60
    xor rdi, rdi
    syscall

;============================
; Seção para evitar aviso de stack executável
;============================
section .note.GNU-stack noexec nowrite progbits
