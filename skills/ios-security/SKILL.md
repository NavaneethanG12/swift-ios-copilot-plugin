---
name: ios-security
description: >
  Security best practices — Keychain, SSL pinning, encryption, biometrics,
  ATS, OWASP Mobile Top 10, jailbreak detection, privacy manifest.
argument-hint: "[security concern, vulnerability, or auth question]"
user-invocable: true
---

# iOS Security

## OWASP Mobile Top 10

| # | Risk | iOS Mitigation |
|---|---|---|
| M1 | Credential storage | Keychain + `AfterFirstUnlockThisDeviceOnly` |
| M2 | Supply chain | Pin SPM versions, audit deps |
| M3 | Auth/authorization | Biometrics + Keychain, server validation |
| M4 | Input validation | Validate external input, Codable |
| M5 | Communication | HTTPS-only (ATS), cert pinning |
| M6 | Privacy | ATT, minimal data, privacy manifest |
| M7 | Binary protection | Strip symbols, no debug in release |
| M8 | Misconfiguration | Audit entitlements, no debug logs |
| M9 | Data storage | Keychain for secrets, encrypt files |
| M10 | Cryptography | CryptoKit only, no custom crypto |

---

## Storage Rules

| Data | Use | Never |
|---|---|---|
| Passwords/tokens | Keychain | UserDefaults |
| API keys | Keychain / build config | Hard-coded |
| User prefs | UserDefaults | — |
| Sensitive docs | CryptoKit encrypted file | Plain text |

---

## Key Patterns

- **Keychain access**: `SecItemAdd` with `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` + `SecAccessControlCreateWithFlags(.biometryCurrentSet)` for biometric protection.
- **Biometrics**: `LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)`. Always provide passcode fallback.
- **SSL pinning**: Custom `URLSessionDelegate` → compare server cert hash → cancel on mismatch.
- **Encryption**: `AES.GCM.seal(data, using: key)` (CryptoKit). Store key in Keychain.
- **ATS**: Never `NSAllowsArbitraryLoads` in production. TLS 1.2+ required.

---

## Checklist

- [ ] No sensitive data in UserDefaults or logs
- [ ] No hard-coded credentials
- [ ] Keychain uses `ThisDeviceOnly`
- [ ] All traffic HTTPS, cert pinning for sensitive APIs
- [ ] Biometric auth with passcode fallback
- [ ] Tokens in `Authorization` header, not URL params
- [ ] Debug symbols stripped in release
- [ ] `#if DEBUG` guards on dev-only code
- [ ] `PrivacyInfo.xcprivacy` present
- [ ] ATT prompt before tracking
