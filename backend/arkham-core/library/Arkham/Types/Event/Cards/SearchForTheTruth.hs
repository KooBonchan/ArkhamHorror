{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Event.Cards.SearchForTheTruth where

import Arkham.Import

import Arkham.Types.Event.Attrs

newtype SearchForTheTruth = SearchForTheTruth Attrs
  deriving newtype (Show, ToJSON, FromJSON)

searchForTheTruth :: InvestigatorId -> EventId -> SearchForTheTruth
searchForTheTruth iid uuid = SearchForTheTruth $ baseAttrs iid uuid "02008"

instance HasModifiersFor env SearchForTheTruth where
  getModifiersFor = noModifiersFor

instance HasActions env SearchForTheTruth where
  getActions i window (SearchForTheTruth attrs) = getActions i window attrs

instance (HasQueue env, HasCount env ClueCount InvestigatorId) => RunMessage env SearchForTheTruth where
  runMessage msg e@(SearchForTheTruth attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> do
      clueCount' <- unClueCount <$> getCount iid
      e <$ unshiftMessages
        [DrawCards iid (min 5 clueCount') False, Discard (toTarget attrs)]
    _ -> SearchForTheTruth <$> runMessage msg attrs
