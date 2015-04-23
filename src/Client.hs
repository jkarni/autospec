module Client (client) where

import           Prelude ()
import           Prelude.Compat
import           Network.HTTP.Client
import           Network.HTTP.Client.Internal
import           Network.Socket hiding (recv)
import           Network.Socket.ByteString (sendAll, recv)
import qualified Data.ByteString.Lazy as L

import           Http (newSocket, socketAddr)

client :: IO L.ByteString
client = simpleHttp "http://typeful.net"

simpleHttp :: String -> IO L.ByteString
simpleHttp url = do
  withManager defaultManagerSettings {managerRawConnection = return newConnection} $ \manager -> do
    req <- parseUrl url
    responseBody <$> httpLbs req manager
  where
    newConnection _ _ _ = do
      sock <- newSocket
      connect sock socketAddr
      socketConnection sock 8192

socketConnection :: Socket -> Int -> IO Connection
socketConnection sock chunksize = makeConnection (recv sock chunksize) (sendAll sock) (sClose sock)
