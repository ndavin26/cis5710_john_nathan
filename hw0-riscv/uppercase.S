        .section .data
input_string:   .asciz "Hello jkrhJNsadsd ++==! /*-()??><?>:*&@(#$%)"

        # tohost/fromhost are data locations used by Spike
        .align 8
tohost: .byte 0
        .align 8
fromhost: .byte 0

        
        .section .text
        .globl _start
_start:
        # Load the address of the input string into a0
        la a0, input_string

        # Your code here!
        # Convert to uppercase in-place
        # Loop: read byte, if NUL stop, if 'a'..'z' subtract 32, store back, advance
loop:
        lbu     t0, 0(a0)          # t0 = *a0 (unsigned byte)
        beqz    t0, end_program    # if NUL terminator, done

        li      t1, 97             # 'a'
        li      t2, 122            # 'z'
        blt     t0, t1, no_change  # if ch < 'a', skip
        bgt     t0, t2, no_change  # if ch > 'z', skip

        addi    t0, t0, -32        # ch = ch - ('a' - 'A') = ch - 32
        sb      t0, 0(a0)          # store uppercase back

no_change:
        addi    a0, a0, 1          # a0++
        j       loop               # repeat
        
end_program:
        # jump here when you're done
        j end_program

