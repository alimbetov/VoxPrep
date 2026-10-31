# CareerSpeak — Marketing & Design Expert Panel Review

**Status:** PRODUCT / UX / BRAND AUDIT  
**Branch:** `feat/backend-contract-gap-audit`  
**Baseline:** `feat/p2-flutter-production-adapters` + backend contract gap audit  
**Review type:** simulated cross-functional expert panel used as a design critique technique; no claim is made that external named experts participated.

---

## 1. Executive verdict

CareerSpeak has a stronger technical foundation than its current product expression.

The architecture already communicates several valuable product qualities:

- offline-first reliability;
- deterministic content delivery;
- local-first privacy;
- real audio support;
- adaptive Flutter UI;
- multilingual support;
- professional rather than childish visual direction.

However, the current learner experience does not yet convert those strengths into a clear market proposition.

The main issue is not visual polish. The main issue is **product hierarchy**.

Today the product presents three promises at once:

```text
Professional English
IELTS preparation
International interview practice
```

These are related, but they represent different jobs-to-be-done, purchase motivations, learning loops and success metrics.

The panel recommendation is therefore:

> CareerSpeak should not market itself as a generic English-learning catalogue. It should present itself as a goal-driven English performance coach, with career/interview English as the strongest initial wedge and IELTS as a clearly separated goal path.

A good internal product sentence would be:

```text
CareerSpeak helps non-native professionals practise the English they need
for interviews, work communication and international career progression —
with structured listening, speaking, testing and review that works offline.
```

This positioning makes the existing `READ → LISTEN → REPEAT → TEST → REVIEW` loop substantially more meaningful.

---

# 2. Simulated expert panel

The review intentionally combines different professional perspectives.

## A. Product Marketing Strategist

Focus:

- category positioning;
- target audience;
- value proposition;
- differentiation;
- messaging hierarchy;
- store/landing-page conversion.

## B. Senior UX / Product Designer

Focus:

- onboarding;
- information architecture;
- navigation;
- task completion;
- cognitive load;
- state/empty/error experiences.

## C. Brand / Visual Design Director

Focus:

- product identity;
- visual hierarchy;
- emotional tone;
- component language;
- differentiation beyond default Material 3.

## D. Growth / Retention Product Lead

Focus:

- activation;
- habit formation;
- return loops;
- progress communication;
- recommendation quality;
- re-engagement.

## E. Learning Experience Designer

Focus:

- pedagogical loop;
- review semantics;
- learning goals;
- feedback;
- perceived progress;
- confidence building.

The recommendations below represent the combined panel view.

---

# 3. What is already strong

## 3.1 The product has a credible technical story

The offline-first architecture is not only an implementation property. It can become a market differentiator for learners who:

- commute;
- travel;
- have unreliable mobile connectivity;
- want downloaded listening packs;
- do not want an account before trying the product.

Recommended market message:

```text
Download once. Practise anywhere.
```

Do not expose infrastructure terms such as Drift, manifests or sync journals to users, but do expose the benefit.

---

## 3.2 Local-first learner state is a useful trust signal

The MVP intentionally avoids a learner account and keeps progress/favorites locally.

This can be communicated positively:

```text
No account required to start.
Your learning progress stays on your device.
```

Do not overstate privacy guarantees beyond the actual implementation, but this is a meaningful onboarding-friction advantage.

---

## 3.3 Material Design 3 is the correct implementation baseline

The existing decision to use one coherent Material 3 system is sound.

The panel agrees with the intended characteristics:

```text
professional
academic
calm
modern
focused
```

The risk is not Material 3 itself. The risk is stopping at **generic Material defaults** and failing to create a recognizable CareerSpeak visual identity.

---

## 3.4 Adaptive layout is product quality, not just engineering quality

The existing COMPACT / MEDIUM / EXPANDED / LARGE strategy is appropriate.

Particularly strong:

