# octarisk
Financial Risk Measurement - an Octave based full valuation Monte-Carlo (MC) and stress testing Risk Measurement Tool

This project aims to provide a framework for assessing the risk of financial portfolios - namely calculating portfolio values under stress and in MC scenarios.
Value-At-Risk and other risk measures are calculated on instrumental and positional level.

The code is written in Octave / Matlab language and will be useable right out-of-the box with Octave version >= 4.0.0.

Since this projects is in its starting phase, the full code is not yet accessible. However, more and more parts will be available.

Key features are:
- full valuation of financial instruments in all scenarios
- highly scaleable to thousands of instruments and hundreds of risk factors
- very fast through fully vectorized code (>100000 MC scenarios possible)
- runs in seconds for small portfolios with dozens of instruments
- non-normal assumptions possible with a t-copula approach and defining arbitrary marginal distributions for your risk factors
