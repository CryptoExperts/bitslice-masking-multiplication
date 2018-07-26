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
;;                      BBPPTV MULTIPLICATION FUNCTIONS                      ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



    ;; ------------------------------------------------------------------------
    ;; Compute mat mult procedure for the case d = 2 (terminal case)

rec_mat_mult_d2 
    push{LR}
    ;; shift_m set to get Mij
    MOV     R10, #MASKING_ORDER
    MOV     R9, R11
    MUL     R9, R10, R9
    ADD     R9, R12
    ;;
    LDR     R3, [R0], #4
    LDR     R4, [R0], #-4   
    LDR     R5, [R1], #4
    LDR     R6, [R1], #-4   
    AND     R10, R3, R5
    STR     R10, [R8, R9, LSL #2]
    AND     R10, R3, R6
    ADD     R9, #1
    STR     R10, [R8, R9, LSL #2]
    ;; shift_m set to get Mi+1j
    ADD     R9, #(MASKING_ORDER-1)
    ;;
    AND     R10, R4, R5
    STR     R10, [R8, R9, LSL #2]
    AND     R10, R4, R6
    ADD     R9, #1
    STR     R10, [R8, R9, LSL #2]
    
    pop{LR}
    BX  LR
    
    ;; ------------------------------------------------------------------------
    ;; Generic refresh macro (any order) with loops 

refresh 
    push{LR}
    LDR     R3, [R0], #4
    LDR     R4, [R1], #4
    MOV     R12, #1
loopRefresh
    ;; refresh x_0, x_i
    get_random R6,R7
    LDR     R5, [R0]
    EOR     R3, R6
    EOR     R5, R6
    STR     R5, [R0], #4
    ;; refresh y_0, y_i
    get_random R6,R7
    LDR     R5, [R1]
    EOR     R4, R6
    EOR     R5, R6
    STR     R5, [R1], #4
    ;; loop processing
    ADD     R12, #1
    CMP     R12, R11
    BNE     loopRefresh
    ;; reset adresses of x and y
    MOV     R6, #4
    MUL     R5, R11, R6
    SUB     R0, R5
    SUB     R1, R5
    STR     R3, [R0]
    STR     R4, [R1]

    pop{LR}
    BX  LR



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BBPPTV MULTIPLICATION MACROS                        ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;         MAT MULT D = 4        ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    MACRO
    rec_mat_mult_d4 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x, $stop_x, $start_y, $stop_y
    ;; M11 = X1 * Y1
    MOV     R11, #$start_x
    MOV     R12, #$start_y
    BL rec_mat_mult_d2 
    ;; Refresh X1,Y1
    MOV     R11, #2
    BL refresh 
    ;; M12 = X1 * Y2
    ADD     $addr_y, #8
    MOV     R11, #$start_x
    MOV     R12, #$stop_y
    BL rec_mat_mult_d2 
    ;; M21 = X2 * Y1
    ADD     $addr_x, #8
    SUB     $addr_y, #8
    MOV     R11, #$stop_x
    MOV     R12, #$start_y
    BL rec_mat_mult_d2 
    ;; Refresh X2,Y2
    ADD     $addr_y, #8
    MOV     R11, #2
    BL refresh 
    ;; M22 = X2 * Y2
    MOV     R11, #$stop_x
    MOV     R12, #$stop_y
    BL rec_mat_mult_d2 
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
    MOV     R11, #4
    BL refresh 
    ;; M12 = X1 * Y2
    ADD     $addr_y, #16
    rec_mat_mult_d4 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x1, $stop_x1, $start_y2, $stop_y2
    ;; M21 = X2 * Y1
    ADD     $addr_x, #16
    SUB     $addr_y, #16
    rec_mat_mult_d4 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x2, $stop_x2, $start_y1, $stop_y1
    ;; Refresh X2,Y2
    ADD     $addr_y, #16
    MOV     R11, #4
    BL refresh 
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
    MOV     R11, #8
    BL refresh 
    ;; M12 = X1 * Y2
    ADD     $addr_y, #32
    rec_mat_mult_d8 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x11, $stop_x11, $start_x12, $stop_x12, $start_y21, $stop_y21, $start_y22, $stop_y22
    ;; M21 = X2 * Y1
    ADD     $addr_x, #32
    SUB     $addr_y, #32
    rec_mat_mult_d8 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, $start_x21, $stop_x21, $start_x22, $stop_x22, $start_y11, $stop_y11, $start_y12, $stop_y12
    ;; Refresh X2,Y2
    ADD     $addr_y, #32
    MOV     R11, #8
    BL refresh 
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
    MOV     R11, #16
    BL refresh 
    ;; M12 = X1 * Y2
    ADD     $addr_y, #64
    rec_mat_mult_d16 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30
    ;; M21 = X2 * Y1
    ADD     $addr_x, #64
    SUB     $addr_y, #64
    rec_mat_mult_d16 $x_1, $x_2, $y_1, $y_2, $tmp, $addr_x, $addr_y, $addr_m, $addr_r, $shift_m, 16, 18, 20, 22, 24, 26, 28, 30, 0, 2, 4, 6, 8, 10, 12, 14
    ;; Refresh X2,Y2
    ADD     $addr_y, #64
    MOV     R11, #16
    BL refresh 
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
    MOV     R11, #0
    MOV     R12, #0
    BL rec_mat_mult_d2 
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

function_bcpz_mult

    ;; ------------------------------------------------------------------------
    ;; Init phase

    push{LR}
    LDR     R8, =matmultTable
    LDR     R7, =RNGTab

    ;; ------------------------------------------------------------------------
    ;; computation of the matrix of cross products

    B mat_mult
end_mat_mult

    ;; ------------------------------------------------------------------------
    ;; c_i = Mii

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
    pop{LR}
    BX  LR
    LTORG
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                 MAT MULT TABLE USED FOR BCPZ MULTIPLICATION               ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    AREA    bcpz_data, DATA, READWRITE
matmultTable    % 4*(MASKING_ORDER)*(MASKING_ORDER)

