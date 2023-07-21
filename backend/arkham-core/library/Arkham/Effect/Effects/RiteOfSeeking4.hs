module Arkham.Effect.Effects.RiteOfSeeking4 (
  riteOfSeeking4,
  RiteOfSeeking4 (..),
) where

import Arkham.Prelude

import Arkham.Action qualified as Action
import Arkham.ChaosToken
import Arkham.Classes
import Arkham.Effect.Runner
import Arkham.Message
import Arkham.Window qualified as Window

newtype RiteOfSeeking4 = RiteOfSeeking4 EffectAttrs
  deriving anyclass (HasAbilities, IsEffect, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

riteOfSeeking4 :: EffectArgs -> RiteOfSeeking4
riteOfSeeking4 = RiteOfSeeking4 . uncurry4 (baseAttrs "02233")

instance RunMessage RiteOfSeeking4 where
  runMessage msg e@(RiteOfSeeking4 attrs@EffectAttrs {..}) = case msg of
    RevealChaosToken _ iid token -> case effectTarget of
      InvestigationTarget iid' _ | iid == iid' -> do
        when
          (chaosTokenFace token `elem` [Skull, Cultist, Tablet, ElderThing, AutoFail])
          ( pushAll
              [ If
                  (Window.RevealChaosTokenEffect iid token effectId)
                  [SetActions iid effectSource 0, ChooseEndTurn iid]
              , DisableEffect effectId
              ]
          )
        pure e
      _ -> pure e
    SkillTestEnds _ _ -> do
      case effectTarget of
        InvestigatorTarget iid -> pushAll [DisableEffect effectId, EndTurn iid]
        _ -> push (DisableEffect effectId)
      pure e
    Successful (Action.Investigate, _) iid source _ _
      | effectSource == source -> case effectTarget of
          InvestigationTarget _ lid' -> do
            push
              (InvestigatorDiscoverClues iid lid' (toSource attrs) 2 (Just Action.Investigate))
            pure e
          _ -> pure e
    _ -> RiteOfSeeking4 <$> runMessage msg attrs
