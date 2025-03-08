section .data
    arg1  : db 10, 'Primeiro argumento (float): '
    strl2 : equ $-arg1
    arg2  : db 10, 'Segundo argumento (operacao): '
    strl3 : equ $-arg2
    arg3  : db 10, 'Terceiro argumento (float): '
    strl4 : equ $-arg3
    lf    : db 10,10 ; quebra-de-linha dupla

section .bss
    temp  : resb 1  ; char para impressão
    noPa  : resq 1  ; número de parâmetros

section .text
    global _start

_start:
    xor r9, r9
    pop qword [noPa]  ; número de parâmetros -- argc

    ; Ignorar o nome do programa
    pop r15           ; Remove o primeiro argumento (nome do programa)

    ; Processa o primeiro argumento (float)
    pop r15           ; Primeiro número float
    mov rax, 1
    mov rdi, 1
    mov rsi, arg1
    mov rdx, strl2
    syscall

    call printArg

    ; Processa o segundo argumento (operador)
    pop r15           ; Operação (char: a, s, m, d)
    mov rax, 1
    mov rdi, 1
    mov rsi, arg2
    mov rdx, strl3
    syscall

    call printArg

    ; Processa o terceiro argumento (float)
    pop r15           ; Segundo número float
    mov rax, 1
    mov rdi, 1
    mov rsi, arg3
    mov rdx, strl4
    syscall

    call printArg

    ; Finaliza o programa
    mov rax, 1
    mov rdi, 1
    mov rsi, lf
    mov rdx, 2
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

printArg:
    xor r9, r9
printLoop:
    mov r8b, [r15 + r9]
    cmp r8b, 0
    je endPrint
    mov [temp], r8b
    mov rax, 1
    mov rdi, 1
    mov rsi, temp
    mov rdx, 1
    syscall
    inc r9
    jmp printLoop
endPrint:
    ret
