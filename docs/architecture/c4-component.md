# C4 — Level 3: Components (inside the `kiss` CLI process)

**Date:** 2026-04-26
**Subject system:** KISS CLI (kiss-u) — container C1

> Drafted by `architect` (auto mode). Status: **Proposed**. Decider:
> **TBD — confirm**. The two re-designed packages
> (`extensions/` and `presets/`) replace today's monolithic
> `extensions.py` (2,493 LOC) and `presets.py` (2,098 LOC). The
> public surface (class names exported from each package) is
> preserved; this is a *decomposition*, not a rename.

## What this shows

The major modules / classes that live inside the `kiss` CLI
process (container C1), and how they collaborate. The diagrams
below focus on the parts that change in this re-design — the
extensions and presets packages.

## A. Process-level overview (current, kept)

```mermaid
flowchart TB
    typer["Typer app<br/><em>cli/__init__.py</em>"]

    subgraph cmds["CLI command modules (cli/*.py)"]
        init["init.py"]
        chk["check.py"]
        intg["integration.py"]
        ext["extension.py"]
        pre["preset.py"]
        wf["workflow.py"]
        ver["version.py"]
    end

    subgraph core["Core helpers (no I/O when avoidable)"]
        installer["installer.py"]
        ctx["context.py"]
        cfg["config.py"]
        ui["ui.py"]
        tracker["tracker.py"]
        skassets["skill_assets.py"]
        agentsmod["agents.py"]
        integrity["_integrity.py"]
        bcat["_bundled_catalogs.py"]
    end

    subgraph integrations_pkg["integrations/"]
        ireg["__init__.py<br/>(INTEGRATION_REGISTRY)"]
        ibase["base.py<br/>(IntegrationBase)"]
        imani["manifest.py"]
        icat["catalog.py"]
        each13["13 concrete integrations<br/>(claude, copilot, gemini, …)"]
    end

    subgraph workflows_pkg["workflows/"]
        wfeng["engine.py"]
        wfbase["base.py"]
        wfreg["__init__.py<br/>(STEP_REGISTRY)"]
        wfsteps["steps/<br/>(10 step types)"]
    end

    subgraph extensions_pkg["extensions/  (re-designed package)"]
        e_mgr["manager.py"]
        e_mani["manifest.py"]
        e_reg["registry.py"]
        e_cat["catalog.py"]
        e_cfg["config.py"]
        e_hook["hooks.py"]
        e_fm["frontmatter.py"]
        e_ver["version.py (pure)"]
        e_err["errors.py"]
        e_core["core_commands.py"]
    end

    subgraph presets_pkg["presets/  (re-designed package)"]
        p_mgr["manager.py"]
        p_mani["manifest.py"]
        p_reg["registry.py"]
        p_cat["catalog.py"]
        p_resv["resolver.py (pure)"]
        p_skills["skills.py"]
        p_cmds["commands.py"]
        p_tmpl["templates.py (pure)"]
        p_err["errors.py"]
    end

    typer --> cmds
    init --> installer
    init --> integrations_pkg
    init --> extensions_pkg
    init --> presets_pkg
    init --> workflows_pkg
    intg --> integrations_pkg
    ext --> extensions_pkg
    pre --> presets_pkg
    wf --> workflows_pkg

    extensions_pkg --> core
    presets_pkg --> core
    integrations_pkg --> core
    workflows_pkg --> core
```

## B. Re-designed `extensions/` package

### Diagram

```mermaid
flowchart TB
    cli_ext["cli/extension.py<br/>(Typer command module)"]

    subgraph extpkg["extensions/  (was: extensions.py 2,493 LOC)"]
        facade["__init__.py<br/><em>re-exports the public surface</em>"]
        mgr["manager.py<br/><em>ExtensionManager</em>"]
        mani["manifest.py<br/><em>ExtensionManifest, CatalogEntry</em>"]
        reg["registry.py<br/><em>ExtensionRegistry</em>"]
        cat["catalog.py<br/><em>ExtensionCatalog</em>"]
        cfg["config.py<br/><em>ConfigManager</em>"]
        hook["hooks.py<br/><em>HookExecutor — only subprocess caller</em>"]
        fm["frontmatter.py<br/><em>CommandRegistrar (frontmatter helpers)</em>"]
        verm["version.py (pure)<br/><em>version_satisfies, normalize_priority</em>"]
        err["errors.py (pure)<br/><em>ExtensionError, ValidationError, CompatibilityError</em>"]
        core["core_commands.py<br/><em>_load_core_command_names</em>"]
    end

    subgraph fs["Filesystem (edges only)"]
        userdir["<project>/.kiss/extensions/"]
        cattree["core_pack/extensions/"]
        cmds[".claude/commands/, .gemini/commands/, …"]
    end

    subprocess["subprocess (hooks)"]

    cli_ext --> facade
    facade --> mgr
    facade --> mani
    facade --> reg
    facade --> cat
    facade --> cfg
    facade --> hook
    facade --> err

    mgr --> mani
    mgr --> reg
    mgr --> cat
    mgr --> cfg
    mgr --> hook
    mgr --> fm
    mgr --> verm
    mgr --> core
    mgr --> err

    mani -->|reads YAML| userdir
    reg -->|reads / writes registry.json| userdir
    cat -->|reads catalog| cattree
    cfg -->|reads / writes per-extension config| userdir
    hook -->|spawns| subprocess
    mgr -->|writes command files| cmds

    classDef pure fill:#efe,stroke:#383,color:#000
    classDef io fill:#eef,stroke:#558,color:#000
    classDef facadec fill:#ffe,stroke:#883,color:#000
    class verm,err,fm pure
    class mani,reg,cat,cfg,hook,core,mgr io
    class facade facadec
```

