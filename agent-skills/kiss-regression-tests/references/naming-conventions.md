# Regression-test naming

Pick one convention and stick to it across the project.

| Framework | File name pattern | Test name pattern |
|---|---|---|
| pytest | `test_bug_014_email_trim.py` | `test_bug_014_email_trim_rejects_whitespace` |
| vitest / jest | `bug-014-email-trim.test.ts` | `describe('BUG-014 email trim', …)` |
| junit5 | `Bug014EmailTrimTest.java` | `rejectsWhitespace()` |
| go | `bug_014_email_trim_test.go` | `TestBug014EmailTrim_RejectsWhitespace` |

## Guidance

- Include the bug id in the file or class name. Makes grep-to-bug
  trivial.
- Start the test name with the observable symptom, not the fix.
  "rejectsWhitespace" > "stripsAllWhitespace".
- One bug → at least one test file. Split into multiple tests only
  if the bug produced multiple distinct symptoms.
- Regression tests live under a dedicated `regression/` folder
  alongside the normal test tree; some teams prefer co-locating
  with the affected module — either is fine, be consistent.
