{-# LANGUAGE OverloadedStrings #-}
module Run where

import           Prelude ()
import           Prelude.Compat
import           Control.Exception
import           Control.Concurrent
import           Control.Monad (void, forever)
import           Data.Foldable
import           Data.List
import           System.FSNotify
import           Filesystem.Path.CurrentOS (encodeString)

import           Interpreter (Session, Summary(..))
import qualified Interpreter
import qualified Http

import           Util
import           EventQueue

waitForever :: IO ()
waitForever = forever $ threadDelay 10000000

watchFiles :: EventQueue -> IO ()
watchFiles queue = void . forkIO $ do
  withManager $ \manager -> do
    _ <- watchTree manager "." (not . isBoring . eventPath) (\event -> emitEvent (Just . encodeString $ eventPath event) queue)
    waitForever

watchInput :: EventQueue -> IO ()
watchInput queue = void . forkIO $ do
  input <- getContents
  forM_ (lines input) $ \_ -> do
    emitEvent Nothing queue
  emitDone queue

run :: [String] -> IO ()
run args = do
  queue <- newQueue
  watchFiles queue
  watchInput queue
  lastOutput <- newMVar (True, "")
  Http.withServer (readMVar lastOutput) $ do
    bracket (Interpreter.new args) Interpreter.close $ \interpreter -> do
      processQueue queue $ modifyMVar_ lastOutput $ \_ -> trigger interpreter

runWeb :: [String] -> IO ()
runWeb args = do
  bracket (Interpreter.new args) Interpreter.close $ \interpreter -> do
    _ <- trigger interpreter
    lock <- newMVar ()
    Http.withServer (withMVar lock $ \() -> trigger interpreter) $ do
      waitForever

trigger :: Session -> IO (Bool, String)
trigger interpreter = do
  xs <- Interpreter.reload interpreter
  (ys, summary) <- if "Ok, modules loaded:" `isInfixOf` xs
    then Interpreter.hspec interpreter
    else return ("", Nothing)
  return (maybe False ((== 0) . summaryFailures) summary, xs ++ ys)
