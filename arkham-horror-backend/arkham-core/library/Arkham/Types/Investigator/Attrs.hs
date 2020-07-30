{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Investigator.Attrs where

import Arkham.Json
import Arkham.Types.Ability
import Arkham.Types.ActId
import Arkham.Types.Action (Action)
import qualified Arkham.Types.Action as Action
import Arkham.Types.AssetId
import Arkham.Types.Card
import Arkham.Types.Card.Id
import Arkham.Types.Classes
import Arkham.Types.EnemyId
import Arkham.Types.FastWindow
import Arkham.Types.Helpers
import Arkham.Types.Investigator.Runner
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Stats
import Arkham.Types.Target
import Arkham.Types.Trait
import Arkham.Types.TreacheryId
import ClassyPrelude
import Data.Coerce
import qualified Data.HashSet as HashSet
import Lens.Micro
import Safe (fromJustNote)
import System.Random
import System.Random.Shuffle

instance HasCardCode Attrs where
  getCardCode = unInvestigatorId . investigatorId

data Attrs = Attrs
  { investigatorName :: Text
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
  , investigatorModifiers :: [Modifier]
  , investigatorAbilities :: [Ability]
  , investigatorDefeated :: Bool
  , investigatorResigned :: Bool
  }
  deriving stock (Show, Generic)

instance ToJSON Attrs where
  toJSON = genericToJSON $ aesonOptions $ Just "investigator"
  toEncoding = genericToEncoding $ aesonOptions $ Just "investigator"

instance FromJSON Attrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "investigator"

locationId :: Lens' Attrs LocationId
locationId = lens investigatorLocation $ \m x -> m { investigatorLocation = x }

modifiers :: Lens' Attrs [Modifier]
modifiers =
  lens investigatorModifiers $ \m x -> m { investigatorModifiers = x }

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

facingDefeat :: Attrs -> Bool
facingDefeat Attrs {..} =
  investigatorHealthDamage
    >= investigatorHealth
    || investigatorSanityDamage
    >= investigatorSanity

skillValueFor :: SkillType -> [Modifier] -> Attrs -> Int
skillValueFor skill tempModifiers attrs = foldr
  applyModifier
  baseSkillValue
  (investigatorModifiers attrs <> tempModifiers)
 where
  applyModifier (SkillModifier skillType m _) n =
    if skillType == skill then max 0 (n + m) else n
  applyModifier _ n = n
  baseSkillValue = case skill of
    SkillWillpower -> investigatorWillpower attrs
    SkillIntellect -> investigatorIntellect attrs
    SkillCombat -> investigatorCombat attrs
    SkillAgility -> investigatorAgility attrs
    SkillWild -> error "investigators do not have wild skills"

damageValueFor :: Int -> Attrs -> Int
damageValueFor baseValue attrs = foldr
  applyModifier
  baseValue
  (investigatorModifiers attrs)
 where
  applyModifier (DamageDealt m _) n = max 0 (n + m)
  applyModifier _ n = n

baseAttrs :: InvestigatorId -> Text -> Stats -> [Trait] -> Attrs
baseAttrs iid name Stats {..} traits = Attrs
  { investigatorName = name
  , investigatorId = iid
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
  , investigatorTraits = HashSet.fromList traits
  , investigatorTreacheries = mempty
  , investigatorModifiers = mempty
  , investigatorAbilities = mempty
  , investigatorDefeated = False
  , investigatorResigned = False
  }

sourceIsInvestigator :: Source -> Attrs -> Bool
sourceIsInvestigator source Attrs {..} = case source of
  InvestigatorSource sourceId -> sourceId == investigatorId
  AssetSource sourceId -> sourceId `elem` investigatorAssets
  _ -> False

matchTarget :: Attrs -> ActionTarget -> Action -> Bool
matchTarget attrs (FirstOneOf as) action =
  action `elem` as && action `notElem` investigatorActionsTaken attrs
matchTarget _ (IsAction a) action = action == a

actionCost :: Attrs -> Action -> Int
actionCost attrs a = foldr applyModifier 1 (investigatorModifiers attrs)
 where
  applyModifier (ActionCostOf match m _) n =
    if matchTarget attrs match a then n + m else n
  applyModifier _ n = n

cluesToDiscover :: Attrs -> Int -> Int
cluesToDiscover attrs startValue = foldr
  applyModifier
  startValue
  (investigatorModifiers attrs)
 where
  applyModifier (DiscoveredClues m _) n = n + m
  applyModifier _ n = n

canAfford :: Attrs -> Action -> Bool
canAfford a@Attrs {..} actionType =
  actionCost a actionType <= investigatorRemainingActions

canPerform
  :: (MonadReader env m, InvestigatorRunner env) => Attrs -> Action -> m Bool
canPerform a@Attrs {..} Action.Move = do
  blockedLocationIds <- HashSet.map unBlockedLocationId <$> asks (getSet ())
  let
    accessibleLocations =
      investigatorConnectedLocations `difference` blockedLocationIds
  pure $ canAfford a Action.Move && not (null accessibleLocations)
canPerform a Action.Investigate = pure $ canAfford a Action.Investigate
canPerform a@Attrs {..} Action.Fight = do
  enemyIds <- asks (getSet investigatorLocation)
  aloofEnemyIds <- HashSet.map unAloofEnemyId
    <$> asks (getSet investigatorLocation)
  let
    unengagedEnemyIds = enemyIds `difference` investigatorEngagedEnemies
    fightableEnemyIds =
      investigatorEngagedEnemies
        `union` (unengagedEnemyIds `difference` aloofEnemyIds)
  pure $ canAfford a Action.Fight && not (null fightableEnemyIds)
canPerform a@Attrs {..} Action.Evade =
  pure $ canAfford a Action.Evade && not (null investigatorEngagedEnemies)
canPerform a@Attrs {..} Action.Engage = do
  enemyIds <- asks (getSet investigatorLocation)
  let unengagedEnemyIds = enemyIds `difference` investigatorEngagedEnemies
  pure $ canAfford a Action.Engage && not (null unengagedEnemyIds)
canPerform a Action.Draw = pure $ canAfford a Action.Draw
canPerform a Action.Resign = pure $ canAfford a Action.Resign
canPerform a Action.Resource = pure $ canAfford a Action.Resource
canPerform a Action.Parley = pure $ canAfford a Action.Parley
canPerform a@Attrs {..} Action.Play = do
  let playableCards = filter (isPlayable a [DuringTurn You]) investigatorHand
  pure $ canAfford a Action.Play && not (null playableCards)
canPerform a@Attrs {..} Action.Ability = do
  availableAbilities <- getAvailableAbilities a
  filteredAbilities <- flip filterM availableAbilities $ \case
    (_, _, ActionAbility _ action, _) -> canPerform a action -- TODO: we need to calculate the total cost
    (_, _, FreeAbility (SkillTestWindow _), _) -> pure False
    (_, _, ReactionAbility _, _) -> pure False

  pure $ canAfford a Action.Ability && not (null filteredAbilities)

fastIsPlayable :: Attrs -> [FastWindow] -> Card -> Bool
fastIsPlayable _ _ (EncounterCard _) = False -- TODO: there might be some playable ones?
fastIsPlayable a windows c@(PlayerCard MkPlayerCard {..}) =
  pcFast && isPlayable a windows c

isPlayable :: Attrs -> [FastWindow] -> Card -> Bool
isPlayable _ _ (EncounterCard _) = False -- TODO: there might be some playable ones?
isPlayable a@Attrs {..} windows c@(PlayerCard MkPlayerCard {..}) =
  (pcCardType /= SkillType)
    && (pcCost <= investigatorResources)
    && none prevents investigatorModifiers
    && (not pcFast || (pcFast && cardInWindows windows c a))
 where
  none f = not . any f
  prevents (CannotPlay types _) = pcCardType `elem` types
  prevents _ = False

takeAction :: Action -> Attrs -> Attrs
takeAction action a =
  a
    & (remainingActions %~ max 0 . subtract (actionCost a action))
    & (actionsTaken %~ (<> [action]))

getAvailableAbilities
  :: (InvestigatorRunner env, MonadReader env m) => Attrs -> m [Ability]
getAvailableAbilities a@Attrs {..} = do
  assetAbilities <- mconcat
    <$> traverse (asks . getList) (HashSet.toList investigatorAssets)
  treacheryAbilities <- mconcat
    <$> traverse (asks . getList) (HashSet.toList investigatorTreacheries)
  locationAbilities <- asks (getList investigatorLocation)
  locationEnemyIds <- asks (getSet @EnemyId investigatorLocation)
  locationEnemyAbilities <- mconcat
    <$> traverse (asks . getList) (HashSet.toList locationEnemyIds)
  locationAssets <- asks (getSet @AssetId investigatorLocation)
  locationAssetAbilities <- mconcat
    <$> traverse (asks . getList) (HashSet.toList locationAssets)
  locationTreacheries <- asks (getSet @TreacheryId investigatorLocation)
  locationTreacheryAbilities <- mconcat
    <$> traverse (asks . getList) (HashSet.toList locationTreacheries)
  actAndAgendaAbilities <- asks (getList ())
  pure $ filter canPerformAbility $ mconcat
    [ investigatorAbilities
    , assetAbilities
    , treacheryAbilities
    , locationAbilities
    , locationEnemyAbilities
    , locationAssetAbilities
    , locationTreacheryAbilities
    , actAndAgendaAbilities
    ]
 where
  canPerformAbility (_, _, ActionAbility _ actionType, _) =
    canAfford a actionType
  canPerformAbility (_, _, FreeAbility (SkillTestWindow _), _) = False
  canPerformAbility (_, _, ReactionAbility _, _) = False

drawOpeningHand :: Attrs -> Int -> ([PlayerCard], [Card], [PlayerCard])
drawOpeningHand a n = go n (a ^. discard, a ^. hand, coerce (a ^. deck))
 where
  go 0 (d, h, cs) = (d, h, cs)
  go _ (_, _, []) =
    error "this should never happen, it means the deck was empty during drawing"
  go m (d, h, (c : cs)) = if pcWeakness c
    then go m (c : d, h, cs)
    else go (m - 1) (d, PlayerCard c : h, cs)

cardInWindows :: [FastWindow] -> Card -> Attrs -> Bool
cardInWindows windows c _ = case c of
  PlayerCard pc ->
    not . null $ pcFastWindows pc `intersect` HashSet.fromList windows
  _ -> False

abilityInWindows
  :: (MonadReader env m, InvestigatorRunner env)
  => [FastWindow]
  -> Ability
  -> Attrs
  -> m Bool
abilityInWindows windows ability _ = case ability of
  (_, _, ReactionAbility window, OncePerRound) -> if window `elem` windows
    then do
      usedAbilities <- map unUsedAbility <$> asks (getList ())
      pure $ ability `notElem` usedAbilities
    else pure False
  (_, _, ReactionAbility window, _) -> pure $ window `elem` windows
  _ -> pure False

instance (InvestigatorRunner env) => RunMessage env Attrs where
  runMessage msg a@Attrs {..} = case msg of
    Setup -> do
      let (discard', hand', deck') = drawOpeningHand a 5
      unshiftMessage (ShuffleDiscardBackIn investigatorId)
      pure
        $ a
        & (resources .~ 5)
        & (discard .~ discard')
        & (hand .~ hand')
        & (deck .~ Deck deck')
    AllRandomDiscard -> do
      n <- liftIO $ randomRIO (0, length investigatorHand - 1)
      case investigatorHand !!? n of
        Nothing -> pure a
        Just c ->
          a <$ unshiftMessage (DiscardCard investigatorId (getCardId c))
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
    EnemySpawn lid eid | lid == investigatorLocation -> do
      aloofEnemyIds <- HashSet.map unAloofEnemyId
        <$> asks (getSet investigatorLocation)
      when (eid `notElem` aloofEnemyIds)
        $ unshiftMessage (EnemyEngageInvestigator eid investigatorId)
      pure a
    EnemyMove eid _ lid | lid == investigatorLocation -> do
      aloofEnemyIds <- HashSet.map unAloofEnemyId
        <$> asks (getSet investigatorLocation)
      when (eid `notElem` aloofEnemyIds)
        $ unshiftMessage (EnemyEngageInvestigator eid investigatorId)
      pure a
    EnemyEngageInvestigator eid iid | iid == investigatorId ->
      pure $ a & engagedEnemies %~ HashSet.insert eid
    EnemyDefeated eid _ _ _ -> pure $ a & engagedEnemies %~ HashSet.delete eid
    RemoveEnemy eid -> pure $ a & engagedEnemies %~ HashSet.delete eid
    TakeControlOfAsset iid aid | iid == investigatorId ->
      pure $ a & assets %~ HashSet.insert aid
    ChooseAndDiscardAsset iid | iid == investigatorId -> a <$ unshiftMessage
      (Ask $ ChooseOne $ map DiscardAsset (HashSet.toList $ a ^. assets))
    AttachTreacheryToInvestigator tid iid | iid == investigatorId ->
      pure $ a & treacheries %~ HashSet.insert tid
    DiscardCard iid cardId | iid == investigatorId -> do
      let
        card = fromJustNote "must be in hand"
          $ find ((== cardId) . getCardId) investigatorHand
      case card of
        PlayerCard pc ->
          pure
            $ a
            & hand
            %~ filter ((/= cardId) . getCardId)
            & discard
            %~ (pc :)
        EncounterCard _ -> pure $ a & hand %~ filter ((/= cardId) . getCardId) -- TODO: This should discard to the encounter discard
    RemoveCardFromHand iid cardCode | iid == investigatorId ->
      pure $ a & hand %~ filter ((/= cardCode) . getCardCode)
    Discard (TreacheryTarget tid) ->
      pure $ a & treacheries %~ HashSet.delete tid
    Discard (EnemyTarget eid) ->
      pure $ a & engagedEnemies %~ HashSet.delete eid
    AssetDiscarded aid cardCode | aid `elem` investigatorAssets ->
      pure
        $ a
        & (assets %~ HashSet.delete aid)
        & (discard %~ (lookupPlayerCard cardCode (CardId $ unAssetId aid) :))
    ChooseActivateCardAbilityAction iid | iid == investigatorId -> do
      availableAbilities <- getAvailableAbilities a
      a <$ unshiftMessage
        (Ask $ ChooseOne $ map
          (ActivateCardAbilityAction iid)
          availableAbilities
        )
    ChooseFightEnemy iid skillType tempModifiers isAction
      | iid == investigatorId -> do
        unshiftMessage
          (Ask $ ChooseOne $ map
            (\eid -> FightEnemy iid eid skillType tempModifiers isAction)
            (HashSet.toList investigatorEngagedEnemies)
          )
        pure $ takeAction Action.Fight a
    FightEnemy iid eid skillType tempModifiers True | iid == investigatorId ->
      a <$ unshiftMessages
        [ TakeAction iid (actionCost a Action.Fight) Action.Fight
        , FightEnemy iid eid skillType tempModifiers False
        ]
    FightEnemy iid eid skillType tempModifiers False | iid == investigatorId ->
      do
        unshiftMessages
          [ WhenAttackEnemy iid eid
          , AttackEnemy iid eid skillType tempModifiers
          , AfterAttackEnemy iid eid
          ]
        pure a
    InvestigatorDamageEnemy iid eid | iid == investigatorId -> do
      let damage = damageValueFor 1 a
      a <$ unshiftMessage (EnemyDamage eid iid (InvestigatorSource iid) damage)
    EnemyEvaded iid eid | iid == investigatorId ->
      pure $ a & engagedEnemies %~ HashSet.delete eid
    ChooseEvadeEnemy iid skillType isAction | iid == investigatorId -> do
      unshiftMessage
        (Ask $ ChooseOne $ map
          (\eid -> EvadeEnemy iid eid skillType isAction)
          (HashSet.toList investigatorEngagedEnemies)
        )
      pure $ takeAction Action.Fight a
    EvadeEnemy iid eid skillType True | iid == investigatorId ->
      a <$ unshiftMessages
        [ TakeAction iid (actionCost a Action.Evade) Action.Evade
        , EvadeEnemy iid eid skillType False
        ]
    EvadeEnemy iid eid skillType False | iid == investigatorId ->
      a <$ unshiftMessages
        [ WhenEvadeEnemy iid eid
        , TryEvadeEnemy iid eid skillType
        , AfterEvadeEnemy iid eid
        ]
    MoveAction iid lid True -> a <$ unshiftMessages
      [ TakeAction iid (actionCost a Action.Move) Action.Move
      , CheckAttackOfOpportunity iid
      , MoveAction iid lid False
      ]
    MoveAction iid lid False | iid == investigatorId -> do
      unshiftMessage (MoveTo iid lid)
      pure $ takeAction Action.Move a
    InvestigatorAssignDamage iid eid health sanity | iid == investigatorId -> do
      allDamageableAssets <-
        HashSet.toList . HashSet.map unDamageableAssetId <$> asks (getSet iid)
      a <$ unshiftMessage
        (Ask $ ChooseOne
          (InvestigatorDamage investigatorId (EnemySource eid) health sanity
          : map (\k -> AssetDamage k eid health sanity) allDamageableAssets
          )
        )
    Investigate iid lid skillType True -> a <$ unshiftMessages
      [ TakeAction iid (actionCost a Action.Investigate) Action.Investigate
      , CheckAttackOfOpportunity iid
      , Investigate iid lid skillType False
      ]
    InvestigatorDiscoverClues iid lid n | iid == investigatorId ->
      a <$ unshiftMessage
        (DiscoverCluesAtLocation iid lid (cluesToDiscover a n))
    DiscoverClues iid lid n | iid == investigatorId -> do
      availableAbilities <- getAvailableAbilities a
      filteredAbilities <- filterM
        (flip (abilityInWindows [WhenDiscoverClues You YourLocation]) a)
        availableAbilities
      a <$ unshiftMessage
        (Ask
        $ ChooseOne
        $ map
            (\ability ->
              Run [UseCardAbility iid ability, DiscoverClues iid lid n]
            )
            filteredAbilities
        <> [AfterDiscoverClues iid lid n]
        )
    AfterDiscoverClues iid _ n | iid == investigatorId -> pure $ a & clues +~ n
    PayCardCost iid cardId | iid == investigatorId -> do
      let
        card = fromJustNote "not in hand"
          $ find ((== cardId) . getCardId) (a ^. hand)
        cost = getCost card
      pure $ a & resources -~ cost
    PlayCard iid cardId True -> do
      let
        card = fromJustNote "not in hand"
          $ find ((== cardId) . getCardId) investigatorHand
        actionCost' = case card of
          PlayerCard pc -> if pcFast pc then 0 else actionCost a Action.Play
          _ -> actionCost a Action.Play
      a <$ unshiftMessages
        [ TakeAction iid actionCost' Action.Play
        , PayCardCost iid cardId
        , CheckAttackOfOpportunity iid
        , PlayCard iid cardId False
        ]
    PlayedCard iid cardId | iid == investigatorId ->
      pure $ a & hand %~ filter ((/= cardId) . getCardId)
    InvestigatorPlayAsset iid aid | iid == investigatorId ->
      pure $ a & assets %~ HashSet.insert aid
    InvestigatorDamage iid _ health sanity | iid == investigatorId -> do
      let a' = a & healthDamage +~ health & sanityDamage +~ sanity
      if facingDefeat a'
        then a' <$ unshiftMessage (InvestigatorWhenDefeated iid)
        else pure a'
    InvestigatorWhenDefeated iid | iid == investigatorId -> do
      unshiftMessage (InvestigatorDefeated iid)
      pure $ a & defeated .~ True
    MoveAllTo lid -> a <$ unshiftMessage (MoveTo investigatorId lid)
    MoveTo iid lid | iid == investigatorId -> do
      connectedLocations' <- HashSet.map unConnectedLocationId
        <$> asks (getSet lid)
      unshiftMessages [WhenEnterLocation iid lid, AfterEnterLocation iid lid]
      pure $ a & locationId .~ lid & connectedLocations .~ connectedLocations'
    AddedConnection lid1 lid2
      | lid1 == investigatorLocation || lid2 == investigatorLocation
      -> pure
        $ a
        & (connectedLocations %~ HashSet.insert lid1)
        & (connectedLocations %~ HashSet.insert lid2)
    AddModifier (InvestigatorTarget iid) modifier | iid == investigatorId ->
      pure $ a & modifiers %~ (modifier :)
    RemoveAllModifiersOnTargetFrom (InvestigatorTarget iid) source
      | iid == investigatorId -> pure $ a & modifiers %~ filter
        ((source /=) . sourceOfModifier)
    ChooseEndTurn iid | iid == investigatorId -> pure $ a & endedTurn .~ True
    BeginRound ->
      pure
        $ a
        & (endedTurn .~ False)
        & (remainingActions .~ 3)
        & (actionsTaken .~ mempty)
    DrawCards iid n True | iid == investigatorId -> a <$ unshiftMessages
      [ TakeAction iid (actionCost a Action.Draw) Action.Draw
      , CheckAttackOfOpportunity iid
      , DrawCards iid n False
      ]
    DrawCards iid n False | iid == investigatorId ->
      if null (unDeck investigatorDeck)
        then if null investigatorDiscard
          then pure a
          else
            a <$ unshiftMessages
              [ShuffleDiscardBackIn iid, DrawCards iid n False]
        else do
          let
            (mcard, deck') = drawCard (coerce investigatorDeck)
            handUpdate = maybe id ((:) . PlayerCard) mcard
          case mcard of
            Just MkPlayerCard {..} -> when (pcCardType == PlayerTreacheryType)
              $ unshiftMessage (DrewPlayerTreachery iid pcCardCode)
            Nothing -> pure ()
          pure $ a & hand %~ handUpdate & deck .~ Deck deck'
    InvestigatorSpendClues iid n | iid == investigatorId ->
      pure $ a & clues -~ n
    SpendResources iid n | iid == investigatorId ->
      pure $ a & resources -~ n & resources %~ max 0
    TakeResources iid n True | iid == investigatorId -> a <$ unshiftMessages
      [ TakeAction iid (actionCost a Action.Resource) Action.Resource
      , CheckAttackOfOpportunity iid
      , TakeResources iid n False
      ]
    TakeResources iid n False | iid == investigatorId ->
      pure $ a & resources +~ n
    EmptyDeck iid | iid == investigatorId -> a <$ unshiftMessages
      [ShuffleDiscardBackIn iid, InvestigatorDamage iid EmptyDeckSource 0 1]
    AllDrawEncounterCard ->
      a <$ unshiftMessage (InvestigatorDrawEncounterCard investigatorId)
    RevelationSkillTest iid source skillType difficulty onSuccess onFailure ->
      a <$ unshiftMessage
        (BeginSkillTest iid source skillType difficulty onSuccess onFailure [])
    ActivateCardAbilityAction iid ability@(_, _, abilityType, _)
      | iid == investigatorId -> do
        unshiftMessage (UseCardAbility iid ability) -- We should check action type when added for aoo
        case abilityType of
          ActionAbility _ actionType ->
            if actionType
                `notElem` [ Action.Fight
                          , Action.Evade
                          , Action.Resign
                          , Action.Parley
                          ]
              then unshiftMessage (CheckAttackOfOpportunity iid)
              else pure ()
          _ -> pure ()
        pure a
    AllDrawCardAndResource -> do
      let
        (mcard, deck') = drawCard (coerce investigatorDeck)
        handUpdate = maybe id ((:) . PlayerCard) mcard
      when (null deck') $ unshiftMessage (EmptyDeck investigatorId)
      pure $ a & resources +~ 1 & hand %~ handUpdate & deck .~ Deck deck'
    LoadDeck iid deck' | iid == investigatorId -> do
      shuffled <- liftIO $ shuffleM deck'
      pure $ a & deck .~ Deck shuffled
    BeforeSkillTest iid skillType | iid == investigatorId -> do
      commitedCardIds <- map unCommitedCardId . HashSet.toList <$> asks
        (getSet iid)
      availableAbilities <- getAvailableAbilities a
      let
        filteredAbilities = flip filter availableAbilities $ \case
          (_, _, FreeAbility (SkillTestWindow st), _) | st == skillType -> True
          _ -> False
        triggerMessage = StartSkillTest
        beginMessage = BeforeSkillTest iid skillType
        committableCards = flip filter investigatorHand $ \case
          PlayerCard MkPlayerCard {..} ->
            pcId
              `notElem` commitedCardIds
              && (SkillWild `elem` pcSkills || skillType `elem` pcSkills)
          _ -> False
      if not (null filteredAbilities) || not (null committableCards) || not
        (null commitedCardIds)
      then
        unshiftMessage
          (Ask $ ChooseOne
            (map
                (\ability -> Run [UseCardAbility iid ability, beginMessage])
                filteredAbilities
            <> map
                 (\card ->
                   Run
                     [SkillTestCommitCard iid (getCardId card), beginMessage]
                 )
                 committableCards
            <> map
                 (\cardId ->
                   Run [SkillTestUncommitCard iid cardId, beginMessage]
                 )
                 commitedCardIds
            <> [triggerMessage]
            )
          )
      else
        unshiftMessage triggerMessage
      pure a
    InvestigatorStartSkillTest iid skillType tempModifiers ->
      a <$ unshiftMessage
        (TriggerSkillTest
          iid
          skillType
          (skillValueFor skillType tempModifiers a)
        )
    CheckFastWindow iid windows | iid == investigatorId -> do
      availableAbilities <- getAvailableAbilities a
      let playableCards = filter (fastIsPlayable a windows) investigatorHand
      filteredAbilities <- filterM
        (flip (abilityInWindows windows) a)
        availableAbilities
      if not (null playableCards)
        then a <$ unshiftMessage
          (Ask
          $ ChooseOne
          $ map
              (\c -> Run
                [ PayCardCost iid (getCardId c)
                , PlayCard iid (getCardId c) False
                , CheckFastWindow iid windows
                ]
              )
              playableCards
          <> map
               (\ability ->
                 Run
                   [ UseCardAbility investigatorId ability
                   , CheckFastWindow iid windows
                   ]
               )
               filteredAbilities
          <> [Continue "Skip playing fast cards"]
          )
        else pure a

    TakeAction iid actionCost' action | iid == investigatorId ->
      pure
        $ a
        & (remainingActions %~ max 0 . subtract actionCost')
        & (actionsTaken %~ (<> [action]))
    PlayerWindow iid | iid == investigatorId -> do
      advanceableActIds <-
        HashSet.toList . HashSet.map unAdvanceableActId <$> asks (getSet ())
      canDos <- filterM (canPerform a) Action.allActions
      blockedLocationIds <- HashSet.map unBlockedLocationId <$> asks (getSet ())
      let
        accessibleLocations =
          investigatorConnectedLocations `difference` blockedLocationIds
      a <$ unshiftMessage
        (Ask $ ChooseOne
          ([ TakeResources iid 1 True | Action.Resource `elem` canDos ]
          <> [ DrawCards iid 1 True | Action.Draw `elem` canDos ]
          <> [ ChooseActivateCardAbilityAction iid
             | Action.Ability `elem` canDos
             ]
          <> [ PlayCard iid (getCardId c) True
             | c <- investigatorHand
             , Action.Play
               `elem` canDos
               || fastIsPlayable a [DuringTurn You] c
             , isPlayable a [DuringTurn You] c
             ]
          <> [ MoveAction iid lid True
             | Action.Move `elem` canDos
             , lid <- HashSet.toList accessibleLocations
             ]
          <> [ Investigate iid investigatorLocation SkillIntellect True
             | Action.Investigate `elem` canDos
             ]
          <> [ FightEnemy iid eid SkillCombat [] True
             | Action.Fight `elem` canDos
             , eid <- HashSet.toList investigatorEngagedEnemies
             ]
          <> [ ChooseEngageEnemyAction iid | Action.Engage `elem` canDos ]
          <> [ EvadeEnemy iid eid SkillAgility True
             | Action.Evade `elem` canDos
             , eid <- HashSet.toList investigatorEngagedEnemies
             ]
          <> map AdvanceAct advanceableActIds
          <> [ChooseEndTurn iid]
          )
        )
    _ -> pure a
