# Version History 
### 0.7.0, 2020/12/05
Version v0.7.0 is a major release providing compatibility with Octave 5.2 and 6.1
- dropping support for Octave 4.4

### 0.6.0, 2020/04/26
Version v0.6.0 is a major release introducing a new reporting framework
- Extension of Retail class
- Rework of Position class
- Refactoring and extension of reporting functionality (e.g. high-quality graphical output)
- various refactoring and bugfixing

### 0.5.1, 2019/06/13
Version v0.5.1 is a minor release with additional features
- Introduction of Retail class to allow for valuation of private investors banking and insurance products
- various refactoring and bugfixing

### 0.5.0, 2019/03/28
Version v0.5.0 is a major release with additional features
- Solvency II compliant reporting for asset data according to the Tripartite v4.0 standard
- various refactoring and bugfixing


### 0.4.4, 2019/02/12
Version v0.4.4 is a minor release with bug fixes, stability and performance improvements
- dropped support for Octave 4.2 due to compatility issues with Gnu++11 compiler
- code refactoring for improved stability and performance

### 0.4.3, 2018/05/20
Version v0.4.3 is a minor release with bug fixes and some more features
- fixed a compatibility issue with Octave 4.4.0
- refactoring of script for cash flow rollout for better readability and maintainability
- introduced more statistical tests for scenario generation

### 0.4.2, 2017/12/10
Version v0.4.2 is a minor release with new features, performance improvements and bug fixes
- implemented credit default swaps
- introduced Sobol quasi-random number generator

### 0.4.1, 2017/10/21
Version v0.4.1 is a minor release with bug fixes and the introduction of a GUI
- bugfix regarding applying risk factor stresses
- introduced a revaluation of all underlying instrument of sensitivity instruments
- introduction of a graphical user interface

### 0.4.0, 2017/08/23
Version v0.4.0 is a major release with massive speed impprovements, refactored code,
extended documentation and a modified stress test interface

- bugfix of Hagan convexity adjustment
- added new attributes for stochastic CF instruments
- sensitivity instruments: new subtype SENSI
- introduction of aggregated index objects
- recursive aggregation of index and curves possible
- performance improvements for loading instruments and mktdata
- reworked stress test framework with interface change: individual objects (e.g. curves, indizes, surfaces) can be shocked in each stress scenarios (absolute or relative shock, apply certain value)
- reworked interpolation of curves, surfaces and cubes (via oct files) to increase interpolation performance (vectorization not possible for stress scenarios)
- performance improvment with C++ functions for interpolation of cube values and linear interpolation of curves
	
### 0.3.5, 2017/05/26
Version v0.3.5 is a minor release with new instruments, refactored code and
extended documentation.

- introduction of Binary and Lookback options
- introduction of Forward Rate / Volatility / Variance Agreements
- calculation of key rate durations and convexities for bonds
- volatility calibration for caps and floors
- consolidation of calibration scripts (generic approach)
- refactored portfolio aggregation

### 0.3.5-rc1, 2017/03/25
Release candidate of the upcoming octarisk v0.3.5 release. 

- Extended in-code documentation functionality (.help method) for several classes
- Introduction of new instruments: Averaging floating rate note
- Introduction of new pricing function for basket volatilities and option prices
- Introduction of sensitivity calculation for Forwards and Swaptions

### 0.3.4, 2017/02/11
Version v0.3.4 is a minor release with bugfixes, performance improvements and new instruments.

- Extended class and object documentation.
- Introduction of new instruments: Inflation Linked Bonds and Inflation Linked Caps/Floors
	
### 0.3.3, 2016/12/03
Version v0.3.3 is a minor release with additional instrument and reworked volatility framework.

- Introduction of new instruments: Bonds with embedded options, CM Swaps, CMS Caps and Floors
- Introduction of new pricing function for callable bonds in c++ code (compiled as oct file)
- several minor bugfixes

### 0.3.2, 2016/10/20
Version v0.3.2 is a minor release introducing a new session-like instrument valuation interface.

- Introduction of new instruments: Asian Options, Basket, Options on Baskets
- Introduciton of a new Class: Matrix
- several minor bugfixes and new test cases
- Introduction of a new framework for oct files compiled from c++ code

### 0.3.1, 2016/08/21
Version v0.3.1 is a minor version with new testing features, more validated pricing functions and several minor bugfixes.

### 0.3.0, 2016/06/30
Version v0.3.0 is a major version with greatly improved features and validated pricing functions.

- independent validation of all pricing functions
- unittests for more convenient refactoring and instrument examples
- several bugfixes

### 0.3.0-rc1, 2016/05/20
Version v0.3.0-rc1 is the first release candidate for the upcoming release, where all API changes shall be accomplished.

The Version improves again the file-based interaction: 
- The file formats for correlation input files has changed to reflect a more user friendly input format. 
The correlation matrix is now linearized, which means that one correlation pair is specified in each line. 
Moreover, risk factor subsets for MC generation and stress testing are independent.
- Introduced stable seed: a binary seed file for seeding the Mersenne-Twister PRNG is specified
- Introduced Aggregated Curves: aggregated curves consist of sums of arbitrary other curves defined during mktdata object generation 
for the chosen curve term structure. Aggregated curves can be assigned to discount curve or spread curve in instrument specifications. 

### 0.2.0, 2016/04/21: 
minor release: bugfixes, change of file interface (new input structure of mktdata, instruments, riskfactors, positions and stresstests) allowing flexibel
number of attributes per product type

### 0.1.0, 2016/04/03: 
pre-release version, going public

### 0.0.6, 2016/04/02: 
implemented Surface class for volatility surfaces / cubes
implemented swaption instrument valuation (Black76 and Bachelier model)

### 0.0.5, 2016/03/28: 
changed the implementation to object oriented approach (introduced instrument, risk factor classes)

### 0.0.4, 2016/02/05:	
added spread risk factors, general cash flow pricing 

### 0.0.3, 2016/01/19  
added new instrument types FRB, FRN, FAB, ZCB
added synthetic instruments (linear combinations of other instruments)
added equity forwards and Black-Karasinski stochastic process
                                              
### 0.0.2, 2015/12/16:  
added Willow Tree model for pricing american equity options, 
added volatility surface model for term / moneyness structure of volatility

### 0.0.1, 2015/11/24:   
initial version 



