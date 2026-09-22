# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#20 Core experience + offline hardening

Park Hunt now supports the complete local hunt loop and has CI protection against accidental networking in the prototype core.

### #21 Image handling

The app now has an offline, memory-conscious image pipeline for discovery thumbnails and full reveals.

Content can independently declare:

- `thumbnailImageName` — small list/browse artwork,
- `revealImageName` — larger exact-reference artwork.

Older JSON without `thumbnailImageName` remains compatible.

### Runtime behavior

`BundledRevealImageStore` now uses ImageIO thumbnail generation rather than decoding original photos at their full source size.

- thumbnails are capped at **320 px**,
- reveal images are capped at **1600 px**,
- decoded images are cached by filename + requested pixel size,
- images are loaded only from the application bundle.

Collection and Nearby rows use the thumbnail asset when provided. Reveal uses the larger downsampled reveal asset.

### Authoring / compression

Use the bundled helper to turn one source photo into the two production variants:

```bash
./scripts/prepare-discovery-image.sh ~/Desktop/source.jpg pirates-secret-001
```

It produces:

```text
ParkHunt/Resources/Images/pirates-secret-001-thumb.jpg
ParkHunt/Resources/Images/pirates-secret-001-reveal.jpg
```

and prints the two JSON fields to paste into the discovery record.

The authoring sizes are:

- thumbnail: max 320 px, JPEG normal quality,
- reveal: max 1600 px, JPEG high quality.

### CI packaging guard

GitHub Actions now verifies image references before building.

For every referenced image it requires:

- filename-only references,
- a packaged file in `ParkHunt/Resources/Images/`,
- JPG/JPEG/HEIC/PNG format,
- thumbnail file size no larger than **400 KB**,
- reveal file size no larger than **2 MB**.

The existing offline-readiness loader also verifies both thumbnail and reveal references exist in the installed bundle.

The prototype discovery currently declares no images, so its behavior is unchanged until real field-test content is populated.

## Verification

CI now runs:

```text
Verify offline core
→ Verify image assets
→ Generate Xcode project
→ Build for iOS Simulator
```

Unit-test source also covers backward-compatible image decoding, thumbnail/reveal round-tripping, and independent offline validation of the two image roles. The workflow still builds rather than runs XCTest; full test execution remains in #32.

## Architecture

```text
ParkHunt/
├── Core/
│   ├── Content/  Bundle image store + downsampling
│   └── Offline/  Referenced-image readiness validation
├── Features/
│   ├── Collection/ Thumbnail presentation
│   ├── Nearby/     Thumbnail presentation
│   ├── Reveal/     Downsampled reveal presentation
│   └── Shared/     DiscoveryThumbnailView
└── Resources/
    └── Images/      Optimized packaged image variants

scripts/
├── prepare-discovery-image.sh
├── verify-image-assets.py
└── verify-offline-core.sh
```

## Next effort

**#22 Accessibility:** Dynamic Type, VoiceOver, contrast, large tap areas, and non-color-only difficulty/status presentation across the core hunt flow.
