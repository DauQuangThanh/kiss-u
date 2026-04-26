# C4 — Level 1: System Context

**Date:** {date}
**Subject system:** {system_name}

## What this shows

People and external systems that interact with **{system_name}**.
No internals. One-screen overview for any stakeholder.

## Diagram

```mermaid
flowchart LR
    user["👤 User<br/><em>persona / role</em>"]
    admin["👤 Admin"]
    system(({system_name}))
    idp["🔑 Identity Provider<br/><em>external</em>"]
    billing["💳 Billing / Payments<br/><em>external</em>"]

    user -->|uses| system
    admin -->|configures| system
    system -->|authenticates via| idp
    system -->|charges via| billing
```

## Actors

| Actor | Type | Relationship | Notes |
|---|---|---|---|
| User | person | primary | |
| Admin | person | operator | |

## External systems

| System | Relationship | Owner | Notes |
|---|---|---|---|
| Identity Provider | authentication | <vendor> | |
| Billing | payment rails | <vendor> | |
