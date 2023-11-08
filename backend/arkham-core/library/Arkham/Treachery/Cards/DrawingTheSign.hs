module Arkham.Treachery.Cards.DrawingTheSign (
  drawingTheSign,
  DrawingTheSign (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Game.Helpers
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype DrawingTheSign = DrawingTheSign TreacheryAttrs
  deriving anyclass (IsTreachery)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

drawingTheSign :: TreacheryCard DrawingTheSign
drawingTheSign = treachery DrawingTheSign Cards.drawingTheSign

instance HasModifiersFor DrawingTheSign where
  getModifiersFor (InvestigatorTarget iid) (DrawingTheSign attrs) =
    pure
      $ toModifiers
        attrs
        [HandSize (-5) | treacheryOnInvestigator iid attrs]
  getModifiersFor _ _ = pure []

instance HasAbilities DrawingTheSign where
  getAbilities (DrawingTheSign a) =
    [ restrictedAbility a 1 OnSameLocation
        $ ActionAbility []
        $ ActionCost 2
    ]

instance RunMessage DrawingTheSign where
  runMessage msg t@(DrawingTheSign attrs) = case msg of
    Revelation iid (isSource attrs -> True) -> do
      push $ attachTreachery attrs iid
      pure t
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      push $ toDiscardBy iid (toAbilitySource attrs 1) attrs
      pure t
    _ -> DrawingTheSign <$> runMessage msg attrs
