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
 * Authors: Dahmun Goudarzi, Anthony Journault, Matthieu Rivain and François-
 * Xavier Standaert 
 *
 */



    AREA    bbpptv_code, CODE, READONLY


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BBPPTV MULTIPLICATION MACROS                        ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    ;; ------------------------------------------------------------------------
    ;; Compute \alpha and xor it to an accumulator

    MACRO
    compute_alpha_and_xor $res, $tmp_a, $tmp_b, $addr_a, $addr_b, $i, $j
    LDR $tmp_a, [$addr_a, $i, LSL #2]
    LDR $tmp_b, [$addr_b, $j, LSL #2]
    AND $tmp_a, $tmp_b
    EOR $res, $tmp_a
    LDR $tmp_a, [$addr_a, $j, LSL #2]
    LDR $tmp_b, [$addr_b, $i, LSL #2]   
    AND $tmp_a, $tmp_b
    EOR $res, $tmp_a
    MEND


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BBPPTV MULTIPLICATION FUNCTION                      ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
original_bbpptv_mult

    ;; ------------------------------------------------------------------------
    ;; Init phase 

    LDR     R7, =RNGTab
    ;; Table of the form [r | s] storing the random r and s 
    LDR     R10, =randTable  
    
    ;; ------------------------------------------------------------------------
    ;; Creating the s_i

    MOV     R12, #(MASKING_ORDER-2)
loopScreation
    get_random R3, R7
    ADD     R4, R10, #(MASKING_ORDER<<1)*4
    STR     R3, [R4, R12, LSL #2]
    
    SUBS    R12, #2
    BNE     loopScreation
    
    ;; ------------------------------------------------------------------------
    ;; Cross products computation 

    MOV     R12, #0
loopOverSharesBBPPTV
    ;; c_i = alpha_i,i
    LDR     R4, [R0,R12, LSL #2] 
    LDR     R5, [R1,R12, LSL #2] 
    AND     R8, R4, R5
    ;; nested loop
    MOV     R11, #(MASKING_ORDER-1)
loopNestedBBPPTV
    ADD     R4, R12, #2
    CMP     R4, R11
    BHI     noNestedLoops
    ;; t_ij += r_ij
    get_random R6, R7
    MOV     R5, #MASKING_ORDER
    MUL     R4, R5, R12
    ADD     R4, R11
    STR     R6, [R10, R4, LSL #2]
    ;; t_ij += \alpha_i,j
    compute_alpha_and_xor R6, R4, R5, R0, R1, R12, R11
    ;; t_ij += s_j-1
    SUB     R5, R11, #1 
    ADD     R4, R10, #(MASKING_ORDER<<1)*4
    LDR     R3, [R4, R5, LSL #2]
    EOR     R6, R3
    ;; t_ij += \alpha_i,j-1
    compute_alpha_and_xor R6, R4, R3, R0, R1, R12, R5
    ;; c_i += t_ij
    EOR     R8, R6
    ;; loop nested processing
    SUB     R11, #2
    B       loopNestedBBPPTV
noNestedLoops
    
    ;; ------------------------------------------------------------------------
    ;; Randomness correction 

    ;; Comparison test between i and d mod 2 to enter (or not) the correction
    MOV     R4, #((MASKING_ORDER-1)<<31)
    CMP     R4, R12, LSL #31
    BNE     noCorrectionRIJ
    ;; Case where i and d mod 2 have same parity
    SUBS    R11, R12, #1
    BMI     endOfCorrection
loopOverCorrectionRJI
    ;; c_i = c_i + r_ji
    MOV     R5, #MASKING_ORDER
    MUL     R4, R5, R11
    ADD     R4, R12
    LDR     R3, [R10, R4, LSL #2]
    EOR     R8, R3
    ;; loop over correction of rij processing
    SUBS    R11, #1
    BPL     loopOverCorrectionRJI
    B       endOfCorrection
noCorrectionRIJ
    ;; Case where i and d mod 2 have different parity
    ADD     R11, R12, #1
    ;; t_ii+1 += r_ii+1
    get_random R6, R7
    MOV     R5, #MASKING_ORDER
    MUL     R4, R5, R12
    ADD     R4, R11
    STR     R6, [R10, R4, LSL #2]
    ;; t_ii+1 += \alpha_i,i+1
    compute_alpha_and_xor R6, R4, R5, R0, R1, R12, R11
    ;; c_i += t_ii+1
    EOR     R8, R6
endOfCorrection
    ;; Store the accumulator at each step i
    STR     R8, [R2, R12, LSL #2]
    ;; loop over shares processing
    ADD     R12, #1
    CMP     R12, #MASKING_ORDER
    BNE     loopOverSharesBBPPTV
    
    BX LR
    LTORG


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                 RANDOM TABLE USED FOR BBPPTV MULTIPLICATION               ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    AREA    bbpptv_data, DATA, READWRITE
randTable   % 4*((MASKING_ORDER)*(MASKING_ORDER)+ MASKING_ORDER)

