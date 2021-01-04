module Arkham.Types.Location.Helpers
  ( module X
  , module Arkham.Types.Location.Helpers
  )
where

import Arkham.Prelude

import Arkham.Types.Ability
import qualified Arkham.Types.Action as Action
import Arkham.Types.Classes.Entity
import Arkham.Types.Cost
import Arkham.Types.Game.Helpers as X
import Arkham.Types.InvestigatorId
import Arkham.Types.Message

resignAction :: Entity a => InvestigatorId -> a -> Message
resignAction iid a = ActivateCardAbilityAction
  iid
  (mkAbility (toSource a) 99 (ActionAbility (Just Action.Resign) (ActionCost 1))
  )
