{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Treachery.Cards.AncientEvils where

import Arkham.Json
import Arkham.Types.Classes
import Arkham.Types.Message
import Arkham.Types.Target
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner
import Arkham.Types.TreacheryId
import ClassyPrelude
import Lens.Micro

newtype AncientEvils = AncientEvils Attrs
  deriving newtype (Show, ToJSON, FromJSON)

ancientEvils :: TreacheryId -> a -> AncientEvils
ancientEvils uuid _ = AncientEvils $ baseAttrs uuid "01166"

instance HasActions env investigator AncientEvils where
  getActions i window (AncientEvils attrs) = getActions i window attrs

instance (TreacheryRunner env) => RunMessage env AncientEvils where
  runMessage msg (AncientEvils attrs@Attrs {..}) = case msg of
    Revelation _ tid | tid == treacheryId -> do
      unshiftMessages
        [ PlaceDoomOnAgenda
        , AdvanceAgendaIfThresholdSatisfied
        , Discard (TreacheryTarget tid)
        ]
      AncientEvils <$> runMessage msg (attrs & resolved .~ True)
    _ -> AncientEvils <$> runMessage msg attrs
