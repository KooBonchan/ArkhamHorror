module Arkham.Asset.Assets.ThomasDawsonSoldierInANewWar (
  thomasDawsonSoldierInANewWar,
  ThomasDawsonSoldierInANewWar (..),
)
where

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Import.Lifted
import Arkham.Capability
import Arkham.Helpers.Window
import Arkham.Matcher
import Arkham.Modifier

newtype ThomasDawsonSoldierInANewWar = ThomasDawsonSoldierInANewWar AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

thomasDawsonSoldierInANewWar :: AssetCard ThomasDawsonSoldierInANewWar
thomasDawsonSoldierInANewWar = asset ThomasDawsonSoldierInANewWar Cards.thomasDawsonSoldierInANewWar

instance HasModifiersFor ThomasDawsonSoldierInANewWar where
  getModifiersFor target (ThomasDawsonSoldierInANewWar a) = modified a $ case target of
    InvestigatorTarget iid | iid `controls` a -> [SkillModifier #willpower 1, SkillModifier #combat 1]
    _ -> []

instance HasAbilities ThomasDawsonSoldierInANewWar where
  getAbilities (ThomasDawsonSoldierInANewWar a) =
    [ restrictedAbility a 1 ControlsThis
        $ ReactionAbility
          ( EnemyAttacksEvenIfCancelled
              #after
              (affectsOthers $ InvestigatorAt YourLocation <> can.draw.cards)
              AnyEnemyAttack
              AnyEnemy
          )
          (exhaust a)
    ]

instance RunMessage ThomasDawsonSoldierInANewWar where
  runMessage msg a@(ThomasDawsonSoldierInANewWar attrs) = runQueueT $ case msg of
    UseCardAbility _iid (isSource attrs -> True) 1 (getAttackDetails -> details) _ -> do
      case details.target of
        InvestigatorTarget iid' -> drawCardsIfCan iid' (attrs.ability 1) 1
        _ -> pure ()
      pure a
    _ -> ThomasDawsonSoldierInANewWar <$> liftRunMessage msg attrs
