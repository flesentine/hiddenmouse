# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#29 Core experience + content admin

Park Hunt now supports the full local hunt loop, offline image packaging, progress, accessibility, one-handed controls, haptics, restoration, recovery, local analytics/privacy controls, and JSON-based content administration.

### #30 Content validation tools

Content changes now go through an editorial validator before the generated catalog or Xcode build is accepted.

`scripts/validate-content-admin.py` checks:

- discovery filename/order format,
- required and unknown fields,
- stable kebab-case IDs,
- duplicate land/area/discovery/hint/tag IDs,
- discovery ID registry lifecycle,
- retired-ID reuse,
- category/difficulty/status enum values,
- park/land/area relationships,
- location coordinate/radius bounds,
- two normal clues + one final detailed hint,
- unique contiguous hint order,
- non-empty clue/reveal content,
- ISO 8601 verification dates,
- `lastVerifiedAt` for verified content,
- image filename/type/existence,
- placeholder/TODO/prototype text.

The validator has its own mutation self-tests and runs in CI before catalog synchronization.

The new `ContentAdmin/discovery-id-registry.json` gives IDs a lifecycle:

- `development`
- `active`
- `retired`

Retired IDs remain reserved and cannot be reused.

The intentional prototype fixture is explicitly marked:

```json
"_editorial": {
  "developmentOnly": true,
  "notes": "..."
}
```

Admin-only underscore fields are stripped from the generated app catalog.

Normal development validation permits that explicit fixture with warnings. Field-test/release validation is stricter:

```bash
python3 scripts/validate-content-admin.py --shipping
```

Shipping mode rejects development-only content, placeholder text, and discoveries still marked `unverified` or `needsRecheck`.

## Verification

CI now runs:

```text
Self-test content validator
→ Validate content admin
→ Verify content admin catalog
→ Verify offline core
→ Verify image assets
→ Verify privacy boundaries
→ Generate Xcode project
→ Build for iOS Simulator
```

## Next effort

**#31 Prototype content population:** replace the development fixture with the first 15–20 original, validated Disneyland discoveries for the field-test area.
