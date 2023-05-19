module Arkham.Treachery.Cards.OminousPortents (
  ominousPortents,
  OminousPortents (..),
)
where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.Effect.Window
import Arkham.Helpers
import Arkham.Helpers.Modifiers
import Arkham.Keyword (Keyword (Peril))
import Arkham.Message
import Arkham.Scenarios.TheWagesOfSin.Helpers
import Arkham.SkillType
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype OminousPortents = OminousPortents TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ominousPortents :: TreacheryCard OminousPortents
ominousPortents = treachery OminousPortents Cards.ominousPortents

instance RunMessage OminousPortents where
  runMessage msg t@(OminousPortents attrs) = case msg of
    Revelation iid (isSource attrs -> True) -> do
      mTopSpectralCard <- headMay . unDeck <$> getSpectralDeck
      push
        $ chooseOrRunOne
          iid
        $ [ Label
            "Draw the top card of the spectral encounter deck. That card gains peril, and its effects cannot be canceled."
            [ createWindowModifierEffect
                EffectCardResolutionWindow
                attrs
                (toCardId topSpectralCard)
                [AddKeyword Peril, EffectsCannotBeCanceled]
            , InvestigatorDrewEncounterCard iid (topSpectralCard {ecAddedPeril = True})
            ]
          | topSpectralCard <- maybeToList mTopSpectralCard
          ]
          <> [ Label
                "Test {willpower} (3). If you fail take 2 horror."
                [beginSkillTest iid attrs attrs SkillWillpower 3]
             ]
      pure t
    _ -> OminousPortents <$> runMessage msg attrs
