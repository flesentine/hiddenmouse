# Battery testing

Park Hunt's battery strategy is deliberately simple for the prototype: location is an optional, foreground-only convenience for Nearby, not a tracking subsystem.

## Automated acceptance criteria

Every CI run must prove that the codebase still follows these constraints:

1. Nearby uses a one-shot Core Location request.
2. Requested accuracy stays at the hundred-meter level.
3. A second request is not started while the first request is still locating.
4. A user can explicitly retry after a terminal result.
5. Location work is discarded when Nearby disappears or the scene becomes inactive/backgrounded.
6. The app does not request Always authorization.
7. The app does not enable background location updates.
8. The app does not start continuous, visit, or significant-change location monitoring.
9. The app does not opt into best, navigation, or nearest-ten-meter accuracy.

The source-level gate lives in `scripts/verify-battery-boundaries.py`. Request-policy behavior is covered by `ParkHuntTests/LocationServiceTests.swift`.

## Real-device field check

Simulator runs are useful for behavior and lifecycle regressions but are not a trustworthy measure of battery percentage, thermal load, or radio/GPS power draw.

On the later TestFlight field build, use a real iPhone for a park-length session and confirm:

- Nearby gets a fix and then the location indicator stops.
- Leaving Nearby or backgrounding the app ends location activity.
- Reopening ordinary hunt screens does not wake GPS.
- Repeated manual browsing does not request location.
- The device does not show abnormal heat during normal hunt/reveal/collection use.
- Battery Settings and/or Xcode Energy diagnostics do not show sustained background location activity.

Any failure of those field checks should reopen #35 before App Store release.
