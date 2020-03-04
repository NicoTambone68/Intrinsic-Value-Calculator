# Intrinsic Value Calculator
## An utility in Haskell to evaluate stock quotes through the discounted cash flow methodology

### Introduction

The idea of intrinsic value of a stock has been brought to the general public by Ben Graham in the late forties. The intrinsic value is the price of a stock based on the current assets and liabilities of the company plus the expected future revenues on a given time horizon, e.g. 10 years. In other words, the intrinsic value is the fair price an investor would pay today for a stock she will be going to sell ten years from now. Moreover Graham introduced the idea of Margin of Safety, that is a discount factor that we should apply to the Intrinsic Value as an additional safety to face the investment risk.

### Implementation

The program has been implemented in Haskell as an example of a real-world application of this great functional language.

### Using the program

The program reads a csv file (named ivcalc.csv) containing financial data as in the following example.

```
ticker,beta,cashflowop,growth5,growth10,cash,debt,sharesoutst,currprice
TIKER1,1.6,38510,0.3008,0.15,55020,23410,490.86,2300.1
TIKER2,1.2,19790,0.2008,0.15,35620,13220,200.16,980.5
TIKER3,1.1,45610,0.1000,0.05,30020,43410,590.18,405.21
TIKER4,0.6,56000,0.1200,0.05,75020,33410,190.26,2322.11
```

The output is presented on screen
```
--------------------------------------------------------
Ticker | Intrinsic Value |  Current Price |   Evaluation
--------------------------------------------------------
 TIKER1           1870.46          2300.10   Strong Sell
 TIKER2           1918.13           980.50   Buy
 TIKER3            838.91           405.21   Strong Buy
 TIKER4           4044.35          2322.11   Hold
```

### Requirements

The program makes use of Cassava libraries. To install these libraries, please use cabal with the following command:

cabal install cassava



