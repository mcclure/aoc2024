# Writes the number 49 (ASCII '1') to stdout. Runs on 64-bit Linux only.

    .global main

    # GNU requires this. Pathetic
    .section .note.GNU-stack,"",@progbits

    .data

printf_arg: .asciz "%d\n"

input: .asciz "\
137\
"

    .text

_exit:
    # exit(0)

    mov     $60, %rax               # system call 60 is exit
    xor     %rdi, %rdi              # we want return code 0
    syscall                         # invoke operating system to exit

_print: # ARGUMENTS: %esi
    # Modeled on https://stackoverflow.com/a/38335743
    # printf( "%d\n", [%esi] )
    
    push %rbx
    lea  printf_arg(%rip), %rdi
    xor %eax, %eax          # "Zeroing EAX is efficient way to clear AL." (?)
    call printf
    pop %rbx

    ret

main:
    mov $0, %esi
    mov $0, %r10
    mov input, %r10 # Load pointer

    mov $0, %rax     # Clear high bits of a
    mov 0(%r10), %al # Dereference r10 into a
    mov %eax, %esi   # Resize a into s

    call _print

    jmp _exit
