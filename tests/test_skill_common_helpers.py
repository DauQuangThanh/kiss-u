"""Runtime behaviour tests for the shared helper library in
``agent-skills/_template/scripts/bash/common.sh``.

These tests exercise the context-file parser, work-type directory
resolution, the debt-register writer, and the .extract companion
writer by invoking Bash directly against a temporary project tree.

PowerShell parity is NOT exercised here — that's runtime-dependent
and covered by a separate test (``test_skill_common_helpers_ps.py``)
gated on ``pwsh`` availability. For now we rely on the structural
parity check in ``test_skill_bundle_layout.py`` to catch drift.
"""

from __future__ import annotations

import os
import subprocess
import textwrap
from pathlib import Path

import pytest

from tests.conftest import requires_bash


REPO_ROOT = Path(__file__).resolve().parents[1]
COMMON_SH = REPO_ROOT / "agent-skills" / "_template" / "scripts" / "bash" / "common.sh"


def _run_bash(script: str, cwd: Path) -> subprocess.CompletedProcess:
    """Run a small bash snippet that sources common.sh."""
    full = f"set -e\nsource {COMMON_SH}\n{script}\n"
    return subprocess.run(
        ["bash", "-c", full],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        timeout=30,
        env={**os.environ, "KISS_AUTO": "1"},
    )


@pytest.fixture
def kiss_project(tmp_path: Path) -> Path:
    """A scratch project with a sane .kiss/context.yml."""
    (tmp_path / ".kiss").mkdir()
    (tmp_path / ".kiss" / "context.yml").write_text(textwrap.dedent("""\
        schema_version: "1.0"
        paths:
          docs: docs
          specs: docs/specs
          plans: docs/plans
          tasks: docs/tasks
          templates: templates
          scripts: scripts
        current:
          feature: user-auth
          spec: null
          plan: null
          task: null
          checklist: null
          branch: null
        preferences:
          output_format: markdown
          task_numbering: sequential
          confirm_before_write: true
          auto_update_context: true
        integrations:
          - claude
        """))
    return tmp_path


