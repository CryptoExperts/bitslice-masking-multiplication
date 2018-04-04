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
    set_corr $mask_reg
    MOV     $mask_reg, #0x1
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
    set_corr $mask_reg
    MOV     $mask_reg, #0x1
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
    set_corr $mask_reg
    MOV     $mask_reg, #0x1
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
    set_corr $mask_reg
    MOV     $mask_reg, #0
    MEND    
    ENDIF
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BDFGSS MULTIPLICATION FUNCTION                      ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
bdfgss_mult
    
    ;; ------------------------------------------------------------------------
    ;; Init phase
    
    push{R14}
    LDR     R7, =RNGReg
    MOV     R8, #0xFFFFFFFF
    set_corr R9

    ;; ------------------------------------------------------------------------
    ;; x = a AND b

    ;; set mask for rotate1
    EOR     R14, R8, R9
    ;; s = a AND b
    LDR     R0, [R0]
    LDR     R1, [R1]
    AND     R6, R0, R1
    ;; s += r_1
    get_random R3, R7
    EOR     R6, R3
    
    ;; ------------------------------------------------------------------------
    ;; s = a AND rot(b,i) + rot(a,i) AND b

    MOV     R12, #1
loopOverSharesbdfgss_mult
    ;; tmp_a = rot(a,i)
    ;; tmp_b = rot(b,i)
    MOV     R4, R0
    MOV     R5, R1
    ;; set mask
    EOR     R8, R8, R9
    LSL     R9, R9, #1
    ;;computute MASKING_ORDER -i
    RSB     R11, R12, #MASKING_ORDER
    ;; rotation of a by i
    AND     R10, R8, R4, LSL R12
    LSR     R4, R4, R11
    BIC     R4, R4, R8
    EOR     R4, R10, R4
    ;; rotation of b by i
    AND     R10, R8, R5, LSL R12
    LSR     R5, R5, R11
    BIC     R5, R5, R8
    EOR     R5, R10, R5
    ;; s ^= a*rot(b,i)
    AND     R10, R0, R5
    EOR     R6, R10
    ;; s ^= rot(a,i)*b
    AND     R10, R1, R4
    EOR     R6, R10
    ;; if loop counter is odd, skip rotation
    ANDS    R11, R12, #1
    BNE     skipRndGen
    get_random R3, R7
    B       skipRotate
skipRndGen
    ;; rotation of r by 1
    AND     R10, R14, R3, LSL #1
    LSR     R3, R3, #(MASKING_ORDER-1)
    BIC     R3, R3, R14
    EOR     R3, R10, R3 
skipRotate
    EOR     R6, R3
    ;;  loop processing 
    ADD     R12, #1
    CMP     R12, #(LOOP_COND+1)
    BNE     loopOverSharesbdfgss_mult

    ;; ------------------------------------------------------------------------
    ;; s ^= a AND rot(b,d/2)

    ;;set mask
    EOR     R8, R8, R9
    ;;compute MASKING_ORDER-i
    RSB     R11, R12, #MASKING_ORDER
    ;; rotation of a by i
    AND     R10, R8, R1, LSL R12
    LSR     R1, R1, R11
    BIC     R1, R1, R8
    EOR     R1, R10, R1
    ;;  s ^= a AND rot(b,d/2)
    AND     R9, R0, R1
    EOR     R6, R9

    ;; ------------------------------------------------------------------------
    ;; return s

    STR     R6, [R2]
    
    pop{R14}
    BX LR
    LTORG