- navigation switching without business-state reset;
- master/detail on wider layouts;
- large text qualification;
- RTL support;
- no tablet-only feature forks.

This should remain invisible to marketing copy but visible in product quality and screenshots.

---

# 4. Critical marketing findings

## MKT-01 — Positioning is currently too broad

**Severity:** P0

Current headline direction effectively combines:

```text
Professional English + IELTS + interview practice
```

This is understandable as a roadmap but weak as a first-touch proposition.

A user should understand within seconds:

1. who the product is for;
2. what outcome it improves;
3. why this product rather than a generic English application.

### Recommendation

Use a primary wedge.

Recommended initial hierarchy:

```text
PRIMARY
International career / interview English

SECONDARY
Professional English practice

SEPARATE GOAL PATH
IELTS
```

This does not require deleting IELTS. It requires preventing IELTS and career preparation from competing for the same first-screen message.

### Backend/product implication

Content needs explicit goal/track metadata rather than only generic category/level fields.

Recommended backend-owned concepts:

```text
LearningGoal
LearningTrack
ContentGoalRef
```

Example goal codes:

```text
JOB_INTERVIEW
WORKPLACE_ENGLISH
IELTS
TECH_INTERVIEW
MANAGEMENT_INTERVIEW
```

Do not hardcode these as permanent Flutter enums if product managers must change them later.

---

## MKT-02 — The product lacks a strong differentiation sentence

**Severity:** P0

"English learning" is a crowded mental category. CareerSpeak should not compete on breadth.

The strongest differentiated combination already present in the architecture is:

```text
career-specific content
+ listening/speaking loop
+ structured review
+ real audio
+ offline-first
+ multilingual learning support
```

Recommended positioning territory:

> Practical English rehearsal for real career moments.

Alternative message territory:

```text
Practise the English before you need it.
```

This is stronger than presenting the product as another catalogue of vocabulary and tests.

---

## MKT-03 — Content should be packaged around outcomes, not implementation content types

**Severity:** P1

Current content types are useful technically:

```text
vocabulary
interview
topic
shadowing
phrase
```

But these are not necessarily the strongest user-facing navigation model.

A learner is more likely to think:

```text
I have an interview next week
I need to explain my experience
I need to answer behavioural questions
I need to speak more confidently
I need IELTS 7.0
```

than:

```text
I want a shadowing object
```

### Recommendation

Keep content types for content architecture, but introduce goal-oriented collections such as:

```text
Senior Java interview
Tell me about yourself
Behavioural interview
System design English
Meetings and status updates
Salary and negotiation
IELTS Speaking Part 2
```

### Backend implication

Introduce backend-owned collections/programs:

```text
LearningCollection
CollectionContentRef
```

Possible fields:

```text
code
title
subtitle
description
goalCode
levelCode
estimatedMinutes
heroAssetId
sortOrder
active
contentRefs[]
```

---

# 5. Critical UX findings

## UX-01 — Onboarding is missing from the current product experience

**Severity:** P0

The specification anticipates onboarding, but the current implemented feature surface primarily begins with Home/Learn/Tests/Review/Settings.

The first session needs to answer a small number of high-value questions.

Recommended onboarding:

```text
1. What are you preparing for?
   Interview / Workplace / IELTS

2. What is your approximate English level?
   B1 / B2 / C1 / Not sure

3. What support language do you want?
   English / Russian / Kazakh

4. Which English accent do you prefer?
   US / UK / Australian / No preference

5. Download a starter pack?
   Yes / Later
```

The flow should be skippable and should not require registration.

### Why it matters

Without onboarding, Home cannot legitimately say "Recommended" because it has almost no basis for recommendation.

### Backend/device implication

The selected learner goal and preferences can remain device-owned in MVP.

Backend must supply the goal/track/catalog metadata needed to fulfil those preferences.

---

## UX-02 — Home is informative, but not yet motivational

**Severity:** P1

Current Home emphasizes counters:

