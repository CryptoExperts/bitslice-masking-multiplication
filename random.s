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


    
    AREA    rand_code, CODE, READONLY



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;;                              TRNG SETTINGS MACROS                         ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;              TRNG 1           ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        
    IF      RAND_MODE = TRNG1
    MACRO   
    get_random $rnd, $pttab
    LDR     $rnd, [$pttab]
    MEND


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;                               ;;
    ;;              TRNG 2           ;;
    ;;                               ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    ELIF    RAND_MODE = TRNG2
    MACRO   
    get_random $rnd, $pttab
    push{LR}
    BL      sleep
    pop{LR}
    LDR     $rnd, [$pttab]
    MEND

    ;; ------------------------------------------------------------------------
    ;; sleep for 80 clock cycles

sleep
    GBLA    loop_sleep
loop_sleep SETA 0
    WHILE   loop_sleep<80
    NOP
loop_sleep SETA loop_sleep+1
    WEND
    BX  LR
    
    ENDIF
    
    AREA    random_table, DATA, READONLY
RNGReg
    DCW 0x4461,0x686D,0x756E,0x2047,0x6f75,0x6461,0x727a,0x6920
