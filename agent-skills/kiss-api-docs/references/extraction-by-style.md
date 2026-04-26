# Extracting API docs by style

## REST

- Prefer `openapi.{yaml,json}` if present — it's authoritative.
- Otherwise walk route files: Express `app.get/post`, FastAPI
  decorators, Flask `@app.route`, Go `http.Handle`, etc.
- Cite `file:line` for every endpoint.

## GraphQL

- `schema.graphql` is authoritative.
- If code-first, walk `buildSchema` / decorator-based generators.

## gRPC

- `.proto` files are authoritative.
- Note: streaming methods (client-stream / server-stream / bidi).

## tRPC

- Routers + procedures — trace from the app router tree.

## Events / Messaging

- Topic names + schema (Avro / JSON schema / protobuf) define the
  contract. Name the producer + consumer per topic.

## AI-authoring note

Every claim is attributed to a file:line. If the source is
insufficient to infer a schema (e.g. `any`), record the endpoint
without the schema and log an `ANALYSISDEBT`.
