{-# LANGUAGE ImplicitParams #-}

module Arkham.Effect.Builder
  ( module X
  , module Arkham.Effect.Builder
  ) where

import Arkham.Duration as X

import Arkham.Calculation.IsCalculation
import Arkham.Matcher.Location
import Arkham.Calculation
import Arkham.Classes.HasGame
import Arkham.Classes.HasQueue
import Arkham.Effect.Types
import Arkham.Effect.Window
import Arkham.EffectMetadata
import Arkham.GameT
import Arkham.Helpers.Modifiers (toModifiers)
import Arkham.Message (Message (CreateEffect))
import Arkham.Message.Lifted.Queue
import Arkham.Modifier
import Arkham.Prelude
import Arkham.Queue
import Arkham.SkillType
import Arkham.Source
import Arkham.Target
import Control.Monad.State.Strict

newtype EffectBuilderT m a = EffectBuilderT {runEffectBuilder :: StateT EffectBuilder m a}
  deriving newtype (Functor, Applicative, Monad, MonadIO, MonadState EffectBuilder)

class WithEffect m where
  effect
    :: (?source :: source, ReverseQueue m, Targetable target, Sourceable source)
    => target -> EffectBuilderT m () -> m ()
  effect target body = do
    effectId <- getRandom
    builder <- execStateT (runEffectBuilder body) =<< makeEffectBuilder "genef" Nothing ?source target
    push $ CreateEffect builder {effectBuilderEffectId = Just effectId}

instance WithEffect (QueueT Message GameT)
instance WithEffect m => WithEffect (StateT s m)

enableOn :: Monad m => EffectWindow -> EffectBuilderT m ()
enableOn window = EffectBuilderT $ do
  b <- get
  put $ b {effectBuilderWindow = Just $ combine window (effectBuilderWindow b)}
 where
  combine w = \case
    Just (FirstEffectWindow ws) -> FirstEffectWindow $ w : ws
    Just ws -> FirstEffectWindow [w, ws]
    Nothing -> w

removeOn :: Monad m => EffectWindow -> EffectBuilderT m ()
removeOn window = EffectBuilderT $ do
  b <- get
  put $ b {effectBuilderDisableWindow = Just $ combine window (effectBuilderDisableWindow b)}
 where
  combine w = \case
    Just (FirstEffectWindow ws) -> FirstEffectWindow $ w : ws
    Just ws -> FirstEffectWindow [w, ws]
    Nothing -> w

instance (Monad m, a ~ ()) => Duration (EffectBuilderT m a) where
  type DurationOf (EffectBuilderT m a) = EffectWindow
  during window = do
    enableOn window
    removeOn window

apply :: HasGame m => ModifierType -> EffectBuilderT m ()
apply modKind = EffectBuilderT $ do
  b <- get
  meta <- addModifier b
  put $ b {effectBuilderMetadata = meta}
 where
  addModifier b = do
    mods <- toModifiers (effectBuilderSource b) [modKind]
    pure $ case effectBuilderMetadata b of
      Just (EffectModifiers mods') ->
        Just $ EffectModifiers $ mods <> mods'
      _ -> Just $ EffectModifiers mods

damageDealt :: HasGame m => Int -> EffectBuilderT m ()
damageDealt n = apply $ DamageDealt n

combat :: HasGame m => GameCalculation -> EffectBuilderT m ()
combat = modifySkill #combat

modifySkill :: HasGame m => SkillType -> GameCalculation -> EffectBuilderT m ()
modifySkill sKind calc = apply $ CalculatedSkillModifier sKind calc

class IfLocation a where
  ifLocation :: LocationMatcher -> a

instance (IsCalculation a, IsCalculation b) => IfLocation (a -> b -> GameCalculation) where
  ifLocation matcher a b = IfLocationExistsCalculation matcher (toCalculation a) (toCalculation b)