```text
Completed
Listened
Favorites
Due
```

Counters are useful, but they describe database state more than learner momentum.

### Recommendation

Change the Home hierarchy to:

```text
1. Today / next best action
2. Continue current learning path
3. Goal progress
4. Recommended next lesson
5. Review due
6. Library shortcuts
```

Example:

```text
Interview in 8 days
Continue: Explaining your backend experience
12 min
[Continue]

This week
4 sessions · 46 min · 3 review items
```

The product should answer:

> What should I do next?

before:

> How many items exist in each marker state?

---

## UX-03 — `Due` currently has misleading semantics

**Severity:** P0

The current implementation effectively treats:

```text
Due = not completed
```

and the Review screen also uses incomplete content for its due filter.

This is not a real review schedule.

The word `Due` implies pedagogical scheduling and therefore creates a trust obligation.

### Recommendation

Either:

**Option A — until scheduling exists**

rename it to:

```text
Not completed
```

or

**Option B — preferred product direction**

implement a real `ReviewScheduler` with:

```text
nextReviewAt
reviewStage
lastReviewedAt
reviewOutcome
```

Then "Due today" becomes a legitimate learner promise.

### Backend/device implication

Review scheduling can remain device-owned in MVP, but it must be a real domain model rather than a presentation alias for incomplete content.

---

## UX-04 — User-facing copy leaks engineering implementation language

**Severity:** P0

Current product copy includes implementation-oriented phrases such as:

```text
Assessment catalogue qualified against repository ports before production persistence is connected.
```

and:

```text
Offline content is managed by production adapters
```

These sentences must never reach production users.

### Recommendation

Introduce a strict rule:

> No architecture, adapter, repository, persistence, qualification, manifest or sync implementation vocabulary in learner-facing strings.

Replace with benefit/state language.

Examples:

```text
Tests
Practise with short quizzes or timed exam sessions.
```

```text
Downloads
Manage lessons saved for offline practice.
```

---

## UX-05 — Learn is a flat catalogue where a guided path is needed

**Severity:** P1

Search + filters are useful for power users, but the current Learn experience is fundamentally library-first.

Recommended hierarchy:

```text
Learn
├── Continue your path
├── Goals / tracks
├── Recommended
├── Categories
└── Browse all
```

Search remains available but should not carry the main discovery burden.

---

## UX-06 — Filter vocabulary is too system-oriented

**Severity:** P2

Examples:

```text
Not listened
Not completed
```

These are correct state filters, but are not always optimal primary learner language.

Possible more human labels:

```text
New to listen
In progress
Saved
Completed
```

Keep exact domain semantics internally; adapt labels for user comprehension.

---

## UX-07 — Empty states should teach and redirect

**Severity:** P1

Current empty states mostly say that no content matches or is available.

Recommended empty-state pattern:

```text
What happened
+ why
+ best next action
```

Example:

```text
No saved lessons yet.
Tap the heart on useful lessons and they will appear here.
[Browse lessons]
```

For sync/network failure, distinguish:

```text
No content published
No downloaded content
Network unavailable
Sync failed
Filter returned zero results
```

These are different user problems.

---

# 6. Visual / brand findings

## DES-01 — Material 3 should remain the system, but CareerSpeak needs a stronger signature

**Severity:** P1

The current design contract correctly avoids visual chaos, but the product still needs recognizable branded primitives.

Recommended signature components:

```text
CareerSpeak Learning Card
Goal/Track Card
Audio Practice Card
Interview Question Card
Review Card
Progress Ring / Goal Progress block
CareerSpeak Empty State
CareerSpeak Status Chip
```

These should be built from Material 3, not replace Material 3.

---

## DES-02 — Deep indigo is safe, but not sufficient as identity

**Severity:** P2

The provisional `#3F51B5` direction is professional but common.

Do not solve differentiation by adding many colors.

Instead build identity through:

