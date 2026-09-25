# TestFlight setup

Park Hunt has a reproducible Release archive path for TestFlight. Repository CI proves that the Release/device build can archive without needing Apple credentials; an actual upload still requires the Apple Developer team and App Store Connect access owned by the developer account.

## Versioning

Version metadata lives in `Config/Version.xcconfig`:

- `MARKETING_VERSION` is the user-visible version.
- `CURRENT_PROJECT_VERSION` is the build number and must increase for every App Store Connect upload.

For field builds, keep the marketing version stable unless the product version is intentionally changing and increment only the build number.

## CI readiness path

Every normal CI run now:

1. verifies TestFlight/release metadata,
2. builds/tests the app as before,
3. creates an **unsigned Release archive for a generic iOS device**.

That archive step proves the Release configuration compiles for device architecture and produces an `.xcarchive`. It intentionally disables signing because repository CI does not contain Apple certificates or App Store Connect credentials.

## Signed local archive

On a Mac signed into the correct Apple Developer account:

```bash
TEAM_ID=ABCDE12345 BUILD_NUMBER=2 ./scripts/build-testflight-archive.sh signed
```

The script regenerates the Xcode project, archives the Release configuration for a generic iOS device, uses automatic signing with the supplied team, exports using `Config/ExportOptions-TestFlight.plist`, and preserves repository-controlled version/build metadata.

The exported build lands under `Build/TestFlight/export` by default.

## Upload boundary

The repository does **not** contain Apple credentials. Uploading to App Store Connect therefore remains an authenticated developer action. The archive/export plumbing is ready, but a real TestFlight upload must use an authorized Apple Developer/App Store Connect session, for example through Xcode Organizer.

Before the first upload, also confirm:

- the bundle identifier `com.flesentine.parkhunt` exists in the Apple Developer account,
- the App Store Connect app record uses that bundle identifier,
- the Apple team has accepted current agreements,
- an AppIcon is present before production validation if Apple requires it,
- the field-test content status is appropriate for the build being distributed.

## Release metadata policy

Do not let App Store Connect silently renumber builds. `manageAppVersionAndBuildNumber` is disabled in the export options so the repository remains the source of truth.

Release builds also keep dSYMs enabled for crash symbolication and run Xcode product validation.
