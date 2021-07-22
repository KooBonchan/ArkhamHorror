module Arkham.Types.Act.Cards.Fold
  ( Fold(..)
  , fold
  ) where

import Arkham.Prelude hiding (fold)

import Arkham.Types.Ability
import Arkham.Types.Act.Attrs
import Arkham.Types.Act.Helpers
import Arkham.Types.Act.Runner
import Arkham.Types.Action
import Arkham.Types.AssetId
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.GameValue
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Query
import Arkham.Types.Resolution
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Window

newtype Fold = Fold ActAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasModifiersFor env)

fold :: Fold
fold = Fold $ baseAttrs "02069" "Fold" (Act 3 A) Nothing

instance ActionRunner env => HasActions env Fold where
  getActions iid NonFast (Fold attrs) = withBaseActions iid NonFast attrs $ do
    investigatorLocationId <- getId @LocationId iid
    maid <- fmap unStoryAssetId <$> getId (CardCode "02079")
    case maid of
      Nothing -> pure []
      Just aid -> do
        miid <- fmap unOwnerId <$> getId aid
        assetLocationId <- getId aid
        pure
          [ UseAbility
              iid
              (mkAbility
                (ProxySource (AssetSource aid) (toSource attrs))
                1
                (ActionAbility (Just Parley) $ ActionCost 1)
              )
          | isNothing miid && Just investigatorLocationId == assetLocationId
          ]
  getActions i window (Fold x) = getActions i window x

instance ActRunner env => RunMessage env Fold where
  runMessage msg a@(Fold attrs@ActAttrs {..}) = case msg of
    InvestigatorResigned _ -> do
      investigatorIds <- getSet @InScenarioInvestigatorId ()
      a <$ when
        (null investigatorIds)
        (push $ AdvanceAct actId (toSource attrs))
    AdvanceAct aid _ | aid == actId && onSide B attrs -> do
      maid <- fmap unStoryAssetId <$> getId (CardCode "02079")
      a <$ case maid of
        Nothing -> push (ScenarioResolution $ Resolution 1)
        Just assetId -> do
          miid <- fmap unOwnerId <$> getId assetId
          push
            (ScenarioResolution
            $ maybe (Resolution 1) (const (Resolution 2)) miid
            )
    UseCardAbility iid (ProxySource _ source) _ 1 _
      | isSource attrs source && actSequence == Act 3 A -> do
        maid <- fmap unStoryAssetId <$> getId (CardCode "02079")
        case maid of
          Nothing -> error "this ability should not be able to be used"
          Just aid -> a <$ push
            (BeginSkillTest
              iid
              source
              (AssetTarget aid)
              (Just Parley)
              SkillWillpower
              3
            )
    PassedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source && actSequence == Act 3 A -> do
        maid <- fmap unStoryAssetId <$> getId (CardCode "02079")
        case maid of
          Nothing -> error "this ability should not be able to be used"
          Just aid -> do
            currentClueCount <- unClueCount <$> getCount aid
            requiredClueCount <- getPlayerCountValue (PerPlayer 1)
            push (PlaceClues (AssetTarget aid) 1)
            a <$ when
              (currentClueCount + 1 >= requiredClueCount)
              (push $ TakeControlOfAsset iid aid)
    _ -> Fold <$> runMessage msg attrs
