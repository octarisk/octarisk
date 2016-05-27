# octarisk
Market Risk Measurement in Octave

This project aims to provide a framework for assessing the market risk of financial portfolios.

The *ultimate goal* is a complete valuation and risk assessment framework for most financial instruments, where risk measures
and stress test impacts on arbitrary portfolios can be calculated. Hereby, state-of-the-art methods and a light-weight and rapid 
calculation shall be implemented with free software only.

The code is written in Octave language and will be useable right out-of-the box with Octave version >= 4.0.0 
and the Statistics and Financial packages.

![Image](http://www.octarisk.com/images/OCTARISK_logo_standard.svg)

## Contributors
Stefan Schloegl (schinzilord@octarisk.com)

## Installation

You need Octave in Version >=4.0.0 with installed statistics and financial package.
Moreover, an efficient linear algebra package is strongly recommended (e.g. OpenBLAS / LaPACK)

Just follow the following steps:
- install Octave either from your distro repository (`sudo apt-get install octave` or `yum install octave-forge`) or directly from the binaries
- install IO, Statistics and Financial packages. Therefore type at the running Octave command line:

```
pkg install -forge io
pkg install -forge statistics
pkg install -forge financial
```

- clone the Octarisk repository or download the latest  [release](https://github.com/octarisk/octarisk/releases) and unpack it in your desired folder
- add the path of your Octarisk directory to Octave (mind the forward slashes `/`, even under Windows):

```
addpath ('/path/to/octarisk-latest')
savepath()
```

- start Octarisk with a reference to your working_directory (which can be anywhere on the system where you have wright access). 
An example working_folder is provided in the released data.

```
octarisk ('/path/to/octarisk-latest/working_folder')
```

- the script shall run several seconds and give you two file based reports (you can find the reports under `/path/to/octarisk-latest/working_folder/output/reports`),
four images with each two histograms and bar charts for two test portfolios, and some more details on the Octave screen.

- now you can start adjusting the input data (`/path/to/octarisk-latest/working_folder/input/ and /mktdata`) or change the risk measurement settings directly in the `octarisk.m` script.

For a more detailed installation instruction please refer to this [tutorial](http://www.octarisk.com/tutorial.html).

## Compatibility

Octarisk runs on every system with a running [Octave](https://www.gnu.org/software/octave/) environment in Version >= 4.0.0.
To my knowledge, Octave binaries are provided for MS Windows and many Linux distributions.

A system with at least 4Gb memory is recommended.

Matlab Compatibility:
In the upcomming releases there will be enhanced compatilibity to Matlab provided.
However, more adjustments (regarding automatic broadcasting vs. bsxfun) are necessary. In the future for each major Octave release there will be
detailed instructions how full compatibility with Matlab can be reached and / or a Matlab version will be released.
However, further code development will be still accomplished with Octave (because it is *free* and everybody can contribute and run the code.)
Write me an Email if you need assistance in porting the code basis to Matlab.

## Version history

- Version 0.3.0-rc1 further enhanced file interface, aggregated curves introduced, bug fixes
- Version 0.2.0   enhanced file interface and bug fixes
- Version 0.1.0   first public release

