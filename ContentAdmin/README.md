# Park Hunt Content Admin

This directory is the **authoring source of truth** for Park Hunt content.

Do not hand-edit `ParkHunt/Resources/content-catalog.json`. That file is generated from this directory and bundled into the iOS app.

## Layout

```text
ContentAdmin/
├── lands.json
├── areas.json
├── discovery-id-registry.json
├── discoveries/
│   └── 010-prototype-secret-001.json
└── templates/
    └── discovery.template.json
```

Each discovery lives in its own JSON file. Discovery filenames use a three-digit editorial-order prefix such as `010-`, `020-`, `030-`. The filename controls catalog order; the discovery's stable `id` controls identity.

## Standard content workflow

1. Copy `templates/discovery.template.json` into `discoveries/`.
2. Name it `NNN-descriptive-slug.json`.
3. Add its stable ID to `discovery-id-registry.json` with state `active`.
4. Fill in park, land, optional area, category, difficulty, location, hints, reveal, verification state, tags, and optional images.
5. Prepare images when needed:

```bash
./scripts/prepare-discovery-image.sh ~/Desktop/source.jpg <discovery-id>
```

6. Validate the editorial source:

```bash
python3 scripts/validate-content-admin.py
```

7. Generate the runtime catalog:

```bash
python3 scripts/build-content-catalog.py
```

8. Verify synchronization:

```bash
python3 scripts/build-content-catalog.py --check
```

## Shipping / field-test gate

Before a build is considered field-test or release content, run:

```bash
python3 scripts/validate-content-admin.py --shipping
```

Shipping mode rejects:

- any `_editorial.developmentOnly` discovery,
- registry entries still in `development`,
- placeholder/TODO/prototype text,
- `unverified` discoveries,
- `needsRecheck` discoveries.

The current prototype fixture is intentionally marked development-only, so normal development CI accepts it with warnings while `--shipping` rejects it.

## ID registry

`discovery-id-registry.json` records the lifecycle of stable discovery IDs.

Example:

```json
{
  "some-discovery-id": {
    "state": "active"
  },
  "old-discovery-id": {
    "state": "retired",
    "notes": "Removed after venue change."
  }
}
```

Allowed states:

- `development` — intentional fixture/non-shipping content
- `active` — current real content
- `retired` — ID must not be reused

Do not delete retired IDs. Keeping them in the registry protects saved progress and future sync from accidental ID reuse.

## Validation rules

`scripts/validate-content-admin.py` validates the admin source before generation.

It catches, among other things:

- malformed filenames and duplicate editorial-order prefixes,
- missing/unknown fields,
- empty required values,
- invalid/non-kebab-case IDs,
- duplicate land, area, discovery, hint, and tag IDs,
- ID-registry mismatches and retired-ID reuse,
- invalid category/difficulty/verification values,
- invalid land/area references,
- discovery park/land mismatches,
- bad latitude/longitude/radius values,
- missing hint stages,
- duplicate/non-contiguous hint orders,
- fewer than two normal clues,
- missing/multiple detailed hints,
- detailed hint not being last,
- empty reveal text,
- bad ISO 8601 verification dates,
- verified discoveries missing `lastVerifiedAt`,
- missing/unsupported packaged images,
- placeholder/TODO/prototype text,
- development-only content leaking into shipping mode.

The validator also has mutation self-tests:

```bash
python3 scripts/validate-content-admin.py --self-test
```

## Development-only metadata

Administrative fields begin with an underscore and are removed when the runtime catalog is generated.

The current supported metadata is:

```json
"_editorial": {
  "developmentOnly": true,
  "notes": "Why this temporary content exists."
}
```

Development-only content must have a matching `development` registry state. It can produce warnings in normal validation but is always an error in `--shipping` mode.

## Runtime discovery fields

Required:

- `id`
- `title`
- `parkID`
- `landID`
- `category`
- `difficulty`
- `hints`
- `revealDescription`
- `verificationStatus`
- `isIndoor`
- `tags`

Optional:

- `areaID`
- `location`
- `thumbnailImageName`
- `revealImageName`
- `lastVerifiedAt`

Categories:

- `hiddenMickey`
- `hiddenCharacter`
- `imagineeringDetail`
- `movieReference`
- `historicalDetail`
- `easterEgg`
- `secretFeature`

Difficulty:

- `easy`
- `medium`
- `hard`
- `expert`

Verification status:

- `verified`
- `needsRecheck`
- `unverified`
- `temporarilyUnavailable`
- `removed`

## Hint convention

Each hunt currently requires:

- at least two `clue` hints,
- exactly one `detailed` hint,
- contiguous orders beginning at 1,
- the detailed hint last.

Hint IDs should be stable and begin with the discovery ID.

## Location

Location is optional. When present:

```json
"location": {
  "latitude": 33.8119,
  "longitude": -117.9190,
  "radiusMeters": 100
}
```

The validator accepts latitude -90…90, longitude -180…180, and a positive radius up to 5000 meters.

Coordinates are approximate content metadata for Nearby ranking, not proof that a guest found a detail.

## Images

Image fields are optional and filename-only:

```json
"thumbnailImageName": "pirates-secret-001-thumb.jpg",
"revealImageName": "pirates-secret-001-reveal.jpg"
```

Referenced files must exist under `ParkHunt/Resources/Images/` and use JPG/JPEG/HEIC/PNG. The separate image-assets CI gate continues to enforce packaged file-size limits.

## Dates

`lastVerifiedAt` uses timezone-aware ISO 8601:

```json
"lastVerifiedAt": "2026-09-23T00:00:00Z"
```

Any discovery marked `verified` must include it.

## Generated runtime file

`scripts/build-content-catalog.py` strips admin-only underscore fields, combines the source files deterministically, and writes:

```text
ParkHunt/Resources/content-catalog.json
```

Editing rule:

**Edit `ContentAdmin/` → validate → generate the runtime catalog.**
