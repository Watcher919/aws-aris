{-# LANGUAGE DeriveDataTypeable, MultiParamTypeClasses #-}
module Aws.SimpleDb.Error
where

import           Aws.Metadata
import           Aws.SimpleDb.Metadata
import           Aws.Xml
import           Data.Typeable
import qualified Control.Exception         as C
import qualified Network.HTTP.Types        as HTTP

type ErrorCode = String

data SdbError
    = SdbError {
        sdbStatusCode :: HTTP.Status
      , sdbErrorCode :: ErrorCode
      , sdbErrorMessage :: String
      , sdbErrorMetadata :: Maybe SdbMetadata
      }
    | SdbXmlError { 
        sdbXmlErrorMessage :: String
      , sdbXmlErrorMetadata :: Maybe SdbMetadata
      }
    deriving (Show, Typeable)

instance WithMetadata SdbError SdbMetadata where
    getMetadata SdbError { sdbErrorMetadata = err }       = err
    getMetadata SdbXmlError { sdbXmlErrorMetadata = err } = err

    setMetadata m e@SdbError{}    = e { sdbErrorMetadata = Just m }
    setMetadata m e@SdbXmlError{} = e { sdbXmlErrorMetadata = Just m }

instance C.Exception SdbError

sdbForce :: String -> [a] -> Either SdbError a
sdbForce msg = force (SdbXmlError msg Nothing)

sdbForceM :: String -> [Either SdbError a] -> Either SdbError a
sdbForceM msg = forceM (SdbXmlError msg Nothing)
