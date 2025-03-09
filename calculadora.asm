; nasm -f elf64 calculadora.asm && gcc -no-pie calculadora.o -o calculadora.x

; nasm -f elf64 -g -F dwarf calculadora.asm ; gcc -m64 -no-pie -g calculadora.o -o calculadora.x

section .data
    output_ok_format db "%2f %c %2f = %2f", 10, 0
    output_notok_format db "%2f %c %2f = funcionalidade nao disponivel", 10, 0

    file_name db "saida.txt", 0
    file_mode db "a+", 0
    erro_argumentos_msg db "Erro: Numero incorreto de argumentos", 10, 0
    controle : db "X", 0

section .bss
    operando1 resd 1
    operador resb 1
    operando2 resd 1
    arquivo resq 1

section .text
    extern printf, fprintf, fopen, fclose, atof
    global main
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
main:
    

    mov r8b, [operador]
    
    cmp r8b, 'a'
    je adicao
    
    cmp r8b, 's' 
    je subtracao 

    cmp r8b, 'm'
    je multiplicacao 

    cmp r8b, 'd'
    je divisao 

end:
    mov rdi, qword[arquivo]
    call fclose

    mov rsp, rbp   
    pop rbp

    mov rax, 60
    mov rdi, 0
    syscall

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
    mov rdi, qword[arquivo]
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
    mov rdi, qword[arquivo]
    mov rsi, solnotok
    cvtss2sd xmm1, [op2]
    mov rdx, r8
    cvtss2sd xmm0, [op1]
    call fprintf

    movss xmm0, dword[controle]
    mov rsp, rbp
    pop rbp
    ret



