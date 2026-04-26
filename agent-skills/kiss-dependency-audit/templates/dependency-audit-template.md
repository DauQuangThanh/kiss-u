# Dependency Audit: {feature}

**Date:** {date}
**Lockfile:** {lockfile}
**Licence policy:** {licence_policy}

## Summary

- **Direct deps:** <count>
- **Transitive deps:** <count>
- **CVEs open — Critical:** <count>
- **CVEs open — High:** <count>
- **Licence conflicts:** <count>
- **Abandonware candidates:** <count>

## CVEs

| Dep | Version | CVE | Severity | Fixed in | Upgrade path |
|---|---|---|---|---|---|
| `pkg-a` | 1.2.3 | CVE-2026-XXXXX | High | 1.2.5 | patch bump |

## Licence conflicts

| Dep | Version | Licence | Action |
|---|---|---|---|
| `gpl-pkg` | 1.0.0 | GPL-3.0 | replace / negotiate exception |

## Abandonware candidates

| Dep | Last release | Notes |
|---|---|---|
| `old-pkg` | 2023-01-15 | no activity in > 2 years — consider fork |

## Sources

- Vendor advisories / GitHub Security Advisories — fetched
  YYYY-MM-DD.
- OSV database — fetched YYYY-MM-DD.

## Debt

All open High / Critical CVEs and licence conflicts are duplicated
as `CSDEBT-NN` entries in `security-debts.md`.
