# Quality attributes — vocabulary

Use these canonical names when ranking. Spell out acronyms on first
use in the intake document.

| Name | One-line definition |
|---|---|
| **Performance** | Speed of a single request (latency) + throughput (QPS) |
| **Scalability** | Ability to handle more load without linear cost growth |
| **Availability** | Uptime; % of requests that succeed (see SLA target) |
| **Reliability** | Mean time between failures; graceful degradation |
| **Security** | Confidentiality, integrity, authN/authZ, compliance |
| **Maintainability** | Ease of change; onboarding cost; test coverage |
| **Portability** | Moving between clouds / runtimes without rewrite |
| **Observability** | Ability to answer "what's happening now / what went wrong" |
| **Cost efficiency** | Cost per request / per user / per feature |
| **Time to market** | Speed of getting a first version in front of users |

Exactly **one** name per rank row. If a user names two things
together ("reliability + security"), ask them to pick which is
higher; two ranks at the same level produce fuzzy trade-off
decisions later.
