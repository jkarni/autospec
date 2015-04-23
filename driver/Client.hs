module Main (main) where

import qualified Data.ByteString.Lazy as L

import           Client

main :: IO ()
main = client >>= L.putStr