### Components

| Component | Class(es) / functions exposed (preserve names) | Pure / I/O | Role |
|---|---|---|---|
| `extensions/__init__.py` | re-exports `ExtensionManifest`, `ExtensionRegistry`, `ExtensionManager`, `ExtensionCatalog`, `ConfigManager`, `HookExecutor`, `CommandRegistrar`, `ExtensionError`, `ValidationError`, `CompatibilityError`, `CatalogEntry`, `version_satisfies`, `normalize_priority` | facade | Backward-compat shim — callers in `cli/extension.py`, `presets/`, `cli/init.py` keep working unchanged |
| `extensions/errors.py` | `ExtensionError`, `ValidationError`, `CompatibilityError` | **pure** | No globals, no I/O |
| `extensions/version.py` | `version_satisfies(current, required) -> bool`, `normalize_priority(value, default=10) -> int` | **pure** | Same input → same output (Principle IV) |
| `extensions/frontmatter.py` | `CommandRegistrar.parse_frontmatter`, `CommandRegistrar.render_frontmatter` (today at `extensions.py:1457,1462`) | **pure** | Renamed away from the colliding `kiss_cli.agents.CommandRegistrar` (TDEBT-020) — recommended fresh class name `FrontmatterCodec` once accepted |
| `extensions/core_commands.py` | `_load_core_command_names() -> frozenset[str]` (today at `extensions.py:99`) | I/O at edge | Reads bundled core command list once at import |
| `extensions/manifest.py` | `ExtensionManifest`, `CatalogEntry` | I/O at edge | YAML parsing in `_load_yaml`; `_validate` stays pure once helpers are extracted |
| `extensions/registry.py` | `ExtensionRegistry` | I/O at edge | Reads / writes `<project>/.kiss/extensions/registry.json`. Path injected via constructor (already done — `extensions_dir: Path`) |
| `extensions/catalog.py` | `ExtensionCatalog` | I/O at edge | Catalog search / info / add / remove |
| `extensions/config.py` | `ConfigManager` | I/O at edge | Per-extension config read / write |
| `extensions/hooks.py` | `HookExecutor` | I/O at edge | **Only** module that calls `subprocess` for hooks |
| `extensions/manager.py` | `ExtensionManager` | composes I/O | Orchestrator. Today's 14+ methods (e.g. `install_from_directory`, `install_from_zip`, `remove`, `_register_extension_skills`, `_unregister_extension_skills`, `check_compatibility`, `list_installed`, `get_extension`) get split into ≤ 40-LOC functions during the decomposition (Principle III) |

### Sizing targets (per Principle III)

- Each module ≤ 400 LOC executable.
- Each function ≤ 40 LOC executable.
- Cyclomatic complexity ≤ 10 per function.
- Nesting depth ≤ 3.
- Public surface = the names re-exported from `__init__.py`;
  everything else is private.

### Why this layout (KISS / YAGNI)

- Splits **by side-effect type** (pure helpers vs. filesystem I/O
  vs. subprocess), not by speculative future features. This is the
  minimum cut that makes Principle IV testable and Principle III
  enforceable.
- Preserves all today's class names — no rename churn, no
  rippling test changes outside `tests/test_extensions.py`.
- Adds **one** new private class name suggestion
  (`FrontmatterCodec`) only if the user agrees to resolve TDEBT-020;
  otherwise the existing class name stays inside its new home.

## C. Re-designed `presets/` package

### Diagram

