# CLI Reference

The kiss (`kiss`) manages the full lifecycle of Spec-Driven Development — from project initialization to workflow automation.

## Core Commands

The foundational commands for creating and managing kiss projects. Initialize a new project with the necessary directory structure, templates, and scripts. Verify that your system has the required tools installed. Check version and system information.

[Core Commands reference →](core.md)

## Integrations

Integrations connect kiss to your AI coding agents. Each integration sets up the appropriate command files, context rules, and directory structures for a specific agent. Multiple integrations can be installed and active simultaneously in a single project.

[Integrations reference →](integrations.md)

## Extensions

Extensions add new capabilities to kiss — domain-specific commands, external tool integrations, quality gates, and more. They are discovered through catalogs and can be installed, updated, enabled, disabled, or removed independently. Multiple extensions can coexist in a single project.

[Extensions reference →](extensions.md)

## Presets

Presets customize how kiss works — overriding command files, template files, and script files without changing any tooling. They let you enforce organizational standards, adapt the workflow to your methodology, or localize the entire experience. Multiple presets can be stacked with priority ordering to layer customizations.

[Presets reference →](presets.md)

## Workflows

Workflows automate multi-step Spec-Driven Development processes into repeatable sequences. They chain commands, prompts, shell steps, and human checkpoints together, with support for conditional logic, loops, fan-out/fan-in, and the ability to pause and resume from the exact point of interruption.

[Workflows reference →](workflows.md)
