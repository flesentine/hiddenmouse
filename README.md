# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#27 Core experience + local analytics

Park Hunt now supports the complete local hunt loop, offline image packaging/downsampling, progress, Collection, Settings, accessibility, one-handed controls, haptics, active-hunt restoration, explicit recovery states, and a local typed analytics foundation.

### #28 Privacy implementation

Privacy controls and retention rules are now explicit and enforced.

#### Location

- Nearby still requests only **When In Use** authorization.
- A location fix exists only in memory for the current Nearby calculation.
- `LocationFix` intentionally does not conform to `Codable`.
- Leaving Nearby or backgrounding the app immediately discards the in-memory fix.
- Returning to an active Nearby screen obtains a fresh foreground fix instead of retaining old coordinates.
- No location history, latitude, longitude, accuracy, or raw `LocationFix` is persisted.

#### Local analytics controls

Settings → Privacy now includes:

- **Local Analytics** on/off,
- current locally stored event count,
- **Clear Analytics Data** with destructive confirmation.

Local Analytics defaults on because it remains entirely on-device. Turning it off immediately stops new event recording but does not silently delete existing data. Clear Analytics Data permanently deletes the stored event buffer without changing hunt progress or the analytics preference.

#### Retention

Analytics now has two independent limits:

- newest **500 events** maximum,
- automatic **30-day** retention.

Expired events are pruned on read and write.

#### CI privacy guard

`scripts/verify-privacy-boundaries.py` fails CI if:

- a Swift file that uses `UserDefaults` also references precise-location fields/types,
- `LocationFix` becomes Codable,
- the location layer gains file/UserDefaults persistence,
- the typed analytics schema adds banned precise-location or sensitive-content identifiers.

The Privacy & Legal screen documents these behaviors.

## Verification

CI now runs:

```text
Verify offline core
→ Verify image assets
→ Verify privacy boundaries
→ Generate Xcode project
→ Build for iOS Simulator
```

Source tests cover analytics preference behavior, disabling collection, independent clearing, and 30-day retention. Full XCTest execution remains scheduled for #32.

## Next effort

**#29 Content admin format:** make adding and maintaining discoveries possible without editing Swift code.
