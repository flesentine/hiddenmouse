# Park Hunt Content Admin

This directory is the **authoring source of truth** for Park Hunt content.

Do not hand-edit `ParkHunt/Resources/content-catalog.json`. That file is generated from this directory and bundled into the iOS app.

## Layout

```text
ContentAdmin/
├── lands.json
├── areas.json
├── discoveries/
│   └── 010-prototype-secret-001.json
└── templates/
    └── discovery.template.json
```

### `lands.json`

A JSON array of land records.

Required fields:

- `id` — stable lowercase/kebab-case identifier
- `parkID` — stable park identifier
- `name` — guest-facing name
- `sortOrder` — display order

### `areas.json`

A JSON array of attraction/area records.

Required fields:

- `id`
- `landID`
- `name`
- `kind`
- `sortOrder`

### `discoveries/*.json`

Each discovery lives in its **own JSON file**. This is the normal place editors add and maintain content.

Discovery filenames begin with a numeric editorial-order prefix:

```text
010-pirates-detail.json
020-pirates-reference.json
030-haunted-detail.json
```

The number controls the generated catalog order. The filename is administrative only; the stable in-app identity comes from the record's `id`.

Use gaps such as 010, 020, 030 so another discovery can be inserted later without renaming the whole folder.

## Add a discovery

1. Copy `templates/discovery.template.json` into `discoveries/`.
2. Name it with an editorial-order prefix and descriptive slug.
3. Give the discovery a stable `id`. Do not change that ID after release.
4. Set its park, land, optional area, category, difficulty, hints, reveal, verification state, tags, and optional location/images.
5. If it uses photos, generate the packaged variants with:

```bash
./scripts/prepare-discovery-image.sh ~/Desktop/source.jpg <discovery-id>
```

6. Rebuild the runtime catalog:

```bash
python3 scripts/build-content-catalog.py
```

7. Inspect the generated diff in `ParkHunt/Resources/content-catalog.json`.

CI runs the generator in `--check` mode, so it will fail if the bundled catalog is stale or was edited by hand.

## Discovery fields

Required runtime fields:

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

Optional runtime fields:

- `areaID`
- `location`
- `thumbnailImageName`
- `revealImageName`
- `lastVerifiedAt`

### Categories

Use one of:

- `hiddenMickey`
- `hiddenCharacter`
- `imagineeringDetail`
- `movieReference`
- `historicalDetail`
- `easterEgg`
- `secretFeature`

### Difficulty

Use one of:

- `easy`
- `medium`
- `hard`
- `expert`

### Verification status

Use one of:

- `verified`
- `needsRecheck`
- `unverified`
- `temporarilyUnavailable`
- `removed`

### Hints

Hints use stable IDs, numeric `order`, text, and a `kind`.

Normal progressive clues use:

```json
"kind": "clue"
```

The stronger final help stage uses:

```json
"kind": "detailed"
```

The prototype convention is two normal clues followed by one detailed hint.

## Location

Location is optional. When present:

```json
"location": {
  "latitude": 33.8119,
  "longitude": -117.9190,
  "radiusMeters": 100
}
```

Coordinates are content metadata for approximate Nearby ranking. They are not proof that a guest found an indoor detail.

## Images

Image references are optional. Use filenames only:

```json
"thumbnailImageName": "pirates-secret-001-thumb.jpg",
"revealImageName": "pirates-secret-001-reveal.jpg"
```

The files themselves belong in `ParkHunt/Resources/Images/`.

## Dates

`lastVerifiedAt` is optional and uses ISO 8601:

```json
"lastVerifiedAt": "2026-09-23T00:00:00Z"
```

## Generated file

Run:

```bash
python3 scripts/build-content-catalog.py
```

The generator:

- reads `lands.json`,
- reads `areas.json`,
- loads discovery files in filename order,
- builds schema version 1,
- writes deterministic pretty JSON to the bundled runtime path.

Check-only mode:

```bash
python3 scripts/build-content-catalog.py --check
```

This does not rewrite anything. It exits nonzero if the runtime catalog differs from the admin source.

## Editing rule

**Edit `ContentAdmin/`; generate `ParkHunt/Resources/content-catalog.json`.**

That separation keeps content work independent from Swift implementation and gives code review a clear source file for every discovery.
