module Arkham.Scenarios.TheMiskatonicMuseum.Helpers where

import Arkham.Classes
import Arkham.Classes.HasGame
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Id
import Arkham.Matcher
import Arkham.Prelude

getInPlayHuntingHorror :: HasGame m => m (Maybe EnemyId)
getInPlayHuntingHorror = getHuntingHorrorWith AnyInPlayEnemy

getHuntingHorror :: HasGame m => m (Maybe EnemyId)
getHuntingHorror = getHuntingHorrorWith AnyEnemy

getHuntingHorrorWith :: HasGame m => EnemyMatcher -> m (Maybe EnemyId)
getHuntingHorrorWith matcher = selectOne $ enemyIs Cards.huntingHorror <> matcher

getRestrictedHall :: HasGame m => m LocationId
getRestrictedHall = selectJust $ LocationWithFullTitle "Exhibit Hall" "Restricted Hall"
