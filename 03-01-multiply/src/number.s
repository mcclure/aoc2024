# Writes the number 69 to the console using only calls. Runs on 64-bit Linux only.

    .global main

    # GNU requires this. Pathetic
    .section .note.GNU-stack,"",@progbits

    .data

printf_arg: .asciz "%d\n"

    .text

main:
    # Modeled on https://stackoverflow.com/a/38335743
    # printf("%d\n", 69)
    
    push %rbx
    lea  printf_arg(%rip), %rdi
    mov  $69, %esi           # "Writing to ESI zero extends to RSI." (?)
    xor %eax, %eax          # "Zeroing EAX is efficient way to clear AL." (?)
    call printf
    pop %rbx

    # exit(0)

    mov     $60, %rax               # system call 60 is exit
    xor     %rdi, %rdi              # we want return code 0
    syscall                         # invoke operating system to exit

