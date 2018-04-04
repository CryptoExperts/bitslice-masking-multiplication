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



    AREA    bdfgss_refresh_code, CODE, READONLY
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                       BDFGSS REFRESH MASK FUNCTION                        ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


        
bdfgss_refresh

    ;; ------------------------------------------------------------------------
    ;; Init phase

    LDR R7, =RNGReg



    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;          BDFGSS : D=2         ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    IF MASKING_ORDER = 2

    ;; r_0 = a
    LDR     R0, [R0]
    get_random R3, R7
    ;; a + r
    EOR     R0, R0, R3
    ;;generation of the mask for rotation by 1
    MOV     R6, #0x5500
    EOR     R6, R6, #0x55
    EOR     R6, R6, R6, LSL #16
    ;; rotation of b by 1
    AND     R9, R6, R3, LSR #1
    BIC     R10, R3, R6, LSR #(MASKING_ORDER-1)
    EOR     R10, R9, R10, LSL #(MASKING_ORDER-1)
    ;; xor
    EOR     R0, R0, R10
    ;; return
    STR     R0, [R0]


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;          BDFGSS : D=4         ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ELIF MASKING_ORDER = 4

    ;; r_0 = a
    LDR     R0, [R0]
    get_random R3, R7
    ;; a + r
    EOR     R0, R0, R3
    ;;generation of the mask for rotation by 1
    MOV     R6, #0x7700
    EOR     R6, R6, #0x77
    EOR     R6, R6, R6, LSL #16
    ;; rotation of b by 1
    AND     R9, R6, R3, LSR #1
    BIC     R10, R3, R6, LSR #(MASKING_ORDER-1)
    EOR     R10, R9, R10, LSL #(MASKING_ORDER-1)
    ;; xor
    EOR     R0, R0, R10
    ;; return
    STR     R0, [R0]


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;          BDFGSS : D=8         ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ELIF MASKING_ORDER = 8

    ;; r_0 = a
    LDR     R0, [R0]
    get_random R3, R7
    ;; a + r
    EOR     R0, R0, R3
    ;;generation of the mask for rotation by 1
    MOV     R6, #0x7F00
    EOR     R6, R6, #0x7F
    EOR     R6, R6, R6, LSL #16
    ;; rotation of b by 1
    AND     R9, R6, R3, LSR #1
    BIC     R10, R3, R6, LSR #(MASKING_ORDER-1)
    EOR     R10, R9, R10, LSL #(MASKING_ORDER-1)
    ;; xor
    EOR     R0, R0, R10
    ;; return
    STR     R0, [R0]


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;          BDFGSS : D=16        ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ELIF MASKING_ORDER = 16

    ;; r_0 = a
    LDR     R0, [R0]
    get_random R3, R7
    ;; a + r
    EOR     R0, R0, R3
    ;;generation of the mask for rotation by 1
    MOV     R6, #0x7F00
    EOR     R6, R6, #0xFF
    EOR     R6, R6, R6, LSL #16
    ;; rotation of b by 1
    AND     R9, R6, R3, LSR #1
    BIC     R10, R3, R6, LSR #(MASKING_ORDER-1)
    EOR     R10, R9, R10, LSL #(MASKING_ORDER-1)
    ;; xor
    EOR     R0, R0, R10
    ;; return
    STR     R0, [R0]
    

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;          BDFGSS : D=32        ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ELIF MASKING_ORDER = 32

    ;; r_0 = a
    LDR     R0, [R0]
    get_random R3, R7
    ;; a + r
    EOR     R0, R0, R3
    ;; (a + r) + rot(r)
    EOR     R0, R0, R3, ROR #1
    ;; return
    STR     R0, [R0]    
    ENDIF
        
    BX LR
    LTORG