- a disciplined indigo/ink core;
- one distinct accent family;
- typography hierarchy;
- audio waveform/voice motif;
- consistent illustration/graphic language;
- characteristic card composition;
- distinctive icon treatment.

The product should be recognizable in grayscale layout before relying on color.

---

## DES-03 — Avoid dashboard aesthetics on the learning home

**Severity:** P1

Four equal statistic cards can make the Home screen resemble an admin dashboard.

CareerSpeak is a learning product.

Use visual hierarchy around an active learning task rather than equal-weight KPIs.

Recommended priority:

```text
NEXT ACTION      strongest visual emphasis
CURRENT GOAL     second
PROGRESS         supporting
STATS            tertiary
```

---

## DES-04 — Career / interview content needs a more mature visual tone than gamified language apps

**Severity:** P1

The existing design-system decision already points in the right direction.

Recommended emotional territory:

```text
confidence
clarity
competence
progress
calm preparation
```

Avoid:

```text
childish mascots
excessive confetti
coins/hearts as economy
overly bright reward loops
competitive pressure
```

Lightweight positive reinforcement is still useful, but it should resemble professional coaching rather than a game economy.

---

# 7. Learning experience findings

## LRN-01 — The product loop is strong but needs visible continuity

**Severity:** P0

The declared loop is:

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

This is one of the strongest product assets in the repository.

However, it should become visible as a learner journey.

A lesson detail should communicate:

```text
Read      ✓
Listen    ✓
Repeat    current
Test      locked/next
Review    scheduled later
```

Do not make these rigid blockers for all content, but show progression.

### Backend implication

Backend content should be able to describe learning activities/steps rather than Flutter inferring every sequence from content type.

Potential model:

```text
LearningActivity
activityType
contentCode
sequence
required
```

This can be deferred if current content payload already maps naturally, but the model should be considered before backend contracts freeze.

---

## LRN-02 — Tests need meaningful feedback, not only scoring

**Severity:** P1

The current test model already has `skill` and `explanation`, which is good.

The production UX should use them to explain:

```text
what was wrong
why
which skill is weak
what to practise next
```

A score alone has low learning value.

Recommended completion screen:

```text
7/10
Strong: vocabulary, comprehension
Needs work: interview structure
Recommended next: STAR answers — 8 min
```

### Backend implication

Use stable `skillCode`, not free-text skill names, so recommendations and analytics can be deterministic.

---

## LRN-03 — Confidence and speaking practice need explicit product treatment

**Severity:** P1

Career/interview users care about performing under pressure, not merely consuming content.

Even before speech recognition exists, the UX can support:

```text
listen
pause
repeat aloud
record locally later
compare with model audio
retry
mark confident / needs practice
```

Do not market pronunciation scoring until a real scoring system exists.

---

# 8. Growth and retention findings

## GRW-01 — Activation event is currently undefined

**Severity:** P0

A meaningful activation event should not be "app opened" or "content downloaded".

Recommended MVP activation definition:

```text
Learner selects a goal
+ completes one full learning loop or meaningful lesson
+ returns or schedules review
```

Possible measurable proxy:

```text
goal selected
AND first content LISTENED
AND first content COMPLETED
```

No server analytics are required to define the product event conceptually.

---

## GRW-02 — `Continue learning` is good but should preserve actual context

**Severity:** P1

Current Home chooses the first incomplete item.

That is deterministic but not necessarily the user's real continuation point.

Preferred ranking:

```text
active playback/content session
> recently opened incomplete content
> current learning track next item
> recommended item
```

### Device implication

Persist:

```text
lastOpenedAt
lastActiveContentIdentity
currentTrackCode
```

where appropriate.

---

## GRW-03 — Recommendation needs an explicit contract

**Severity:** P1

The current Home has a `Recommended` section but simply takes a few content items.

This creates a semantic mismatch.

Until a real recommendation rule exists, rename it to something honest such as:

