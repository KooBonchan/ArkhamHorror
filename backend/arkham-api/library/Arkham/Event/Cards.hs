module Arkham.Event.Cards (module Arkham.Event.Cards, module X) where

import Arkham.Prelude

import Arkham.Card.CardCode
import Arkham.Card.CardDef
import Arkham.Event.Cards.EdgeOfTheEarth as X
import Arkham.Event.Cards.NightOfTheZealot as X
import Arkham.Event.Cards.Parallel as X
import Arkham.Event.Cards.Promo as X
import Arkham.Event.Cards.ReturnTo as X
import Arkham.Event.Cards.Standalone as X
import Arkham.Event.Cards.Starter as X
import Arkham.Event.Cards.TheCircleUndone as X
import Arkham.Event.Cards.TheDreamEaters as X
import Arkham.Event.Cards.TheDunwichLegacy as X
import Arkham.Event.Cards.TheFeastOfHemlochVale as X
import Arkham.Event.Cards.TheForgottenAge as X
import Arkham.Event.Cards.TheInnsmouthConspiracy as X
import Arkham.Event.Cards.ThePathToCarcosa as X
import Arkham.Event.Cards.TheScarletKeys as X

allPlayerEventCards :: Map CardCode CardDef
allPlayerEventCards =
  mapFromList
    $ concatMap
      toCardCodePairs
      [ aChanceEncounter
      , aChanceEncounter2
      , aGlimmerOfHope
      , aTestOfWill
      , aTestOfWill1
      , aTestOfWill2
      , aWatchfulPeace3
      , absolution
      , abyssalRot
      , aceInTheHole3
      , actOfDesperation
      , adHoc
      , aemberRot
      , aethericCurrentYoth
      , aethericCurrentYuggoth
      , againstAllOdds2
      , alterFate1
      , alterFate3
      , ambush1
      , anatomicalDiagrams
      , antediluvianHymn
      , astoundingRevelation
      , astralTravel
      , atACrossroads1
      , backstab
      , backstab3
      , banish1
      , baitAndSwitch
      , baitAndSwitch3
      , bankJob
      , barricade
      , barricade3
      , beguile
      , bellyOfTheBeast
      , bideYourTime
      , bindMonster2
      , bizarreDiagnosis
      , blackMarket2
      , blindingLight
      , blindingLight2
      , bloodEclipse1
      , bloodEclipse3
      , bloodRite
      , bloodWillHaveBlood2
      , bolas
      , breachTheDoor
      , breakingAndEntering
      , breakingAndEntering2
      , burnAfterReading1
      , burningTheMidnightOil
      , buryThemDeep
      , butterflyEffect1
      , callForBackup2
      , callTheBeyond2
      , callingInFavors
      , captivatingDiscovery
      , cheapShot
      , cheapShot2
      , cheatDeath5
      , cheatTheSystem1
      , cleanSneak4
      , cleanThemOut
      , closeCall2
      , confound3
      , connectTheDots
      , contraband
      , contraband2
      , controlVariable
      , coupDeGrace
      , counterespionage1
      , counterpunch
      , counterpunch2
      , counterspell2
      , crackTheCase
      , crypticResearch4
      , crypticWritings
      , crypticWritings2
      , cunningDistraction
      , customAmmunition3
      , customModifications
      , daringManeuver
      , daringManeuver2
      , darkInsight
      , darkMemory
      , darkMemoryAdvanced
      , darkPact
      , darkProphecy
      , dawnStar1
      , decipheredReality5
      , decoy
      , deepKnowledge
      , delayTheInevitable
      , delveTooDeep
      , denyExistence
      , denyExistence5
      , devilsLuck
      , dirtyDeeds3
      , dodge
      , dodge2
      , drainEssence
      , drawnToTheFlame
      , dumbLuck
      , dumbLuck2
      , dynamiteBlast
      , dynamiteBlast2
      , dynamiteBlast3
      , easyMark1
      , eatLead
      , eatLead2
      , eavesdrop
      , eideticMemory3
      , elaborateDistraction
      , eldritchInitiation
      , eldritchInspiration
      , eldritchInspiration1
      , elusive
      , emergencyAid
      , emergencyCache
      , emergencyCache2
      , emergencyCache3
      , enchantWeapon3
      , endOfTheRoad
      , etherealForm
      , etherealForm2
      , etherealWeaving3
      , etherealSlip
      , etherealSlip2
      , eucatastrophe3
      , everVigilant1
      , everVigilant4
      , evidence
      , evidence1
      , existentialRiddle1
      , exploitWeakness
      , explosiveWard
      , exposeWeakness1
      , exposeWeakness3
      , extensiveResearch
      , extensiveResearch1
      , extraAmmunition1
      , falseSurrender
      , fangOfTyrthrha4
      , faustianBargain
      , fendOff3
      , fickleFortune3
      , fightOrFlight
      , fineTuning1
      , firstWatch
      , flare1
      , flurryOfBlows5
      , followed
      , foolMeOnce1
      , foresight1
      , forewarned1
      , fortuitousDiscovery
      , fortuneOrFate2
      , friendsInLowPlaces
      , galvanize1
      , gangUp1
      , gazeOfOuraxsh2
      , getBehindMe
      , getOverHere
      , getOverHere2
      , ghastlyRevelation
      , glimpseTheUnthinkable1
      , glimpseTheUnthinkable5
      , glory
      , grievousWound
      , grift
      , gritYourTeeth
      , guidance
      , guidance1
      , guidedByFaith
      , hallow3
      , handEyeCoordination1
      , handOfFate
      , harmonyRestored2
      , heedTheDream2
      , heroicRescue
      , heroicRescue2
      , hiddenPocket
      , hidingSpot
      , hitAndRun
      , hitMe
      , holdUp
      , honedInstinct
      , hotStreak2
      , hotStreak4
      , hypnoticGaze
      , hypnoticGaze2
      , ifItBleeds
      , illPayYouBack
      , illSeeYouInHell
      , illTakeThat
      , imDoneRunnin
      , imOuttaHere
      , impromptuBarrier
      , improvisation
      , improvisedWeapon
      , inTheShadows
      , infighting3
      , intelReport
      , interrogate
      , iveGotAPlan
      , iveGotAPlan2
      , iveHadWorse2
      , iveHadWorse4
      , joinTheCaravan1
      , juryRig
      , keepFaith
      , keepFaith2
      , kickingTheHornetsNest
      , knowledgeIsPower
      , lessonLearned2
      , letGodSortThemOut
      , letMeHandleThis
      , lifeline1
      , liveAndLearn
      , lodgeDebts
      , logicalReasoning
      , logicalReasoning4
      , lookWhatIFound
      , lookWhatIFound2
      , lucidDreaming2
      , lucky
      , lucky2
      , lucky3
      , lure1
      , lure2
      , makeshiftTrap
      , makingPreparations
      , manipulateDestiny2
      , manoAMano1
      , manoAMano2
      , mapTheArea
      , marksmanship1
      , meditativeTrance
      , mindOverMatter
      , mindOverMatter2
      , mindWipe1
      , mindWipe3
      , miracleWish5
      , momentOfRespite3
      , moneyTalks
      , moneyTalks2
      , monsterSlayer
      , monsterSlayer5
      , moonlightRitual
      , moonlightRitual2
      , motivationalSpeech
      , mysteriesRemain
      , mystifyingSong
      , narrowEscape
      , natureOfTheBeast1
      , noStoneUnturned
      , noStoneUnturned5
      , nothingLeftToLose3
      , obscureStudies
      , occultEvidence
      , occultInvocation
      , oneInTheChamber
      , oneTwoPunch
      , oneTwoPunch5
      , onTheHunt
      , onTheHunt3
      , onTheLam
      , onTheLamAdvanced
      , onTheTrail1
      , onTheTrail3
      , oops
      , oops2
      , openGate
      , parallelFates
      , parallelFates2
      , payDay1
      , payYourDue
      , perseverance
      , persuasion
      , pilfer
      , pilfer3
      , powerWord
      , practiceMakesPerfect
      , predatorOrPrey
      , premonition
      , preparedForTheWorst
      , preparedForTheWorst2
      , preposterousSketches
      , preposterousSketches2
      , protectingTheAnirniq2
      , pushedToTheLimit
      , putrescentRot
      , quantumFlux
      , quantumParadox
      , quickGetaway
      , radiantSmite1
      , readTheSigns
      , readTheSigns2
      , recharge2
      , recharge4
      , refine
      , regurgitation
      , reliable1
      , riastrad1
      , righteousHunt1
      , riteOfEquilibrium5
      , sacrifice1
      , salvage2
      , scarletRot
      , sceneOfTheCrime
      , scoutAhead
      , scroungeForSupplies
      , sealOfTheElders5
      , searchForTheTruth
      , searchForTheTruthAdvanced
      , secondWind
      , secondWind2
      , seekingAnswers
      , seekingAnswers2
      , shedALight
      , shortcut
      , shortcut2
      , shrineOfTheMoirai3
      , sleightOfHand
      , slipAway
      , slipAway2
      , smallFavor
      , smuggledGoods
      , snareTrap2
      , sneakAttack
      , sneakAttack2
      , sneakBy
      , snipe1
      , snitch2
      , soothingMelody
      , spectralRazor
      , spectralRazor2
      , stallForTime
      , standTogether
      , standTogether3
      , stargazing1
      , stirThePot
      , stirThePot5
      , stirringUpTrouble1
      , stormOfSpirits
      , stormOfSpirits3
      , stouthearted
      , stringOfCurses
      , sureGamble3
      , sweepingKick1
      , swiftReflexes
      , swiftReload2
      , taskForce
      , taunt
      , taunt2
      , taunt3
      , teamwork
      , telescopicSight3
      , temptFate
      , testingSprint
      , thePaintedWorld
      , theRavenQuill
      , theStygianEye3
      , theTruthBeckons
      , thinkOnYourFeet
      , thinkOnYourFeet2
      , thirdTimesACharm2
      , thoroughInquiry
      , throwTheBookAtThem
      , tidesOfFate
      , timeWarp2
      , tinker
      , toeToToe
      , transmogrify
      , trialByFire
      , trialByFire3
      , trueSurvivor3
      , trusted
      , truthFromFiction
      , truthFromFiction2
      , twentyOneOrBust
      , uncageTheSoul
      , uncageTheSoul3
      , uncannyGrowth
      , underSurveillance1
      , underprepared
      , unearthTheAncients
      , unearthTheAncients2
      , untimelyTransaction1
      , unsolvedCase
      , vamp
      , vamp3
      , vantagePoint
      , virescentRot
      , voiceOfRa
      , wardOfProtection
      , wardOfProtection2
      , wardOfProtection5
      , wardOfRadiance
      , warningShot
      , waylay
      , wellMaintained1
      , willToSurvive
      , willToSurvive3
      , windsOfPower1
      , wingingIt
      , wordOfCommand2
      , wordOfWeal
      , wordOfWoe
      , workingAHunch
      , writtenInTheStars
      , wrongPlaceRightTime
      , youHandleThisOne
      , youOweMeOne
      ]

allEncounterEventCards :: Map CardCode CardDef
allEncounterEventCards = mapFromList $ concatMap toCardCodePairs [theStarsAreRight]
