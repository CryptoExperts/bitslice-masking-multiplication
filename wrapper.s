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

#include "parameters.h"
    PRESERVE8
#include "random.s"
    
    IF MODE = ISW
#include "1_isw.s"
    
    ELIF MODE = ISW_UNROLLED
#include "1_isw_unrolled.s"
    
    ELIF MODE = BDFGSS
#include "2_bdfgss.s"
    
    ELIF MODE = BDFGSS_UNROLLED
#include "2_bdfgss_unrolled.s" 
    
    ELIF MODE = BBPPTV
#include "3_bbpptv.s"
    
    ELIF MODE = BBPPTV_UNROLLED
#include "3_bbpptv_unrolled.s"
    
    ELIF MODE = BBPPTV_ORIGINAL
#include "3_bbpptv_original.s"
    
    ELIF MODE = BCPZ_MACRO
#include "4_bcpz_macro.s"
    
    ELIF MODE = BCPZ_FUNCTION
#include "4_bcpz_function.s"
    
    ELIF MODE = ISW_REFRESH
#include "5_isw_refresh.s"
    
    ELIF MODE = BDFGSS_REFRESH
#include "5_bdfgss_refresh.s"
    
    ENDIF
    
    EXPORT  wrapper_mul
    EXPORT  wrapper_ref
    
    AREA    multbs_test, CODE, READONLY
        
wrapper_mul
    push{R3-R12, LR}
    
    IF      MODE = ISW 
    BL  isw_mult    
    
    ELIF    MODE = ISW_UNROLLED
    BL  unrolled_isw_mult

    ELIF    MODE = BDFGSS 
    BL  bdfgss_mult
    
    ELIF    MODE = BDFGSS_UNROLLED
    BL  unrolled_bdfgss_mult

    ELIF    MODE = BBPPTV
    BL  bbpptv_mult

    ELIF    MODE = BBPPTV_UNROLLED
    BL  unrolled_bbpptv_mult

    ELIF    MODE = BBPPTV_ORIGINAL
    BL  original_bbpptv_mult

    ELIF    MODE = BCPZ_MACRO 
    BL  macro_bcpz_mult

    ELIF    MODE = BCPZ_FUNCTION
    BL  function_bcpz_mult

    ENDIF
    
    pop{R3-R12, LR}
    BX  LR
    LTORG


wrapper_ref
    push{R3-R12, LR}

    IF  MODE = ISW_REFRESH
    BL  isw_refresh

    ELIF    MODE = BDFGSS_REFRESH
    BL  bdfgss_refresh  

    ENDIF 

    pop{R3-R12, LR}
    BX  LR
    LTORG
    
    END
