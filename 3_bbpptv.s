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


    ;; ------------------------------------------------------------------------
    ;; Compute the loop row procedure as defined in the paper
    
    MACRO
$label  loop_row $c_i, $c_j, $tmp, $tmp_a, $tmp_b, $rnd, $addr_trng, $addr_rnd, $addr_a, $addr_b, $addr_c, $i, $j, $t
    MOV     $j, #(MASKING_ORDER-1)
$label.loopRow
    ;; loop condition processing 
    ADD     $tmp, $i, #$t
    CMP     $tmp, $j
    BHI     $label.noNestedLoops
    ;; c_i = c_i + r
    get_random $rnd, $addr_trng
    EOR     $c_i, $rnd
    ;; c_j = c_j + r    
    LDR     $c_j, [$addr_c, $j, LSL #2]
    EOR     $c_j, $rnd
    STR     $c_j, [$addr_c, $j, LSL #2]
    ;; c_i = c_i + \alpha_i,j
    compute_alpha_and_xor $c_i,$tmp_a,$tmp_b,$addr_a,$addr_b,$i,$j
    ;; c_i = c_i + s_j-1
    SUB     $j, #1
    LDR     $rnd, [$addr_rnd, $j, LSL #2]
    EOR     $c_i, $rnd 
    ;; c_i = c_i + \alpha_i,j-1
    compute_alpha_and_xor $c_i,$tmp_a,$tmp_b,$addr_a,$addr_b,$i,$j
    ;; loop processing
    SUB     $j, #1
    B       $label.loopRow
$label.noNestedLoops
    MEND
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BBPPTV MULTIPLICATION FUNCTION                      ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


bbpptv_mult

    ;; ------------------------------------------------------------------------
    ;; Init phase 

    LDR     R7, =RNGReg
    LDR     R10, =randTable  ;; Table for the s
    
    ;; ------------------------------------------------------------------------
    ;;  computing c_i = a_i*b_i and generating the s_i

    MOV     R12, #0
loopCScreation
    ;; s <- F
    get_random R3, R7
    STR     R3, [R10, R12, LSL #2]
    ;; c_i = a_i * b_i
    LDR     R4, [R0,R12, LSL #2] 
    LDR     R5, [R1,R12, LSL #2] 
    AND     R8, R4, R5
    STR     R8, [R2,R12, LSL #2]
    ;; c_i+1 = a_i+1 * b_i+1
    ADD     R12, #1
    LDR     R4, [R0,R12, LSL #2] 
    LDR     R5, [R1,R12, LSL #2] 
    AND     R8, R4, R5
    STR     R8, [R2,R12, LSL #2]
    ;; loop processing 
    ADD     R12, #1
    CMP     R12, #MASKING_ORDER
    BNE     loopCScreation
    
    ;; ------------------------------------------------------------------------
    ;; computing cross products loop composed of 2 loop row calls
    
    MOV     R12, #0
loopBBPPTV
    ;; loop row i,i+3
    LDR     R8, [R2, R12, LSL #2]
lr1 loop_row R8,R4,R5,R4,R5,R5,R7,R10,R0,R1,R2,R12,R9,3
    ;; c_i = c_i + \alpha_i,i+1
    ADD     R11, R12, #1
    compute_alpha_and_xor R8,R4,R5,R0,R1,R12,R11
    get_random R3, R7
    EOR     R8, R3
    STR     R8, [R2, R12, LSL #2]
    ;; loop row i+1,i+3
    LDR     R8, [R2, R11, LSL #2]
lr2 loop_row R8,R4,R5,R4,R5,R5,R7,R10,R0,R1,R2,R11,R9,2
    ;; c_i+1 = c_i+1 + r_i,i+1
    EOR     R8, R3
    STR     R8, [R2, R11, LSL #2]
    ;; loop processing
    ADD     R12, #2
    CMP     R12, #MASKING_ORDER
    BNE     loopBBPPTV
    
    BX LR
    LTORG


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                 RANDOM TABLE USED FOR BBPPTV MULTIPLICATION               ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    AREA    bbpptv_data, DATA, READWRITE
randTable   % 4*MASKING_ORDER

