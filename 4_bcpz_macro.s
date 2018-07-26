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



    AREA    bcpz_mult_code, CODE, READONLY
    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BBPPTV MULTIPLICATION MACROS                        ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ;; ------------------------------------------------------------------------
    ;; Compute mat mult procedure for the case d = 2 (terminal case)

    MACRO
    rec_mat_mult_d2 $x_1, $x_2, $y_1, $y_2, $tmp,  $addr_x, $addr_y, $addr_m, $shift_m, $i, $j
    IF      MASKING_ORDER = 2
    
    LDR     $x_1, [$addr_x], #4
    LDR     $x_2, [$addr_x], #-4    
    LDR     $y_1, [$addr_y], #4
    LDR     $y_2, [$addr_y], #-4    
    AND     $tmp, $x_1, $y_1
    STR     $tmp, [$addr_m], #4
    AND     $tmp, $x_1, $y_2
    STR     $tmp, [$addr_m], #4
    AND     $tmp, $x_2, $y_1
    STR     $tmp, [$addr_m], #4
    AND     $tmp, $x_2, $y_2
    STR     $tmp, [$addr_m], #-12
    
    ;; ------------------------------------------------------------------------
    ;; Compute mat mult procedure for the case d > 2 (induction case)

    ELSE
    ;; shift_m set to get Mij
    MOV     $tmp, #MASKING_ORDER
    MOV     $shift_m, #$i
    MUL     $shift_m, $tmp, $shift_m
    ADD     $shift_m, #$j
    ;;
    LDR     $x_1, [$addr_x], #4
    LDR     $x_2, [$addr_x], #-4    
    LDR     $y_1, [$addr_y], #4
    LDR     $y_2, [$addr_y], #-4    
    AND     $tmp, $x_1, $y_1
    STR     $tmp, [$addr_m, $shift_m, LSL #2]
    AND     $tmp, $x_1, $y_2
    ADD     $shift_m, #1
    STR     $tmp, [$addr_m, $shift_m, LSL #2]
    ;; shift_m set to get Mi+1j
    ADD     $shift_m, #(MASKING_ORDER-1)
    ;;
    AND     $tmp, $x_2, $y_1
    STR     $tmp, [$addr_m, $shift_m, LSL #2]
    AND     $tmp, $x_2, $y_2
    ADD     $shift_m, #1
    STR     $tmp, [$addr_m, $shift_m, LSL #2]
    
    ENDIF
    
    MEND

    ;; ------------------------------------------------------------------------
    ;; Generic refresh macro (any order) with WHILE procedure (copy of code)
    
    MACRO
    refresh $x_1, $x_2, $r, $addr_x, $addr_r, $d
    LDR     $x_1, [$addr_x], #4
    GBLA    refresh_cpt
refresh_cpt SETA 0
    WHILE   refresh_cpt<$d-1
    get_random $r, $addr_r
    LDR     $x_2, [$addr_x]     
    EOR     $x_1, $r
    EOR     $x_2, $r
    STR     $x_2, [$addr_x], #4
refresh_cpt SETA  refresh_cpt+1
    WEND
    SUB     $addr_x, #$d*4
    STR     $x_1, [$addr_x]
    MEND
    
    ;; ------------------------------------------------------------------------
    ;; Generic refresh macro (any order) with loops 

    MACRO
    loop_refresh $x_1, $x_2, $r, $addr_x, $addr_r, $cpt_loop
    LDR     $x_1, [$addr_x], #4
    MOV     $cpt_loop, #1
$label.loop_refresh
    get_random $r, $addr_r
    LDR     $x_2, [$addr_x]     
    EOR     $x_1, $r
    EOR     $x_2, $r
    STR     $x_2, [$addr_x], #4
    ADD     $cpt_loop, #1
    CMP     $cpt_loop, #(MASKING_ORDER>>1)
    BNE     $label.loop_refresh
    SUB     $addr_x, #(MASKING_ORDER>>1)*4
    STR     $x_1, [$addr_x]
    MEND


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;         MAT MULT D = 4        ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    MACRO
    rec_mat_mult_d4 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x, $stop_x, $start_y, $stop_y
    ;; M11 = X1 * Y1
    rec_mat_mult_d2 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $shift_m, $start_x, $start_y
    ;; Refresh X1,Y1
    refresh $x_1, $x_2, $tmp, $addr_x, $addr_r, 2
    refresh $y_1, $y_2, $tmp, $addr_y, $addr_r, 2
    ;; M12 = X1 * Y2
    ADD     $addr_y, #8
    rec_mat_mult_d2 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $shift_m, $start_x, $stop_y
    ;; M21 = X2 * Y1
    ADD     $addr_x, #8
    SUB     $addr_y, #8
    rec_mat_mult_d2 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $shift_m, $stop_x, $start_y
    ;; Refresh X2,Y2
    ADD     $addr_y, #8
    refresh $x_1, $x_2, $tmp, $addr_x, $addr_r, 2
    refresh $y_1, $y_2, $tmp, $addr_y, $addr_r, 2
    ;; M22 = X2 * Y2
    rec_mat_mult_d2 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $shift_m, $stop_x, $stop_y
    SUB     $addr_x, #8
    SUB     $addr_y, #8
    MEND
        

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;         MAT MULT D = 8        ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    MACRO
    rec_mat_mult_d8 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x1, $stop_x1, $start_x2, $stop_x2, $start_y1, $stop_y1, $start_y2, $stop_y2
    ;; M11 = X1 * Y1
    rec_mat_mult_d4 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x1, $stop_x1, $start_y1, $stop_y1
    ;; Refresh X1,Y1
    refresh $x_1, $x_2, $tmp, $addr_x, $addr_r, 4
    refresh $y_1, $y_2, $tmp, $addr_y, $addr_r, 4
    ;; M12 = X1 * Y2
    ADD     $addr_y, #16
    rec_mat_mult_d4 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x1, $stop_x1, $start_y2, $stop_y2
    ;; M21 = X2 * Y1
    ADD     $addr_x, #16
    SUB     $addr_y, #16
    rec_mat_mult_d4 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x2, $stop_x2, $start_y1, $stop_y1
    ;; Refresh X2,Y2
    ADD     $addr_y, #16
    refresh $x_1, $x_2, $tmp, $addr_x, $addr_r, 4
    refresh $y_1, $y_2, $tmp, $addr_y, $addr_r, 4
    ;; M22 = X2 * Y2
    rec_mat_mult_d4 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x2, $stop_x2, $start_y2, $stop_y2
    SUB     $addr_x, #16
    SUB     $addr_y, #16
    MEND
    

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;         MAT MULT D = 16       ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    MACRO
    rec_mat_mult_d16 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x11, $stop_x11, $start_x12, $stop_x12, $start_x21, $stop_x21, $start_x22, $stop_x22, $start_y11, $stop_y11, $start_y12, $stop_y12, $start_y21, $stop_y21, $start_y22, $stop_y22
    ;; M11 = X1 * Y1
    rec_mat_mult_d8 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x11, $stop_x11, $start_x12, $stop_x12, $start_y11, $stop_y11, $start_y12, $stop_y12
    ;; Refresh X1,Y1
    refresh $x_1, $x_2, $tmp, $addr_x, $addr_r, 8
    refresh $y_1, $y_2, $tmp, $addr_y, $addr_r, 8
    ;; M12 = X1 * Y2
    ADD     $addr_y, #32
    rec_mat_mult_d8 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x11, $stop_x11, $start_x12, $stop_x12, $start_y21, $stop_y21, $start_y22, $stop_y22
    ;; M21 = X2 * Y1
    ADD     $addr_x, #32
    SUB     $addr_y, #32
    rec_mat_mult_d8 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x21, $stop_x21, $start_x22, $stop_x22, $start_y11, $stop_y11, $start_y12, $stop_y12
    ;; Refresh X2,Y2
    ADD     $addr_y, #32
    refresh $x_1, $x_2, $tmp, $addr_x, $addr_r, 8
    refresh $y_1, $y_2, $tmp, $addr_y, $addr_r, 8
    ;; M22 = X2 * Y2
    rec_mat_mult_d8 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x21, $stop_x21, $start_x22, $stop_x22, $start_y21, $stop_y21, $start_y22, $stop_y22
    SUB     $addr_x, #32
    SUB     $addr_y, #32
    MEND
    

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;         MAT MULT D = 32       ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    MACRO
    rec_mat_mult_d32 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m
    ;; M11 = X1 * Y1
    rec_mat_mult_d16 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, 0, 2, 4, 6, 8, 10, 12, 14, 0, 2, 4, 6, 8, 10, 12, 14
    ;; Refresh X1,Y1
    refresh $x_1, $x_2, $tmp, $addr_x, $addr_r, 16
    refresh $y_1, $y_2, $tmp, $addr_y, $addr_r, 16
    ;; M12 = X1 * Y2
    ADD     $addr_y, #64
    rec_mat_mult_d16 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30
    ;; M21 = X2 * Y1
    ADD     $addr_x, #64
    SUB     $addr_y, #64
    rec_mat_mult_d16 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, 16, 18, 20, 22, 24, 26, 28, 30, 0, 2, 4, 6, 8, 10, 12, 14
    ;; Refresh X2,Y2
    ADD     $addr_y, #64
    refresh $x_1, $x_2, $tmp, $addr_x, $addr_r, 16
    refresh $y_1, $y_2, $tmp, $addr_y, $addr_r, 16
    ;; M22 = X2 * Y2
    rec_mat_mult_d16 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, 16, 18, 20, 22, 24, 26, 28, 30, 16, 18, 20, 22, 24, 26, 28, 30
    SUB     $addr_x, #64
    SUB     $addr_y, #64
    MEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BBPPTV MULTIPLICATION FUNCTION                      ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;  MAT MULT INDUCTION FUNCTION  ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mat_mult

    IF      MASKING_ORDER = 2
    rec_mat_mult_d2 R3,R4,R5,R6,R10,R0,R1,R8,R9,0,0
    ELIF    MASKING_ORDER = 4
    rec_mat_mult_d4 R3,R4,R5,R6,R10,R0,R1,R8,R7,R9,0,2,0,2
    ELIF    MASKING_ORDER = 8
    rec_mat_mult_d8 R3,R4,R5,R6,R10,R0,R1,R8,R7,R9,0,2,4,6,0,2,4,6
    ELIF    MASKING_ORDER = 16
    rec_mat_mult_d16 R3,R4,R5,R6,R10,R0,R1,R8,R7,R9,0,2,4,6,8,10,12,14,0,2,4,6,8,10,12,14
    ELIF    MASKING_ORDER = 32
    rec_mat_mult_d32 R3,R4,R5,R6,R10,R0,R1,R8,R7,R9
    ENDIF
    
    B end_mat_mult
    LTORG


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;      BCPZ MULTIPLICATION      ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


macro_bcpz_mult

    ;; ------------------------------------------------------------------------
    ;; Init phase

    LDR     R8, =matmultTable
    LDR     R7, =RNGTab
    ;; computation of the matrix of cross products
    B mat_mult
end_mat_mult
    
    ;; ------------------------------------------------------------------------
    ;; computation of the matrix of cross products

    MOV     R12, #0
loop0bcpz
    MOV     R5, #MASKING_ORDER
    MUL     R4, R5, R12
    ADD     R4, R12
    LDR     R6, [R8,R4, LSL #2]
    STR     R6, [R2,R12, LSL #2]
    ;; loop 0 processing
    ADD     R12, #1
    CMP     R12, #MASKING_ORDER
    BNE     loop0bcpz
    
    ;; ------------------------------------------------------------------------
    ;; Cross products computation

    MOV     R12, #0
loop1bcpz
    ADD     R11, R12, #1
loop2bcpz
    ;; s <-$ F
    get_random R3,R7
    ;; c_i += s
    LDR     R6, [R2,R12, LSL #2]
    EOR     R6, R3
    STR     R6, [R2,R12, LSL #2]
    ;; s'  = s + Mij
    MOV     R5, #MASKING_ORDER
    MUL     R4, R5, R12
    ADD     R4, R11
    LDR     R6, [R8,R4, LSL #2]
    EOR     R3, R6
    ;; s' += Mji
    MOV     R5, #MASKING_ORDER
    MUL     R4, R5, R11
    ADD     R4, R12
    LDR     R6, [R8,R4, LSL #2]
    EOR     R3, R6
    ;; c_j += s'
    LDR     R6, [R2,R11, LSL #2]
    EOR     R6, R3
    STR     R6, [R2,R11, LSL #2]
    ;; loop 2 processing
    ADD     R11, #1
    CMP     R11, #MASKING_ORDER
    BNE     loop2bcpz
    ;; loop 1 processing
    ADD     R12, #1
    CMP     R12, #(MASKING_ORDER-1)
    BNE     loop1bcpz
    BX  LR
    LTORG
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                 MAT MULT TABLE USED FOR BCPZ MULTIPLICATION               ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    
    AREA    bcpz_data, DATA, READWRITE
matmultTable    % 4*(MASKING_ORDER)*(MASKING_ORDER)

