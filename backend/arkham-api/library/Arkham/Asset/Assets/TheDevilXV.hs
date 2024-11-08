module Arkham.Asset.Assets.TheDevilXV (theDevilXv, TheDevilXV (..)) where

import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Card
import Arkham.Matcher
import Arkham.Prelude

newtype TheDevilXV = TheDevilXV AssetAttrs
  deriving anyclass (IsAsset, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theDevilXv :: AssetCard TheDevilXV
theDevilXv = asset TheDevilXV Cards.theDevilXv

instance HasModifiersFor TheDevilXV where
  getModifiersFor (InvestigatorTarget iid) (TheDevilXV a) = do
    inHand <- selectAny $ InHandOf (InvestigatorWithId iid) <> BasicCardMatch (CardWithId $ toCardId a)
    toModifiers a [CannotPlay $ CardWithType AssetType <> NotCard (CardWithId $ toCardId a) | inHand]
  getModifiersFor _ _ = pure []

instance RunMessage TheDevilXV where
  runMessage msg (TheDevilXV attrs) = TheDevilXV <$> runMessage msg attrs
