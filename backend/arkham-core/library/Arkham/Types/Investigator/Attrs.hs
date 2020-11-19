{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Investigator.Attrs where

import Arkham.Import

import Arkham.Types.Action (Action)
import qualified Arkham.Types.Action as Action
import Arkham.Types.Card.PlayerCardWithBehavior
import Arkham.Types.CommitRestriction
import Arkham.Types.Investigator.Runner
import Arkham.Types.Stats
import qualified Arkham.Types.Keyword as Keyword
import Arkham.Types.Trait
import Control.Monad.Fail
import Data.Coerce
import qualified Data.HashMap.Strict as HashMap
import qualified Data.HashSet as HashSet
import Data.List ((\\))
import System.Random
import System.Random.Shuffle

instance HasCardCode Attrs where
  getCardCode = unInvestigatorId . investigatorId

data Attrs = Attrs
  { investigatorName :: Text
  , investigatorClass :: ClassSymbol
  , investigatorId :: InvestigatorId
  , investigatorHealth :: Int
  , investigatorSanity :: Int
  , investigatorWillpower :: Int
  , investigatorIntellect :: Int
  , investigatorCombat :: Int
  , investigatorAgility :: Int
  , investigatorHealthDamage :: Int
  , investigatorSanityDamage :: Int
  , investigatorClues :: Int
  , investigatorResources :: Int
  , investigatorLocation :: LocationId
  , investigatorActionsTaken :: [Action]
  , investigatorRemainingActions :: Int
  , investigatorEndedTurn :: Bool
  , investigatorEngagedEnemies :: HashSet EnemyId
  , investigatorAssets :: HashSet AssetId
  , investigatorDeck :: Deck PlayerCard
  , investigatorDiscard :: [PlayerCard]
  , investigatorHand :: [Card]
  , investigatorConnectedLocations :: HashSet LocationId
  , investigatorTraits :: HashSet Trait
  , investigatorTreacheries :: HashSet TreacheryId
  , investigatorDefeated :: Bool
  , investigatorResigned :: Bool
  , investigatorSlots :: HashMap SlotType [Slot]
  , investigatorXP :: Int
  , investigatorPhysicalTrauma :: Int
  , investigatorMentalTrauma :: Int
  -- investigator-specific fields
  , investigatorTomeActions :: Maybe Int
  }
  deriving stock (Show, Generic)

instance ToJSON Attrs where
  toJSON = genericToJSON $ aesonOptions $ Just "investigator"
  toEncoding = genericToEncoding $ aesonOptions $ Just "investigator"

instance FromJSON Attrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "investigator"

locationIdL :: Lens' Attrs LocationId
locationIdL =
  lens investigatorLocation $ \m x -> m { investigatorLocation = x }

xpL :: Lens' Attrs Int
xpL = lens investigatorXP $ \m x -> m { investigatorXP = x }

physicalTraumaL :: Lens' Attrs Int
physicalTraumaL =
  lens investigatorPhysicalTrauma $ \m x -> m { investigatorPhysicalTrauma = x }

mentalTraumaL :: Lens' Attrs Int
mentalTraumaL =
  lens investigatorMentalTrauma $ \m x -> m { investigatorMentalTrauma = x }

connectedLocations :: Lens' Attrs (HashSet LocationId)
connectedLocations = lens investigatorConnectedLocations
  $ \m x -> m { investigatorConnectedLocations = x }

endedTurn :: Lens' Attrs Bool
endedTurn =
  lens investigatorEndedTurn $ \m x -> m { investigatorEndedTurn = x }

resigned :: Lens' Attrs Bool
resigned = lens investigatorResigned $ \m x -> m { investigatorResigned = x }

defeated :: Lens' Attrs Bool
defeated = lens investigatorDefeated $ \m x -> m { investigatorDefeated = x }

resources :: Lens' Attrs Int
resources =
  lens investigatorResources $ \m x -> m { investigatorResources = x }

clues :: Lens' Attrs Int
clues = lens investigatorClues $ \m x -> m { investigatorClues = x }

slots :: Lens' Attrs (HashMap SlotType [Slot])
slots = lens investigatorSlots $ \m x -> m { investigatorSlots = x }

remainingActions :: Lens' Attrs Int
remainingActions = lens investigatorRemainingActions
  $ \m x -> m { investigatorRemainingActions = x }

actionsTaken :: Lens' Attrs [Action]
actionsTaken =
  lens investigatorActionsTaken $ \m x -> m { investigatorActionsTaken = x }

engagedEnemies :: Lens' Attrs (HashSet EnemyId)
engagedEnemies =
  lens investigatorEngagedEnemies $ \m x -> m { investigatorEngagedEnemies = x }

assets :: Lens' Attrs (HashSet AssetId)
assets = lens investigatorAssets $ \m x -> m { investigatorAssets = x }

treacheries :: Lens' Attrs (HashSet TreacheryId)
treacheries =
  lens investigatorTreacheries $ \m x -> m { investigatorTreacheries = x }

healthDamage :: Lens' Attrs Int
healthDamage =
  lens investigatorHealthDamage $ \m x -> m { investigatorHealthDamage = x }

sanityDamage :: Lens' Attrs Int
sanityDamage =
  lens investigatorSanityDamage $ \m x -> m { investigatorSanityDamage = x }

discard :: Lens' Attrs [PlayerCard]
discard = lens investigatorDiscard $ \m x -> m { investigatorDiscard = x }

hand :: Lens' Attrs [Card]
hand = lens investigatorHand $ \m x -> m { investigatorHand = x }

deck :: Lens' Attrs (Deck PlayerCard)
deck = lens investigatorDeck $ \m x -> m { investigatorDeck = x }

instance Entity Attrs where
  toSource = InvestigatorSource . investigatorId
  toTarget = InvestigatorTarget . investigatorId
  isSource Attrs { investigatorId } (InvestigatorSource iid) =
    iid == investigatorId
  isSource _ _ = False
  isTarget Attrs { investigatorId } (InvestigatorTarget iid) =
    iid == investigatorId
  isTarget _ _ = False

getFacingDefeat
  :: (MonadReader env m, HasModifiersFor env env) => Attrs -> m Bool
getFacingDefeat a@Attrs {..} = do
  modifiedHealth <- getModifiedHealth a
  modifiedSanity <- getModifiedSanity a
  pure
    $ investigatorHealthDamage
    >= modifiedHealth
    || investigatorSanityDamage
    >= modifiedSanity

skillValueFor :: SkillType -> Maybe Action -> [Modifier] -> Attrs -> Int
skillValueFor skill maction tempModifiers attrs = foldr
  applyModifier
  (baseSkillValueFor skill maction tempModifiers attrs)
  tempModifiers
 where
  applyModifier (AnySkillValue m) n = max 0 (n + m)
  applyModifier (SkillModifier skillType m) n =
    if skillType == skill then max 0 (n + m) else n
  applyModifier (ActionSkillModifier action skillType m) n =
    if skillType == skill && Just action == maction then max 0 (n + m) else n
  applyModifier _ n = n

baseSkillValueFor :: SkillType -> Maybe Action -> [Modifier] -> Attrs -> Int
baseSkillValueFor skill _maction tempModifiers attrs = foldr
  applyModifier
  baseSkillValue
  tempModifiers
 where
  applyModifier (BaseSkillOf skillType m) _ | skillType == skill = m
  applyModifier _ n = n
  baseSkillValue = case skill of
    SkillWillpower -> investigatorWillpower attrs
    SkillIntellect -> investigatorIntellect attrs
    SkillCombat -> investigatorCombat attrs
    SkillAgility -> investigatorAgility attrs
    SkillWild -> error "investigators do not have wild skills"

damageValueFor
  :: (MonadReader env m, HasModifiersFor env env, HasSource ForSkillTest env)
  => Int
  -> Attrs
  -> m Int
damageValueFor baseValue attrs = do
  source <-
    asks $ fromJustNote "damage outside skill test" . getSource ForSkillTest
  modifiers' <-
    getModifiersFor source (InvestigatorTarget $ investigatorId attrs) =<< ask
  pure $ foldr applyModifier baseValue modifiers'
 where
  applyModifier (DamageDealt m) n = max 0 (n + m)
  applyModifier _ n = n

getIsScenarioAbility
  :: ( HasSource ForSkillTest env
     , MonadReader env m
     , CanBeWeakness TreacheryId env
     )
  => m Bool
getIsScenarioAbility = do
  source <-
    asks $ fromJustNote "damage outside skill test" . getSource ForSkillTest
  case source of
    SkillTestSource _ source' _ -> case source' of
      EnemySource _ -> pure True
      AgendaSource _ -> pure True
      LocationSource _ -> pure True
      TreacherySource tid -> asks $ not . getIsWeakness tid
      ActSource _ -> pure True
      _ -> pure False
    _ -> pure False

getHandSize
  :: (MonadReader env m, HasModifiersFor env env, HasSource ForSkillTest env)
  => Attrs
  -> m Int
getHandSize attrs = do
  source <- asks $ fromMaybe (toSource attrs) . getSource ForSkillTest
  modifiers' <-
    getModifiersFor source (InvestigatorTarget $ investigatorId attrs) =<< ask
  pure $ foldr applyModifier 8 modifiers'
 where
  applyModifier (HandSize m) n = max 0 (n + m)
  applyModifier _ n = n

getActionsForTurn
  :: (MonadReader env m, HasModifiersFor env env) => Attrs -> m Int
getActionsForTurn attrs@Attrs {..} = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  pure $ foldr applyModifier 3 modifiers'
 where
  applyModifier (AdditionalActions m) n = max 0 (n + m)
  applyModifier _ n = n

getCanDiscoverClues
  :: (MonadReader env m, HasModifiersFor env env) => Attrs -> m Bool
getCanDiscoverClues attrs@Attrs {..} = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  pure $ not (any match modifiers')
 where
  match CannotDiscoverClues{} = True
  match _ = False

getCanSpendClues
  :: (MonadReader env m, HasModifiersFor env env) => Attrs -> m Bool
getCanSpendClues attrs@Attrs {..} = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  pure $ not (any match modifiers')
 where
  match CannotSpendClues{} = True
  match _ = False

getModifiedHealth
  :: (MonadReader env m, HasModifiersFor env env) => Attrs -> m Int
getModifiedHealth attrs@Attrs {..} = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  pure $ foldr applyModifier investigatorHealth modifiers'
 where
  applyModifier (HealthModifier m) n = max 0 (n + m)
  applyModifier _ n = n

getModifiedSanity
  :: (MonadReader env m, HasModifiersFor env env) => Attrs -> m Int
getModifiedSanity attrs@Attrs {..} = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  pure $ foldr applyModifier investigatorSanity modifiers'
 where
  applyModifier (SanityModifier m) n = max 0 (n + m)
  applyModifier _ n = n

removeFromSlots :: AssetId -> HashMap SlotType [Slot] -> HashMap SlotType [Slot]
removeFromSlots aid = HashMap.map (map (removeIfMatches aid))

fitsAvailableSlots :: [SlotType] -> [Trait] -> Attrs -> Bool
fitsAvailableSlots slotTypes traits a = null
  (slotTypes \\ concatMap
    (\slotType -> availableSlotTypesFor slotType traits a)
    (setToList (HashSet.fromList slotTypes))
  )

availableSlotTypesFor :: SlotType -> [Trait] -> Attrs -> [SlotType]
availableSlotTypesFor slotType traits a =
  case HashMap.lookup slotType (a ^. slots) of
    Nothing -> []
    Just slots' ->
      replicate (length (filter (canPutIntoSlot traits) slots')) slotType

placeInAvailableSlot :: AssetId -> [Trait] -> [Slot] -> [Slot]
placeInAvailableSlot _ _ [] = error "could not find empty slot"
placeInAvailableSlot aid traits (x : xs) = if canPutIntoSlot traits x
  then putIntoSlot aid x : xs
  else x : placeInAvailableSlot aid traits xs

discardableAssets :: SlotType -> Attrs -> [AssetId]
discardableAssets slotType a = case HashMap.lookup slotType (a ^. slots) of
  Nothing -> []
  Just slots' -> mapMaybe slotItem slots'

discardableCards :: Attrs -> [Card]
discardableCards Attrs {..} = if all cardIsWeakness investigatorHand
  then investigatorHand
  else filter (not . cardIsWeakness) investigatorHand

getAttrStats :: Attrs -> Stats
getAttrStats Attrs {..} = Stats
  { health = investigatorHealth
  , sanity = investigatorSanity
  , willpower = investigatorWillpower
  , intellect = investigatorIntellect
  , combat = investigatorCombat
  , agility = investigatorAgility
  }

baseAttrs :: InvestigatorId -> Text -> ClassSymbol -> Stats -> [Trait] -> Attrs
baseAttrs iid name classSymbol Stats {..} traits = Attrs
  { investigatorName = name
  , investigatorId = iid
  , investigatorClass = classSymbol
  , investigatorHealth = health
  , investigatorSanity = sanity
  , investigatorWillpower = willpower
  , investigatorIntellect = intellect
  , investigatorCombat = combat
  , investigatorAgility = agility
  , investigatorHealthDamage = 0
  , investigatorSanityDamage = 0
  , investigatorClues = 0
  , investigatorResources = 0
  , investigatorLocation = "00000"
  , investigatorActionsTaken = mempty
  , investigatorRemainingActions = 3
  , investigatorEndedTurn = False
  , investigatorEngagedEnemies = mempty
  , investigatorAssets = mempty
  , investigatorDeck = mempty
  , investigatorDiscard = mempty
  , investigatorHand = mempty
  , investigatorConnectedLocations = mempty
  , investigatorTraits = setFromList traits
  , investigatorTreacheries = mempty
  , investigatorDefeated = False
  , investigatorResigned = False
  , investigatorSlots = HashMap.fromList
    [ (AccessorySlot, [Slot (InvestigatorSource iid) Nothing])
    , (BodySlot, [Slot (InvestigatorSource iid) Nothing])
    , (AllySlot, [Slot (InvestigatorSource iid) Nothing])
    , ( HandSlot
      , [ Slot (InvestigatorSource iid) Nothing
        , Slot (InvestigatorSource iid) Nothing
        ]
      )
    , ( ArcaneSlot
      , [ Slot (InvestigatorSource iid) Nothing
        , Slot (InvestigatorSource iid) Nothing
        ]
      )
    ]
  , investigatorXP = 0
  , investigatorPhysicalTrauma = 0
  , investigatorMentalTrauma = 0
  , investigatorTomeActions = Nothing
  }

matchTarget :: Attrs -> ActionTarget -> Action -> Bool
matchTarget attrs (FirstOneOf as) action =
  action `elem` as && all (`notElem` investigatorActionsTaken attrs) as
matchTarget _ (IsAction a) action = action == a
matchTarget _ (EnemyAction a _) action = action == a

getActionCost
  :: (MonadReader env m, HasModifiersFor env env) => Attrs -> Action -> m Int
getActionCost attrs a = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  pure $ foldr applyModifier 1 modifiers'
 where
  applyModifier (ActionCostOf match m) n =
    if matchTarget attrs match a then n + m else n
  applyModifier _ n = n

getActionCostModifier
  :: (MonadReader env m, HasModifiersFor env env)
  => Attrs
  -> Maybe Action
  -> m Int
getActionCostModifier _ Nothing = pure 0
getActionCostModifier attrs (Just a) = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  pure $ foldr applyModifier 0 modifiers'
 where
  applyModifier (ActionCostOf match m) n =
    if matchTarget attrs match a then n + m else n
  applyModifier _ n = n

getSpendableClueCount
  :: (MonadReader env m, HasModifiersFor env env) => Attrs -> m Int
getSpendableClueCount a = do
  canSpendClues <- getCanSpendClues a
  pure $ if canSpendClues then investigatorClues a else 0

cluesToDiscover
  :: (MonadReader env m, HasModifiersFor env env, HasSource ForSkillTest env)
  => Attrs
  -> Int
  -> m Int
cluesToDiscover attrs startValue = do
  source <-
    asks $ fromJustNote "damage outside skill test" . getSource ForSkillTest
  modifiers' <-
    getModifiersFor source (InvestigatorTarget $ investigatorId attrs) =<< ask
  pure $ foldr applyModifier startValue modifiers'
 where
  applyModifier (DiscoveredClues m) n = n + m
  applyModifier _ n = n

getCanAfford
  :: (MonadReader env m, HasModifiersFor env env) => Attrs -> Action -> m Bool
getCanAfford a@Attrs {..} actionType = do
  actionCost <- getActionCost a actionType
  pure $ actionCost <= investigatorRemainingActions

getFastIsPlayable
  :: (MonadReader env m, HasModifiersFor env env)
  => Attrs
  -> [Window]
  -> Card
  -> m Bool
getFastIsPlayable _ _ (EncounterCard _) = pure False -- TODO: there might be some playable ones?
getFastIsPlayable attrs windows c@(PlayerCard MkPlayerCard {..}) = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  isPlayable <- getIsPlayable attrs windows c
  pure $ (pcFast || canBecomeFast modifiers') && isPlayable
 where
  canBecomeFast modifiers' = foldr applyModifier False modifiers'
  applyModifier (CanBecomeFast (mcardType, traits)) _
    | maybe True (== pcCardType) mcardType
      && not (null (setFromList traits `intersect` pcTraits))
    = True
  applyModifier _ val = val

getModifiedCardCost
  :: (MonadReader env m, HasModifiersFor env env) => Attrs -> Card -> m Int
getModifiedCardCost attrs (PlayerCard MkPlayerCard {..}) = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  pure $ foldr applyModifier startingCost modifiers'
 where
  startingCost = case pcCost of
    StaticCost n -> n
    DynamicCost -> 0
  applyModifier (ReduceCostOf traits m) n
    | not (null (setFromList traits `intersection` pcTraits)) = max 0 (n - m)
  applyModifier (ReduceCostOfCardType cardType m) n | cardType == pcCardType =
    max 0 (n - m)
  applyModifier _ n = n
getModifiedCardCost attrs (EncounterCard MkEncounterCard {..}) = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  pure $ foldr
    applyModifier
    (error "we need so specify ecCost for this to work")
    modifiers'
 where
  applyModifier (ReduceCostOf traits m) n
    | not (null (setFromList traits `intersection` ecTraits)) = max 0 (n - m)
  applyModifier _ n = n

getIsPlayable
  :: (MonadReader env m, HasModifiersFor env env)
  => Attrs
  -> [Window]
  -> Card
  -> m Bool
getIsPlayable _ _ (EncounterCard _) = pure False -- TODO: there might be some playable ones?
getIsPlayable attrs@Attrs {..} windows c@(PlayerCard MkPlayerCard {..}) = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  modifiedCardCost <- getModifiedCardCost attrs c
  pure
    $ (pcCardType /= SkillType)
    && (modifiedCardCost <= investigatorResources)
    && none prevents modifiers'
    && (not pcFast || (pcFast && cardInWindows windows c attrs))
    && (pcAction /= Just Action.Evade || not (null investigatorEngagedEnemies))
 where
  none f = not . any f
  prevents (CannotPlay types) = pcCardType `elem` types
  prevents _ = False

drawOpeningHand :: Attrs -> Int -> ([PlayerCard], [Card], [PlayerCard])
drawOpeningHand a n = go n (a ^. discard, a ^. hand, coerce (a ^. deck))
 where
  go 0 (d, h, cs) = (d, h, cs)
  go _ (_, _, []) =
    error "this should never happen, it means the deck was empty during drawing"
  go m (d, h, c : cs) = if pcWeakness c
    then go m (c : d, h, cs)
    else go (m - 1) (d, PlayerCard c : h, cs)

cardInWindows :: [Window] -> Card -> Attrs -> Bool
cardInWindows windows c _ = case c of
  PlayerCard pc -> not . null $ pcWindows pc `intersect` setFromList windows
  _ -> False

getPlayableCards
  :: (MonadReader env m, HasModifiersFor env env)
  => Attrs
  -> [Window]
  -> m [Card]
getPlayableCards a@Attrs {..} windows = do
  playableDiscards <- getPlayableDiscards a windows
  playableHandCards <- filterM (getFastIsPlayable a windows) investigatorHand
  pure $ playableHandCards <> playableDiscards

getPlayableDiscards
  :: (MonadReader env m, HasModifiersFor env env)
  => Attrs
  -> [Window]
  -> m [Card]
getPlayableDiscards attrs@Attrs {..} windows = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  filterM (getFastIsPlayable attrs windows) (possibleCards modifiers')
 where
  possibleCards modifiers' = map (PlayerCard . snd) $ filter
    (canPlayFromDiscard modifiers')
    (zip @_ @Int [0 ..] investigatorDiscard)
  canPlayFromDiscard modifiers' (n, card) =
    any (allowsPlayFromDiscard n card) modifiers'
  allowsPlayFromDiscard 0 MkPlayerCard {..} (CanPlayTopOfDiscard (mcardType, traits))
    = maybe True (== pcCardType) mcardType
      && (null traits || (setFromList traits `HashSet.isSubsetOf` pcTraits))
  allowsPlayFromDiscard _ _ _ = False


getPossibleSkillTypeChoices
  :: (MonadReader env m, HasModifiersFor env env)
  => SkillType
  -> Attrs
  -> m [SkillType]
getPossibleSkillTypeChoices skillType attrs = do
  modifiers' <- getModifiersFor (toSource attrs) (toTarget attrs) =<< ask
  pure $ foldr applyModifier [skillType] modifiers'
 where
  applyModifier (UseSkillInPlaceOf toReplace toUse) skills
    | toReplace == skillType = toUse : skills
  applyModifier _ skills = skills

instance HasId InvestigatorId () Attrs where
  getId _ Attrs {..} = investigatorId

instance HasModifiersFor env Attrs where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Attrs where
  getActions iid window attrs | iid == investigatorId attrs = concat <$> for
    (attrs ^.. hand . traverse . _PlayerCard)
    (getActions iid window . toPlayerCardWithBehavior)
  getActions _ _ _ = pure []

instance HasTokenValue env Attrs where
  getTokenValue _ _ _ = error "should not be asking this here"

instance InvestigatorRunner env => RunMessage env Attrs where
  runMessage msg i = do
    traverseOf_
      (hand . traverse . _PlayerCard)
      (runMessage msg . toPlayerCardWithBehavior)
      i
    runInvestigatorMessage msg i

_PlayerCard :: Traversal' Card PlayerCard
_PlayerCard f (PlayerCard pc) = PlayerCard <$> f pc
_PlayerCard _ (EncounterCard ec) = pure (EncounterCard ec)

hasModifier
  :: (MonadReader env m, HasModifiersFor env env) => Attrs -> Modifier -> m Bool
hasModifier Attrs { investigatorId } m =
  elem m
    <$> (getModifiersFor
            (InvestigatorSource investigatorId)
            (InvestigatorTarget investigatorId)
        =<< ask
        )

runInvestigatorMessage
  :: (InvestigatorRunner env, MonadReader env m, MonadIO m, MonadFail m)
  => Message
  -> Attrs
  -> m Attrs
runInvestigatorMessage msg a@Attrs {..} = case msg of
  ResetGame -> pure $ (baseAttrs
                        investigatorId
                        investigatorName
                        investigatorClass
                        (getAttrStats a)
                        (setToList investigatorTraits)
                      )
    { investigatorXP = investigatorXP
    , investigatorPhysicalTrauma = investigatorPhysicalTrauma
    , investigatorMentalTrauma = investigatorMentalTrauma
    , investigatorSanityDamage = investigatorMentalTrauma
    , investigatorHealthDamage = investigatorPhysicalTrauma
    }
  SetupInvestigators -> do
    let (discard', hand', deck') = drawOpeningHand a 5
    pure
      $ a
      & (resources .~ 5)
      & (discard .~ discard')
      & (hand .~ hand')
      & (deck .~ Deck deck')
  InvestigatorMulligan iid | iid == investigatorId -> if null investigatorHand
    then a <$ unshiftMessage (FinishedWithMulligan investigatorId)
    else a <$ unshiftMessage
      (Ask iid
      $ ChooseOne
      $ Run
          [Continue "Done With Mulligan", FinishedWithMulligan investigatorId]
      : [ Run [DiscardCard iid (getCardId card), InvestigatorMulligan iid]
        | card <- investigatorHand
        ]
      )
  AllRandomDiscard | not (a ^. defeated || a ^. resigned) ->
    a <$ unshiftMessage (RandomDiscard investigatorId)
  RandomDiscard iid | iid == investigatorId -> do
    n <- liftIO $ randomRIO (0, length investigatorHand - 1)
    case investigatorHand !!? n of
      Nothing -> pure a
      Just c -> a <$ unshiftMessage (DiscardCard investigatorId (getCardId c))
  FinishedWithMulligan iid | iid == investigatorId -> do
    let
      (discard', hand', deck') =
        drawOpeningHand a (5 - length investigatorHand)
    unshiftMessage (ShuffleDiscardBackIn iid)
    pure
      $ a
      & (resources .~ 5)
      & (discard .~ discard')
      & (hand .~ hand')
      & (deck .~ Deck deck')
  ShuffleDiscardBackIn iid | iid == investigatorId ->
    if not (null investigatorDiscard)
      then do
        deck' <- liftIO
          $ shuffleM (investigatorDiscard <> coerce investigatorDeck)
        pure $ a & discard .~ [] & deck .~ Deck deck'
      else pure a
  Resign iid | iid == investigatorId -> do
    unshiftMessage (InvestigatorResigned iid)
    pure $ a & resigned .~ True
  InvestigatorDefeated iid | iid == investigatorId ->
    a <$ unshiftMessage (InvestigatorWhenEliminated iid)
  InvestigatorResigned iid | iid == investigatorId ->
    a <$ unshiftMessage (InvestigatorWhenEliminated iid)
  -- InvestigatorWhenEliminated is handled by the scenario
  InvestigatorEliminated iid | iid == investigatorId -> do
    unshiftMessage
      (PlaceClues (LocationTarget investigatorLocation) investigatorClues)
    pure $ a & clues .~ 0 & resources .~ 0
  EnemyMove eid _ lid | lid == investigatorLocation -> do
    keywords <- asks $ getSet eid
    unengaged <- asks $ null . getSet @InvestigatorId eid
    when
        (Keyword.Aloof
        `notElem` keywords
        && (unengaged || Keyword.Massive `elem` keywords)
        )
      $ unshiftMessage (EnemyEngageInvestigator eid investigatorId)
    pure a
  EnemyMove eid _ lid | lid /= investigatorLocation ->
    pure $ a & engagedEnemies %~ deleteSet eid
  EnemyEngageInvestigator eid iid | iid == investigatorId ->
    pure $ a & engagedEnemies %~ insertSet eid
  EnemyDefeated eid _ _ _ _ _ -> do
    pure $ a & engagedEnemies %~ deleteSet eid
  RemoveEnemy eid -> pure $ a & engagedEnemies %~ deleteSet eid
  TakeControlOfAsset iid aid | iid == investigatorId ->
    pure $ a & assets %~ insertSet aid
  ChooseAndDiscardAsset iid | iid == investigatorId -> do
    discardableAssetIds <-
      asks $ map unDiscardableAssetId . setToList . getSet iid
    a <$ unshiftMessage
      (Ask iid $ ChooseOne $ map (Discard . AssetTarget) discardableAssetIds)
  AttachAsset aid _ | aid `member` investigatorAssets ->
    pure $ a & assets %~ deleteSet aid
  AttachTreachery tid (InvestigatorTarget iid) | iid == investigatorId ->
    pure $ a & treacheries %~ insertSet tid
  AllCheckHandSize | not (a ^. defeated || a ^. resigned) -> do
    handSize <- getHandSize a
    when (length investigatorHand > handSize)
      $ unshiftMessage (CheckHandSize investigatorId)
    pure a
  CheckHandSize iid | iid == investigatorId -> do
    handSize <- getHandSize a
    when (length investigatorHand > handSize) $ unshiftMessage
      (Ask iid $ ChooseOne
        [ Run [DiscardCard iid (getCardId card), CheckHandSize iid]
        | card <- investigatorHand
        ]
      )
    pure a
  AddToDiscard iid pc | iid == investigatorId -> pure $ a & discard %~ (pc :)
  ChooseAndDiscardCard iid | iid == investigatorId -> do
    a <$ unshiftMessage
      (Ask iid
      $ ChooseOne
      $ [ DiscardCard iid (getCardId card) | card <- discardableCards a ]
      )
  DiscardCard iid cardId | iid == investigatorId -> do
    let
      card = fromJustNote "must be in hand"
        $ find ((== cardId) . getCardId) investigatorHand
    case card of
      PlayerCard pc ->
        pure $ a & hand %~ filter ((/= cardId) . getCardId) & discard %~ (pc :)
      EncounterCard _ -> pure $ a & hand %~ filter ((/= cardId) . getCardId) -- TODO: This should discard to the encounter discard
  RemoveCardFromHand iid cardCode | iid == investigatorId ->
    pure $ a & hand %~ filter ((/= cardCode) . getCardCode)
  ShuffleIntoDeck iid (TreacheryTarget tid) | iid == investigatorId -> do
    pure $ a & treacheries %~ deleteSet tid
  Discard (TreacheryTarget tid) -> do
    pure $ a & treacheries %~ deleteSet tid
  Discard (EnemyTarget eid) -> do
    pure $ a & engagedEnemies %~ deleteSet eid
  Discarded (AssetTarget aid) cardCode | aid `elem` investigatorAssets -> do
    pure
      $ a
      & (assets %~ deleteSet aid)
      & (discard %~ (lookupPlayerCard cardCode (CardId $ unAssetId aid) :))
      & (slots %~ removeFromSlots aid)
  ChooseFightEnemy iid source skillType isAction | iid == investigatorId -> do
    enemyIds <- asks (getSet investigatorLocation)
    aloofEnemyIds <-
      asks $ HashSet.map unAloofEnemyId . getSet investigatorLocation
    let
      fightableEnemyIds =
        investigatorEngagedEnemies `union` (enemyIds `difference` aloofEnemyIds)
    a <$ unshiftMessage
      (Ask iid $ ChooseOne
        [ FightEnemy iid eid source skillType isAction
        | eid <- setToList fightableEnemyIds
        ]
      )
  EngageEnemy iid eid True | iid == investigatorId -> a <$ unshiftMessages
    [TakeAction iid 1 (Just Action.Engage), EngageEnemy iid eid False]
  EngageEnemy iid eid False | iid == investigatorId ->
    pure $ a & engagedEnemies %~ insertSet eid
  EngageEnemy iid eid False | iid /= investigatorId ->
    pure $ a & engagedEnemies %~ deleteSet eid
  FightEnemy iid eid source skillType True | iid == investigatorId ->
    a <$ unshiftMessages
      [ TakeAction iid 1 (Just Action.Fight)
      , FightEnemy iid eid source skillType False
      ]
  FightEnemy iid eid source skillType False | iid == investigatorId -> do
    unshiftMessages
      [ WhenAttackEnemy iid eid
      , AttackEnemy iid eid source skillType
      , AfterAttackEnemy iid eid
      ]
    pure a
  FailedAttackEnemy iid eid | iid == investigatorId -> do
    investigatorIds <- asks $ setToList . getSet eid
    case investigatorIds of
      [x] | x /= iid -> unshiftMessage (InvestigatorDamageInvestigator iid x)
      _ -> pure ()
    pure a
  InvestigatorDamageInvestigator iid xid | iid == investigatorId -> do
    damage <- damageValueFor 1 a
    a <$ unshiftMessage
      (InvestigatorAssignDamage xid (InvestigatorSource iid) damage 0)
  InvestigatorDamageEnemy iid eid | iid == investigatorId -> do
    damage <- damageValueFor 1 a
    a <$ unshiftMessage (EnemyDamage eid iid (InvestigatorSource iid) damage)
  EnemyEvaded iid eid | iid == investigatorId -> do
    unshiftMessage (CheckWindow iid [AfterEnemyEvaded You eid])
    pure $ a & engagedEnemies %~ deleteSet eid
  AddToVictory (EnemyTarget eid) -> pure $ a & engagedEnemies %~ deleteSet eid
  ChooseEvadeEnemy iid source skillType isAction | iid == investigatorId ->
    a <$ unshiftMessage
      (chooseOne
        iid
        [ EvadeEnemy iid eid source skillType isAction
        | eid <- setToList investigatorEngagedEnemies
        ]
      )
  EvadeEnemy iid eid source skillType True | iid == investigatorId ->
    a <$ unshiftMessages
      [ TakeAction iid 1 (Just Action.Evade)
      , EvadeEnemy iid eid source skillType False
      ]
  EvadeEnemy iid eid source skillType False | iid == investigatorId ->
    a <$ unshiftMessages
      [ WhenEvadeEnemy iid eid
      , TryEvadeEnemy iid eid source skillType
      , AfterEvadeEnemy iid eid
      ]
  MoveAction iid lid True | iid == investigatorId -> a <$ unshiftMessages
    [ TakeAction iid 1 (Just Action.Move)
    , CheckAttackOfOpportunity iid False
    , MoveAction iid lid False
    ]
  MoveAction iid lid False | iid == investigatorId -> a <$ unshiftMessages
    [Will (MoveTo iid lid), MoveFrom iid investigatorLocation, MoveTo iid lid]
  Will (FailedSkillTest iid _ _ (InvestigatorTarget iid') _)
    | iid == iid' && iid == investigatorId
    -> a <$ unshiftMessage
      (CheckWindow investigatorId [WhenWouldFailSkillTest You])
  InvestigatorDirectDamage iid source damage horror
    | iid == investigatorId && not
      (investigatorDefeated || investigatorResigned)
    -> a <$ unshiftMessages
      ([InvestigatorDamage iid source damage horror, CheckDefeated]
      <> [After (InvestigatorTakeDamage iid source damage horror)]
      <> [ CheckWindow iid [AfterAssignedHorror You] | horror > 0 ]
      )
  InvestigatorAssignDamage iid source damage horror
    | iid == investigatorId && not
      (investigatorDefeated || investigatorResigned)
    -> a <$ unshiftMessages
      ([ InvestigatorDoAssignDamage iid source damage horror [] []
       , CheckDefeated
       ]
      <> [After (InvestigatorTakeDamage iid source damage horror)]
      )
  InvestigatorDoAssignDamage iid source 0 0 damageTargets horrorTargets
    | iid == investigatorId -> a <$ unshiftMessages
      ([ DidReceiveDamage target source
       | target <- setToList (HashSet.fromList damageTargets)
       ]
      <> [ DidReceiveHorror target source
         | target <- setToList (HashSet.fromList horrorTargets)
         ]
      )
  DidReceiveHorror (InvestigatorTarget iid) _ | iid == investigatorId ->
    a <$ unshiftMessage (CheckWindow iid [AfterAssignedHorror You])
  InvestigatorDoAssignDamage iid source health sanity damageTargets horrorTargets
    | iid == investigatorId
    -> do
      healthDamageMessages <- if health > 0
        then do
          let
            assignRestOfHealthDamage = InvestigatorDoAssignDamage
              investigatorId
              source
              (health - 1)
              sanity
          healthDamageableAssets <-
            asks $ map unHealthDamageableAssetId . setToList . getSet iid
          pure
            $ Run
                [ InvestigatorDamage investigatorId source 1 0
                , assignRestOfHealthDamage
                  (InvestigatorTarget investigatorId : damageTargets)
                  horrorTargets
                ]
            : [ Run
                  [ AssetDamage aid source 1 0
                  , assignRestOfHealthDamage
                    (AssetTarget aid : damageTargets)
                    horrorTargets
                  ]
              | aid <- healthDamageableAssets
              ]
        else pure []
      sanityDamageMessages <- if sanity > 0
        then do
          let
            assignRestOfSanityDamage = InvestigatorDoAssignDamage
              investigatorId
              source
              health
              (sanity - 1)
          sanityDamageableAssets <-
            asks $ map unSanityDamageableAssetId . setToList . getSet iid
          pure
            $ Run
                [ InvestigatorDamage investigatorId source 0 1
                , assignRestOfSanityDamage
                  damageTargets
                  (InvestigatorTarget investigatorId : horrorTargets)
                ]
            : [ Run
                  [ AssetDamage aid source 0 1
                  , assignRestOfSanityDamage
                    damageTargets
                    (AssetTarget aid : horrorTargets)
                  ]
              | aid <- sanityDamageableAssets
              ]
        else pure []
      a <$ unshiftMessage
        (Ask iid $ ChooseOne $ healthDamageMessages <> sanityDamageMessages)
  Investigate iid lid source skillType True | iid == investigatorId ->
    a <$ unshiftMessages
      [ TakeAction iid 1 (Just Action.Investigate)
      , CheckAttackOfOpportunity iid False
      , Investigate iid lid source skillType False
      ]
  InvestigatorDiscoverCluesAtTheirLocation iid n | iid == investigatorId ->
    runMessage (InvestigatorDiscoverClues iid investigatorLocation n) a
  InvestigatorDiscoverClues iid lid n | iid == investigatorId -> do
    canDiscoverClues <- getCanDiscoverClues a
    if canDiscoverClues
      then do
        modifiedCluesToDiscover <- cluesToDiscover a n
        a <$ unshiftMessage
          (DiscoverCluesAtLocation iid lid modifiedCluesToDiscover)
      else pure a
  GainClues iid n | iid == investigatorId -> do
    pure $ a & clues +~ n
  DiscoverClues iid lid n | iid == investigatorId -> do
    a <$ unshiftMessage (AfterDiscoverClues iid lid n)
  AfterDiscoverClues iid _ n | iid == investigatorId -> pure $ a & clues +~ n
  PayCardCost iid cardId | iid == investigatorId -> do
    let
      card =
        fromJustNote "not in hand" $ find ((== cardId) . getCardId) (a ^. hand)
      cost = getCost card
    pure $ a & resources -~ cost
  PayDynamicCardCost iid cardId n beforePlayMessages | iid == investigatorId ->
    do
      let
        resolveMessages =
          beforePlayMessages <> [PayedForDynamicCard iid cardId n False]
      if investigatorResources > n
        then a <$ unshiftMessage
          (Ask
            iid
            (ChooseOne
              [ Label
                "Increase spent resources"
                [PayDynamicCardCost iid cardId (n + 1) beforePlayMessages]
              , Label ("Resolve with cost of " <> tshow n) resolveMessages
              ]
            )
          )
        else a <$ unshiftMessages resolveMessages
  PayedForDynamicCard iid cardId n False | iid == investigatorId -> do
    unshiftMessage (PlayDynamicCard iid cardId n Nothing False)
    pure $ a & resources -~ n
  InitiatePlayDynamicCard iid cardId n mtarget asAction
    | iid == investigatorId -> a <$ unshiftMessages
      [ CheckWindow iid [WhenPlayCard You cardId]
      , PlayDynamicCard iid cardId n mtarget asAction
      ]
  PlayDynamicCard iid cardId _n _mtarget True | iid == investigatorId -> do
    let
      card = fromJustNote "not in hand"
        $ find ((== cardId) . getCardId) investigatorHand
      isFast = case card of
        PlayerCard pc -> pcFast pc
        _ -> False
      maction = case card of
        PlayerCard pc -> pcAction pc
        _ -> Nothing
      actionProvokesAttackOfOpportunities =
        maction
          `notElem` [ Just Action.Evade
                    , Just Action.Parley
                    , Just Action.Resign
                    , Just Action.Fight
                    ]
      provokesAttackOfOpportunities = case card of
        PlayerCard pc ->
          actionProvokesAttackOfOpportunities
            && DoesNotProvokeAttacksOfOpportunity
            `notElem` pcAttackOfOpportunityModifiers pc
        _ -> actionProvokesAttackOfOpportunities
      aooMessage = if provokesAttackOfOpportunities
        then [CheckAttackOfOpportunity iid isFast]
        else []
    actionCost' <- if isFast
      then pure 0
      else maybe (pure 1) (getActionCost a) maction
    a <$ unshiftMessages
      [ TakeAction iid actionCost' (Just Action.Play)
      , PayDynamicCardCost iid cardId 0 aooMessage
      ]
  InitiatePlayCard iid cardId mtarget asAction | iid == investigatorId ->
    a <$ unshiftMessages
      [ CheckWindow iid [WhenPlayCard You cardId]
      , PlayCard iid cardId mtarget asAction
      ]
  PlayCard iid cardId mtarget True | iid == investigatorId -> do
    let
      card = fromJustNote "not in hand"
        $ find ((== cardId) . getCardId) investigatorHand
      isFast = case card of
        PlayerCard pc -> pcFast pc
        _ -> False
      maction = case card of
        PlayerCard pc -> pcAction pc
        _ -> Nothing
      actionProvokesAttackOfOpportunities =
        maction
          `notElem` [ Just Action.Evade
                    , Just Action.Parley
                    , Just Action.Resign
                    , Just Action.Fight
                    ]
      provokesAttackOfOpportunities = case card of
        PlayerCard pc ->
          actionProvokesAttackOfOpportunities
            && DoesNotProvokeAttacksOfOpportunity
            `notElem` pcAttackOfOpportunityModifiers pc
        _ -> actionProvokesAttackOfOpportunities
      aooMessage = if provokesAttackOfOpportunities
        then [CheckAttackOfOpportunity iid isFast]
        else []
    actionCost' <- if isFast
      then pure 0
      else maybe (pure 1) (getActionCost a) maction
    if investigatorRemainingActions
        >= actionCost'
        && investigatorResources
        >= getCost card
      then a <$ unshiftMessages
        ([TakeAction iid actionCost' (Just Action.Play), PayCardCost iid cardId]
        <> aooMessage
        <> [PlayCard iid cardId mtarget False]
        )
      else pure a
  PlayedCard iid cardId | iid == investigatorId -> do
    pure $ a & hand %~ filter ((/= cardId) . getCardId)
  InvestigatorPlayAsset iid aid slotTypes traits | iid == investigatorId -> do
    let assetsUpdate = assets %~ insertSet aid
    if fitsAvailableSlots slotTypes traits a
      then pure $ foldl'
        (\a' slotType ->
          a' & slots . ix slotType %~ placeInAvailableSlot aid traits
        )
        (a & assetsUpdate)
        slotTypes
      else do
        let
          missingSlotTypes = slotTypes \\ concatMap
            (\slotType -> availableSlotTypesFor slotType traits a)
            (setToList (HashSet.fromList slotTypes))
          assetsThatCanProvideSlots = setToList . HashSet.fromList $ concatMap
            (`discardableAssets` a)
            missingSlotTypes
        a <$ unshiftMessage
          (Ask iid $ ChooseOne
            [ Run
                [ Discard (AssetTarget aid')
                , InvestigatorPlayAsset iid aid slotTypes traits
                ]
            | aid' <- assetsThatCanProvideSlots
            ]
          )
  ChangeCardToFast iid cardId | iid == investigatorId -> do
    let
      updateCard card = if getCardId card == cardId
        then case card of
          PlayerCard pc -> PlayerCard $ pc { pcFast = True }
          EncounterCard ec -> EncounterCard ec
        else card
    pure $ a & hand %~ map updateCard
  RemoveAllCopiesOfCardFromGame iid cardCode | iid == investigatorId -> do
    for_ investigatorAssets $ \assetId -> do
      cardCode' <- asks $ getId @CardCode assetId
      when
        (cardCode == cardCode')
        (unshiftMessage $ RemoveFromGame (AssetTarget assetId))
    pure
      $ a
      & (deck %~ Deck . filter ((/= cardCode) . getCardCode) . unDeck)
      & (discard %~ filter ((/= cardCode) . getCardCode))
      & (hand %~ filter ((/= cardCode) . getCardCode))
  InvestigatorDamage iid _ health sanity | iid == investigatorId ->
    pure $ a & healthDamage +~ health & sanityDamage +~ sanity
  CheckDefeated -> do
    facingDefeat <- getFacingDefeat a
    if facingDefeat
      then do
        modifiedHealth <- getModifiedHealth a
        modifiedSanity <- getModifiedSanity a
        unshiftMessage (InvestigatorWhenDefeated investigatorId)
        let
          physicalTrauma =
            if investigatorHealthDamage >= modifiedHealth then 1 else 0
          mentalTrauma =
            if investigatorSanityDamage >= modifiedSanity then 1 else 0
        pure
          $ a
          & physicalTraumaL
          +~ physicalTrauma
          & mentalTraumaL
          +~ mentalTrauma
      else pure a
  HealDamage (InvestigatorTarget iid) amount | iid == investigatorId ->
    pure $ a & healthDamage %~ max 0 . subtract amount
  HealHorror (InvestigatorTarget iid) amount | iid == investigatorId -> do
    cannotHealHorror <- hasModifier a CannotHealHorror
    pure $ if cannotHealHorror
      then a
      else a & sanityDamage %~ max 0 . subtract amount
  InvestigatorWhenDefeated iid | iid == investigatorId -> do
    unshiftMessage (InvestigatorDefeated iid)
    pure $ a & defeated .~ True & endedTurn .~ True
  InvestigatorKilled iid | iid == investigatorId -> do
    unshiftMessage (InvestigatorDefeated iid)
    pure $ a & defeated .~ True & endedTurn .~ True
  MoveAllTo lid | not (a ^. defeated || a ^. resigned) ->
    a <$ unshiftMessage (MoveTo investigatorId lid)
  MoveTo iid lid | iid == investigatorId -> do
    connectedLocations' <- asks $ HashSet.map unConnectedLocationId . getSet lid
    unshiftMessages [WhenEnterLocation iid lid, AfterEnterLocation iid lid]
    pure $ a & locationIdL .~ lid & connectedLocations .~ connectedLocations'
  AddedConnection lid1 lid2 | lid1 == investigatorLocation ->
    pure $ a & (connectedLocations %~ insertSet lid2)
  AddedConnection lid1 lid2 | lid2 == investigatorLocation ->
    pure $ a & (connectedLocations %~ insertSet lid1)
  AddSlot iid slotType slot | iid == investigatorId -> do
    let
      slots' = HashMap.findWithDefault [] slotType investigatorSlots
      assetIds = mapMaybe slotItem slots'
      emptiedSlots = sort $ slot : map emptySlot slots'
    unshiftMessage (RefillSlots iid slotType assetIds)
    pure $ a & slots %~ HashMap.insert slotType emptiedSlots
  RefillSlots iid slotType assetIds | iid == investigatorId -> do
    let
      slots' = HashMap.findWithDefault [] slotType investigatorSlots
      emptiedSlots = sort $ map emptySlot slots'
    assetsWithTraits <- for assetIds $ \assetId -> do
      traits <- asks $ setToList . getSet assetId
      pure (assetId, traits)
    let
      updatedSlots = foldl'
        (\s (aid, ts) -> if any (canPutIntoSlot ts) s
          then placeInAvailableSlot aid ts s
          else s
        )
        emptiedSlots
        assetsWithTraits
    if length (mapMaybe slotItem updatedSlots) == length assetIds
      then pure $ a & slots %~ HashMap.insert slotType updatedSlots
      else do
        unshiftMessage
          (Ask iid $ ChooseOne
            [ Run
                [ Discard (AssetTarget aid')
                , RefillSlots iid slotType (filter (/= aid') assetIds)
                ]
            | aid' <- assetIds
            ]
          )
        pure a
  ChooseEndTurn iid | iid == investigatorId -> do
    unshiftMessage (CheckWindow iid [AfterEndTurn You])
    pure $ a & endedTurn .~ True
  BeginRound -> do
    actionsForTurn <- getActionsForTurn a
    pure
      $ a
      & (endedTurn .~ False)
      & (remainingActions .~ actionsForTurn)
      & (actionsTaken .~ mempty)
  DrawCards iid n True | iid == investigatorId -> a <$ unshiftMessages
    [ TakeAction iid 1 (Just Action.Draw)
    , CheckAttackOfOpportunity iid False
    , DrawCards iid n False
    ]
  DrawCards iid 0 False | iid == investigatorId -> pure a
  DrawCards iid n False | iid == investigatorId ->
    if null (unDeck investigatorDeck)
      then if null investigatorDiscard
        then pure a
        else a
          <$ unshiftMessages [ShuffleDiscardBackIn iid, DrawCards iid n False]
      else do
        let
          (mcard, deck') = drawCard (coerce investigatorDeck)
          handUpdate = maybe id ((:) . PlayerCard) mcard
        case mcard of
          Just card@MkPlayerCard {..} -> do
            when (pcCardType == PlayerTreacheryType)
              $ unshiftMessage (DrewPlayerTreachery iid pcCardCode pcId)
            when (pcCardType == PlayerEnemyType)
              $ unshiftMessage (DrewPlayerEnemy iid pcCardCode pcId)
            when (pcCardType /= PlayerTreacheryType && pcWeakness) $ void
              (runMessage
                (Revelation iid (PlayerCardSource $ getCardId card))
                (toPlayerCardWithBehavior card)
              )
          Nothing -> pure ()
        unshiftMessage (DrawCards iid (n - 1) False)
        pure $ a & hand %~ handUpdate & deck .~ Deck deck'
  InvestigatorSpendClues iid n | iid == investigatorId -> pure $ a & clues -~ n
  SpendResources iid n | iid == investigatorId ->
    pure $ a & resources %~ max 0 . subtract n
  TakeResources iid n True | iid == investigatorId -> do
    unlessM (hasModifier a CannotGainResources) $ unshiftMessages
      [ TakeAction iid 1 (Just Action.Resource)
      , CheckAttackOfOpportunity iid False
      , TakeResources iid n False
      ]
    pure a
  TakeResources iid n False | iid == investigatorId -> do
    cannotGainResources <- hasModifier a CannotGainResources
    pure $ if cannotGainResources then a else a & resources +~ n
  EmptyDeck iid | iid == investigatorId -> a <$ unshiftMessages
    [ShuffleDiscardBackIn iid, InvestigatorDamage iid EmptyDeckSource 0 1]
  AllDrawEncounterCard | not (a ^. defeated || a ^. resigned) ->
    a <$ unshiftMessage
      (Ask investigatorId
      $ ChooseOne [InvestigatorDrawEncounterCard investigatorId]
      )
  When (EnemySpawn _ lid eid) | lid == investigatorLocation -> do
    traits <- asks $ setToList . getSet eid
    a <$ unshiftMessage
      (CheckWindow investigatorId [WhenEnemySpawns YourLocation traits])
  ActivateCardAbilityAction iid Ability {..} | iid == investigatorId -> do
    unshiftMessage
      (UseCardAbility iid abilitySource abilityMetadata abilityIndex) -- We should check action type when added for aoo
    case abilityType of
      ForcedAbility -> pure ()
      FastAbility _ -> pure ()
      ReactionAbility _ -> pure ()
      ActionAbility n actionType ->
        if actionType
            `notElem` [ Just Action.Fight
                      , Just Action.Evade
                      , Just Action.Resign
                      , Just Action.Parley
                      ]
          then unshiftMessages
            [TakeAction iid n actionType, CheckAttackOfOpportunity iid False]
          else unshiftMessage (TakeAction iid n actionType)
    pure a
  ActivateCardAbilityActionWithDynamicCost iid Ability {..}
    | iid == investigatorId -> do
      unshiftMessage
        (PayForCardAbility iid abilitySource abilityMetadata abilityIndex) -- We should check action type when added for aoo
      case abilityType of
        ForcedAbility -> pure ()
        FastAbility _ -> pure ()
        ReactionAbility _ -> pure ()
        ActionAbility n actionType ->
          if actionType
              `notElem` [ Just Action.Fight
                        , Just Action.Evade
                        , Just Action.Resign
                        , Just Action.Parley
                        ]
            then unshiftMessages
              [TakeAction iid n actionType, CheckAttackOfOpportunity iid False]
            else unshiftMessage (TakeAction iid n actionType)
      pure a
  AllDrawCardAndResource | not (a ^. defeated || a ^. resigned) -> do
    unshiftMessage (DrawCards investigatorId 1 False)
    pure $ a & resources +~ 1
  LoadDeck iid deck' | iid == investigatorId -> do
    shuffled <- liftIO $ shuffleM $ flip map deck' $ \card -> if pcWeakness card
      then card { pcBearer = Just $ BearerId $ unInvestigatorId iid }
      else card
    pure $ a & deck .~ Deck shuffled
  InvestigatorCommittedCard iid cardId | iid == investigatorId ->
    pure $ a & hand %~ filter ((/= cardId) . getCardId)
  BeforeSkillTest iid skillType | iid == investigatorId -> do
    committedCardIds <- asks $ map unCommittedCardId . setToList . getSet iid
    committedCardCodes <- asks $ HashSet.map unCommittedCardCode . getSet ()
    actions <- getActions iid (WhenSkillTest skillType) ()
    isScenarioAbility <- getIsScenarioAbility
    source <-
      asks $ fromJustNote "damage outside skill test" . getSource ForSkillTest
    cannotCommitCards <-
      elem CannotCommitCards
        <$> (getModifiersFor source (InvestigatorTarget investigatorId) =<< ask)
    let
      triggerMessage = StartSkillTest investigatorId
      beginMessage = BeforeSkillTest iid skillType
      committableCards = if cannotCommitCards
        then []
        else flip filter investigatorHand $ \case
          PlayerCard MkPlayerCard {..} ->
            pcId
              `notElem` committedCardIds
              && (SkillWild `elem` pcSkills || skillType `elem` pcSkills)
              && (MaxOnePerTest
                 `notElem` pcCommitRestrictions
                 || pcCardCode
                 `notElem` committedCardCodes
                 )
              && (ScenarioAbility
                 `notElem` pcCommitRestrictions
                 || isScenarioAbility
                 )
          _ -> False
    if not (null committableCards) || not (null committedCardIds) || not
      (null actions)
    then
      unshiftMessage
        (SkillTestAsk $ Ask iid $ ChooseOne
          (map
              (\card ->
                Run [SkillTestCommitCard iid (getCardId card), beginMessage]
              )
              committableCards
          <> map
               (\cardId ->
                 Run [SkillTestUncommitCard iid cardId, beginMessage]
               )
               committedCardIds
          <> map (\action -> Run [action, beginMessage]) actions
          <> [triggerMessage]
          )
        )
    else
      unshiftMessage (SkillTestAsk $ Ask iid $ ChooseOne [triggerMessage])
    pure a
  BeforeSkillTest iid skillType | iid /= investigatorId -> do
    locationId' <- asks (getId iid)
    isScenarioAbility <- getIsScenarioAbility
    when (locationId' == investigatorLocation) $ do
      committedCardIds <-
        asks $ map unCommittedCardId . setToList . getSet investigatorId
      committedCardCodes <- asks $ HashSet.map unCommittedCardCode . getSet ()
      let
        beginMessage = BeforeSkillTest iid skillType
        committableCards = if not (null committedCardIds)
          then []
          else flip filter investigatorHand $ \case
            PlayerCard MkPlayerCard {..} ->
              pcId
                `notElem` committedCardIds
                && (SkillWild `elem` pcSkills || skillType `elem` pcSkills)
                && (OnlyYourTest `notElem` pcCommitRestrictions)
                && (MaxOnePerTest
                   `notElem` pcCommitRestrictions
                   || pcCardCode
                   `notElem` committedCardCodes
                   )
                && (ScenarioAbility
                   `notElem` pcCommitRestrictions
                   || isScenarioAbility
                   )
            _ -> False
      when (not (null committableCards) || not (null committedCardIds))
        $ unshiftMessage
            (SkillTestAsk $ Ask investigatorId $ ChooseOne
              (map
                  (\card ->
                    Run
                      [ SkillTestCommitCard investigatorId (getCardId card)
                      , beginMessage
                      ]
                  )
                  committableCards
              <> map
                   (\cardId ->
                     Run
                       [ SkillTestUncommitCard investigatorId cardId
                       , beginMessage
                       ]
                   )
                   committedCardIds
              )
            )
    pure a
  CheckWindow iid windows | iid == investigatorId -> do
    actions <- fmap concat <$> for windows $ \window -> do
      getActions iid window ()
    playableCards <- getPlayableCards a windows
    if not (null playableCards) || not (null actions)
      then a <$ unshiftMessage
        (chooseOne iid
        $ [ Run
              [ PayCardCost iid (getCardId c)
              , PlayCard iid (getCardId c) Nothing False
              , CheckWindow iid windows
              ]
          | c <- playableCards
          ]
        <> map (Run . (: [CheckWindow iid windows])) actions
        <> [Continue "Skip playing fast cards or using reactions"]
        )
      else pure a
  LoseActions iid _ n | iid == investigatorId ->
    pure $ a & remainingActions %~ max 0 . subtract n
  SetActions iid _ n | iid == investigatorId -> pure $ a & remainingActions .~ n
  GainActions iid _ n | iid == investigatorId ->
    pure $ a & remainingActions +~ n
  TakeAction iid actionCost' maction | iid == investigatorId -> do
    costModifier <- getActionCostModifier a maction
    let
      modifiedActionCost = max 0 (actionCost' + costModifier)
      actionsTakenUpdate = case maction of
        Nothing -> id
        Just action -> (<> [action])
    pure
      $ a
      & (remainingActions %~ max 0 . subtract modifiedActionCost)
      & (actionsTaken %~ actionsTakenUpdate)
  PutOnTopOfDeck iid card | iid == investigatorId ->
    pure $ a & deck %~ Deck . (card :) . unDeck
  AddToHand iid card | iid == investigatorId -> do
    case card of
      PlayerCard card' -> void $ runMessage
        (Revelation iid (PlayerCardSource $ getCardId card'))
        (toPlayerCardWithBehavior card')
      _ -> pure ()
    pure $ a & hand %~ (card :)
  ShuffleCardsIntoDeck iid cards | iid == investigatorId -> do
    deck' <- liftIO $ shuffleM (cards <> unDeck investigatorDeck)
    pure $ a & deck .~ Deck deck'
  AddToHandFromDeck iid cardId | iid == investigatorId -> do
    let
      card = fromJustNote "card did not exist"
        $ find ((== cardId) . getCardId) (unDeck investigatorDeck)
    deck' <- liftIO $ shuffleM $ filter
      ((/= cardId) . getCardId)
      (unDeck investigatorDeck)
    case card of
      MkPlayerCard {..} -> do
        when (pcCardType == PlayerTreacheryType)
          $ unshiftMessage (DrewPlayerTreachery iid pcCardCode pcId)
        when (pcCardType == PlayerEnemyType)
          $ unshiftMessage (DrewPlayerEnemy iid pcCardCode pcId)
    pure $ a & deck .~ Deck deck' & hand %~ (PlayerCard card :)
  DisengageEnemy iid eid | iid == investigatorId -> do
    pure $ a & engagedEnemies %~ deleteSet eid
  SearchDeckForTraits iid (InvestigatorTarget iid') traits
    | iid' == investigatorId -> runMessage
      (SearchTopOfDeck
        iid
        (InvestigatorTarget iid')
        (length $ unDeck investigatorDeck)
        traits
        ShuffleBackIn
      )
      a
  SearchTopOfDeck iid (InvestigatorTarget iid') n traits strategy
    | iid' == investigatorId -> do
      let
        (cards, deck') = splitAt n $ unDeck investigatorDeck
        traits' = setFromList traits
      case strategy of
        PutBackInAnyOrder -> unshiftMessage
          (Ask iid $ ChooseOneAtATime
            [ AddFocusedToTopOfDeck
                iid
                (InvestigatorTarget iid')
                (getCardId card)
            | card <- cards
            ]
          )
        ShuffleBackIn -> do
          let
            choices =
              [ Run
                  [ AddFocusedToHand
                    iid
                    (InvestigatorTarget iid')
                    (getCardId card)
                  , ShuffleAllFocusedIntoDeck iid (InvestigatorTarget iid')
                  ]
              | card <- cards
              , null traits'
                || not (null $ traits' `intersection` getTraits card)
              ]
          unshiftMessage
            (chooseOne iid $ if null choices
              then
                [ Label
                    "No cards found"
                    [ShuffleAllFocusedIntoDeck iid (InvestigatorTarget iid')]
                ]
              else choices
            )
      actions <- fmap concat <$> for cards $ \card' -> getActions
        iid
        (WhenAmongSearchedCards You)
        (toPlayerCardWithBehavior card')
      -- TODO: This is for astounding revelation and only one research action is possible
      -- so we are able to short circuit here, but we may have additional cards in the
      -- future so we may want to make this more versatile
      unless (null actions) $ unshiftMessage
        (chooseOne iid
        $ actions
        <> [Continue "Skip playing fast cards or using reactions"]
        )
      unshiftMessage (FocusCards $ map PlayerCard cards)
      pure $ a & deck .~ Deck deck'
  SearchDiscard iid (InvestigatorTarget iid') traits | iid' == investigatorId ->
    do
      let traits' = setFromList traits
      unshiftMessage
        (Ask iid $ ChooseOne
          [ Run
              [ AddFocusedToHand iid (InvestigatorTarget iid') (getCardId card)
              , RemoveFromDiscard iid (getCardId card)
              ]
          | card <- investigatorDiscard
          , null traits' || traits' `intersection` getTraits card == traits'
          ]
        )
      a <$ unshiftMessage (FocusCards $ map PlayerCard investigatorDiscard)
  RemoveFromDiscard iid cardId | iid == investigatorId ->
    pure $ a & discard %~ filter ((/= cardId) . getCardId)
  SufferTrauma iid physical mental | iid == investigatorId ->
    pure $ a & physicalTraumaL +~ physical & mentalTraumaL +~ mental
  GainXP iid amount | iid == investigatorId -> pure $ a & xpL +~ amount
  InvestigatorPlaceCluesOnLocation iid n | iid == investigatorId -> do
    let cluesToPlace = min n investigatorClues
    unshiftMessage
      (PlaceClues (LocationTarget investigatorLocation) cluesToPlace)
    pure $ a & clues -~ cluesToPlace
  InvestigatorPlaceAllCluesOnLocation iid | iid == investigatorId -> do
    unshiftMessage
      (PlaceClues (LocationTarget investigatorLocation) investigatorClues)
    pure $ a & clues .~ 0
  RemoveDiscardFromGame iid | iid == investigatorId -> pure $ a & discard .~ []
  After (FailedSkillTest iid _ _ (InvestigatorTarget iid') n)
    | iid == iid' && iid == investigatorId -> do
      a <$ unshiftMessage (CheckWindow iid [AfterFailSkillTest You n])
  After (PassedSkillTest iid _ source (InvestigatorTarget iid') n)
    | iid == iid' && iid == investigatorId -> do
      a <$ unshiftMessage (CheckWindow iid [AfterPassSkillTest source You n])
  PlayerWindow iid additionalActions | iid == investigatorId -> do
    actions <- getActions iid NonFast ()
    fastActions <- getActions iid (DuringTurn You) ()
    playerWindowActions <- getActions iid FastPlayerWindow ()
    modifiers' <-
      getModifiersFor (InvestigatorSource iid) (InvestigatorTarget iid) =<< ask
    canAffordTakeResources <- getCanAfford a Action.Resource
    canAffordDrawCards <- getCanAfford a Action.Draw
    canAffordPlayCard <- getCanAfford a Action.Play
    isPlayableMap :: HashMap Card Bool <- mapFromList <$> for
      investigatorHand
      (\c -> do
        isPlayable <- getIsPlayable a [DuringTurn You] c
        pure (c, isPlayable)
      )
    let isPlayable c = findWithDefault False c isPlayableMap
    fastIsPlayableMap :: HashMap Card Bool <- mapFromList <$> for
      investigatorHand
      (\c -> do
        fastIsPlayable <- getFastIsPlayable a [DuringTurn You] c
        pure (c, fastIsPlayable)
      )
    let fastIsPlayable c = findWithDefault False c fastIsPlayableMap
    a <$ unshiftMessage
      (Ask iid $ ChooseOne
        (additionalActions
        <> [ TakeResources iid 1 True
           | canAffordTakeResources
             && CannotGainResources
             `notElem` modifiers'
           ]
        <> [ DrawCards iid 1 True
           | canAffordDrawCards
             && CannotTakeAction (IsAction Action.Draw)
             `notElem` modifiers'
           ]
        <> [ InitiatePlayCard iid (getCardId c) Nothing True
           | c <- investigatorHand
           , canAffordPlayCard || fastIsPlayable c
           , isPlayable c && not (isDynamic c)
           ]
        <> [ InitiatePlayDynamicCard iid (getCardId c) 0 Nothing True
           | c <- investigatorHand
           , canAffordPlayCard || fastIsPlayable c
           , isPlayable c && isDynamic c
           ]
        <> [ChooseEndTurn iid]
        <> actions
        <> fastActions
        <> playerWindowActions
        )
      )
  _ -> pure a
