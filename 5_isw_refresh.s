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



    AREA    iswrefresh_code, CODE, READONLY


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                          ISW REFRESH MASK FUNCTION                        ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


isw_refresh

    ;; ------------------------------------------------------------------------
    ;; init phase

    push{R2-R12, LR}
    LDR     R7, =RNGReg
    

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;      MASKING ORDER = 2	     ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    IF      MASKING_ORDER = 2

	;; ldr a_0
    LDR     R4, [R0, #0]
    get_random R3,R7
    ;; a_0 <- a_0 + s
    EOR     R4, R3
    ;; a_1 <- a_1 + s
    LDR     R5, [R0, #4]
    EOR     R5, R3
    STR     R5, [R0, #4]
    ;; store a_0
    STR     R4, [R0, #0]

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;     MASKING ORDER = 0 mod 4   ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ELSE

    ;; ------------------------------------------------------------------------
    ;; a_i = a_i + s
    ;; a_j = a_j + s

    MOV     R12, #0
loop1rf
    ;; load a_i
    get_random  R3, R7
    LDR     R4, [R0, R12, LSL #2]
    ADD     R2, R12, #1
    LDR     R6, [R0, R2, LSL #2]
    ADD     R2, #1
    EOR     R4, R3
    EOR     R6,R3
    get_random R3, R7
    LDR     R9, [R0, R2, LSL #2]
    ADD     R2, #1
    EOR     R4, R3
    EOR     R9, R3
    LDR     R10, [R0, R2, LSL #2]
    get_random R3, R7
    EOR     R4, R3
    EOR     R10, R3
    ADD     R11, R2, #1
    CMP     R11, #MASKING_ORDER
    BEQ     endofloop
loop2rf
    get_random R3, R7
    LDR     R5, [R0, R11, LSL #2]
    EOR     R4, R3
    EOR     R5, R3
    get_random R3, R7
    EOR     R6, R3
    EOR     R5, R3
    get_random R3, R7
    EOR     R9, R3
    EOR     R5, R3
    get_random R3, R7
    EOR     R10, R3
    EOR     R5, R3
    STR     R5, [R0, R11, LSL #2]
    ;; loop 2 processing
    ADD     R11, #1
    CMP     R11, #MASKING_ORDER
    BNE     loop2rf
    ;; store a_i
    STR     R4, [R0, R12, LSL #2]
    ADD     R12, #1
    STR     R6, [R0, R12, LSL #2]
    ADD     R12, #1
    STR     R9, [R0, R12, LSL #2]
    ADD     R12, #1
    STR     R10, [R0, R12, LSL #2]
    ;; loop 1 processing
    ADD     R12, #1
    CMP     R12, #(MASKING_ORDER-1)
    BNE     loop1rf
endofloop
    ENDIF
    
    pop{R2-R12, LR}
    BX LR
    LTORG
