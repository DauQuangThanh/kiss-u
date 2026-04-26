# Security Review: {feature}

**Date:** {date}
**Scope:** {scope}
**Compliance regime:** {compliance}
**Threat model:** {threat_model}

## Summary

- **Critical findings:** <count>
- **High findings:** <count>
- **Medium findings:** <count>
- **Low findings:** <count>

## Findings

### CS-01: <short title>

- **Category:** <OWASP A01 / CWE-NNN>
- **Severity:** Critical / High / Medium / Low
- **File / line:** `path/to/file.ts:42`
- **Description:** <what's exposed + why>
- **Impact:** <what an attacker can do>
- **Remediation:** <outline; cite cheat-sheet / reference>

### CS-02: <next>

…

## Threat model (STRIDE)

| Threat | Finding? | Notes |
|---|---|---|
| **S**poofing identity | | |
| **T**ampering with data | | |
| **R**epudiation | | |
| **I**nformation disclosure | | |
| **D**enial of service | | |
| **E**levation of privilege | | |

## OWASP Top 10:2025 coverage

| Category | Reviewed? | Findings |
|---|:-:|---|
| A01 — Broken access control | | |
| A02 — Cryptographic failures | | |
| A03 — Injection | | |
| A04 — Insecure design | | |
| A05 — Security misconfiguration | | |
| A06 — Vulnerable components | | |
| A07 — Identification & authN failures | | |
| A08 — Software & data integrity failures | | |
| A09 — Logging & monitoring failures | | |
| A10 — Server-side request forgery | | |

## Compliance cross-check

{compliance_notes}

## Debt

All Critical / High findings are duplicated in `security-debts.md`
as `CSDEBT-NN` entries.
