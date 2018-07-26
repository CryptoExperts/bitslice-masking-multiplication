# Secure Multiplication for Bitslice Higher-Order Masking

This repository provides some material related to the article <a href="https://eprint.iacr.org/complete/">Secure Multiplication for Bitslice Higher-Order Masking</a> published at <a href="https://www.cosade.org/">COSADE 2018</a>. The repository includes the source codes of the multiplication schemes optimised in ARMv7 assembly as depicted in the paper. 

## Authors

* Dahmun Goudarzi ([CryptoExperts](https://www.cryptoexperts.com)) 
* Anthony Journault ([UCL-CryptoGroup] (https://uclouvain.be/crypto/))
* Matthieu Rivain ([CryptoExperts](https://www.cryptoexperts.com)) 
* François-Xavier Standaert ([UCL-CryptoGroup] (https://uclouvain.be/crypto/))

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
 * **wrapper.s**: ARMv7 assembly source code that call the multiplication according to the parameters in parameter.h.

### Header file:

 * **parameter.h**: Header files containing different sets of parameters or constant definition.

### Main:

* **main.c**: Main file containing function to set up shares/unmasked shares according to mode chosen and testing the correctness.

## Parameters
* **MASKING_ORDER**: sets the masking order. Possible values lies in $\{2,4,8,16,32\}$
* **NB\_ELM\_PBM**: sets the number of elements per register in the BDFGSS type multiplications. More precisely, since we manipulate all the shares of a sensitive bit at once and in order to make full use of the register, we store NB\_ELM\_PBM sensitive bits (with their shares) in a 32-bit register. Hence it is defined as $\frac{32}{MASKING\_ORDER}$ (needs no modification).
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
* **RAND_MODE**: sets the TRNG settings to be used. For test purposes, a table with pre computed random bytes (labelled RNGTab) is used. The two possible values are:
	* TRNG1: TRNG with 3 clock cycles
	* TRNG2: TRNG with 80 clock cycles
	
/!\ WARNING /!\

* As opposed to what is written in the paper, the TRNG1 mode is 3 clock cycles (instead of 10). This is not affecting the trend highlighted in the paper.
* The random generation code is dedicated for benchmarking only. For a practical use the get_random function should be defined according to the specific use case.

/!\ WARNING /!\

## How to use

To test the code: 

* install Keil µVision (version 5 or higher), 
* create a project for a ARMv7 target (little endian)
* add the source files (wrapper.s, parameter.h and main.c) to the project and run.

