# Writes the number 49 (ASCII '1') to stdout. Runs on 64-bit Linux only.

    .global main

    # GNU requires this. Pathetic
    .section .note.GNU-stack,"",@progbits

    .data

printf_arg: .asciz "%ld\n"          # See test/prid.c

input: .asciz "137"

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
    lea input(%rip), %r10

    mov $0, %rbx     # Clear b (character temporary)
    mov $0, %rax     # Clear a (accumulator)

_main_loop:

    mov 0(%r10), %bl # Dereference r10 into a
    cmp $0, %bl      # a == 0?
    je _main_loop_done # then branch
    sub $48, %bl     # Assume ASCII number
    
    mov $10, %rcx    # Digit-shift accumulator a
    mul %rcx

    add %rbx, %rax   # Sum to accumulator a
    add $1, %r10     # Iterate pointer
    jmp _main_loop   # Repeat
    
_main_loop_done:

    mov %rax, %rsi   # Move b into s 

    call _print

    jmp _exit