```text
Explore
Recently added
Popular for your goal
```

only when the underlying rule supports the label.

Longer term, recommendations can remain deterministic without ML:

```text
goal
level
content completion
skill gaps
current track
review schedule
```

---

## GRW-04 — Retention should come from utility, not artificial streak pressure

**Severity:** P1

For an adult professional audience, the strongest return triggers are:

```text
interview date
current preparation goal
scheduled review
unfinished track
new relevant content pack
offline-ready practice
```

A streak may be tested later, but it should not become the core motivational model.

---

# 9. Information architecture recommendation

The current top-level navigation:

```text
Home
Learn
Tests
Review
Settings/My
```

is broadly sound and should not be expanded casually.

The panel recommends preserving this top-level simplicity.

The major improvement belongs **inside Learn and Home**, not in adding more tabs.

Recommended structure:

```text
HOME
├── Next action
├── Current goal / track
├── Continue
├── Due review
└── Explore

LEARN
├── My path
├── Interview
├── Workplace English
├── IELTS
├── Collections
└── Browse all

TESTS
├── Quick check
├── Practice
├── Exam simulation
└── Previous local results

REVIEW
├── Due today
├── Needs practice
├── Saved
└── Completed history (optional)

MY / SETTINGS
├── Goal & level
├── Language support
├── Voice/accent
├── Downloads/storage
├── Appearance
└── About/privacy
```

---

# 10. Recommended backend contract additions caused by product/UX needs

This review reinforces the existing backend contract-gap audit and adds product-driven requirements.

## Existing required contracts

```text
B0.2 PracticeTest
B0.3 Taxonomy
B0.4 Locale / Voice catalog
```

## Additional recommended contracts

### B0.5 LearningGoal / LearningTrack

Backend-owned product configuration.

Suggested conceptual model:

```text
LearningGoal
- code
- title
- subtitle
- description
- active
- sortOrder
- heroAssetId?

LearningTrack
- code
- goalCode
- title
- subtitle
- levelCode?
- estimatedMinutes?
- active
- sortOrder

LearningTrackContentRef
- trackCode
- contentCode
- contentType
- sequence
- required
```

### B0.6 LearningCollection

For editorial packaging independent of rigid learning tracks.

```text
LearningCollection
- code
- title
- subtitle
- description
- goalCode?
- heroAssetId?
- active
- sortOrder
```

### B0.7 Stable Skill taxonomy

Required for meaningful test feedback and deterministic recommendations.

```text
Skill
- code
- label
- description?
- parentCode?
- active
- sortOrder
```

Examples:

```text
INTERVIEW_STRUCTURE
STAR_METHOD
TECHNICAL_VOCABULARY
FLUENCY
LISTENING_COMPREHENSION
IELTS_SPEAKING_COHERENCE
```

### B0.8 Editorial presentation metadata

Avoid pushing presentation decisions into Flutter code.

Backend-owned, carefully bounded metadata may include:

```text
featured
badgeCode?
heroAssetId?
editorialRank?
publishedAt
```

Do **not** turn backend payloads into arbitrary remote UI JSON. Flutter should still own layout and components.

The backend should define **what is promoted**, not **how pixels are drawn**.

---

# 11. Copywriting rules

Create a learner-facing copy standard before release.

## Never expose

```text
repository
adapter
persistence
manifest
DTO
port
qualification
sync journal
production implementation
schema
revision checksum
```

unless a diagnostic/developer screen explicitly requires it.

## Prefer

```text
Downloaded
Available offline
Update available
Ready to practise
Needs review
Saved
Completed
Continue
Try again
```

## Tone

```text
adult
concise
confident
supportive
non-childish
non-corporate
```

Avoid both infantilization and enterprise-software jargon.

---

# 12. Store / landing-page concept

The application should eventually be marketable through a simple 5-frame story.

## Frame 1 — Outcome

```text
Prepare your English for the interview that matters.
```

