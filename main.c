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



#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>    
#include <string.h>
#include <time.h>       
#include "parameters.h"

void wrapper_mul (uint* operandA, uint* operandB, uint* out);
void wrapper_ref (uint* operand);

/* Generate the encodings for ISW-based multiplications and refreshes */
void isw_mask_generator (uint* tab, uint operand) {
    int i=0;
    tab[MASKING_ORDER-1] = 0;
    for (i=0; i<MASKING_ORDER-1; i++) {
        tab[i] = rand();
        tab[MASKING_ORDER-1] ^= tab[i];
    }
    tab[MASKING_ORDER-1] ^= operand;
}

/* Wrapper to generate encodings depending on the multiplication type */
void init_operand_mul (uint operand_A, uint operand_B, uint* masked_operand_A, uint* masked_operand_B) {
    if (MODE == 21 || MODE == 22) {
        masked_operand_A[0] = operand_A;
        masked_operand_B[0] = operand_B;
    }
    else {
        isw_mask_generator(masked_operand_A, operand_A);
        isw_mask_generator(masked_operand_B, operand_B);
    }
}

/* Wrapper to generate encodings depending on the refresh type */
void init_operand_ref (uint operand, uint* operand_ref) {
    if (MODE == 6) {
        operand_ref[0] = operand;
    }
    else {
        isw_mask_generator(operand_ref, operand);
    }
}

/* Unmask an encoding */
uint unmasked_res (uint masked_res[MASKING_ORDER]) {
    int i=0;
    uint res = 0;
    uint tmp = 0;
    uint elm = 0;
    if (MODE == 21 || MODE == 22 || MODE == 6) {
        if(MASKING_ORDER == 32){
            res = (__builtin_popcount(masked_res[0]))%2;
        }
        else{
            for (i=0; i<NB_ELM_PBM; i++) {
                tmp = (masked_res[0]>>(MASKING_ORDER*i)) & ((1ULL<<MASKING_ORDER)-1);
                elm = __builtin_popcount(tmp) % 2;
                res = res ^ (elm << MASKING_ORDER*i);
            }
        }
    }
    else {
        res = masked_res[0];
        for (i=1; i<MASKING_ORDER; i++) {
            res ^= masked_res[i];
        }           
    }
    return res;
}

/* Test function for the result of a multiplication between two masked operands */
int test_mult (uint operand_A, uint operand_B, uint res) {
    int test = 0;
    int tmpA,tmpB,elm;
    int i;
    int resA =0;
    int resB =0;
    // PBM multiplication test
    if (MODE == 21 || MODE == 22) {
        if(MASKING_ORDER == 32) {
            test = (__builtin_popcount(operand_A) % 2) & (__builtin_popcount(operand_B) % 2);
        }
        else {
			for (i=0; i<NB_ELM_PBM; i++) {
                tmpA = (operand_A>>(MASKING_ORDER*i)) & ((1ULL<<MASKING_ORDER)-1);
                elm = __builtin_popcount(tmpA) % 2;
                resA = resA ^ (elm << MASKING_ORDER*i);
            
                tmpB = (operand_B>>(MASKING_ORDER*i)) & ((1ULL<<MASKING_ORDER)-1);
                elm = __builtin_popcount(tmpB) % 2;
                resB = resB ^ (elm << MASKING_ORDER*i);
            }
            test = resA & resB;
		}
    }
    // ISW-based multiplication test
    else {
        test = operand_A & operand_B;
    }

	if (test != res) {
        return 1;
    }
    return 0;
}

/* Test function for the results of a refresh of the encoding of a masked variable */
int test_refresh (uint operand, uint res) {
    int i =0;
    int test = 0;
    int tmp = 0;
    uint mask = (1ULL<<MASKING_ORDER)-1;
    // PBM refresh test
    if (MODE == 6) {
        for (i=0; i<NB_ELM_PBM; i++) {
            tmp = operand & (mask<<(MASKING_ORDER*i));
            test = res & (mask<<(MASKING_ORDER*i));
            if ((__builtin_popcount(tmp) % 2) != (__builtin_popcount(test) % 2)) {
                return 1;
            }
        }
    }
    // ISW refresh test
    else if (MODE == 5) {
        if (operand != res) {
            return 1;
        }
    }
    return 0;
}

int main() {
    uint operand_A;
    uint operand_B;
    uint res = 0;
    int  i=0;
    uint masked_operand_A[MASKING_ORDER];
    uint masked_operand_B[MASKING_ORDER];
    uint masked_res[MASKING_ORDER];
    srand(atoi(__TIME__ + 6));
    // Test for the refresh functions
    if (MODE == 5 || MODE == 6) {
        for (i=0; i<1000; i++) {
            operand_A = rand();
            init_operand_ref(operand_A, masked_operand_A);
            wrapper_ref(masked_operand_A);
            res = unmasked_res(masked_operand_A);
            if (test_refresh(operand_A,res) == 1) {
                return 1;
            }
        }
    }
    // Test for the multiplication functions
    else {
        for (i=0; i<1000; i++){
            operand_A = rand();
            operand_B = rand();
            init_operand_mul(operand_A, operand_B, masked_operand_A, masked_operand_B);
            wrapper_mul(masked_operand_A, masked_operand_B, masked_res);
            res = unmasked_res(masked_res);
            if (test_mult(operand_A,operand_B,res) == 1) {
                return 1;
            }
        }
    }
    return 0;
}