```mermaid
flowchart TB
    cli_pre["cli/preset.py<br/>(Typer command module)"]

    subgraph prepkg["presets/  (was: presets.py 2,098 LOC)"]
        pfacade["__init__.py<br/><em>re-exports the public surface</em>"]
        pmgr["manager.py<br/><em>PresetManager</em>"]
        pmani["manifest.py<br/><em>PresetManifest, PresetCatalogEntry</em>"]
        preg["registry.py<br/><em>PresetRegistry</em>"]
        pcat["catalog.py<br/><em>PresetCatalog</em>"]
        presv["resolver.py (pure)<br/><em>PresetResolver</em>"]
        pskills["skills.py<br/><em>skill register/unregister + restore</em>"]
        pcmds["commands.py<br/><em>command register/unregister + replay</em>"]
        ptmpl["templates.py (pure)<br/><em>_substitute_core_template</em>"]
        perr["errors.py (pure)<br/><em>PresetError, PresetValidationError, PresetCompatibilityError</em>"]
    end

    extfacade["extensions/__init__.py<br/>(public facade)"]
    fs["Filesystem (edges only)"]
    cattree["core_pack/presets/"]

    cli_pre --> pfacade
    pfacade --> pmgr
    pfacade --> pmani
    pfacade --> preg
    pfacade --> pcat
    pfacade --> presv
    pfacade --> perr

    pmgr --> pmani
    pmgr --> preg
    pmgr --> pcat
    pmgr --> presv
    pmgr --> pskills
    pmgr --> pcmds
    pmgr --> ptmpl
    pmgr --> perr
    pmgr --> extfacade

    pmani -->|reads YAML| fs
    preg -->|reads / writes registry.json| fs
    pcat -->|reads catalog| cattree
    pskills -->|reads / writes skills tree| fs
    pcmds -->|reads / writes commands tree| fs

    classDef pure fill:#efe,stroke:#383,color:#000
    classDef io fill:#eef,stroke:#558,color:#000
    classDef facadec fill:#ffe,stroke:#883,color:#000
    class presv,ptmpl,perr pure
    class pmani,preg,pcat,pskills,pcmds,pmgr io
    class pfacade facadec
```

### Components

| Component | Class(es) / functions exposed (preserve names) | Pure / I/O | Role |
|---|---|---|---|
| `presets/__init__.py` | re-exports `PresetManifest`, `PresetRegistry`, `PresetManager`, `PresetCatalog`, `PresetResolver`, `PresetError`, `PresetValidationError`, `PresetCompatibilityError`, `PresetCatalogEntry` | facade | Backward-compat shim |
| `presets/errors.py` | the three exception types | **pure** | |
| `presets/templates.py` | `_substitute_core_template` (today at `presets.py:33`) | **pure** | Same input → same output |
| `presets/resolver.py` | `PresetResolver` (today at `presets.py:1797+`) | **pure** | Resolution algorithm — no filesystem |
| `presets/manifest.py` | `PresetManifest`, `PresetCatalogEntry` | I/O at edge | YAML parse + validation |
| `presets/registry.py` | `PresetRegistry` | I/O at edge | `<project>/.kiss/presets/registry.json` |
| `presets/catalog.py` | `PresetCatalog` | I/O at edge | Catalog mgmt |
| `presets/skills.py` | (private) `_register_skills`, `_unregister_skills`, `_replay_skill_override`, `_build_extension_skill_restore_index` | I/O at edge | Skill lifecycle inside a preset |
| `presets/commands.py` | (private) `_register_commands`, `_unregister_commands`, `_replay_wraps_for_command`, `_skill_title_from_command` | I/O at edge | Command lifecycle inside a preset |
| `presets/manager.py` | `PresetManager` | composes I/O | Orchestrator. Today's `install_from_directory`, `install_from_zip`, `remove`, `list_installed`, `get_pack`, `check_compatibility` get split into ≤ 40-LOC functions (Principle III) |

### Sizing targets

Same as the extensions package: ≤ 400 LOC per module, ≤ 40 LOC per
function, cyclomatic ≤ 10, nesting ≤ 3.

## D. Cross-package contracts (preserve)

The following inbound edges to `extensions/` and `presets/` MUST
keep working through the public facades:

| Caller | Symbol | Source line (current) |
|---|---|---|
| `cli/extension.py` | `ExtensionManager`, `ExtensionRegistry`, `ExtensionCatalog`, `ConfigManager`, etc. | imported as `from kiss_cli.extensions import …` |
| `cli/preset.py` | `PresetManager`, `PresetRegistry`, `PresetCatalog`, `PresetResolver`, exceptions | `from kiss_cli.presets import …` |
| `cli/init.py` | both managers (preset install path) | top of file |
| `presets/manager.py` (new) | `extensions.ExtensionManager` (preset → extension dependency) | `presets.py:27-28` (today imports `packaging`, plus uses `extensions` package indirectly) |

The decomposition keeps the `from kiss_cli.extensions import X` /
`from kiss_cli.presets import X` form intact, so callers do not
move. ADR-013 / ADR-014 capture this commitment.

## E. Notes / non-goals

- **No new features.** Per Principle I, the re-design adds no new
  capability — it splits existing code along an existing seam
  (side-effect type) so the size limits become enforceable.
- **No rename of public classes.** Renames are a separate
  decision (TDEBT-020 covers the only collision today).
- **No change to the integration / workflow packages.** Those
  modules are already small enough to satisfy Principle III at
  module scale (`integrations/base.py` at 1,374 LOC is the next
  candidate after this re-design lands but is out of scope here —
  noted as TDEBT-022).
- **Code-level structure (function bodies, signatures of new
  helpers) belongs in `docs/design/<feature>/design.md`,** not in
  this Level-3 view. The developer agent picks that up after the
  ADRs are accepted.
