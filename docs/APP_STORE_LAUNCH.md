# App Store launch

Effort #55 separates repository readiness from authenticated App Store Connect submission.

## Repository gate

Run:

```bash
python3 scripts/verify-app-store-launch.py
```

This is the CI-safe structural gate. It verifies the production bundle identity, App Store listing source, privacy claims, Apple privacy manifest, app-local UserDefaults required-reason declaration, version metadata, and App Store icon.

The app includes `ParkHunt/PrivacyInfo.xcprivacy` with tracking disabled, no off-device collected-data declarations, and `NSPrivacyAccessedAPICategoryUserDefaults` reason `CA92.1` for app-local preferences/progress.

## Strict submission gate

Before submitting a real build, run:

```bash
python3 scripts/verify-app-store-launch.py --strict
```

Strict mode additionally fails until all external/submission dependencies in `AppStore/launch-config.json` are completed and production content passes:

```bash
python3 scripts/validate-content-admin.py --shipping
```

The current field-test catalog intentionally contains `needsRecheck` discoveries, so strict launch readiness should remain blocked until those discoveries are physically verified or removed from the shipping catalog.

## External items that cannot be completed from this repository

Complete these with the actual Apple Developer/App Store Connect account and public web presence:

- register `com.flesentine.parkhunt` in the Apple Developer account,
- create the matching App Store Connect app record,
- provide a real Support URL,
- provide a real Privacy Policy URL,
- accept current Apple agreements,
- prepare required App Store screenshots,
- complete the age-rating questionnaire,
- complete export-compliance answers,
- configure App Review contact/details,
- configure pricing and availability,
- configure the production App Clip experience and associated invocation domain.

After each item is genuinely complete, update only the corresponding field in `AppStore/launch-config.json`.

Do not mark a field complete just to make the verifier pass.

## Public version

`Config/Version.xcconfig` remains the source of truth. The repository currently stays on a pre-release version while field verification is unfinished.

When strict launch blockers are cleared:

1. set `MARKETING_VERSION` to the intended public release (for example `1.0.0`),
2. increment `CURRENT_PROJECT_VERSION`,
3. rerun the strict verifier,
4. build a signed Release archive:

```bash
TEAM_ID=ABCDE12345 BUILD_NUMBER=<next> ./scripts/build-testflight-archive.sh signed
```

5. validate/export/upload with the authorized Apple account.

## Listing source of truth

`AppStore/launch-config.json` contains the current proposed:

- app name,
- bundle identifier,
- categories,
- subtitle,
- keywords,
- promotional text,
- description,
- privacy assertions,
- external submission dependencies.

Keep the in-app Privacy & Legal copy and App Store privacy answers consistent with actual implementation.
