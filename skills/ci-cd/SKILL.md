---
name: ci-cd
description: >
  Set up CI/CD for iOS/macOS — Xcode Cloud, GitHub Actions, Fastlane,
  automated testing, code signing, TestFlight deployment.
argument-hint: "[CI platform, build issue, or deployment question]"
user-invocable: true
---

# CI/CD — iOS / macOS

## Platform Comparison

| Platform | Best for | Signing | Free tier |
|---|---|---|---|
| Xcode Cloud | Apple-integrated | Automatic | 25 hrs/mo |
| GitHub Actions | Flexible, GitHub-native | Manual (match/Fastlane) | 2000 min/mo |
| Fastlane | Automation layer (any CI) | `match` | OSS |

---

## Xcode Cloud

Configure in Xcode (Product → Xcode Cloud):
- **Triggers**: push to `main`, PR, tag
- **Actions**: Build, Test, Analyze, Archive
- **Post-actions**: Deploy to TestFlight

Custom scripts in `ci_scripts/`: `ci_post_clone.sh` (install tools), `ci_pre_xcodebuild.sh` (lint).

---

## GitHub Actions

```yaml
# .github/workflows/ios.yml — key structure
on: [push, pull_request] # branches: [main]
jobs:
  build-and-test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - run: sudo xcode-select -s /Applications/Xcode_16.app
      - uses: actions/cache@v4  # cache SPM
        with: { path: "~/Library/Developer/Xcode/DerivedData/*/SourcePackages", key: "spm-${{ hashFiles('**/Package.resolved') }}" }
      - run: xcodebuild build-for-testing -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
      - run: xcodebuild test-without-building -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

---

## Fastlane

```ruby
platform :ios do
  lane :test do
    scan(scheme: "MyApp", device: "iPhone 16", code_coverage: true)
  end
  lane :beta do
    match(type: "appstore", readonly: true)
    increment_build_number(build_number: latest_testflight_build_number + 1)
    build_app(scheme: "MyApp", export_method: "app-store")
    upload_to_testflight(skip_waiting_for_build_processing: true)
  end
end
```

Code signing: `fastlane match init` → `match appstore` / `match development`. Certs in private git repo.

---

## Checklist

- [ ] CI runs on every PR and push to main
- [ ] Tests with coverage reporting
- [ ] Signing via `match` or API key
- [ ] SPM packages cached
- [ ] TestFlight deployment automated from main
- [ ] Build number auto-incremented
- [ ] Secrets in CI secrets, not repo
