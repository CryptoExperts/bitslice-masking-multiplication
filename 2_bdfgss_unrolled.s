/*
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Authors: Dahmun Goudarzi, Anthony Journaul, Matthieu Rivain and François-
 * Xavier Standaert 
 *
 */



    AREA    bdfgss_code, CODE, READONLY



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BDFGSS MULTIPLICATION MACROS                        ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;      CONSTANT DEFINITION      ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ;; ------------------------------------------------------------------------
    ;; Set the number of round for the nested loop wrt to the masking order

LOOP_COND   EQU ((MASKING_ORDER-((MASKING_ORDER-3)&0x3))>>1)


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;      CONSTANT FOR D=4         ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    IF  MASKING_ORDER = 4

    ;; ------------------------------------------------------------------------
    ;; Set a register to the masked value to the internal rotations
    
NB_LOOP     EQU 3
    MACRO
    set_mask $mask_reg
    MOV     $mask_reg, #0x7
    GBLA    mask_repetition
mask_repetition SETA 0
    WHILE   mask_repetition<NB_LOOP
    EOR     $mask_reg, $mask_reg, LSL #(MASKING_ORDER<<mask_repetition)
mask_repetition SETA  mask_repetition+1
    WEND
    MEND
        

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;      CONSTANT FOR D=8         ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ELIF    MASKING_ORDER = 8

    ;; ------------------------------------------------------------------------
    ;; Set a register to the masked value to the internal rotations

NB_LOOP     EQU 2
    MACRO
    set_mask $mask_reg
    MOV     $mask_reg, #0x7F
    GBLA    mask_repetition
mask_repetition SETA 0
    WHILE   mask_repetition<NB_LOOP
    EOR     $mask_reg, $mask_reg, LSL #(MASKING_ORDER<<mask_repetition)
mask_repetition SETA  mask_repetition+1
    WEND
    MEND


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;      CONSTANT FOR D=4         ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    ELIF    MASKING_ORDER = 16

    ;; ------------------------------------------------------------------------
    ;; Set a register to the masked value to the internal rotations

NB_LOOP     EQU 1
    MACRO
    set_mask $mask_reg
    MOV     $mask_reg, #0x7F00
    EOR     $mask_reg, #0xFF
    GBLA    mask_repetition
mask_repetition SETA 0
    WHILE   mask_repetition<NB_LOOP
    EOR     $mask_reg, $mask_reg, LSL #(MASKING_ORDER<<mask_repetition)
mask_repetition SETA  mask_repetition+1
    WEND
    MEND


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;      CONSTANT FOR D=32        ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    ELSE

    ;; ------------------------------------------------------------------------
    ;; Set a register to 0 since there is no internal rotations for d=32

