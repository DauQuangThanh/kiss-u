# {title}

**Project:** {project}
**Revision:** {revision}
**Date:** {date}
**Status:** Draft

## Sign-off

| Role | Name | Signature | Date |
|---|---|---|---|
| Author | | | |
| Technical Reviewer | | | |
| Approver | | | |

---

## 1. Introduction

### 1.1 Purpose

This document specifies the software requirements for **{project}**. It is
the authoritative baseline used by the design, development, and testing teams
to verify that the delivered system satisfies the agreed stakeholder needs.

Reference standard: IEEE 29148:2018 *Systems and software engineering —
Life cycle processes — Requirements engineering*.

### 1.2 Scope

{scope}

### 1.3 Definitions, acronyms, and abbreviations

| Term | Definition |
|---|---|
| FR | Functional Requirement |
| NFR | Non-Functional Requirement |
| MoSCoW | Must / Should / Could / Won't prioritisation scheme |
| SRS | Software Requirements Specification |
| RTM | Requirements Traceability Matrix |

### 1.4 Overview

Section 2 provides the overall system description and constraints.
Section 3 lists functional requirements (FR-NNN).
Section 4 lists non-functional requirements (NFR-NNN).
Section 5 describes external interface requirements.
Section 6 states constraints and assumptions.

---

## 2. Overall description

### 2.1 Product perspective

{product_perspective}

### 2.2 Product functions (summary)

{product_functions_summary}

### 2.3 User classes and characteristics

{user_classes}

### 2.4 Operating environment

{operating_environment}

### 2.5 Design and implementation constraints

{design_constraints}

### 2.6 Assumptions and dependencies

{assumptions}

---

## 3. Functional requirements

<!-- Each FR entry follows the format:
     ### FR-NNN: <Title>
     **Priority:** Must / Should / Could / Won't (MoSCoW)
     **Source:** specs/<feature>/spec.md
     **Description:** …
     **Acceptance criterion:** Given … When … Then …
     **Rationale:** …
-->

{functional_requirements}

---

## 4. Non-functional requirements

<!-- Each NFR follows the same pattern as FR but with NFR-NNN identifiers.
     Subcategories: Performance, Security, Reliability, Usability,
     Maintainability, Portability, Legal / Compliance. -->

{non_functional_requirements}

---

## 5. External interface requirements

### 5.1 User interfaces

{ui_interfaces}

### 5.2 Hardware interfaces

{hardware_interfaces}

### 5.3 Software / API interfaces

{api_interfaces}

### 5.4 Communication interfaces

{comm_interfaces}

---

## 6. Constraints and assumptions

{constraints_and_assumptions}

---

## Appendix A: Open SRSDEBT items

See `srs-debts.md`.

## Appendix B: Traceability stub

<!-- Populated by kiss-traceability-matrix. -->

| Req ID | Source spec | Design section | Task ID | Test case ID |
|---|---|---|---|---|
