# Secure Multiplication for Bitslice Higher-Order Masking

This repository provides some material related to the article  <a href="https://eprint.iacr.org/2018/315.pdf">Secure Multiplication for Bitslice Higher-Order Masking</a> published at <a href="https://www.cosade.org/">COSADE 2018</a>. The repository includes the source codes of the multiplication schemes optimised in ARMv7 assembly as depicted in the paper. 

## Authors

* Dahmun Goudarzi ([CryptoExperts](https://www.cryptoexperts.com)) 
* Anthony Journault (<a href="https://uclouvain.be/crypto/">UCL-CryptoGroup</a>)
* Matthieu Rivain ([CryptoExperts](https://www.cryptoexperts.com)) 
* François-Xavier Standaert (<a href="https://uclouvain.be/crypto/">UCL-CryptoGroup</a>)

## Copyright and License

Copyright &copy; 2018, CryptoExperts and Université Catholique de Louvain

License <a href="https://en.wikipedia.org/wiki/GNU_General_Public_License#Version_3">GNU General Public License v3 (GPLv3)</a>


## Content

### ARMv7 assembly source files:

 * **1_isw.s**: generic ISW multiplication.
 * **1\_isw_unrolled.s**: unrolled ISW multiplication.
 * **2_bdgfss.s**: generic BDGFSS multiplication (can not be used for a masking order of 2 and 32).
 * **2\_bdgfss_unrolled.s**: unrolled BDGFSS multiplication.
 * **3\_bbpptv.s**: generic BBPPTV multiplication.
 * **3\_bbpptv_unrolled.s**: unrolled BBPPTV multiplication.
 * **3\_bbpptv_original.s**: BBPPTV multiplication from the original paper.
 * **4\_bcpz_macro.s**: BCPZ multiplication with macros.
 * **4\_bcpz_function.s**: BCPZ multiplication with macros and functions.
 * **5\_isw_refresh.s**: ISW refresh.
 * **5\_bdfgss_refresh.s**: BDFGSS refresh.
 * **random.s**: random generation.
 * **wrapper.s**: ARMv7 assembly source code that calls the multiplications according to the parameters in parameter.h.

### Header file:

 * **parameter.h**: Header files containing different sets of parameters or constant definition:
   *  the choice of the random number generation:
   		*  TRNG1 output a 32 bits random values in 10 cycles
   		*  TRNG2 output a 32 bits random values in 80 cycles 
   * the choice of the multiplication or refresh to use (listed above).
	* the choice of the masking order (can only be powers of 2)
	* the number of elements stored in a register 
	* the choice of the multiplication or the refresh to be tested 
	* the choice of the TRNG to be used

### Main:

* **main.c**: Main file containing function to set up shares/unmasked shares according to mode chosen and testing the correctness.

## Parameters
* **MASKING_ORDER**: sets the masking order. Possible values lies in {2,4,8,16,32}
* **NB\_ELM\_PBM**: sets the number of elements per register in the PBM type multiplications. It is defined as 32/MASKING\_ORDER (needs no modification). 
* **MODE**: sets the mode of multiplication or refresh to be tested by the main. The possible values are the different multiplications/refreshes defined in the above files. In other words, it can be equal to:
	* ISW
	* ISW_UNROLLED
	* BDFGSS
	* BDFGSS_UNROLLED
	* BBPPTV
	* BBPPTV_UNROLLED
	* BBPPTV_ORIGINAL
	* BCPZ_MACRO
	* BCPZ_FUNCTION
	* BDFGSS_REFRESH
* **RAND_MODE**: sets the TRNG settings to be used. The two possible values are:
	* TRNG1: TRNG with 10 clock cycles
	* TRNG2: TRNG with 80 clock cycles
	
## How to use

To test the code: 

* install Keil µVision (version 5 or higher), 
* create a project for a ARMv7 target (little endian)
* add the source files (wrapper.s, parameter.h and main.c) to the project and run.

