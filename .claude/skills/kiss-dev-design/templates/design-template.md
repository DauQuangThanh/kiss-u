<!-- markdownlint-disable MD024 -->
# Detailed Design: {feature}

**Date:** {date}
**Pattern:** {pattern}
**API style:** {api_style}
**Data style:** {data_style}

## Module structure

<!-- One block per top-level module. Name + responsibility + files.
     Keep to one page; anything longer probably needs splitting. -->

### <module-name>

- **Responsibility:** what this module owns
- **Entry points:** public functions / HTTP endpoints / topic subs
- **Collaborators:** modules it calls; modules that call it
- **Error handling:** exceptions raised; retry policy; fallback

### <next module>

…

## Cross-cutting concerns

- **Auth** — which middleware / guards run on every request
- **Logging** — structured? correlation id? log level by env
- **Tracing** — OpenTelemetry spans around which seams
- **Feature flags** — names + default values + rollout plan
- **Rate limiting** — where; algorithm; defaults

## Migration plan (if the feature changes an existing module)

- <step 1>
- <step 2>
- Rollback procedure

## Open questions

- <link to `tech-debts.md` entries>
