module Arkham.Asset.Assets.MrPeabody (mrPeabody, mrPeabodyEffect, MrPeabody (..)) where

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Import.Lifted
import Arkham.Effect.Import
import Arkham.Matcher
import Arkham.Message.Lifted.Choose
import Arkham.Modifier
import Arkham.Trait (Trait (Passageway))

newtype MrPeabody = MrPeabody AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

mrPeabody :: AssetCard MrPeabody
mrPeabody = ally MrPeabody Cards.mrPeabody (2, 2)

instance HasAbilities MrPeabody where
  getAbilities (MrPeabody attrs) = [restrictedAbility attrs 1 ControlsThis $ actionAbilityWithCost (exhaust attrs)]

instance RunMessage MrPeabody where
  runMessage msg a@(MrPeabody attrs) = runQueueT $ case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      locations <- select Anywhere
      chooseTargetM iid locations $ createCardEffect Cards.mrPeabody Nothing (attrs.ability 1)
      pure a
    _ -> MrPeabody <$> liftRunMessage msg attrs

newtype MrPeabodyEffect = MrPeabodyEffect EffectAttrs
  deriving anyclass (HasAbilities, IsEffect)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

mrPeabodyEffect :: EffectArgs -> MrPeabodyEffect
mrPeabodyEffect = cardEffect MrPeabodyEffect Cards.mrPeabody

instance HasModifiersFor MrPeabodyEffect where
  getModifiersFor target (MrPeabodyEffect attrs) | attrs.target == target = do
    toModifiers attrs [ShroudModifier (-1), AddTrait Passageway]
  getModifiersFor _ _ = pure []

instance RunMessage MrPeabodyEffect where
  runMessage msg e@(MrPeabodyEffect attrs) = runQueueT $ case msg of
    Ready (AssetTarget aid) | isSource aid attrs.source -> disableReturn e
    _ -> MrPeabodyEffect <$> liftRunMessage msg attrs
