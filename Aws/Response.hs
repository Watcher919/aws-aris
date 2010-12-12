{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}

module Aws.Response
where
  
import           Aws.Http
import           Control.Monad.Compose.Class
import           Control.Monad.Error.Class
import           Control.Monad.Reader.Class
import           Text.XML.Monad
import qualified Data.ByteString.Lazy.UTF8   as BLU
import qualified Text.XML.Light              as XL

data Response
    = Response {
        httpResponse :: HttpResponse
      }
    deriving (Show)

class FromResponse a e where
    fromResponse :: Response -> Either e a

instance FromResponse Response e where
    fromResponse = Right

fromResponseXml :: Xml e Response a -> Response -> Either e a
fromResponseXml = runXml

parseXmlResponse :: (FromXmlError e, Error e) => Xml e Response XL.Element
parseXmlResponse = parseXMLDoc <<< asks (BLU.toString . responseBody . httpResponse)
