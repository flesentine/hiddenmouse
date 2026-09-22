# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#21 Core experience + offline images

Park Hunt now supports the complete local hunt loop, offline image packaging/downsampling, progress, Collection, Settings, and CI guards for offline/image integrity.

### #22 Accessibility

The core experience has been hardened for Dynamic Type and VoiceOver without capping the user’s preferred text size.

- metadata rows use adaptive horizontal/vertical layouts instead of compressing text,
- Hunt clue headers stack when accessibility text sizes need more room,
- Progress totals and section rows adapt vertically at large text sizes,
- custom action buttons use at least a **48 pt** tap target,
- difficulty is always presented as text plus an icon,
- Found / Started / Unfound states are explicit text and symbols rather than color-only states,
- Nearby and Collection rows expose deterministic VoiceOver summaries with title, state, difficulty, location context, and distance/date when available,
- Hunt clue cards expose clue title, clue position, and clue text as one meaningful VoiceOver element,
- important page/section titles participate in VoiceOver’s heading rotor,
- the Reveal image has descriptive alternative text while list thumbnails remain decorative,
- Help Style choices expose both their description and selected/not-selected state,
- progress bars expose numeric “x of y found” accessibility values.

The app continues to use semantic SwiftUI fonts and system foreground styles, so text responds to Dynamic Type and colors follow system contrast/appearance settings.

## Verification

CI continues to run:

```text
Verify offline core
→ Verify image assets
→ Generate Xcode project
→ Build for iOS Simulator
```

Accessibility-label source tests are committed for Nearby, Collection, Hunt clue, and progress descriptions. Full XCTest execution remains part of #32; UI accessibility traversal testing remains part of #33.

## Next effort

**#23 One-handed UX polish:** move the highest-frequency hunt actions into the easiest thumb zone and tighten button ordering/spacing for in-park use.
