{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Treachery.Cards.HuntingShadow where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype HuntingShadow = HuntingShadow Attrs
  deriving newtype (Show, ToJSON, FromJSON)

huntingShadow :: TreacheryId -> a -> HuntingShadow
huntingShadow uuid _ = HuntingShadow $ baseAttrs uuid "01135"

instance HasModifiersFor env HuntingShadow where
  getModifiersFor = noModifiersFor

instance HasActions env HuntingShadow where
  getActions i window (HuntingShadow attrs) = getActions i window attrs

instance (TreacheryRunner env) => RunMessage env HuntingShadow where
  runMessage msg (HuntingShadow attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      playerSpendableClueCount <- unSpendableClueCount <$> getCount iid
      if playerSpendableClueCount > 0
        then unshiftMessage
          (Ask iid $ ChooseOne
            [ Label "Spend 1 clue" [SpendClues 1 [iid]]
            , Label "Take 2 damage" [InvestigatorAssignDamage iid source 2 0]
            ]
          )
        else unshiftMessage (InvestigatorAssignDamage iid source 2 0)
      HuntingShadow <$> runMessage msg (attrs & resolved .~ True)
    _ -> HuntingShadow <$> runMessage msg attrs
