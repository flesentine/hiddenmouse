# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#28 Core experience + privacy

Park Hunt now supports the complete local hunt loop, offline image packaging/downsampling, progress, Collection, Settings, accessibility, one-handed controls, haptics, restoration, recovery states, local analytics, and explicit privacy controls.

### #29 Content admin format

Content authors no longer need to touch Swift or hand-maintain the app’s bundled aggregate catalog.

The source of truth is now:

```text
ContentAdmin/
├── lands.json
├── areas.json
├── discoveries/
│   └── 010-prototype-secret-001.json
└── templates/
    └── discovery.template.json
```

Each discovery is an independent JSON document. Its filename starts with a numeric editorial-order prefix so content can be reordered without changing the discovery’s stable ID.

`scripts/build-content-catalog.py` combines the admin source into the runtime bundle:

```bash
python3 scripts/build-content-catalog.py
```

CI runs:

```bash
python3 scripts/build-content-catalog.py --check
```

and fails if `ParkHunt/Resources/content-catalog.json` was edited directly or is out of sync with `ContentAdmin/`.

The complete authoring workflow, allowed enum values, image workflow, location shape, hint convention, verification states, and date format are documented in `ContentAdmin/README.md`.

The existing prototype discovery has been migrated into the admin source without changing its runtime content.

## Verification

CI now runs:

```text
Verify content admin catalog
→ Verify offline core
→ Verify image assets
→ Verify privacy boundaries
→ Generate Xcode project
→ Build for iOS Simulator
```

## Next effort

**#30 Content validation tools:** add editorial validation for missing hints, invalid coordinates, duplicate/stale IDs, bad image references, invalid land/area assignments, placeholder/TODO content, and incomplete records before content can ship.
