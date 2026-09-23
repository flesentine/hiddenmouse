# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#26 Core experience + recovery

Park Hunt now supports the complete local hunt loop, offline image packaging/downsampling, progress, Collection, Settings, accessibility, one-handed controls, haptics, active-hunt restoration, and explicit recovery/error states.

### #27 Analytics foundation

The prototype now has a local, strongly typed analytics foundation for measuring the core hunt funnel without introducing a network SDK.

Recorded events:

- app open,
- hunt started,
- active unfinished hunt restored,
- normal clue revealed,
- detailed help revealed,
- full reveal opened,
- discovery found,
- Find Another tapped,
- unfinished hunt deliberately exited.

Analytics records may contain only bounded gameplay metadata such as discovery ID, land ID, category, difficulty, hint order/kind, next discovery ID, and whether Reveal was open during restoration.

They deliberately do **not** contain:

- latitude/longitude or location fixes,
- clue text,
- reveal text,
- discovery titles,
- image names,
- tags,
- a user ID,
- a device ID.

Events are stored only in local UserDefaults through `UserDefaultsAnalyticsRecorder`. No analytics network request, SDK, or upload path exists. The local buffer is capped at the newest **500 events** so prototype instrumentation cannot grow without bound.

Restored hunts record `activeHuntRestored` rather than being counted as a new `huntStarted`, which keeps return/retention behavior separate from new hunt starts. Deliberately leaving an unfinished hunt records `huntExitedUnfinished`, allowing later field-test analysis to distinguish abandonment from return.

The Privacy & Legal screen now documents the local analytics behavior.

## Verification

CI continues to run:

```text
Verify offline core
→ Verify image assets
→ Generate Xcode project
→ Build for iOS Simulator
```

Source tests cover event typing, restoration metadata, privacy-sensitive field exclusion, local persistence, clearing, and bounded event retention. Full XCTest execution remains scheduled for #32.

## Next effort

**#28 Privacy implementation:** formalize local-data retention and privacy controls, ensure precise location is never persisted, and add user-facing controls for locally stored analytics where appropriate.
