# RAG status — how to judge consistently

## What RAG means

| Band | Meaning |
|---|---|
| 🟢 **Green** | On track. Trivial variance. No intervention needed. |
| 🟡 **Amber** | At risk. Material variance or concerning trend; intervention planned or in progress. |
| 🔴 **Red** | Off track. Plan will not deliver as committed without external action. |

## Judgement rules — pick the most severe band that triggers

**Go Red if any of:**

- A milestone has slipped past its target date without a new agreed
  date.
- An open Red risk (score ≥15) has materialised.
- Budget variance exceeds ±20%.
- A dependency (vendor, approval, data) is late and has no ETA.

**Go Amber if any of (and no Red triggers):**

- A milestone is forecast to slip by > 1 week.
- An open Amber risk (score 8–14) has a mitigation in progress.
- Budget variance is ±10–20%.
- Team health signal degraded (velocity drop, burnout, attrition).

**Green** when none of the above.

## Anti-patterns (avoid)

- **"Watermelon"** — green outside, red inside. Sponsors hate
  being surprised. If Amber is honest, report Amber.
- **"Tomato"** — red outside, green inside. Over-signalling
  fatigues the audience. Downgrade to Amber if a mitigation is in
  place and working.
- **Band thrashing** — band changes every report. Usually means
  the criteria are being applied inconsistently; pick clear
  thresholds and stick to them.

## AI-authoring note

The skill **proposes** a RAG band based on what the extracts and
user inputs say. The proposal is always labelled "(AI proposal —
confirm with user)". The user owns the final band.
