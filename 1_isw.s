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



    AREA    isw_code, CODE, READONLY



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                        ISW MULTIPLICATION FUNCTION                        ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


isw_mult

    ;; ------------------------------------------------------------------------
    ;; init phase

    LDR     R7, =RNGTab

    ;; ------------------------------------------------------------------------
    ;;  c_i = a_i AND b_i

    MOV     R12, #0
loop0isw
    LDR     R4, [R0,R12, LSL #2] 
    LDR     R5, [R1,R12, LSL #2] 
    AND     R6, R4, R5
    STR     R6, [R2,R12, LSL #2]
    ;; loop 0 processing
    ADD     R12, #1
    CMP     R12, #MASKING_ORDER
    BNE     loop0isw

    ;; ------------------------------------------------------------------------
    ;; s' = (s + (a_i*b_j)) + (a_j*b_i)
    ;; c_i = c_i + s
    ;; c_j = c_j + s'

    MOV     R12, #0
loop1isw
    ADD     R11, R12, #1
loop2isw
    ;; s <-$ F
    get_random R3,R7
    ;; c_i += s
    LDR     R6, [R2,R12, LSL #2]
    EOR     R6, R3
    STR     R6, [R2,R12, LSL #2]
    ;; s' += a_i AND b_j
    LDR     R4, [R0,R12, LSL #2] 
    LDR     R5, [R1,R11, LSL #2]
    AND     R6, R4, R5
    EOR     R3, R6
    ;; s' += a_j AND b_i
    LDR     R4, [R0,R11, LSL #2] 
    LDR     R5, [R1,R12, LSL #2] 
    AND     R6, R4, R5
    EOR     R3, R6
    ;; c_j += s'
    LDR     R6, [R2,R11, LSL #2]
    EOR     R6, R3
    STR     R6, [R2,R11, LSL #2]
    ;; loop 2 processing
    ADD     R11, #1
    CMP     R11, #MASKING_ORDER
    BNE     loop2isw
    ;; loop 1 processing
    ADD     R12, #1
    CMP     R12, #(MASKING_ORDER-1)
    BNE     loop1isw

    BX LR
    LTORG
