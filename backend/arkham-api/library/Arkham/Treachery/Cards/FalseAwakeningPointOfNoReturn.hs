module Arkham.Treachery.Cards.FalseAwakeningPointOfNoReturn (falseAwakeningPointOfNoReturn) where

import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Cards.FalseAwakening
import Arkham.Treachery.Import.Lifted

newtype FalseAwakeningPointOfNoReturn = FalseAwakeningPointOfNoReturn FalseAwakening
  deriving anyclass (IsTreachery, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

instance HasAbilities FalseAwakeningPointOfNoReturn where
  getAbilities (FalseAwakeningPointOfNoReturn inner) = getAbilities inner

falseAwakeningPointOfNoReturn :: TreacheryCard FalseAwakeningPointOfNoReturn
falseAwakeningPointOfNoReturn = treachery (FalseAwakeningPointOfNoReturn . FalseAwakening) Cards.falseAwakeningPointOfNoReturn

instance RunMessage FalseAwakeningPointOfNoReturn where
  runMessage msg (FalseAwakeningPointOfNoReturn inner) =
    FalseAwakeningPointOfNoReturn <$> runMessage msg inner
