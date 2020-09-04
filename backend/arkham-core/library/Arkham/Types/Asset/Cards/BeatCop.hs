{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Asset.Cards.BeatCop where

import Arkham.Json
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner
import Arkham.Types.AssetId
import Arkham.Types.Classes
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Slot
import Arkham.Types.Source
import Arkham.Types.Target
import ClassyPrelude
import qualified Data.HashSet as HashSet

newtype BeatCop = BeatCop Attrs
  deriving newtype (Show, ToJSON, FromJSON)

beatCop :: AssetId -> BeatCop
beatCop uuid = BeatCop $ (baseAttrs uuid "01018")
  { assetSlots = [AllySlot]
  , assetHealth = Just 2
  , assetSanity = Just 2
  }

instance (IsInvestigator investigator) => HasActions env investigator BeatCop where
  getActions i _ (BeatCop Attrs {..}) | Just (getId () i) == assetInvestigator =
    pure
      [ UseCardAbility
          (getId () i)
          (AssetSource assetId)
          (AssetSource assetId)
          1
      ]
  getActions _ _ _ = pure []

instance (AssetRunner env) => RunMessage env BeatCop where
  runMessage msg a@(BeatCop attrs@Attrs {..}) = case msg of
    InvestigatorPlayAsset iid aid _ _ | aid == assetId -> do
      unshiftMessage
        (AddModifier
          (InvestigatorTarget iid)
          (AssetSource aid)
          (SkillModifier SkillCombat 1)
        )
      pure a
    UseCardAbility iid _ (AssetSource aid) 1 | aid == assetId -> do
      locationId <- asks (getId @LocationId (getInvestigator attrs))
      locationEnemyIds <- HashSet.toList <$> asks (getSet locationId)
      unshiftMessages
        [ Discard (AssetTarget aid)
        , Ask iid $ ChooseOne
          [ EnemyDamage eid iid (AssetSource assetId) 1
          | eid <- locationEnemyIds
          ]
        ]
      pure a
    _ -> BeatCop <$> runMessage msg attrs
