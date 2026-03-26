# iOS Debugging — Quick Classification Checklist

Use this checklist to quickly classify the type of failure before diving in.

## Is it a crash?
- [ ] Crash log available (`.ips` file or Xcode Organizer)?
- [ ] Exception type: `EXC_BAD_ACCESS` / `EXC_BREAKPOINT` / `SIGABRT`?
- [ ] Crash reproducible on device vs simulator only?

## Is it a UI/layout issue?
- [ ] Views missing, overlapping, or wrong size?
- [ ] Console shows `Unable to simultaneously satisfy constraints`?
- [ ] Problem only on certain screen sizes or Dynamic Type settings?
- [ ] Dark Mode or trait collection related?

## Is it a networking issue?
- [ ] `URLError` in logs?
- [ ] HTTP status code unexpected (401, 403, 500)?
- [ ] Works in simulator but not on device (ATS / certificate issue)?

## Is it a memory issue?
- [ ] App grows in memory over time without releasing?
- [ ] Crash log shows `jettisoned` or `OOM`?
- [ ] Leaks Instrument shows retained objects?

## Is it a build / configuration issue?
- [ ] Build fails with red errors in Xcode?
- [ ] Archive works but debug does not (or vice versa)?
- [ ] Missing entitlements or provisioning issues?
