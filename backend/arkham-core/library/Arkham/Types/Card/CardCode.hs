module Arkham.Types.Card.CardCode where

import ClassyPrelude
import Data.Aeson

newtype CardCode = CardCode { unCardCode :: Text }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable, IsString)

newtype LocationCardCode = LocationCardCode { unLocationCardCode :: CardCode }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable, IsString)

newtype ResignedCardCode = ResignedCardCode { unResignedCardCode :: CardCode }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable, IsString)

newtype CommittedCardCode = CommittedCardCode { unCommittedCardCode :: CardCode }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable, IsString)

newtype TreacheryCardCode = TreacheryCardCode { unTreacheryCardCode :: CardCode }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable, IsString)

newtype VictoryDisplayCardCode = VictoryDisplayCardCode { unVictoryDisplayCardCode :: CardCode }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable, IsString)

class HasCardCode a where
  toCardCode :: a -> CardCode

instance HasCardCode CardCode where
  toCardCode = id
