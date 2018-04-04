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



#ifndef _MULT_BITSLICE_H
#define _MULT_BITSLICE_H

/* Random mode definition */
#define TRNG1               0		// TRNG with 10 clock cycles 
#define TRNG2               1		// TRNG with 80 clock cycles

/* Code mode */
#define ISW                 11		// Generic ISW multiplication 
#define ISW_UNROLLED        12		// Unrolled ISW multiplication
#define BDFGSS              21		// Generic BDFGSS multiplication
#define BDFGSS_UNROLLED     22  	// Unrolled BDFGSS multiplication
#define BBPPTV              31		// Generic BBPPTV multiplication
#define BBPPTV_UNROLLED     32  	// Unrolled BBPPTV multiplication
#define BBPPTV_ORIGINAL     33      // Original BBPPTV multiplication
#define BCPZ_MACRO          41		// BCPZ multiplication with macros
#define BCPZ_FUNCTION       42      // BCPZ multiplication with a mix of macros and functions
#define ISW_REFRESH         5		// ISW refresh
#define BDFGSS_REFRESH      6		// BDFGSS refresh

/* Code mode definitions */
#define MASKING_ORDER       2						// Set the masking order (must be a power of 2)
#define NB_ELM_PBM          (32/MASKING_ORDER)		// Defines the number of elements per register for BDFGSS based multiplication
#define MODE                ISW						// Set the multiplication or refresh to test
#define RAND_MODE           TRNG1					// Set the TRNG to be used


/* Test definitions*/
#define uint unsigned int

#endif /* _MULT_BITSLICE_H */
