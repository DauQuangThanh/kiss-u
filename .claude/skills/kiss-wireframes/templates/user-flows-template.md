# User flows: {feature}

**Date:** {date}
**Persona:** {persona}

## Sign-in (happy path)

```mermaid
flowchart LR
    start([Start]) --> landing["Landing page"]
    landing -->|Sign in| login["Sign-in form"]
    login -->|submit valid| home[[Home]]
    login -->|submit invalid| login
    login -->|Forgot password| forgot["Forgot password"]
    forgot -->|Send link| confirm["Check email"]
```

## Sign-in (error branches)

```mermaid
flowchart LR
    login -->|locked account| locked["Locked — contact support"]
    login -->|SSO down| fallback["Email/password fallback"]
```

## Cross-flow notes

- Back button behaviour per screen is default unless noted.
- Persistent banners (e.g. "maintenance planned") are shown at
  the top and do not block the flow.
