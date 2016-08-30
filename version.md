# Version History 

### next versions
Possible new Features:
- calculation of key rate durations for Bonds
- Asian Options (geometric and arithmetic averaging), closed form solutions only
- callable bonds (construct Willowtree for IR, incorporate call/put schedules)

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