@requires_bash
class TestReadContext:
    """read_context populates KISS_* env vars from context.yml."""

    def test_defaults_when_context_missing(self, tmp_path: Path):
        # Create a .kiss/ directory so find_kiss_root returns this
        # path, but omit context.yml so the helper warns + uses
        # defaults.
        (tmp_path / ".kiss").mkdir()
        r = _run_bash(
            'read_context 2>/dev/null\n'
            'echo "DOCS=<${KISS_DOCS_DIR}>"\n'
            'echo "SPECS=<${KISS_SPECS_DIR}>"\n'
            'echo "FEATURE=<${KISS_CURRENT_FEATURE}>"\n',
            tmp_path,
        )
        assert r.returncode == 0, r.stderr
        assert "DOCS=<docs>" in r.stdout
        assert "SPECS=<docs/specs>" in r.stdout
        assert "FEATURE=<>" in r.stdout

    def test_populates_from_context_yml(self, kiss_project: Path):
        r = _run_bash(
            'read_context\n'
            'echo "DOCS=<${KISS_DOCS_DIR}>"\n'
            'echo "SPECS=<${KISS_SPECS_DIR}>"\n'
            'echo "FEATURE=<${KISS_CURRENT_FEATURE}>"\n'
            'echo "CONFIRM=<${KISS_CONFIRM_BEFORE_WRITE}>"\n',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        assert "DOCS=<docs>" in r.stdout
        assert "SPECS=<docs/specs>" in r.stdout
        assert "FEATURE=<user-auth>" in r.stdout
        assert "CONFIRM=<true>" in r.stdout

    def test_repo_root_resolves_to_kiss_project(self, kiss_project: Path):
        sub = kiss_project / "nested" / "deep"
        sub.mkdir(parents=True)
        r = _run_bash('read_context\nprintf "%s\\n" "$KISS_REPO_ROOT"', sub)
        assert r.returncode == 0, r.stderr
        resolved = r.stdout.strip()
        assert Path(resolved).resolve() == kiss_project.resolve()


@requires_bash
class TestWorktypeDir:
    """worktype_dir returns and creates docs/<work-type>/ under repo root."""

    def test_creates_work_type_dir(self, kiss_project: Path):
        r = _run_bash(
            'read_context\nworktype_dir architecture',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        out = r.stdout.strip()
        assert out.endswith("/docs/architecture")
        assert (kiss_project / "docs" / "architecture").is_dir()

    def test_idempotent(self, kiss_project: Path):
        r = _run_bash(
            'read_context\nworktype_dir testing\nworktype_dir testing',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        # Two calls, two identical paths in stdout
        lines = r.stdout.strip().split("\n")
        assert lines[0] == lines[1]


@requires_bash
class TestFeatureScopedDir:
    """feature_scoped_dir nests a feature slug under the work-type dir."""

    def test_happy_path(self, kiss_project: Path):
        r = _run_bash(
            'read_context\nfeature_scoped_dir testing',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        assert r.stdout.strip().endswith("/docs/testing/user-auth")
        assert (kiss_project / "docs" / "testing" / "user-auth").is_dir()

    def test_errors_when_feature_unset(self, tmp_path: Path):
        (tmp_path / ".kiss").mkdir()
        (tmp_path / ".kiss" / "context.yml").write_text(textwrap.dedent("""\
            schema_version: "1.0"
            paths:
              docs: docs
              specs: docs/specs
              plans: docs/plans
              tasks: docs/tasks
              templates: templates
              scripts: scripts
            current:
              feature: null
              spec: null
              plan: null
              task: null
              checklist: null
              branch: null
            preferences:
              output_format: markdown
              task_numbering: sequential
              confirm_before_write: true
              auto_update_context: true
            integrations:
              - claude
            """))
        r = _run_bash(
            'read_context\nfeature_scoped_dir testing',
            tmp_path,
        )
        # Script set -e + missing feature => non-zero + error message.
        assert r.returncode != 0
        assert "current.feature" in r.stderr


@requires_bash
class TestAppendDebt:
    """append_debt creates and auto-increments a numbered debt file."""

    def test_creates_and_increments(self, kiss_project: Path):
        r = _run_bash(
            'read_context\n'
            'DIR=$(worktype_dir architecture)\n'
            'append_debt "$DIR/tech-debts.md" TDEBT "first debt"\n'
            'append_debt "$DIR/tech-debts.md" TDEBT "second debt"',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        ids = r.stdout.strip().split("\n")
        assert ids == ["TDEBT-01", "TDEBT-02"]
        body = (kiss_project / "docs" / "architecture" / "tech-debts.md").read_text()
        assert "TDEBT-01: first debt" in body
        assert "TDEBT-02: second debt" in body

    def test_reuses_existing_file_numbering(self, kiss_project: Path):
        debt_file = kiss_project / "docs" / "project" / "pm-debts.md"
        debt_file.parent.mkdir(parents=True)
        debt_file.write_text(
            "# Debt register (PMDEBT)\n\n"
            "PMDEBT-01: legacy\n"
            "PMDEBT-07: another legacy\n"
        )
        r = _run_bash(
            f'read_context\nappend_debt "{debt_file}" PMDEBT "next one"',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        assert r.stdout.strip() == "PMDEBT-08"


@requires_bash
class TestWriteExtract:
    """write_extract writes a KEY=VALUE sidecar next to the artefact."""

    def test_writes_pairs(self, kiss_project: Path):
        r = _run_bash(
            'read_context\n'
            'DIR=$(worktype_dir architecture)\n'
            'ART="$DIR/intake.md"\n'
            'echo "# Intake" > "$ART"\n'
            'write_extract "$ART" FOO=bar "BAZ=hello world"',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        extract = kiss_project / "docs" / "architecture" / "intake.extract"
        assert extract.is_file()
        lines = extract.read_text().splitlines()
        assert "FOO=bar" in lines
        assert "BAZ=hello world" in lines


@requires_bash
class TestAgentMode:
    """KISS_AGENT_MODE selects auto / interactive + enables KISS_AUTO."""

    def test_default_is_interactive(self, kiss_project: Path):
        r = _run_bash(
            'unset KISS_AGENT_MODE\n'
            'unset KISS_AUTO\n'
            'read_context\n'
            'echo "MODE=<${KISS_AGENT_MODE}>"\n'
            'echo "AUTO=<${KISS_AUTO:-}>"\n',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        assert "MODE=<interactive>" in r.stdout
        assert "AUTO=<>" in r.stdout

    def test_auto_enables_kiss_auto(self, kiss_project: Path):
        r = _run_bash(
            'export KISS_AGENT_MODE=auto\n'
            'unset KISS_AUTO\n'
            'read_context\n'
            'echo "MODE=<${KISS_AGENT_MODE}>"\n'
            'echo "AUTO=<${KISS_AUTO}>"\n',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        assert "MODE=<auto>" in r.stdout
        assert "AUTO=<1>" in r.stdout

    def test_auto_case_insensitive(self, kiss_project: Path):
        r = _run_bash(
            'export KISS_AGENT_MODE=AUTO\n'
            'read_context\n'
            'echo "MODE=<${KISS_AGENT_MODE}>"\n',
            kiss_project,
        )
        assert "MODE=<auto>" in r.stdout

    def test_anything_else_is_interactive(self, kiss_project: Path):
        r = _run_bash(
            'export KISS_AGENT_MODE=bogus\n'
            'read_context\n'
            'echo "MODE=<${KISS_AGENT_MODE}>"\n',
            kiss_project,
        )
        assert "MODE=<interactive>" in r.stdout


@requires_bash
class TestWriteDecision:
    """write_decision logs to docs/agent-decisions/<agent>/<YYYY-MM-DD>.md."""

    def test_writes_first_entry(self, kiss_project: Path):
        r = _run_bash(
            'export KISS_AGENT=project-manager\n'
            'export KISS_AGENT_MODE=auto\n'
            'read_context\n'
            'write_decision default-applied "methodology=scrum" "no PM_METHODOLOGY provided"\n',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        assert r.stdout.strip() == "D-01"
        from datetime import datetime, timezone
        today = datetime.now().strftime("%Y-%m-%d")
        log = kiss_project / "docs" / "agent-decisions" / "project-manager" / f"{today}-decisions.md"
        assert log.is_file()
        body = log.read_text()
        assert "**Mode:** auto" in body
        assert "### D-01 — default-applied" in body
        assert "**What:** methodology=scrum" in body
        assert "**Why:** no PM_METHODOLOGY provided" in body

    def test_auto_increments(self, kiss_project: Path):
        r = _run_bash(
            'export KISS_AGENT=architect\n'
            'read_context\n'
            'write_decision autonomous-action "draft C4 context" "no existing context file"\n'
            'write_decision alternative-picked "PostgreSQL over MySQL" "both viable; PG chosen by prior ADR"\n',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        ids = r.stdout.strip().split("\n")
        assert ids == ["D-01", "D-02"]

    def test_rejects_unknown_kind(self, kiss_project: Path):
        r = _run_bash(
            'export KISS_AGENT=architect\n'
            'read_context\n'
            'write_decision bogus "x" "y" || echo "failed"\n',
            kiss_project,
        )
        assert "failed" in r.stdout

    def test_defaults_agent_to_shared(self, kiss_project: Path):
        r = _run_bash(
            'unset KISS_AGENT\n'
            'read_context\n'
            'write_decision autonomous-action "did a thing"\n',
            kiss_project,
        )
        assert r.returncode == 0, r.stderr
        shared_dir = kiss_project / "docs" / "agent-decisions" / "shared"
        assert shared_dir.is_dir()
        assert any(shared_dir.iterdir())


@requires_bash
class TestResolveAuto:
    """resolve_auto honours the env → answers → extract → default chain."""

    def test_env_wins(self, kiss_project: Path):
        r = _run_bash(
            'read_context\nexport KISS_TOPIC=fromenv\nresolve_auto KISS_TOPIC "default" || true',
            kiss_project,
        )
        assert r.stdout.strip() == "fromenv"

    def test_answers_file_used_when_env_empty(self, kiss_project: Path):
        answers = kiss_project / "answers.env"
        answers.write_text("KISS_TOPIC=fromfile\n")
        r = _run_bash(
            f'read_context\n'
            f'unset KISS_TOPIC\n'
            f'export KISS_ANSWERS="{answers}"\n'
            f'resolve_auto KISS_TOPIC "default" || true',
            kiss_project,
        )
        assert r.stdout.strip() == "fromfile"

    def test_default_when_nothing_provided(self, kiss_project: Path):
        r = _run_bash(
            'read_context\n'
            'unset KISS_TOPIC\n'
            'unset KISS_ANSWERS\n'
            'unset KISS_EXTRACTS\n'
            'resolve_auto KISS_TOPIC "thedefault" || true',
            kiss_project,
        )
        assert r.stdout.strip() == "thedefault"

    def test_extract_chain_consulted(self, kiss_project: Path):
        ex = kiss_project / "upstream.extract"
        ex.write_text("KISS_TOPIC=fromextract\n")
        r = _run_bash(
            f'read_context\n'
            f'unset KISS_TOPIC\n'
            f'unset KISS_ANSWERS\n'
            f'export KISS_EXTRACTS="{ex}"\n'
            f'resolve_auto KISS_TOPIC "default" || true',
            kiss_project,
        )
        assert r.stdout.strip() == "fromextract"


@requires_bash
class TestExampleActionScript:
    """The sample action in _template/ exercises the full flow end-to-end."""

    def test_dry_run_does_not_write(self, kiss_project: Path):
        script = COMMON_SH.parent / "example-action.sh"
        r = subprocess.run(
            ["bash", str(script), "--dry-run", "some-topic"],
            cwd=str(kiss_project),
            capture_output=True,
            text=True,
            timeout=30,
        )
        assert r.returncode == 0, r.stderr
        assert "[dry-run]" in r.stdout
        assert not (kiss_project / "docs" / "_template-output").exists()

    def test_auto_mode_writes_artefact_and_extract(self, kiss_project: Path):
        script = COMMON_SH.parent / "example-action.sh"
        r = subprocess.run(
            ["bash", str(script), "--auto", "my-topic"],
            cwd=str(kiss_project),
            capture_output=True,
            text=True,
            timeout=30,
        )
        assert r.returncode == 0, r.stderr
        artefact = kiss_project / "docs" / "_template-output" / "example.md"
        extract = kiss_project / "docs" / "_template-output" / "example.extract"
        assert artefact.is_file()
        assert extract.is_file()
        assert "my-topic" in artefact.read_text()
        assert "TOPIC=my-topic" in extract.read_text()
