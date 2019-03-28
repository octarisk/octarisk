# octarisk
<p align="center">
  <img src="http://www.octarisk.com/images/OCTARISK_logo_standard.svg" width="150" >
</p>

## Market Risk Measurement in Octave

This project aims to provide a framework for quantifying and analysing
the market risk of financial portfolios.
Insights into the risk contributions allow for efficient risk capital
allocation and increase the financial performance in the long run.

The *ultimate goal* is a complete valuation and risk assessment framework for 
most financial instruments, where risk measures
and stress test impacts on arbitrary portfolios can be calculated. Hereby, 
state-of-the-art methods and a light-weight and rapid 
calculation shall be implemented with free software only.

The code is written in Octave and C++ language and will be useable right out-of-the box 
with Octave version >= 4.4.1 and the Financial and Statistics package. The code 
is licensed under the GNU GPL.

Further information:
[website](http://www.octarisk.com)

[documentation (PDF)](http://www.octarisk.com/documentation/doc_octarisk.pdf)

[documentation (online)](http://www.octarisk.com/documentation/index.html)

[classes and objects (online)](http://www.octarisk.com/documentation/Octave-octarisk-Classes.html#Octave-octarisk-Classes)

[process overview (online)](https://www.octarisk.com/documentation/Implementation-concept.html#Process-overview)

[function and method hierarchy (PDF)](https://www.octarisk.com/download/octarisk_dependencies.pdf)

## Contributors
Stefan Schloegl (schinzilord@octarisk.com)

IRRer-Zins (IRRer-Zins@t-online.de)
## Installation

You need Octave in Version >=4.4.1 with installed financial, io and statistics package.
Moreover, an efficient linear algebra package is strongly recommended (e.g. OpenBLAS / LaPACK)

Just follow these steps:
- install Octave either from your distro repository (`sudo apt-get install octave` 
or `yum install octave-forge`) or directly from the binaries
- install Financial, IO and Statistics package. Therefore type at the Octave command line
(installation may take some minutes to complete):

```
pkg install -forge financial
pkg install -forge io
pkg install -forge statistics
```

- clone the Octarisk repository or download the latest 
[release](https://github.com/octarisk/octarisk/releases) and unpack it 
to your desired folder
- add the path of your Octarisk directory to Octave (mind the forward 
slashes `/`, even under Windows):

```
addpath ('/path/to/octarisk-latest')
savepath()
```
- compile required C++ code by typing on the Octave console (C++11 compiler required)
```
compile_oct_files('/path/to/octarisk-latest')
```
This takes a couple of minutes and compiles into binaries for even faster pricing (the most performance relevant algorithm have been highly optimized in C++).
- adjust the path to your working_directory (which can be 
anywhere on the system where you have write access). 
An example working_folder with pre-defined instruments, risk factors and 
portfolio is provided in the release.
- run unittests and integrationtests
```
unittests()
integrationtests ('/path/to/octarisk-latest/testing_folder')
```
All tests have to be successful (PASS only, no FAILS). Otherwise please make sure all C++ binaries were compiled and financial, io and statistical packages were installed properly. The integrationtests valuate all possible instrument types and calculates portfolio value-at-risk and stress figures (a full end to end test including scenario generation, instrument valuation and portfolio aggregation is performed).

- open script file octarisk_gui.m and set the input path to your installation directory 'path/to/working_folder'. Furthermore adjust the link to the working folder in the second line of the central parameter file 'parameter.csv' or parameter_unix.csv (depending which OS you use)
- start the GUI (which automatically calls octarisk main script) or just call the main script from the console


```
octarisk_gui ('/path/to/octarisk-latest/working_folder')
octarisk ('/path/to/octarisk-latest/working_folder')
```

- the script will run several seconds and gives you two file based reports 
(you can find the reports under `/path/to/octarisk-latest/working_folder/output/reports`),
and instrument and portfolio attributes and risk measures on your screen.

- now you can start using the GUI, adjusting the input data (`/path/to/octarisk-latest/working_folder/input/ and /mktdata`) 
or change the risk measurement settings directly in the `octarisk.m` script.

- for Solvency II asset data regulatory reporting and generation of Tripartite v4.0 compliant reports call the script
```
solvency2_reporting('/path/to/octarisk-latest/sii_stdmodel_folder')
```

For a more detailed installation instruction please refer to this 
[tutorial](http://www.octarisk.com/tutorial.html).

## Compatibility

Octarisk runs on every system with a running [Octave](https://www.gnu.org/software/octave/) 
environment in Version >= 4.4.1.
To my knowledge, Octave binaries are provided for MS Windows and many Linux distributions.

A system with at least 4Gb memory is recommended.

Matlab Compatibility:
In the upcomming releases there will be enhanced compatilibity to Matlab provided.
However, more adjustments (regarding automatic broadcasting vs. bsxfun) are necessary. 
In the future for each major Octave release there will be
detailed instructions how full compatibility with Matlab can be reached and / or 
a Matlab version will be released.
However, further code development will be still accomplished with Octave (because 
it is *free* and everybody can contribute and run the code.)
Write me an Email if you need assistance in porting the code basis to Matlab.
Octave's oct-files with c++ pricing functions needs to be ported to mex-files
in order to provide full Matlab compatibility.

## Version history

- Version 0.5.0	  introduction of Solvency II reporting according to Tripartitie v4.0 standard
- Version 0.4.4  bug fixes, stability and performance improvements (dropped support for Octave 4.2)
- Version 0.4.3   fixed compatibility issues with Octave 4.4.0 release, minor bug fixes, more statistical tests
- Version 0.4.2   introduction of CDS and Sobol number generator, minor bug fixes
- Version 0.4.1   introduction of a GUI and a batch mode, minor bug fixes
- Version 0.4.0   massive speed impprovements, enhanced documentation, modified stress test interface
- Version 0.3.5   more instruments, refactored code, enhanced documentation
- Version 0.3.4   various performance improvements, enhanced documentation
- Version 0.3.3   introduction of c++ pricing functions, enhanced volatility framework
- Version 0.3.2   introduction of a session-like instrument valuation interface, new instruments
- Version 0.3.1   enhanced testing features for regression and integration tests 
- Version 0.3.0   independent validation of all pricing functions, unittests, bug fixes
- Version 0.3.0-rc1 further enhanced file interface, aggregated curves introduced, bug fixes
- Version 0.2.0   enhanced file interface and bug fixes
- Version 0.1.0   first public release

## Alternative Solutions

The following alternative commercial and proprietary solutions exist:
- [IBM Algorithmics](http://www-03.ibm.com/software/products/en/algomarkrisk)
- [Sungard / FIS Frontarena](https://www.sungard.com/solutions/trading-network-services/trade-order-management/front-arena/front-arena-position-risk-management)
- [Numerix](http://www.numerix.com/product/market-risk)
- [Quaternion](https://www.quaternion.com/software-solutions/) (which relies on 
Quantlib libraries, but is fully proprietary)
- [QuantLib](http://quantlib.org/index.shtml) is an open source library for 
instrument pricing. The QuantLib repository could serve as a basis for Octave 
code adaptions

Up to my knowledge, there is only one free and open solution for measuring market risk
- [OpenGamma](http://www.opengamma.com/solutions/market-risk) including tools for 
measuring market risk and a margining toolset.

You can also download the code of the OpenGamma platform from 
[Github](https://github.com/OpenGamma/Strata). 
However, I have not tested their solution and can neither compare the performance 
nor the features between Octarisk and OpenGamma.

Octarisk focusses on being fast, light-weight and easy to set up and maintain. 
Therefore it contrasts the feature-rich proprietary solutions with massive overheads 
which are in use by financial institutions.

Nevertheless, Octarisk can be used for portfolios with several thousands instruments 
and risk factors. Therefore it is best suited to use it as an independent
tool to validate the results of proprietary solutions or as a (starting) point for 
a full in-house market risk measurement solution.

The costs of using Octarisk are low, since the licensing costs
both for Octave and Octarisk are zero. The money can be spent on in-house 
or external support for development of new features and maintenance. 
As a result you do not face vendor lock-in and have full transparency - forever.


