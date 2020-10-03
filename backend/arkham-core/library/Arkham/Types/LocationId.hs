module Arkham.Types.LocationId where

import Arkham.Types.Card.CardCode
import ClassyPrelude
import Data.Aeson

newtype LocationId = LocationId { unLocationId :: CardCode }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable, IsString)

newtype ConnectedLocationId = ConnectedLocationId { unConnectedLocationId :: LocationId }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype BlockedLocationId = BlockedLocationId { unBlockedLocationId :: LocationId }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype ClosestLocationId = ClosestLocationId { unClosestLocationId :: LocationId }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype FarthestLocationId = FarthestLocationId { unFarthestLocationId :: LocationId }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype EmptyLocationId = EmptyLocationId { unEmptyLocationId :: LocationId }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)

newtype RevealedLocationId = RevealedLocationId { unRevealedLocationId :: LocationId }
  deriving newtype (Show, Eq, ToJSON, FromJSON, ToJSONKey, FromJSONKey, Hashable)
