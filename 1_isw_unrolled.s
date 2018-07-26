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



    AREA    isw_unrolled_code, CODE, READONLY


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                        ISW MULTIPLICATION MACROS                          ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;    Nested loop computation    ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    MACRO
    computation_crossed $addr_a, $addr_b, $addr_c, $addr_rand, $tmp_a, $tmp_b, $tmp_c, $tmp_rand, $i, $j
    get_random $tmp_rand,$addr_rand
    ;; c_i += s
    LDR     $tmp_c, [$addr_c, #$i]
    EOR     $tmp_c, $tmp_rand
    STR     $tmp_c, [$addr_c, #$i]
    ;; s' += a_i AND b_j
    LDR     $tmp_a, [$addr_a, #$i] 
    LDR     $tmp_b, [$addr_b, #$j]
    AND     $tmp_c, $tmp_a, $tmp_b
    EOR     $tmp_rand, $tmp_c
    ;; s' += a_j AND b_i
    LDR     $tmp_a, [$addr_a, #$j] 
    LDR     $tmp_b, [$addr_b, #$i] 
    AND     $tmp_c, $tmp_a, $tmp_b
    EOR     $tmp_rand, $tmp_c
    ;; c_j += s'
    LDR     $tmp_c, [$addr_c, #$j]
    EOR     $tmp_c, $tmp_rand
    STR     $tmp_c, [$addr_c, #$j]
    MEND

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;    First loop computation     ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    MACRO
    computation_aibi $addr_a, $addr_b, $addr_c, $tmp_a, $tmp_b, $tmp_c, $i
    LDR     $tmp_a, [$addr_a, #$i]
    LDR     $tmp_b, [$addr_b, #$i]
    AND     $tmp_c, $tmp_a, $tmp_b
    STR     $tmp_c, [$addr_c, #$i]
    MEND



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                        ISW MULTIPLICATION FUNCTION                        ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


unrolled_isw_mult

    ;; ------------------------------------------------------------------------
    ;; init phase
    LDR     R7, =RNGTab


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;       UNROLLED ISW : D=2      ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    IF      MASKING_ORDER = 2

    ;; loop for a_i AND b_i
    computation_aibi R0, R1, R2, R4, R5, R6, 0
    computation_aibi R0, R1, R2, R4, R5, R6, 4
    ;; inner loop for cross products computation
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 4


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;       UNROLLED ISW : D=4      ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        
    ELIF    MASKING_ORDER = 4

    ;; ------------------------------------------------------------------------
    ;; loop for a_i AND b_i

    computation_aibi R0, R1, R2, R4, R5, R6, 0
    computation_aibi R0, R1, R2, R4, R5, R6, 4
    computation_aibi R0, R1, R2, R4, R5, R6, 8
    computation_aibi R0, R1, R2, R4, R5, R6, 12

    ;; ------------------------------------------------------------------------
    ;; inner loop for cross products computation

    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 4
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 8
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 8
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 12


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;       UNROLLED ISW : D=8      ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        
    ELIF    MASKING_ORDER = 8

    ;; ------------------------------------------------------------------------
    ;; loop for a_i AND b_i

    computation_aibi R0, R1, R2, R4, R5, R6, 0
    computation_aibi R0, R1, R2, R4, R5, R6, 4
    computation_aibi R0, R1, R2, R4, R5, R6, 8
    computation_aibi R0, R1, R2, R4, R5, R6, 12
    computation_aibi R0, R1, R2, R4, R5, R6, 16
    computation_aibi R0, R1, R2, R4, R5, R6, 20
    computation_aibi R0, R1, R2, R4, R5, R6, 24
    computation_aibi R0, R1, R2, R4, R5, R6, 28

    ;; ------------------------------------------------------------------------
    ;; inner loop for cross products computation

    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 4
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 8
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 8
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 28


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;       UNROLLED ISW : D=16     ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    ELIF    MASKING_ORDER = 16

    ;; ------------------------------------------------------------------------
    ;; loop for a_i AND b_i

    computation_aibi R0, R1, R2, R4, R5, R6, 0
    computation_aibi R0, R1, R2, R4, R5, R6, 4
    computation_aibi R0, R1, R2, R4, R5, R6, 8
    computation_aibi R0, R1, R2, R4, R5, R6, 12
    computation_aibi R0, R1, R2, R4, R5, R6, 16
    computation_aibi R0, R1, R2, R4, R5, R6, 20
    computation_aibi R0, R1, R2, R4, R5, R6, 24
    computation_aibi R0, R1, R2, R4, R5, R6, 28
    computation_aibi R0, R1, R2, R4, R5, R6, 32
    computation_aibi R0, R1, R2, R4, R5, R6, 36
    computation_aibi R0, R1, R2, R4, R5, R6, 40
    computation_aibi R0, R1, R2, R4, R5, R6, 44
    computation_aibi R0, R1, R2, R4, R5, R6, 48
    computation_aibi R0, R1, R2, R4, R5, R6, 52
    computation_aibi R0, R1, R2, R4, R5, R6, 56
    computation_aibi R0, R1, R2, R4, R5, R6, 60

    ;; ------------------------------------------------------------------------
    ;; inner loop for cross products computation

    ;;i=1
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 4
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 8
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 60
    ;;i=2
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 8
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 60
    ;;i=3
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 60
    ;;i=4
    B ignore1
    LTORG
ignore1
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 60
    ;;i=5
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 60
    ;;i=6
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 60
    ;;i=7
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 60
    ;;i=8
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 60
    ;;ii=9
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 60
    ;;ii=10
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 60
    ;;ii=11
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 60
    ;;ii=12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 60
    ;;ii=13
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 60
    ;;ii=14
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 60
    ;;ii=15
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 60


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;       UNROLLED ISW : D=32     ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    ELIF    MASKING_ORDER = 32

    ;; ------------------------------------------------------------------------
    ;; loop for a_1 AND b_i

    computation_aibi R0, R1, R2, R4, R5, R6, 0
    computation_aibi R0, R1, R2, R4, R5, R6, 4
    computation_aibi R0, R1, R2, R4, R5, R6, 8
    computation_aibi R0, R1, R2, R4, R5, R6, 12
    computation_aibi R0, R1, R2, R4, R5, R6, 16
    computation_aibi R0, R1, R2, R4, R5, R6, 20
    computation_aibi R0, R1, R2, R4, R5, R6, 24
    computation_aibi R0, R1, R2, R4, R5, R6, 28
    computation_aibi R0, R1, R2, R4, R5, R6, 32
    computation_aibi R0, R1, R2, R4, R5, R6, 36
    computation_aibi R0, R1, R2, R4, R5, R6, 40
    computation_aibi R0, R1, R2, R4, R5, R6, 44
    computation_aibi R0, R1, R2, R4, R5, R6, 48
    computation_aibi R0, R1, R2, R4, R5, R6, 52
    computation_aibi R0, R1, R2, R4, R5, R6, 56
    computation_aibi R0, R1, R2, R4, R5, R6, 60
    computation_aibi R0, R1, R2, R4, R5, R6, 64
    computation_aibi R0, R1, R2, R4, R5, R6, 68
    computation_aibi R0, R1, R2, R4, R5, R6, 72
    computation_aibi R0, R1, R2, R4, R5, R6, 76
    computation_aibi R0, R1, R2, R4, R5, R6, 80
    computation_aibi R0, R1, R2, R4, R5, R6, 84
    computation_aibi R0, R1, R2, R4, R5, R6, 88
    computation_aibi R0, R1, R2, R4, R5, R6, 92
    computation_aibi R0, R1, R2, R4, R5, R6, 96
    computation_aibi R0, R1, R2, R4, R5, R6, 100
    computation_aibi R0, R1, R2, R4, R5, R6, 104
    computation_aibi R0, R1, R2, R4, R5, R6, 108
    computation_aibi R0, R1, R2, R4, R5, R6, 112
    computation_aibi R0, R1, R2, R4, R5, R6, 116
    computation_aibi R0, R1, R2, R4, R5, R6, 120
    computation_aibi R0, R1, R2, R4, R5, R6, 124
    
    ;; ------------------------------------------------------------------------
    ;; inner loop for cross products computation

    ;;i=1
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 4
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 8
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 0, 124
    
    B ignore1
    LTORG
ignore1
    
    ;;i=2
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 8
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 4, 124
    ;;i=3
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 8, 124
    ;;i=4
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 12, 124
    
    B ignore2
    LTORG
ignore2
    
    ;;i=5
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 16, 124
    ;;i=6
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 20, 124
    ;;i=7
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 24, 124
    ;;i=8
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 32
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 28, 124
    
    B ignore3
    LTORG
ignore3
    
    ;;i=9
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 36
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 32, 124
    ;;i=10
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 40
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 36, 124
    ;;i=11
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 44
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 40, 124
    ;;i=12
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 48
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 44, 124
    ;;i=13
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 52
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 48, 124
    ;;i=14
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 56
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 52, 124
    ;;i=15
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 60
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 56, 124
    ;;i=16
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 64
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 60, 124
    ;;i=17
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 68
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 64, 124
    ;;i=18
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 72
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 68, 124
    ;;i=19
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 76
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 72, 124
    ;;i=20
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 80
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 76, 124
    ;;i=21
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 80, 84
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 80, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 80, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 80, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 80, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 80, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 80, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 80, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 80, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 80, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 80, 124
    ;;i=22
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 84, 88
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 84, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 84, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 84, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 84, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 84, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 84, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 84, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 84, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 84, 124
    ;;i=23
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 88, 92
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 88, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 88, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 88, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 88, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 88, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 88, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 88, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 88, 124
    ;;i=24
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 92, 96
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 92, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 92, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 92, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 92, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 92, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 92, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 92, 124
    ;;i=25
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 96, 100
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 96, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 96, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 96, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 96, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 96, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 96, 124
    ;;i=26
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 100, 104
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 100, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 100, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 100, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 100, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 100, 124
    ;;i=27
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 104, 108
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 104, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 104, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 104, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 104, 124
    ;;i=28
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 108, 112
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 108, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 108, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 108, 124
    ;;i=29
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 112, 116
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 112, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 112, 124
    ;;i=30
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 116, 120
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 116, 124
    ;;i=31
    computation_crossed R0, R1, R2, R7, R4, R5, R6, R3, 120, 124

    
    ENDIF
        
    BX LR
    LTORG
