# octarisk
Market Risk Measurement in Octave

This project aims to provide a framework for assessing the market risk of financial portfolios.

The code is written in Octave language and will be useable right out-of-the box with Octave version >= 4.0.0.

## Contributors
Stefan Schloegl (schinzilord@octarisk.com)

## Installation

You need Octave in Version >=4.0 with installed statistics and financial package.
Moreover, an efficient linear algebra package is strongly recommended (e.g. OpenBLAS / LaPACK)

For detailed installation instructions please refer to the tutorial at www.octarisk.com.

## Compatibility

Octarisk runs on any system with a running Octave environment in Version >= 4.0.0.
To my knowledge, Octave binaries are provided for MS Windows and many Linux distributions.

A system with at least 4Gb memory is recommended.

Matlab Compatibility:
In the next release there will be enhanced compatilibity to Matlab provided (e.g. replace endXYZ with end, " with ').
However, more adjustments (regarding automatic broadcasting vs. bsxfun) are necessary. In the future for each major Octave release there will be
a separate Matlab compatible release.
Since full compatibility will hardly be reached, the development is focussed on Octave.
Write me an Email if you need assistance in porting the whole code basis to Matlab.

## Version history

Version 0.2.0   enhanced file interface and bug fixes
Version 0.1.0   first public release

