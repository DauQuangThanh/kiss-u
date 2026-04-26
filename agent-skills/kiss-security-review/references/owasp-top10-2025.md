# OWASP Top 10:2025 — review checklist

For each category, the skill asks: does the feature have anything
that pattern-matches this? If yes, add a finding with `file:line`.

| # | Category | Smell patterns | Remediation pointers |
|---|---|---|---|
| A01 | Broken access control | Missing authZ on endpoints; trust boundaries crossed via user-supplied id; IDOR | Per-request authZ; deny by default; server-side checks only |
| A02 | Cryptographic failures | Weak cipher / MD5 / SHA-1; secrets in source; plaintext sensitive data; self-rolled crypto | Use current standards (AES-256 GCM, Argon2id); managed secrets |
| A03 | Injection | String-concatenated SQL / LDAP / command / template; unsanitised input | Parameterised queries; safe-rendering templates; allow-lists |
| A04 | Insecure design | No rate limit; business-logic flaws; untrustworthy design assumptions | Threat model before design lands (STRIDE); deny-by-default |
| A05 | Security misconfiguration | Default creds; open ports; verbose errors; cloud over-permissioned IAM | Hardened baselines; least privilege; automated config scanning |
| A06 | Vulnerable / outdated components | Old lib versions; unpatched CVEs; unused deps | Continuous dependency audit (`kiss-dependency-audit`) |
| A07 | Identification / authN failures | Weak passwords allowed; missing MFA; session fixation | OIDC + MFA; rotate session on privilege change; short-lived tokens |
| A08 | Software & data integrity failures | Unsigned updates; CI/CD without attestations; deserialising untrusted data | Supply-chain attestations; signed artefacts; avoid `pickle`/`eval` |
| A09 | Logging / monitoring failures | No audit trail; sensitive fields logged in plain; no alerts on auth events | Structured logs + retention; alert on failed auth + priv escalation |
| A10 | Server-side request forgery | User-supplied URL fetched server-side without allow-list | Allow-list of hostnames; block internal IP ranges; metadata protection |

## AI-authoring note

- Cite **every** finding to a specific file/line; category-only
  entries without code location are discarded.
- Severity = likelihood × impact. Use the project-plan / intake to
  calibrate impact (customer data, money movement, PII = High+).
- For A06, delegate detail to `kiss-dependency-audit`.
