# Solves the puzzle (generic version, needs convert.pl). Runs on 64-bit Linux only.

    .intel_syntax noprefix

    .global main

    # GNU requires this. Pathetic
    .section .note.GNU-stack,"",@progbits

    .data

printf_arg: .asciz "%ld\n"          # See test/prid.c

input: .asciz "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"

match_prefix:  .ascii "mul("
match_prefix2: .ascii "don't()"

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
    mov r14, 0     # Clear E (disabled)

_main_loop_reset:
    mov r9, 0      # Clear 9 (state)
    mov r10, 0     # Clear A (op 1)
    mov r11, 0     # Clear B (op 2)
    mov r13, 0     # Clear D (state2)

# States
# 0 1 2 3  4    5
# M U L ( d1 , d2 )

# State2's
# 0 = MUL(), 1 = DON'T(), 2 = DO() [in state2 1 or 2, state 6 == final]

_main_loop:

    mov bl, 0[r8] # Dereference r10 into b
    cmp bl, 0      # a == 0?
    je _main_loop_done # then branch

_main_loop_retry:

    _main_trymul:
        cmp r13, 0 # Divert if DODONT
        jg _main_test_dodont # Branch
        cmp r9, 4 # Are we in MUL( state?
        jge _main_postprefix # If not, branch
        lea  rax, match_prefix[rip]
        add rax, r9
        mov al, 0[rax]
        cmp al, bl
        je _main_mul_succeed
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

    _main_mul_succeed:
        cmp r14,0 # This is an (inefficient) late check to see if we're parsing in disabled mode. 
        jne _main_dodont_fail
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
        cmp bl, 'd'
        je _main_switch_dodont # Wait no!! Not a failure!!
    _main_dodont_fail:
        add r8,1 # Iterate pointer
        jmp _main_loop_reset

    _main_switch_dodont:
        mov r13, 1
        jmp _main_succeed

    _main_test_dodont:
        lea rax, match_prefix2[rip]
        add rax, r9 # These two lines are reused but the things before and after are different...
        mov al, 0[rax]
        cmp al, bl
        je _main_dodont_succeed
        # We're now failed, but maybe failure isn't really failure...
        cmp r9, 2             # If we are on index 2...
        jne _main_dodont_fail
        cmp bl, '('           # And the character is a (...
        jne _main_dodont_fail
        mov r9, 6             # Then switch to state2 2 and skip ahead to the (.
        mov r13, 2
        jmp _main_succeed_number

    _main_dodont_succeed:
        cmp r9, 6         # Are we done?
        jne _main_succeed # No, keep scanning...
        mov r14, 2
        sub r14, r13 # Set r14 to 0 for 2 or 1 for 1
        jmp _main_loop_reset
        
_main_loop_done:

    mov rsi, r12    # Move b into s 

    call _print

    jmp _exit
