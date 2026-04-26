# STRIDE threat modelling — quick guide

STRIDE = Spoofing / Tampering / Repudiation / Information
disclosure / Denial of service / Elevation of privilege.

For each trust boundary on the C4 container diagram, ask one
question per letter.

| Letter | Question |
|---|---|
| **S**poofing | Can an attacker impersonate a legitimate actor? |
| **T**ampering | Can an attacker modify data in transit or at rest? |
| **R**epudiation | Can an actor deny an action they performed? |
| **I**nformation disclosure | Can an attacker see data they shouldn't? |
| **D**enial of service | Can an attacker make the service unavailable? |
| **E**levation of privilege | Can an attacker gain more rights than granted? |

## Scoping

Apply STRIDE to every edge in the C4 container diagram. If an
edge crosses a trust boundary (user → system, system → IdP, etc.),
it deserves at least two STRIDE questions.

## AI-authoring note

STRIDE is a *generative* tool — you surface candidate threats and
the user / security team decides which warrant findings. Do not
claim "no STRIDE threats" without listing the questions you
considered.