## Frame 2 — Method

```text
Read. Listen. Repeat. Test. Review.
```

## Frame 3 — Relevant content

```text
Technical interviews, behavioural answers and workplace English.
```

## Frame 4 — Offline

```text
Download practice packs and keep learning anywhere.
```

## Frame 5 — Language support

```text
Learn in English with Russian or Kazakh support when you need it.
```

IELTS can have its own store screenshot/landing-page subsection rather than sharing the main headline equally with career preparation.

---

# 13. Priority matrix

## P0 — fix before treating the product UX as production-ready

```text
MKT-01  choose primary positioning hierarchy
MKT-02  define one differentiation sentence
UX-01   add goal-oriented onboarding
UX-03   fix misleading Due semantics
UX-04   remove engineering language from learner UI
LRN-01  make READ→LISTEN→REPEAT→TEST→REVIEW visible as a product loop
GRW-01  define activation event
```

## P1 — next product design slice

```text
MKT-03  outcome-oriented collections/tracks
UX-02   redesign Home around next best action
UX-05   move Learn from flat catalogue toward guided discovery
UX-07   actionable empty/error states
DES-01  branded CareerSpeak component vocabulary
DES-03  reduce dashboard character on Home
DES-04  professional coaching visual tone
LRN-02  skill-based test feedback
LRN-03  explicit repeat/speaking interaction
GRW-02  actual continuation context
GRW-03  honest deterministic recommendations
GRW-04  utility-led retention model
```

## P2 — refinement / qualification

```text
UX-06   learner-friendly state labels
DES-02  refine visual signature and brand palette
store screenshots / landing-page copy
microcopy consistency audit
motion and audio visualisation refinement
```

---

# 14. Proposed product-design roadmap

The panel recommends **not** attempting a large visual redesign immediately.

Use the following sequence:

```text
PD0  Product positioning freeze
     ↓
PD1  Goal / track / taxonomy backend contracts
     ↓
PD2  First-run onboarding
     ↓
PD3  Home information hierarchy redesign
     ↓
PD4  Learn goal-based discovery
     ↓
PD5  Real review scheduling semantics
     ↓
PD6  PracticeTest production integration + feedback UX
     ↓
PD7  CareerSpeak branded component layer
     ↓
PD8  Store/landing-page packaging
     ↓
PD9  usability + accessibility + conversion qualification
```

This order prevents polishing screens whose product hierarchy is still unstable.

---

# 15. Recommended product north star

For the MVP, the panel recommends optimizing for:

> **Completed meaningful practice sessions per active learner**, not raw content views.

A meaningful practice session should represent real progress through the learning loop rather than opening a card.

Supporting product metrics can later include:

```text
first-session activation
lesson completion
listen → repeat progression
review completion
track completion
7-day return
content saved for offline use
```

Do not let analytics architecture dictate the product before the learning loop itself is valid.

---

# 16. Final panel decision

## Keep

```text
offline-first architecture
local-first progress
Material Design 3
adaptive UI
small top-level navigation
content revision discipline
real audio direction
multilingual support
READ→LISTEN→REPEAT→TEST→REVIEW concept
```

## Change

```text
generic multi-purpose positioning
flat catalogue-first discovery
dashboard-heavy Home hierarchy
fake/weak Due semantics
engineering language in learner UI
unqualified Recommended label
hardcoded product catalogs in Flutter
```

## Add

```text
goal-based onboarding
LearningGoal / LearningTrack
editorial collections
stable Skill taxonomy
real review scheduling
meaningful test feedback
branded CareerSpeak component language
clear market differentiation
```

The core conclusion is:

> The engineering foundation is sufficiently disciplined. The next risk is no longer architecture alone; it is building a technically correct application whose value proposition is too broad and whose UI exposes system state rather than learner intent.

The product should now shift from **catalogue delivery** to **goal-driven coaching** while preserving the existing offline-first and deterministic backend architecture.
