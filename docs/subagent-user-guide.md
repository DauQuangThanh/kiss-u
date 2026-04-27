# KISS Subagent User Guide

> This guide explains how all 14 KISS role agents interconnect, what commands
> they expose, what artefacts they consume and produce, and which order to run
> them for **greenfield** (new project) and **brownfield** (existing codebase)
> projects.

---

## Table of Contents

1. [Choosing Your Starting Point](#1-choosing-your-starting-point)
2. [Agent Ecosystem Overview](#2-agent-ecosystem-overview)
3. [Greenfield Workflow — Agile / Scrum](#3-greenfield-workflow--agile--scrum)
4. [Greenfield Workflow — Waterfall / Regulated](#4-greenfield-workflow--waterfall--regulated)
5. [Brownfield Workflow](#5-brownfield-workflow)
6. [Cross-Agent Data Flow](#6-cross-agent-data-flow)
7. [Agent Reference](#7-agent-reference)

---

## 1. Choosing Your Starting Point

```mermaid
flowchart TD
    START([Start here])
    Q1{New project or\nexisting codebase?}
    Q2{Delivery methodology?}
    Q3{Docs exist or\ncode only?}
    GF_A["Greenfield — Agile\n→ §3"]
    GF_W["Greenfield — Waterfall\n→ §4"]
    BF["Brownfield\n→ §5"]

    START --> Q1
    Q1 -->|New project| Q2
    Q1 -->|Existing codebase| Q3
    Q2 -->|Agile / Scrum| GF_A
    Q2 -->|Waterfall / Regulated| GF_W
    Q3 -->|Some docs exist| BF
    Q3 -->|Code only| BF
```

---

## 2. Agent Ecosystem Overview

The 14 role agents cluster into five functional zones.

```mermaid
flowchart LR
    subgraph REQ["Requirements & Product"]
        PO[product-owner]
        BA[business-analyst]
        UX[ux-designer]
    end

    subgraph ARCH_ZONE["Architecture & Design"]
        ARCH[architect]
        DEV[developer]
    end

    subgraph PLAN["Planning & Delivery"]
        PM[project-manager]
        SM[scrum-master]
        DO[devops]
    end

    subgraph QA["Quality & Testing"]
        TA[test-architect]
        TEST[tester]
        QR[code-quality-reviewer]
        SR[code-security-reviewer]
        BF[bug-fixer]
    end

    subgraph ANALYSIS["Analysis — Brownfield"]
        TAN[technical-analyst]
    end

    REQ --> ARCH_ZONE
    REQ --> PLAN
    ARCH_ZONE --> QA
    ARCH_ZONE --> PLAN
    QA --> PLAN
    ANALYSIS --> ARCH_ZONE
    ANALYSIS --> QA
```

### Agent summary

| Agent | Zone | Primary commands |
|-------|------|-----------------|
| `business-analyst` | Requirements | `/kiss-specify` `/kiss-clarify-specs` `/kiss-srs` `/kiss-uat-plan` `/kiss-data-migration-plan` |
| `product-owner` | Requirements | `/kiss-backlog` `/kiss-acceptance-criteria` `/kiss-roadmap` `/kiss-tasks-to-issues` |
| `ux-designer` | Requirements | `/kiss-wireframes` |
| `architect` | Architecture | `/kiss-arch-intake` `/kiss-tech-research` `/kiss-adr-author` `/kiss-c4-diagrams` |
| `developer` | Design & Build | `/kiss-dev-design` `/kiss-plan` `/kiss-implement` `/kiss-unit-tests` |
| `project-manager` | Planning | `/kiss-project-planning` `/kiss-wbs-decompose` `/kiss-phase-gate` `/kiss-baseline` `/kiss-risk-register` `/kiss-status-report` `/kiss-change-control` |
| `scrum-master` | Planning | `/kiss-sprint-planning` `/kiss-standup` `/kiss-retrospective` |
| `devops` | Delivery | `/kiss-cicd-pipeline` `/kiss-infrastructure-plan` `/kiss-containerization` `/kiss-observability-plan` `/kiss-deployment-strategy` `/kiss-handover` `/kiss-data-migration-plan` |
| `test-architect` | Quality | `/kiss-test-strategy` `/kiss-test-framework` `/kiss-quality-gates` `/kiss-traceability-matrix` |
| `tester` | Quality | `/kiss-test-cases` `/kiss-test-execution` `/kiss-bug-report` `/kiss-regression-tests` |
| `code-quality-reviewer` | Quality | `/kiss-quality-review` |
| `code-security-reviewer` | Quality | `/kiss-security-review` `/kiss-dependency-audit` |
| `bug-fixer` | Quality | `/kiss-bug-triage` `/kiss-implement` `/kiss-regression-tests` `/kiss-change-log` |
| `technical-analyst` | Analysis | `/kiss-codebase-scan` `/kiss-arch-extraction` `/kiss-api-docs` `/kiss-dependency-map` |

---

## 3. Greenfield Workflow — Agile / Scrum

```mermaid
flowchart TD
    START([New project])

    subgraph P1["Phase 1 — Discovery & Requirements"]
        PO["**product-owner**\n/kiss-backlog\n/kiss-acceptance-criteria\n/kiss-roadmap"]
        BA["**business-analyst**\n/kiss-specify\n/kiss-clarify-specs"]
        UX["**ux-designer**\n/kiss-wireframes"]
    end

    subgraph P2["Phase 2 — Architecture"]
        ARCH["**architect**\n/kiss-arch-intake\n/kiss-tech-research\n/kiss-adr-author\n/kiss-c4-diagrams"]
    end

    subgraph P3["Phase 3 — Sprint Setup"]
        SM["**scrum-master**\n/kiss-sprint-planning"]
        TA["**test-architect**\n/kiss-test-strategy\n/kiss-test-framework\n/kiss-quality-gates"]
    end

    subgraph P4["Phase 4 — Build & Test  ↺ repeat per sprint"]
        DEV["**developer**\n/kiss-dev-design\n/kiss-plan\n/kiss-implement\n/kiss-unit-tests"]
        TEST["**tester**\n/kiss-test-cases\n/kiss-test-execution\n/kiss-bug-report"]
        QR["**code-quality-reviewer**\n/kiss-quality-review"]
        SR["**code-security-reviewer**\n/kiss-security-review"]
        BF["**bug-fixer**\n/kiss-bug-triage\n/kiss-implement"]
    end

    subgraph P5["Phase 5 — Delivery"]
        DO["**devops**\n/kiss-cicd-pipeline\n/kiss-deployment-strategy\n/kiss-observability-plan"]
        PM["**project-manager**\n/kiss-risk-register\n/kiss-status-report\n/kiss-change-control"]
    end

    START --> PO
    PO -->|"backlog.md / roadmap.md"| BA
    BA -->|"spec.md"| ARCH
    BA -->|"spec.md"| UX
    PO -->|"backlog.md"| SM

    ARCH -->|"intake.md / ADRs / C4"| DEV
    ARCH -->|"intake.md"| TA

    SM -->|"sprint-NN-plan.md"| DEV
    TA -->|"strategy.md / quality-gates.md"| TEST

    DEV -->|"design.md / source"| TEST
    DEV -->|"design.md / source"| QR
    DEV -->|"source"| SR

    TEST -->|"BUG-NNN.md"| BF
    QR -->|"quality-debts.md"| BF
    SR -->|"security-debts.md"| BF
    BF -->|"change-register.md"| TEST

    TEST -->|"execution.md"| PM
    DO -->|"cicd.md / deployment.md"| PM

    P4 -->|"sprint complete → re-plan"| SM
    P1 --> P2
    P2 --> P3
    P3 --> P4
    P4 --> P5
```

### Agile artefact map

| Phase | Artefact | Produced by |
|-------|----------|-------------|
| Discovery | `docs/product/backlog.md` | product-owner |
| Discovery | `docs/product/roadmap.md` | product-owner |
| Discovery | `docs/specs/<feature>/spec.md` | business-analyst |
| Discovery | `docs/ux/<feature>/wireframes.md` | ux-designer |
| Architecture | `docs/architecture/intake.md` | architect |
| Architecture | `docs/decisions/ADR-NNN-*.md` | architect |
| Architecture | `docs/architecture/c4-context.md` | architect |
| Sprint Setup | `docs/agile/sprint-NN-plan.md` | scrum-master |
| Sprint Setup | `docs/testing/<feature>/strategy.md` | test-architect |
| Sprint Setup | `docs/testing/<feature>/quality-gates.md` | test-architect |
| Build | `docs/design/<feature>/design.md` | developer |
| Build | `docs/design/<feature>/api-contract.md` | developer |
| Build | `docs/testing/<feature>/test-cases.md` | tester |
| Build | `docs/testing/<feature>/execution.md` | tester |
| Build | `docs/bugs/BUG-NNN-*.md` | tester |
| Delivery | `docs/operations/cicd.md` | devops |
| Delivery | `docs/operations/deployment.md` | devops |

---

## 4. Greenfield Workflow — Waterfall / Regulated

The Waterfall variant adds formal **phase gates**, a consolidated **SRS**,
a **requirements traceability matrix (RTM)**, a **UAT plan** (owned by
`business-analyst`), and a go-live **handover package**. The `project-manager`
orchestrates all gates and baselines.

```mermaid
flowchart TD
    START([New project])

    subgraph SRR["Phase 1 — Requirements  ➜  SRR gate"]
        BA1["**business-analyst**\n/kiss-specify\n/kiss-srs\n/kiss-data-migration-plan"]
        PO1["**product-owner**\n/kiss-backlog\n/kiss-acceptance-criteria"]
        UX1["**ux-designer**\n/kiss-wireframes"]
        PM_SRR["**project-manager**\n/kiss-phase-gate  SRR\n/kiss-baseline  requirements"]
    end

    subgraph PDR["Phase 2 — System Design  ➜  PDR/CDR gates"]
        ARCH1["**architect**\n/kiss-arch-intake\n/kiss-tech-research\n/kiss-adr-author\n/kiss-c4-diagrams"]
        DEV1["**developer**\n/kiss-dev-design\n/kiss-plan"]
        TA1["**test-architect**\n/kiss-test-strategy\n/kiss-test-framework\n/kiss-traceability-matrix"]
        PM_PDR["**project-manager**\n/kiss-wbs-decompose\n/kiss-phase-gate  PDR\n/kiss-phase-gate  CDR\n/kiss-baseline  design"]
    end

    subgraph BUILD["Phase 3 — Build & Integration"]
        DEV2["**developer**\n/kiss-implement\n/kiss-unit-tests"]
        QR1["**code-quality-reviewer**\n/kiss-quality-review"]
        SR1["**code-security-reviewer**\n/kiss-security-review"]
        BF1["**bug-fixer**\n/kiss-bug-triage\n/kiss-implement"]
    end

    subgraph TEST_PHASE["Phase 4 — System Test & UAT  ➜  ORR gate"]
        TEST1["**tester**\n/kiss-test-cases\n/kiss-test-execution"]
        BA2["**business-analyst**\n/kiss-uat-plan"]
        PM_ORR["**project-manager**\n/kiss-phase-gate  ORR"]
    end

    subgraph DEPLOY["Phase 5 — Deployment & Handover  ➜  Go-live gate"]
        DO1["**devops**\n/kiss-cicd-pipeline\n/kiss-deployment-strategy\n/kiss-handover\n/kiss-data-migration-plan"]
        PM_GL["**project-manager**\n/kiss-phase-gate  go-live\n/kiss-status-report"]
    end

    START --> PO1
    PO1 -->|"backlog.md"| BA1
    BA1 -->|"spec.md / srs.md"| ARCH1
    BA1 -->|"spec.md"| UX1
    BA1 -->|"srs.md"| PM_SRR

    PM_SRR -->|"GATE-SRR.md / requirements baseline"| ARCH1

    ARCH1 -->|"intake.md / ADRs / C4"| DEV1
    ARCH1 -->|"intake.md"| TA1
    DEV1 -->|"design.md"| TA1
    TA1 -->|"traceability-matrix.md"| BA2
    PM_PDR -->|"GATE-PDR.md / design baseline"| DEV2

    DEV2 -->|"source / unit tests"| QR1
    DEV2 -->|"source"| SR1
    QR1 -->|"quality-debts.md"| BF1
    SR1 -->|"security-debts.md"| BF1
    BF1 -->|"change-register.md"| TEST1

    BA2 -->|"uat-plan.md"| TEST1
    TEST1 -->|"execution.md"| PM_ORR

    DO1 -->|"migration-runbook.md\nhandover-package.md"| PM_GL

    SRR -->|"SRR gate passed"| PDR
    PDR -->|"CDR gate passed"| BUILD
    BUILD -->|"code-complete"| TEST_PHASE
    TEST_PHASE -->|"ORR gate passed"| DEPLOY
```

### Additional Waterfall artefacts

| Phase | Artefact | Produced by |
|-------|----------|-------------|
| Requirements | `docs/analysis/srs.md` | business-analyst |
| Requirements | `docs/project/gates/GATE-SRR-*.md` | project-manager |
| Requirements | `docs/baselines/requirements/manifest.md` | project-manager |
| Design | `docs/project/wbs-index.md` | project-manager |
| Design | `docs/project/gates/GATE-PDR-*.md` | project-manager |
| Design | `docs/project/gates/GATE-CDR-*.md` | project-manager |
| Design | `docs/baselines/design/manifest.md` | project-manager |
| Design | `docs/analysis/traceability-matrix.md` | test-architect |
| Testing | `docs/analysis/uat-plan/<feature>/uat-plan.md` | business-analyst |
| Testing | `docs/analysis/uat-plan/<feature>/uat-sign-off.md` | business-analyst |
| Testing | `docs/project/gates/GATE-ORR-*.md` | project-manager |
| Delivery | `docs/operations/handover/handover-package.md` | devops |
| Delivery | `docs/operations/migration-runbook.md` | devops |
| Delivery | `docs/analysis/data-migration-plan.md` | business-analyst |
| Delivery | `docs/analysis/field-mapping.md` | business-analyst |

### Phase gate summary

| Gate | Trigger | Owner | Key inputs checked |
|------|---------|-------|--------------------|
| SRR — System Requirements Review | All feature specs approved | project-manager | `srs.md`, `spec.md` files |
| PDR — Preliminary Design Review | Architecture intake + ADRs + C4 approved | project-manager | `intake.md`, `ADR-*.md`, `c4-*.md` |
| CDR — Critical Design Review | Detailed design + RTM complete | project-manager | `design.md`, `traceability-matrix.md` |
| ORR — Operational Readiness Review | System test passed + UAT signed off | project-manager | `execution.md`, `uat-sign-off.md` |
| Go-live | Deployment plan + handover package ready | project-manager | `deployment.md`, `handover-package.md` |

---

## 5. Brownfield Workflow

Brownfield projects start with `technical-analyst` scanning the existing
codebase to produce a discovered baseline. The outputs seed the architect
and developer agents, bypassing the initial specification phase (though a
new-feature spec is still recommended for any change work).

```mermaid
flowchart TD
    START([Existing codebase])

    subgraph DISC["Phase 1 — Discovery  ★ Brownfield only"]
        TAN["**technical-analyst**\n/kiss-codebase-scan\n/kiss-arch-extraction\n/kiss-api-docs\n/kiss-dependency-map"]
    end

    subgraph BASE["Phase 2 — Architecture Baseline"]
        ARCH_BF["**architect**\n/kiss-arch-intake  from extraction\n/kiss-adr-author  gap ADRs\n/kiss-c4-diagrams  updated"]
        QR_BF["**code-quality-reviewer**\n/kiss-quality-review  existing code"]
        SR_BF["**code-security-reviewer**\n/kiss-security-review\n/kiss-dependency-audit"]
    end

    subgraph FEAT["Phase 3 — Feature Development  same as §3 / §4"]
        BA_BF["**business-analyst**\n/kiss-specify  new feature"]
        DEV_BF["**developer**\n/kiss-dev-design\n/kiss-plan\n/kiss-implement"]
        TEST_BF["**tester**\n/kiss-test-cases\n/kiss-test-execution"]
    end

    subgraph FIX["Phase 4 — Remediation"]
        BF_BF["**bug-fixer**\n/kiss-bug-triage\n/kiss-implement"]
        DO_BF["**devops**\n/kiss-cicd-pipeline  update\n/kiss-containerization"]
        PM_BF["**project-manager**\n/kiss-risk-register\n/kiss-status-report"]
    end

    START --> TAN

    TAN -->|"codebase-scan.md\nextracted.md"| ARCH_BF
    TAN -->|"api-docs.md\ndependencies.md"| DEV_BF
    TAN -->|"dependencies.md"| QR_BF
    TAN -->|"extracted.md\ndependencies.md"| SR_BF

    ARCH_BF -->|"intake.md  updated\ngap ADRs\nC4 diagrams"| DEV_BF
    ARCH_BF -->|"intake.md"| TEST_BF

    QR_BF -->|"quality-debts.md"| BF_BF
    SR_BF -->|"security-debts.md"| BF_BF

    BA_BF -->|"spec.md"| DEV_BF
    DEV_BF -->|"design.md / source"| TEST_BF

    BF_BF -->|"change-register.md"| PM_BF
    DO_BF -->|"cicd.md"| PM_BF

    DISC --> BASE
    BASE --> FEAT
    FEAT --> FIX
```

### Brownfield discovery artefacts

| Artefact | Path | Notes |
|----------|------|-------|
| Codebase scan | `docs/analysis/codebase-scan.md` | Language, LOC, entry points, tooling |
| Extracted architecture | `docs/architecture/extracted.md` | Containers + components reverse-engineered from source |
| Extracted API docs | `docs/analysis/api-docs.md` | Endpoint/schema inventory from existing routes |
| Dependency map | `docs/analysis/dependencies.md` + `module-graph.mmd` | Internal module graph + external package list |
| Gap ADRs | `docs/decisions/ADR-NNN-*.md` | Architect records undocumented decisions found in extraction |

### Brownfield vs. greenfield comparison

| Aspect | Greenfield | Brownfield |
|--------|-----------|------------|
| First agent | `product-owner` or `business-analyst` | `technical-analyst` |
| Architecture source | Freshly authored by `architect` | Extracted by `technical-analyst`, refined by `architect` |
| Spec requirement | Always needed | Needed for new features; existing behaviour inferred from scan |
| Dependency audit | Optional | Strongly recommended (run `code-security-reviewer` early) |
| Quality debts | Accumulate from new code | Existing debts surfaced immediately by `code-quality-reviewer` |

---

## 6. Cross-Agent Data Flow

The diagram below shows every significant artefact that crosses an agent
boundary. Agents are coloured by zone.

```mermaid
flowchart LR
    PO(product-owner):::req
    BA(business-analyst):::req
    UX(ux-designer):::req
    ARCH(architect):::arch
    DEV(developer):::arch
    PM(project-manager):::plan
    SM(scrum-master):::plan
    DO(devops):::plan
    TA(test-architect):::qa
    TEST(tester):::qa
    QR(code-quality-reviewer):::qa
    SR(code-security-reviewer):::qa
    BF(bug-fixer):::qa
    TAN(technical-analyst):::analysis

    PO -->|"backlog / roadmap"| BA
    PO -->|"backlog / acceptance"| SM
    PO -->|"acceptance"| TEST
    PO -->|"roadmap"| ARCH
    PO -->|"backlog"| PM

    BA -->|"spec.md"| ARCH
    BA -->|"spec.md"| DEV
    BA -->|"spec.md"| UX
    BA -->|"spec.md"| TA
    BA -->|"srs.md"| PM
    BA -->|"srs.md"| TA
    BA -->|"srs.md"| DO
    BA -->|"data-migration-plan\nfield-mapping"| DO
    BA -->|"uat-plan.md"| TEST

    ARCH -->|"intake / ADRs / C4"| DEV
    ARCH -->|"intake / C4"| TA
    ARCH -->|"intake / C4 / ADRs"| SR
    ARCH -->|"intake"| DO

    DEV -->|"design / API contract"| TEST
    DEV -->|"design"| TA
    DEV -->|"design / source"| QR
    DEV -->|"source"| SR
    DEV -->|"API contract"| TAN
    DEV -->|"design / data model"| DO

    TA -->|"strategy / framework / gates"| TEST
    TA -->|"traceability-matrix"| BA
    TA -->|"quality-gates"| DO

    TEST -->|"BUG-NNN.md"| BF
    TEST -->|"execution.md"| PM

    QR -->|"quality-debts"| BF
    SR -->|"security-debts"| BF
    SR -->|"security-debts"| PM

    BF -->|"change-register"| TEST
    BF -->|"change-register"| PM

    PM -->|"project-plan / risk-register"| ARCH
    PM -->|"project-plan"| SM
    SM -->|"sprint-plan"| DEV
    SM -->|"impediments"| PM

    TAN -->|"codebase-scan / extracted"| ARCH
    TAN -->|"api-docs / dependencies"| DEV
    TAN -->|"extracted / dependencies"| QR
    TAN -->|"extracted / dependencies"| SR

    DO -->|"cicd / deployment"| PM

    classDef req fill:#4a90d9,color:#fff,stroke:#2c5f8a
    classDef arch fill:#7b68ee,color:#fff,stroke:#5a4dbf
    classDef plan fill:#f5a623,color:#fff,stroke:#c47e0a
    classDef qa fill:#50c878,color:#fff,stroke:#2d8a4e
    classDef analysis fill:#e8735a,color:#fff,stroke:#b84a30
```

---

## 7. Agent Reference

### business-analyst

Drafts and refines feature specifications, SRS, UAT plans, and data
migration strategy.

**Commands**: `/kiss-specify` · `/kiss-clarify-specs` · `/kiss-srs` ·
`/kiss-uat-plan` · `/kiss-data-migration-plan`

**Reads from**: product-owner → `backlog.md` · architect → `architecture/**`
· test-architect → `traceability-matrix.md`

| Artefact | Path | When |
|----------|------|------|
| Feature spec | `docs/specs/<feature>/spec.md` | Always |
| Requirement debts | `docs/specs/requirement-debts.md` | Always |
| SRS | `docs/analysis/srs.md` | Waterfall / regulated |
| UAT plan | `docs/analysis/uat-plan/<feature>/uat-plan.md` | Waterfall / regulated |
| UAT sign-off | `docs/analysis/uat-plan/<feature>/uat-sign-off.md` | Waterfall / regulated |
| Data migration plan | `docs/analysis/data-migration-plan.md` | If legacy data migration needed |
| Field mapping | `docs/analysis/field-mapping.md` | If legacy data migration needed |

---

### product-owner

Maintains the ordered product backlog, acceptance criteria, and roadmap.
Converts approved items to GitHub issues.

**Commands**: `/kiss-backlog` · `/kiss-acceptance-criteria` · `/kiss-roadmap`
· `/kiss-tasks-to-issues`

**Reads from**: business-analyst → specs · architect → feasibility ·
project-manager → plan constraints

| Artefact | Path |
|----------|------|
| Product backlog | `docs/product/backlog.md` |
| Acceptance criteria | `docs/product/acceptance.md` |
| Roadmap | `docs/product/roadmap.md` |
| Product debts | `docs/product/product-debts.md` |

---

### ux-designer

Produces text-based wireframes and Mermaid user-flow diagrams.

**Commands**: `/kiss-wireframes`

**Reads from**: business-analyst → spec · product-owner → acceptance criteria

| Artefact | Path |
|----------|------|
| Wireframes | `docs/ux/<feature>/wireframes.md` |
| User flows | `docs/ux/<feature>/user-flows.md` |
| UX debts | `docs/ux/ux-debts.md` |

---

### architect

Captures quality-attribute intake, researches technology options, records
decisions as ADRs, and drafts C4 diagrams.

**Commands**: `/kiss-arch-intake` · `/kiss-tech-research` · `/kiss-adr-author`
· `/kiss-c4-diagrams` · `/kiss-clarify-specs` · `/kiss-plan` ·
`/kiss-standardize`

**Reads from**: business-analyst → spec · product-owner → backlog ·
project-manager → project plan

| Artefact | Path |
|----------|------|
| Architecture intake | `docs/architecture/intake.md` |
| C4 context diagram | `docs/architecture/c4-context.md` |
| C4 container diagram | `docs/architecture/c4-container.md` |
| C4 component diagram | `docs/architecture/c4-component.md` |
| ADRs | `docs/decisions/ADR-NNN-<slug>.md` |
| Technology research | `docs/research/<topic>.md` |
| Tech debts | `docs/architecture/tech-debts.md` |

---

### developer

Turns the architect's blueprint into a concrete module design, API contract,
and data model; scaffolds unit tests; drives implementation via the SDD
plan → taskify → implement chain.

**Commands**: `/kiss-dev-design` · `/kiss-plan` · `/kiss-implement` ·
`/kiss-unit-tests` · `/kiss-standardize`

**Reads from**: business-analyst → spec · architect → intake + ADRs ·
product-owner → acceptance criteria · project-manager → plan

| Artefact | Path |
|----------|------|
| Implementation plan | `docs/plans/<feature>/plan.md` |
| Detailed design | `docs/design/<feature>/design.md` |
| API contract | `docs/design/<feature>/api-contract.md` |
| Data model | `docs/design/<feature>/data-model.md` |
| Unit test index | `docs/testing/<feature>/unit-tests-index.md` |
| Source edits | project source tree |

> **Note:** The developer authors the authoritative API contract for new
> endpoints. The `technical-analyst` validates it matches the implementation
> on brownfield projects.

---

### project-manager

Drafts the project plan, WBS, risk register, phase gates, baselines, status
reports, and change log. Primarily used on Waterfall / regulated projects;
Agile projects use `scrum-master` for sprint cadence.

**Commands**: `/kiss-project-planning` · `/kiss-wbs-decompose` ·
`/kiss-phase-gate` · `/kiss-baseline` · `/kiss-risk-register` ·
`/kiss-status-report` · `/kiss-change-control` · `/kiss-taskify` ·
`/kiss-feature-checklist` · `/kiss-standardize`

**Reads from**: business-analyst → specs · architect → architecture ·
product-owner → product · tester/bug-fixer → bugs ·
code-security-reviewer → security debts

| Artefact | Path |
|----------|------|
| Project plan | `docs/project/project-plan.md` |
| Communication plan | `docs/project/communication-plan.md` |
| WBS index | `docs/project/wbs-index.md` |
| Risk register | `docs/project/risk-register.md` |
| Status report | `docs/project/status-YYYY-MM-DD.md` |
| Phase gate | `docs/project/gates/GATE-<type>-<date>.md` |
| Baseline manifest | `docs/baselines/<label>/manifest.md` |
| Change log | `docs/project/change-log.md` |

---

### scrum-master

Drafts sprint plans, logs standup notes, and synthesises retrospective notes
into action items.

**Commands**: `/kiss-sprint-planning` · `/kiss-standup` · `/kiss-retrospective`
· `/kiss-taskify` · `/kiss-feature-checklist`

**Reads from**: product-owner → backlog + acceptance ·
project-manager → project plan

| Artefact | Path |
|----------|------|
| Sprint plan | `docs/agile/sprint-NN-plan.md` |
| Standup notes | `docs/agile/standups/YYYY-MM-DD.md` |
| Impediments | `docs/agile/impediments.md` |
| Retrospective | `docs/agile/retro-sprint-NN.md` |
| Action items | `docs/agile/action-items.md` |

---

### test-architect

Drafts the feature-scoped test strategy, framework recommendation, quality
gates, and requirements traceability matrix (RTM).

**Commands**: `/kiss-test-strategy` · `/kiss-test-framework` ·
`/kiss-quality-gates` · `/kiss-traceability-matrix` · `/kiss-plan` ·
`/kiss-standardize`

**Reads from**: business-analyst → spec + SRS · architect → intake ·
project-manager → risk register

| Artefact | Path |
|----------|------|
| Test strategy | `docs/testing/<feature>/strategy.md` |
| Framework recommendation | `docs/testing/<feature>/framework.md` |
| Quality gates | `docs/testing/<feature>/quality-gates.md` |
| RTM | `docs/analysis/traceability-matrix.md` |
| Test debts | `docs/testing/<feature>/test-debts.md` |

---

### tester

Writes executable test cases, maintains the test-execution ledger, authors
structured bug reports, and owns the regression test index.

**Commands**: `/kiss-test-cases` · `/kiss-test-execution` · `/kiss-bug-report`
· `/kiss-regression-tests` · `/kiss-taskify` · `/kiss-verify-tasks`

**Reads from**: test-architect → strategy + framework ·
business-analyst → UAT plan · developer → design ·
product-owner → acceptance criteria

| Artefact | Path |
|----------|------|
| Test cases | `docs/testing/<feature>/test-cases.md` |
| Execution ledger | `docs/testing/<feature>/execution.md` |
| Bug report | `docs/bugs/BUG-NNN-<slug>.md` |
| Regression index | `docs/testing/regression-index.md` |
| Test debts | `docs/testing/<feature>/test-debts.md` |

> **Note:** The `bug-fixer` writes the regression test code; the `tester`
> owns the index and validates each entry runs in CI.

---

### code-quality-reviewer

Reviews source code for maintainability, complexity, SOLID/DRY/KISS, and
project-standards compliance.

**Commands**: `/kiss-quality-review` · `/kiss-standardize`

**Reads from**: developer → design + source · architect → intake

| Artefact | Path |
|----------|------|
| Quality review | `docs/reviews/<feature>/quality.md` |
| Quality debts | `docs/reviews/quality-debts.md` *(append)* |

---

### code-security-reviewer

Reviews code and config against OWASP Top 10:2025, STRIDE, and common CWE
patterns. Also audits third-party dependencies.

**Commands**: `/kiss-security-review` · `/kiss-dependency-audit`

**Reads from**: architect → C4 + intake + ADRs · developer → source ·
devops → infra config

| Artefact | Path |
|----------|------|
| Security review | `docs/reviews/<feature>/security.md` |
| Dependency audit | `docs/reviews/<feature>/dependencies.md` |
| Security debts | `docs/reviews/security-debts.md` *(append)* |

---

### bug-fixer

Triages the bug backlog, applies minimal targeted fixes, writes regression
test code, and records all changes in the change register.

**Commands**: `/kiss-bug-triage` · `/kiss-implement` · `/kiss-regression-tests`
· `/kiss-change-log` · `/kiss-verify-tasks`

**Reads from**: tester → bug reports · code-quality-reviewer → quality debts
· code-security-reviewer → security debts

| Artefact | Path |
|----------|------|
| Triage | `docs/bugs/triage.md` |
| Change register | `docs/bugs/change-register.md` |
| Regression tests | project test tree *(code only)* |
| Fix debts | `docs/bugs/fix-debts.md` *(append)* |

---

### devops

Drafts CI/CD, IaC, container strategy, observability plan, deployment
runbook, and ops handover. For projects with legacy data migration, translates
the `business-analyst`-authored migration strategy into a technical cutover
runbook.

**Commands**: `/kiss-cicd-pipeline` · `/kiss-infrastructure-plan` ·
`/kiss-containerization` · `/kiss-observability-plan` ·
`/kiss-deployment-strategy` · `/kiss-handover` · `/kiss-data-migration-plan`

**Reads from**: architect → C4 + intake · test-architect → quality gates ·
business-analyst → SRS + `data-migration-plan.md` + `field-mapping.md`

| Artefact | Path | When |
|----------|------|------|
| CI/CD design | `docs/operations/cicd.md` | Always |
| Infrastructure plan | `docs/operations/infra.md` | Always |
| Container strategy | `docs/operations/containers.md` | If containerised |
| Observability plan | `docs/operations/monitoring.md` | Always |
| Deployment runbook | `docs/operations/deployment.md` | Always |
| Handover package | `docs/operations/handover/handover-package.md` | Waterfall / production |
| Migration runbook | `docs/operations/migration-runbook.md` | If legacy data migration |
| Ops debts | `docs/operations/ops-debts.md` | Always |

---

### technical-analyst

Scans an existing codebase and produces a technology overview, extracted
architecture, API docs, and dependency map. **Brownfield only** — run
before `architect` on existing projects.

**Commands**: `/kiss-codebase-scan` · `/kiss-arch-extraction` · `/kiss-api-docs`
· `/kiss-dependency-map`

**Reads from**: source tree (authoritative) · architect → existing intake +
ADRs (cross-check)

| Artefact | Path |
|----------|------|
| Codebase scan | `docs/analysis/codebase-scan.md` |
| Extracted architecture | `docs/architecture/extracted.md` |
| Extracted API docs | `docs/analysis/api-docs.md` |
| Dependency map | `docs/analysis/dependencies.md` + `module-graph.mmd` |
| Analysis debts | `docs/analysis/analysis-debts.md` |

> **Note:** The `technical-analyst` documents extracted API docs for existing
> endpoints. For new endpoints, the `developer` authors the authoritative
> API contract and the `technical-analyst` validates it matches the
> implementation.
