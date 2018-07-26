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



    AREA    bbpptv_unrolled_code, CODE, READONLY


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BBPPTV MULTIPLICATION MACROS                        ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ;; ------------------------------------------------------------------------
    ;; Compute \alpha and xor it to an accumulator

    MACRO
    compute_alpha_and_xor $res, $tmp_a, $tmp_b, $addr_a, $addr_b, $i, $j
    LDR $tmp_a, [$addr_a, #$i]
    LDR $tmp_b, [$addr_b, #$j]
    AND $tmp_a, $tmp_b
    EOR $res, $tmp_a
    LDR $tmp_a, [$addr_a, #$j]
    LDR $tmp_b, [$addr_b, #$i]  
    AND $tmp_a, $tmp_b
    EOR $res, $tmp_a
    MEND
    
    
    ;; ------------------------------------------------------------------------
    ;; Compute two rounds of c_i = a_i AND b_i 

    MACRO
    inner_loop1 $addr_a, $addr_b, $addr_c, $addr_rand, $addr_randtable, $tmp_a, $tmp_b, $tmp_c, $tmp_rand, $i, $j
    ;; j = i+1
    ;; computing c_i = a_i*b_i and generating the s_i
    ;; s <- F
    get_random $tmp_rand, $addr_rand
    STR     $tmp_rand, [$addr_randtable, #$i]
    ;; c_i = a_i * b_i
    LDR     $tmp_a, [$addr_a,#$i] 
    LDR     $tmp_b, [$addr_b,#$i] 
    AND     $tmp_c, $tmp_a, $tmp_b
    STR     $tmp_c, [$addr_c,#$i]
    ;; c_i+1 = a_i+1 * b_i+1
    LDR     $tmp_a, [$addr_a,#$j] 
    LDR     $tmp_b, [$addr_b,#$j] 
    AND     $tmp_c, $tmp_a, $tmp_b
    STR     $tmp_c, [$addr_c,#$j]
    MEND


    ;; ------------------------------------------------------------------------
    ;; Compute the cross products in the inner loop 

    MACRO
    inner_looprow $addr_a, $addr_b, $addr_c, $addr_rand, $addr_randtable, $tmp_a, $tmp_b, $tmp_c, $c_i, $tmp_rand, $i, $j, $k
    ;; k = j-1
    ;; c_j = c_j + r    
    get_random $tmp_rand, $addr_rand
    LDR     $tmp_c, [$addr_c, #$j]
    EOR     $tmp_c, $tmp_rand
    STR     $tmp_c, [$addr_c, #$j]
    ;; c_i = c_i + r
    EOR     $c_i, $tmp_rand
    ;; c_i = c_i + \alpha_i,j
    compute_alpha_and_xor $c_i,$tmp_a,$tmp_b,$addr_a,$addr_b,$i,$j
    ;; c_i = c_i + s_j-1
    LDR     $tmp_rand, [$addr_randtable, #$k]
    EOR     $c_i, $tmp_rand 
    ;; c_i = c_i + \alpha_i,j-1
    compute_alpha_and_xor $c_i, $tmp_a, $tmp_b, $addr_a, $addr_b, $i, $k
    MEND
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BBPPTV MULTIPLICATION FUNCTION                      ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



unrolled_bbpptv_mult

    ;; ------------------------------------------------------------------------
    ;; Init phase 

    LDR     R7, =RNGTab


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;     UNROLLED BBPPTV : D=2     ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    IF MASKING_ORDER = 2

    get_random R3, R7
    ;;c_1 = a_1 * b_1
    LDR     R4, [R0,#0] 
    LDR     R5, [R1,#0]
    AND     R6, R4, R5
    ;;c_2 = a_2 * b_2
    LDR     R8, [R0,#4] 
    LDR     R9, [R1,#4]
    AND     R10, R8, R9
    ;;c_1 = c_1 + r
    EOR     R6, R6, R3
    ;;c_2 = c_2 + r
    EOR     R10, R10, R3
    STR     R10, [R2, #4]
    ;; c_1 = c_1 + a_1 * b_2
    AND     R10, R4, R9
    EOR     R6, R6, R10
    ;; c_1 = c_1 + a_2 * b_a
    AND     R10, R5, R8
    EOR     R6, R6, R10
    STR     R6, [R2, #0]
    
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;     UNROLLED BBPPTV : D=4     ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    

    ELIF MASKING_ORDER = 4

    get_random R3, R7 ;; r_0
    get_random R4, R7 ;; r_1
    get_random R5, R7 ;; r_2
    get_random R6, R7 ;; r_3
    
    LDR     R8, [R0, #0]
    LDR     R9, [R1, #0]
    AND     R10, R8, R9
    EOR     R10, R10, R3
    compute_alpha_and_xor R10, R8, R9, R0, R1, 0, 12
    EOR     R10, R10, R4
    compute_alpha_and_xor R10, R8, R9, R0, R1, 0, 8
    STR     R10, [R2, #0]
    
    LDR     R8, [R0, #4]
    LDR     R9, [R1, #4]
    AND     R10, R8, R9
    EOR     R10, R10, R5
    compute_alpha_and_xor R10, R8, R9, R0, R1, 4, 12
    EOR     R10, R10, R4
    compute_alpha_and_xor R10, R8, R9, R0, R1, 4, 8
    STR     R10, [R2, #4]
    
    LDR     R8, [R0, #8]
    LDR     R9, [R1, #8]
    AND     R10, R8, R9
    EOR     R10, R10, R6
    compute_alpha_and_xor R10, R8, R9, R0, R1, 8, 12
    STR     R10, [R2, #8]
    
    LDR     R8, [R0, #12]
    LDR     R9, [R1, #12]
    AND     R10, R8, R9
    EOR     R10, R10, R6
    EOR     R10, R10, R5
    EOR     R10, R10, R4
    compute_alpha_and_xor R10, R8, R9, R0, R1, 4, 0
    STR     R10, [R2, #12]


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;     UNROLLED BBPPTV : D=8     ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    

    ELIF MASKING_ORDER = 8

    LDR     R10, =randTable  ;; Table for the s
    
    ;; ------------------------------------------------------------------------
    ;; loop for a_i AND b_i

    ;;c_1 = a_1 * b_1
    LDR     R4, [R0,#0] 
    LDR     R5, [R1,#0]
    AND     R6, R4, R5
    STR     R6, [R2, #0]
    ;;c_2 = a_2 * b_2
    LDR     R4, [R0,#4] 
    LDR     R5, [R1,#4]
    AND     R6, R4, R5
    STR     R6, [R2, #4]
    ;;first loop
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 8, 12
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 16, 20
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 24, 28
    

    ;; ------------------------------------------------------------------------
    ;; inner loop for cross products computation

    ;;second loop
    ;; i = 1
    LDR     R8, [R2, #0]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 20, 16
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 12, 8
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 0, 4
    STR     R8, [R2, #0]
    LDR     R8, [R2, #4]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 20, 16
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 12, 8
    EOR     R8, R8, R3
    STR     R8, [R2, #4]
    ;; i = 3
    LDR     R8, [R2, #8]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 20, 16
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 8, 12
    STR     R8, [R2, #8]
    LDR     R8, [R2, #12]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 20, 16
    EOR     R8, R8, R3
    STR     R8, [R2, #12]
    ;; i = 5
    LDR     R8, [R2, #16]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 28, 24
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 16, 20
    STR     R8, [R2, #16]
    LDR     R8, [R2, #20]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 28, 24
    EOR     R8, R8, R3
    STR     R8, [R2, #20]
    ;; i = 7
    LDR     R8, [R2, #24]
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 24, 28
    STR     R8, [R2, #24]
    LDR     R8, [R2, #28]
    EOR     R8, R8, R3
    STR     R8, [R2, #28]


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;     UNROLLED BBPPTV : D=16    ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    ELIF MASKING_ORDER = 16
    
    LDR        R10, =randTable  ;; Table for the s

    ;; ------------------------------------------------------------------------
    ;; loop for a_i AND b_i
    
    ;;c_1 = a_1 * b_1
    LDR        R4, [R0,#0]
    LDR        R5, [R1,#0]
    AND     R6, R4, R5
    STR        R6, [R2, #0]
    ;;c_2 = a_2 * b_2
    LDR        R4, [R0,#4]
    LDR        R5, [R1,#4]
    AND     R6, R4, R5
    STR        R6, [R2, #4]
    ;;first loop
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 8, 12
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 16, 20
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 24, 28
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 32, 36
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 40, 44
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 48, 52
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 56, 60
    
    ;; ------------------------------------------------------------------------
    ;; inner loop for cross products computation

    ;;second loop
    ;; i = 1
    LDR     R8, [R2, #0]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 20, 16
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 12, 8
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 0, 4
    STR        R8, [R2, #0]
    LDR        R8, [R2, #4]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 20, 16
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 12, 8
    EOR     R8, R8, R3
    STR        R8, [R2, #4]
    B ignore2
    LTORG
ignore2
    ;; i = 3
    LDR     R8, [R2, #8]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 20, 16
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 8, 12
    STR        R8, [R2, #8]
    LDR        R8, [R2, #12]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 20, 16
    EOR     R8, R8, R3
    STR        R8, [R2, #12]
    ;; i = 5
    LDR     R8, [R2, #16]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 28, 24
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 16, 20
    STR        R8, [R2, #16]
    LDR        R8, [R2, #20]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 28, 24
    EOR     R8, R8, R3
    STR        R8, [R2, #20]
    ;; i = 7
    LDR     R8, [R2, #24]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 36, 32
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 24, 28
    STR        R8, [R2, #24]
    LDR        R8, [R2, #28]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 36, 32
    EOR     R8, R8, R3
    STR        R8, [R2, #28]
    ;; i = 9
    LDR     R8, [R2, #32]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 44, 40
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 32, 36
    STR        R8, [R2, #32]
    LDR        R8, [R2, #36]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 44, 40
    EOR     R8, R8, R3
    STR        R8, [R2, #36]
    ;; i = 11
    LDR     R8, [R2, #40]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 52, 48
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 40, 44
    STR        R8, [R2, #40]
    LDR        R8, [R2, #44]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 52, 48
    EOR     R8, R8, R3
    STR        R8, [R2, #44]
    ;; i = 13
    LDR     R8, [R2, #48]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 48, 60, 56
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 48, 52
    STR        R8, [R2, #48]
    LDR        R8, [R2, #52]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 52, 60, 56
    EOR     R8, R8, R3
    STR        R8, [R2, #52]
    ;; i = 15
    LDR     R8, [R2, #56]
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 56, 60
    STR        R8, [R2, #56]
    LDR        R8, [R2, #60]
    EOR     R8, R8, R3
    STR        R8, [R2, #60]


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;       UNROLLED ISW : D=32     ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    ELIF    MASKING_ORDER = 32
    
    LDR     R10, =randTable  ;; Table for the s
    
    ;; ------------------------------------------------------------------------
    ;; loop for a_i AND b_i

    ;;c_1 = a_1 * b_1
    LDR     R4, [R0,#0] 
    LDR     R5, [R1,#0]
    AND     R6, R4, R5
    STR     R6, [R2, #0]
    ;;c_2 = a_2 * b_2
    LDR     R4, [R0,#4] 
    LDR     R5, [R1,#4]
    AND     R6, R4, R5
    STR     R6, [R2, #4]
    ;;first loop
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 8, 12
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 16, 20
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 24, 28
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 32, 36
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 40, 44
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 48, 52
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 56, 60
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 64, 68
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 72, 76
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 80, 84
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 88, 92
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 96, 100
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 104, 108
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 112, 116
    inner_loop1 R0, R1, R2, R7, R10, R4, R5, R6, R3, 120, 124
    

    ;; ------------------------------------------------------------------------
    ;; inner loop for cross products computation

    ;;second loop
    ;; i = 1
    LDR     R8, [R2, #0]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 20, 16
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 0, 12, 8
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 0, 4
    STR     R8, [R2, #0]
    LDR     R8, [R2, #4]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 20, 16
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 4, 12, 8
    EOR     R8, R8, R3
    STR     R8, [R2, #4]
    B ignore1
    LTORG
ignore1 
    ;; i = 3
    LDR     R8, [R2, #8]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 8, 20, 16
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 8, 12
    STR     R8, [R2, #8]
    LDR     R8, [R2, #12]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 28, 24
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 12, 20, 16
    EOR     R8, R8, R3
    STR     R8, [R2, #12]
    ;; i = 5
    LDR     R8, [R2, #16]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 16, 28, 24
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 16, 20
    STR     R8, [R2, #16]
    LDR     R8, [R2, #20]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 36, 32
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 20, 28, 24
    EOR     R8, R8, R3
    STR     R8, [R2, #20]
    ;; i = 7
    LDR     R8, [R2, #24]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 24, 36, 32
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 24, 28
    STR     R8, [R2, #24]
    LDR     R8, [R2, #28]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 44, 40
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 28, 36, 32
    EOR     R8, R8, R3
    STR     R8, [R2, #28]
    ;; i = 9
    LDR     R8, [R2, #32]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 32, 44, 40
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 32, 36
    STR     R8, [R2, #32]
    LDR     R8, [R2, #36]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 52, 48
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 36, 44, 40
    EOR     R8, R8, R3
    STR     R8, [R2, #36]
    B ignore2
    LTORG
ignore2
    ;; i = 11
    LDR     R8, [R2, #40]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 40, 52, 48
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 40, 44
    STR     R8, [R2, #40]
    LDR     R8, [R2, #44]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 60, 56
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 44, 52, 48
    EOR     R8, R8, R3
    STR     R8, [R2, #44]
    ;; i = 13
    LDR     R8, [R2, #48]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 48, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 48, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 48, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 48, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 48, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 48, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 48, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 48, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 48, 60, 56
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 48, 52
    STR     R8, [R2, #48]
    LDR     R8, [R2, #52]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 52, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 52, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 52, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 52, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 52, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 52, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 52, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 52, 68, 64
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 52, 60, 56
    EOR     R8, R8, R3
    STR     R8, [R2, #52]
    ;; i = 15
    LDR     R8, [R2, #56]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 56, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 56, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 56, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 56, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 56, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 56, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 56, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 56, 68, 64
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 56, 60
    STR     R8, [R2, #56]
    LDR     R8, [R2, #60]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 60, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 60, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 60, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 60, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 60, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 60, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 60, 76, 72
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 60, 68, 64
    EOR     R8, R8, R3
    STR     R8, [R2, #60]
    ;; i = 17
    LDR     R8, [R2, #64]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 64, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 64, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 64, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 64, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 64, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 64, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 64, 76, 72
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 64, 68
    STR     R8, [R2, #64]
    LDR     R8, [R2, #68]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 68, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 68, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 68, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 68, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 68, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 68, 84, 80
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 68, 76, 72
    EOR     R8, R8, R3
    STR     R8, [R2, #68]
    ;; i = 19
    LDR     R8, [R2, #72]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 72, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 72, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 72, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 72, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 72, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 72, 84, 80
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 72, 76
    STR     R8, [R2, #72]
    LDR     R8, [R2, #76]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 76, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 76, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 76, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 76, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 76, 92, 88
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 76, 84, 80
    EOR     R8, R8, R3
    STR     R8, [R2, #76]
    ;; i = 21
    LDR     R8, [R2, #80]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 80, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 80, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 80, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 80, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 80, 92, 88
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 80, 84
    STR     R8, [R2, #80]
    LDR     R8, [R2, #84]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 84, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 84, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 84, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 84, 100, 96
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 84, 92, 88
    EOR     R8, R8, R3
    STR     R8, [R2, #84]
    B ignore3
    LTORG
ignore3
    ;; i = 23
    LDR     R8, [R2, #88]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 88, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 88, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 88, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 88, 100, 96
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 88, 92
    STR     R8, [R2, #88]
    LDR     R8, [R2, #92]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 92, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 92, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 92, 108, 104
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 92, 100, 96
    EOR     R8, R8, R3
    STR     R8, [R2, #92]
    ;; i = 25
    LDR     R8, [R2, #96]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 96, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 96, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 96, 108, 104
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 96, 100
    STR     R8, [R2, #96]
    LDR     R8, [R2, #100]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 100, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 100, 116, 112
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 100, 108, 104
    EOR     R8, R8, R3
    STR     R8, [R2, #100]
    ;; i = 27
    LDR     R8, [R2, #104]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 104, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 104, 116, 112
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 104, 108
    STR     R8, [R2, #104]
    LDR     R8, [R2, #108]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 108, 124, 120
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 108, 116, 112
    EOR     R8, R8, R3
    STR     R8, [R2, #108]
    ;; i = 29
    LDR     R8, [R2, #112]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 112, 124, 120
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 112, 116
    STR     R8, [R2, #112]
    LDR     R8, [R2, #116]
    inner_looprow R0, R1, R2, R7, R10, R4, R5, R6, R8, R9, 116, 124, 120
    EOR     R8, R8, R3
    STR     R8, [R2, #116]
    ;; i = 31
    LDR     R8, [R2, #120]
    get_random R3, R7
    EOR     R8, R8, R3
    compute_alpha_and_xor R8, R4, R5, R0, R1, 120, 124
    STR     R8, [R2, #120]
    LDR     R8, [R2, #124]
    EOR     R8, R8, R3
    STR     R8, [R2, #124]
    
    ENDIF
    
    BX LR
    LTORG


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                 RANDOM TABLE USED FOR BBPPTV MULTIPLICATION               ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    AREA    bbpptv_data, DATA, READWRITE
randTable   % 4*MASKING_ORDER
