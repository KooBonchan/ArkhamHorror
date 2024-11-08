module Arkham.Event.Events.UncageTheSoul3 (uncageTheSoul3, UncageTheSoul3 (..)) where

import Arkham.Asset.Types (Field (..))
import Arkham.Cost
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Import.Lifted
import Arkham.Game.Helpers (getIsPlayableWithResources)
import Arkham.Helpers.Cost (getSpendableResources)
import Arkham.Helpers.Message (handleTargetChoice)
import Arkham.Matcher hiding (AssetCard, PlayCard)
import Arkham.Modifier
import Arkham.Projection
import Arkham.Window (defaultWindows)

newtype UncageTheSoul3 = UncageTheSoul3 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

uncageTheSoul3 :: EventCard UncageTheSoul3
uncageTheSoul3 = event UncageTheSoul3 Cards.uncageTheSoul3

instance RunMessage UncageTheSoul3 where
  runMessage msg e@(UncageTheSoul3 attrs) = runQueueT $ case msg of
    PlayThisEvent iid eid | eid == toId attrs -> do
      assets <- select $ assetControlledBy iid <> DiscardableAsset <> oneOf [#spell, #ritual]
      rs <- (+ 3) <$> getSpendableResources iid
      assets' <- flip filterM assets \aid -> do
        card <- field AssetCard aid
        getIsPlayableWithResources iid attrs rs (UnpaidCost NoAction) (defaultWindows iid) card
      results <-
        select
          $ oneOf
            [ inHandOf iid <> basic (oneOf [#spell, #ritual])
            , inDiscardOf iid <> basic (oneOf [#spell, #ritual])
            ]
      if null results
        then chooseOrRunOneToHandle iid attrs assets'
        else unless (null assets) do
          chooseOne iid $ Label "Do not discard asset" []
            : targetLabels assets (only . handleTargetChoice iid attrs)
      doStep 1 msg
      pure e
    HandleTargetChoice iid (isSource attrs -> True) (AssetTarget aid) -> do
      toDiscardBy iid attrs aid
      pure e
    DoStep 1 (PlayThisEvent iid eid) | eid == toId attrs -> do
      let ws = defaultWindows iid
      rs <- (+ 3) <$> getSpendableResources iid

      cards <-
        filterM (getIsPlayableWithResources iid GameSource rs (UnpaidCost NoAction) ws)
          =<< select
            ( oneOf
                [ inHandOf iid <> basic (oneOf [#spell, #ritual])
                , inDiscardOf iid <> basic (oneOf [#spell, #ritual])
                ]
            )
      chooseTargetM iid cards \c -> do
        push $ AddToHandQuiet iid [c]
        costModifier attrs c (ReduceCostOf (CardWithId c.id) 3)
        push $ PayCardCost iid c ws
      pure e
    _ -> UncageTheSoul3 <$> liftRunMessage msg attrs
