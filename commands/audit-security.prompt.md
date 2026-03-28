---
description: "Audit the project for security vulnerabilities (OWASP Mobile Top 10)"
agent: security-auditor
---

Perform a security audit on this project.

Load the **ios-security** skill. Check against OWASP Mobile Top 10:
- M1: Improper credential storage (plaintext passwords, UserDefaults for secrets)
- M2: Insufficient transport security (missing ATS, no SSL pinning)
- M3: Insecure authentication / session management
- M4: Insufficient cryptography
- M5: Insecure data storage (sensitive data in logs, caches, pasteboard)
- M6: Insufficient privacy controls (missing Privacy Manifest entries)
- M7: Binary protections (jailbreak detection, debug detection)
- M8: Insecure data sharing between apps
- M9: Improper Keychain configuration
- M10: Biometric authentication bypass risks

Produce a **Security Findings Table** with:
- Severity (Critical / High / Medium / Low)
- OWASP category
- Affected file and line range
- Description
- Recommended fix

${input:scope:Scope — specific files/modules to audit, or "all" for full project}
