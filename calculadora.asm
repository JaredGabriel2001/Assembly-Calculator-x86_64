; nasm -f elf64 calculadora.asm ; gcc -m64 -no-pie calculadora.o -o calculadora.x

section .data
    output1 db "Primeiro operando: %.2lf", 10, 0
    output2 db "Operador: %c", 10, 0
    output3 db "Segundo operando: %.2lf", 10, 0
    resultOutput db "Resultado: %.2lf", 10, 0
    formatFloat db "%lf", 0
    formatChar db " %c", 0
    resultFormat db "%.2lf + %.2lf = %.2lf", 10, 0
    filename db "saida.txt", 0
    printArgsFormat db "Argumentos: %.2lf %c %.2lf", 10, 0

section .bss
    operando1 resq 1
    operando2 resq 1
    operador resb 1
    resultado resq 1
    file resq 1

section .text
    global main
    extern printf, sscanf, fopen, fprintf, fclose

main:
    ; Prolog
    push rbp
    mov rbp, rsp

    ; Carregar argc e argv
    mov rdi, [rbp+16] ; argc
    cmp rdi, 4          ; Verifica se argc == 4 (nome do programa + 3 argumentos)
    jne end             ; Se não for, termina silenciosamente

    ; Processar argumentos
    mov rsi, [rbp+24] ; argv
    mov rsi, [rsi+8]  ; argv[1]
    mov rdi, formatFloat
    lea rdx, [operando1]
    call sscanf        ; Lê o primeiro operando
    cmp rax, 1
    jne end

    mov rsi, [rbp+24]
    mov rsi, [rsi+16] ; argv[2]
    mov rdi, formatChar
    lea rdx, [operador]
    call sscanf        ; Lê o operador
    cmp rax, 1
    jne end

    mov rsi, [rbp+24]
    mov rsi, [rsi+24] ; argv[3]
    mov rdi, formatFloat
    lea rdx, [operando2]
    call sscanf        ; Lê o segundo operando
    cmp rax, 1
    jne end

    ; Print dos argumentos
    mov rdi, printArgsFormat
    movsd xmm0, [operando1]
    movzx esi, byte [operador]
    movsd xmm1, [operando2]
    call printf

    ; Exibir os valores lidos
    mov rdi, output1
    movsd xmm0, [operando1] ; Passa operando1 no xmm0 para printf
    call printf

    mov rdi, output2
    movzx rsi, byte [operador] ; Passa operador no rsi para printf
    call printf

    mov rdi, output3
    movsd xmm0, [operando2] ; Passa operando2 no xmm0 para printf
    call printf

    ; Realizar a soma se o operador for 'a'
    movzx rax, byte [operador]
    cmp rax, 'a'
    jne end_calc

    movsd xmm0, [operando1]
    addsd xmm0, [operando2]
    movsd [resultado], xmm0

    ; Abrir o arquivo para escrita (append)
    mov rdi, filename
    mov rsi, "a"
    call fopen
    cmp rax, 0
    je end_calc
    mov [file], rax

    ; Escrever o resultado no arquivo
    mov rdi, [file]
    mov rsi, resultFormat
    movsd xmm0, [operando1]
    movsd xmm1, [operando2]
    movsd xmm2, [resultado]
    call fprintf

    ; Fechar o arquivo
    mov rdi, [file]
    call fclose

end_calc:
    ; Epilog
    xor rax, rax
end:
    mov rsp, rbp
    pop rbp
    ret