{-# LANGUAGE RecordWildCards, TypeFamilies, FlexibleInstances, MultiParamTypeClasses, OverloadedStrings, TupleSections #-}
module Aws.SimpleDb.Commands.Domain where

import           Aws.Core
import           Aws.SimpleDb.Info
import           Aws.SimpleDb.Metadata
import           Aws.SimpleDb.Query
import           Aws.SimpleDb.Response
import           Control.Applicative
import           Data.Maybe
import           Data.Time
import           Data.Time.Clock.POSIX
import           Text.XML.Cursor       (($//), (&|))
import qualified Data.Text             as T
import qualified Data.Text.Encoding    as T

data CreateDomain
    = CreateDomain {
        cdDomainName :: T.Text
      }
    deriving (Show)

data CreateDomainResponse 
    = CreateDomainResponse
    deriving (Show)
             
createDomain :: T.Text -> CreateDomain
createDomain name = CreateDomain { cdDomainName = name }
             
instance SignQuery CreateDomain where
    type Info CreateDomain = SdbInfo
    signQuery CreateDomain{..} = sdbSignQuery [("Action", "CreateDomain"), ("DomainName", T.encodeUtf8 cdDomainName)]

instance ResponseConsumer r CreateDomainResponse where
    type ResponseMetadata CreateDomainResponse = SdbMetadata
    responseConsumer _ = sdbResponseConsumer $ sdbCheckResponseType CreateDomainResponse "CreateDomainResponse"

instance Transaction CreateDomain CreateDomainResponse

data DeleteDomain
    = DeleteDomain {
        ddDomainName :: T.Text
      }
    deriving (Show)

data DeleteDomainResponse
    = DeleteDomainResponse
    deriving (Show)
             
deleteDomain :: T.Text -> DeleteDomain
deleteDomain name = DeleteDomain { ddDomainName = name }
             
instance SignQuery DeleteDomain where
    type Info DeleteDomain = SdbInfo
    signQuery DeleteDomain{..} = sdbSignQuery [("Action", "DeleteDomain"), ("DomainName", T.encodeUtf8 ddDomainName)]

instance ResponseConsumer r DeleteDomainResponse where
    type ResponseMetadata DeleteDomainResponse = SdbMetadata
    responseConsumer _ = sdbResponseConsumer $ sdbCheckResponseType DeleteDomainResponse "DeleteDomainResponse"

instance Transaction DeleteDomain DeleteDomainResponse

data DomainMetadata
    = DomainMetadata {
        dmDomainName :: T.Text
      }
    deriving (Show)

data DomainMetadataResponse
    = DomainMetadataResponse {
        dmrTimestamp :: UTCTime
      , dmrItemCount :: Integer
      , dmrAttributeValueCount :: Integer
      , dmrAttributeNameCount :: Integer
      , dmrItemNamesSizeBytes :: Integer
      , dmrAttributeValuesSizeBytes :: Integer
      , dmrAttributeNamesSizeBytes :: Integer
      }
    deriving (Show)

domainMetadata :: T.Text -> DomainMetadata
domainMetadata name = DomainMetadata { dmDomainName = name }

instance SignQuery DomainMetadata where
    type Info DomainMetadata = SdbInfo
    signQuery DomainMetadata{..} = sdbSignQuery [("Action", "DomainMetadata"), ("DomainName", T.encodeUtf8 dmDomainName)]

instance ResponseConsumer r DomainMetadataResponse where
    type ResponseMetadata DomainMetadataResponse = SdbMetadata

    responseConsumer _ = sdbResponseConsumer parse
        where parse cursor = do
                sdbCheckResponseType () "DomainMetadataResponse" cursor
                dmrTimestamp <- forceM "Timestamp expected" $ cursor $// elCont "Timestamp" &| (fmap posixSecondsToUTCTime . readInt)
                dmrItemCount <- forceM "ItemCount expected" $ cursor $// elCont "ItemCount" &| readInt
                dmrAttributeValueCount <- forceM "AttributeValueCount expected" $ cursor $// elCont "AttributeValueCount" &| readInt
                dmrAttributeNameCount <- forceM "AttributeNameCount expected" $ cursor $// elCont "AttributeNameCount" &| readInt
                dmrItemNamesSizeBytes <- forceM "ItemNamesSizeBytes expected" $ cursor $// elCont "ItemNamesSizeBytes" &| readInt
                dmrAttributeValuesSizeBytes <- forceM "AttributeValuesSizeBytes expected" $ cursor $// elCont "AttributeValuesSizeBytes" &| readInt
                dmrAttributeNamesSizeBytes <- forceM "AttributeNamesSizeBytes expected" $ cursor $// elCont "AttributeNamesSizeBytes" &| readInt
                return DomainMetadataResponse{..}

instance Transaction DomainMetadata DomainMetadataResponse

data ListDomains
    = ListDomains {
        ldMaxNumberOfDomains :: Maybe Int
      , ldNextToken :: Maybe T.Text
      }
    deriving (Show)

data ListDomainsResponse
    = ListDomainsResponse {
        ldrDomainNames :: [T.Text]
      , ldrNextToken :: Maybe T.Text
      }
    deriving (Show)

listDomains :: ListDomains
listDomains = ListDomains { ldMaxNumberOfDomains = Nothing, ldNextToken = Nothing }

instance SignQuery ListDomains where
    type Info ListDomains = SdbInfo
    signQuery ListDomains{..} = sdbSignQuery $ catMaybes [
                                  Just ("Action", "ListDomains")
                                , ("MaxNumberOfDomains",) . T.encodeUtf8 . T.pack . show <$> ldMaxNumberOfDomains
                                , ("NextToken",) . T.encodeUtf8 <$> ldNextToken
                                ]

instance ResponseConsumer r ListDomainsResponse where
    type ResponseMetadata ListDomainsResponse = SdbMetadata
    responseConsumer _ = sdbResponseConsumer parse
        where parse cursor = do
                sdbCheckResponseType () "ListDomainsResponse" cursor
                let names = cursor $// elContent "DomainName"
                let nextToken = listToMaybe $ cursor $// elContent "NextToken"
                return $ ListDomainsResponse names nextToken

instance Transaction ListDomains ListDomainsResponse
