{-
The MIT License (MIT)
Copyright (c) 2020 Nicolò Tambone
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-}

{-# LANGUAGE OverloadedStrings #-}

import Control.Applicative
import qualified Data.ByteString.Lazy as BL
import Data.Csv
import qualified Data.Vector as V
import Text.Printf

--
-- data structure of the records read from csv file
--
data Financials = Financials
    { ticker      :: !String
    , beta        :: !Double
    , cashflowop  :: !Double
    , growth5     :: !Double
    , growth10    :: !Double
    , cash        :: !Double
    , debt        :: !Double
    , sharesoutst :: !Double
    , currprice   :: !Double 
    }


--
-- Fields name of the records from csv file
--
instance FromNamedRecord Financials where
    parseNamedRecord r = Financials <$> r .: "ticker" <*> r .: "beta" <*> r .: "cashflowop" <*> 
                                        r .: "growth5" <*> r .: "growth10" <*> r.: "cash" <*> 
                                        r .: "debt" <*> r .: "sharesoutst" <*> r .: "currprice"


--
-- calcDiscountRate
--
-- The Discount Rate is based on beta which is
-- an indicator of volatility. The higher the volatility,
-- the higher will be the discount rate.
--
calcDiscountRate :: (RealFloat a) => a -> Double
calcDiscountRate beta 
        | beta < 0.8 = 0.05
        | beta >= 0.80 && beta <= 1.0 = 0.060 
        | beta >= 1.01 && beta <= 1.1 = 0.065
        | beta >= 1.11 && beta <= 1.2 = 0.070
        | beta >= 1.21 && beta <= 1.3 = 0.075
        | beta >= 1.31 && beta <= 1.4 = 0.080
        | beta >= 1.41 && beta <= 1.5 = 0.085
        | beta > 1.5 = 0.09



--
-- calcIntrinsicValue
--
-- Estimate the intrinsic value with the Discounted Cash Flow formula.
-- We are going to set a ten years horizon, using a growth rate estimation
-- for the first five years and a different growth rate estimation for the
-- latter five years.
--
calcIntrinsicValue :: Financials -> Double 
calcIntrinsicValue f = (sum(presValueCFVector) + (cash f) - (debt f))/(sharesoutst f)
        where 
            projCF05Vector    = tail ( take 6 ( iterate ((1 + (growth5 f))*) (cashflowop f) ) )
            projCF10Vector    = tail ( take 6 ( iterate ((1 + (growth10 f))*) (last(projCF05Vector)) ) ) 
            projCFVector      = projCF05Vector ++ projCF10Vector
            drVector          = tail (take 11 (iterate ((1 + (calcDiscountRate (beta f)))*) 1 ))
            presValueCFVector = [x/y | (x,y) <- zip projCFVector drVector, y /= 0]

--
-- evaluateStock
--
-- Evaluate the current stock by subtracting the current price from the intrinsic value,
-- then dividing for the i.v. and applying a margin of safety. 
-- This will tell us whether the stock is underrated or overrated based on the future
-- estimated revenues of the company. Then the algorithm will suggest to buy the stock, 
-- otherwise to hold or sell it if it's already in our portfolio.
--
evaluateStock :: Financials -> Double -> String
evaluateStock f m
        | df <  0.011                 = "Strong Buy"
        | df >= 0.011  && df <= 0.05  = "Buy"
        | df >= 0.051  && df <= 0.10  = "Hold"
        | df >= 0.11   && df <= 0.20  = "Sell"
        | df >= 0.21                  = "Strong Sell"
        where 
            df = (((currprice f) - iv)/iv) + m
            iv = calcIntrinsicValue f

--
-- main
--
-- evaluate the stock based on financial data contained in ivcalc.csv 
--
main :: IO ()
main = do
    let marginOfSafety = (0.5 :: Double)
    putStrLn  "--------------------------------------------------------"
    putStrLn $ printf "Evaluating with Margin of Safety = %4.2f%%" (marginOfSafety*100)
    putStrLn  "--------------------------------------------------------"
    putStrLn  "Ticker | Intrinsic Value |  Current Price |   Evaluation"
    putStrLn  "--------------------------------------------------------"
    csvData <- BL.readFile "ivcalc.csv"
    case decodeByName csvData of
        Left err -> putStrLn err
        Right (_, v) -> V.forM_ v $ \ f ->
            putStrLn $ printf "%7s"    (ticker f)                ++ 
                       printf "%18.2f" (calcIntrinsicValue f)    ++ 
                       printf "%17.2f" (currprice f)             ++ "   " ++ 
                       printf "%s"     (evaluateStock f marginOfSafety)


