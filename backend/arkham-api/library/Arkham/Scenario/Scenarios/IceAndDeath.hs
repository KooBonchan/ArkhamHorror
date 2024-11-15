module Arkham.Scenario.Scenarios.IceAndDeath (IceAndDeath (..), iceAndDeath) where

import Arkham.Asset.Cards qualified as Assets
import Arkham.Card.CardDef
import Arkham.EncounterSet qualified as Set
import Arkham.Investigator.Cards qualified as Investigators
import Arkham.Matcher
import Arkham.Scenario.Import.Lifted
import Arkham.Scenarios.IceAndDeath.Helpers

newtype IceAndDeath = IceAndDeath ScenarioAttrs
  deriving anyclass (IsScenario, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

iceAndDeath :: Difficulty -> IceAndDeath
iceAndDeath difficulty = scenario IceAndDeath "08501" "Ice and Death" difficulty []

instance HasChaosTokenValue IceAndDeath where
  getChaosTokenValue iid tokenFace (IceAndDeath attrs) = case tokenFace of
    Skull -> pure $ toChaosTokenValue attrs Skull 3 5
    Cultist -> pure $ ChaosTokenValue Cultist NoModifier
    Tablet -> pure $ ChaosTokenValue Tablet NoModifier
    ElderThing -> pure $ ChaosTokenValue ElderThing NoModifier
    otherFace -> getChaosTokenValue iid otherFace attrs

expeditionTeam :: NonEmpty CardDef
expeditionTeam =
  Assets.drAmyKenslerProfessorOfBiology
    :| [ Assets.professorWilliamDyerProfessorOfGeology
       , Assets.danforthBrilliantStudent
       , Assets.roaldEllsworthIntrepidExplorer
       , Assets.takadaHirokoAeroplaneMechanic
       , Assets.averyClaypoolAntarcticGuide
       , Assets.drMalaSinhaDaringPhysician
       , Assets.jamesCookieFredericksDubiousChoice
       , Assets.eliyahAshevakDogHandler
       ]

instance RunMessage IceAndDeath where
  runMessage msg s@(IceAndDeath attrs) = runQueueT $ scenarioI18n $ case msg of
    StartCampaign -> do
      recordSetInsert ExpeditionTeam $ map (.cardCode) expeditionTeam
      pure s
    PreScenarioSetup -> do
      story $ i18nWithTitle "iceAndDeath"
      doStep 1 PreScenarioSetup
      pure s
    DoStep 1 PreScenarioSetup -> do
      story $ i18nWithTitle "iceAndDeathPart1Intro1"

      selectAny (investigatorIs Investigators.winifredHabbamock) >>= \case
        True -> doStep 2 PreScenarioSetup
        False -> doStep 3 PreScenarioSetup

      pure s
    DoStep 2 PreScenarioSetup -> do
      story $ i18nWithTitle "iceAndDeathPart1Intro2"
      doStep 4 PreScenarioSetup
      pure s
    DoStep 3 PreScenarioSetup -> do
      story $ i18nWithTitle "iceAndDeathPart1Intro3"
      doStep 4 PreScenarioSetup
      pure s
    DoStep 4 PreScenarioSetup -> do
      story $ i18nWithTitle "iceAndDeathPart1Intro4"
      killed <- sample expeditionTeam
      crossOutRecordSetEntries ExpeditionTeam [killed.cardCode]
      pure s
    Setup -> runScenarioSetup IceAndDeath attrs do
      gather Set.IceAndDeath
    _ -> IceAndDeath <$> liftRunMessage msg attrs
