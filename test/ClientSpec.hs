{-# LANGUAGE OverloadedStrings #-}
module ClientSpec (spec) where

import           Helper

import           Http
import           Client

spec :: Spec
spec = do
  describe "client" $ do
    it "does a HTTP request via a Unix domain socket" $ do
      inTempDirectory $ do
        withServer (return (True, "hello")) $ do
          client `shouldReturn` "hello"
