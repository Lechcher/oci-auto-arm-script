## Context

The `auto_provision.sh` script has evolved to include automated OCI CLI bootstrap, dynamic resource resolution, principal authentication support, and project-local run artifact generation. Users need a consolidated guide to understand how to use these features correctly.

## Goals / Non-Goals

**Goals:**
- Provide a clear, copy-pasteable example for the most common use case (default launch with API key).
- Document environment variables and CLI flags comprehensively.
- Explain the artifact directory structure and what it contains.

**Non-Goals:**
- Do not document every possible OCI CLI flag (refer users to official OCI docs for raw command mode).
- Do not provide a tutorial on setting up an Oracle Cloud account or generating SSH keys.

## Decisions

- **Structure**:
  - Title/Description
  - Prerequisites
  - Quick Start
  - Authentication (explaining the 3 modes)
  - Features (Bootstrap, Auto-retry, Artifacts)
  - Usage (CLI flags and Environment Variables)
- **Format**: Markdown standard with code blocks for commands.
- **Location**: Root directory `README.md`.

## Risks / Trade-offs

- [Risk] Documentation can drift from script implementation. -> Mitigation: Keep examples focused on stable core arguments and rely on script `--help` for exhaustive flag documentation.
