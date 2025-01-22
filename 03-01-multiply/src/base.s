# Solves the puzzle (generic version, needs convert.pl). Runs on 64-bit Linux only.

    .intel_syntax noprefix

    .global main

    # GNU requires this. Pathetic
    .section .note.GNU-stack,"",@progbits

    .data

printf_arg: .asciz "%ld\n"          # See test/prid.c

# !!!!!!!!!!!!!!!! This line will be replaced by "input"

match_prefix: .ascii "mul("

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
    lea r8, input[rip]

    mov rbx, 0     # Clear b (character temporary)
    mov rax, 0     # Clear a (accumulator)
    mov r12, 0     # Clear C (total)

_main_loop_reset:
    mov r9, 0      # Clear 9 (state)
    mov r10, 0     # Clear A (op 1)
    mov r11, 0     # Clear B (op 2)

# States
# 0 1 2 3  4    5
# M U L ( d1 , d2 )

_main_loop:

    mov bl, 0[r8] # Dereference r10 into b
    cmp bl, 0      # a == 0?
    je _main_loop_done # then branch

_main_loop_retry:

    _main_trymul:
        cmp r9, 4 # Are we in MUL( state?
        jge _main_postprefix # If not, branch
        lea  rax, match_prefix[rip]
        add rax, r9
        mov al, 0[rax]
        cmp al, bl
        je _main_succeed
        jmp _main_fail

    _main_postprefix:
        cmp r9, 5 # Are we in number/')' state?
        jl _main_s4 # If not, branch
        cmp bl, ')' # Is it a )
        jne _main_number  # If not, assume it's a number

        # r12 += (r10 * r11)
        mov rax, r10
        mul r11
        add r12, rax

        add r8, 1        # Funky _succeed-- iterate pointer
        jmp _main_loop_reset

    _main_s4:
        cmp bl, ',' # Is it a ,
        jne _main_number # If not, assume it's a number
        
        # Move op1 to op2
        mov r11, r10
        mov r10, 0
        jmp _main_succeed

    _main_number:
        cmp bl, '0'
        jl _main_fail
        cmp bl, '9'
        jg _main_fail

        sub bl, '0'     # Assume ASCII number
        
        mov rax, r10   # op1 to accumulator        (Maybe unnecessary but be safe)
        mov rcx, 10    # Digit-shift accumulator a
        mul rcx

        add rax, rbx   # Sum to accumulator a
        mov r10, rax   # Accumulator to op1

        jmp _main_succeed_number

    _main_succeed:
        add r9, 1 # Iterate state
    _main_succeed_number:
        add r8, 1        # Iterate pointer
        jmp _main_loop   # Repeat

    _main_fail:
        cmp r9, 0 # Looking for a M, didn't even find that
        je _main_true_fail
        mov r9, 0
        jmp _main_loop_retry
    _main_true_fail:
        add r8,1 # Iterate pointer
        jmp _main_loop_reset
        
_main_loop_done:

    mov rsi, r12    # Move b into s 

    call _print

    jmp _exit
