<!-- markdownlint-disable MD024 -->
# Wireframes: {feature}

**Date:** {date}
**Persona:** {persona}

> Low-fidelity only — structure + content, not visual design.

## Screen: <Login>

```text
┌─────────────────────────────────────────┐
│ 🏠 App                                  │
├─────────────────────────────────────────┤
│                                         │
│   Sign in                               │
│   ─────────                             │
│   email:    [_____________]             │
│   password: [_____________]             │
│                                         │
│   [ Sign in ]   [ Forgot password? ]    │
│                                         │
│   or                                    │
│   [ Sign in with Google ]               │
└─────────────────────────────────────────┘
```

**Covers:** AC-01, AC-02
**States:** default · loading · error (invalid creds) · locked

## Screen: <next>

…

## Components per screen

| Component | Purpose | States |
|---|---|---|
| Email input | username | default / error / disabled |
| Password input | secret | default / error |
| Primary CTA | submit | default / loading / disabled |
