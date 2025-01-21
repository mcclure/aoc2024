# Writes the number 49 (ASCII '1') to stdout. Runs on 64-bit Linux only.

    .intel_syntax noprefix

    .global main

    # GNU requires this. Pathetic
    .section .note.GNU-stack,"",@progbits

    .data

printf_arg: .asciz "%ld\n"          # See test/prid.c

input: .asciz "137"

    .text

_exit:
    # exit(0)

    mov    eax, 60                  # system call 60 is exit
    xor    rdi, rdi              # we want return code 0
    syscall                         # invoke operating system to exit

_print: # ARGUMENTS: %esi
    # Modeled on https://stackoverflow.com/a/38335743
    # printf( "%d\n", [%esi] )
    
    push rbx
    lea  rdi, printf_arg[rip]
    xor eax, eax          # "Zeroing EAX is efficient way to clear AL." (?)
    call printf
    pop rbx

    ret

main:
    mov esi, 0
    lea r10, input[rip]

    mov rbx, 0     # Clear b (character temporary)
    mov rax, 0     # Clear a (accumulator)

_main_loop:

    mov bl, 0[r10] # Dereference r10 into a
    cmp bl, 0      # a == 0?
    je _main_loop_done # then branch
    sub bl, '0'     # Assume ASCII number
    
    mov rcx, 10    # Digit-shift accumulator a
    mul rcx

    add rax, rbx   # Sum to accumulator a
    add r10, 1     # Iterate pointer
    jmp _main_loop   # Repeat
    
_main_loop_done:

    mov rsi, rax    # Move b into s 

    call _print

    jmp _exit