NB_LOOP     EQU 0
    MACRO
    set_mask $mask_reg
    MOV     $mask_reg, #0
    MEND    
    ENDIF


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;        ROTATION MACRO         ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;; ------------------------------------------------------------------------
    ;; Rotate every chunk of MASKING_ORDER elements of 1
    
    MACRO
    rotate_1 $out, $in, $tmp, $mask_reg
    AND     $tmp, $mask_reg, $in, LSR #1
    BIC     $out, $in, $mask_reg, LSR #(MASKING_ORDER-1)
    EOR     $out, $tmp, $out, LSL #(MASKING_ORDER-1)
    MEND
        
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                         ;;
    ;;        PODUCT + XOR + ROTATION MACRO    ;;
    ;;                                         ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    MACRO
    product_xor_rotate $s, $a, $b, $r, $reg_mask, $mask_rot1, $tmp1, $tmp2, $tmp3, $i, $d_i, $mask1, $mask2
    ;; s = a AND rot(b,i) + rot(a,i) AND b + rot(r,1)
    ;; generation of the mask for rotation by i
    MOV     $reg_mask, #$mask1
    EOR     $reg_mask, $reg_mask, #$mask2
    EOR     $reg_mask, $reg_mask, $reg_mask, LSL #16
    ;;loop of iteration
    ;; rotation of b by i
    AND     $tmp1, $reg_mask, $b, LSR #$i
    BIC     $tmp2, $b, $reg_mask, LSR #$d_i
    EOR     $tmp2, $tmp1, $tmp2, LSL #$d_i
    ;;product + xor
    ;;x_2i = a AND rot(b,i)
    AND     $tmp3, $a, $tmp2
    ;;y_3i-1 = y_3i-2 + x_2i
    EOR     $s, $s, $tmp3 
    ;; rotation of a by i
    AND     $tmp1, $reg_mask, $a, LSR #$i
    BIC     $tmp2, $a, $reg_mask, LSR #$d_i
    EOR     $tmp2, $tmp1, $tmp2, LSL #$d_i
    ;;product + xor
    ;;x_2i+1 = rot(a,i) AND b
    AND     $tmp3, $b, $tmp2
    ;;y_3i = y_3i-1 + x_2i+1
    EOR     $s, $s, $tmp3 
    ;; rotation of r by i
    AND     $tmp1, $mask_rot1, $r, LSR #1
    BIC     $tmp2, $r, $mask_rot1, LSR #(MASKING_ORDER-1)
    EOR     $tmp2, $tmp1, $tmp2, LSL #(MASKING_ORDER-1)
    ;;xor of random
    ;;y_3i+1 = y_3i + rot(r,1)
    EOR $s, $s, $tmp2
    MEND
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                         ;;
    ;;        PODUCT + XOR MACRO               ;;
    ;;                                         ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    MACRO
    product_xor $s, $a, $b, $r, $reg_mask, $tmp1, $tmp2, $tmp3, $i, $d_i, $mask1, $mask2
    ;; s = a AND rot(b,i) + rot(a,i) AND b + r
    ;; generation of the mask for rotation by i
    MOV     $reg_mask, #$mask1
    EOR     $reg_mask, $reg_mask, #$mask2
    EOR     $reg_mask, $reg_mask, $reg_mask, LSL #16
    ;;loop of iteration
    ;; rotation of b by i
    AND     $tmp1, $reg_mask, $b, LSR #$i
    BIC     $tmp2, $b, $reg_mask, LSR #$d_i
    EOR     $tmp2, $tmp1, $tmp2, LSL #$d_i
    ;;product + xor
    ;;x_2i = a AND rot(b,i)
    AND     $tmp3, $a, $tmp2
    ;;y_3i-1 = y_3i-2 + x_2i
    EOR     $s, $s, $tmp3 
    ;; rotation of a by i
    AND     $tmp1, $reg_mask, $a, LSR #$i
    BIC     $tmp2, $a, $reg_mask, LSR #$d_i
    EOR     $tmp2, $tmp1, $tmp2, LSL #$d_i
    ;;product + xor
    ;;x_2i+1 = rot(a,i) AND b
    AND     $tmp3, $b, $tmp2
    ;;y_3i = y_3i-1 + x_2i+1
    EOR     $s, $s, $tmp3 
    ;;xor of random
    ;;y_3i+1 = y_3i + r
    EOR $s, $s, $r
    MEND
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                         ;;
    ;;        FIRST COMPUTATION MACRO          ;;
    ;;                                         ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    MACRO
    first_computation $s, $a, $b, $r, $tmp
    ;; s = a AND b XOR r
    AND     $tmp, $a, $b
    EOR     $s, $tmp, $r
    MEND
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                         ;;
    ;;        LAST COMPUTATION MACRO           ;;
    ;;                                         ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    MACRO
    last_computation_correction $s, $a, $b, $mask, $tmp1, $tmp2, $tmp3, $mask1, $mask2, $d_by_2
    ;; generation of the mask for rotation by d_by_2
    MOV     $mask, #$mask1
    EOR     $mask, $mask, #$mask2
    EOR     $mask, $mask, $mask, LSL #16
    ;; rotation of b by d_by_2
    AND     $tmp1, $mask, $b, LSR #$d_by_2
    BIC     $tmp2, $b, $mask, LSR #$d_by_2
    EOR     $tmp2, $tmp1, $tmp2, LSL #$d_by_2
    ;;product + xor
    AND     $tmp3, $a, $tmp2
    EOR     $s, $s, $tmp3
    MEND
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                                         ;;
    ;;        INNER LOOP MACRO D=32            ;;
    ;;                                         ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    MACRO
    innerloop_32 $s, $a, $b, $r, $addr_r, $tmp, $i, $j
    get_random $r, $addr_r
    ;; s = s XOR a AND rot(b,i)
    AND $tmp, $a, $b, ROR #$i
    EOR $s, $s, $tmp 
    ;; s = s XOR rot(a,i) AND b XOR r
    AND $tmp, $b, $a, ROR #$i
    EOR $s, $s, $tmp 
    EOR $s, $s, $r
    ;; s = s XOR a AND rot(b,j)
    AND $tmp, $a, $b, ROR #$j
    EOR $s, $s, $tmp
    ;; s = s XOR rot(a,j) AND b XOR rot(r,1)
    AND $tmp, $b, $a, ROR #$j
    EOR $s, $s, $tmp
    EOR $s, $s, $r, ROR #1
    MEND
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BDFGSS MULTIPLICATION FUNCTION                      ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    
unrolled_bdfgss_mult

    ;; ------------------------------------------------------------------------
    ;; Init phase

    LDR     R7, =RNGReg
    ;; r0 = a, r1 = b
    LDR     R0, [R0]
    LDR     R1, [R1]
    

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;     UNROLLED BDFGSS : D=2     ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    IF      MASKING_ORDER = 2

    ;; ------------------------------------------------------------------------
    
    get_random R3, R7
    ;; x_1 = a AND b
    AND     R4, R0, R1 
    ;; y_1 = x_1 + r
    EOR     R5, R4, R3


    ;; ------------------------------------------------------------------------
    ;; s = a AND rot(b,i) + rot(a,i) AND b

    ;; generation of the mask for rotation by 1 stored in R6
    MOV     R6, #0x5500
    EOR     R6, R6, #0x55
    EOR     R6, R6, R6, LSL #16
    ;; rotation of b by 1
    AND     R9, R6, R1, LSR #1
    BIC     R10, R1, R6, LSR #(MASKING_ORDER-1)
    EOR     R10, R9, R10, LSL #(MASKING_ORDER-1)
    ;;product + xor
    ;; x_2 = a AND rot(b,1)
    AND     R4, R0, R10
    ;; y_2 = y_1 + x_1 
    EOR     R5, R5, R4 
    ;; rotation of r by 1
    AND     R9, R6, R3, LSR #1
    BIC     R10, R3, R6, LSR #(MASKING_ORDER-1)
    EOR     R10, R9, R10, LSL #(MASKING_ORDER-1)
    ;; xor of random
    ;; y_4 = y_3 + rot(r,1)
    EOR R5, R5, R10 
        
    ;; ------------------------------------------------------------------------
    ;; return s

    STR     R5, [R2]


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;     UNROLLED BDFGSS : D=4     ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    ELIF    MASKING_ORDER = 4
    
    ;; ------------------------------------------------------------------------
    get_random R3, R7
    first_computation R5, R0, R1, R3, R4

    ;; ------------------------------------------------------------------------
    product_xor_rotate R5, R0, R1, R3, R6, R6, R9, R10, R4, 1, 3, 0x7700, 0x77
    
    ;; ------------------------------------------------------------------------
    last_computation_correction R5, R0, R1, R8, R9, R10, R4, 0x3300, 0x33, 2
    
    ;; ------------------------------------------------------------------------
    ;; return s
    STR     R5, [R2]


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;     UNROLLED BDFGSS : D=8     ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ELIF    MASKING_ORDER = 8

    ;; ------------------------------------------------------------------------
    get_random R3, R7
    first_computation R5, R0, R1, R3, R4

    ;; ------------------------------------------------------------------------
        product_xor_rotate R5, R0, R1, R3, R6, R6, R9, R10, R4, 1, 7, 0x7F00, 0x7F
    ;; new random generation
    get_random R3, R7
    product_xor R5, R0, R1, R3, R8, R9, R10, R4, 2, 6, 0x3F00, 0x3F 
    product_xor_rotate R5, R0, R1, R3, R8, R6, R9, R10, R4, 3, 5, 0x1F00, 0x1F

    ;; ------------------------------------------------------------------------
    last_computation_correction R5, R0, R1, R8, R9, R10, R4, 0x0F00, 0x0F, 4
    
    ;; ------------------------------------------------------------------------
    ;; return s
    STR     R5, [R2]
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;     UNROLLED BDFGSS : D=16    ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ELIF    MASKING_ORDER = 16

    ;; ------------------------------------------------------------------------
    get_random R3, R7
    first_computation R5, R0, R1, R3, R4
    
    ;; ------------------------------------------------------------------------
    product_xor_rotate R5, R0, R1, R3, R6, R6, R9, R10, R4, 1, 15, 0x7F00, 0xFF
    ;; new random generation
    get_random R3, R7
    product_xor R5, R0, R1, R3, R8, R9, R10, R4, 2, 14, 0x3F00, 0xFF    
    product_xor_rotate R5, R0, R1, R3, R8, R6, R9, R10, R4, 3, 13, 0x1F00, 0xFF
    ;;new random generation
    get_random R3, R7
    product_xor R5, R0, R1, R3, R8, R9, R10, R4, 4, 12, 0x0F00, 0xFF    
    product_xor_rotate R5, R0, R1, R3, R8, R6, R9, R10, R4, 5, 11, 0x0700, 0xFF
    ;;new random generation
    get_random R3, R7
    product_xor R5, R0, R1, R3, R8, R9, R10, R4, 6, 10, 0x0300, 0xFF    
    product_xor_rotate R5, R0, R1, R3, R8, R6, R9, R10, R4, 7, 9, 0x0100, 0xFF
    
    ;; ------------------------------------------------------------------------
    last_computation_correction R5, R0, R1, R8, R9, R10, R4, 0x0000, 0xFF, 8

    ;; ------------------------------------------------------------------------
    ;; return s
    STR     R5, [R2]

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;     UNROLLED BDFGSS : D=32    ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    

    ELIF    MASKING_ORDER = 32

    ;; ------------------------------------------------------------------------
    ;;First loop computation
    get_random R3, R7
    first_computation R5, R0, R1, R3, R4

    AND R4, R0, R1, ROR #1 ;;x_2 = a.rot(b,1)
    EOR R5, R5, R4 ;; y_2 = y_1 + x_2
    AND R4, R1, R0, ROR #1 ;;x_3 = b.rot(a,1)
    EOR R5, R5, R4 ;; y_3 = y_2 + x_3
    EOR R5, R5, R3, ROR #1 ;;y_4 = y_3 + rot(r1,1)
    
    ;; ------------------------------------------------------------------------
    ;; Inner loop computation
    innerloop_32 R5, R0, R1, R3, R7, R4, 2, 3
    innerloop_32 R5, R0, R1, R3, R7, R4, 4, 5
    innerloop_32 R5, R0, R1, R3, R7, R4, 6, 7
    innerloop_32 R5, R0, R1, R3, R7, R4, 8, 9
    innerloop_32 R5, R0, R1, R3, R7, R4, 10, 11
    innerloop_32 R5, R0, R1, R3, R7, R4, 12, 13
    innerloop_32 R5, R0, R1, R3, R7, R4, 14, 15
    
    ;; ------------------------------------------------------------------------
    ;;Last loop computation
    AND R4, R0, R1, ROR #16
    EOR R5, R5, R4
    
    ;; ------------------------------------------------------------------------
    ;; return s
    STR     R5, [R2]


    ENDIF
    
    BX LR
    LTORG


